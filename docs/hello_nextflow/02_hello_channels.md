# Part 2: Hello Channels

[TODO] CHANNELS ARE X. LEARN HOW TO USE THEM TO PROVIDE INPUTS TO PROCESSES

---

## 0. Warmup: Run `hello-channels.nf`

We're going to use the workflow script `hello-channels.nf` as a starting point.
It is equivalent to the script produced by working through Part 1 of this training course.

Just to make sure everything is working, run the script once before making any changes:

```bash
nextflow run hello-channels.nf
```

```console title="Output"
 N E X T F L O W   ~  version 24.10.0

Launching `hello-channels.nf` [silly_moriondo] DSL2 - revision: a0dfbc86fe

executor >  local (1)
[03/b321a3] sayHello [100%] 1 of 1 ✔
```

---

## 1. Add variable inputs using a channel

In its current state, our workflow uses a greeting hardcoded into the process command.
We want to add some flexibility by using an input variable, so that we can more easily change the greeting.

This requires us to make four inter-related changes to our script:

1. Tell the process to expect variable inputs by adding an `input:` block
2. Edit the process to use the input
3. Create a **channel** to pass input to the process (more on that in a minute)
4. Add the channel as input to the process call

### 1.1. Add an input block to the process definition

First we need to adapt the process definition to accept an input called `greeting`.

In the process block, make the following code change:

_Before:_

```groovy title="hello-channels.nf" linenums="6"
process sayHello {

    publishDir 'results', mode: 'copy'

    output:
        path 'output.txt'
```

_After:_

```groovy title="hello-channels.nf" linenums="6"
process sayHello {

    publishDir 'results', mode: 'copy'

    input:
        val greeting

    output:
        path 'output.txt'
```

The `greeting` variable is prefixed by `val` to tell Nextflow it's a value (not a path).

### 1.2. Edit the process command to use the input variable

Now we swap the original hardcoded value for the input variable.

In the process block, make the following code change:

_Before:_

```groovy title="hello-channels.nf" linenums="16"
"""
echo 'Hello World!' > output.txt
"""
```

_After:_

```groovy title="hello-channels.nf" linenums="16"
"""
echo '$greeting' > output.txt
"""
```

Make sure to prepend the `$` symbol to tell Nextflow this is a variable name that needs to be replaced with the actual value (=interpolated).

### 1.3. Create an input channel

Now that our process expects an input, we need to set up that input in the workflow body.

We are going to do this using a channel.
And to keep things simple for now, we are going to use the simplest possible channel, containing a single value.

This is the line of code to do it:

`greeting_ch = Channel.of('Hello world!')`

This creates a channel called `greeting_ch` using the `Channel.of()` channel factory, which sets up a simple value channel, and gives it the string `'Hello world!'` to use as the greeting value.

In the workflow block, make the following code change:

_Before:_

```groovy title="hello-channels.nf" linenums="21"
workflow {

    // emit a greeting
    sayHello()
}
```

_After:_

```groovy title="hello-channels.nf" linenums="21"
workflow {

    // create a channel for inputs
    greeting_ch = Channel.of('Hello world!')

    // emit a greeting
    sayHello()
}
```

We are still hardcoding the value of the greeting, but now it's one level up, in the workflow body instead of being in the process definition.
This is progress.

### 1.4. Add the channel as input to the process call

Now we need to actually plug our newly created channel into the `sayHello()` process call.

In the workflow block, make the following code change:

_Before:_

```groovy title="hello-channels.nf" linenums="26"
// emit a greeting
sayHello()
```

_After:_

```groovy title="hello-channels.nf" linenums="26"
// emit a greeting
sayHello(greeting_ch)
```

This tells Nextflow to run the `sayHello` process on the contents of the `greeting_ch` channel.

### 1.5. Run the workflow command again

Let's run it!

```bash
nextflow run hello-channels.nf
```

If you made all four edits correctly, you should get another successful execution:

```console title="Output"
 N E X T F L O W   ~  version 24.10.0

 ┃ Launching `hello-channels.nf` [prickly_avogadro] DSL2 - revision: b58b6ab94b

executor >  local (1)
[1f/50efd5] sayHello (1) [100%] 1 of 1 ✔
```

