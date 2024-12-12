# Part 1: Hello World

A "Hello World!" is a minimalist example that is meant to demonstrate the basic syntax and structure of a programming language or software framework. The example typically consists of printing the phrase "Hello, World!" to the output device, such as the console or terminal, or writing it to a file.

In this first part of the Hello Nextflow training course, we ease into the topic with a very simple domain-agnostic Hello World example, which we'll progressively build up to demonstrate the usage of foundational Nextflow logic and components.

---

## 0. Warmup: Run Hello World directly

Let's demonstrate this with a simple command that we run directly in the terminal, to show what it does before we wrap it in Nextflow.

### 0.1. Make the terminal say hello

```bash
echo 'Hello World!'
```

### 0.2. Now make it write the text output to a file

```bash
echo 'Hello World!' > output.txt
```

### 0.3. Verify that the output file is there using the `ls` command

```bash
ls
```

### 0.4. Show the file contents

```bash
cat output.txt
```

!!! tip

    In the Gitpod environment, you can also find the output file in the file explorer, and view its contents by clicking on it. Alternatively, you can use the `code` command to open the file for viewing.

    ```bash
    code output.txt
    ```

### Takeaway

You now know how to run a simple command in the terminal that outputs some text, and optionally, how to make it write the output to a file.

### What's next?

Discover what that would look like written as a Nextflow workflow.

---

## 1. Try the Hello World workflow starter script

As mentioned in the orientation, we provide you with a fully functional if minimalist workflow script named `hello-world.nf` that does the same thing as before (write out 'Hello World!') but with Nextflow.

To get you started, we'll first open up the workflow script so you can get a sense of how it's structured, then we'll run it (before trying to make any modifications) to verify that it does what we expect.

### 1.1. Decipher the code structure

Let's open the `hello-world.nf` script in the editor pane.

!!! note

    The file is in the `hello-nextflow` directory, which should be your current working directory.
    You can either click on the file in the file explorer, or type `ls` in the terminal and Cmd+Click (MacOS) or Ctrl+Click (PC) on the file to open it.

```groovy title="hello-world.nf" linenums="1"
#!/usr/bin/env nextflow

/*
 * Use echo to print 'Hello World!' to standard out
 */
process sayHello {

    output:
        stdout

    script:
    """
    echo 'Hello World!'
    """
}

workflow {

    // emit a greeting
    sayHello()
}
```

As you can see, a Nextflow script involves two main types of core components: one or more **processes**, and the **workflow** itself.
Each **process** describes what operation(s) the corresponding step in the pipeline should accomplish, while the **workflow** describes the dataflow logic that connects the various steps.

Let's take a closer look at the **process** block first, then we'll look at the **workflow** block.

#### 1.1.1 The `process` definition

The first block of code describes a **process**.
The process definition starts with the keyword `process`, followed by the process name and finally the process body delimited by curly braces.
The process body must contain a script block which specifies the command to run, which can be anything you would be able to run in a command line terminal.

Here we have a **process** called `sayHello` that writes its **output** to `stdout`.

```groovy title="hello-world.nf" linenums="3"
/*
 * Use echo to print 'Hello World!' to standard out
 */
process sayHello {

    output:
        stdout

    script:
    """
    echo 'Hello World!'
    """
}
```

This a very minimal process definition that just contains an output definition and the script itself.
In a real-world pipeline, a process usually contains additional blocks such as directives, inputs, and conditional clauses, which we'll introduce later in this training course.

!!! note

    The output definition does not _determine_ what output will be created.
    It simply _declares_ what is the expected output, so that Nextflow can look for it once execution is complete.
    This is necessary for verifying that the command was executed successfully and for passing the output to downstream processes if needed.

#### 1.1.2 The `workflow` definition

The second block of code describes the **workflow** itself.
The workflow definition starts with the keyword `workflow`, followed by an optional name, then the workflow body delimited by curly braces.

Here we have a **workflow** that consists of one call to the `sayHello` process.

```groovy title="hello-world.nf" linenums="16"
workflow {

    // emit a greeting
    sayHello()
}
```

This a very minimal **workflow** definition.
In a real-world pipeline, the workflow typically contains multiple calls to **processes** connected by **channels**.
You'll learn how to add more processes and connect them by channels in a little bit.

### 1.2. Run the workflow

Looking at code is not nearly as fun as running it, so let's try this out in practice.

```bash
nextflow run hello-world.nf
```

You console output should look something like this:

