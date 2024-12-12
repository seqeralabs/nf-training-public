# Part 6: Hello Modules

This section covers how to organize your workflow code to make development and maintenance of your pipeline more efficient and sustainable.
Specifically, we are going to demonstrate how to use **modules**.

In Nextflow, a **module** is a single process definition that is encapsulated by itself in a standalone code file.
To use a module in a workflow, you just add a single-line import statement to your workflow code file; then you can integrate the process into the workflow the same way you normally would.

Putting processes into individual modules makes it possible to reuse process definitions in multiple workflows without producing multiple copies of the code.
This makes the code more shareable, flexible and maintainable.

!!!note

    It is also possible to encapsulate a section of a workflow as a 'subworkflow' that can be imported into a larger pipeline, but that is outside the scope of this training.

---

## 0. Warmup

When we started developing our workflow, we put everything in one single code file.
In Part 5 (Hello Config), we started turning our one-file workflow into a proper pipeline project.
We moved to the standard Nextflow convention of naming the workflow file `main.nf`, fleshed out the configuration file, and added a parameter file.

Now it's time to tackle **modularizing** our code, _i.e._ extracting the process definitions into modules.

We're going to be working with a clean set of project files inside the project directory called `hello-modules` (for Modules).

### 0.1. Explore the `hello-modules` directory

Let's move into the project directory.

```bash
cd hello-modules
```

!!! warning

    If you're continuing on directly from Part 5, you'll need to move up one directory first.
    ```
     cd ../hello-modules
    ```

The `hello-modules` directory has the same content and structure that you're expected to end up with in `hello-config` on completion of Part 5.

```console title="Directory contents"
hello-modules/
├── demo-params.json
├── main.nf
└── nextflow.config
```

For a detailed description of these files, see the warmup section in Part 5.

### 0.2. Create a symbolic link to the data

Just like last time, we need to set up a symlink to the data.
To do so, run this command from inside the `hello-modules` directory:

```bash
ln -s ../data data
```

This creates a symbolic link called `data` pointing to the data directory one level up.

### 0.3 Run the workflow using the appropriate profiles

Now that everything is in place, we should be able to run the workflow using the profiles we set up in Part 5.

```bash
nextflow run main.nf -profile my_laptop,demo
```

And so it does.

```console title="Output"
 N E X T F L O W   ~  version 24.10.0

 ┃ Launching `main.nf` [special_brenner] DSL2 - revision: 5a07b4894b

executor >  local (7)
[26/60774a] SAMTOOLS_INDEX (1)       | 3 of 3 ✔
[5a/eb40c4] GATK_HAPLOTYPECALLER (2) | 3 of 3 ✔
[8f/94ac86] GATK_JOINTGENOTYPING     | 1 of 1 ✔
```

Like previously, there will now be a `work` directory and a `results_genomics` directory inside your project directory.

### Takeaway

You're ready to start modularizing your workflow.

### What's next?

Learn how to create your first module following conventions inspired by the nf-core project.

---

## 1. Create a module for the `SAMTOOLS_INDEX` process