Feel free to check the results directory to satisfy yourself that the outcome is still the same as previously.
So far we're just progressively tweaking the code to increase the flexibility of our workflow while achieving the same end result.

### Takeaway

You know how to use a simple channel to provide an input to a process.

### What's next?

Learn how to make the workflow run on a batch of multiple input values.

---

## 2. Modify the workflow to run on a batch of input values

Workflows typically run on batches of inputs that are meant to be processed in bulk, so we want to upgrade the workflow to accept multiple input values.

### 2.1. Load multiple greetings into the input channel

Conveniently, the `Channel.of()` channel factory we've been using is quite happy to accept more than one value, so we don't need to modify that at all.
We just have to load more values into the channel.

In the workflow block, make the following code change:

_Before:_

```groovy title="hello-channels.nf" linenums="46"
// create a channel for inputs
greeting_ch = Channel.of('Hello')
```

_After:_

```groovy title="hello-channels.nf" linenums="46"
// create a channel for inputs
greeting_ch = Channel.of('Hello','Bonjour','Holà')
```

The documentation tells us this should work. Can it really be so simple?

### 2.2. Run the command and look at the log output

Let's try it.

```bash
nextflow run hello-channels.nf
```

Well, it certainly seems to run just fine:

```console title="Output"
 N E X T F L O W   ~  version 24.10.0

 ┃ Launching `hello-channels.nf` [lonely_pare] DSL2 - revision: b9f1d96905

executor >  local (3)
[3d/1fe62c] sayHello (2)       [100%] 3 of 3 ✔
```

However... This seems to indicate that '3 of 3' calls were made for the process, which is encouraging, but this only give us one subdirectory path. What's going on?

By default, the ANSI logging system writes the logging from multiple calls to the same process on the same line. Fortunately, we can disable that behavior.

### 2.3. Run the command again with the `-ansi-log false` option

To expand the logging to display one line per process call, add `-ansi-log false` to the command.

```bash
nextflow run hello-channels.nf -ansi-log false
```

This time we see all six work subdirectories listed in the output:

```console title="Output"
N E X T F L O W  ~  version 24.02.0-edge
Launching `hello-channels.nf` [big_woese] DSL2 - revision: 53f20aeb70
[62/d81e63] Submitted process > sayHello (1)
[19/507af3] Submitted process > sayHello (2)
[8a/3126e6] Submitted process > sayHello (3)
```

That's much better; at least for a simple workflow.
For a complex workflow, or a large number of inputs, having the full list output to the terminal might get a bit overwhelming.

That being said, we have another problem. If you look in the `results` directory, there is only one file: `output.txt`!

```console title="Directory contents"
results
└── output.txt
```

What's up with that? Shouldn't we be expecting a separate file per input greeting, so three files in all?
Did all three greetings go into a single file?
You can check the contents of `output.txt`; you will find only one of the three.

You may recall that we hardcoded the output file name for the `sayHello` process, so all three calls produced a file called `output.txt`.
You can check the work subdirectories for each of the three processes; each of them contains a file called `output.txt` as expected.

As long as the output files stay there, isolated from the other processes, that is okay.
But when the `publishDir` directive copies each of them to the same `results` directory, whichever got copied there first gets overwritten by the next one, and so on.

### 2.4. Ensure the output file names will be unique

We can continue publishing all the outputs to the same results directory, but we need to ensure they will have unique names.
Specifically, we need to modify the first process to generate a file name dynamically so that the final file names will be unique.

So how do we make the file names unique? A common way to do that is to use some unique piece of metadata as part of the file name.
Here, for convenience, we'll just use the greeting itself since it's just a short string, and prepend it to the base output filename.

In the process block, make the following code changes:

_Before:_

```groovy title="hello-channels.nf" linenums="11"
process sayHello {

    publishDir 'results', mode: 'copy'

    input:
        val greeting

    output:
        path 'output.txt'

    script:
    """
    echo '$greeting' > output.txt
    """
}
```

