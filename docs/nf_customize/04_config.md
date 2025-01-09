# Configuration options

Each nf-core pipeline comes with a set of “sensible defaults”. While the defaults are a great place to start, you will certainly want to modify these to fit your own purposes and system requirements.

**You do not need to edit the pipeline code to configure nf-core pipelines.**

Nextflow will look for configuration files in several locations when it is launched. As each source can contain conflicting settings, the sources are ranked to decide which settings to apply.

Configuration sources are reported below and listed in order of priority:

1. Parameters specified on the command line (`--parameter`)
2. Parameters that are provided using the `-params-file` option
3. Config file that are provided using the `-c` option
4. The config file named `nextflow.config` in the current directory
5. The config file named `nextflow.config` in the pipeline project directory
6. The config file `$HOME/.nextflow/config`
7. Values defined within the pipeline script itself (e.g., `main.nf`)

While some of these files are already included in the nf-core pipeline repository (e.g., the `nextflow.config` file in the nf-core pipeline repository), some are automatically identified on your local system (e.g., the `nextflow.config` in the launch directory), and others are only included if they are specified using `run` options (e.g., `-params-file`, and `-c`).

Understanding how and when these files are interpreted by Nextflow is critical for the accurate configuration of a pipeline execution.

## Parameters

Parameters are pipeline specific settings that can be used to customize the execution of a pipeline.

At the highest level, parameters can be customized using the command line. Any parameter can be configured on the command line by prefixing the parameter name with a double dash (`--`):

```bash
--<parameter>
```

Depending on the parameter type, you may be required to add additional information after your parameter flag. For example, for a string parameter, you would add the string after the parameter flag. For example, the `outdir` parameter required by the `nf-core/demo` pipeline:

```bash
nextflow nf-core/demo --outdir results
```

Every nf-core pipeline has a full list of parameters on the nf-core website. You will also be shown a description and the type of the parameter when viewing these parameters. Some parameters will also have additional text to help you understand how a parameter should be used.

Parameters and their descriptions can also be viewed in the command line using the `run` command with the `--help` parameter.

!!! question "Exercise"

    View the parameters for the `nf-core/demo` pipeline using the command line:

    ```bash
    nextflow run nf-core/demo --help
    ```

