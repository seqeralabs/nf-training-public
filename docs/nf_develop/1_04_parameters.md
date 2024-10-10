# Adding parameters

Parameters that can be overridden, either using the command line or the Nextflow configuration file, and should be used for anything that a pipeline user may want to configure regularly

Here, as a simple example, you will add a new parameter to your pipeline that will skip the `SEQTK_TRIM` process.

## Default values

In the nf-core template the default values for parameters are set in the `nextflow.config` in the base repository.

Any new parameters should be added to the `nextflow.config` with a default value within the `params` scope.

Parameter names should be unique and easily identifiable.

!!! question "Exercise"

    Add a new parameter `skip_trim` to your `nextflow.config` file and set it to `false`.

    ```groovy title="nextflow.config" linenums="27"
    // Trimming
    skip_trim                   = false
    ```

## Adding parameters to your pipeline

Parameters are accessible in the pipeline script.

Here, an `if` statement that is depended on the `skip_trim` parameter can be used to modulate the execution of the `SEQTK_TRIM` process. An `!` can be used to imply the logical "not".

Thus, if the `skip_trim` parameter is **not** `true`, the `SEQTK_TRIM` will be be executed.

!!! question "Exercise"

    Add an `if` statement that is dependent on the `skip_trim` parameter to your pipeline.

    ```groovy title="workflows/mypipeline.nf" linenums="40"
    //
    // MODULE: Run SEQTK_TRIM
    //
    if (!params.skip_trim) {
        SEQTK_TRIM (
            ch_samplesheet
        )
        ch_trimmed  = SEQTK_TRIM.out.reads
        ch_versions = ch_versions.mix(SEQTK_TRIM.out.versions.first())
    }
    ```

Now your if statement has been added to your main workflow file and has a default setting in your `nextflow.config` file, you will be able to flexibly skip the new trimming step using the `skip_trim` parameter.

!!! question "Exercise"

    Check your new `skip_trim` parameter is working by adding it to your execution command.

    ```console
    nextflow run nf-core-myfirstpipeline -profile test,singularity --outdir results --skip_trim
    ```

    You should see that the `SEQTK_TRIM` process has been skipped in your execution.

## Linting your changes

Linting is a static analysis process that helps ensure code quality by automatically identifying syntax errors, potential bugs, and adherence to coding standards. By enforcing consistency and best practices, linting enhances code readability, reduces errors, and streamlines the development workflow.

As a part of nf-core tools, the `nf-core lint` command can be used to check for inconsistencies in your code, compare your code against source code, and compare your code against nf-core standards.

Executing the `nf-core lint` command from within your pipeline repository will print a list of ignored tests, warnings, failed tests, and a summary.

```console
╭───────────────────────╮
│ LINT RESULTS SUMMARY  │
├───────────────────────┤
│ [✔] 192 Tests Passed  │
│ [?]   0 Tests Ignored │
│ [!]  26 Test Warnings │
│ [✗]   1 Test Failed   │
╰───────────────────────╯
```

!!! question "Exercise"

    Execute the `nf-core lint` command to test your pipeline.

    **It is expected that some of these tests will fail.**

## Updating `nextflow_schema.json`

If you have added parameters and they have not been documented in the `nextflow_schema.json` file then pipeline tests will fail during linting.

```console
schema_params: Param skip_trim from nextflow config not found in nextflow_schema.json
```

For linting tests to pass the `nextflow_schema.json` file must be updated with the parameters that were added to your pipeline but have not been documented.

The `nextflow_schema.json` file can get very big and very complicated very quickly. The `nf-core schema build` command is designed to support developers write, check, validate, and propose additions to your `nextflow_schema.json` file.

```console
nf-core schema build
```

It will enable you to launch a web builder to edit this file in your web browser rather than trying to edit this file manually.

```console
INFO     [✓] Default parameters match schema validation
INFO     [✓] Pipeline schema looks valid (found 31 params)
✨ Found 'params.skip_trim' in the pipeline config, but not in the schema. Add to pipeline schema? [y/n]: y

🚀  Launch web builder for customization and editing? [y/n]: y
```

Using the web builder you can add add details about your new parameters.

The parameters that you have added to your pipeline will be added to the bottom of the `nf-core schema build` file. Some information about these parameters will be automatically filled based on the default value from your `nextflow.config`. You will be able to categorize your new parameters into a group, add icons, and add descriptions for each.

![Pipeline parameters](img/schemabuild.png)

Once you have made your edits you can click `Finished` and all changes will be automatically added to your `nextflow_schema.json` file.

!!! question "Exercise"

    Use the `nf-core schema build` command to update your schema. Add any grouping and information you think is appropriate.

    ```console
    nf-core schema build
    ```

    Lint your pipeline again to see if the tests pass.

    ```console
    nf-core lint
    ```

    All pipeline tests should pass.

## Push your changes to GitHub

Now you have added a new tool to your pipeline and you are satisfied with your improvements you can `add`, `commit`, and `push` your changes to GitHub.

You can check which branch you are on using the `git branch` command.

As your current branch `myFeature` has no upstream branch you will need to set the remote as upstream the first time you push your changes.

!!! question "Exercise"

    Push your changes to your GitHub repository.

    ```bash
    git add .
    git commit -m "Added setk_trim to pipeline"
    git push --set-upstream origin myFeature
    ```

From this point, you could merge your update into the dev branch or continue your development.

---

Congratulations! You have now added a new parameter to your pipeline and updated the schema for linting tests to pass
!
