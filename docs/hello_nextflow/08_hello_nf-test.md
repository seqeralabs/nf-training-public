# Part 7: Hello nf-test

Testing is a critical part of developing and maintaining any software, including Nextflow workflows. Having a comprehensive test suite helps ensure reproducibility and makes it easier to maintain your code over time. It's also invaluable during the development process itself, helping you catch bugs early and verify that changes work as intended.

While many developers focus primarily on end-to-end testing (running the entire workflow with test data), this approach alone is insufficient. A robust testing strategy should also include module-level tests (similar to unit tests in traditional software development) that verify each component works correctly in isolation. These granular tests help you:

1. Validate that individual modules work as expected with different inputs
2. Quickly identify where problems occur when things break
3. Gain confidence when refactoring or updating code
4. Get "free" testing when reusing tested modules in new workflows

In this section, we'll introduce [**nf-test**](https://www.nf-test.com/), a testing framework specifically designed for Nextflow. nf-test makes it easy to write and run both module-level and workflow-level tests, helping you build more reliable pipelines. For additional background on nf-test and its benefits, check out [this detailed blog post](https://nextflow.io/blog/2024/nf-test-in-nf-core.html).

---

## 0. Warmup

In this section, we'll add tests to our pipeline using nf-test. We'll write both workflow-level tests that verify the entire pipeline works correctly, as well as module-level tests for each of our three processes.

We'll be working with a clean set of project files in a directory called `hello-nf-test`, similar to what we did in Part 6 (Hello Modules).

!!!note

    If you haven't completed the previous parts of this training course, you may want to do so first to better understand the code structure.
    The pipeline we'll be testing uses a modular design, with processes defined as local modules and parameters specified in a configuration file.

### 0.1. Explore the `hello-nf-test` directory

Let's move into the project directory. If you're continuing on directly from Part 6, you'll need to move up one directory first:

```bash
cd hello-nf-test
```

The `hello-nf-test` directory contains the same files and follows the same structure as the completed `hello-modules` directory from Part 6. If you haven't completed Part 6 yet, you can find the expected files and structure described there.

```console title="Directory contents"
hello-nf-test/
├── demo-params.json
├── main.nf
├── modules
└── nextflow.config
```

For a detailed description of each file in the project directory, please refer to the warmup section in Part 6. To understand the structure and contents of the `modules` directory specifically, we recommend reviewing Part 6 in its entirety - it provides a concise but thorough explanation of the modular workflow design.

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

The pipeline executed successfully, creating the expected output.

As with previous runs, this generated both a `work` directory (containing intermediate files) and a `results_genomics` directory (containing final outputs) in your project folder.
However, we won't need to examine these directories for now, as we're shifting our focus from pipeline development to testing.

From this point forward, we'll be working with the `nf-test` package - a testing framework specifically designed for Nextflow pipelines. This will allow us to verify our pipeline's behavior in a more systematic and automated way.

### 0.4. Initialize `nf-test`

The `nf-test` package provides an initialization command that sets up the necessary configuration files and directory structure required for testing your Nextflow project. This command creates a `tests` directory and a configuration file that defines test settings and parameters.

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

## 1. Add a workflow-level test

Let's begin by creating a test for the complete pipeline workflow. This test will execute the entire pipeline from start to finish and verify its successful completion. While this is conceptually similar to running `nextflow run` from the command line, the testing framework provides additional capabilities - specifically, the ability to programmatically validate the pipeline's outputs and behavior through assertions. This allows us to automatically verify that the pipeline is working as expected.

### 1.1. Generate pipeline-level stub test file

`nf-test` provides commands to generate test file templates. While it offers several specialized test generation options, we'll start by using the basic pipeline test generator, which creates a test file to verify our main workflow execution.

```bash
nf-test generate pipeline main.nf
```

This command generates a basic test file at `tests/main.nf.test`. Let's examine its contents:

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

Let's examine the key components of this test file:

1. The Details Block

    - Contains metadata about the test using `name`, `script`, and `test` keywords
    - `name` describes what's being tested
    - `script` specifies which Nextflow script to test
    - These default values are fine for our tutorial

