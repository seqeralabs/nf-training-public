# Part 4: Hello Modules

This section covers how to organize your workflow code to make development and maintenance of your pipeline more efficient and sustainable.
Specifically, we are going to demonstrate how to use **modules**.

In Nextflow, a **module** is a single process definition that is encapsulated by itself in a standalone code file.
To use a module in a workflow, you just add a single-line import statement to your workflow code file; then you can integrate the process into the workflow the same way you normally would.

When we started developing our workflow, we put everything in one single code file.

Putting processes into individual modules makes it possible to reuse process definitions in multiple workflows without producing multiple copies of the code.
This makes the code more shareable, flexible and maintainable.

!!!note

    It is also possible to encapsulate a section of a workflow as a 'subworkflow' that can be imported into a larger pipeline, but that is outside the scope of this training.

---

## 0. Warmup [TODO]

[TODO] Run hello-modules to verify that it works

---

## 1. Create a module for the `sayHello()` process

[TODO]

### 1.1. Create a directory to store modules

### 1.2. Create a file stub for the new module

Let's create an empty file for the module called `sayHello.nf`.

```bash
touch modules/local/sayHello.nf
```

This gives us a place to put the process code.

### 1.3. Move the `sayHello` process code to the module file

Copy the whole process definition over from the workflow file to the module file, making sure to copy over the `#!/usr/bin/env nextflow` shebang too.

```groovy title="modules/local/sayHello.nf" linenums="1"
#!/usr/bin/env nextflow

[TODO]
```

Once that is done, delete the process definition from the workflow file, but make sure to leave the shebang in place.

### 1.4. Add an import declaration before the workflow block

The syntax for importing a local module is fairly straightforward:

```groovy title="Import declaration syntax"
include { <MODULE_NAME> } from '<path_to_module>'
```

Let's insert that above the workflow block and fill it out appropriately.

_Before:_

```groovy title="hello-modules.nf" linenums="73"
workflow {
```

_After:_

```groovy title="hello-modules.nf" linenums="73"
// Include modules
include { sayHello } from './modules/local/sayHello.nf'

workflow {
```

### 1.5. Run the workflow to verify that it does the same thing as before

We're running the workflow with essentially the same code and inputs as before, so let's add the `-resume` flag and see what happens.

```bash
nextflow run hello-modules.nf -resume
```

Sure enough, Nextflow recognizes that it's still all the same work to be done, even if the code is split up into multiple files.

```console title="Output"
[TODO]
```

So modularizing the code in the course of development does not break resumability!

### Takeaway

You know how to extract a process into a local module.

### What's next?

Practice making more modules.

---

## 2. Repeat procedure for the remaining processes

Once you've done one, you can do a million modules...
But let's just do two more for now.

### 2.1. Create directories to house the code for the two GATK modules

[TODO]

### 2.2. Add import declarations to the workflow `main.nf` file

Now all that remains is to add the import statements:

[TODO]

_Before:_

```groovy title="hello-modules.nf" linenums="3"
// Include modules
include { sayHello } from './modules/local/hello-modules.nf'

workflow {
```

_After:_

```groovy title="hello-modules.nf" linenums="3"
// Include modules
include { sayHello } from './modules/local/sayHello.nf'
include { convertToUpper } from './modules/local/convertToUpper.nf'
include { collectGreetings } from './modules/local/collectGreetings.nf'

workflow {
```

### 2.3. Run the workflow to verify that everything still works as expected

Look at that short `hello-modules.nf` file! Let's run it once last time.

```bash
nextflow run hello-modules.nf -resume
```

Yep, everything still works, including the resumability of the pipeline.

```console title="Output"
[TODO]
```

Congratulations, you've done all this work and absolutely nothing has changed to how the pipeline works!

Jokes aside, now your code is more modular, and if you decide to write another pipeline that calls on one of those processes, you just need to type one short import statement to use the relevant module.
This is better than just copy-pasting the code, because if later you decide to improve the module, all your pipelines will inherit the improvements.

### Takeaway

You know how to modularize multiple processes in a workflow.

### What's next?

Learn to manage inputs and parameters with more flexibility and convenience.

---

## 3. [TODO] Subworkflow?
