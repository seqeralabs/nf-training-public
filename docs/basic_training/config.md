---
title: Configuration
description: Fundamentals Nextflow Training Workshop
---

# Nextflow configuration

A key Nextflow feature is the ability to decouple the workflow implementation by the configuration setting required by the underlying execution platform.
This enables portable deployment without the need to modify the application code.

When you launch Nextflow, it will look for configuration files in several locations. As each source can contain conflicting settings, the sources are ranked to decide which settings to apply. Configuration sources are reported below and listed in order of priority:

1. Parameters specified on the command line (`--parameter`)
2. Parameters that are provided using the `-params-file` option
3. Config file that are provided using the `-c` option
4. The config file named `nextflow.config` in the current directory
5. The config file named `nextflow.config` in the pipeline project directory
6. The config file `$HOME/.nextflow/config`
7. Values defined within the pipeline script itself (e.g., `main.nf`)

## Parameters

Parameters are pipeline specific settings. Parameters can be defined in the workflow script using the `params` keyword followed by the parameter name. For example:

```groovy linenums="1" title="hello.nf"
#!/usr/bin/env nextflow

params.greeting = 'Hello world!'
...
```

At the highest level, parameters can be customised using the command line.
Any parameter can be configured on the command line by prefixing the parameter name with a double dash (--).
For example, the `greeting` parameter in the `hello.nf` script can be configured using the command line as follows:

```bash
nextflow run hello.nf --greeting 'Bonjour le monde!'
```

Instead of including each parameter on the command line, parameters can also be configured using the `-params-file` and a JSON or YML file:

```json linenums="1" title="params.json"
{
    "greeting": "Bonjour le monde!"
}
```

Multiple parameters can be included in one params file and added to the execution command using the `-params-file` option:

```bash
nextflow run hello.nf -params-file params.json
```

!!! question "Exercise"

    Run the `hello.nf` script with the `greeting` parameter set to `Hallo Welt!` using a params file.

    ??? solution

        ```json linenums="1" title="params.json"
        {
            "greeting": "Hallo Welt!"
        }
        ```

        ```bash
        nextflow run hello.nf -params-file params.json
        ```

!!! tip

    Parameters files are useful to consolidate large number of parameters in a single file.

!!! cboard-list-2 "Summary"

    In this step you have learned:

    1. How to define parameters in a workflow script
    2. How to configure parameters on the command line
    3. How to configure parameters using `-params-file`

## Configuration files

When a workflow script is launched, Nextflow looks for a file named `nextflow.config` in the current directory and in the script base directory (if it is not the same as the current directory). Finally, it checks for the file: `$HOME/.nextflow/config`.

When more than one of the above files exists, they are merged, so that the settings in the first override the same settings that may appear in the second, and so on.

The default config file search mechanism can be extended by providing an extra configuration file by using the command line option: `-c <config file>`. For example:

```bash
nextflow run hello.nf -c custom.config
```

### Config syntax

A Nextflow configuration file is a simple text file containing a set of properties defined using the syntax:

```groovy linenums="1" title="nextflow.config"
name = value
```

!!! info

    String values need to be wrapped in quotation characters while numbers and boolean values (`true`, `false`) do not. Also, note that values are typed, meaning for example that, `1` is different from `'1'`, since the first is interpreted as the number one, while the latter is interpreted as a string value.

### Config variables

Configuration properties can be used as variables in the configuration file itself, by using the usual `$propertyName` or `${expression}` syntax.

```groovy linenums="1" title="nextflow.config"
propertyOne = 'world'
anotherProp = "Hello $propertyOne"
customPath = "$PATH:/my/app/folder"
```

!!! tip

    In the configuration file it’s possible to access any variable defined in the host environment such as `$PATH`, `$HOME`, `$PWD`, etc.

### Config comments

Configuration files use the same conventions for comments used in the Nextflow script:

```groovy linenums="1"
// comment a single line

/*
    a comment spanning
    multiple lines
*/
```

### Config scopes

Configuration settings can be organized in different scopes by dot prefixing the property names with a scope identifier or grouping the properties in the same scope using the curly brackets notation:

```groovy linenums="1" title="nextflow.config"
alpha.x  = 1
alpha.y  = 'string value..'

beta {
    p = 2
    q = 'another string ..'
}
```

### Config params

The scope `params` allows the definition of workflow parameters that override the values defined in the main workflow script.

This is useful to consolidate one or more execution parameters in a separate file.

```groovy linenums="1" title="nextflow.config"
params.foo = 'Bonjour'
params.bar = 'le monde!'
```

```groovy linenums="1" title="snippet.nf"
params.foo = 'Hello'
params.bar = 'world!'

// print both params
println "$params.foo $params.bar"
```

!!! exercise

    Using the code blocks above, run `snippet.nf` without specifying any parameters. Then, run it again specifying the `foo` parameter on the command line.

    ```bash
    nextflow run snippet.nf
    ```

    ??? Solution

        Run the script without any modification:

        ```bash
        nextflow run snippet.nf
        ```

        ```console title="Output"
        Bonjour le monde!
        ```

        Execute the snippit again specifying the `foo` parameter on the command line:

        ```bash
        nextflow run snippet.nf --foo Hola
        ```

        ```console title="Output"
        Hola le monde!
        ```

        Note how the `foo` parameter is overridden by the value specified on the command line and the `bar` parameter is taken from the configuration file.

### Config env

The `env` scope allows the definition of one or more variables that will be exported into the environment where the workflow tasks will be executed.

```groovy linenums="1" title="my-env.config"
env.ALPHA = 'some value'
env.BETA = "$HOME/some/path"
```

```groovy linenums="1" title="snippet.nf"
process FOO {
    debug true

    script:
    '''
    env | egrep 'ALPHA|BETA'
    '''
}

workflow {
    FOO()
}
```

Executing the snippets above will produce the following output:

```bash
nextflow run snippet.nf -c my-env.config
```

```console title="Output"
BETA=/home/user/some/path
ALPHA=some value
```

### Config process

