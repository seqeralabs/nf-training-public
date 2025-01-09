---
title: Processes
description: Fundamentals Nextflow Training Workshop
---

# Processes

In Nextflow, a `process` is the basic computing primitive to execute foreign functions (i.e., custom scripts or tools).

The `process` definition starts with the keyword `process`, followed by the process name and finally the process body delimited by curly brackets.

A basic `process`, only using the `script` definition block, looks like the following:

```groovy linenums="1" title="snippet.nf"
process SAYHELLO {
    script:
    """
    echo 'Hello world!'
    """
}
```

!!! info

    The `process` name is commonly written in upper case by convention.

However, the process body can contain up to **five** definition blocks:

1. **Directives** are initial declarations that define optional settings
2. **Input** defines the expected input channel(s)
3. **Output** defines the expected output channel(s)
4. **When** is an optional clause statement to allow conditional processes
5. **Script** is a string statement that defines the command to be executed by the process' task

The full process syntax is defined as follows:

!!! info ""

    Click the :material-plus-circle: icons in the code for explanations.

```groovy linenums="1"
process < name > {
    [ directives ] // (1)!

    input: // (2)!
    < process inputs >

    output: // (3)!
    < process outputs >

    when: // (4)!
    < condition >

    [script|shell|exec]: // (5)!
    """
    < user script to be executed >
    """
}
```

1. Zero, one, or more process directives
2. Zero, one, or more process inputs
3. Zero, one, or more process outputs
4. An optional boolean conditional to trigger the process execution
5. The command to be executed

## Script

The `script` block is a string statement that defines the command to be executed by the process.

A process can execute only one `script` block. It must be the last statement when the process contains `input` and `output` declarations.

The `script` block can be a single or a multi-line string. The latter simplifies the writing of non-trivial scripts composed of multiple commands spanning over multiple lines. For example:

```groovy linenums="1" title="snippet.nf"
process EXAMPLE {
    script:
    """
    echo 'Hello world!\nHola mundo!\nCiao mondo!\nHallo Welt!' > file
    cat file | head -n 1 | head -c 5 > chunk_1.txt
    gzip -c chunk_1.txt  > chunk_archive.gz
    """
}

workflow {
    EXAMPLE()
}
```

!!! tip

    In the snippet below the directive `debug` is used to enable the debug mode for the process. This is useful to print the output of the process script in the console.

