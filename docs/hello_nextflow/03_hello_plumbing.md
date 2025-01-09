# Part 3: Hello Plumbing

Most real-world workflows involve more than one step.
In this training module, you'll learn how to connect processes together in a multi-step workflow.
You will learn basic plumbing logic for making data flow from one process to the next, collecting outputs from multiple process calls, passing more than one input through a channel and handling multiple outputs.

Building on the domain-agnostic Hello World example from earlier in the course, we're going to make the following changes to our workflow:

-   Add a second step that converts the greeting to uppercase, using the classic UNIX text replacement command `tr '[a-z]' '[A-Z]'`;
-   Add a third step that collects all the transformed greetings together back into a single file;
-   Refine the third step to handle processing subsequent batches without overwriting results;
-   Output some simple statistics about the greetings that we process.

---

## 0. Warmup: Run `hello-plumbing.nf`

We're going to use the workflow script `hello-plumbing.nf` as a starting point.
It is equivalent to the script produced by working through Part 2 of this training course.

Just to make sure everything is working, run the script once before making any changes:

```bash
nextflow run hello-plumbing.nf
```

This should produce the following output:

```console title="Output"
 N E X T F L O W   ~  version 24.10.0

Launching `hello-plumbing.nf` [tender_becquerel] DSL2 - revision: f7fbe8e223

executor >  local (3)
[74/e135b2] sayHello (3)       [100%] 3 of 3 ✔
```

---

## 1. Add the second step to the workflow

First, we need to write a new process that wraps the `tr '[a-z]' '[A-Z]'` command.
Then we'll need to add it to the workflow, setting it up to take the output of the `sayHello()` process as input.

### 1.0. Run the uppercasing command in the terminal

The step we want to add to our workflow will use the text replacement command `tr '[a-z]' '[A-Z]'` to convert the greetings output by the first step to uppercase.

!!! note

    This is a very naive text replacement one-liner that does not account for accented letters, so for example 'Holà' will become 'HOLà'. This is expected.

Let's run the full command by itself in the terminal to verify that it works as expected, just like we did at the start with `echo 'Hello World'`.

Run the following in your terminal:

```bash
echo 'Hello World' | tr '[a-z]' '[A-Z]' > UPPER-output.txt
```

The output is a text file called `UPPER-output.txt` that contains the uppercase version of the `Hello World` string:

```console title="UPPER-output.txt"
HELLO WORLD
```

### 1.1. Write the uppercasing step as a Nextflow process

We can model our new process on the first one, since we want to use all the same components.

Add the following process definition to the workflow script.

```groovy title="hello-plumbing.nf" linenums="22"
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
    cat '$input_file' | tr '[a-z]' '[A-Z]' > 'UPPER-${input_file}'
    """
}
```

Here, we compose the second output filename based on the input filename, similarly to what we did originally for the output of the first process.

!!! note

    Nextflow will determine the order of operations based on the chaining of inputs and outputs, so the order of the process definitions in the workflow script does not matter.
    However, we do recommend you be kind to your collaborators and to your future self, and try to write them in a logical order for the sake of readability.

### 1.2. Add a call to the new process in the workflow block

Now we need to tell Nextflow to actually call the process that we just defined.

In the workflow block, make the following code change:

_Before:_

```groovy title="hello-plumbing.nf" linenums="53"
    // emit a greeting
    sayHello(greeting_ch)
}
```

_After:_

```groovy title="hello-plumbing.nf" linenums="53"
    // emit a greeting
    sayHello(greeting_ch)

    // convert the greeting to uppercase
    convertToUpper()
}
```

This is not yet functional because we have not specified what should be input to the `convertToUpper()` process.

### 1.3. Pass the output of the first process to the second process

Now we need to connect the plumbing to make the output of the `sayHello()` process flow into the `convertToUpper()` process.

Conveniently, Nextflow automatically packages the output of a process into a channel called `<process>.out`.
So the output of the `sayHello` process is a channel called `sayHello.out`, which we can plug straight into the call to `convertToUpper()`.

In the workflow block, make the following code change:

_Before:_

```groovy title="hello-plumbing.nf" linenums="56"
    // convert the greeting to uppercase
    convertToUpper()
}
```

_After:_