2. The `when` Block

    - Sets up the test conditions and inputs
    - Contains a `params` section where you define workflow parameters
    - Think of this as "when we run the workflow with these settings..."
    - This is where you'll configure all inputs the workflow needs

3. The `then` Block
    - Defines what success looks like using assertions
    - Each assertion checks if something is true
    - The test passes only if all assertions pass
    - Common assertions check for workflow success or expected outputs

This structure follows the "Given-When-Then" pattern used in behavior-driven development:

-   "Given": We have a workflow to test (implicit in the test setup)
-   "When": We run it with specific parameters (the `when` block)
-   "Then": We check if it behaved correctly (the `then` block)

The test file includes two key assertions:

1. `assert workflow.success`

    - Checks if the workflow completed without errors
    - This is your basic "did it crash?" test
    - Passes if the workflow exits with status code 0

2. `assert snapshot(workflow.out).match()`
    - Compares workflow outputs against a saved reference
    - The reference snapshot includes channel contents and file checksums
    - Helps catch unexpected changes in workflow behavior
    - We'll cover snapshots in more detail later

Currently this test is incomplete - we need to specify the actual input data that the workflow requires. Let's add those inputs next.

### 1.2. Specify input parameters

Now we need to specify the workflow's input parameters. While there are several approaches to do this, the most straightforward method is to use the `nextflow.config` file in the `tests` directory (created earlier by `nf-test init`).

By adding parameters to this file's `params {}` block, we can define inputs that will be available to all tests in the repository. Here's how to set up the configuration:

```groovy title="tests/nextflow.config" linenums="1"
/*
 * Pipeline parameters
 */

params {
    // Primary input (file of input files, one per line)
    reads_bam        = "${projectDir}/data/sample_bams.txt"

    // Accessory files
    reference        = "${projectDir}/data/ref/ref.fasta"
    reference_index  = "${projectDir}/data/ref/ref.fasta.fai"
    reference_dict   = "${projectDir}/data/ref/ref.dict"
    intervals        = "${projectDir}/data/ref/intervals.bed"

    // Base name for final output file
    cohort_name      = "family_trio"
}
```

When nf-test runs any test, it automatically loads this configuration file and makes these parameters available to the workflow. This approach has several benefits:

1. Parameters are defined in one central location
2. All tests use the same parameter definitions
3. Changes to input paths only need to be made in one place
4. The configuration is version-controlled alongside your tests

Note that you can still override these parameters in individual test files if needed for specific test cases.

### 1.3. Run the test

Now that we've set up our test file and parameters, let's run the test. The basic command structure is:

```bash
nf-test test --profile docker_on tests/main.nf.test
```

Let's break down each component:

1. `nf-test test` - The base command to execute tests
2. `--profile docker_on` - Enables Docker for running the workflow
3. `tests/main.nf.test` - The path to our test file

!!!note "About the --profile parameter"
While `--profile` is optional, explicitly enabling Docker (or other container systems) in your tests is recommended:

    - It ensures consistent testing across different environments
    - Helps catch container-specific issues early
    - Allows testing with different container technologies (Docker, Singularity, etc.)
    - Uses two dashes (`--`) because it's a parameter for nf-test to pass to Nextflow

    You could set `docker.enable = true` in `tests/nextflow.config` instead, but explicit testing with different container systems is better practice.

When we run this command, we get:

```console title="Output"
🚀 nf-test 0.9.1
https://www.nf-test.com
(c) 2021 - 2024 Lukas Forer and Sebastian Schoenherr


Test Workflow hello-nf-test.nf

  Test [df3a3a8c] 'Should run without failures' PASSED (62.493s)


SUCCESS: Executed 1 tests in 62.498s
```

The output shows that our test passed successfully! This means:

1. The workflow executed without errors
2. All assertions in our test passed
3. The entire test suite ran in about 62 seconds