```console title="Output"
 N E X T F L O W   ~  version 24.10.0

 ┃ Launching `hello-world.nf` [reverent_carson] DSL2 - revision: 463b611a35

executor >  local (1)
[1c/7d08e6] sayHello [100%] 1 of 1 ✔
```

Congratulations, you just ran your first Nextflow workflow!

The most important output here is the last line (line 6), which reports that the `sayHello` process was successfully executed once.

Okay, that's great, but where do we find the output?
The `sayHello` process definition said that the output would be sent to standard out, but nothing got printed in the console, did it?

### 1.3. Find the output and logs in the `work` directory

When you run Nextflow for the first time in a given directory, it creates a directory called `work` where it will write all files (and symlinks) generated in the course of execution.
Have a look inside; you'll find a subdirectory named with a hash (in order to make it unique; we'll discuss why in a bit), nested two levels deep and containing a handful of log files.

!!! tip

    If you browse the contents of the task subdirectory in the Gitpod's VSCode file explorer, you'll see all these files right away.
    However, these files are set to be invisible in the terminal, so if you want to use `ls` or `tree` to view them, you'll need to set the relevant option for displaying invisible files.

    ```bash
    tree -a work
    ```

    You should see something like this, though the exact subdirectory names will be different on your system.

    ```console title="Directory contents"
    work
    └── 1c
        └── 7d08e685a7aa7060b9c21667924824
            ├── .command.begin
            ├── .command.err
            ├── .command.log
            ├── .command.out
            ├── .command.run
            ├── .command.sh
            └── .exitcode
    ```

You may have noticed that the subdirectory names appeared (in truncated form) in the output from the workflow run, in the line that says:

```console title="Output"
[1c/7d08e6] sayHello [100%] 1 of 1 ✔
```

This tells you what is the subdirectory path for that specific process call (sometimes called task).

!!! note

    Nextflow creates a separate unique subdirectory for each process call.
    It stages the relevant input files, script, and other helper files there, and writes any output files and logs there as well.

If we look inside the subdirectory, we find the following log files:

- **`.command.begin`**: Metadata related to the beginning of the execution of the process task
- **`.command.err`**: Error messages (stderr) emitted by the process task
- **`.command.log`**: Complete log output emitted by the process task
- **`.command.out`**: Regular output (stdout) by the process task
- **`.command.sh`**: The command that was run by the process task call
- **`.exitcode`**: The exit code resulting from the command

In this case, you can look for your output in the `.command.out` file, since that's where stdout output is captured.
If you open it, you'll find the `Hello World!` greeting, which was the expected result of our minimalist workflow.

It's also worth having a look at the `.command.sh` file, which tells you what command Nextflow actually executed. In this case it's very straightforward, but later in the course you'll see commands that involve some interpolation of variables. When you're dealing with that, you need to be able to check exactly what was run, especially when troubleshooting an issue.

### Takeaway

You know how to decipher a simple Nextflow script, run it and find the output and logs in the work directory.

### What's next?

Learn how to make the script output a named file.

---

## 3. Send the output to a file

Instead of printing "Hello World!" to standard output, we'd prefer to save that output to a specific file, just like we did when running in the terminal earlier.
This is how most tools that you'll run as part of real-world pipelines typically behave; we'll see examples of that later.

To achieve this result, both the script and the output definition blocks need to be updated.

### 3.1. Change the process command to output a named file

This is the same change we made when we ran the command directly in the terminal earlier.

_Before:_

```groovy title="hello-world.nf" linenums="11"
    """
    echo 'Hello World!'
    """
```

_After:_

```groovy title="hello-world.nf" linenums="11"
    """
    echo 'Hello World!' > output.txt
    """
```

### 3.2. Change the output declaration in the `sayHello` process

We need to tell Nextflow that it should now look for a specific file to be produced by the process execution.

_Before:_

```groovy title="hello-world.nf" linenums="8"
output:
    stdout
```

_After:_

```groovy title="hello-world.nf" linenums="8"
output:
    path 'output.txt'
```

!!! note

    Inputs and outputs in the process blocks typically require a qualifier and a variable name:

    ```
    <input/output qualifier> <input/output name>
    ```

    The qualifier defines the type of data to be received.
    This information is used by Nextflow to apply the semantic rules associated with each qualifier, and handle it properly.
    Common qualifiers include `val` and `path`.
    In the example above, `stdout` is an exception since it is not associated with a name.

