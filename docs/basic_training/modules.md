---
title: Modularization
description: Fundamentals Nextflow Training Workshop
---

# Modularization

The definition of module libraries simplifies the writing of complex data analysis workflows and makes re-use of processes much easier.

Using the `hello.nf` example from earlier, you can convert the workflow’s processes into modules, then call them within the workflow scope.

## Modules

Nextflow DSL2 allows for the definition of stand-alone module scripts that can be included and shared across multiple workflows. Each module can contain its own `process` or `workflow` definition.

### Importing modules

Components defined in the module script can be imported into other Nextflow scripts using the `include` statement. This allows you to store these components in one or more file(s) that they can be re-used in multiple workflows.

Using the `hello.nf` example, you can achieve this by:

-   Creating a file called `modules.nf` in the top-level directory.
-   Copying and pasting the two process definitions for `SPLITLETTERS` and `CONVERTTOUPPER` into `modules.nf`.
-   Removing the `process` definitions in the `hello.nf` script.
-   Importing the processes from `modules.nf` within the `hello.nf` script anywhere above the `workflow` definition:

```groovy linenums="1" title="hello.nf"
include { SPLITLETTERS   } from './modules.nf'
include { CONVERTTOUPPER } from './modules.nf'
```

!!! note

    In general, you would use relative paths to define the location of the module scripts using the `./` prefix.

!!! exercise

    Create a `modules.nf` file with the `SPLITLETTERS` and `CONVERTTOUPPER` processes from `hello.nf`. Then remove these processes from `hello.nf` and include them in the workflow using the `include` definitions shown above.

    ??? solution

        The `hello.nf` script should look similar like this:

        ```groovy linenums="1" title="hello.nf"
        #!/usr/bin/env nextflow

        params.greeting  = 'Hello world!'
        greeting_ch = Channel.of(params.greeting)

        include { SPLITLETTERS   } from './modules.nf'
        include { CONVERTTOUPPER } from './modules.nf'

        workflow {
            letters_ch = SPLITLETTERS(greeting_ch)
            results_ch = CONVERTTOUPPER(letters_ch.flatten())
            results_ch.view { it }
        }
        ```

        Your `./modules.nf` file should look similar to this:

        ```groovy linenums="1" title="modules.nf"
        process SPLITLETTERS {
            input:
            val x

            output:
            path 'chunk_*'

            script:
            """
            printf '$x' | split -b 6 - chunk_
            """
        }

        process CONVERTTOUPPER {
            input:
            path y

            output:
            stdout

            script:
            """
            cat $y | tr '[a-z]' '[A-Z]'
            """
        }
        ```

### Multiple imports

If a Nextflow module script contains multiple `process` definitions they can also be imported using a single `include` statement as shown in the example below:

```groovy linenums="1" title="hello.nf"
#!/usr/bin/env nextflow

params.greeting  = 'Hello world!'
greeting_ch = Channel.of(params.greeting)

include { SPLITLETTERS; CONVERTTOUPPER } from './modules.nf'

workflow {
    letters_ch = SPLITLETTERS(greeting_ch)
    results_ch = CONVERTTOUPPER(letters_ch.flatten())
    results_ch.view { it }
}
```

### Module aliases

When including a module component it is possible to specify a name alias using the `as` declaration. This allows the inclusion and the invocation of the same component multiple times using different names:

```groovy linenums="1" title="hello.nf"
#!/usr/bin/env nextflow

params.greeting = 'Hello world!'
greeting_ch = Channel.of(params.greeting)

include { SPLITLETTERS as SPLITLETTERS_one } from './modules.nf'
include { SPLITLETTERS as SPLITLETTERS_two } from './modules.nf'

include { CONVERTTOUPPER as CONVERTTOUPPER_one } from './modules.nf'
include { CONVERTTOUPPER as CONVERTTOUPPER_two } from './modules.nf'

workflow {
    letters_ch1 = SPLITLETTERS_one(greeting_ch)
    results_ch1 = CONVERTTOUPPER_one(letters_ch1.flatten())
    results_ch1.view { it }

    letters_ch2 = SPLITLETTERS_two(greeting_ch)
    results_ch2 = CONVERTTOUPPER_two(letters_ch2.flatten())
    results_ch2.view { it }
}
```

Note how the `SPLITLETTERS` and `CONVERTTOUPPER` processes are imported twice, each time with a different alias, and how these aliases are used to invoke the processes:

```console title="Output"
N E X T F L O W  ~  version 23.10.1
Launching `hello.nf` [crazy_shirley] DSL2 - revision: 99f6b6e40e
executor >  local (6)
[2b/ec0395] process > SPLITLETTERS_one (1)   [100%] 1 of 1 ✔
[d7/be3b77] process > CONVERTTOUPPER_one (1) [100%] 2 of 2 ✔
[04/9ffc05] process > SPLITLETTERS_two (1)   [100%] 1 of 1 ✔
[d9/91b029] process > CONVERTTOUPPER_two (2) [100%] 2 of 2 ✔
WORLD!
HELLO
HELLO
WORLD!
```

!!! tip

    You can store each process in separate files within separate sub-folders or combined in one big file (both are valid).
    You can find examples of this on public repos such as the [Seqera RNA-Seq tutorial](https://github.com/seqeralabs/rnaseq-nf/tree/master/modules) or within nf-core workflows, such as [nf-core/rnaseq](https://github.com/nf-core/rnaseq/tree/master/modules/nf-core).

### Output definition

Nextflow allows the use of alternative output definitions within workflows to simplify your code.

In the previous example (`hello.nf`), you defined the channel names to specify the input to the next process:

```groovy linenums="1" title="hello.nf"
workflow  {
    greeting_ch = Channel.of(params.greeting)
    letters_ch = SPLITLETTERS(greeting_ch)
    results_ch = CONVERTTOUPPER(letters_ch.flatten())
    results_ch.view { it }
}
```

You can also explicitly define the output of one channel to another using the `.out` attribute, removing the channel definitions completely:

```groovy linenums="1" title="hello.nf"
workflow  {
    greeting_ch = Channel.of(params.greeting)
    SPLITLETTERS(greeting_ch)
    CONVERTTOUPPER(SPLITLETTERS.out.flatten())
    CONVERTTOUPPER.out.view()
}
```

If a process defines two or more output channels, each channel can be accessed by indexing the `.out` attribute, e.g., `.out[0]`, `.out[1]`, etc. In the example below, the `[0]'th` output is shown:

```groovy linenums="1" title="hello.nf"
workflow  {
    greeting_ch = Channel.of(params.greeting)
    SPLITLETTERS(greeting_ch)
    CONVERTTOUPPER(SPLITLETTERS.out.flatten())
    CONVERTTOUPPER.out[0].view()
}
```

Alternatively, the process `output` definition allows the use of the `emit` statement to define a named identifier that can be used to reference the channel in the external scope.

In the example below, an `emit` statement has been added to the `CONVERTTOUPPER` process and is then used in the workflow definition:

```groovy linenums="1" title="modules.nf"
process SPLITLETTERS {
    input:
    val x

    output:
    path 'chunk_*'

    script:
    """
    printf '$x' | split -b 6 - chunk_
    """
}

process CONVERTTOUPPER {
    input:
    path y

    output:
    stdout emit: upper

    script:
    """
    cat $y | tr '[a-z]' '[A-Z]'
    """
}

workflow {
    greeting_ch = Channel.of(params.greeting)
    SPLITLETTERS(greeting_ch)
    CONVERTTOUPPER(SPLITLETTERS.out.flatten())
    CONVERTTOUPPER.out.upper.view { it }
}
```

### Using piped outputs

Another way to deal with outputs in the workflow scope is to use pipes `|`.

!!! exercise

    Try changing the workflow script to the snippet below:

    ```groovy linenums="1"
    workflow {
        Channel.of(params.greeting) | SPLITLETTERS | flatten | CONVERTTOUPPER | view
    }
    ```

    Here, a [pipe](https://www.nextflow.io/docs/latest/dsl2.html#pipes) passes the output as a channel to the next process without the need of applying `.out` to the process name.

!!! cboard-list-2 "Summary"

    In this step you have learned:

    1. How to import modules
    2. How to import multiple modules
    3. How to use module aliases
    4. How to use alternative output definitions
    5. How to use piped outputs

## Workflow definition

The `workflow` scope allows the definition of components that define the invocation of one or more processes or operators:

```groovy linenums="1" title="hello.nf"
#!/usr/bin/env nextflow

params.greeting = 'Hello world!'

include { SPLITLETTERS } from './modules.nf'
include { CONVERTTOUPPER } from './modules.nf'


workflow my_workflow {
    greeting_ch = Channel.of(params.greeting)
    SPLITLETTERS(greeting_ch)
    CONVERTTOUPPER(SPLITLETTERS.out.flatten())
    CONVERTTOUPPER.out.upper.view { it }
}

workflow {
    my_workflow()
}
```

For example, the snippet above defines a `workflow` named `my_workflow`, that is invoked via another `workflow` definition.

!!! note

    Make sure that your `modules.nf` file is the one containing the `emit` on the `CONVERTTOUPPER` process.

!!! warning

    A workflow component can access any variable or parameter defined in the outer scope. In the running example, you can also access `params.greeting` directly within the `workflow` definition.

### Workflow inputs

A `workflow` component can declare one or more input channels using the `take` statement. For example:

```groovy linenums="1" title="hello.nf"
#!/usr/bin/env nextflow

params.greeting = 'Hello world!'

include { SPLITLETTERS } from './modules.nf'
include { CONVERTTOUPPER } from './modules.nf'

workflow my_workflow {
    take:
    greeting

    main:
    SPLITLETTERS(greeting)
    CONVERTTOUPPER(SPLITLETTERS.out.flatten())
    CONVERTTOUPPER.out.upper.view { it }
}
```

!!! note

    When the `take` statement is used, the `workflow` definition needs to be declared within the `main` block.

The input for the `workflow` can then be specified as an argument:

```groovy linenums="1" title="hello.nf"
workflow {
    my_workflow(Channel.of(params.greeting))
}
```

### Workflow outputs

A `workflow` can declare one or more output channels using the `emit` statement. For example:

```groovy linenums="1" title="hello.nf"
#!/usr/bin/env nextflow

params.greeting = 'Hello world!'
greeting_ch = Channel.of(params.greeting)

process SPLITLETTERS {
    input:
    val x

    output:
    path 'chunk_*'

    """
    printf '$x' | split -b 6 - chunk_
    """
}

process CONVERTTOUPPER {
    input:
    path y

    output:
    stdout emit: upper

    """
    cat $y | tr '[a-z]' '[A-Z]'
    """
}

workflow my_workflow {
    take:
    greeting

    main:
    SPLITLETTERS(greeting)
    CONVERTTOUPPER(SPLITLETTERS.out.flatten())

    emit:
    CONVERTTOUPPER.out.upper
}

workflow {
    my_workflow(Channel.of(params.greeting))
    my_workflow.out.view()
}
```

As a result, you can use the `my_workflow.out` notation to access the outputs of `my_workflow` in the invoking `workflow`.

You can also declare named outputs within the `emit` block.

```groovy linenums="1" title="hello.nf"
#!/usr/bin/env nextflow

params.greeting = 'Hello world!'
greeting_ch = Channel.of(params.greeting)

process SPLITLETTERS {
    input:
    val x

    output:
    path 'chunk_*'

    """
    printf '$x' | split -b 6 - chunk_
    """
}

process CONVERTTOUPPER {
    input:
    path y

    output:
    stdout emit: upper

    """
    cat $y | tr '[a-z]' '[A-Z]'
    """
}

workflow my_workflow {
    take:
    greeting

    main:
    SPLITLETTERS(greeting)
    CONVERTTOUPPER(SPLITLETTERS.out.flatten())

    emit:
    my_data = CONVERTTOUPPER.out.upper
}

workflow {
    my_workflow(Channel.of(params.greeting))
    my_workflow.out.my_data.view()
}
```

The result of the above snippet can then be accessed using `my_workflow.out.my_data`.

### Calling named workflows

Within a `main.nf` script (called `hello.nf` in our example) you can also have multiple workflows. In which case you may want to call a specific workflow when running the code. For this you could use the entrypoint call `-entry <workflow_name>`.

The following snippet has two named workflows (`my_workflow_one` and `my_workflow_two`):

```groovy linenums="1" title="hello2.nf"
#!/usr/bin/env nextflow

params.greeting = 'Hello world!'

include { SPLITLETTERS as SPLITLETTERS_one } from './modules.nf'
include { SPLITLETTERS as SPLITLETTERS_two } from './modules.nf'

include { CONVERTTOUPPER as CONVERTTOUPPER_one } from './modules.nf'
include { CONVERTTOUPPER as CONVERTTOUPPER_two } from './modules.nf'


workflow my_workflow_one {
    letters_ch1 = SPLITLETTERS_one(params.greeting)
    results_ch1 = CONVERTTOUPPER_one(letters_ch1.flatten())
    results_ch1.view { it }
}

workflow my_workflow_two {
    letters_ch2 = SPLITLETTERS_two(params.greeting)
    results_ch2 = CONVERTTOUPPER_two(letters_ch2.flatten())
    results_ch2.view { it }
}

workflow {
    my_workflow_one(Channel.of(params.greeting))
    my_workflow_two(Channel.of(params.greeting))
}
```

You can choose which workflow to run by using the `entry` flag:

```bash
nextflow run hello2.nf -entry my_workflow_one
```

!!! cboard-list-2 "Summary"

    In this step you have learned:

    1. How to define workflow inputs
    2. How to define workflow outputs
    3. How to use named workflows

## DSL2 migration notes

To view a summary of the changes introduced when Nextflow migrated from DSL1 to DSL2 please refer to the [DSL2 migration notes](https://www.nextflow.io/docs/latest/dsl2.html#dsl2-migration-notes) in the official Nextflow documentation.