You can also view these on the [nf-core/demo parameters page](https://nf-co.re/demo/1.1.0/parameters/).

## Default configuration files

All parameters have a default configuration that is defined using the `nextflow.config` file in the pipeline project directory. Most parameters are set to `null` or `false` by default.

There are also several `includeConfig` statements in the `nextflow.config` file that are used to include additional `.config` files from the `conf/` folder. Each additional `.config` file contains categorized configuration information for your pipeline execution, some of which can be optionally included:

-   `base.config`
    -   Included by the pipeline by default.
    -   Generous resource allocations using labels.
    -   Does not specify any method for software management and expects software to be available (or specified elsewhere).
-   `igenomes.config`
    -   Included by the pipeline by default.
    -   Default configuration to access reference files stored on [AWS iGenomes](https://ewels.github.io/AWS-iGenomes/).
-   `igenomes_ignored.config`
    -   Empty genomes dictionary to use when igenomes is ignored.
-   `modules.config`
    -   Included by the pipeline by default.
    -   Module-specific configuration options (both mandatory and optional).
-   `test.config`
    -   Only included if specified as a profile.
    -   A configuration profile to test the pipeline with a small test dataset.
-   `test_full.config`
    -   Only included if specified as a profile.
    -   A configuration profile to test the pipeline with a full-size test dataset.

!!! note

    Some configuration files contain the definition of profiles. For example, the `docker`, `singularity`, and `conda` profiles are defined in the `nextflow.config` file in the pipeline project directory.

Profiles used by nf-core pipelines can be broadly categorized into two groups:

-   **Software management profiles**
    -   Profiles for the management of software using software management tools, for example, `docker`, `singularity`, and `conda`.
-   **Test profiles**
    -   Profiles to execute the pipeline with a standardized set of test data and parameters, for example, `test` and `test_full`.

nf-core pipelines are required to define software containers and environments that can be activated using profiles. Although it is possible to run the pipelines with software installed by other methods (e.g., environment modules or manual installation), using Docker or Singularity is more sharable, convenient, and reproducible.

## Shared configuration files

An `includeConfig` statement in the `nextflow.config` file is also used to include custom institutional profiles that have been submitted to the nf-core [config repository](https://github.com/nf-core/configs). At run time, nf-core pipelines will fetch these configuration profiles from the [nf-core config repository](https://github.com/nf-core/configs) and make them available.

For shared resources such as an HPC cluster, you may consider developing a shared institutional profile.

[This tutorial](https://nf-co.re/docs/usage/tutorials/step_by_step_institutional_profile) can be used to help setting up an institutional profile.

## Custom parameter and configuration files

Nextflow will also look for files that are external to the pipeline project directory. These files include:

-   The config file `$HOME/.nextflow/config`
-   A config file named `nextflow.config` in your current directory
-   Custom files specified using the command line
    -   A parameter file that is provided using the `-params-file` option
    -   A config file that are provided using the `-c` option

**You do not need to use all of these files to run your pipeline.**

**Parameter files**

Parameter files are `.json` files that can contain an unlimited number of parameters:

```json title="my-params.json" linenums="1"
{
    "<parameter1_name>": 1,
    "<parameter2_name>": "<string>",
    "<parameter3_name>": true
}
```

You can override default parameters by creating a `.json` file and passing it as a command-line argument using the `-param-file` option:

```bash
nextflow run nf-core/demo -profile singularity -param-file <path/to/params.json>
```

!!! question "Exercise"

    Add the `input` and `outdir` parameters to a params file. Give `input` the complete path to your sample sheet and give `outdir` the name `results_mycustomparams`:

    1. Create `mycustomparams.json`:

    ```bash
    code mycustomparams.json
    ```

    2. Add your `input` and `output` parameters:

    ```json title="mycustomparams.json" linenums="1"
    {
    "input": "/workspace/gitpod/nf-customize/samplesheet.csv",
    "outdir": "results_mycustomparams"
    }
    ```

    3. Run  `nf-core/demo` with your custom `mycustomparams.json` file:

    ```bash
    nextflow run nf-core/demo -profile singularity -params-file mycustomparams.json
    ```

The pipeline should run successfully. You should be able to see a new results folder `results_mycustomparams` in your current directory.

**Configuration files**

Configuration files are `.config` files that can contain various pipeline properties and can be passed to Nextflow using the `-c` option in your execution command:

```bash
nextflow run nf-core/demo -profile singularity -params-file mycustomparams.json -c <path/to/custom.config>
```

Custom configuration files are the same format as the configuration file included in the pipeline directory.

Configuration properties are organized into [scopes](https://www.nextflow.io/docs/latest/config.html#config-scopes) by dot prefixing the property names with a scope identifier or grouping the properties in the same scope using the curly brackets notation:

```console title="custom.config" linenums="1"
alpha.x  = 1
alpha.y  = 'string value'
```

Is equivalent to:

```console title="custom.config" linenums="1"
alpha {
    x = 1
    y = 'string value'
}
```

Scopes allow you to quickly configure settings required to deploy a pipeline on different infrastructure using different software management.

For example, the `executor` scope can be used to provide settings for the deployment of a pipeline on an HPC cluster. Similarly, the `singularity` scope controls how Singularity containers are executed by Nextflow.

A common scenario is for users to write a custom configuration file specific to running a pipeline on their infrastructure.

!!! warning

    Do not use `-c <file>` to specify parameters as this will result in errors. Custom config files specified with `-c` must only be used for tuning process resource specifications, other infrastructural tweaks (such as output directories), or module arguments (args).

Multiple scopes can be included in the same `.config` file using a mix of dot prefixes and curly brackets:

```console title="example.config" linenums="1"
executor.name = "sge"

singularity {
    enabled    = true
    autoMounts = true
}
```

See the [Nextflow documentation](https://www.nextflow.io/docs/latest/config.html#config-scopes) for a full list of scopes.

!!! question "Exercise"

    Instead of using the `singularity` profile a custom configuration file can be used to enable singularity. Create a custom configuration file and enable singularity and singularity auto mounts using the singularity scope.

    1. Create `mycustomconfig.config`:

    ```bash
    code mycustomconfig.config
    ```

    2. Add your configuration to the singularity scope:

    ```console title="mycustomconfig.config" linenums="1"
    singularity {
        enabled    = true
        autoMounts = true
    }
    ```

    3. Run `nf-core/demo` with your `mycustomconfig.config` in your execution command:

    ```bash
    nextflow run nf-core/demo -profile test --outdir results_config -c mycustomconfig.config
    ```

The pipeline will run successfully.

!!! note "Multiple config files"

    Multiple custom `.config` files can be included at execution by separating them with a comma (`,`).

The `process` scope allows you to configure pipeline processes and is used extensively to define resources and additional arguments for modules.

By default, process resources are allocated in the `conf/base.config` file using the `withLabel` selector:

```bash title="conf/base.config" linenums="1"
process {
    withLabel: BIG_JOB {
        cpus = 16
        memory = 64.GB
    }
}
```

Similarly, the `withName` selector enables the configuration of a process by name. By default, module parameters are defined in the `conf/modules.config` file:

```bash title="conf/modules.config" linenums="1"
process {
    withName: MYPROCESS {
        cpus = 4
        memory = 8.GB
    }
}
```

While some tool arguments are included as a part of a module. To make nf-core modules sharable across pipelines, most tool arguments are defined in the `conf/modules.conf` file in the pipeline code under the `ext.args` entry.

Importantly, having these arguments outside the module also allows them to be customized at runtime.

For example, if you wanted to add arguments to the `MULTIQC` process in the `nf-core/demo` pipeline, you could use the process scope and the `withName` selector:

```console title="example.config" linenums="1"
process {
    withName : "MULTIQC" {
        ext.args   = { "<your custom parameter>" }
    }
```

An extended execution path of the module may be required to make it more specific if a process is used multiple times in a pipeline:

```console title="example.config" linenums="1"
process {
    withName: "NFCORE_DEMO:DEMO:MULTIQC" {
        ext.args = { "<your custom parameter>" }
    }
}
```

The extended execution path is built from the pipelines, subworkflows, and module used to execute the process.

!!! question "Exercise"

    Modify your existing `mycustomconfig.config` by adding a process scope, with the `withName` selector, to add a custom title to your MultiQC report:

    1. Open `mycustomconfig.config`:

    ```bash
    code mycustomconfig.config
    ```

    2. Add a `process` scope and using the `withName` selector for `MULTIQC`, add `--title` flag with a custom report name.

    ```console title="mycustomconfig.config" linenums="1"
    singularity {
        enabled    = true
        autoMounts = true
    }

    process {
        withName: 'MULTIQC' {
                ext.args   = { "--title \"my_custom_title\"" }
            }
    }
    ```

    3. Run `nf-core/demo` with your `mycustomconfig.config` in your execution command::

    ```bash
    nextflow run nf-core/demo -profile test --outdir results_process -c mycustomconfig.config
    ```

    View the `multiqc` folder inside your results directory:

    ```bash
    ls results_process/multiqc/
    ```

## Mixing configuration files

It is important to consider how the different configuration options interact during each execution and how you can apply these to minimize mistakes and extra configuration.

!!! question "Exercise"

    Execute the `nf-core/demo` pipeline with the `singularity` profile, your `mycustomparams.json` file, your `mycustomconfig.config` file, and a command line flag `--outdir results_mixed`:

    ```bash
    nextflow run nf-core/demo -profile singularity -params-file mycustomparams.json -c mycustomconfig.config --outdir results_mixed
    ```

You now have a new output directory named `results_mixed` despite the directory being named `results_customparams` in your custom parameters file.

!!! question "Exercise"

    Consider how the different levels of configuration interacted. Mix and match configuration levels to rename your outputs.

---

Congratulations! You have successfully customized the execution of the `nf-core/demo` pipeline using different methods!