For more advanced testing, you can add additional assertions to verify specific outputs or behaviors. The [nf-test documentation](https://www.nf-test.com/docs/assertions/assertions/) provides a comprehensive guide to available assertion types.

Congratulations! You've now written your first nf-test. You can now modify the pipeline to your hearts content, safe in the knowledge that you can easily check the pipeline will exit successfully. This gives us confidence to modify the internals of our pipeline. Combined with some automation, we can even run the tests automatically on every code change, giving us a powerful safety net for developing our pipeline. This isn't covered in this tutorial however...

---

## 2. Test a process for success and matching outputs

While testing the entire pipeline is useful, we can also test individual processes to help pinpoint issues when they occur. For example, if our pipeline fails, testing each process separately can help identify exactly where the problem lies. Let's create a test for the `SAMTOOLS_INDEX` process - if this test fails, we'll know the issue is within that process, and if it passes, we can focus our debugging efforts elsewhere.

The SAMTOOLS_INDEX process is straightforward - it takes a BAM file as input and generates an index file. We'll verify that the process not only executes successfully but also consistently produces identical output files when given the same input. This kind of targeted testing helps us maintain and debug our pipeline more effectively.

### 2.1. Generate a test file stub

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

Open this file and look at the code:

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

The logic follows the same pattern as the pipeline-level test, but focuses on testing an individual process rather than a workflow. We use `assert process.success` to verify that the process completes without failures, and `snapshot(process.out).match()` to ensure the outputs remain consistent with previous test runs.

### 2.2. Move the test file and update the script path

First, let's organize our test files properly. The recommended practice is to keep test files alongside the module code they test.
For each module's `main.nf` file, we'll create a `tests` directory in the same location. This makes it easy to find and maintain tests for specific modules:

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

### 2.3. Provide inputs to the test process

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

### 2.4. Rename the test based on the primary test input

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

### 2.5. Specify test parameters

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

### 2.6. Run the test and examine the output

We can use the same testing syntax as before, but this time we will specifically target the test file we just created:

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

The test first verifies that the process completed successfully, meaning the SAMTOOLS_INDEX process executed without errors and exited with a status code of 0. While this basic check confirms the process didn't crash, it doesn't validate the actual output. For that deeper validation, we use nf-test's snapshot functionality.

When the test runs, it creates a snapshot file called `main.nf.test.snap` in the same directory as the test file. This snapshot captures:

1. All output channel contents from the process
2. MD5 checksums of generated output files
3. Any additional values explicitly passed to `snapshot()` in the test assertions

On subsequent test runs, nf-test will:

1. Re-run the process
2. Generate fresh outputs and calculate new checksums
3. Compare the new results against the stored snapshot
4. Flag any differences between the new results and the snapshot as test failures

This snapshot-based testing approach helps catch both obvious failures and subtle behavioral changes that might otherwise go unnoticed. It provides a reliable way to verify that code modifications haven't inadvertently altered the process's functionality.

!!!warning

    That means we have to be sure that the output we record in the original run is correct!

When future code changes cause different outputs, the test will fail. At this point, we need to determine if the change is expected or not:

-   If the code is broken, we need to fix the issue so that the test passes again with the original snapshot.
-   If the change is expected (e.g., an improvement in the underlying tool), we can update the snapshot to use the new output as the reference by running the test with `--update-snapshot`.

### 2.7. Add more tests to `SAMTOOLS_INDEX`

To ensure our process works correctly across different scenarios, it's good practice to test it with multiple input files. This helps catch edge cases and potential issues that may only appear with certain inputs. The nf-test framework allows us to define multiple test cases within the same test file. Each test case can use different input files while sharing the same test structure. Let's add two more test cases to verify that our SAMTOOLS_INDEX process works correctly with different BAM files:

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

### 2.8. Run the test suite and update the snapshot

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

The warning indicates that any failing snapshots will be automatically re-recorded due to the `--update-snapshot` parameter.

!!!note "Test Data Best Practices"
While we're using the same data files that we used to demonstrate the pipeline's scientific outputs, this isn't ideal for a production test environment.

    For production testing, you should create minimal test datasets that still exercise the key functionality. The goal is to keep test data as small as possible while ensuring it remains valid and tests the essential features. This approach helps maintain a test suite that runs quickly enough to be run frequently during development - if tests take too long to run, developers may skip running them, defeating their purpose as a safety net.

### Takeaway

You know how to write basic tests that evaluate success and whether outputs match reference outputs exactly.

### What's next?

Learn how to write tests for chained processes, and to evaluate whether outputs contain specific lines.

---

## 3. Add tests to a chained process and test for contents

Now that we know how to handle the simplest case, we're going to kick things up a notch with the `GATK_HAPLOTYPECALLER` process.

As the second step in our pipeline, its input depends on the output of another process.
We can deal with this in two ways:

-   Manually generate some static test data that is suitable as intermediate input to the process;
-   Use a special [setup method](https://www.nf-test.com/docs/testcases/setup/) to handle it dynamically for us.

**Spoiler:** We're going to use the setup method.

### 3.1. Generate the test file stub

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

### 3.2. Move the test file and update the script path

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

### 3.3. Provide inputs using the setup method

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

While the setup method provides a convenient way to chain processes together in tests, it should be used judiciously. Module-level tests are designed to validate processes in isolation, allowing us to pinpoint issues in specific components. Using setup to connect multiple processes can make it harder to identify the root cause when tests fail.

For most cases, we recommend using pre-generated test files that you create and version control as part of your test suite. This approach maintains process isolation and makes tests more predictable and easier to debug. We'll demonstrate this approach in the next section.

However, the setup method remains valuable when you specifically want to test the integration between two modules or verify that processes work together correctly in a chain. Just be mindful that such tests blur the line between unit and integration testing.

<!-- TODO: consider switching the order of types of tests, might make more sense in terms of flow -->

### 3.4. Run test and examine output

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

### 3.5. Run again and observe failure

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

Looking at the error message, we can see that the md5sum values are different between the two test runs for both the VCF file and its index.

This is happening because GATK HaplotypeCaller automatically includes a timestamp in the VCF header metadata. Since this timestamp changes with each run, the files will have different md5sums even when the actual variant calls are identical. This makes a simple file checksum comparison unreliable for testing the tool's output consistency.

How do we deal with that?

### 3.6. Use a content assertion method

Instead of comparing file checksums, we can use content-based assertions to verify specific lines in the output. The [nf-test assertions documentation](https://nf-co.re/docs/contributing/tutorials/nf-test_assertions) provides several options for this.

For VCF files, a good approach is to check for the presence of key header lines and variant records. This allows us to verify the essential content while ignoring timestamp-related differences.

Let's modify the test to use content assertions by replacing the snapshot comparison in the `then` block:

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

This approach reads the full VCF file content to search for specific lines. While this works for small test files, it's not recommended for larger files where you should instead extract and check specific lines of interest.

The tradeoff is that we need to carefully choose which lines serve as meaningful test signals. However, this targeted testing approach allows us to verify with high precision that an analysis tool consistently identifies important features (like rare variants) as the tool evolves. This makes it a powerful way to catch regressions in key functionality.

### 3.7. Run again and observe success

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

### 3.8. Add more test data

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

### 3.9. Run the test command

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

## 4. Use locally stored inputs

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

### 4.1. Generate the test file stub

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

### 4.2. Move the test file and update the script path

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

### 4.3. Provide inputs

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
}
```

### 4.4. Use content assertions

The output of the joint genotyping step is another VCF file, so we're going to use a content assertion again.

```groovy title="modules/local/gatk/jointgenotyping/tests/main.nf.test" linenums="25"
then {
    assert process.success
    assert path(process.out[0][0]).readLines().contains('#CHROM	POS	ID	REF	ALT	QUAL	FILTER	INFO	FORMAT	reads_father	reads_mother	reads_son')
    assert path(process.out[0][0]).readLines().contains('20_10037292_10066351	3480	.	C	CT	1625.89	.	AC=5;AF=0.833;AN=6;BaseQRankSum=0.220;DP=85;ExcessHet=0.0000;FS=2.476;MLEAC=5;MLEAF=0.833;MQ=60.00;MQRankSum=0.00;QD=21.68;ReadPosRankSum=-1.147e+00;SOR=0.487	GT:AD:DP:GQ:PL	0/1:15,16:31:99:367,0,375	1/1:0,18:18:54:517,54,0	1/1:0,26:26:78:756,78,0')
}
```

### 4.5. Run the test

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

### Takeaway

You know how to write and run several kinds of tests for individual modules and for the entire workflow.

### What's next?

Celebrate and take a big break! Next up, we delve into the cornucopia of code and tools that is the nf-core project.
