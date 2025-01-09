---
title: Channels
description: Fundamentals Nextflow Training Workshop
---

# Channels

Channels are a key data structure of Nextflow that allows the implementation of reactive-functional oriented computational workflows based on the [Dataflow](https://en.wikipedia.org/wiki/Dataflow_programming) programming paradigm.

They are used to logically connect tasks to each other or to implement functional style data transformations.

<figure class="excalidraw">
--8<-- "docs/basic_training/img/channel-files.excalidraw.svg"
</figure>

## Channel types

Nextflow distinguishes two different kinds of channels: **queue** channels and **value** channels.

### Queue channel

A **queue** channel is an _asynchronous_ unidirectional _FIFO_ queue that connects two processes or operators.

-   _asynchronous_ means that operations are non-blocking.
-   _unidirectional_ means that data flows from a producer to a consumer.
-   _FIFO_ means that the data is guaranteed to be delivered in the same order as it is produced. First In, First Out.

A queue channel is implicitly created by process output definitions or using channel factories such as [Channel.of](https://www.nextflow.io/docs/latest/channel.html#of) or [Channel.fromPath](https://www.nextflow.io/docs/latest/channel.html#frompath).

Try the following snippets:

!!! info ""

    Click the :material-plus-circle: icons in the code for explanations.

```groovy linenums="1" title="snippet.nf"
ch = Channel.of(1, 2, 3)
ch.view() // (1)!
```

1. Applying the `view` channel operator to the `ch` channel prints each item emitted by the channels

!!! question "Exercise"

    The script `snippet.nf` contains the code from above. Execute it with Nextflow and view the output.

    ??? solution

        Run the following command:

        ```bash
        nextflow run snippet.nf
        ```

        The output should be:

        ```console title="Output"
        1
        2
        3
        ```

### Value channels

A **value** channel (a.k.a. a singleton channel) is bound to a single value and it can be read unlimited times without consuming its contents. A `value` channel is created using the [value](https://www.nextflow.io/docs/latest/channel.html#value) channel factory or by operators returning a single value, such as [first](https://www.nextflow.io/docs/latest/operator.html#first), [last](https://www.nextflow.io/docs/latest/operator.html#last), [collect](https://www.nextflow.io/docs/latest/operator.html#operator-collect), [count](https://www.nextflow.io/docs/latest/operator.html#operator-count), [min](https://www.nextflow.io/docs/latest/operator.html#operator-min), [max](https://www.nextflow.io/docs/latest/operator.html#operator-max), [reduce](https://www.nextflow.io/docs/latest/operator.html#operator-reduce), and [sum](https://www.nextflow.io/docs/latest/operator.html#operator-sum).

To see the difference between value and queue channels, you can modify `snippet.nf` to the following:

```groovy linenums="1" title="snippet.nf"
ch1 = Channel.of(1, 2, 3)
ch2 = Channel.of(1)

process SUM {
    input:
    val x
    val y

    output:
    stdout

    script:
    """
    echo \$(($x+$y))
    """
}

workflow {
    SUM(ch1, ch2).view()
}
```

This workflow creates two channels, `ch1` and `ch2`, and then uses them as inputs to the `SUM` process. The `SUM` process sums the two inputs and prints the result to the standard output.

When you run this script, it only prints `2`, as you can see below:

```console title="Output"
2
```

A process will only instantiate a task when there are elements to be consumed from _all_ the channels provided as input to it. Because `ch1` and `ch2` are queue channels, and the single element of `ch2` has been consumed, no new process instances will be launched, even if there are other elements to be consumed in `ch1`.

To use the single element in `ch2` multiple times, you can either use the `Channel.value` channel factory, or use a channel operator that returns a single element, such as `first()`:

```groovy linenums="1" title="snippet.nf"
ch1 = Channel.of(1, 2, 3)
ch2 = Channel.value(1)

process SUM {
    input:
    val x
    val y

    output:
    stdout

    script:
    """
    echo \$(($x+$y))
    """
}

workflow {
    SUM(ch1, ch2).view()
}
```

```console title="Output"
2
3
4
```

In many situations, Nextflow will implicitly convert variables to value channels when they are used in a process invocation.

For example, when you invoke a process with a workflow parameter (`params.ch2`) which has a string value, it is automatically cast into a value channel:

```groovy linenums="1" title="snippet.nf"
ch1 = Channel.of(1, 2, 3)
params.ch2 = "1"

process SUM {
    input:
    val x
    val y

    output:
    stdout

    script:
    """
    echo \$(($x+$y))
    """
}

workflow {
    SUM(ch1, params.ch2).view()
}
```

As you can see, the output is the same as the previous example when the `first()` operator was used:

```console title="Output"
2
3
4
```

!!! question "Exercise"

    Use the `.first()` operator to create a value channel from `ch2` so that all 3 elements of `ch1` are consumed.

    ```groovy linenums="1" title="snippet.nf"
    ch1 = Channel.of(1, 2, 3)
    ch2 = Channel.of(1)

    process SUM {
        input:
        val x
        val y

        output:
        stdout

        script:
        """
        echo \$(($x+$y))
        """
    }

    workflow {
        SUM(ch1, ch2).view()
    }
    ```

    ??? solution

        Modify the `workflow` section to the following:

        ```groovy linenums="1" title="snippet.nf"
        workflow {
            SUM(ch1, ch2.first()).view()
        }
        ```

!!! cboard-list-2 "Summary"

    In this step you have learned:

    1. The features of a value and queue channels
    3. Strategies to change channel types

## Channel factories

Channel factories are Nextflow commands for creating channels that have implicit expected inputs and functions. There are several different Channel factories which are useful for different situations. The following sections will cover the most common channel factories.

!!! tip

    New in version 20.07.0: channel was introduced as an alias of Channel, allowing factory methods to be specified as `channel.of()` or `Channel.of()`, and so on.

### `value()`

The `value` channel factory is used to create a _value_ channel. An optional not `null` argument can be specified to bind the channel to a specific value. For example:

```groovy linenums="1" title="snippet.nf"
ch1 = Channel.value() // (1)!
ch2 = Channel.value('Hello there') // (2)!
ch3 = Channel.value([1, 2, 3, 4, 5]) // (3)!
```

1. Creates an _empty_ value channel
2. Creates a value channel and binds a string to it
3. Creates a value channel and binds a list object to it that will be emitted as a sole emission

### `of()`

The factory `Channel.of` allows the creation of a queue channel with the values specified as arguments.

```groovy linenums="1" title="snippet.nf"
Channel
    .of(1, 3, 5, 7)
    .view()
```

This example creates a channel that emits the values specified as a parameter in the `of` channel factory. It will print the following:

```console title="Output"
1
3
5
7
```

The `Channel.of` channel factory works in a similar manner to `Channel.from` (which is now [deprecated](https://www.nextflow.io/docs/latest/channel.html#of)), fixing some inconsistent behaviors of the latter and providing better handling when specifying a range of values. For example, the following works with a range from 1 to 23:

```groovy linenums="1" title="snippet.nf"
Channel
    .of(1..23, 'X', 'Y')
    .view()
```

### `fromList()`

The `Channel.fromList` channel factory creates a channel emitting the elements provided by a list object specified as an argument:

```groovy linenums="1" title="snippet.nf"
list = ['hello', 'world']

Channel
    .fromList(list)
    .view()
```

### `fromPath()`

The `fromPath` channel factory creates a queue channel emitting one or more files matching the specified glob pattern.

```groovy linenums="1" title="snippet.nf"
Channel
    .fromPath('./data/meta/*.csv')
```

This example creates a channel and emits as many items as there are files with a `csv` extension in the `./data/meta` folder. Each element is a file object implementing the [Path](https://docs.oracle.com/javase/8/docs/api/java/nio/file/Paths.html) interface.

!!! tip

    Two asterisks, i.e. `**`, works like `*` but cross directory boundaries. This syntax is generally used for matching complete paths. Curly brackets specify a collection of sub-patterns.

Some channel factories also have options to help you control their behaviour. For example, the `fromPath` channel factory has the following options:

| Name          | Description                                                                                                                                |
| ------------- | ------------------------------------------------------------------------------------------------------------------------------------------ |
| glob          | When `true` interprets characters `*`, `?`, `[]` and `{}` as glob wildcards, otherwise handles them as normal characters (default: `true`) |
| type          | Type of path returned, either `file`, `dir` or `any` (default: `file`)                                                                     |
| hidden        | When `true` includes hidden files in the resulting paths (default: `false`)                                                                |
| maxDepth      | Maximum number of directory levels to visit (default: `no limit`)                                                                          |
| followLinks   | When `true` symbolic links are followed during directory tree traversal, otherwise they are managed as files (default: `true`)             |
| relative      | When `true` return paths are relative to the top-most common directory (default: `false`)                                                  |
| checkIfExists | When `true` throws an exception when the specified path does not exist in the file system (default: `false`)                               |

Learn more about the glob patterns syntax at [this link](https://docs.oracle.com/javase/tutorial/essential/io/fileOps.html#glob).

!!! question "Exercise"

    Use the `Channel.fromPath` channel factory to create a channel emitting all files with the suffix `.fq` in the `data/ggal/` directory and any subdirectory. Include any hidden files and print the file names with the `view` operator.

    ??? solution

        ```groovy linenums="1" title="snippet.nf"
        Channel
            .fromPath('./data/ggal/**.fq', hidden: true)
            .view()
        ```

### `fromFilePairs()`

The `fromFilePairs` channel factory creates a channel emitting the file pairs matching a glob pattern provided by the user. The matching files are emitted as tuples, in which the first element is the grouping key of the matching pair and the second element is the list of files (sorted in lexicographical order).

```groovy linenums="1" title="snippet.nf"
Channel
    .fromFilePairs('./data/ggal/*_{1,2}.fq')
    .view()
```

It will produce an output similar to the following:

```console title="Output"
[liver, [/workspace/gitpod/nf-training/data/ggal/liver_1.fq, /workspace/gitpod/nf-training/data/ggal/liver_2.fq]]
[gut, [/workspace/gitpod/nf-training/data/ggal/gut_1.fq, /workspace/gitpod/nf-training/data/ggal/gut_2.fq]]
[lung, [/workspace/gitpod/nf-training/data/ggal/lung_1.fq, /workspace/gitpod/nf-training/data/ggal/lung_2.fq]]
```

!!! warning

    The glob pattern _must_ contain at least a star wildcard character (`*`).

The `fromFilePairs` channel factory also has options to help you control its behaviour:

| Name          | Description                                                                                                                    |
| ------------- | ------------------------------------------------------------------------------------------------------------------------------ |
| type          | Type of paths returned, either `file`, `dir` or `any` (default: `file`)                                                        |
| hidden        | When `true` includes hidden files in the resulting paths (default: `false`)                                                    |
| maxDepth      | Maximum number of directory levels to visit (default: `no limit`)                                                              |
| followLinks   | When `true` symbolic links are followed during directory tree traversal, otherwise they are managed as files (default: `true`) |
| size          | Defines the number of files each emitted item is expected to hold (default: `2`). Set to `-1` for any                          |
| flat          | When `true` the matching files are produced as sole elements in the emitted tuples (default: `false`)                          |
| checkIfExists | When `true`, it throws an exception of the specified path that does not exist in the file system (default: `false`)            |

!!! question "Exercise"

    Use the `fromFilePairs` channel factory to create a channel emitting all pairs of fastq reads in the `data/ggal/` directory. Execute this script twice, once with the option `flat: true` and once with `flat: false`. What is the difference?

    ??? solution

        Use the following with the `flat` option equaling true:

        ```groovy linenums="1" title="snippet.nf"
        Channel
            .fromFilePairs('./data/ggal/*_{1,2}.fq', flat: true)
            .view()
        ```

        And false:

        ```groovy linenums="1" title="snippet.nf"
        Channel
            .fromFilePairs('./data/ggal/*_{1,2}.fq', flat: false)
            .view()
        ```
        Check the square brackets around the file names, to see the difference with `flat`.

### `fromSRA()`

The `Channel.fromSRA` channel factory makes it possible to query the [NCBI SRA](https://www.ncbi.nlm.nih.gov/sra) archive and returns a channel emitting the FASTQ files matching the specified selection criteria.

The query can be project ID(s) or accession number(s) supported by the [NCBI ESearch API](https://www.ncbi.nlm.nih.gov/books/NBK25499/#chapter4.ESearch).

!!! info

    This function now requires an API key you can only get by logging into your NCBI account.

??? example "Instructions for NCBI login and key acquisition"

    1. Go to: <https://www.ncbi.nlm.nih.gov/>
    2. Click the top right "Log in" button to sign into NCBI. Follow their instructions.
    3. Once into your account, click the button at the top right, usually your ID.
    4. Go to Account settings
    5. Scroll down to the API Key Management section.
    6. Click on "Create an API Key".
    7. The page will refresh and the key will be displayed where the button was. Copy your key.

The following snippet will print the contents of an NCBI project ID:

```groovy linenums="1" title="snippet.nf"
params.ncbi_api_key = '<Your API key here>'

Channel
    .fromSRA(['SRP073307'], apiKey: params.ncbi_api_key)
    .view()
```

!!! info ""

    :material-lightbulb: Replace `<Your API key here>` with your API key.

This should print:

```console title="Output"
[SRR3383346, [/vol1/fastq/SRR338/006/SRR3383346/SRR3383346_1.fastq.gz, /vol1/fastq/SRR338/006/SRR3383346/SRR3383346_2.fastq.gz]]
[SRR3383347, [/vol1/fastq/SRR338/007/SRR3383347/SRR3383347_1.fastq.gz, /vol1/fastq/SRR338/007/SRR3383347/SRR3383347_2.fastq.gz]]
[SRR3383344, [/vol1/fastq/SRR338/004/SRR3383344/SRR3383344_1.fastq.gz, /vol1/fastq/SRR338/004/SRR3383344/SRR3383344_2.fastq.gz]]
[SRR3383345, [/vol1/fastq/SRR338/005/SRR3383345/SRR3383345_1.fastq.gz, /vol1/fastq/SRR338/005/SRR3383345/SRR3383345_2.fastq.gz]]
// (remaining omitted)
```

Multiple accession IDs can be specified using a list object:

```groovy linenums="1" title="snippet.nf"
ids = ['ERR908507', 'ERR908506', 'ERR908505']
Channel
    .fromSRA(ids, apiKey: params.ncbi_api_key)
    .view()
```

```console title="Output"
[ERR908507, [/vol1/fastq/ERR908/ERR908507/ERR908507_1.fastq.gz, /vol1/fastq/ERR908/ERR908507/ERR908507_2.fastq.gz]]
[ERR908506, [/vol1/fastq/ERR908/ERR908506/ERR908506_1.fastq.gz, /vol1/fastq/ERR908/ERR908506/ERR908506_2.fastq.gz]]
[ERR908505, [/vol1/fastq/ERR908/ERR908505/ERR908505_1.fastq.gz, /vol1/fastq/ERR908/ERR908505/ERR908505_2.fastq.gz]]
```

!!! info

    Read pairs are implicitly managed and are returned as a list of files.

It’s straightforward to use this channel as an input using the usual Nextflow syntax

The code below creates a channel containing two samples from a public SRA study and runs `FASTQC` on the resulting files. See:

```groovy linenums="1" title="snippet.nf"
params.ncbi_api_key = '<Your API key here>'

params.accession = ['ERR908507', 'ERR908506']

process FASTQC {
    input:
    tuple val(sample_id), path(reads_file)

    output:
    path("fastqc_${sample_id}_logs")

    script:
    """
    mkdir fastqc_${sample_id}_logs
    fastqc -o fastqc_${sample_id}_logs -f fastq -q ${reads_file}
    """
}

workflow {
    reads = Channel.fromSRA(params.accession, apiKey: params.ncbi_api_key)
    FASTQC(reads)
}
```

!!! cboard-list-2 "Summary"

    In this step you have learned:

    1. How to use common channel factories
    2. How to use the `fromSRA` channel factory to query the NCBI SRA archive
