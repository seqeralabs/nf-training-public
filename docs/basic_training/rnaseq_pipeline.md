---
title: Simple RNA-Seq workflow
description: Fundamentals Nextflow Training Workshop
---

# Simple RNA-Seq workflow

To demonstrate a real-world biomedical scenario, you will implement a proof of concept RNA-Seq workflow which:

1. Indexes a transcriptome file
2. Performs quality controls
3. Performs quantification
4. Creates a MultiQC report

This will be done using a series of seven scripts. Each script will build on the previous to create a complete workflow. You can find these in the tutorial folder (`script1.nf` - `script7.nf`). These scripts will make use of third-party tools that are known by many bioinformaticians:

1. [Salmon](https://combine-lab.github.io/salmon/) is a tool for quantifying molecules known as transcripts through a type of data called RNA-seq data.
2. [FastQC](https://www.bioinformatics.babraham.ac.uk/projects/fastqc/) is a tool for quality analysis of high throughput sequence data. You can think of it as a way to assess the quality of your data.
3. [MultiQC](https://multiqc.info) searches a given directory for analysis logs and compiles a HTML report for easy viewing. It's a general use tool, perfect for summarizing the output from numerous bioinformatics tools.

Although you may be unfamiliar with these tools, they represent real world bioinformatic tools and will be used to teach you how to use Nextflow to create a workflow.

## Define the workflow parameters

Parameters are inputs and options that can be modified when the workflow is executed.

The script `script1.nf` defines three workflow input parameters and uses the [groovy `println`](https://www.tutorialspoint.com/groovy/groovy_basic_syntax.htm) command to print one of these to the console.

```groovy linenums="1" title="script1.nf"
params.reads = "$projectDir/data/ggal/gut_{1,2}.fq"
params.transcriptome_file = "$projectDir/data/ggal/transcriptome.fa"
params.multiqc = "$projectDir/multiqc"

println "reads: $params.reads"
```

Run it by using the following command:

```bash
nextflow run script1.nf
```

Parameters are special in Nextflow as they can be modified at the time you execute your command, for example:

```bash
nextflow run script1.nf --reads '/workspace/gitpod/nf-training/data/ggal/lung_{1,2}.fq'
```

Your output will look something like this:

```console title="Output"
N E X T F L O W  ~  version 23.10.1
Launching `script1.nf` [big_baekeland] DSL2 - revision: 86d466d737
reads: /workspace/gitpod/nf-training/data/ggal/lung_{1,2}.fq
```

!!! question "Exercise"

    Add a fourth parameter named `outdir` to `script1.nf` and give it the string "results".

    ??? Solution

        ```groovy linenums="1" title="script1.nf"
        params.reads = "$projectDir/data/ggal/gut_{1,2}.fq"
        params.transcriptome_file = "$projectDir/data/ggal/transcriptome.fa"
        params.multiqc = "$projectDir/multiqc"
        params.outdir = "results"
        ```

The `log.info` command can be used to print multiline information using groovy’s logger functionality. Instead of writing a series of `println` commands, it can be used to include a multiline message.

```groovy linenums="1" title="example.nf"
log.info """\
    This is
    a multiline
    message
"""
```

!!! question "Exercise"

    Modify `script1.nf` to print all of the workflow parameters by using a single `log.info` command as a [multiline string](https://www.nextflow.io/docs/latest/script.html#multi-line-strings) statement.

    !!! tip ""

        :material-lightbulb: See an example [here](https://github.com/nextflow-io/rnaseq-nf/blob/3b5b49f/main.nf#L41-L48).


    ??? Solution

        Add the following to your script file:

        ```groovy linenums="9" title="script1.nf"
        log.info """\
            R N A S E Q - N F   P I P E L I N E
            ===================================
            transcriptome: ${params.transcriptome_file}
            reads        : ${params.reads}
            outdir       : ${params.outdir}
            """
            .stripIndent(true)
        ```

!!! cboard-list-2 "Summary"

    In this step you have learned:

    1. How to define parameters in your workflow script
    2. How to pass parameters by using the command line
    3. How to use `log.info` to print information and save it in the log execution file

## Create a transcriptome index file

Nextflow allows the execution of any command or script by using a `process` definition.

A `process` is defined by providing three main declarations:

-   [`input`](https://www.nextflow.io/docs/latest/process.html#inputs)
-   [`output`](https://www.nextflow.io/docs/latest/process.html#outputs)
-   [`script`](https://www.nextflow.io/docs/latest/process.html#script)

To add a transcriptome `INDEX` processing step to your pipeline, you will need to add the following code block to your `script1.nf`. Alternatively, this code block has already been added to `script2.nf`.

```groovy linenums="18" title="script2.nf"
/*
 * define the `INDEX` process that creates a binary index
 * given the transcriptome file
 */
process INDEX {
    input:
    path transcriptome

    output:
    path 'salmon_index'

    script:
    """
    salmon index --threads $task.cpus -t $transcriptome -i salmon_index
    """
}
```

Additionally, you will need to add a workflow scope containing an input channel definition and the index process:

```groovy linenums="35" title="script2.nf"
workflow {
    index_ch = INDEX(params.transcriptome_file)
}
```

Here, the `params.transcriptome_file` parameter is used as the input for the `INDEX` process. The `INDEX` process (using the `salmon` tool) creates `salmon_index`, an indexed transcriptome that is passed as an output to the `index_ch` channel.

!!! info

    The `input` declaration defines a `transcriptome` path variable which is used in the `script` as a reference (using the dollar symbol) in the Salmon execution command.

!!! warning

    Resource requirements such as CPUs and memory limits can change with different workflow executions and platforms. Nextflow can use `$task.cpus` as a variable for the number of CPUs. See [process directives documentation](https://www.nextflow.io/docs/latest/process.html#directives) for more details.

!!! question "Exercise"

    Use the `nextflow run` command to execute `script2.nf`:

    ```bash
    nextflow run script2.nf
    ```

This execution will fail because `salmon` is not installed in your environment. Fortunately, a docker container image with the salmon software is available and has already been defined in your `nextflow.config` file.

Nextflow has support for managing the execution of processes in Docker containers. This is useful when you need to execute a process that requires a specific software version or a specific operating system.

!!! question "Exercise"

    Add the command line option `-with-docker` to launch `script2.nf` with the docker container:

    ```bash
    nextflow run script2.nf -with-docker
    ```

This time the execution will work because it uses the Docker container `nextflow/rnaseq-nf` that is defined in the `nextflow.config` file in your current directory. If you are running this script locally, you will need to download Docker to your machine, log in, activate Docker, and allow the script to download the container containing the run scripts.

You can learn more about Docker [here](https://www.nextflow.io/docs/latest/docker.html).

To avoid being required to add `-with-docker` to your execution command every time you execute the script, you can enable docker in your `nextflow.config` file.

!!! question "Exercise"

    Enable docker by adding `docker.enabled = true` to your `nextflow.config` file.

Viewing a channel with the [`view`](https://www.nextflow.io/docs/latest/operator.html#view) operator is a useful way to see what is in a channel and is useful for testing and debugging:

!!! question "Exercise"

    Print the output of the `index_ch` channel by using the [view](https://www.nextflow.io/docs/latest/operator.html#view) operator.

    ??? Solution

        Add the following to the end of your workflow block in your script file

        ```groovy linenums="35" title="script2.nf"
        workflow {
            index_ch = INDEX(params.transcriptome_file)
            index_ch.view()
        }
        ```

Directives are used to specify the execution requirements of a process. For example, the `cpus` directive specifies the number of CPUs required to execute the process. Directives can be added under the `process` declaration.

```groovy linenums="22" title="script2.nf"
process PROCESS_NAME {
    cpus 2
    ...
}
```

!!! question "Exercise"

    Add the `cpus` directive to the `INDEX` process to modify the number of CPUs allocated for its execution.

    ??? Solution

        Add `cpus 2` to the top of the index process:

        ```groovy linenums="22" title="script2.nf"
        process INDEX {
            cpus 2

            input:
            ...
        ```

        You can check the directive has been applied by viewing the script executed in the work directory. Look for the hexadecimal (e.g. `work/7f/f285b80022d9f61e82cd7f90436aa4/`), then `cat` the `.command.sh` file.

        ```bash
        cat work/7f/f285b80022d9f61e82cd7f90436aa4/.command.sh
        ```

Nextflow will organize the process work directory into a series of folders. The hexadecimal folder name is the process identifier. You can view the structure of these files using the `tree` command.

For example, executing `tree work` should look something like this:

```console title="Output"
work
├── 17
│   └── 263d3517b457de4525513ae5e34ea8
│       ├── index
│       │   ├── complete_ref_lens.bin
│       │   ├── ctable.bin
│       │   ├── ctg_offsets.bin
│       │   ├── duplicate_clusters.tsv
│       │   ├── eqtable.bin
│       │   ├── info.json
│       │   ├── mphf.bin
│       │   ├── pos.bin
│       │   ├── pre_indexing.log
│       │   ├── rank.bin
│       │   ├── refAccumLengths.bin
│       │   ├── ref_indexing.log
│       │   ├── reflengths.bin
│       │   ├── refseq.bin
│       │   ├── seq.bin
│       │   └── versionInfo.json
│       └── transcriptome.fa -> /workspace/Gitpod_test/data/ggal/transcriptome.fa
├── 7f
```

!!! cboard-list-2 "Summary"

    In this step you have learned:

    1. How to define a process executing a custom command
    2. How process inputs are declared
    3. How process outputs are declared
    4. How to view a channel
    5. How to add a directive to a process

## Collect read files by pairs

There are numerous channel factories that can be used to create channels. In this step, you will use the [fromFilePairs](https://www.nextflow.io/docs/latest/channel.html#fromfilepairs) channel factory to create a channel of read pairs.

The `fromFilePairs` channel factory takes a glob pattern as input and returns a channel of tuples. Each tuple contains two items: the first is the read pair prefix and the second is a list of paths to the read files.

By adding the `view` operator to the `read_pairs_ch` channel, you can see the contents of the channel.

!!! question "Exercise"

    Add the `read_pairs_ch.view()` command to the end of your workflow block in your script file.

    ??? Solution

        Add the following to the end of your workflow block in your script file

        ```groovy linenums="19" title="script3.nf"
        read_pairs_ch.view()
        ```

        It will print something similar to this:

        ```console title="Output"
        [gut, [/.../data/ggal/gut_1.fq, /.../data/ggal/gut_2.fq]]
        ```

The above exercise shows how the `read_pairs_ch` channel emits tuples composed of two items, where the first is the read pair prefix and the second is a list representing the actual files.

Glob patterns can also be used to create channels of files. For example, the following command creates a channel of all the files in the `data/ggal` directory:

```bash
nextflow run script3.nf --reads 'data/ggal/*_{1,2}.fq'
```

!!! warning

    File paths that include one or more wildcards ie. `*`, `?`, etc., MUST be wrapped in single-quoted characters to avoid Bash expanding the glob.

The [`set`](https://www.nextflow.io/docs/latest/operator.html#set) operator can also be used to define a new channel variable in place of an `=` assignment.

!!! question "Exercise"

    Use the [set](https://www.nextflow.io/docs/latest/operator.html#set) operator in place of `=` assignment to define the `read_pairs_ch` channel.

    ??? Solution

        ```groovy linenums="18" title="script3.nf"
        Channel
            .fromFilePairs(params.reads)
            .set { read_pairs_ch }
        ```

Channel factories also have options that can be used to modify their behaviour. For example, the `checkIfExists` option can be used to check if the specified path contains file pairs. If the path does not contain file pairs, an error is thrown. A full list of options can be found in the [channel factory documentation](https://www.nextflow.io/docs/latest/channel.html#channel-factories).

!!! question "Exercise"

    Use the `checkIfExists` option for the [fromFilePairs](https://www.nextflow.io/docs/latest/channel.html#fromfilepairs) channel factory to check if the specified path contains file pairs.

    ??? Solution

        ```groovy linenums="18" title="script3.nf"
        Channel
            .fromFilePairs(params.reads, checkIfExists: true)
            .set { read_pairs_ch }
        ```

!!! cboard-list-2 "Summary"

    In this step you have learned:

    1. How to use `fromFilePairs` to handle read pair files
    2. How to use the `set` operator to define a new channel variable
    3. How to use the `checkIfExists` option to check for the existence of input files

!!! info

    The declaration of a channel can be before the workflow scope or within it. As long as it is upstream of the process that requires the specific channel.

## Perform expression quantification

`script4.nf` adds a gene expression `QUANTIFICATION` process and a call to it within the workflow scope. Quantification requires the index transcriptome and RNA-Seq read pair fastq files.

In the workflow scope, note how the `index_ch` channel is assigned as output in the `INDEX` process.

Next, note that the first input channel for the `QUANTIFICATION` process is the previously declared `index_ch`, which contains the `path` to the `salmon_index`.

Also, note that the second input channel for the `QUANTIFICATION` process, is the `read_pair_ch` you just created. This being a `tuple` composed of two items (a value: `sample_id` and a list of paths to the fastq reads: `reads`) in order to match the structure of the items emitted by the `fromFilePairs` channel factory.

Execute it by using the following command:

```bash
nextflow run script4.nf -resume
```

You will see the execution of the `QUANTIFICATION` process.

When using the `-resume` option, any step that has already been processed is skipped.

Try to execute the same script again with more read files, as shown below:

```bash
nextflow run script4.nf -resume --reads 'data/ggal/*_{1,2}.fq'
```

You will notice that the `QUANTIFICATION` process is executed multiple times.

Nextflow parallelizes the execution of your workflow simply by providing multiple sets of input data to your script.

!!! tip

    It may be useful to apply optional settings to a specific process using [directives](https://www.nextflow.io/docs/latest/process.html#directives) by specifying them in the process body.

!!! question "Exercise"

    Add a [tag](https://www.nextflow.io/docs/latest/process.html#tag) directive to the `QUANTIFICATION` process to provide a more readable execution log.

    ??? Solution

        Add the following before the input declaration:

        ```groovy linenums="35" title="script4.nf"
        process QUANTIFICATION {
            tag "Salmon on $sample_id"

            input:
            ...
        ```

!!! question "Exercise"

    Add a [publishDir](https://www.nextflow.io/docs/latest/process.html#publishdir) directive to the `QUANTIFICATION` process to store the process results in a directory of your choice.

    ??? Solution

        Add the following before the `input` declaration in the `QUANTIFICATION` process:

        ```groovy linenums="35" title="script4.nf"
        process QUANTIFICATION {
            tag "Salmon on $sample_id"
            publishDir params.outdir, mode: 'copy'

            input:
            ...
        ```

!!! cboard-list-2 "Summary"

    In this step you have learned:

    1. How to connect two processes together by using the channel declarations
    2. How to `resume` the script execution and skip cached steps
    3. How to use the `tag` directive to provide a more readable execution output
    4. How to use the `publishDir` directive to store a process results in a path of your choice

## Quality control

Next, you will implement a `FASTQC` quality control step for your input reads (using the label `fastqc`). The inputs are the same as the read pairs used in the `QUANTIFICATION` step.

You can run it by using the following command:

```bash
nextflow run script5.nf -resume
```

Nextflow DSL2 knows to split the `reads_pair_ch` into two identical channels as they are required twice as an input for both of the `FASTQC` and the `QUANTIFICATION` process.

## MultiQC report

This step collects the outputs from the `QUANTIFICATION` and `FASTQC` processes to create a final report using the [MultiQC](http://multiqc.info/) tool.

You can execute `script6.nf` with the following command:

```bash
nextflow run script6.nf -resume --reads 'data/ggal/*_{1,2}.fq'
```

It creates the final report in the `results` folder in the current `work` directory.

In this script, note the use of the [mix](https://www.nextflow.io/docs/latest/operator.html#mix) and [collect](https://www.nextflow.io/docs/latest/operator.html#collect) operators chained together to gather the outputs of the `QUANTIFICATION` and `FASTQC` processes as a single input. [Operators](https://www.nextflow.io/docs/latest/operator.html) can be used in combinations to combine, split, and transform channels.

```groovy linenums="91" title="script6.nf"
MULTIQC(quant_ch.mix(fastqc_ch).collect())
```

You will only want one task of MultiQC to be executed to produce one report. Therefore, you can use the `mix` channel operator to combine the `quant_ch` and the `fastqc_ch` channels, followed by the `collect` operator, to return the complete channel contents as a single element.

!!! question "Exercise"

    Remove the `collect` operators from the `MULTIQC` process and run the script again. See what happens.

    ??? Solution

        Modify the workflow block to look like this:

        ```groovy linenums="83" title="script6.nf"
        workflow {
            Channel
                .fromFilePairs(params.reads, checkIfExists: true)
                .set { read_pairs_ch }

            index_ch = INDEX(params.transcriptome_file)
            quant_ch = QUANTIFICATION(index_ch, read_pairs_ch)
            fastqc_ch = FASTQC(read_pairs_ch)
            MULTIQC(quant_ch.mix(fastqc_ch))
        }
        ```

        Note how the `MULTIQC` process is executed **6** times.

!!! cboard-list-2 "Summary"

    In this step you have learned:

    1. How to collect many outputs to a single input with the `collect` operator
    2. How to `mix` two channels into a single channel
    3. How to chain two or more operators together

## Handle completion event

This step shows how to execute an action when the workflow completes the execution.

Note that Nextflow processes define the execution of **asynchronous** tasks ,i.e., they are not executed one after another as if they were written in the workflow script in a common **imperative** programming language.

The script uses the `workflow.onComplete` event handler to print a confirmation message when the script completes.

Try to run it by using the following command:

```bash
nextflow run script7.nf -resume --reads 'data/ggal/*_{1,2}.fq'
```

!!! cboard-list-2 "Summary"

    In this step you have learned:

    1. How to add completion events to your workflow

## Email notifications

Send a notification email when the workflow execution completes using the `-N <email address>` command-line option.

Note: this requires the configuration of a SMTP server in the nextflow config file. Below is an example `nextflow.config` file showing the settings you would have to configure:

```groovy linenums="1" title="nextflow.config"
mail {
    from = 'info@nextflow.io'
    smtp.host = 'email-smtp.eu-west-1.amazonaws.com'
    smtp.port = 587
    smtp.user = "xxxxx"
    smtp.password = "yyyyy"
    smtp.auth = true
    smtp.starttls.enable = true
    smtp.starttls.required = true
}
```

See [mail documentation](https://www.nextflow.io/docs/latest/mail.html#mail-configuration) for details.

## Custom scripts

Real-world workflows use a lot of custom user scripts (BASH, R, Python, etc.).
Nextflow allows you to consistently use and manage these scripts.
Simply put them in a directory named `bin` in the workflow project root.
They will be automatically added to the workflow execution `PATH`.

For example, the `FASTQC` process in `script7.nf` could be replaced by creating an executable script named `fastqc.sh` in the `bin` directory as shown below:

Create a new file named `fastqc.sh` with the following content:

```bash linenums="1" title="fastqc.sh"
#!/bin/bash
set -e
set -u

sample_id=${1}
reads=${2}

mkdir fastqc_${sample_id}_logs
fastqc -o fastqc_${sample_id}_logs -f fastq -q ${reads}
```

Give it execute permission and move it into the `bin` directory:

```bash
chmod +x fastqc.sh
mkdir -p bin
mv fastqc.sh bin
```

Open the `script7.nf` file and replace the `FASTQC` process script block with the following code:

```groovy linenums="60" title="script7.nf"
script:
"""
fastqc.sh "$sample_id" "$reads"
"""
```

!!! question "Exercise"

    Use the example above to replace the `FASTQC` process script block in `script7.nf` with an executable `fastqc.sh` script.

!!! cboard-list-2 "Summary"

    In this step you have learned:

    1. How to write or use existing custom scripts in your Nextflow workflow
    2. How to avoid the use of absolute paths by having your scripts in the `bin/` folder

## Metrics and reports

Nextflow can produce multiple reports and charts providing several runtime metrics and execution information. These can be enabled by using the following command line options:

The `-with-report` option enables the creation of the workflow execution report.

The `-with-trace` option enables the creation of a tab separated value (TSV) file containing runtime information for each executed task.

The `-with-timeline` option enables the creation of the workflow timeline report showing how processes were executed over time. This may be useful to identify the most time consuming tasks and bottlenecks.

Finally, the `-with-dag` option enables the rendering of the workflow execution direct acyclic graph representation. The dag needs to be given a name (`-with-dag dag.png`). Note: This feature requires the installation of [Graphviz](http://www.graphviz.org/) on your computer. See [here](https://www.nextflow.io/docs/latest/tracing.html#dag-visualisation) for further details. You can also output HTML DAGs, and the `-preview` command my allow you to have a look at an approximate DAG without having to run the pipeline.

!!! question "Exercise"

    Execute `script7.nf` and and generate a report (`-with-report`), trace (`-with-trace`), timeline (`-with-timeline`), and dag ('-with-dag dag.png').

    ??? Solution

        ```bash
        nextflow run script7.nf -with-docker -with-report -with-trace -with-timeline -with-dag dag.png
        ```

        You can view the DAG by using the following command:

        ```bash
        open dag.png
        ```

        You can view the HTML files by right-clicking on the file name in the left side-bar and choosing the **Show Preview** menu item.

        !!! warning

            Run time metrics may be incomplete for runs with short running tasks, as in the case of this tutorial.

!!! cboard-list-2 "Summary"

    In this step you have learned:

    1. How to generate reports and charts for your executions

## Run a project from GitHub

Nextflow allows the execution of a workflow project directly from a GitHub repository (or similar services, e.g., BitBucket and GitLab).

This simplifies the sharing and deployment of complex projects and tracking changes in a consistent manner.

The following GitHub repository hosts a version of the workflow introduced in this tutorial: <https://github.com/nextflow-io/rnaseq-nf>

You can run it by specifying the project name and launching each task of the execution as a Docker container run command:

```bash
nextflow run nextflow-io/rnaseq-nf -with-docker
```

It automatically downloads the container and stores it in the `$HOME/.nextflow` folder.

The nextflow `info` command can be used to show the project information:

```bash
nextflow info nextflow-io/rnaseq-nf
```

Nextflow allows the execution of a specific revision of your project by using the `-r` command line option. For example:

```bash
nextflow run nextflow-io/rnaseq-nf -r v2.1 -with-docker
```

Revisions are defined by using Git tags or branches defined in the project repository.

Tags enable precise control of the changes in your project files and dependencies over time.

!!! cboard-list-2 "Summary"

    In this step you have learned:

    1. How to execute a project directly from GitHub
    2. How to specify a specific revision of a project