_After:_

```groovy title="hello-channels.nf" linenums="11"
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

Make sure to replace `output.txt` in both the output definition and in the `script:` command block.

!!! tip

    In the output definition, you MUST use double quotes around the output filename expression (NOT single quotes), otherwise it will fail.

This should produce a unique output file name every time the process is called.

### 2.5. Run the workflow and look at the results directory

Let's run it and check that it works.

```bash
nextflow run hello-channels.nf
```

Reverting back to the summary view, the output looks like this again:

```console title="Output"
 N E X T F L O W   ~  version 24.10.0

 ┃ Launching `hello-channels.nf` [jovial_mccarthy] DSL2 - revision: 53f20aeb70

executor >  local (3)
[03/f007f2] sayHello (1)       [100%] 3 of 3 ✔
```

But more importantly, now we have three new files in addition to the one we already had in the `results` directory:

```console title="Directory contents"
results
├── Bonjour-output.txt
├── Hello-output.txt
├── Holà-output.txt
└── output.txt
```

Success! Now we can add as many greetings as we like without worrying about output files being overwritten.

!!! note

    In practice, naming files based on the input data itself is almost always impractical.
    The better way to generate dynamic filenames is to use a samplesheet contain relevant metadata (such as unique sample IDs) and create a data structure called a 'map'.
    We can then pass the map to the processes, which can be set up to select an appropriate identifier to generate the filenames.
    You'll learn how to do that later in your Nextflow training.

### Takeaway

You know how to feed a batch of multiple input elements through a channel.

### What's next?

Learn how to make the workflow take a file as its source of input values.

---

## 3. Use CLI parameters to supply input values

We want to be able to specify the input from the command line, since that is the piece that will almost always be different in subsequent runs of the workflow.
Good news: Nextflow has a built-in workflow parameter system called `params`, which makes it easy to declare and use CLI parameters.

### 3.1. Edit the input channel declaration to use a parameter

Here we replace the hardcoded input strings with `params.greeting` in the channel creation line.

In the workflow block, make the following code changes:

_Before:_

```groovy title="hello-channels.nf" linenums="23"
// create a channel for inputs
greeting_ch = Channel.of('Hello','Bonjour','Holà')
```

_After:_

```groovy title="hello-channels.nf" linenums="23"
// create a channel for inputs
greeting_ch = Channel.of(params.greeting)
```

This automatically creates a parameter called `greeting` that you can use to provide a value in the command line.

### 3.2. Run the workflow again with the `--greeting` parameter

To provide a value for this parameter, simply add `--greeting <value>` to your command line.
Let's start with using a single value.

```bash
nextflow run hello-channels.nf --greeting 'Bonjour le monde!'
```

Running this should feel extremely familiar by now.

```console title="Output"
 N E X T F L O W   ~  version 24.10.0

 ┃ Launching `hello-channels.nf` [cheesy_engelbart] DSL2 - revision: b58b6ab94b

executor >  local (1)
[1c/9b6dc9] sayHello (1) [100%] 1 of 1 ✔
```

Be sure to open up the output file to check that you now have the new version of the greeting. Voilà!

!!! tip

    You can readily distinguish Nextflow-level parameters from pipeline-level parameters.

    - Parameters that apply to a pipeline always take a double hyphen (`--`).
    - Parameters that modify a Nextflow setting, _e.g._ the `-resume` feature we used earlier, take a single hyphen (`-`).

### 3.3. Set a default value for a command line parameter

In many cases, it makes sense to supply a default value for a given parameter so that you don't have to specify it for every run.

Let's initialize the `greeting` parameter with a default value by adding a parameter declaration before the workflow definition.

```groovy title="hello-channels.nf" linenums="22"
/*
 * Pipeline parameters
 */
params.greeting = 'Holà mundo!'
```

!!! tip

    You can put the parameter declaration inside the workflow block if you prefer. Whatever you choose, try to group similar things in the same place so you don't end up with declarations all over the place.

### 3.4. Run the workflow again without specifying the parameter

Now that you have a default value set, you can run the workflow again without having to specify a value in the command line.

```bash
nextflow run hello-channels.nf
```

The console output should look the same.

```console title="Output"
 N E X T F L O W   ~  version 24.10.0

 ┃ Launching `hello-channels.nf` [wise_waddington] DSL2 - revision: 988fc779cf

