# Part N: Hello nf-test

!!!note

    This training module is under redevelopment.

Being able to systematically test that every part of your workflow is doing what it's supposed to do is critical for reproducibility and long-term maintenance.
And it's also helpful during the development process!

This is (hopefully) not controversial.
However, people often focus on setting up top-level tests, in which the workflow is run on some test data from start to finish.
This is useful, but unfortunately incomplete.
You should also implement tests at the level of each individual module (equivalent to what is called 'unit tests' in general software engineering) to verify the functionality of individual components of your workflow.
That will ensure that each module performs as expected under different conditions and inputs.
And it also means that when you assemble a new workflow from existing modules that already have tests, you get built-in testing for free!

In this part of the training, we're going to show you how to use [**nf-test**](https://www.nf-test.com/), a testing framework that integrates well with Nextflow and makes it straightforward to add both module-level and workflow-level tests to your pipeline.
For more background information about nf-test, we recommend you read [this blog post](https://nextflow.io/blog/2024/nf-test-in-nf-core.html).

---

## 0. Warmup

We're going to add a few different types of tests to the three processes in our pipeline, as well as a workflow-level test.

Similarly to we did in Part 6 (Hello Modules), we're going to be working with a clean set of project files inside the project directory called `hello-nf-test`.

!!!note

    If you haven't worked through the previous parts of this training course, you should consider doing so now to understand how the code is organized.
    In a nutshell, this is a modularized pipeline; the processes are in local modules and the parameter declarations are in a configuration file.

### 0.1. Explore the `hello-nf-test` directory

Let's move into the project directory.
If you're continuing on directly from Part 6, you'll need to move up one directory first.

```bash
cd hello-nf-test
```

The `hello-nf-test` directory has the same content and structure that you're expected to end up with in `hello-modules` on completion of Part 6.

```console title="Directory contents"
hello-nf-test/
├── demo-params.json
├── main.nf
├── modules
└── nextflow.config
```

For a detailed description of the files, see the warmup section in Part 6.
For details about the contents of the `modules` directory, read through all of Part 6 (it's pretty short).

### 0.2. Create a symbolic link to the data

Just like last time, we need to set up a symlink to the data.
To do so, run this command from inside the `hello-nf-test` directory:

```bash
ln -s ../data data
```

This creates a symbolic link called `data` pointing to the data directory one level up.

### 0.3 Run the workflow using the appropriate profiles

Now that everything is in place, we should be able to run the workflow using the profiles we originally set up in Part 5 (Hello Config).

```bash
nextflow run main.nf -profile my_laptop,demo
```

This should look very familiar by now if you've been working through this training course from the start.

```console title="Output"
 N E X T F L O W   ~  version 24.10.0

 ┃ Launching `main.nf` [special_brenner] DSL2 - revision: 5a07b4894b

executor >  local (7)
[26/60774a] SAMTOOLS_INDEX (1)       | 3 of 3 ✔
[5a/eb40c4] GATK_HAPLOTYPECALLER (2) | 3 of 3 ✔
[8f/94ac86] GATK_JOINTGENOTYPING     | 1 of 1 ✔
```

As expected, it all worked.

Like previously, there will now be a `work` directory and a `results_genomics` directory inside your project directory.
However, we are going to ignore them entirely, because we are no longer going to touch the pipeline itself, and we're not even going to interact directly with Nextflow as such.

Instead, we are going to interact with the `nf-test` package.

### 0.4. Initialize `nf-test`

The `nf-test` package provides an initialization command that sets up a few things in order for us to start developing tests for our project.

```bash
nf-test init
```

This should produce the following output:

```bash
🚀 nf-test 0.9.1
https://www.nf-test.com
(c) 2021 - 2024 Lukas Forer and Sebastian Schoenherr

Project configured. Configuration is stored in nf-test.config
```

It also creates a `tests` directory containing a configuration file stub.

### Takeaway

You know how to initialize `nf-test` in preparation for developing tests.

### What's next?

Learn how to write basic tests that evaluate whether the process calls were successful and produced the correct outputs.

---

## 1. Test a process for success and matching outputs

We're going to start by adding a test for the `SAMTOOLS_INDEX` process.
It's a very simple process that takes a single input file (for which we have test data on hand) and generates an index file.
We want to test that the process runs successfully and that the file it produces is always the same for a given input.

### 1.1. Generate a test file stub

First, we use the `nf-test generate process` command to create a test file stub.

```bash
nf-test generate process modules/local/samtools/index/main.nf
```

This creates a file in the same directory as `main.nf`, summarized in the terminal output as follows:

```console title="Output"
Load source file '/workspace/gitpod/hello-nextflow/hello-nf-test/modules/local/samtools/index/main.nf'
Wrote process test file '/workspace/gitpod/hello-nextflow/tests/hello-nf-test/modules/local/samtools/index/main.nf.test

SUCCESS: Generated 1 test files.
```

You can navigate to the directory in the file explorer and open the file, which should contain the following code:

```groovy title="tests/modules/local/samtools/index/main.nf.test" linenums="1"
nextflow_process {

    name "Test Process SAMTOOLS_INDEX"
    script "modules/local/samtools/index/main.nf"
    process "SAMTOOLS_INDEX"

    test("Should run without failures") {

        when {
            params {
                // define parameters here. Example:
                // outdir = "tests/results"
            }
            process {
                """
                // define inputs of the process here. Example:
                // input[0] = file("test-file.txt")
                """
            }
        }

        then {
            assert process.success
            assert snapshot(process.out).match()
        }

    }

}
```

In plain English, the logic of the test reads as follows:
"**When** these _parameters_ are provided to this _process_, **then** we expect to see these results."

The expected results are formulated as `assert` statements.

-   `assert process.success` states that we expect the process to run successfully and complete without any failures.
-   `snapshot(process.out).match()` states that we expect the result of the run to be identical to the result obtained in a previous run (if applicable).
    We discuss this in more detail later.

For most real-world modules (which usually require some kind of input), this is not yet a functional test.
We need to add the inputs that will be fed to the process, and any parameters if applicable.

### 1.2. Move the test file and update the script path

Before we get to work on filling out the test, we need to move the file to its definitive location.
The preferred convention is to ship tests in a `tests` directory co-located with each module's `main.nf` file, so we create a `tests/` directory in the module's directory:

```bash
mkdir -p modules/local/samtools/index/tests
```

Then we move the test file there:

```bash
mv tests/modules/local/samtools/index/main.nf.test modules/local/samtools/index/tests/
```

As a result, we can update the full path in the `script` section of the test file to a relative path:

_Before:_

```groovy title="modules/local/samtools/index/tests/main.nf.test" linenums="3"
name "Test Process SAMTOOLS_INDEX"
script "modules/local/samtools/index/main.nf"
process "SAMTOOLS_INDEX"
```

_After:_

```groovy title="modules/local/samtools/index/tests/main.nf.test" linenums="3"
name "Test Process SAMTOOLS_INDEX"
script "../main.nf"
process "SAMTOOLS_INDEX"
```

### 1.3. Provide inputs to the test process

The stub file includes a placeholder that we need to replace with an actual test input:

_Before:_

```groovy title="modules/local/samtools/index/tests/main.nf.test" linenums="14"
process {
    """
    // define inputs of the process here. Example:
    // input[0] = file("test-file.txt")
    """
}
```

We choose one of our available data files and plug it into the `process` block:

_After:_

```groovy title="modules/local/samtools/index/tests/main.nf.test" linenums="14"
process {
    """
    input[0] = file("${projectDir}/data/bam/reads_son.bam")
    """
}
```

### 1.4. Rename the test based on the primary test input

The stub file gives the test a generic name referring to the assertion that it should run without failures.
Since we added a specific input, it's good practice to rename the test accordingly.

_Before:_

```groovy title="modules/local/samtools/index/tests/main.nf.test" linenums="7"
test("Should run without failures") {
```

This takes an arbitrary string, so we could put anything we want.
Here we choose to refer to the file name and its format:

_After:_

```groovy title="modules/local/samtools/index/tests/main.nf.test" linenums="7"
test("reads_son [bam]") {
```

### 1.5. Specify test parameters

The `params` block in the stub file includes a placeholder for parameters:

_Before:_

```groovy title="modules/local/samtools/index/tests/main.nf.test" linenums="11"
params {
    // define parameters here. Example:
    // outdir = "tests/results"
}
```

We use it to specify a location for the results to be output, using the default suggestion:

_After:_

```groovy title="modules/local/samtools/index/tests/main.nf.test" linenums="11"
params {
    outdir = "tests/results"
}
```

### 1.6. Run the test and examine the output

Finally, it's time to run our test! Let's break down the syntax.

-   The basic command is `nf-test test`.
-   To that, we add `--profile docker_on` to specify that we want Nextflow to run the test with Docker enabled.
-   Then the test file that we want to run.

!!!note

    The `--profile` parameter is technically optional in the sense that nf-test does not require it.
    There is a `nextflow.config` file in the `nf-test` directory where we could write `docker.enable = on` to have Docker enabled by default.
    However, it's good practice to test your modules explicitly (and separately) with every packaging system they support.
    This allows you to detect issues that might arise when the module no longer works with Docker but still works with Conda, for example.

    Note also the TWO dashes, `--`, because here it's a parameter of the `nf-test test` command, which passes the instruction on to Nextflow itself.

All put together, it looks like this:

```bash
nf-test test --profile docker_on modules/local/samtools/index/tests/main.nf.test
```

This should produce the following output:

```console title="Output"
🚀 nf-test 0.9.1
https://www.nf-test.com
(c) 2021 - 2024 Lukas Forer and Sebastian Schoenherr


Test Process SAMTOOLS_INDEX

  Test [f2eed6af] 'reads_son [bam]' PASSED (9.01s)
  Snapshots:
    1 created [reads_son [bam]]


Snapshot Summary:
  1 created

SUCCESS: Executed 1 tests in 9.062s
```

The test verified the first assertion, that the process should complete successfully.

Additionally, this also produces a snapshot file called `main.nf.test.snap` that captures all the output channels and the MD5SUMs of all elements.

If we re-run the test, the program will check that the new output matches the output that was originally recorded.

!!!warning

    That means we have to be sure that the output we record in the original run is correct!

If, in the course of future development, something in the code changes that causes the output to be different, the test will fail and we will have to determine whether the change is expected or not.

-   If it turns out that something in the code broke, we will have to fix it, with the expectation that the fixed code will pass the test.
-   If it is an expected change (e.g., the tool has been improved and the results are better) then we will need to update the snapshot to accept the new output as the reference to match, using the parameter `--update-snapshot` when we run the test command.

### 1.7. Add more tests to `SAMTOOLS_INDEX`

Sometimes it's useful to test a range of different input files to ensure we're testing for a variety of potential issues.

We can add as many tests as we want inside the same test file for a module.

Try adding the following tests to the module's test file:

```groovy title="modules/local/samtools/index/tests/main.nf.test" linenums="27"
test("reads_mother [bam]") {

    when {
        params {
            outdir = "tests/results"
        }
        process {
            """
            input[0] = file("${projectDir}/data/bam/reads_mother.bam")
            """
        }
    }

    then {
        assert process.success
        assert snapshot(process.out).match()
    }

}
```

And:

```groovy title="modules/local/samtools/index/tests/main.nf.test" linenums="47"
test("reads_father [bam]") {

    when {
        params {
            outdir = "tests/results"
        }
        process {
            """
            input[0] = file("${projectDir}/data/bam/reads_father.bam")
            """
        }
    }

    then {
        assert process.success
        assert snapshot(process.out).match()
    }

}
```

These simply go one after another in the test file.

!!! warning

    Watch out for those curly braces, make sure they're all paired up appropriately...

### 1.8. Run the test suite and update the snapshot

```bash
nf-test test --profile docker_on modules/local/samtools/index/tests/main.nf.test --update-snapshot
```

This should produce the following output:

```console title="Output"
🚀 nf-test 0.9.1
https://www.nf-test.com
(c) 2021 - 2024 Lukas Forer and Sebastian Schoenherr

Warning: every snapshot that fails during this test run is re-record.

Test Process SAMTOOLS_INDEX

  Test [bc664c47] 'reads_son [bam]' PASSED (9.6s)
  Test [f413ec92] 'reads_mother [bam]' PASSED (9.138s)
  Test [99a73481] 'reads_father [bam]' PASSED (9.536s)


SUCCESS: Executed 3 tests in 28.281s
```

Notice the warning, referring to the effect of the `--update-snapshot` parameter.

!!!note

    Here we are using test data that we used previously to demonstrate the scientific outputs of the pipeline.
    If we had been planning to operate these tests in a production environment, we would have generated smaller inputs for testing purposes.

    In general it's important to keep unit tests as light as possible by using the smallest pieces of data necessary and sufficient for evaluating process functionality, otherwise the total runtime can add up quite seriously.
    A test suite that takes too long to run regularly is a test suite that's likely to get skipped in the interest of expediency.

### Takeaway

You know how to write basic tests that evaluate success and whether outputs match reference outputs exactly.

### What's next?

Learn how to write tests for chained processes, and to evaluate whether outputs contain specific lines.

---

## 2. Add tests to a chained process and test for contents

Now that we know how to handle the simplest case, we're going to kick things up a notch with the `GATK_HAPLOTYPECALLER` process.

As the second step in our pipeline, its input depends on the output of another process.
We can deal with this in two ways:

-   Manually generate some static test data that is suitable as intermediate input to the process;
-   Use a special [setup method](https://www.nf-test.com/docs/testcases/setup/) to handle it dynamically for us.

**Spoiler:** We're going to use the setup method.

### 2.1. Generate the test file stub

As previously, first we generate the file stub:

```bash
nf-test generate process modules/local/gatk/haplotypecaller/main.nf
```

This produces the following test stub:

```groovy title="tests/modules/local/gatk/haplotypecaller/main.nf.test" linenums="1"
nextflow_process {

    name "Test Process GATK_HAPLOTYPECALLER"
    script "modules/local/gatk/haplotypecaller/main.nf"
    process "GATK_HAPLOTYPECALLER"

    test("Should run without failures") {

        when {
            params {
                // define parameters here. Example:
                // outdir = "tests/results"
            }
            process {
                """
                // define inputs of the process here. Example:
                // input[0] = file("test-file.txt")
                """
            }
        }

        then {
            assert process.success
            assert snapshot(process.out).match()
        }

    }

}
```

### 2.2. Move the test file and update the script path

We create a directory for the test file co-located with the module's `main.nf` file:

```bash
mkdir -p modules/local/gatk/haplotypecaller/tests
```

And move the test stub file there:

```bash
mv tests/modules/local/gatk/haplotypecaller/main.nf.test modules/local/gatk/haplotypecaller/tests/
```

Finally, don't forget to update the script path:

_Before:_

```groovy title="modules/local/gatk/haplotypecaller/tests/main.nf.test" linenums="3"
name "Test Process GATK_HAPLOTYPECALLER"
script "modules/local/gatk/haplotypecaller/main.nf"
process "GATK_HAPLOTYPECALLER"
```

_After:_

```groovy title="modules/local/gatk/haplotypecaller/tests/main.nf.test" linenums="3"
name "Test Process GATK_HAPLOTYPECALLER"
script "../main.nf"
process "GATK_HAPLOTYPECALLER"
```

### 2.3. Provide inputs using the setup method

We insert a `setup` block before the `when` block, where we can trigger a run of the `SAMTOOLS_INDEX` process on one of our original input files.

_Before:_

```groovy title="modules/local/gatk/haplotypecaller/tests/main.nf.test" linenums="7"
test("Should run without failures") {

    when {
```

_After:_

```groovy title="modules/local/gatk/haplotypecaller/tests/main.nf.test" linenums="7"
test("reads_son [bam]") {

    setup {
        run("SAMTOOLS_INDEX") {
            script "../../../samtools/index/main.nf"
            process {
                """
                input[0] =  file("${projectDir}/data/bam/reads_son.bam")
                """
            }
        }
    }

    when {
```

Then we can refer to the output of that process in the `when` block where we specify the test inputs:

```groovy title="modules/local/gatk/haplotypecaller/tests/main.nf.test" linenums="20"
    when {
        params {
            outdir = "tests/results"
        }
        process {
            """
            input[0] = SAMTOOLS_INDEX.out
            input[1] = file("${projectDir}/data/ref/ref.fasta")
            input[2] = file("${projectDir}/data/ref/ref.fasta.fai")
            input[3] = file("${projectDir}/data/ref/ref.dict")
            input[4] = file("${projectDir}/data/ref/intervals.bed")
            """
        }
    }
```

Using the setup method is convenient, though you should consider its use carefully.
Module-level tests are supposed to test processes in isolation in order to detect changes at the individual process level; breaking that isolation undermines that principle.

In many cases, it's better to use intermediate test files that you generate manually as part of the preparation.
We'll show you how to do that in the next section.
But we show you the setup method too because sometimes it is useful to be able to test the connection between two modules specifically.

<!-- TODO: consider switching the order of types of tests, might make more sense in terms of flow -->

### 2.4. Run test and examine output

```bash
nf-test test --profile docker_on modules/local/gatk/haplotypecaller/tests/main.nf.test
```

This produces the following output:

```console title="Output"
🚀 nf-test 0.9.1
https://www.nf-test.com
(c) 2021 - 2024 Lukas Forer and Sebastian Schoenherr


Test Process GATK_HAPLOTYPECALLER

  Test [86fd1bce] 'reads_son [bam]' PASSED (19.082s)
  Snapshots:
    1 created [reads_son [bam]]


Snapshot Summary:
  1 created

SUCCESS: Executed 1 tests in 19.09s
```

It also produces a snapshot file like earlier.

### 2.5. Run again and observe failure

Interestingly, if you run the exact same command again, this time the test will fail with the following:

```bash
nf-test test --profile docker_on modules/local/gatk/haplotypecaller/tests/main.nf.test
```

Produces:

```console title="Output"
🚀 nf-test 0.9.1
https://www.nf-test.com
(c) 2021 - 2024 Lukas Forer and Sebastian Schoenherr


Test Process GATK_HAPLOTYPECALLER

  Test [86fd1bce] 'reads_son [bam]' FAILED (23.781s)

  java.lang.RuntimeException: Different Snapshot:
  [                                                                                                     [
      {                                                                                                     {
          "0": [                                                                                                        "0": [
              [                                                                                                     [
                  {                                                                                                     {
                      "id": "reads_son"                                                                                       "id": "reads_son"
                  },                                                                                                    },
                  "reads_son.bam.g.vcf:md5,f3583cbbe439469bfc166612e1617694",                      |                    "reads_son.bam.g.vcf:md5,428f855d616b34d44a4f0a3bcc1a0b14",
                  "reads_son.bam.g.vcf.idx:md5,16a78feaf6602adb2a131494e0274f9e"                           |                    "reads_son.bam.g.vcf.idx:md5,5a8d299625ef3cd3266229507a789dbb"
              ]                                                                                                     ]
          ]                                                                                                     ]
      }                                                                                                     }
  ]                                                                                                     ]

  Nextflow stdout:

  Nextflow stderr:

  Nextflow 24.09.2-edge is available - Please consider updating your version to it


    Obsolete snapshots can only be checked if all tests of a file are executed successful.


FAILURE: Executed 1 tests in 23.79s (1 failed)
```

The error message tells you there were differences between the snapshots for the two runs; specifically, the md5sum values are different for the VCF files.

Why? To make a long story short, the HaplotypeCaller tool includes a timestamp in the VCF header that is different every time (by definition).
As a result, we can't just expect the files to have identical md5sums even if they have identical content in terms of the variant calls themselves.

How do we deal with that?

### 2.6. Use a content assertion method

One way to solve the problem is to use a [different kind of assertion](https://nf-co.re/docs/contributing/tutorials/nf-test_assertions).
In this case, we're going to check for specific content instead of asserting identity.
More exactly, we'll have the tool read the lines of the VCF file and check for the existence of specific lines.

In practice, we replace the second assertion in the `then` block as follows:

_Before:_

```groovy title="modules/local/gatk/haplotypecaller/tests/main.nf.test" linenums="35"
then {
    assert process.success
    assert snapshot(process.out).match()
}
```

_After:_

```console title="modules/local/gatk/haplotypecaller/tests/main.nf.test" linenums="35"
then {
    assert process.success
    assert path(process.out[0][0]).readLines().contains('#CHROM	POS	ID	REF	ALT	QUAL	FILTER	INFO	FORMAT	reads_son')
    assert path(process.out[0][0]).readLines().contains('20_10037292_10066351	3277	.	G	<NON_REF>	.	.	END=3282	GT:DP:GQ:MIN_DP:PL	0/0:25:72:24:0,72,719')
}
```

Here we're reading in the full content of the VCF output file and searching for a content match, which is okay to do on a small test file, but you wouldn't want to do that on a larger file.
You might instead choose to read in specific lines.

This approach does require choosing more carefully what we want to use as the 'signal' to test for.
On the bright side, it can be used to test with great precision whether an analysis tool can consistently identify 'difficult' features (such as rare variants) as it undergoes further development.

### 2.7. Run again and observe success

Once we've modified the test in this way, we can run the test multiple times, and it will consistently pass.

```bash
nf-test test --profile docker_on modules/local/gatk/haplotypecaller/tests/main.nf.test
```

Produces:

```console title="Output"
🚀 nf-test 0.9.1
https://www.nf-test.com
(c) 2021 - 2024 Lukas Forer and Sebastian Schoenherr


Test Process GATK_HAPLOTYPECALLER

  Test [86fd1bce] 'reads_son [bam]' PASSED (19.765s)


SUCCESS: Executed 1 tests in 19.77s
```

### 2.8. Add more test data

To practice writing these kinds of tests, you can repeat the procedure for the other two input data files provided.
You'll need to make sure to copy lines from the corresponding output VCFs.

Test for the 'mother' sample:

```groovy title="modules/local/gatk/haplotypecaller/tests/main.nf.test" linenums="43"
test("reads_mother [bam]") {

    setup {
        run("SAMTOOLS_INDEX") {
            script "../../../samtools/index/main.nf"
            process {
                """
                input[0] =  file("${projectDir}/data/bam/reads_mother.bam")
                """
            }
        }
    }

    when {
        params {
            outdir = "tests/results"
        }
        process {
            """
            input[0] = SAMTOOLS_INDEX.out
            input[1] = file("${projectDir}/data/ref/ref.fasta")
            input[2] = file("${projectDir}/data/ref/ref.fasta.fai")
            input[3] = file("${projectDir}/data/ref/ref.dict")
            input[4] = file("${projectDir}/data/ref/intervals.bed")
            """
        }
    }

    then {
        assert process.success
        assert path(process.out[0][0]).readLines().contains('#CHROM	POS	ID	REF	ALT	QUAL	FILTER	INFO	FORMAT	reads_mother')
        assert path(process.out[0][0]).readLines().contains('20_10037292_10066351	3277	.	G	<NON_REF>	.	.	END=3278	GT:DP:GQ:MIN_DP:PL	0/0:38:99:37:0,102,1530')
    }
}
```

Test for the 'father' sample:

```groovy title="modules/local/gatk/haplotypecaller/tests/main.nf.test" linenums="78"
test("reads_father [bam]") {

    setup {
        run("SAMTOOLS_INDEX") {
            script "../../../samtools/index/main.nf"
            process {
                """
                input[0] =  file("${projectDir}/data/bam/reads_father.bam")
                """
            }
        }
    }

    when {
        params {
            outdir = "tests/results"
        }
        process {
            """
            input[0] = SAMTOOLS_INDEX.out
            input[1] = file("${projectDir}/data/ref/ref.fasta")
            input[2] = file("${projectDir}/data/ref/ref.fasta.fai")
            input[3] = file("${projectDir}/data/ref/ref.dict")
            input[4] = file("${projectDir}/data/ref/intervals.bed")
            """
        }
    }

    then {
        assert process.success
        assert path(process.out[0][0]).readLines().contains('#CHROM	POS	ID	REF	ALT	QUAL	FILTER	INFO	FORMAT	reads_father')
        assert path(process.out[0][0]).readLines().contains('20_10037292_10066351	3277	.	G	<NON_REF>	.	.	END=3281	GT:DP:GQ:MIN_DP:PL	0/0:44:99:42:0,120,1800')
    }
}
```

### 2.9. Run the test command

```bash
nf-test test --profile docker_on modules/local/gatk/haplotypecaller/tests/main.nf.test
```

Produces:

```console title="Output"
🚀 nf-test 0.9.1
https://www.nf-test.com
(c) 2021 - 2024 Lukas Forer and Sebastian Schoenherr


Test Process GATK_HAPLOTYPECALLER

  Test [86fd1bce] 'reads_son [bam]' PASSED (21.639s)
  Test [547788fd] 'reads_mother [bam]' PASSED (18.153s)
  Test [be786719] 'reads_father [bam]' PASSED (18.058s)


SUCCESS: Executed 3 tests in 57.858s
```

That completes the basic test plan for this second step in the pipeline. On to the third and last module-level test!

### Takeaway

You know how to write tests for chained processes, and evaluate whether outputs contain specific lines.

### What's next?

Learn how to write tests that use manually generated intermediate test data.

---

## 3. Use locally stored inputs

For the third step in our pipeline we'll use manually generated intermediate test data that is co-located with the module itself.

We've included a copy of the intermediate files produced by the first part of the pipeline under the `jointgenotyping` module:

```console title="Directory contents"
modules/local/gatk/jointgenotyping/tests/inputs/
├── reads_father.bam.g.vcf
├── reads_father.bam.g.vcf.idx
├── reads_mother.bam.g.vcf
├── reads_mother.bam.g.vcf.idx
├── reads_son.bam.g.vcf
└── reads_son.bam.g.vcf.idx
```

The idea here is to use these files as inputs to the test we're going to write for the joint genotyping step.

### 3.1. Generate the test file stub

As previously, first we generate the file stub:

```bash
nf-test generate process modules/local/gatk/jointgenotyping/main.nf
```

This produces the following test stub:

```groovy title="tests/modules/local/gatk/jointgenotyping/main.nf.test" linenums="1"
nextflow_process {

    name "Test Process GATK_JOINTGENOTYPING"
    script "modules/local/gatk/jointgenotyping/main.nf"
    process "GATK_JOINTGENOTYPING"

    test("Should run without failures") {

        when {
            params {
                // define parameters here. Example:
                // outdir = "tests/results"
            }
            process {
                """
                // define inputs of the process here. Example:
                // input[0] = file("test-file.txt")
                """
            }
        }

        then {
            assert process.success
            assert snapshot(process.out).match()
        }

    }

}
```

### 3.2. Move the test file and update the script path

This time we already have a directory for tests co-located with the module's `main.nf` file, so we can move the test stub file there:

```bash
mv tests/modules/local/gatk/jointgenotyping/main.nf.test modules/local/gatk/jointgenotyping/tests/
```

And don't forget to update the script path:

_Before:_

```groovy title="modules/local/gatk/jointgenotyping/tests/main.nf.test" linenums="3"
name "Test Process GATK_JOINTGENOTYPING"
script "modules/local/gatk/jointgenotyping/main.nf"
process "GATK_JOINTGENOTYPING"
```

_After:_

```groovy title="modules/local/gatk/jointgenotyping/tests/main.nf.test" linenums="3"
name "Test Process GATK_JOINTGENOTYPING"
script "../main.nf"
process "GATK_JOINTGENOTYPING"
```

### 3.3. Provide inputs

Fill in the inputs based on the process input definitions and rename the test accordingly:

```groovy title="modules/local/gatk/jointgenotyping/tests/main.nf.test" linenums="7"
test("family_trio [vcf] [idx]") {

    when {
        params {
            outdir = "tests/results"
        }
        process {
            """
            input[0] = [
                file("${projectDir}/modules/local/gatk/jointgenotyping/tests/inputs/reads_father.bam.g.vcf"),
                file("${projectDir}/modules/local/gatk/jointgenotyping/tests/inputs/reads_mother.bam.g.vcf"),
                file("${projectDir}/modules/local/gatk/jointgenotyping/tests/inputs/reads_son.bam.g.vcf")
            ]
            input[1] = [
                file("${projectDir}/modules/local/gatk/jointgenotyping/tests/inputs/reads_father.bam.g.vcf.idx"),
                file("${projectDir}/modules/local/gatk/jointgenotyping/tests/inputs/reads_mother.bam.g.vcf.idx"),
                file("${projectDir}/modules/local/gatk/jointgenotyping/tests/inputs/reads_son.bam.g.vcf.idx")
            ]
            input[2] = file("${projectDir}/data/ref/intervals.bed")
            input[3] = "family_trio"
            input[4] = file("${projectDir}/data/ref/ref.fasta")
            input[5] = file("${projectDir}/data/ref/ref.fasta.fai")
            input[6] = file("${projectDir}/data/ref/ref.dict")
            """
        }
    }
```

### 3.4. Use content assertions

The output of the joint genotyping step is another VCF file, so we're going to use a content assertion again.

```groovy title="modules/local/gatk/jointgenotyping/tests/main.nf.test" linenums="25"
then {
    assert process.success
    assert path(process.out[0][0]).readLines().contains('#CHROM	POS	ID	REF	ALT	QUAL	FILTER	INFO	FORMAT	reads_father	reads_mother	reads_son')
    assert path(process.out[0][0]).readLines().contains('20_10037292_10066351	3480	.	C	CT	1625.89	.	AC=5;AF=0.833;AN=6;BaseQRankSum=0.220;DP=85;ExcessHet=0.0000;FS=2.476;MLEAC=5;MLEAF=0.833;MQ=60.00;MQRankSum=0.00;QD=21.68;ReadPosRankSum=-1.147e+00;SOR=0.487	GT:AD:DP:GQ:PL	0/1:15,16:31:99:367,0,375	1/1:0,18:18:54:517,54,0	1/1:0,26:26:78:756,78,0')
}
```

### 3.5. Run the test

```bash
nf-test test --profile docker_on modules/local/gatk/jointgenotyping/tests/main.nf.test
```

Produces:

```console title="Output"
🚀 nf-test 0.9.1
https://www.nf-test.com
(c) 2021 - 2024 Lukas Forer and Sebastian Schoenherr


Test Process GATK_JOINTGENOTYPING

  Test [24c3cb4b] 'family_trio [vcf] [idx]' PASSED (14.881s)


SUCCESS: Executed 1 tests in 14.885s
```

It works! And that's it for module-level tests for our pipeline.

### Takeaway

You know how to write tests for using inputs that have been previously generated and are co-located with the module code.

### What's next?

Learn how to write a workflow-level test.

---

## 4. Add a workflow-level test

Now all that remains is to add a test for checking that the whole pipeline runs to completion.

### 4.1. Generate pipeline-level stub test file

The command is similar to the one for module tests, except it says `generate pipeline` instead of `generate process`:

```bash
nf-test generate pipeline main.nf
```

It produces a similar stub file:

```groovy title="tests/main.nf.test" linenums="1"
nextflow_pipeline {

    name "Test Workflow main.nf"
    script "main.nf"

    test("Should run without failures") {

        when {
            params {
                // define parameters here. Example:
                // outdir = "tests/results"
            }
        }

        then {
            assert workflow.success
        }

    }

}
```

The line `assert workflow.success` is a simple assertion testing for whether the pipeline ran successfully.

!!!note

    In this case the test file can stay where `nf-test` created it.

### 4.2. Specify input parameters

We still need to specify inputs.
There are several ways of doing this, including by specifying a profile.
However, a simpler way is to set up a `params {}` block in the `nextflow.config` file that `nf-test init` originally created in the `tests` directory.

```groovy title="tests/nextflow.config" linenums="1"
/*
 * Pipeline parameters
 */

params {
    // Primary input (file of input files, one per line)
    reads_bam        = "${projectDir}/data/sample_bams.txt"

    // Output directory
    params.outdir = "results_genomics"

    // Accessory files
    reference        = "${projectDir}/data/ref/ref.fasta"
    reference_index  = "${projectDir}/data/ref/ref.fasta.fai"
    reference_dict   = "${projectDir}/data/ref/ref.dict"
    intervals        = "${projectDir}/data/ref/intervals.bed"

    // Base name for final output file
    cohort_name      = "family_trio"
}
```

When we run the test, `nf-test` will pick up this configuration file and pull in the inputs accordingly.

### 4.3. Run the test

Here we go!

```bash
nf-test test --profile docker_on tests/main.nf.test
```

This produces:

```console title="Output"
🚀 nf-test 0.9.1
https://www.nf-test.com
(c) 2021 - 2024 Lukas Forer and Sebastian Schoenherr


Test Workflow hello-nf-test.nf

  Test [df3a3a8c] 'Should run without failures' PASSED (62.493s)


SUCCESS: Executed 1 tests in 62.498s
```

That's it! If necessary, more nuanced assertions can be added to test for the validity and content of the pipeline outputs.
You can learn more about the different kinds of assertions you can use in the [nf-test documentation](https://www.nf-test.com/docs/assertions/assertions/).

### 4.3. Run ALL the tests!

nf-test has one more trick up it's sleeve. We can run all the tests at once! Modify the `nf-test.config` file so that nf-test looks in every directory for nf-test files. You can do this by modifying the `testsDir` parameter:

_Before:_

```groovy title="tests/nf-test.config" linenums="1"
config {

    testsDir "tests"
    workDir ".nf-test"
    configFile "tests/nextflow.config"
    profile ""

}
```

_After:_

```groovy title="tests/nf-test.config" linenums="1"
config {

    testsDir "."
    workDir ".nf-test"
    configFile "tests/nextflow.config"
    profile ""

}
```

Now, we can simply run nf-test and it will run _every single test_ in our repository:

```bash
nf-test test --profile docker_on
```

```console title="Output"
gitpod /workspaces/hello-nextflow/hello-nf-test (master) $ nf-test test --profile docker_on

🚀 nf-test 0.9.2
https://www.nf-test.com
(c) 2021 - 2024 Lukas Forer and Sebastian Schoenherr


Test Process GATK_HAPLOTYPECALLER

  Test [91903020] 'reads_son [bam]' PASSED (9.392s)
  Test [6dd10adf] 'reads_mother [bam]' PASSED (9.508s)
  Test [2d01c506] 'reads_father [bam]' PASSED (9.209s)

Test Process GATK_JOINTGENOTYPING

  Test [fd98ae7b] 'family_trio [vcf] [idx]' PASSED (10.537s)

Test Process SAMTOOLS_INDEX

  Test [e8dbf1c1] 'reads_son [bam]' PASSED (4.504s)
  Test [5e05ca64] 'reads_mother [bam]' PASSED (4.37s)
  Test [254f67ac] 'reads_father [bam]' PASSED (4.717s)

Test Workflow main.nf

  Test [6fa6c90c] 'Should run without failures' PASSED (23.872s)


SUCCESS: Executed 8 tests in 76.154s
```

7 tests in 1 command! We spent a long time configuring lots and lots of tests, but when it came to running them it was very quick and easy. You can see how useful this is when maintaining a large pipeline, which could include hundreds of different elements. We spend time writing tests once so we can save time running them many times.

Furthermore, we can automate this! imagine tests running every time you or a colleague tries to add new code. This is how we ensure our pipelines maintain a high standard.

### Takeaway

You know how to write and run several kinds of tests for individual modules and for the entire workflow.

### What's next?

Celebrate and take a big break! Next up, we delve into the cornucopia of code and tools that is the nf-core project.