```groovy title="hello-plumbing.nf" linenums="56"
    // convert the greeting to uppercase
    convertToUpper(sayHello.out)
}
```

For a simple case like this (one output to one input), that's all we need to do to connect two processes!

### 1.4. Run the workflow again with `-resume`

Let's run this using the `-resume` flag, since we've already run the first step of the workflow successfully.

```bash
nextflow run hello-plumbing.nf -resume
```

There is now an extra line in the console output, which corresponds to the new process we just added:

```console title="Output"
 N E X T F L O W   ~  version 24.10.0

Launching `hello-plumbing.nf` [cheeky_hamilton] DSL2 - revision: f7fbe8e223

executor >  local (3)
[45/eb4757] sayHello (2)       [100%] 3 of 3, cached: 3 ✔
[ae/4579ab] convertToUpper (3) [100%] 3 of 3 ✔
```

Have a look inside the work directory of one of the calls to the second process.

```bash
tree -a work/ae/4579ab5b4f2c1d986d3a955e31f2b7/
```

You should find two output files listed: the output of the first process, and the output of the second.

```console title="Output"
work/ae/4579ab5b4f2c1d986d3a955e31f2b7/
├── Holà-output.txt -> /workspace/gitpod/hello-nextflow/work/dc/93eab52bd47ef198b1cfe1a7721b4b/Holà-output.txt
└── UPPER-Holà-output.txt
```

The output of the first process is in there because Nextflow staged it there in order to have everything needed for execution within the same subdirectory.
However, it is actually a symbolic link pointing to the the original file in the subdirectory of the first process call.
By default, Nextflow uses symbolic links rather than copies to stage input and intermediate files.

You'll also find the final outputs in the `results` directory since we used the `publishDir` directive in the second process too.

!!! note

    All we did was connect the output of `sayHello` to the input of `convertToUpper` and the two processes could be run serially.
    Nextflow did the hard work of handling individual input and output files and passing them between the two commands for us.
    This is the power of channels in Nextflow, doing the busywork of connecting our pipeline steps together.

### Takeaway

You know how to add a second step that takes the output of the first step as input.

### What's next?

Learn how to collect outputs from batched process calls and feed them into a single process.

---

## 2. Add a step to collect all the greetings

When we apply a transformation to a batch of inputs, like we're doing here to the multiple greetings, we'll often want to collect the transformed outputs and feed them into a single step that performs some kind of analysis or summation.

Here we're simply going to write them all out to a single file, using the UNIX `cat` command.

### 2.0. Run the collection command in the terminal

The collection step we want to add to our workflow will use the `cat` command to concatenate multiple uppercased greetings into a single file.

Let's run the command by itself in the terminal to verify that it works as expected, just like we've done previously.

Run the following in your terminal:

```bash
echo 'Hello' | tr '[a-z]' '[A-Z]' > UPPER-Hello-output.txt
echo 'Bonjour' | tr '[a-z]' '[A-Z]' > UPPER-Bonjour-output.txt
echo 'Holà' | tr '[a-z]' '[A-Z]' > UPPER-Holà-output.txt
cat UPPER-Hello-output.txt UPPER-Bonjour-output.txt UPPER-Holà-output.txt > COLLECTED-output.txt
```

The output is a text file called `COLLECTED-output.txt` that contains the uppercase versions of the original greetings.

```console title="COLLECTED-output.txt"
HELLO
BONJOUR
HOLà
```

That is the result we want to achieve with our workflow.

### 2.1. Outline the collection step as a Nextflow process

We can write an outline for our new process based on the previous one, leaving out a few pieces that require extra work.

Add the following process definition to the workflow script:

```groovy title="hello-plumbing.nf" linenums="41"
/*
 * Collect uppercase greetings into a single output file
 */
process collectGreetings {

    publishDir 'results', mode: 'copy'

    input:
        ???

    output:
        path "COLLECTED-output.txt"

    script:
    """
    ??? > 'COLLECTED-output.txt'
    """
}
```

This is what we can write based on what you've learned so far.
But this is not functional!
It leaves out the input definition(s) and the first half of the script command because we need to figure out how to write that.

### 2.2. Define inputs to `collectGreetings()`