executor >  local (1)
[c0/8b8332] sayHello (1) [100%] 1 of 1 ✔
```

Check the output in the results directory, and... Tadaa! It works!
Nextflow used the default value to name the output.

### 3.5. Run the workflow again with the parameter to override the default value

If you provide the parameter on the command line, the CLI value will override the default value.

Try it out:

```bash
nextflow run hello-channels.nf --greeting 'Konnichiwa!'
```

The console output should look the same, and you will have the corresponding new output in your results directory.

!!! note

    In Nextflow, there are multiple places where you can specify values for parameters.
    If the same parameter is set to different values in multiple places, Nexflow will determine what value to use based on the order of precedence that is described [here](https://www.nextflow.io/docs/latest/config.html).

### Takeaway

You know how to use CLI parameters to feed inputs to the workflow.

### What's next?

Learn how to manage channel contents using operators.

---

## 4. Supply a batch of multiple values via the `params` system

We sneakily reverted to running on just one value there.
What if we want to run on a batch again, like we did earlier?

### 4.1. Try switching the `params.greeting` value to an array of values

Common sense suggests we should be able to simply pass in an array of values instead of a single value. Right?

Make the following code change to the parameter declaration:

_Before:_

```groovy title="hello-channels.nf" linenums="23"
/*
 * Pipeline parameters
 */
params.greeting = 'Holà mundo'
```

_After:_

```groovy title="hello-channels.nf" linenums="23"
/*
 * Pipeline parameters
 */
params.greeting = ['Holà mundo','Konnichiwa,','Dobrý den']
```

### 4.2. Run the workflow

Try running this:

```bash
nextflow run hello-channels.nf
```

Oh no! Nextflow throws an error that starts like this:

```console title="Output"
ERROR ~ Error executing process > 'sayHello (1)'

Caused by:
  Missing output file(s) `[Holà mundo, Konnichiwa, Dobrý den]-output.txt` expected by process `sayHello (1)`
```

It looks like Nextflow tried to run a single process call, using `[Holà mundo, Konnichiwa, Dobrý den]` as a string value, instead of using the three strings in the array as separate values.

How do we get Nextflow to unpack the array and load the individual strings into the channel?

This is where **operators** come in. Nextflow [operators](https://www.nextflow.io/docs/latest/reference/operator.html) allow us to transform how the contents of a channel are packaged.

### 4.3. Add the `flatten()` operator

If you skim through the list of operators linked above, you'll find [`flatten()`](https://www.nextflow.io/docs/latest/reference/operator.html#flatten), which does exactly what we need: unpack the contents of an array and emits them as individual items.

To apply the `flatten()` operator to our input channel, we simply append it to the channel factory declaration.

In the workflow block, make the following code change:

_Before:_

```groovy title="hello-channels.nf" linenums="29"
// create a channel for inputs
greeting_ch = Channel.of(params.greeting)
```

_After:_

```groovy title="hello-channels.nf" linenums="29"
// create a channel for inputs
greeting_ch = Channel.of(params.greeting)
                     .flatten()
```

Here we added the operator on the next line for readability, but you can add operators on the same line as the channel factory if you prefer.

### 4.4. Add `view()` to inspect channel contents

We could run this right away to test if it works, but while we're at it, we're also going to add a couple of [`view()`](https://www.nextflow.io/docs/latest/reference/operator.html#view) directives, which allow us to inspect the contents of a channel.
You can think of `view()` as a debugging tool, like a `print()` statement in Python, if you're familiar with that.

In the workflow block, make the following code change:

_Before:_

```groovy title="hello-channels.nf" linenums="29"
// create a channel for inputs
greeting_ch = Channel.of(params.greeting)
                     .flatten()
```

_After:_

```groovy title="hello-channels.nf" linenums="29"
// create a channel for inputs
greeting_ch = Channel.of(params.greeting)
                     .view{ "Before flatten: $it" }
                     .flatten()
                     .view{ "After flatten: $it" }