Process [directives](https://www.nextflow.io/docs/latest/process.html#directives) allow the specification of settings for the task execution such as `cpus`, `memory`, `container`, and other resources in the workflow script.

This is useful when prototyping a small workflow script.

However, it’s always a good practice to decouple the workflow execution logic from the process configuration settings, i.e. it’s strongly suggested to define the process settings in the workflow configuration file instead of the workflow script.

The `process` configuration scope allows the setting of any `process` [directives](https://www.nextflow.io/docs/latest/process.html#directives) in the Nextflow configuration file:

```groovy linenums="1" title="nextflow.config"
process {
    cpus = 10
    memory = 8.GB
    container = 'biocontainers/bamtools:v2.4.0_cv3'
}
```

The above config snippet defines the `cpus`, `memory` and `container` directives for all processes in your workflow script.

The [process selector](https://www.nextflow.io/docs/latest/config.html#process-selectors) can be used to apply the configuration to a specific process or group of processes (discussed later).

!!! info

    Memory and time duration units can be specified either using a string-based notation in which the digit(s) and the unit **can** be separated by a blank or by using the numeric notation in which the digit(s) and the unit are separated by a dot character and are not enclosed by quote characters.

| String syntax     | Numeric syntax | Value                 |
| ----------------- | -------------- | --------------------- |
| `'10 KB'`         | `10.KB`        | 10240 bytes           |
| `'500 MB'`        | `500.MB`       | 524288000 bytes       |
| `'1 min'`         | `1.min`        | 60 seconds            |
| `'1 hour 25 sec'` | \-             | 1 hour and 25 seconds |

The syntax for setting `process` directives in the configuration file requires `=` (i.e. assignment operator), whereas it should not be used when setting the process directives within the workflow script.

??? example

    ```groovy linenums="1" title="snippet.nf"
    process FOO {
        cpus 4
        memory 2.GB
        time 1.hour
        maxRetries 3

        script:
        """
        your_command --cpus $task.cpus --mem $task.memory
        """
    }
    ```

This is especially important when you want to define a config setting using a dynamic expression using a closure. For example, in a workflow script:

```groovy linenums="1" title="snippet.nf"
process FOO {
    memory { 4.GB * task.cpus }
}
```

You can also define the same setting in the configuration file using a similar syntax:

```groovy linenums="1" title="snippet.nf"
process {
    withName: FOO {
        memory = { 4.GB * task.cpus }
    }
}
```

Directives that require more than one value, e.g. [pod](https://www.nextflow.io/docs/latest/process.html#pod), in the configuration file need to be expressed as a map object.

```groovy linenums="1" title="nextflow.config"
process {
    pod = [env: 'FOO', value: '123']
}
```

Finally, directives that are to be repeated in the process definition, in the configuration files need to be defined as a list object:

```groovy linenums="1" title="nextflow.config"
process {
    pod = [[env: 'FOO', value: '123'],
           [env: 'BAR', value: '456']]
}
```

### Config Docker execution

The container image to be used for the process execution can be specified in the `nextflow.config` file:

```groovy linenums="1" title="nextflow.config"
process.container = 'nextflow/rnaseq-nf'
docker.enabled = true
```

The use of unique "SHA256" Docker image IDs guarantees that the image content does not change over time, for example:

```groovy linenums="1" title="nextflow.config"
process.container = 'nextflow/rnaseq-nf@sha256:aeacbd7ea1154f263cda972a96920fb228b2033544c2641476350b9317dab266'
docker.enabled = true
```

### Config Singularity execution

To run a workflow execution with Singularity, a container image file path is required in the Nextflow config file using the container directive:

```groovy linenums="1" title="nextflow.config"
process.container = '/some/singularity/image.sif'
singularity.enabled = true
```

!!! info

    The container image file must be an absolute path: it must start with a `/`.

The following protocols are supported:

-   `library://` download the container image from the [Singularity Library service](https://cloud.sylabs.io/library).
-   `shub://` download the container image from the [Singularity Hub](https://singularity-hub.org/).
-   `docker://` download the container image from the [Docker Hub](https://hub.docker.com/) and convert it to the Singularity format.
-   `docker-daemon://` pull the container image from a local Docker installation and convert it to a Singularity image file.

!!! warning

    Singularity hub `shub://` is no longer available as a builder service. Though existing images from before 19th April 2021 will still work.

!!! tip

    By specifying a plain Docker container image name, Nextflow implicitly downloads and converts it to a Singularity image when the Singularity execution is enabled.

    ```groovy linenums="1" title="nextflow.config"
    process.container = 'nextflow/rnaseq-nf'
    singularity.enabled = true
    ```

    The above configuration instructs Nextflow to use the Singularity engine to run your script processes. The container is pulled from the Docker registry and cached in the current directory to be used for further runs.

    Alternatively, if you have a Singularity image file, its absolute path location can be specified as the container name either using the `-with-singularity` option or the `process.container` setting in the config file.

### Config Conda execution

The use of a Conda environment can also be provided in the configuration file by adding the following setting in the `nextflow.config` file:

```groovy linenums="1" title="nextflow.config"
process.conda = "/home/ubuntu/miniconda2/envs/nf-tutorial"
```

You can specify the path of an existing Conda environment as either **directory** or the path of Conda environment YAML file.

!!! cboard-list-2 "Summary"

    In this step you have learned:

    1. How to write a Nextflow configuration file.
    2. How to use configuration files to define parameters, environment variables, and process directives
    3. How to use configuration files to define Docker, Singularity, and Conda execution
    4. How to use configuration files to define process directives
