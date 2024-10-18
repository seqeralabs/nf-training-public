# Part 4: Hello nf-test

It is critical for reproducibility and long-term maintenance to have a way to systematically test that every part of your workflow is doing what it's supposed to do. To that end, people often focus on top-level tests, in which the workflow is run on some test data from start to finish. This is useful but unfortunately incomplete. You should also implement module-level tests (equivalent to what is called 'unit tests' in general software engineering) to verify the functionality of individual components of your workflow, ensuring that each module performs as expected under different conditions and inputs.

The [nf-test](https://www.nf-test.com/) package provides a testing framework that integrates well with Nextflow and makes it straightforward to add both module-level and workflow-level tests to your pipeline. For more background information, read the [blog post about nf-test](https://nextflow.io/blog/2024/nf-test-in-nf-core.html) on the Nextflow blog.

Note: This part of the training was developed in collaboration with Sateesh Peri, who implemented all the tests.

---

## 0. Warmup

We start from a base workflow called `hello-nf-test.nf`, which corresponds to the workflow we produced in Part 3: Hello modules (equivalent to `scripts/hello-modules-3.nf`).

This is a modularized pipeline; the processes are in local modules and the parameter declarations are in a configuration file. If you completed the previous parts of the training course, then you already have everything you need in the working directory. However, if you're just starting from this section, you need to copy the `nextflow.config` file and the `modules` folder from `scripts/` to the `hello-nextflow` directory.

```
cd /workspace/gitpod/hello-nextflow
cp scripts/nextflow.config .
cp -r scripts/modules .
```

You also need to unzip the reference data files:

```
tar -zxvf data/ref.tar.gz -C data/
```

### 0.1 Run the workflow to verify that it produces the expected outputs

```bash
nextflow run hello-nf-test.nf
```

The pipeline takes in three BAM files, each one containing sequencing data for one of three samples from a human family trio (mother, father and son), and outputs a VCF file containing variant calls. For more details, see the previous section of this training.

### 0.2 Initialize nf-test

Run the following command in the terminal:

```bash
nf-test init
```

This should produce the following output:

```bash
🚀 nf-test 0.9.0
https://www.nf-test.com
(c) 2021 - 2024 Lukas Forer and Sebastian Schoenherr

Project configured. Configuration is stored in nf-test.config
```

It also creates a `tests` directory containing a configuration file stub.

---

## 1. Test a process for success and matching outputs

We're going to start by adding a test for the `SAMTOOLS_INDEX` process. It's a very simple process that takes a single input file (which we have test data for on hand) and generates an index file. We want to test that the process runs successfully and that the file it produces is always the same for a given input.

### 1.1 Generate a test file stub

```bash
nf-test generate process modules/local/samtools/index/main.nf
```

This creates a test file stub created in same directory as `main.nf`, summarized in the terminal output as follows:

```bash
Load source file '/workspace/gitpod/hello-nextflow/modules/local/samtools/index/main.nf'
Wrote process test file '/workspace/gitpod/hello-nextflow/tests/modules/local/samtools/index/main.nf.test

SUCCESS: Generated 1 test files.
```

You can navigate to the directory in the file explorer and open the file, which should contain the following code:

```groovy title="tests/modules/local/samtools/index/main.nf.test"
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

In plain English, the logic of the test reads as follows: "**When** these _parameters_ are provided to this _process_, **then** we expect to see these results."

The expected results are formulated as `assert` statements. The first, `assert process.success`, simply states that we expect the process to run successfully and complete without any failures. The second, `snapshot(process.out).match()`, says that we expect the result of the run to be identical to the result obtained in a previous run (if applicable). We discuss this in more detail later.

For most real-world modules (which usually require some kind of input), this is not yet a functional test. We need to add the inputs that will be fed to the process, and any parameters if applicable.

### 1.2 Move the test file and update the script path

Before we get to work on filling out the test, we need to move the file to its definitive location. The preferred convention is to ship tests in a `tests` directory co-located with each module's `main.nf` file, so we create a `tests/` directory in the module's directory:

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

### 1.3 Provide inputs to the test process

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
    input[0] = [ [id: 'NA12882' ], file("${projectDir}/data/bam/reads_son.bam") ]
    """
}
```

### 1.4 Rename the test based on the primary test input

The stub file gives the test a generic name referring to the assertion that it should run without failures. Since we added a specific input, it's good practice to rename the test accordingly.

_Before:_

```groovy title="modules/local/samtools/index/tests/main.nf.test" linenums="7"
test("Should run without failures") {
```

This takes an arbitrary string, so we could put anything we want. Here we choose to refer to the file name and its format:

_After:_

```groovy title="modules/local/samtools/index/tests/main.nf.test" linenums="7"
test("reads_son [bam]") {
```

### 1.5 Specify test parameters

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

### 1.6 Run the test and examine the output

```bash
nf-test test modules/local/samtools/index/tests/main.nf.test
```

This should produce the following output:

```bash
🚀 nf-test 0.9.0
https://www.nf-test.com
(c) 2021 - 2024 Lukas Forer and Sebastian Schoenherr


Test Process SAMTOOLS_INDEX

  Test [bc664c47] 'reads_son [bam]' PASSED (5.928s)
  Snapshots:
    1 created [reads_son [bam]]


Snapshot Summary:
  1 created

SUCCESS: Executed 1 tests in 5.935s
```

!!! note

    If you get a `java.nio.file.AccessDeniedException` error, remove the work directory with
    ```
    sudo rm -rf work/
    ```
    and run the test again.

The test verified the first assertion, that the process should complete successfully.

Additionally, this also produces a snapshot file called `main.nf.test.snap` that captures all the output channels and the MD5SUMs of all elements.

If we re-run the test, the program will check that the new output matches the output that was originally recorded.

!!! note

    That does mean that we have to be sure that the output we record in the original run is correct.

If, in the course of future development, something in the code changes that causes the output to be different, the test will fail and we will have to determine whether the change is expected or not. If it turns out that something in the code broke, we will have to fix it, with the expectation that the fixed code will pass the test. If it is an expected change (e.g., the tool has been improved and the results are better) then we will need to update the snapshot to accept the new output as the reference to match, using the parameter `--update-snapshot` when we run the test command.

### 1.7 Add more tests to `SAMTOOLS_INDEX`

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
            input[0] = [ [id: 'NA12878' ], file("${projectDir}/data/bam/reads_mother.bam") ]
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
            input[0] = [ [id: 'NA12877' ], file("${projectDir}/data/bam/reads_father.bam") ]
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

    Watch those curly braces, make sure they're all paired up appropriately...

### 1.8 Run the test suite and update the snapshot

```bash
nf-test test modules/local/samtools/index/tests/main.nf.test --update-snapshot
```

This should produce the following output:

```bash
🚀 nf-test 0.9.0
https://www.nf-test.com
(c) 2021 - 2024 Lukas Forer and Sebastian Schoenherr

Warning: every snapshot that fails during this test run is re-record.

Test Process SAMTOOLS_INDEX

  Test [bc664c47] 'reads_son [bam]' PASSED (5.917s)
  Test [f413ec92] 'reads_mother [bam]' PASSED (5.448s)
  Test [99a73481] 'reads_father [bam]' PASSED (5.872s)
  Snapshots:
    2 created [reads_father [bam], reads_mother [bam]]


Snapshot Summary:
  2 created

SUCCESS: Executed 3 tests in 17.248s
```

Notice the warning, referring to the effect of the `--update-snapshot` parameter.

Note: Here we are using test data that we used previously to demonstrate the scientific outputs of the pipeline. If we had been planning to operate these tests in a production environment, we would have generated smaller inputs for testing purposes. In general it's important to keep unit tests as light as possible by using the smallest pieces of data necessary and sufficient for evaluating process functionality, otherwise the total runtime can add up quite seriously. A test suite that takes too long to run regularly is a test suite that's likely to get skipped in the interest of convenience.

---

## 2. Add tests to a chained process and test for contents

Now that we know how to handle the simplest case, we're going to kick things up a notch with the `GATK_HAPLOTYPECALLER` process. As the second step in our pipeline, its input depends on the output of another process. We can deal with this in two ways: either manually generate some static test data that is suitable as intermediate input to the process, or we can use a special [setup method](https://www.nf-test.com/docs/testcases/setup/) to handle it dynamically for us.

**Spoiler:** We're going to use the setup method.

### 2.1 Generate the test file stub

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

### 2.2 Move the test file and update the script path

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

### 2.3 Provide inputs using the setup method

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
                input[0] =  [ [id: 'NA12882' ], file("${projectDir}/data/bam/reads_son.bam") ]
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

Using the setup method is convenient, though you should consider its use carefully. Module-level tests are supposed to test processes in isolation in order to detect changes at the individual process level; breaking that isolation undermines that principle. You may find that generating intermediate test files is the right thing to do in many cases. But it's important to know that you can use this setup method if you need to.

### 2.4 Run test and examine output

```bash
nf-test test modules/local/gatk/haplotypecaller/tests/main.nf.test
```

This produces the following output:

```bash
🚀 nf-test 0.9.0
https://www.nf-test.com
(c) 2021 - 2024 Lukas Forer and Sebastian Schoenherr


Test Process GATK_HAPLOTYPECALLER

  Test [86fd1bce] 'reads_son [bam]' PASSED (11.073s)
  Snapshots:
    1 created [reads_son [bam]]


Snapshot Summary:
  1 created

SUCCESS: Executed 1 tests in 11.084s
```

It also produces a snapshot file like earlier.

### 2.5 Run again and observe failure

Interestingly, if you run the exact same command again, this time the test will fail with the following:

```bash
nf-test test modules/local/gatk/haplotypecaller/tests/main.nf.test
```

Produces:

```bash
🚀 nf-test 0.9.0
https://www.nf-test.com
(c) 2021 - 2024 Lukas Forer and Sebastian Schoenherr


Test Process GATK_HAPLOTYPECALLER

  Test [86fd1bce] 'reads_son [bam]' FAILED (15.209s)

  java.lang.RuntimeException: Different Snapshot:
  [                                                                                                     [
      {                                                                                                     {
          "0": [                                                                                                        "0": [
              [                                                                                                     [
                  {                                                                                                     {
                      "id": "NA12882"                                                                                       "id": "NA12882"
                  },                                                                                                    },
                  "reads_son.bam.g.vcf:md5,1715fa260695fe0bde5af5641d962053",                      |                    "reads_son.bam.g.vcf:md5,aa0cb4c2c28d8adcdeeda9323bac5b24",
                  "reads_son.bam.g.vcf.idx:md5,dbb55a1e7b40340a46f57dd76ef537aa"                           |                    "reads_son.bam.g.vcf.idx:md5,b7c53459ecb4ba757fe84f33f1f9f7ca"
              ]                                                                                                     ]
          ]                                                                                                     ]
      }                                                                                                     }
  ]                                                                                                     ]

  Nextflow stdout:

  Nextflow stderr:

  Nextflow 24.09.2-edge is available - Please consider updating your version to it


    Obsolete snapshots can only be checked if all tests of a file are executed successful.


FAILURE: Executed 1 tests in 15.223s (1 failed)
```

The error message tells you there were differences between the snapshots for the two runs; specifically, the md5sum values are different for the VCF files.

Why? To make a long story short, the HaplotypeCaller tool includes a timestamp in the VCF header that is different every time (by definition), so we can't just expect the files to have identical md5sums even if they have identical content in terms of the variant calls themselves.

### 2.6 Use a content assertion method

One way to solve the problem is to use a [different kind of assertion](https://nf-co.re/docs/contributing/tutorials/nf-test_assertions). In this case, we're going to check for specific content instead of asserting identity. More exactly, we'll have the tool read the lines of the VCF file and check for the existence of specific lines.

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
    assert path(process.out[0][0][1]).readLines().contains('#CHROM	POS	ID	REF	ALT	QUAL	FILTER	INFO	FORMAT	reads_son')
    assert path(process.out[0][0][1]).readLines().contains('20_10037292_10066351	3277	.	G	<NON_REF>	.	.	END=3282	GT:DP:GQ:MIN_DP:PL	0/0:25:72:24:0,72,719')
}
```

Here we're reading in the full content of the VCF output file and searching for a content match, which is okay to do on a small test file, but you wouldn't want to do that on a larger file. You might instead choose to read in specific lines.

This approach does require choosing more carefully what we want to use as the 'signal' to test for. On the bright side, it can be used to test with great precision whether an analysis tool can consistently identify 'difficult' features (such as rare variants) as it undergoes further development.

### 2.7 Run again and observe success

Once we've modified the test in this way, we can run the test multiple times, and it will consistently pass.

```bash
nf-test test modules/local/gatk/haplotypecaller/tests/main.nf.test
```

Produces:

```bash
🚀 nf-test 0.9.0
https://www.nf-test.com
(c) 2021 - 2024 Lukas Forer and Sebastian Schoenherr


Test Process GATK_HAPLOTYPECALLER

  Test [86fd1bce] 'reads_son [bam]' PASSED (20.804s)


SUCCESS: Executed 1 tests in 20.874s
```

### 2.8 Add more test data

To practice writing these kinds of tests, you can repeat the procedure for the other two input data files provided. You'll need to make sure to copy lines from the corresponding output VCFs.

Test for the 'mother' sample:

```groovy title="modules/local/gatk/haplotypecaller/tests/main.nf.test" linenums="43"
test("reads_mother [bam]") {

    setup {
        run("SAMTOOLS_INDEX") {
            script "../../../samtools/index/main.nf"
            process {
                """
                input[0] =  [ [id: 'NA12882' ], file("${projectDir}/data/bam/reads_mother.bam") ]
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
        assert path(process.out[0][0][1]).readLines().contains('#CHROM	POS	ID	REF	ALT	QUAL	FILTER	INFO	FORMAT	reads_mother')
        assert path(process.out[0][0][1]).readLines().contains('20_10037292_10066351	3277	.	G	<NON_REF>	.	.	END=3278	GT:DP:GQ:MIN_DP:PL	0/0:38:99:37:0,102,1530')
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
                input[0] =  [ [id: 'NA12882' ], file("${projectDir}/data/bam/reads_father.bam") ]
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
        assert path(process.out[0][0][1]).readLines().contains('#CHROM	POS	ID	REF	ALT	QUAL	FILTER	INFO	FORMAT	reads_father')
        assert path(process.out[0][0][1]).readLines().contains('20_10037292_10066351	3277	.	G	<NON_REF>	.	.	END=3281	GT:DP:GQ:MIN_DP:PL	0/0:44:99:42:0,120,1800')
    }
}
```

### 2.9 Run the test command

```bash
nf-test test modules/local/gatk/haplotypecaller/tests/main.nf.test
```

Produces:

```bash
🚀 nf-test 0.9.0
https://www.nf-test.com
(c) 2021 - 2024 Lukas Forer and Sebastian Schoenherr


Test Process GATK_HAPLOTYPECALLER

  Test [86fd1bce] 'reads_son [bam]' PASSED (10.826s)
  Test [547788fd] 'reads_mother [bam]' PASSED (10.999s)
  Test [be786719] 'reads_father [bam]' PASSED (10.799s)


SUCCESS: Executed 3 tests in 32.657s
```

That completes the basic test plan for this second step in the pipeline. On to the third and last!

---

## 3. Use locally stored inputs

For the third step in our pipeline we'll simply use manually generated intermediate test data, stored with the module itself.

We've included a copy of the intermediate files produced by the first part of the pipeline under the `jointgenotyping` module in the pre-finished `scripts` directory.

```bash
cp -r scripts/modules/local/gatk/jointgenotyping/tests modules/local/gatk/jointgenotyping/.
```

This should be the result:

```bash
modules/local/gatk/jointgenotyping/tests/inputs/
├── family_trio_map.tsv
├── reads_father.bam.g.vcf
├── reads_father.bam.g.vcf.idx
├── reads_mother.bam.g.vcf
├── reads_mother.bam.g.vcf.idx
├── reads_son.bam.g.vcf
└── reads_son.bam.g.vcf.idx
```

### 3.1 Generate the test file stub

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

### 3.2 Move the test file and update the script path

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

### 3.3 Provide inputs

Fill in the inputs based on the process input definitions and rename the test accordingly:

```groovy title="modules/local/gatk/jointgenotyping/tests/main.nf.test" linenums="7"
test("family_trio [vcf] [idx]") {

    when {
        params {
            outdir = "tests/results"
        }
        process {
            """
            input[0] = file("${projectDir}/modules/local/gatk/jointgenotyping/tests/inputs/family_trio_map.tsv")
            input[1] = "family_trio"
            input[2] = file("${projectDir}/data/ref/ref.fasta")
            input[3] = file("${projectDir}/data/ref/ref.fasta.fai")
            input[4] = file("${projectDir}/data/ref/ref.dict")
            input[5] = file("${projectDir}/data/ref/intervals.bed")
            """
        }
    }
```

### 3.4 Use content assertions

The output of the joint genotyping step is another VCF file, so we're going to use a content assertion again.

```groovy title="modules/local/gatk/jointgenotyping/tests/main.nf.test" linenums="25"
then {
    assert process.success
    assert path(process.out[0][0]).readLines().contains('#CHROM	POS	ID	REF	ALT	QUAL	FILTER	INFO	FORMAT	NA12877	NA12878	NA12882')
    assert path(process.out[0][0]).readLines().contains('20_10037292_10066351	3480	.	C	CT	1625.89	.	AC=5;AF=0.833;AN=6;BaseQRankSum=0.220;DP=85;ExcessHet=0.0000;FS=2.476;MLEAC=5;MLEAF=0.833;MQ=60.00;MQRankSum=0.00;QD=21.68;ReadPosRankSum=-1.147e+00;SOR=0.487	GT:AD:DP:GQ:PL	0/1:15,16:31:99:367,0,375	1/1:0,18:18:54:517,54,0	1/1:0,26:26:78:756,78,0')
}
```

### 3.5 Run the test

```bash
nf-test test modules/local/gatk/jointgenotyping/tests/main.nf.test
```

Produces:

```bash
🚀 nf-test 0.9.0
https://www.nf-test.com
(c) 2021 - 2024 Lukas Forer and Sebastian Schoenherr


Test Process GATK_JOINTGENOTYPING

  Test [24c3cb4b] 'family_trio [vcf] [idx]' PASSED (10.945s)


SUCCESS: Executed 1 tests in 10.952s
```

It works! And that's it for module-level tests for our pipeline.

---

## 4. Add a pipeline-level test

Now all that remains is to add a test for checking that the whole pipeline runs to completion.

### 4.1 Generate pipeline-level stub test file

The command is similar to the one for module tests:

```bash
nf-test generate pipeline hello-nf-test.nf
```

It produces a similar stub file:

```groovy title="tests/hello-nf-test.nf.test" linenums="1"
nextflow_pipeline {

    name "Test Workflow hello-nf-test.nf"
    script "hello-nf-test.nf"

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

### 4.2 Run the test

In this case the pipeline test is fully functional (because we have default inputs set up in the configuration file) and can be run directly as follows:

```bash
nf-test test tests/hello-nf-test.nf.test
```

This produces:

```bash
🚀 nf-test 0.9.0
https://www.nf-test.com
(c) 2021 - 2024 Lukas Forer and Sebastian Schoenherr


Test Workflow hello-nf-test.nf

  Test [df3a3a8c] 'Should run without failures' PASSED (33.485s)


SUCCESS: Executed 1 tests in 33.492s
```

That's it! If necessary, more nuanced assertions can be added to test for the validity and content of the pipeline outputs. You can learn more about the different kinds of assertions you can use in the [nf-test documentation](https://www.nf-test.com/docs/assertions/assertions/).