We need to collect the greetings from all the calls to the `convertToUpper()` process.
What do we know we can get from the previous step in the workflow?

The channel output by `convertToUpper()` will contain the paths to the individual files containing the uppercased greetings.
That amounts to one input slot; let's call it `input_files` for simplicity.

In the process block, make the following code change:

_Before:_

```groovy title="hello-plumbing.nf" linenums="48"
        input:
            ???
```

_After:_

```groovy title="hello-plumbing.nf" linenums="48"
        input:
            path input_files
```

Notice we use the `path` prefix even though we expect this to contain multiple files.

### 2.3. Compose the concatenation command

This is where things could get a little tricky, because we need to be able to handle an arbitrary number of input files.
Specifically, we can't write the command up front, so we need to tell Nextflow how to compose it at runtime based on what inputs flow into the process.

In other words, if we have an input channel containing the item `[file1.txt, file2.txt, file3.txt]`, we need Nextflow to turn that into `cat file1.txt file2.txt file3.txt`.

Fortunately, Nextflow is quite happy to do that for us if we simply write `cat ${input_files}` in the script command.

In the process block, make the following code change:

_Before:_

```groovy title="hello-plumbing.nf" linenums="54"
    script:
    """
    ??? > 'COLLECTED-output.txt'
    """
```

_After:_

```groovy title="hello-plumbing.nf" linenums="54"
    script:
    """
    cat ${input_files} > 'COLLECTED-output.txt'
    """
```

In theory this should handle any arbitrary number of input files.

!!! tip

    Some command-line tools require providing an argument (like `-input`) for each input file.
    In that case, we would have to do a little bit of extra work to compose the command.
    You can see an example of this in the 'Nextflow for Genomics' training course. [ADD LINK]

### 2.4. Connect the collection step

Now we should just need to call the collection process on the output of the uppercasing step.

In the workflow block, make the following code change:

_Before:_

```groovy title="hello-plumbing.nf" linenums="75"
    // convert the greeting to uppercase
    convertToUpper(sayHello.out)
}
```

_After:_

```groovy title="hello-plumbing.nf" linenums="75"
    // convert the greeting to uppercase
    convertToUpper(sayHello.out)

    // collect all the greetings into one file
    collectGreetings(convertToUpper.out)
}
```

Following the same logic as previously, this should work, right?

### 2.5. Run the workflow with `-resume`

Let's try it.

```bash
nextflow run hello-plumbing.nf -resume
```

It runs successfully, including the third step, but look at the number of calls:

```console title="Output"
executor >  local (3)
[bc/4bb541] sayHello (1)         [100%] 3 of 3, cached: 3 ✔
[89/b627e8] convertToUpper (3)   [100%] 3 of 3, cached: 3 ✔
[7c/f7961c] collectGreetings (2) [100%] 3 of 3 ✔
```

Have a look at the contents of the final output file too:

```console title="COLLECTED-output.txt"
Holà
```

Oh no. The collection step was run individually on each greeting, which is NOT what we wanted.

We need to do something to tell Nextflow explicitly that we want that third step to run on all the items in the channel output by `convertToUpper()`.

### 2.6. Add the `collect()` operator