### 3.3. Run the workflow again

```bash
nextflow run hello-world.nf
```

The log output should be very similar to the first time your ran the workflow:

```console title="Output"
 N E X T F L O W   ~  version 24.10.0

 ┃ Launching `hello-world.nf` [cranky_sinoussi] DSL2 - revision: 30b437bb96

executor >  local (1)
[7a/6bd54c] sayHello [100%] 1 of 1 ✔
```

Like you did before, find the `work` directory in the file explorer.
There, find the `output.txt` output file and click on it to open it, and verify that it contains the greeting as expected.

!!! warning

    This example is brittle because we hardcoded the output filename in two separate places (the script and the output blocks).
    If we change one but not the other, the script will break.
    Later, you'll learn how to use variables to avoid this problem.

### 3.4. Add a `publishDir` directive to the process

You'll have noticed that the output is buried in a working directory several layers deep.
Nextflow is in control of this directory and we are not supposed to interact with it.
To make the output file more accessible, we can utilize the `publishDir` directive.
By specifying this directive, we are telling Nextflow to automatically copy the output file to a designated output directory.
This allows us to leave the working directory alone, while still having easy access to the desired output file.

_Before:_

```groovy title="hello-world.nf" linenums="6"
process sayHello {

    output:
        path 'output.txt'
```

_After:_

```groovy title="hello-world.nf" linenums="6"
process sayHello {

    publishDir 'results', mode: 'copy'

    output:
        path 'output.txt'
```