```

Here `$it` is an implicit variable that represents each individual item loaded in a channel.

### 4.5. Run the workflow

Finally, you can try running the workflow again!

```bash
nextflow run hello-channels.nf
```

This time it works AND gives us the additional insight into what the contents of the channel look like before and after we run the `flatten()` operator:

```console title="Output"
Launching `hello-channels.nf` [irreverent_shaw] DSL2 - revision: b3a71cc376

executor >  local (3)
[20/8f32e4] sayHello (1) [100%] 3 of 3 ✔
Before flatten: [Holà mundo, Konnichiwa, Dobrý den]
After flatten: Holà mundo
After flatten: Konnichiwa
After flatten: Dobrý den
```

You see that we get a single `Before flatten:` statement because at that point the channel contains one item, the original array.
Then we get three separate `After flatten:` statements, one for each greeting, which are now individual items in the channel.

Importantly, this means each item can now be processed separately by the workflow.

!!! tip

    You should delete or comment out the `view()` statements before moving on.

    ```groovy title="hello-channels.nf" linenums="29"
    // create a channel for inputs
    greeting_ch = Channel.of(params.greeting)
                         .flatten()
    ```

### Takeaway

You know how to use the `flatten()` operator to handle a batch of values passed in through the CLI parameter system, and how to use the `view()` directive to inspect channel contents before and after applying an operator.

### What's next?

Learn how to make the workflow take a file as its source of input values.

---

## 5. Modify the workflow to take a file as its source of input values

It's often the case that, when we want to run on a batch of multiple input elements, the input values are contained in a file.
As an example, we prepared a CSV file called `greetings.csv` in the `data/` directory, containing several greetings separated by commas.

```csv title="greetings.csv"
Hello,Bonjour,Holà
```

So we need to modify our workflow to read in the values from a file like that.

### 5.1. Switch the `params.greeting` to the CSV file

In the workflow block, make the following code change:

_Before:_

```groovy title="hello-channels.nf" linenums="23"
/*
 * Pipeline parameters
 */
params.greeting = ['Holà mundo','Konnichiwa,','Dobrý den']
```

_After:_

```groovy title="hello-channels.nf" linenums="23"
/*
 * Pipeline parameters
 */
params.greeting = 'data/greetings.csv'
```

### 5.2. Update the channel declaration to use the input file

Since we now want to use a file instead of a simple value as the input, we can't use the `Channel.of()` channel factory from before.
We need to switch to using a new channel factory, `Channel.fromPath()`, which has some built-in functionality for handling file paths.

In the workflow block, make the following code change:

_Before:_

```groovy title="hello-channels.nf" linenums="29"
// create a channel for inputs
greeting_ch = Channel.of(params.greeting)
                     .flatten()
```

_After:_

```groovy title="hello-channels.nf" linenums="29"
// create a channel for inputs from a CSV file
greeting_ch = Channel.fromPath(params.greeting)
```

### 5.3. Run the workflow

Let's try running the workflow with the new channel factory and the input file.

```bash
nextflow run hello-channels.nf
```

Oh no, another error. This one starts like this:

```console title="Output"
ERROR ~ Error executing process > 'sayHello (1)'

Caused by:
  File `/workspace/gitpod/hello-nextflow/data/greetings.csv-output.txt` is outside the scope of the process work directory: /workspace/gitpod/hello-nextflow/work/cf/8f1c7f433eed3d79e2fa4d1ca81e10

Command executed:

  echo '/workspace/gitpod/hello-nextflow/data/greetings.csv' > '/workspace/gitpod/hello-nextflow/data/greetings.csv-output.txt'