From a technical standpoint, you can create a module simply by copying the process definition into its own file, and you can name that file anything you want.
However, the Nextflow community has adopted certain conventions for code organization, influenced in large part by the [nf-core](https://nf-co.re) project (which we'll cover later in this training series).

The convention for Nextflow modules is that the process definition should be written to a standalone file named `main.nf`, stored in a directory structure with three to four levels:

```console title="Directory structure"
modules
└── local
    └── (<toolkit>)
        └── <tool>
            └── main.nf
```

By convention, all modules are stored in a directory named `modules`.
Additionally, the convention distinguishes _local_ modules (which are part of your project) from _remote_ modules contained in remote repositories.

The next levels down are named after the toolkit (if there is one) then the tool itself.
If the process defined in the module invokes more than one tool, as the GATK_JOINTGENOTYPING does in our example workflow, the name of the module can be the name of the method, or something to that effect.

For example, the module we create for the `SAMTOOLS_INDEX` process will live under `modules/local/samtools/index/`.

```console title="Directory structure"
modules
└── local
    └── samtools
        └── index
            └── main.nf
```

!!!note

    We will cover remote modules later in this training, when we introduce the [nf-core library of modules](https://nf-co.re/modules/).

So let's get started.

### 2.1. Create a directory to house the local module code for the `SAMTOOLS_INDEX` process

Run this command to create the appropriate directory structure:

```bash
mkdir -p modules/local/samtools/index
```

The `-p` flag takes care of creating parent directories as needed.

### 2.2. Create a file stub for the `SAMTOOLS_INDEX` process module

Now let's create an empty `main.nf` file for the module.

```bash
touch modules/local/samtools/index/main.nf
```

This gives us a place to put the process code.

### 2.3. Move the `SAMTOOLS_INDEX` process code to the module file

Copy the whole process definition over from the workflow's `main.nf` file to the module's `main.nf` file, making sure to copy over the `#!/usr/bin/env nextflow` shebang too.

```groovy title="hello-modules/modules/local/samtools/index/main.nf" linenums="1"
#!/usr/bin/env nextflow

/*
 * Generate BAM index file
 */
process SAMTOOLS_INDEX {

    container 'community.wave.seqera.io/library/samtools:1.20--b5dfbd93de237464'
    conda "bioconda::samtools=1.20"

    publishDir params.outdir, mode: 'symlink'

    input:
        path input_bam

    output:
        tuple path(input_bam), path("${input_bam}.bai")

    script:
    """
    samtools index '$input_bam'
    """
}
```

Once that is done, delete the process definition from the workflow's `main.nf` file, but make sure to leave the shebang in place.

### 2.4. Add an import declaration before the workflow block

The syntax for importing a local module is fairly straightforward:

```groovy title="Import declaration syntax"
include { <MODULE_NAME> } from './modules/local/<toolkit>>/<tool>/main.nf'
```

Let's insert that above the workflow block and fill it out appropriately.

_Before:_

```groovy title="hello-modules/main.nf" linenums="73"
workflow {
```

_After:_

```groovy title="hello-modules/main.nf" linenums="73"
// Include modules
include { SAMTOOLS_INDEX } from './modules/local/samtools/index/main.nf'

workflow {
```

### 2.5. Run the workflow to verify that it does the same thing as before

We're running the workflow with essentially the same code and inputs as before, so let's add the `-resume` flag and see what happens.

```bash
nextflow run main.nf -profile my_laptop,demo -resume
```

Sure enough, Nextflow recognizes that it's still all the same work to be done, even if the code is split up into multiple files.

```console title="Output"
 N E X T F L O W   ~  version 24.10.0

 ┃ Launching `main.nf` [agitated_cuvier] DSL2 - revision: 0ce0cd0c04

[c3/0d53a4] SAMTOOLS_INDEX (3)       | 3 of 3, cached: 3 ✔
[c6/8c6c30] GATK_HAPLOTYPECALLER (1) | 3 of 3, cached: 3 ✔
[38/82b2e2] GATK_JOINTGENOTYPING     | 1 of 1, cached: 1 ✔
```

So modularizing the code in the course of development does not break resumability!

### Takeaway

You know how to extract a process into a local module.

### What's next?

Practice making more modules.

---

## 3. Repeat procedure for the remaining processes

Once you've done one, you can do a million modules...
But let's just do two more for now.

### 3.1. Create directories to house the code for the two GATK modules

Since GATK_HAPLOTYPECALLER and GATK_JOINTGENOTYPING both run GATK tools, we'll house them both under a shared `gatk` directory.

```bash
mkdir -p modules/local/gatk/haplotypecaller
mkdir -p modules/local/gatk/jointgenotyping
```

You can imagine how it'll be useful to have that optional directory for grouping modules at the toolkit level.

### 3.2. Create file stubs for the process modules

Now let's make the file stubs to put the code into.

```bash
touch modules/local/gatk/haplotypecaller/main.nf
touch modules/local/gatk/jointgenotyping/main.nf
```

### 3.3. Move the process code to the module files

And finally, move the code for each process to the corresponding `main.nf` file, making sure to copy the shebang line too each time.

### 3.3.1. GATK_HAPLOTYPECALLER module

```groovy title="hello-modules/modules/local/gatk/haplotypecaller/main.nf" linenums="1"
#!/usr/bin/env nextflow

/*
 * Call variants with GATK HaplotypeCaller
 */
process GATK_HAPLOTYPECALLER {

    container "community.wave.seqera.io/library/gatk4:4.5.0.0--730ee8817e436867"
    conda "bioconda::gatk4=4.5.0.0"

    publishDir params.outdir, mode: 'symlink'

    input:
        tuple path(input_bam), path(input_bam_index)
        path ref_fasta
        path ref_index
        path ref_dict
        path interval_list

    output:
        path "${input_bam}.g.vcf"     , emit: vcf
        path "${input_bam}.g.vcf.idx" , emit: idx

    script:
    """
    gatk HaplotypeCaller \
        -R ${ref_fasta} \
        -I ${input_bam} \
        -O ${input_bam}.g.vcf \
        -L ${interval_list} \
        -ERC GVCF
    """
}
```

### 3.3.2. GATK_JOINTGENOTYPING module

```groovy title="hello-modules/modules/local/gatk/jointgenotyping/main.nf" linenums="1"
#!/usr/bin/env nextflow

/*
 * Combine GVCFs into GenomicsDB datastore and run joint genotyping to produce cohort-level calls
 */
process GATK_JOINTGENOTYPING {

    container "community.wave.seqera.io/library/gatk4:4.5.0.0--730ee8817e436867"
    conda "bioconda::gatk4=4.5.0.0"

    publishDir params.outdir, mode: 'symlink'

    input:
        path all_gvcfs
        path all_idxs
        path interval_list
        val cohort_name
        path ref_fasta
        path ref_index
        path ref_dict

    output:
        path "${cohort_name}.joint.vcf"     , emit: vcf
        path "${cohort_name}.joint.vcf.idx" , emit: idx

    script:
    def gvcfs_line = all_gvcfs.collect { gvcf -> "-V ${gvcf}" }.join(' ')
    """
    gatk GenomicsDBImport \
        ${gvcfs_line} \
        -L ${interval_list} \
        --genomicsdb-workspace-path ${cohort_name}_gdb

    gatk GenotypeGVCFs \
        -R ${ref_fasta} \
        -V gendb://${cohort_name}_gdb \
        -L ${interval_list} \
        -O ${cohort_name}.joint.vcf
    """
}
```

### 3.4. Add import declarations to the workflow `main.nf` file

Now all that remains is to add the import statements:

_Before:_

```groovy title="hello-modules/main.nf" linenums="3"
// Include modules
include { SAMTOOLS_INDEX } from './modules/local/samtools/index/main.nf'

workflow {
```

_After:_

```groovy title="hello-modules/main.nf" linenums="3"
// Include modules
include { SAMTOOLS_INDEX } from './modules/local/samtools/index/main.nf'
include { GATK_HAPLOTYPECALLER } from './modules/local/gatk/haplotypecaller/main.nf'
include { GATK_JOINTGENOTYPING } from './modules/local/gatk/jointgenotyping/main.nf'

workflow {
```

### 3.5. Run the workflow to verify that everything still works as expected

Look at that short `main.nf` file! Let's run it once last time.

```bash
nextflow run main.nf -profile my_laptop,demo -resume
```

Yep, everything still works, including the resumability of the pipeline.

```console title="Output"
N E X T F L O W ~ version 24.02.0-edge

┃ Launching `main.nf` [tiny_blackwell] DSL2 - revision: 0ce0cd0c04

[62/21cdc5] SAMTOOLS_INDEX (1) | 3 of 3, cached: 3 ✔
[c6/8c6c30] GATK_HAPLOTYPECALLER (2) | 3 of 3, cached: 3 ✔
[38/82b2e2] GATK_JOINTGENOTYPING | 1 of 1, cached: 1 ✔
```

Congratulations, you've done all this work and absolutely nothing has changed to how the pipeline works!

Jokes aside, now your code is more modular, and if you decide to write another pipeline that calls on one of those processes, you just need to type one short import statement to use the relevant module.
This is better than just copy-pasting the code, because if later you decide to improve the module, all your pipelines will inherit the improvements.

### Takeaway

You know how to modularize multiple processes in a workflow.

### What's next?

Learn to add tests to your pipeline using the nf-test framework.