!!! note

    There is a newer syntax option that makes it possible to declare and publish workflow-level outputs, documented [here](https://www.nextflow.io/docs/latest/workflow.html#publishing-outputs), which makes using `publishDir` at the process level redundant once your pipeline is fully operational.
    However, `publishDir` is still very useful during pipeline development; that is why we include it in this training series.
    This will also ensure that you can read and understand the large number of pipelines that have already been written with `publishDir`.

    You'll learn how to use the workflow-level outputs syntax later in this training series.

### 3.5. Run the workflow again

```bash
nextflow run hello-world.nf
```

The log output should start looking very familiar:

```console title="Output"
 N E X T F L O W   ~  version 24.10.0

 ┃ Launching `hello-world.nf` [mighty_lovelace] DSL2 - revision: 6654bc1327

executor >  local (1)
[10/15498d] sayHello [100%] 1 of 1 ✔
```

This time, Nextflow will have created a new directory called `results/`.
In this directory is our `output.txt` file.
If you check the contents it should match the output in our work/task directory.
This is how we move results files outside of the working directories.

### Takeaway

You know how to send outputs to a specific named file and use the `publishDir` directive to move files outside of the Nextflow working directory.

### What's next?

Learn how to make Nextflow resume running a pipeline using cached results from a prior run to skip any steps it had already completed successfully.

---

## 4. Use the Nextflow resume feature

Nextflow has an option called `-resume` that allows you to re-run a pipeline you've already launched previously.
When launched with `-resume` any processes that have already been run with the exact same code, settings and inputs will be skipped.
Using this mode means Nextflow will only run processes that are either new, have been modified or are being provided new settings or inputs.

There are two key advantages to doing this:

- If you're in the middle of developing your pipeline, you can iterate more rapidly since you only effectively have to run the process(es) you're actively working on in order to test your changes.
- If you're running a pipeline in production and something goes wrong, in many cases you can fix the issue and relaunch the pipeline, and it will resume running from the point of failure, which can save you a lot of time and compute.

### 4.1. Run the workflow again with `-resume`

```bash
nextflow run hello-world.nf -resume
```

The console output should look similar.

```console title="Output"
 N E X T F L O W   ~  version 24.10.0

 ┃ Launching `hello-world.nf` [thirsty_gautier] DSL2 - revision: 6654bc1327

[10/15498d] sayHello [100%] 1 of 1, cached: 1 ✔
```

Notice the additional `cached:` bit in the process status line, which means that Nextflow has recognized that it has already done this work and simply re-used the result from the last run.

!!! note

    When your re-run a pipeline with `resume`, Nextflow does not overwrite any files written to a publishDir directory by any process call that was previously run successfully.

### Takeaway

You know how to to relaunch a pipeline without repeating steps that were already run in an identical way.

### What's next?

Learn how to add in variable inputs.

---

## 5. Add in variable inputs using a channel

So far, we've been emitting a greeting hardcoded into the process command.
Now we're going to add some flexibility by using an input variable, so that we can easily change the greeting.

This requires us to make a series of inter-related changes:

1. Tell the process about expected variable inputs using the `input:` block
2. Edit the process to use the input
3. Create a **channel** to pass input to the process (more on that in a minute)
4. Add the channel as input to the process call

### 5.1. Add an input definition to the process block

First we need to adapt the process definition to accept an input.

_Before:_

```groovy title="hello-world.nf" linenums="6"
process sayHello {

    publishDir 'results', mode: 'copy'

    output:
        path "output.txt"
```

_After:_

```groovy title="hello-world.nf" linenums="6"
process sayHello {

    publishDir 'results', mode: 'copy'

    input:
        val greeting

    output:
        path "output.txt"
```

### 5.2. Edit the process command to use the input variable

Now we swap the original hardcoded value for the input variable.

_Before:_

```groovy title="hello-world.nf" linenums="16"
    """
    echo 'Hello World!' > output.txt
    """
```

_After:_

```groovy title="hello-world.nf" linenums="16"
    """
    echo '$greeting' > output.txt
    """
```

### 5.3. Create an input channel

Now that our process expects an input, we need to set up that input in the workflow body.
This is where channels come in: Nextflow uses channels to feed inputs to processes and ferry data between processes that are connected together.

There are multiple ways to do this, but for now, we're just going to use the simplest possible channel, containing a single value.

We're going to create the channel using the `of()` channel factory, which sets up a simple value channel, and give it a hardcoded string to use as greeting by declaring `greeting_ch = Channel.of('Hello world!')`.

_Before:_

```groovy title="hello-world.nf" linenums="21"
workflow {

    // emit a greeting
    sayHello()
}
```

_After:_

```groovy title="hello-world.nf" linenums="21"
workflow {

    // create a channel for inputs
    greeting_ch = Channel.of('Hello world!')

    // emit a greeting
    sayHello()
}
```

### 5.4. Add the channel as input to the process call

Now we need to actually plug our newly created channel into the `sayHello()` process call.

_Before:_

```groovy title="hello-world.nf" linenums="26"
// emit a greeting
sayHello()
```

_After:_

```groovy title="hello-world.nf" linenums="26"
// emit a greeting
sayHello(greeting_ch)
```

### 5.5. Run the workflow command again

Let's run it!

```bash
nextflow run hello-world.nf
```

If you made all four edits correctly, you should get another successful execution:

```console title="Output"
 N E X T F L O W   ~  version 24.10.0

 ┃ Launching `hello-world.nf` [prickly_avogadro] DSL2 - revision: b58b6ab94b

executor >  local (1)
[1f/50efd5] sayHello (1) [100%] 1 of 1 ✔
```

Feel free to check the results directory to satisfy yourself that the outcome is still the same as previously; so far we're just progressively tweaking the internal plumbing to increase the flexibility of our workflow while achieving the same end result.

### Takeaway

You know how to use a simple channel to provide an input to a process.

### What's next?

Learn how to pass inputs from the command line.

---

## 6. Use CLI parameters for inputs

We want to be able to specify the input from the command line, since that is the piece that will almost always be different in subsequent runs of the workflow.
Good news: Nextflow has a built-in workflow parameter system called `params`, which makes it easy to declare and use CLI parameters.

### 6.1. Edit the input channel declaration to use a parameter

Here we swap out the hardcoded string for `params.greeting` in the channel creation line.

_Before:_

```groovy title="hello-world.nf" linenums="23"
// create a channel for inputs
greeting_ch = Channel.of('Hello world!')
```

_After:_

```groovy title="hello-world.nf" linenums="23"
// create a channel for inputs
greeting_ch = Channel.of(params.greeting)
```

This automatically creates a parameter called `greeting` that you can use to provide a value in the command line.

### 6.2. Run the workflow again with the `--greeting` parameter

To provide a value for this parameter, simply add `--greeting <value>` to your command line.

```bash
nextflow run hello-world.nf --greeting 'Bonjour le monde!'
```

Running this should feel extremely familiar by now.

```console title="Output"
 N E X T F L O W   ~  version 24.10.0

 ┃ Launching `hello-world.nf` [cheesy_engelbart] DSL2 - revision: b58b6ab94b

executor >  local (1)
[1c/9b6dc9] sayHello (1) [100%] 1 of 1 ✔
```

Be sure to open up the output file to check that you now have the new version of the greeting. Voilà!

!!! tip

    It's helpful to distinguish Nextflow-level parameters from pipeline-level parameters.
    For parameters that apply to a pipeline, we use a double hyphen (`--`), whereas we use a single hyphen (`-`) for parameters that modify a specific Nextflow setting, _e.g._ the `-resume` feature we used earlier.

### 6.3. Set a default value for a command line parameter

In many cases, it makes sense to supply a default value for a given parameter so that you don't have to specify it for every run.

Let's initialize the `greeting` parameter with a default value by adding the parameter declaration at the top of the script (with a comment block as a free bonus).

```groovy title="hello-world.nf" linenums="3"
/*
 * Pipeline parameters
 */
params.greeting = "Holà mundo!"
```

### 6.4. Run the workflow again without specifying the parameter

Now that you have a default value set, you can run the workflow again without having to specify a value in the command line.

```bash
nextflow run hello-world.nf
```

The output should look the same.

```console title="Output"
 N E X T F L O W   ~  version 24.10.0

 ┃ Launching `hello-world.nf` [wise_waddington] DSL2 - revision: 988fc779cf

executor >  local (1)
[c0/8b8332] sayHello (1) [100%] 1 of 1 ✔
```

Check the output in the results directory, and... Tadaa! It works! Nextflow used the default value to name the output. But wait, what happens now if we provide the parameter in the command line?

### 6.5. Run the workflow again with the `--greeting` parameter on the command line using a different greeting

```bash
nextflow run hello-world.nf --greeting 'Konnichiwa!'
```

Nextflow's not complaining, that's a good sign:

```console title="Output"
 N E X T F L O W   ~  version 24.10.0

 ┃ Launching `hello-world.nf` [prickly_miescher] DSL2 - revision: 988fc779cf

executor >  local (1)
[56/f88a56] sayHello (1) [100%] 1 of 1 ✔
```

Check the results directory and look at the contents of `output.txt`. Tadaa again!

The value of the parameter we passed on the command line overrode the value we gave the variable in the script. In fact, parameters can be set in several different ways; if the same parameter is set in multiple places, its value is determined based on the order of precedence that is described [here](https://www.nextflow.io/docs/latest/config.html).

!!! tip

    You can put the parameter declaration inside the workflow block if you prefer. Whatever you choose, try to group similar things in the same place so you don't end up with declarations all over the place.

### Takeaway

You know how to set up an input variable for a process and supply a value in the command line.

### What's next?

Learn how to add in a second process and chain them together.

---

## 7. Add a second step to the workflow

Most real-world workflows involve more than one step. Here we introduce a second process that converts the text to uppercase (all-caps), using the classic UNIX one-liner:

```bash
tr '[a-z]' '[A-Z]'
```

We're going to run the command by itself in the terminal first to verify that it works as expected without any of the workflow code getting in the way of clarity, just like we did at the start with `echo 'Hello World'`. Then we'll write a process that does the same thing, and finally we'll connect the two processes so the output of the first serves as input to the second.

### 7.1. Run the command in the terminal by itself

```bash
echo 'Hello World' | tr '[a-z]' '[A-Z]'
```

The output is simply the uppercase version of the text string:

```console title="Output"
HELLO WORLD
```

!!! note

    This is a very naive text replacement one-liner that does not account for accented letters, so for example 'Holà' will become 'HOLà'. This is expected.

### 7.2. Make the command take a file as input and write the output to a file

As previously, we want to output results to a dedicated file, which we name by prepending the original filename with `UPPER-`.

```bash
cat output.txt | tr '[a-z]' '[A-Z]' > UPPER-output.txt
```

Now the `HELLO WORLD` output is in the new output file, `UPPER-output.txt`.

### 7.3. Wrap the command in a new Nextflow process definition

We can model our new process on the first one, since we want to use all the same components.

```groovy title="hello-world.nf" linenums="26"
/*
 * Use a text replace utility to convert the greeting to uppercase
 */
process convertToUpper {

    publishDir 'results', mode: 'copy'

    input:
        path input_file

    output:
        path "UPPER-${input_file}"

    script:
    """
    cat '$input_file' | tr '[a-z]' '[A-Z]' > UPPER-${input_file}
    """
}
```

As a little bonus, here we composed the second output filename based on the first one.

!!! tip

    Very important to remember: you have to use double quotes around the output filename expression (NOT single quotes) or it will fail.

### 7.4. Add a call to the new process in the workflow body

Don't forget we need to tell Nextflow to actually call the process we just created! To do that, we add it to the `workflow` body.

```groovy title="hello-world.nf" linenums="44"
workflow {

    // create a channel for inputs
    greeting_ch = Channel.of(params.greeting)

    // emit a greeting
    sayHello(greeting_ch)

    // convert the greeting to uppercase
    convertToUpper()
}
```

Looking good! But we still need to wire up the `convertToUpper` process call to run on the output of `sayHello`.

### 7.5. Pass the output of the first process to the second process

The output of the `sayHello` process is automatically packaged as a channel called `sayHello.out`, so all we need to do is pass that as the input to the `convertToUpper` process.

```groovy title="hello-world.nf" linenums="52"
// convert the greeting to uppercase
convertToUpper(sayHello.out)
```

For a simple case like this, that's all we need to do to connect two processes!

### 7.6. Run the same workflow command as before

Let's make sure this works:

```bash
nextflow run hello-world.nf --greeting 'Hello World!'
```

Oh, how exciting! There is now an extra line in the log output, which corresponds to the new process we just added:

```console title="Output"
 N E X T F L O W   ~  version 24.10.0

 ┃ Launching `hello-world.nf` [magical_brenner] DSL2 - revision: 0e18f34798

executor >  local (2)
[57/3836c0] sayHello (1)       [100%] 1 of 1 ✔
[ee/bb3cc8] convertToUpper (1) [100%] 1 of 1 ✔
```

You'll notice that this time the workflow produced two new work subdirectories; one per process call.
Check out the work directory of the call to the second process, where you should find two different output files listed. If you look carefully, you'll notice one of them (the output of the first process) has a little arrow icon on the right; that signifies it's a symbolic link.
It points to the location where that file lives in the work directory of the first process.
By default, Nextflow uses symbolic links to stage input files whenever possible, to avoid making duplicate copies.

!!! note

    All we did was connect the output of `sayHello` to the input of `convertToUpper` and the two processes could be run in serial.
    Nextflow did the hard work of handling input and output files and passing them between the two commands for us.
    This is the power of channels in Nextflow, doing the busywork of connecting our pipeline steps together.

    What's more, Nextflow will automatically determine which call needs to be executed first based on how they're connected, so the order in which they're written in the workflow body does not matter.
    However, we do recommend you be kind to your collaborators and to your future self, and try to write them in a logical order!

### Takeaway

You know how to add a second step that takes the output of the first step as input.

### What's next?

Learn how to make the workflow run on a batch of input values.

---

## 8. Modify the workflow to run on a batch of input values

Workflows typically run on batches of inputs that are meant to be processed in bulk, so we want to upgrade the workflow to accept multiple input values.

Conveniently, the `of()` channel factory we've been using is quite happy to accept more than one value, so we don't need to modify that at all; we just have to load more values into the channel.

### 8.1. Load multiple greetings into the input channel

To keep things simple, we go back to hardcoding the greetings in the channel factory instead of using a parameter for the input, but we'll improve on that shortly.

_Before:_

```groovy title="hello-world.nf" linenums="46"
// create a channel for inputs
greeting_ch = Channel.of(params.greeting)
```

_After:_

```groovy title="hello-world.nf" linenums="46"
// create a channel for inputs
greeting_ch = Channel.of('Hello','Bonjour','Holà')
```

The documentation tells us this should work. Can it really be so simple?

### 8.2. Run the command and look at the log output

Let's try it.

```bash
nextflow run hello-world.nf
```

Well, it certainly seems to run just fine.

```console title="Output"
 N E X T F L O W   ~  version 24.10.0

 ┃ Launching `hello-world.nf` [lonely_pare] DSL2 - revision: b9f1d96905

executor >  local (6)
[3d/1fe62c] sayHello (2)       [100%] 3 of 3 ✔
[86/695813] convertToUpper (3) [100%] 3 of 3 ✔
```

However... This seems to indicate that '3 of 3' calls were made for each process, which is encouraging, but this only give us one subdirectory path for each. What's going on?

By default, the ANSI logging system writes the logging from multiple calls to the same process on the same line. Fortunately, we can disable that behavior.

### 8.3. Run the command again with the `-ansi-log false` option

To expand the logging to display one line per process call, just add `-ansi-log false` to the command.

```bash
nextflow run hello-world.nf -ansi-log false
```

This time we see all six work subdirectories listed in the output:

```console title="Output"
N E X T F L O W  ~  version 24.02.0-edge
Launching `hello-world.nf` [big_woese] DSL2 - revision: 53f20aeb70
[62/d81e63] Submitted process > sayHello (1)
[19/507af3] Submitted process > sayHello (2)
[8a/3126e6] Submitted process > sayHello (3)
[12/48a5c6] Submitted process > convertToUpper (1)
[73/e6e746] Submitted process > convertToUpper (2)
[c5/4fedda] Submitted process > convertToUpper (3)
```

That's much better; at least for this number of processes.
For a complex workflow, or a large number of inputs, having the full list output to the terminal might get a bit overwhelming.

That being said, we have another problem. If you look in the `results` directory, there are only two files: `output.txt` and `UPPER-output.txt`!

```console title="Directory contents"
results
├── output.txt
└── UPPER-output.txt
```

What's up with that? Shouldn't we be expecting two files per input greeting, so six files in all?

You may recall that we hardcoded the output file name for the first process.
This was fine as long as there was only a single call made per process, but when we start processing multiple input values and publishing the outputs into the same directory of results, it becomes a problem.
For a given process, every call produces an output with the same file name, so Nextflow just overwrites the previous output file every time a new one is produced.

### 8.4. Ensure the output file names will be unique

Since we're going to be publishing all the outputs to the same results directory, we need to ensure they will have unique names.
Specifically, we need to modify the first process to generate a file name dynamically so that the final file names will be unique.

So how do we make the file names unique? A common way to do that is to use some unique piece of metadata as part of the file name.
Here, for convenience, we'll just use the greeting itself.

_Before:_

```groovy title="hello-world.nf" linenums="11"
process sayHello {

    publishDir 'results', mode: 'copy'

    input:
        val greeting

    output:
        path "output.txt"

    script:
    """
    echo '$greeting' > "output.txt"
    """
}
```

_After:_

```groovy title="hello-world.nf" linenums="11"
process sayHello {

    publishDir 'results', mode: 'copy'

    input:
        val greeting

    output:
        path "${greeting}-output.txt"

    script:
    """
    echo '$greeting' > '$greeting-output.txt'
    """
}
```

This should produce a unique output file name for every call of each process.

### 8.5. Run the workflow and look at the results directory

Let's run it and check that it works.

```bash
nextflow run hello-world.nf
```

Reverting back to the summary view, the output looks like this again:

```console title="Output"
 N E X T F L O W   ~  version 24.10.0

 ┃ Launching `hello-world.nf` [jovial_mccarthy] DSL2 - revision: 53f20aeb70

executor >  local (6)
[03/f007f2] sayHello (1)       [100%] 3 of 3 ✔
[e5/dd2890] convertToUpper (3) [100%] 3 of 3 ✔
```

But more importantly, now we have six new files in addition to the two we already had in the `results` directory:

```console title="Directory contents"
results
├── Bonjour-output.txt
├── Hello-output.txt
├── Holà-output.txt
├── output.txt
├── UPPER-Bonjour-output.txt
├── UPPER-Hello-output.txt
├── UPPER-Holà-output.txt
└── UPPER-output.txt
```

Success! Now we can add as many greetings as we like without worrying about output files being overwritten.

!!! note

    In practice, naming files based on the input data itself is almost always impractical. The better way to generate dynamic filenames is to use a samplesheet contain relevant metadata (such as unique sample IDs) and create a data structure called a 'map', which we pass to processes, and from which we can grab an appropriate identifier to generate the filenames.
    We'll show you how to do that later in this training course.

### Takeaway

You know how to feed a batch of multiple input elements through a channel.

### What's next?

Learn how to make the workflow take a file as its source of input values.

---

## 9. Modify the workflow to take a file as its source of input values

It's often the case that, when we want to run on a batch of multiple input elements, the input values are contained in a file.
As an example, we have provided you with a CSV file called `greetings.csv` in the `data/` directory, containing several greetings separated by commas.

```csv title="greetings.csv"
Hello,Bonjour,Holà
```

So we just need to modify our workflow to read in the values from a file like that.

### 9.1. Set up a CLI parameter with a default value pointing to an input file

First, let's use the `params` system to set up a new parameter called `input_file`, replacing the now useless `greeting` parameter, with a default value pointing to the `greetings.csv` file.

_Before:_

```groovy title="hello-world.nf" linenums="6"
/*
 * Pipeline parameters
 */
params.greeting = "Holà mundo!"
```

_After:_

```groovy title="hello-world.nf" linenums="6"
/*
 * Pipeline parameters
 */
params.input_file = "data/greetings.csv"
```

### 9.2. Update the channel declaration to handle the input file

At this point we introduce a new channel factory, `fromPath()`, which has some built-in functionality for handling file paths.
We're going to use that instead of the `of()` channel factory we used previously; the base syntax looks like this:

```groovy title="channel construction syntax"
Channel.fromPath(params.input_file)
```

Now, we are going to deploy a new concept, an 'operator' to transform that CSV file into channel content. You'll learn more about operators later, but for now just understand them as ways of transforming channels in a variety of ways.

Since our goal is to read in the contents of a `.csv` file, we're going to add the `.splitCsv()` operator to make Nextflow parse the file contents accordingly, as well as the `.flatten()` operator to turn the array element produced by `.splitCsv()` into a channel of individual elements.

So the channel construction instruction becomes:

```groovy title="channel construction syntax"
Channel.fromPath(params.input_file)
       .splitCsv()
       .flatten()
```

And here it is in the context of the workflow body:

_Before:_

```groovy title="hello-world.nf" linenums="46"
// create a channel for inputs
greeting_ch = Channel.of('Hello','Bonjour','Holà')
```

_After:_

```groovy title="hello-world.nf" linenums="46"
// create a channel for inputs from a CSV file
greeting_ch = Channel.fromPath(params.input_file)
                     .splitCsv()
                     .flatten()
```

If you want to see the impact of `.flatten()`, we can make use of `.view()`, another operator, to demonstrate. Edit that section of code so it looks like:

```groovy title="flatten usage"
// create a channel for inputs from a CSV file
greeting_ch = Channel.fromPath(params.input_file)
                     .splitCsv()
                     .view{ "After splitCsv: $it" }
                     .flatten()
                     .view{ "After flatten: $it" }
```

When you run this updated workflow, you'll see the difference:

```console title="view output with and without flatten"
After splitCsv: [Hello, Bonjour, Holà]
After flatten: Hello
After flatten: Bonjour
After flatten: Holà
[d3/1a6e23] Submitted process > sayHello (3)
[8f/d9e431] Submitted process > sayHello (1)
[e7/a088af] Submitted process > sayHello (2)
[1a/776e2e] Submitted process > convertToUpper (1)
[83/fb8eba] Submitted process > convertToUpper (2)
[ee/280f93] Submitted process > convertToUpper (3)
```

As you can see, the `flatten()` operator has transformed the channel from containing arrays to containing individual elements. This can be useful when you want to process each item separately in your workflow.

Remove the `.view()` operations before you continue.

!!! tip

    While you're developing your pipeline, you can inspect the contents of any channel by adding the `.view()` operator to the name of the channel.
    For example, if you add `greeting_ch.view()` anywhere in the workflow body, when you run the script, Nextflow will print the channel contents to standard out.

    You can also use this to inspect the effect of the operators.
    For example, the output of `Channel.fromPath(params.input_file).splitCsv().view()` will look like this:

    ```console title="Output"
    [Hello, Bonjour, Holà]
    ```

    While the output of `Channel.fromPath(params.input_file).splitCsv().flatten().view()` will look like this:

    ```console title="Output"
    Hello
    Bonjour
    Holà
    ```

### 9.3. Run the workflow (one last time!)

```bash
nextflow run hello-world.nf
```

Once again we see each process get executed three times:

```console title="Output"
 N E X T F L O W   ~  version 24.10.0

 ┃ Launching `hello-world.nf` [angry_spence] DSL2 - revision: d171cc0193

executor >  local (6)
[0e/ceb175] sayHello (2)       [100%] 3 of 3 ✔
[01/046714] convertToUpper (3) [100%] 3 of 3 ✔
```

Looking at the outputs, we see each greeting was correctly extracted and processed through the workflow. We've achieved the same result as the previous step, but now we have a lot more flexibility to add more elements to the channel of greetings we want to process.

### Takeaway

You know how to provide the input values to the workflow via a file.

More generally, you've learned how to use the essential components of Nextflow and you have a basic grasp of the logic of how to build a workflow and manage inputs and outputs.

### What's next?

Celebrate your success and take a break!

Don't worry if the channel types and operators feel like a lot to grapple with the first time you encounter them.
You'll get more opportunities to practice using these components in various settings as you work through this training course.

When you're ready, move on to Part 2 to learn about another important concept: provisioning the software required for each process.