Yes, once again the answer to our problem is an operator, the aptly-named [`collect()`](https://www.nextflow.io/docs/latest/reference/operator.html#collect).

This time it's going to look a bit different because we're not adding it in the context of a channel factory.
Instead, we append it to `convertToUpper.out`, which becomes `convertToUpper.out.collect()`, in the process call.

In the workflow block, make the following code changes:

_Before:_

```groovy title="hello-plumbing.nf" linenums="78"
    // collect all the greetings into one file
    collectGreetings(convertToUpper.out)
}
```

_After:_

```groovy title="hello-plumbing.nf" linenums="78"
    // collect all the greetings into one file
    collectGreetings(convertToUpper.out.collect())

    // optional view statements
    convertToUpper.out.view{ "Before collect: $it" }
    convertToUpper.out.collect().view{ "After collect: $it" }
}
```

Notice that we also included a couple of `view()` statements to visualize the before and after states of the channel contents. The `view()` statements can go anywhere you want; we put them after the call for readability.

### 2.7. Run the workflow again with `-resume`

Let's try it again.

```bash
nextflow run hello-plumbing.nf -resume
```

It runs successfully, and this time the third step is only called once!

```console title="Output"
executor >  local (1)
[ec/3bb893] sayHello (2)       [100%] 3 of 3, cached: 3 ✔
[06/dc3c59] convertToUpper (1) [100%] 3 of 3, cached: 3 ✔
[4e/0a5195] collectGreetings   [100%] 1 of 1 ✔
Before collect: /workspace/gitpod/hello-nextflow/work/5e/59bb64da77666f94fb25fb64f7ce10/UPPER-Holà-output.txt
Before collect: /workspace/gitpod/hello-nextflow/work/06/dc3c59e025d435209e9aa55f90094b/UPPER-Hello-output.txt
Before collect: /workspace/gitpod/hello-nextflow/work/89/b627e818957935446948652e8727e6/UPPER-Bonjour-output.txt
After collect: [/workspace/gitpod/hello-nextflow/work/5e/59bb64da77666f94fb25fb64f7ce10/UPPER-Holà-output.txt, /workspace/gitpod/hello-nextflow/work/06/dc3c59e025d435209e9aa55f90094b/UPPER-Hello-output.txt, /workspace/gitpod/hello-nextflow/work/89/b627e818957935446948652e8727e6/UPPER-Bonjour-output.txt]
```

Looking at the output of the `view()` statements, we see the following:

-   Three `Before collect:` statements, one for each greeting: at that point the file paths are individual items in the channel.
-   A single `After collect:` statement: the three file paths are now packaged into a single item.

Have a look at the contents of the final output file too:

```console title="COLLECTED-output.txt"
BONJOUR
HELLO
HOLà
```

This time we have all three greetings in the final output file. Success!

!!! Note

    If you run this several times without `-resume`, you will see the order of the greetings changes.
    This shows you that the order in which items flow through the pipeline is not guaranteed to be consistent.

### Takeaway

You know how to collect outputs from a batch of process calls and feed them into a summation step.

### What's next?

Learn how to pass more than one input through a channel.

---

## 3. Add a batch identifier to make the final output file distinct

We'll want to be able to process subsequent batches of greetings without overwriting the final results.

To that end, we're going to make the following refinements:

-   Modify the collector process to use a batch identifier in the final file name
-   Add a command-line parameter to assign a batch identifier and pass it to the process

### 3.1. Add the batch identifier to the expected inputs

Good news: we can declare as many expected inputs as we want.

In the process block, make the following code change:

_Before:_

```groovy title="hello-plumbing.nf" linenums="48"
    input:
        path input_files
```

_After:_

```groovy title="hello-plumbing.nf" linenums="48"
    input:
        path input_files
        val batch_id
```

### 3.2. Use the `batch_id` variable in the output file name

In the process block, make the following code change:

_Before:_

```groovy title="hello-plumbing.nf" linenums="52"
    output:
        path "COLLECTED-output.txt"

    script:
    """
    cat ${input_files} > 'COLLECTED-output.txt'
    """
```

_After:_

```groovy title="hello-plumbing.nf" linenums="52"
    output:
        path "COLLECTED-${batch_id}-output.txt"

    script:
    """
    cat ${input_files} > 'COLLECTED-${batch_id}-output.txt'
    """
```

This sets up the process to use the `batch_id` value to generate a specific filename for the final output of the workflow.

### 3.3. Add a `batch` command-line parameter

Now we need a way to supply the value for `batch_id`.

You already know how to use the `params` system to declare CLI parameters.
Let's use that to declare a `batch` parameter with a default value (because we are lazy).

In the pipeline parameters section, make the following code changes:

_Before:_

```groovy title="hello-plumbing.nf" linenums="61"
/*
 * Pipeline parameters
 */
params.greeting = 'data/greetings.csv'
```

_After:_

```groovy title="hello-plumbing.nf" linenums="61"
/*
 * Pipeline parameters
 */
params.greeting = 'data/greetings.csv'
params.batch = 'test-batch'
```

Remember you can override that default value by specifying a value with `--batch` on the command line.

### 3.4. Pass the `batch` parameter to the process

To provide the value of the parameter to the process, we need to add it in the process call.

In the workflow block, make the following code change:

_Before:_

```groovy title="hello-plumbing.nf" linenums="80"
    // collect all the greetings into one file
    collectGreetings(convertToUpper.out.collect())
```

_After:_

```groovy title="hello-plumbing.nf" linenums="80"
    // collect all the greetings into one file
    collectGreetings(convertToUpper.out.collect(), params.batch)
```

!!! warning

    You MUST provide the inputs to a process in the EXACT SAME ORDER as they are listed in the input definition block of the process.

### 3.5. Run the workflow

Let's try running this with a batch name on the command line.

```bash
nextflow run hello-plumbing.nf -resume --batch trio
```

It runs successfully and produces the desired output:

```console title="bash"
cat results/COLLECTED-trio-output.txt
```

```console title="Output"
HELLO
BONJOUR
HOLà
```

### Takeaway

You know how to pass more than one input through a channel.

### What's next?

Learn how to emit multiple outputs and handle them conveniently.

---

## 4. Add the count of greetings as an extra output to the collection step

When a process produces only one output, it's easy to access it (in the workflow block) using the `<process>.out` syntax.
When there are two or more outputs, the default way to select a specific output is to use the corresponding (zero-based) index; for example, you would use `<process>.out[0]` to get the first output.
This is not super convenient.

Let's have a look at how we can select and use a specific output of a process when there are more than one.

Since our workflow is very simple, we're going to contrive an example of a second output by pretending that we want to track the number of greetings that are being collected for a given batch of inputs.

### 4.1. Count the number of greetings collected

First we need to get that count.
Conveniently, Nextflow lets us add arbitrary code in the `script:` block of the process definition, which comes in really handy for doing things like this.

In this case, we can use the built-in `size()` function to get the number of files in the `input_files` array.

In the process block, make the following code change:

_Before:_

```groovy title="hello-plumbing.nf" linenums="56"
    script:
    """
    cat ${input_files} > 'COLLECTED-${batch_id}-output.txt'
    """
```

_After:_

```groovy title="hello-plumbing.nf" linenums="56"
    script:
        size = input_files.size()
    """
    cat ${input_files} > 'COLLECTED-${batch_id}-output.txt'
    """
```

### 4.2. Emit the count as a named output

Next, we're going to add the `size` variable we just created to the `output:` block.

In the process block, make the following code change:

_Before:_

```groovy title="hello-plumbing.nf" linenums="52"
    output:
        path "COLLECTED-${batch_id}-output.txt"
```

_After:_

```groovy title="hello-plumbing.nf" linenums="52"
    output:
        path "COLLECTED-${batch_id}-output.txt"
        val size , emit: count
```

Notice that we added `, emit: count` to the `val size` output declaration. This is going to allow us to access that output by the name `count` from the workflow block.

### 4.3. Use `view()` to access the output

In the workflow block, make the following code change:

_Before:_

```groovy title="hello-plumbing.nf" linenums="82"
    // collect all the greetings into one file
    collectGreetings(convertToUpper.out.collect(), params.batch)
```

_After:_

```groovy title="hello-plumbing.nf" linenums="82"
    // collect all the greetings into one file
    collectGreetings(convertToUpper.out.collect(), params.batch)

    // emit a message about the size of the batch
    collectGreetings.out.count.view{ "There were $it greetings in this batch" }
```

### 4.4. Run the workflow

Let's try running this with the current batch of greetings.

```bash
nextflow run hello-plumbing.nf -resume --batch trio
```

This runs successfully:

```console title="Output"
executor >  local (1)
[83/86e10d] sayHello (2)       [100%] 3 of 3, cached: 3 ✔
[a4/be9d34] convertToUpper (2) [100%] 3 of 3, cached: 3 ✔
[f6/75efca] collectGreetings   [100%] 1 of 1 ✔
There were 3 greetings in this batch
```

The last line shows that we correctly retrieved the count of greetings processed.
Feel free to add more to the CSV and see what happens.

### Takeaway

You know how to make a process emit a named output and how to access it from the workflow block.

More generally, you understand the key principles involved in connecting processes together in common ways.

### What's next?

Take a long break, you've earned it.
When you're ready, move on to Part 4 to learn how to modularize your code for better maintainability and code efficiency.