```

The `Command executed:` bit is especially helpful here (you may need to scroll down a bit to find it).

Once again it looks like Nextflow tried to run a single process call, but using the file path itself as a string value.
So it has resolved the file path correctly, but it didn't open the file, which is what we wanted.

How do we get Nextflow to open the file and load its contents into the channel?

Sounds like we need another [operator](https://www.nextflow.io/docs/latest/reference/operator.html).

### 5.4. Add `splitCsv()` operator

Looking through the list of operators again, we find [`splitCsv()`](https://www.nextflow.io/docs/latest/reference/operator.html#splitCsv), which is designed to parse and split CSV-formatted text.

To apply the operator, add it to the channel construction instruction like previously; and we're also going to include view statements while we're at it.

In the workflow block, make the following code change:

_Before:_

```groovy title="hello-channels.nf" linenums="46"
// create a channel for inputs from a CSV file
greeting_ch = Channel.fromPath(params.greeting)
```

_After:_

```groovy title="hello-channels.nf" linenums="46"
// create a channel for inputs from a CSV file
greeting_ch = Channel.fromPath(params.greeting)
                     .view{ "Before splitCsv: $it" }
                     .splitCsv()
                     .view{ "After splitCsv: $it" }
```

### 5.5. Run the workflow again

Let's try running the workflow with the added CSV-parsing logic.

```bash
nextflow run hello-channels.nf
```

Sadly, this fails too. The console output and error starts like this:

```console title="Output"
Before splitCsv: /workspace/gitpod/hello-nextflow/data/greetings.csv
After splitCsv: [Hello, Bonjour, Holà]
ERROR ~ Error executing process > 'sayHello (1)'

Caused by:
  Missing output file(s) `[Hello, Bonjour, Holà]-output.txt` expected by process `sayHello (1)`
```

Okay, this looks a bit familiar. It looks like what happened earlier the first time we tried to run on an array of values.
So Nextflow has successfully loaded the file contents into the channel, but as a single item.
Once again we're going to need to split it up.

Can we use the same solution as that time?

### 5.6. Add `flatten()` operator

Remember `flatten()`? We love `flatten()`.

You know the drill now: we're going to add the operator to the channel construction instruction, and include another `view()` call.

In the workflow block, make the following code change:

_Before:_

```groovy title="hello-channels.nf" linenums="29"
// create a channel for inputs from a CSV file
greeting_ch = Channel.fromPath(params.greeting)
                     .view{ "Before splitCsv: $it" }
                     .splitCsv()
                     .view{ "After splitCsv: $it" }
```

_After:_

```groovy title="hello-channels.nf" linenums="29"
// create a channel for inputs from a CSV file
greeting_ch = Channel.fromPath(params.greeting)
                     .view{ "Before splitCsv: $it" }
                     .splitCsv()
                     .view{ "After splitCsv: $it" }
                     .flatten()
                     .view{ "After flatten: $it" }
```

### 5.7. Run the workflow one more time

Let's run it one more time:

```bash
nextflow run hello-channels.nf
```

This time it should run without error!

```console title="Output"
executor >  local (3)
[99/657682] sayHello (3) [100%] 3 of 3 ✔
Before splitCsv: /workspace/gitpod/hello-nextflow/data/greetings.csv
After splitCsv: [Hello, Bonjour, Holà]
After flatten: Hello
After flatten: Bonjour
After flatten: Holà
```

Looking at the output of the `view()` statements, we see the following:

-   A single `Before splitCsv:` statement: at that point the channel contains one item, the original file path.
-   A single `After splitCsv:` statement: at that point the channel still contains only one item, an array containing the three values.
-   Three separate `After flatten:` statements: one for each greeting, which are now individual items in the channel.

We can also look at the output files, which show that each greeting was correctly extracted and processed through the workflow.

We've achieved the same result as previously, but now we have a lot more flexibility to add more elements to the channel of greetings we want to process by modifying an input file, without modifying any code.

!!! note

    Here we had all greetings on one line in the CSV file.
    You can try adding more lines to the CSV file and see what happens, with and without the `flatten()` operator.

### Takeaway

You know how to use operators like `splitCsv()` and `flatten()` to handle a batch of values passed in through an input file.

More generally, you have a basic understanding of how Nextflow uses channels to manage inputs to processes.

### What's next?

Take a break!
When you're ready, move on to Part 3 to learn how to add more steps to your workflow and do some slightly more interesting plumbing.