By default, the `process` command is interpreted as a **Bash** script. However, any other scripting language can be used by simply starting the script with the corresponding [Shebang](<https://en.wikipedia.org/wiki/Shebang_(Unix)>) declaration. For example:

```groovy linenums="1" title="snippet.nf"
process PYSTUFF {
    debug true

    script:
    """
    #!/usr/bin/env python

    x = 'Hello'
    y = 'world!'
    print ("%s - %s" % (x, y))
    """
}

workflow {
    PYSTUFF()
}
```

```console title="Output"
Hello-world
```

!!! tip

    Multiple programming languages can be used within the same workflow script. However, for large chunks of code it is better to save them into separate files and invoke them from the process script. One can store the specific scripts in the `./bin/` folder.

### Script parameters

Script parameters (`params`) can be defined dynamically using variable values. For example:

```groovy linenums="1" title="snippet.nf"
params.data = 'World'

process FOO {
    debug true

    script:
    """
    echo Hello $params.data
    """
}

workflow {
    FOO()
}
```

```console title="Output"
Hello World
```

!!! info

    A process script can contain any string format supported by the Groovy programming language. This allows us to use string interpolation as in the script above or multiline strings. Refer to [String interpolation](../groovy#string-interpolation) for more information.

!!! warning

    Since Nextflow uses the same Bash syntax for variable substitutions in strings, Bash environment variables need to be escaped using the `\` character. The escaped version will be resolved later, returning the task directory (e.g. work/7f/f285b80022d9f61e82cd7f90436aa4/), while `$PWD` would show the directory where you're running Nextflow.

```groovy linenums="1" title="snippet.nf"
process FOO {
    debug true

    script:
    """
    echo "The current directory is \$PWD"
    """
}

workflow {
    FOO()
}
```

Your expected output will look something like this:

```console title="Output"
The current directory is /workspace/gitpod/nf-training/work/7a/4b050a6cdef4b6c1333ce29f7059a0
```

It can be tricky to write a script that uses many Bash variables. One possible alternative is to use a `script` string delimited by single-quote characters (`'`).

```groovy linenums="1" title="snippet.nf"
process BAR {
    debug true

    script:
    '''
    echo "The current directory is $PWD"
    '''
}

workflow {
    BAR()
}
```

Your expected output will look something like this:

```console title="Output"
The current directory is /workspace/gitpod/nf-training/work/7a/4b050a6cdef4b6c1333ce29f7059a0
```

However, this using the single quotes (`'`) will block the usage of Nextflow variables in the command script.

Another alternative is to use a `shell` statement instead of `script` and use a different syntax for Nextflow variables, e.g., `!{..}`. This allows the use of both Nextflow and Bash variables in the same script.

```groovy linenums="1" title="snippet.nf"
params.data = 'le monde'

process BAZ {
    shell:
    '''
    X='Bonjour'
    echo $X !{params.data}
    '''
}

workflow {
    BAZ()
}
```

### Conditional script

The process script can also be defined in a completely dynamic manner using an `if` statement or any other expression for evaluating a string value. For example:

```groovy linenums="1" title="snippet.nf"
params.compress = 'gzip'
params.file2compress = "$projectDir/data/ggal/transcriptome.fa"

process FOO {
    debug true

    input:
    path file

    script:
    if (params.compress == 'gzip')
        """
        echo "gzip -c $file > ${file}.gz"
        """
    else if (params.compress == 'bzip2')
        """
        echo "bzip2 -c $file > ${file}.bz2"
        """
    else
        throw new IllegalArgumentException("Unknown compressor $params.compress")
}

workflow {
    FOO(params.file2compress)
}
```

!!! question "Exercise"

    Execute this script using the command line to choose `bzip2` compression.

    ??? solution

        Execute the following command:

        ```bash
        nextflow run snippet.nf --compress bzip2
        ```

        The output will look like this:

        ```console title="Output"
        bzip2 -c transcriptome.fa > transcriptome.fa.bz2
        ```

!!! cboard-list-2 "Summary"

    In this step you have learned:

    1. How to use the `script` declaration to define the command to be executed by the process
    2. How to use the `params` variable to define dynamic script parameters
    3. How to use the `shell` declaration to define the command to be executed by the process
    4. How to use the `if` statement to define a conditional script

## Inputs

Nextflow process instances (tasks) are isolated from each other but can communicate between themselves by sending values through channels.

Inputs implicitly determine the dependencies and the parallel execution of the process. The process execution is fired each time _new_ data is ready to be consumed from the input channel:

<figure class="excalidraw">
--8<-- "docs/basic_training/img/channel-process.excalidraw.svg"
</figure>

The `input` block defines the names and qualifiers of variables that refer to channel elements directed at the process. You can only define one `input` block at a time, and it must contain one or more input declarations.

The `input` block follows the syntax shown below:

```groovy linenums="1"
input:
<input qualifier> <input name>
```

There are [several input qualifiers](https://www.nextflow.io/docs/latest/process.html#inputs) that can be used to define the input declaration. The most common are outlined in detail below.

### Input values

The `val` qualifier allows you to receive data of any type as input. It can be accessed in the process script by using the specified input name. For example:

```groovy linenums="1" title="snippet.nf"
num = Channel.of(1, 2, 3)

process BASICEXAMPLE {
    debug true

    input:
    val x

    script:
    """
    echo process job $x
    """
}

workflow {
    BASICEXAMPLE(num)
}
```

In the above example the process is executed three times, each time a value is received from the channel `num` it is used by the script. Thus, it results in an output similar to the one shown below:

```console title="Output"
process job 1
process job 2
process job 3
```

!!! warning

    The channel guarantees that items are delivered in the same order as they have been sent - but - since the process is executed in a parallel manner, there is no guarantee that they are processed in the same order as they are received.

### Input files

The `path` qualifier allows the handling of file values in the process execution context. This means that Nextflow will stage it in the process execution directory, and it can be accessed by the script using the name specified in the input declaration. For example:

```groovy linenums="1" title="snippet.nf"
reads = Channel.fromPath('data/ggal/*.fq')

process FOO {
    debug true

    input:
    path 'sample.fastq'

    script:
    """
    ls sample.fastq
    """
}

workflow {
    result = FOO(reads)
}
```

In this case, the process is executed six times and will print the name of the file `sample.fastq` six times as this is the name of the file in the input declaration and despite the input file name being different in each execution (e.g., `lung_1.fq`).

```console title="Output"
sample.fastq
sample.fastq
sample.fastq
sample.fastq
sample.fastq
sample.fastq
```

The input file name can also be defined using a variable reference as shown below:

```groovy linenums="1" title="snippet.nf"
reads = Channel.fromPath('data/ggal/*.fq')

process FOO {
    debug true

    input:
    path sample

    script:
    """
    ls  $sample
    """
}

workflow {
    result = FOO(reads)
}
```

In this case, the process is executed six times and will print the name of the variable input file six times (e.g., `lung_1.fq`).

```console title="Output"
lung_1.fq
gut_2.fq
liver_2.fq
lung_2.fq
liver_1.fq
gut_1.fq
```

The same syntax is also able to handle more than one input file in the same execution and only requires changing the channel composition using an operator (e.g., `collect`).

```groovy linenums="1" title="snippet.nf"
reads = Channel.fromPath('data/ggal/*.fq')

process FOO {
    debug true

    input:
    path sample

    script:
    """
    ls $sample
    """
}

workflow {
    FOO(reads.collect())
}
```

Note that while the output looks the same, this process is only executed once.

```console title="Output"
lung_1.fq
gut_2.fq
liver_2.fq
lung_2.fq
liver_1.fq
gut_1.fq
```

!!! warning

    In the past, the `file` qualifier was used for files, but the `path` qualifier should be preferred over file to handle process input files when using Nextflow 19.10.0 or later. When a process declares an input file, the corresponding channel elements must be **file** objects created with the file helper function from the file specific channel factories (e.g., `Channel.fromPath` or `Channel.fromFilePairs`).

### Combine input channels

A key feature of processes is the ability to handle inputs from multiple channels. However, it’s important to understand how channel contents and their semantics affect the execution of a process.

Consider the following example:

```groovy linenums="1" title="snippet.nf"
ch1 = Channel.of(1, 2, 3)
ch2 = Channel.of('a', 'b', 'c')

process FOO {
    debug true

    input:
    val x
    val y

    script:
    """
    echo $x and $y
    """
}

workflow {
    FOO(ch1, ch2)
}
```

Both channels emit three values, therefore the process is executed three times, each time with a different pair:

```console title="Output"
1 and a
3 and c
2 and b
```

The process waits until there’s a complete input configuration, i.e., it receives an input value from all the channels declared as input.

When this condition is verified, it consumes the input values coming from the respective channels, spawns a task execution, then repeats the same logic until one or more channels have no more content.

This means channel values are consumed serially one after another and the first empty channel causes the process execution to stop, even if there are other values in other channels.

What happens when channels do not have the same cardinality (i.e., they emit a different number of elements)?

```groovy linenums="1" title="snippet.nf"
ch1 = Channel.of(1, 2, 3)
ch2 = Channel.of('a')

process FOO {
    debug true

    input:
    val x
    val y

    script:
    """
    echo $x and $y
    """
}

workflow {
    FOO(ch1, ch2)
}
```

In the above example, the process is only executed once because the process stops when a channel has no more data to be processed.

```console title="Output"
1 and a
```

However, replacing `ch2` with a `value` channel will cause the process to be executed three times, each time with the same value of `a`:

```groovy linenums="1" title="snippet.nf"
ch1 = Channel.of(1, 2, 3)
ch2 = Channel.value('a')

process FOO {
    debug true

    input:
    val x
    val y

    script:
    """
    echo $x and $y
    """
}

workflow {
    FOO(ch1, ch2)
}
```

```console title="Script output"
1 and a
2 and a
3 and a
```

As `ch2` is now a _value_ channel, it can be consumed multiple times and do not affect process termination.

!!! question "Exercise"

    Write a process that is executed for each read file matching the pattern `data/ggal/*_1.fq` and use the same `data/ggal/transcriptome.fa` in each execution.

    ??? solution

        One possible solution is shown below:

        ```groovy linenums="1" title="snippet.nf"
        params.reads = "$projectDir/data/ggal/*_1.fq"
        params.transcriptome_file = "$projectDir/data/ggal/transcriptome.fa"

        Channel
            .fromPath(params.reads)
            .set { read_ch }

        process COMMAND {
            debug true

            input:
            path reads
            path transcriptome

            script:
            """
            echo $reads $transcriptome
            """
        }

        workflow {
            COMMAND(read_ch, params.transcriptome_file)
        }
        ```

        You may also consider using other Channel factories or operators to create your input channels.

### Input repeaters

The `each` qualifier allows you to repeat the execution of a process for each item in a collection every time new data is received. For example:

```groovy linenums="1" title="snippet.nf"
sequences = Channel.fromPath("$projectDir/data/ggal/*_1.fq")
methods = ['regular', 'espresso']

process ALIGNSEQUENCES {
    debug true

    input:
    path seq
    each mode

    script:
    """
    echo t_coffee -in $seq -mode $mode
    """
}

workflow {
    ALIGNSEQUENCES(sequences, methods)
}
```

```console title="Output"
t_coffee -in gut_1.fq -mode regular
t_coffee -in lung_1.fq -mode espresso
t_coffee -in liver_1.fq -mode regular
t_coffee -in gut_1.fq -mode espresso
t_coffee -in lung_1.fq -mode regular
t_coffee -in liver_1.fq -mode espresso
```

In the above example, every time a file of sequences is received as an input by the process, it executes three tasks, each running a different alignment method set as a `mode` variable. This is useful when you need to repeat the same task for a given set of parameters.

!!! question "Exercise"

    Extend the previous example so a task is executed for an additional type of coffee.

    ??? solution

        Modify the methods list and add another coffee type:

        ```groovy linenums="1" title="snippet.nf"
        sequences = Channel.fromPath("$projectDir/data/ggal/*_1.fq")
        methods = ['regular', 'espresso', 'cappuccino']

        process ALIGNSEQUENCES {
            debug true

            input:
            path seq
            each mode

            script:
            """
            echo t_coffee -in $seq -mode $mode
            """
        }

        workflow {
            ALIGNSEQUENCES(sequences, methods)
        }
        ```

        Your output will look something like this:

        ```console title="Output"
        t_coffee -in gut_1.fq -mode regular
        t_coffee -in lung_1.fq -mode regular
        t_coffee -in gut_1.fq -mode espresso
        t_coffee -in liver_1.fq -mode cappuccino
        t_coffee -in liver_1.fq -mode espresso
        t_coffee -in lung_1.fq -mode espresso
        t_coffee -in liver_1.fq -mode regular
        t_coffee -in gut_1.fq -mode cappuccino
        t_coffee -in lung_1.fq -mode cappuccino
        ```

!!! cboard-list-2 "Summary"

    In this step you have learned:

    1. How to use the `val` qualifier to define the input channel(s) of a process
    2. How to use the `path` qualifier to define the input file(s) of a process
    3. How to use the `each` qualifier to repeat the execution of a process for each item in a collection

## Outputs

The _output_ declaration block defines the channels used by the process to send out the results produced.

Only one output block, that can contain one or more output declaration, can be defined. The output block follows the syntax shown below:

```groovy linenums="1"
output:
<output qualifier> <output name>, emit: <output channel>
```

### Output values

The `val` qualifier specifies a defined _value_ in the script context. Values are frequently defined in the `input` and/or `output` declaration blocks, as shown in the following example:

```groovy linenums="1" title="snippet.nf"
greeting = "Hello world!"

process FOO {
    input:
    val x

    output:
    val x

    script:
    """
    echo $x > file
    """
}

workflow {
    FOO(Channel.of(greeting))
        .view()
}
```

### Output files

The `path` qualifier specifies one or more files produced by the process into the specified channel as an output.

```groovy linenums="1" title="snippet.nf"
process RANDOMNUM {
    output:
    path 'result.txt'

    script:
    """
    echo \$RANDOM > result.txt
    """
}

workflow {
    receiver_ch = RANDOMNUM()
    receiver_ch.view()
}
```

In the above example the process `RANDOMNUM` creates a file named `result.txt` containing a random number.

Since a file parameter using the same name is declared in the output block, the file is sent over the `receiver_ch` channel when the task is complete. A downstream `process` declaring the same channel as _input_ will be able to receive it.

### Multiple output files

When an output file name contains a wildcard character (`*` or `?`) it is interpreted as a [glob](http://docs.oracle.com/javase/tutorial/essential/io/fileOps.html#glob) path matcher. This allows us to _capture_ multiple files into a list object and output them as a sole emission. For example:

```groovy linenums="1" title="snippet.nf"
process SPLITLETTERS {
    output:
    path 'chunk_*'

    script:
    """
    printf 'Hola' | split -b 1 - chunk_
    """
}

workflow {
    letters = SPLITLETTERS()
    letters.view()
}
```

Prints the following:

```console title="Output"
[/workspace/gitpod/nf-training/work/ca/baf931d379aa7fa37c570617cb06d1/chunk_aa, /workspace/gitpod/nf-training/work/ca/baf931d379aa7fa37c570617cb06d1/chunk_ab, /workspace/gitpod/nf-training/work/ca/baf931d379aa7fa37c570617cb06d1/chunk_ac, /workspace/gitpod/nf-training/work/ca/baf931d379aa7fa37c570617cb06d1/chunk_ad]
```

Some caveats on glob pattern behavior:

-   Input files are not included in the list of possible matches
-   Glob pattern matches both files and directory paths
-   When a two stars pattern `**` is used to recourse across directories, only file paths are matched i.e., directories are not included in the result list.

!!! question "Exercise"

    Add the `flatMap` operator and see out the output changes. The documentation for the `flatMap` operator is available at [this link](https://www.nextflow.io/docs/latest/operator.html#flatmap).

    ??? Solution

        Add the `flatMap` operator to the `letters` channel.

        ```groovy linenums="1" title="snippet.nf"
        process SPLITLETTERS {
            output:
            path 'chunk_*'

            script:
            """
            printf 'Hola' | split -b 1 - chunk_
            """
        }

        workflow {
            letters = SPLITLETTERS()
            letters.flatMap().view()
        }
        ```

        Your output will look something like this:

        ```console title="Output"
        /workspace/gitpod/nf-training/work/54/9d79f9149f15085e00dde2d8ead150/chunk_aa
        /workspace/gitpod/nf-training/work/54/9d79f9149f15085e00dde2d8ead150/chunk_ab
        /workspace/gitpod/nf-training/work/54/9d79f9149f15085e00dde2d8ead150/chunk_ac
        /workspace/gitpod/nf-training/work/54/9d79f9149f15085e00dde2d8ead150/chunk_ad
        ```

### Dynamic output file names

When an output file name needs to be expressed dynamically, it is possible to define it using a dynamic string that references values defined in the input declaration block or in the script global context. For example:

```groovy linenums="1" title="snippet.nf"
species = ['cat', 'dog', 'sloth']
sequences = ['AGATAG', 'ATGCTCT', 'ATCCCAA']

Channel
    .fromList(species)
    .set { species_ch }

process ALIGN {
    input:
    val x
    val seq

    output:
    path "${x}.aln"

    script:
    """
    echo align -in $seq > ${x}.aln
    """
}

workflow {
    genomes = ALIGN(species_ch, sequences)
    genomes.view()
}
```

In the above example, each time the process is executed an alignment file is produced whose name depends on the actual value of the `x` input.

### Composite inputs and outputs

So far you have seen how to declare multiple input and output channels that can handle one value at a time. However, Nextflow can also handle a _tuple_ of values.

The `input` and `output` declarations for tuples must be declared with a `tuple` qualifier followed by the definition of each element in the tuple.

```groovy linenums="1" title="snippet.nf"
reads_ch = Channel.fromFilePairs('data/ggal/*_{1,2}.fq')

process FOO {
    input:
    tuple val(sample_id), path(sample_id_paths)

    output:
    tuple val(sample_id), path('sample.bam')

    script:
    """
    echo your_command_here --sample $sample_id_paths > sample.bam
    """
}

workflow {
    sample_ch = FOO(reads_ch)
    sample_ch.view()
}
```

The output will looks something like this:

```console title="Output"
[lung, /workspace/gitpod/nf-training/work/23/fe268295bab990a40b95b7091530b6/sample.bam]
[liver, /workspace/gitpod/nf-training/work/32/656b96a01a460f27fa207e85995ead/sample.bam]
[gut, /workspace/gitpod/nf-training/work/ae/3cfc7cf0748a598c5e2da750b6bac6/sample.bam]
```

!!! question "Exercise"

    Modify the script of the previous exercise so that the _--sample_ file is named as the given `sample_id`.

    ??? solution

        ```groovy linenums="1" title="snippet.nf"
        reads_ch = Channel.fromFilePairs('data/ggal/*_{1,2}.fq')

        process FOO {
            input:
            tuple val(sample_id), path(sample_id_paths)

            output:
            tuple val(sample_id), path("${sample_id}.bam")

            script:
            """
            echo your_command_here --sample $sample_id_paths > ${sample_id}.bam
            """
        }

        workflow {
            sample_ch = FOO(reads_ch)
            sample_ch.view()
        }
        ```

### Output definitions

Nextflow allows the use of alternative output definitions within workflows to simplify your code.

You can also explicitly define the output of a channel using the `.out` attribute:

```groovy linenums="1" title="snippet.nf"
reads_ch = Channel.fromFilePairs('data/ggal/*_{1,2}.fq')

process FOO {
    input:
    tuple val(sample_id), path(sample_id_paths)

    output:
    tuple val(sample_id), path('sample.bam')
    tuple val(sample_id), path('sample.bai')

    script:
    """
    echo your_command_here --sample $sample_id_paths > sample.bam
    echo your_command_here --sample $sample_id_paths > sample.bai
    """
}

workflow {
    FOO(reads_ch)
    FOO.out.view()
}
```

This command will produce an error message, because `.view()` operates on single channels, and FOO.out contains multiple channels.

If a process defines two or more output channels, each channel can be accessed by indexing the `.out` attribute, e.g., `.out[0]`, `.out[1]`, etc. In this example you only have the `[0]'th` output:

```groovy linenums="1" title="snippet.nf"
reads_ch = Channel.fromFilePairs('data/ggal/*_{1,2}.fq')

process FOO {
    input:
    tuple val(sample_id), path(sample_id_paths)

    output:
    tuple val(sample_id), path('sample.bam')
    tuple val(sample_id), path('sample.bai')

    script:
    """
    echo your_command_here --sample $sample_id_paths > sample.bam
    echo your_command_here --sample $sample_id_paths > sample.bai
    """
}

workflow {
    FOO(reads_ch)
    FOO.out[0].view()
}
```

Alternatively, the process `output` definition allows the use of the `emit` statement to define a named identifier that can be used to reference the channel in the external scope.

```groovy linenums="1" title="snippet.nf"
reads_ch = Channel.fromFilePairs('data/ggal/*_{1,2}.fq')

process FOO {
    input:
    tuple val(sample_id), path(sample_id_paths)

    output:
    tuple val(sample_id), path('sample.bam'), emit: bam
    tuple val(sample_id), path('sample.bai'), emit: bai

    script:
    """
    echo your_command_here --sample $sample_id_paths > sample.bam
    echo your_command_here --sample $sample_id_paths > sample.bai
    """
}

workflow {
    FOO(reads_ch)
    FOO.out.bam.view()
}
```

!!! question "Exercise"

    Modify the previous example so that the `bai` output channel is printed to your terminal.

    ??? solution

        Your workflow will look something like this:

        ```groovy linenums="1" title="snippet.nf"
        reads_ch = Channel.fromFilePairs('data/ggal/*_{1,2}.fq')

        process FOO {
            input:
            tuple val(sample_id), path(sample_id_paths)

            output:
            tuple val(sample_id), path('sample.bam'), emit: bam
            tuple val(sample_id), path('sample.bai'), emit: bai

            script:
            """
            echo your_command_here --sample $sample_id_paths > sample.bam
            echo your_command_here --sample $sample_id_paths > sample.bai
            """
        }

        workflow {
            FOO(reads_ch)
            FOO.out.bai.view()
        }
        ```

!!! cboard-list-2 "Summary"

    In this step you have learned:

    1. How to use the `val` qualifier to define the output channel(s) of a process
    2. How to use the `path` qualifier to define the output file(s) of a process
    3. How to use the `tuple` qualifier to define the output channel(s) of a process
    4. How to manage multiple output files using glob patterns
    5. How to use dynamic output file names
    6. How to use composite inputs and outputs
    7. How to define outputs

## When

The `when` declaration allows you to define a condition that must be verified in order to execute the process. This can be any expression that evaluates a boolean value.

It is useful to enable/disable the process execution depending on the state of various inputs and parameters. For example:

```groovy linenums="1" title="snippet.nf"
params.dbtype = 'nr'
params.prot = 'data/prots/*.tfa'
proteins = Channel.fromPath(params.prot)

process FIND {
    debug true

    input:
    path fasta
    val type

    when:
    fasta.name =~ /^BB11.*/ && type == 'nr'

    script:
    """
    echo blastp -query $fasta -db nr
    """
}

workflow {
    result = FIND(proteins, params.dbtype)
}
```

!!! cboard-list-2 "Summary"

    In this step you have learned:

    1. How to use the `when` declaration to allow conditional processes

## Directives

Directive declarations allow the definition of optional settings that affect the execution of the current process without affecting the _semantic_ of the task itself.

They must be entered at the top of the process body, before any other declaration blocks (i.e., _input_, _output_, etc.).

Directives are commonly used to define the amount of computing resources to be used or other meta directives that allow the definition of extra configuration of logging information. For example:

```groovy linenums="1" title="snippet.nf"
process FOO {
    cpus 2
    memory 1.GB
    container 'image/name'

    script:
    """
    echo your_command --this --that
    """
}
```

The complete list of directives is available [at this link](https://www.nextflow.io/docs/latest/process.html#directives). Some of the most common are described in detail below.

### Resource allocation

Directives that allow you to define the amount of computing resources to be used by the process. These are:

| Name                                                                | Description                                                                                                                   |
| ------------------------------------------------------------------- | ----------------------------------------------------------------------------------------------------------------------------- |
| [`cpus`](https://www.nextflow.io/docs/latest/process.html#cpus)     | Allows you to define the number of (logical) CPUs required by the process’ task.                                              |
| [`time`](https://www.nextflow.io/docs/latest/process.html#time)     | Allows you to define how long the task is allowed to run (e.g., time _1h_: 1 hour, _1s_ 1 second, _1m_ 1 minute, _1d_ 1 day). |
| [`memory`](https://www.nextflow.io/docs/latest/process.html#memory) | Allows you to define how much memory the task is allowed to use (e.g., _2 GB_ is 2 GB). Can also use B, KB,MB,GB and TB.      |
| [`disk`](https://www.nextflow.io/docs/latest/process.html#disk)     | Allows you to define how much local disk storage the task is allowed to use.                                                  |

These directives can be used in combination with each other to allocate specific resources to each process. For example:

```groovy linenums="1" title="snippet.nf"
process FOO {
    cpus 2
    memory 1.GB
    time '1h'
    disk '10 GB'

    script:
    """
    echo your_command --this --that
    """
}
```

### PublishDir directive

Given each task is being executed in separate temporary `work/` folder (e.g., `work/f1/850698…`), you may want to save important, non-intermediary, and/or final files in a results folder.

To store our workflow result files, you need to explicitly mark them using the directive [publishDir](https://www.nextflow.io/docs/latest/process.html#publishdir) in the process that’s creating the files. For example:

```groovy linenums="1" title="snippet.nf"
reads_ch = Channel.fromFilePairs('data/ggal/*_{1,2}.fq')

process FOO {
    publishDir "results", pattern: "*.bam"

    input:
    tuple val(sample_id), path(sample_id_paths)

    output:
    tuple val(sample_id), path("*.bam")
    tuple val(sample_id), path("*.bai")

    script:
    """
    echo your_command_here --sample $sample_id_paths > ${sample_id}.bam
    echo your_command_here --sample $sample_id_paths > ${sample_id}.bai
    """
}

workflow {
    FOO(reads_ch)
}
```

The above example will copy all blast script files created by the `BLASTSEQ` process into the directory path `results`.

!!! tip

    The publish directory can be local or remote. For example, output files could be stored using an [AWS S3 bucket](https://aws.amazon.com/s3/) by using the `s3://` prefix in the target path.

You can use more than one `publishDir` to keep different outputs in separate directories. For example:

```groovy linenums="1" title="snippet.nf"
reads_ch = Channel.fromFilePairs('data/ggal/*_{1,2}.fq')

process FOO {
    publishDir "results/bam", pattern: "*.bam"
    publishDir "results/bai", pattern: "*.bai"

    input:
    tuple val(sample_id), path(sample_id_paths)

    output:
    tuple val(sample_id), path("*.bam")
    tuple val(sample_id), path("*.bai")

    script:
    """
    echo your_command_here --sample $sample_id_paths > ${sample_id}.bam
    echo your_command_here --sample $sample_id_paths > ${sample_id}.bai
    """
}

workflow {
    FOO(reads_ch)
}
```

!!! question "Exercise"

    Edit the `publishDir` directive in the previous example to store the output files for each sample type in a different directory.

    ??? Solution

        Your solution could look something like this:

        ```groovy linenums="1" title="snippet.nf"
        reads_ch = Channel.fromFilePairs('data/ggal/*_{1,2}.fq')

        process FOO {
            publishDir "results/$sample_id", pattern: "*.{bam,bai}"

            input:
        ...
        ```

!!! cboard-list-2 "Summary"

    In this step you have learned:

    1. How to use the cpus, time, memory, and disk directives to define the amount of computing resources to be used by the process
    2. How to use the publishDir directive to store the output files in a results folder
