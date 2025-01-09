# Part 3: Hello Genomics

In Part 1, you learned how to use the basic building blocks of Nextflow to assemble a simple pipeline capable of processing some text and parallelizing execution if there were multiple inputs.
Then in Part 2, you learned how to use containers to pull in command line tools to test them and integrate them into your pipelines without having to deal with software dependency issues.

Now, we show you how to use the same components and principles to build a pipeline that does something a bit more interesting, and hopefully a bit more relatable to your work.
Specifically, we show you how to implement a simple variant calling pipeline with [GATK](https://gatk.broadinstitute.org/) (Genome Analysis Toolkit), a widely used software package for analyzing high-throughput sequencing data.

!!! note

    Don't worry if you're not familiar with GATK or genomics in general.
    We'll summarize the necessary concepts as we go, and the workflow implementation principles we demonstrate here apply broadly to any command line tool that takes in some input files and produce some output files.

### Method overview

Variant calling is a genomic analysis method that aims to identify variations in a genome sequence relative to a reference genome.
Here we are going to use tools and methods designed for calling short variants, _i.e._ SNPs and indels.

![GATK pipeline](img/gatk-pipeline.png)

A full variant calling pipeline typically involves a lot of steps, including mapping to the reference and variant filtering and prioritization.
For simplicity, we are going to focus on the core variant calling step, which takes as its main input a file of short-read sequencing data in [BAM](https://samtools.github.io/hts-specs/SAMv1.pdf) format (Binary Alignment Map, a compressed version of SAM, Sequence Alignment Map), as well as a reference genome and a list of genomic intervals to analyze.

For this exercise, we provide you with three samples in BAM format (see Dataset below).
However, GATK requires an index file for each BAM file, which we did not provide (on purpose), so the workflow will have to create one as a preliminary step.

!!! note

    Index files are a common feature of bioinformatics file formats; they contain information about the structure of the main file that allows tools like GATK to access a subset of the data without having to read through the whole file.
    This is important because of how big these files can get.

So to recap, we're going to develop a workflow that does the following:

1. Generate an index file for each BAM input file using [Samtools](https://www.htslib.org/)
2. Run the GATK HaplotypeCaller on each BAM input file to generate per-sample variant calls in VCF (Variant Call Format)

<figure class="excalidraw">
--8<-- "docs/hello_nextflow/img/hello-gatk-1.svg"
</figure>

### Dataset

-   **A reference genome** consisting of a small region of the human chromosome 20 (from hg19/b37) and its accessory files (index and sequence dictionary).
-   **Three whole genome sequencing samples** corresponding to a family trio (mother, father and son), which have been subset to a small slice of data on chromosome 20 to keep the file sizes small.
    The sequencing data is in (Binary Alignment Map) format, i.e. genome sequencing reads that have already been mapped to the reference genome.
-   **A list of genomic intervals**, i.e. coordinates on the genome where our samples have data suitable for calling variants, provided in BED format.

---

## 0. Warmup: Test the Samtools and GATK commands interactively

Just like in the Hello World example, we want to try out the commands manually before we attempt to wrap them in a workflow.
The tools we need (Samtools and GATK) are not installed in the Gitpod environment, but that's not a problem since you learned how to work with containers in Part 2 of this training series (Hello Containers).

!!! note

     Make sure you're in the `hello-nextflow` directory so that the last part of the path shown when you type `pwd` is `hello-nextflow`.

### 0.1. Index a BAM input file with Samtools

We're going to pull down a Samtools container, spin it up interactively and run the `samtools index` command on one of the BAM files.

#### 0.1.1. Pull the Samtools container

```bash
docker pull community.wave.seqera.io/library/samtools:1.20--b5dfbd93de237464
```

#### 0.1.2. Spin up the Samtools container interactively

```bash
docker run -it -v ./data:/data community.wave.seqera.io/library/samtools:1.20--b5dfbd93de237464
```

#### 0.1.3. Run the indexing command

The [Samtools documentation](https://www.htslib.org/doc/samtools-index.html) gives us the command line to run to index a BAM file.

We only need to provide the input file; the tool will automatically generate a name for the output by appending `.bai` to the input filename.

```bash
samtools index /data/bam/reads_mother.bam
```

This should complete immediately, and you should now see a file called `reads_mother.bam.bai` in the same directory as the original BAM input file.

```console title="Directory contents"
data/bam/
├── reads_father.bam
├── reads_mother.bam
├── reads_mother.bam.bai
└── reads_son.bam
```

#### 0.1.4. Exit the Samtools container

```bash
exit
```

### 0.2. Call variants with GATK HaplotypeCaller

We're going to pull down a GATK container, spin it up interactively and run the `gatk HaplotypeCaller` command on the BAM file we just indexed.

#### 0.2.1. Pull the GATK container

```bash
docker pull community.wave.seqera.io/library/gatk4:4.5.0.0--730ee8817e436867
```

#### 0.2.2. Spin up the GATK container interactively

```bash
docker run -it -v ./data:/data community.wave.seqera.io/library/gatk4:4.5.0.0--730ee8817e436867
```

#### 0.2.3. Run the variant calling command

The [GATK documentation](https://gatk.broadinstitute.org/hc/en-us/articles/21905025322523-HaplotypeCaller) gives us the command line to run to perform variant calling on a BAM file.

We need to provide the BAM input file (`-I`) as well as the reference genome (`-R`), a name for the output file (`-O`) and a list of genomic intervals to analyze (`-L`).

However, we don't need to specify the path to the index file; the tool will automatically look for it in the same directory, based on the established naming and co-location convention.
The same applies to the reference genome's accessory files (index and sequence dictionary files, `*.fai` and `*.dict`).

```bash
gatk HaplotypeCaller \
        -R /data/ref/ref.fasta \
        -I /data/bam/reads_mother.bam \
        -O reads_mother.vcf \
        -L /data/ref/intervals.bed
```

The output file `reads_mother.vcf` is created inside your working directory in the container, so you won't see it in the Gitpod file explorer unless you change the output file path.
However, it's a small test file, so you can `cat` it to open it and view the contents.
If you scroll all the way up to the start of the file, you'll find a header composed of many lines of metadata, followed by a list of variant calls, one per line.

```console title="reads_mother.vcf" linenums="26"
#CHROM	POS	ID	REF	ALT	QUAL	FILTER	INFO	FORMAT	reads_mother
20_10037292_10066351	3480	.	C	CT	503.03	.	AC=2;AF=1.00;AN=2;DP=23;ExcessHet=0.0000;FS=0.000;MLEAC=2;MLEAF=1.00;MQ=60.00;QD=27.95;SOR=1.179	GT:AD:DP:GQ:PL	1/1:0,18:18:54:517,54,0
20_10037292_10066351	3520	.	AT	A	609.03	.	AC=2;AF=1.00;AN=2;DP=18;ExcessHet=0.0000;FS=0.000;MLEAC=2;MLEAF=1.00;MQ=60.00;QD=33.83;SOR=0.693	GT:AD:DP:GQ:PL	1/1:0,18:18:54:623,54,0
20_10037292_10066351	3529	.	T	A	155.64	.	AC=1;AF=0.500;AN=2;BaseQRankSum=-0.544;DP=21;ExcessHet=0.0000;FS=1.871;MLEAC=1;MLEAF=0.500;MQ=60.00;MQRankSum=0.000;QD=7.78;ReadPosRankSum=-1.158;SOR=1.034	GT:AD:DP:GQ:PL	0/1:12,8:20:99:163,0,328
```

Each line describes a possible variant identified in the sample's sequencing data. For guidance on interpreting VCF format, see [this helpful article](https://www.ebi.ac.uk/training/online/courses/human-genetic-variation-introduction/variant-identification-and-analysis/understanding-vcf-format/).

The output VCF file is accompanied by an index file called `reads_mother.vcf.idx` that was automatically created by GATK.
It has the same function as the BAM index file, to allow tools to seek and retrieve subsets of data without loading in the entire file.

#### 0.2.4. Exit the GATK container

```bash
exit
```

### Takeaway

You know how to test the Samtools indexing and GATK variant calling commands in their respective containers.

### What's next?

Learn how to wrap those same commands into a two-step workflow that uses containers to execute the work.

---

## 1. Write a single-stage workflow that runs Samtools index on a BAM file

We provide you with a workflow file, `hello-genomics.nf`, that outlines the main parts of the workflow.
It's not functional; its purpose is just to serve as a skeleton that you'll use to write the actual workflow.

### 1.1. Define the indexing process

Let's start by writing a process, which we'll call `SAMTOOLS_INDEX`, describing the indexing operation.

```groovy title="hello-genomics.nf" linenums="9"
/*
 * Generate BAM index file
 */
process SAMTOOLS_INDEX {

    container 'community.wave.seqera.io/library/samtools:1.20--b5dfbd93de237464'

    publishDir params.outdir, mode: 'symlink'

    input:
        path input_bam

    output:
        path "${input_bam}.bai"

    script:
    """
    samtools index '$input_bam'
    """
}
```

You should recognize all the pieces from what you learned in Part 1 & Part 2 of this training series; the only notable change is that this time we're using `mode: symlink` for the `publishDir` directive, and we're using a parameter to define the `publishDir`.

!!! note

    Even though the data files we're using here are very small, in genomics they can get very large. For the purposes of demonstration in the teaching environment, we're using the 'symlink' publishing mode to avoid unnecessary file copies. You shouldn't do this in your final workflows, since you'll lose results when you clean up your `work` directory.

This process is going to require us to pass in a file path via the `input_bam` input, so let's set that up next.

### 1.2. Add an input and output parameter declaration

At the top of the file, under the `Pipeline parameters` section, we declare a CLI parameter called `reads_bam` and give it a default value.
That way, we can be lazy and not specify the input when we type the command to launch the pipeline (for development purposes). We're also going to set `params.outdir` with a default value for the output directory.

```groovy title="hello-genomics.nf" linenums="3"
/*
 * Pipeline parameters
 */

// Primary input
params.reads_bam = "${projectDir}/data/bam/reads_mother.bam"
params.outdir    = "results_genomics"
```

Now we have a process ready, as well as a parameter to give it an input to run on, so let's wire those things up together.

!!! note

    `${projectDir}` is a built-in Nextflow variable that points to the directory where the current Nextflow workflow script (`hello-genomics.nf`) is located.

    This makes it easy to reference files, data directories, and other resources included in the workflow repository without hardcoding absolute paths.

### 1.3. Add workflow block to run SAMTOOLS_INDEX

In the `workflow` block, we need to set up a **channel** to feed the input to the `SAMTOOLS_INDEX` process; then we can call the process itself to run on the contents of that channel.

```groovy title="hello-genomics.nf" linenums="30"
workflow {

    // Create input channel (single file via CLI parameter)
    reads_ch = Channel.fromPath(params.reads_bam)

    // Create index file for input BAM file
    SAMTOOLS_INDEX(reads_ch)
}
```

You'll notice we're using the same `.fromPath` channel factory as we used at the end of Part 1 (Hello World) of this training series.
Indeed, we're doing something very similar.
The difference is that this time we're telling Nextflow to load the file path itself into the channel as an input element, rather than reading in its contents.

### 1.4. Run the workflow to verify that the indexing step works

Let's run the workflow! As a reminder, we don't need to specify an input in the command line because we set up a default value for the input when we declared the input parameter.

```bash
nextflow run hello-genomics.nf
```

The command should produce something like this:

```console title="Output"
 N E X T F L O W   ~  version 24.10.0

 ┃ Launching `hello-genomics.nf` [reverent_sinoussi] DSL2 - revision: 41d43ad7fe

executor >  local (1)
[2a/e69536] SAMTOOLS_INDEX (1) | 1 of 1 ✔
```

You can check that the index file has been generated correctly by looking in the work directory or in the directory set up with `publishDir`.

```console title="Directory contents"
work/2a/e695367b2f60df09cf826b07192dc3
├── reads_mother.bam -> /workspace/gitpod/hello-nextflow/data/bam/reads_mother.bam
└── reads_mother.bam.bai
```

```console title="Directory contents"
results_genomics/
└── reads_mother.bam.bai
```

There it is!

### Takeaway

You know how to wrap a real bioinformatics tool in a single-step Nextflow workflow and have it run using a container.

### What's next?

Add a second step that consumes the output of the first.

---

## 2. Add a second process to run GATK HaplotypeCaller on the indexed BAM file

Now that we have an index for our input file, we can move on to setting up the variant calling step, which is the interesting part of the workflow.

### 2.1. Define the variant calling process

Let's write a process, which we'll call `GATK_HAPLOTYPECALLER`, describing the variant calling operation.

```groovy title="hello-genomics.nf" linenums="30"
/*
 * Call variants with GATK HaplotypeCaller
 */
process GATK_HAPLOTYPECALLER {

    container "community.wave.seqera.io/library/gatk4:4.5.0.0--730ee8817e436867"

    publishDir params.outdir, mode: 'symlink'

    input:
        path input_bam
        path input_bam_index
        path ref_fasta
        path ref_index
        path ref_dict
        path interval_list

    output:
        path "${input_bam}.vcf"     , emit: vcf
        path "${input_bam}.vcf.idx" , emit: idx

    script:
    """
    gatk HaplotypeCaller \
        -R ${ref_fasta} \
        -I ${input_bam} \
        -O ${input_bam}.vcf \
        -L ${interval_list}
    """
}
```

You'll notice that we've introduced some new syntax here (`emit:`) to uniquely name each of our output channels, and the reasons for this will become clear soon.

This command takes quite a few more inputs, because GATK needs more information to perform the analysis compared to a simple indexing job.
But you'll note that there are even more inputs defined in the inputs block than are listed in the GATK command. Why is that?

!!! note

    The GATK knows to look for the BAM index file and the reference genome's accessory files because it is aware of the conventions surrounding those files.
    However, Nextflow is designed to be domain-agnostic and doesn't know anything about bioinformatics file format requirements.

We need to tell Nextflow explicitly that it has to stage those files in the working directory at runtime; otherwise it won't do it, and GATK will (correctly) throw an error about the index files being missing.

Similarly, we have to list the output VCF's index file (the `"${input_bam}.vcf.idx"` file) explicitly so that Nextflow will know to keep track of that file in case it's needed in subsequent steps.

### 2.2. Add definitions for accessory inputs

Since our new process expects a handful of additional files to be provided, we set up some CLI parameters for them under the `Pipeline parameters` section, along with some default values (same reasons as before).

```groovy title="hello-genomics.nf" linenums="10"
// Accessory files
params.reference        = "${projectDir}/data/ref/ref.fasta"
params.reference_index  = "${projectDir}/data/ref/ref.fasta.fai"
params.reference_dict   = "${projectDir}/data/ref/ref.dict"
params.intervals        = "${projectDir}/data/ref/intervals.bed"
```

### 2.3. Create variables to hold the accessory file paths

While main data inputs are streamed dynamically through channels, there are two approaches for handling accessory files. The recommended approach is to create explicit channels, which makes data flow clearer and more consistent. Alternatively, the file() function to create variables can be used for simpler cases, particularly when you need to reference the same file in multiple processes - though be aware this still creates channels implicitly.

Add this to the workflow block (after the `reads_ch` creation):

```groovy title="hello-genomics.nf" linenums="71"
// Load the file paths for the accessory files (reference and intervals)
ref_file        = file(params.reference)
ref_index_file  = file(params.reference_index)
ref_dict_file   = file(params.reference_dict)
intervals_file  = file(params.intervals)
```

This will make the accessory file paths available for providing as input to any processes that need them.

### 2.4. Add a call to the workflow block to run GATK_HAPLOTYPECALLER

Now that we've got our second process set up and all the inputs and accessory files are ready and available, we can add a call to the `GATK_HAPLOTYPECALLER` process in the workflow body.

```groovy title="hello-genomics.nf" linenums="80"
// Call variants from the indexed BAM file
GATK_HAPLOTYPECALLER(
    reads_ch,
    SAMTOOLS_INDEX.out,
    ref_file,
    ref_index_file,
    ref_dict_file,
    intervals_file
)
```

You should recognize the `*.out` syntax from Part 1 of this training series; we are telling Nextflow to take the channel output by `SAMTOOLS_INDEX` and plugging that into the `GATK_HAPLOTYPECALLER` process call.

!!! note

    You'll notice that the inputs are provided in the exact same order in the call to the process as they are listed in the input block of the process.
    In Nextflow, inputs are positional, meaning you _must_ follow the same order; and of course there have to be the same number of elements.

### 2.5. Run the workflow to verify that the variant calling step works

Let's run the expanded workflow with `-resume` so that we don't have to run the indexing step again.

```bash
nextflow run hello-genomics.nf -resume
```

Now if we look at the console output, we see the two processes listed:

```console title="Output"
 N E X T F L O W   ~  version 24.10.0

 ┃ Launching `hello-genomics.nf` [grave_volta] DSL2 - revision: 4790abc96a

executor >  local (1)
[2a/e69536] SAMTOOLS_INDEX (1)       | 1 of 1, cached: 1 ✔
[53/e18e98] GATK_HAPLOTYPECALLER (1) | 1 of 1 ✔
```

The first process was skipped thanks to the caching, as expected, whereas the second process was run since it's brand new.

You'll find the output file `reads_mother.bam.vcf` in the results directory, as well its index file (`*.vcf.idx`). Both are symbolic links to the original files in the work directory where the process call was executed.

```console title="Directory contents"
results_genomics/
├── reads_mother.bam.bai
├── reads_mother.bam.vcf -> /workspace/gitpod/hello-nextflow/work/53/e18e987d56c47f59b7dd268649ec01/reads_mother.bam.vcf
└── reads_mother.bam.vcf.idx -> /workspace/gitpod/hello-nextflow/work/53/e18e987d56c47f59b7dd268649ec01/reads_mother.bam.vcf.idx
```

If you open the VCF file, you should see the same contents as in the file you generated by running the GATK command directly in the container.

```console title="reads_mother.bam.vcf" linenums="26"
#CHROM	POS	ID	REF	ALT	QUAL	FILTER	INFO	FORMAT	reads_mother
20_10037292_10066351	3480	.	C	CT	503.03	.	AC=2;AF=1.00;AN=2;DP=23;ExcessHet=0.0000;FS=0.000;MLEAC=2;MLEAF=1.00;MQ=60.00;QD=27.95;SOR=1.179	GT:AD:DP:GQ:PL	1/1:0,18:18:54:517,54,0
20_10037292_10066351	3520	.	AT	A	609.03	.	AC=2;AF=1.00;AN=2;DP=18;ExcessHet=0.0000;FS=0.000;MLEAC=2;MLEAF=1.00;MQ=60.00;QD=33.83;SOR=0.693	GT:AD:DP:GQ:PL	1/1:0,18:18:54:623,54,0
20_10037292_10066351	3529	.	T	A	155.64	.	AC=1;AF=0.500;AN=2;BaseQRankSum=-0.544;DP=21;ExcessHet=0.0000;FS=1.871;MLEAC=1;MLEAF=0.500;MQ=60.00;MQRankSum=0.000;QD=7.78;ReadPosRankSum=-1.158;SOR=1.034	GT:AD:DP:GQ:PL	0/1:12,8:20:99:163,0,328
```

This is the output we care about generating for each sample in our study.

### Takeaway

You know how to make a very basic two-step workflow that does real analysis work and is capable of dealing with bioinformatics idiosyncrasies like the accessory files.

### What's next?

Make the workflow handle multiple samples in bulk.

---

## 3. Adapt the workflow to run on a batch of samples

It's all well and good to have a workflow that can automate processing on a single sample, but what if you have 1000 samples?
Do you need to write a bash script that loops through all your samples?

No, thank goodness! Just make a minor tweak to the code and Nextflow will handle that for you too.

### 3.1. Turn the input parameter declaration into an array listing the three samples

Let's turn that default file path in the input BAM file declaration into an array listing file paths for our three test samples, up under the `Pipeline parameters` section.

_Before:_

```groovy title="hello-genomics.nf" linenums="7"
// Primary input
params.reads_bam = "${projectDir}/data/bam/reads_mother.bam"
```

_After:_

```groovy title="hello-genomics.nf" linenums="7"
// Primary input (array of three samples)
params.reads_bam = [
    "${projectDir}/data/bam/reads_mother.bam",
    "${projectDir}/data/bam/reads_father.bam",
    "${projectDir}/data/bam/reads_son.bam"
]
```

And that's actually all we need to do, because the channel factory we use in the workflow body (`.fromPath`) is just as happy to accept multiple file paths to load into the input channel as it was to load a single one.

!!! note

    Normally, you wouldn't want to hardcode the list of samples into your workflow file, but we're doing that here to keep things simple.
    We'll present more elegant ways for handling inputs later in this training series.

### 3.2. Run the workflow to verify that it runs on all three samples

Let's try running the workflow now that the plumbing is set up to run on all three test samples.

```bash
nextflow run hello-genomics.nf -resume
```

Funny thing: this _might work_, OR it _might fail_.
If your workflow run succeeded, run it again until you get an error like this:

```console title="Output"
 N E X T F L O W   ~  version 24.10.0

 ┃ Launching `hello-genomics.nf` [loving_pasteur] DSL2 - revision: d2a8e63076

executor >  local (4)
[01/eea165] SAMTOOLS_INDEX (2)       | 3 of 3, cached: 1 ✔
[a5/fa9fd0] GATK_HAPLOTYPECALLER (3) | 1 of 3, cached: 1
ERROR ~ Error executing process > 'GATK_HAPLOTYPECALLER (2)'

Caused by:
  Process `GATK_HAPLOTYPECALLER (2)` terminated with an error exit status (2)

Command executed:

  gatk HaplotypeCaller         -R ref.fasta         -I reads_father.bam         -O reads_father.bam.vcf         -L intervals.bed         -ERC GVCF

Command exit status:
  2

Command error:
```

Further down, buried in the GATK command error output, there will be a line like this:

```console title="Output"
A USER ERROR has occurred: Traversal by intervals was requested but some input files are not indexed.
```

Well, that's weird, considering we explicitly indexed the BAM files in the first step of the workflow. Could there be something wrong with the plumbing?

#### 3.2.1. Check the work directories for the relevant calls

Let's take a look inside the work directory for the failed `GATK_HAPLOTYPECALLER` process call listed in the console output.

```console title="Directory contents"
work/a5/fa9fd0994b6beede5fb9ea073596c2
├── intervals.bed -> /workspace/gitpod/hello-nextflow/data/ref/intervals.bed
├── reads_father.bam.bai -> /workspace/gitpod/hello-nextflow/work/01/eea16597bd6e810fb4cf89e60f8c2d/reads_father.bam.bai
├── reads_son.bam -> /workspace/gitpod/hello-nextflow/data/bam/reads_son.bam
├── reads_son.bam.vcf
├── reads_son.bam.vcf.idx
├── ref.dict -> /workspace/gitpod/hello-nextflow/data/ref/ref.dict
├── ref.fasta -> /workspace/gitpod/hello-nextflow/data/ref/ref.fasta
└── ref.fasta.fai -> /workspace/gitpod/hello-nextflow/data/ref/ref.fasta.fai
```

Pay particular attention to the names of the BAM file and the BAM index that are listed in this directory: `reads_son.bam` and `reads_father.bam.bai`.

What the heck? Nextflow has staged an index file in this process call's work directory, but it's the wrong one. How could this have happened?

#### 3.2.1. Use the [view() operator](https://www.nextflow.io/docs/latest/reference/operator.html#view) to inspect channel contents

Add these two lines in the workflow body before the `GATK_HAPLOTYPER` process call:

```groovy title="hello-genomics.nf" linenums="84"
    // temporary diagnostics
    reads_ch.view()
    SAMTOOLS_INDEX.out.view()
```

Then run the workflow command again.

```bash
nextflow run hello-genomics.nf
```

You may need to run it several times for it to fail again.
This error will not reproduce consistently because it is dependent on some variability in the execution times of the individual process calls.

This is what the output of the two `.view()` calls we added looks like for a failed run:

```console title="Output"
/workspace/gitpod/hello-nextflow/data/bam/reads_mother.bam
/workspace/gitpod/hello-nextflow/data/bam/reads_father.bam
/workspace/gitpod/hello-nextflow/data/bam/reads_son.bam
/workspace/gitpod/hello-nextflow/work/9c/53492e3518447b75363e1cd951be4b/reads_father.bam.bai
/workspace/gitpod/hello-nextflow/work/cc/37894fffdf6cc84c3b0b47f9b536b7/reads_son.bam.bai
/workspace/gitpod/hello-nextflow/work/4d/dff681a3d137ba7d9866e3d9307bd0/reads_mother.bam.bai
```

The first three lines correspond to the input channel and the second, to the output channel.
You can see that the BAM files and index files for the three samples are not listed in the same order!

!!! note

    When you call a Nextflow process on a channel containing multiple elements, Nextflow will try to parallelize execution as much as possible, and will collect outputs in whatever order they become available.
    The consequence is that the corresponding outputs may be collected in a different order than the original inputs were fed in.

As currently written, our workflow script assumes that the index files will come out of the indexing step listed in the same mother/father/son order as the inputs were given.
But that is not guaranteed to be the case, which is why sometimes (though not always) the wrong files get paired up in the second step.

To fix this, we need to make sure the BAM files and their index files travel together through the channels.

!!! tip

    The `view()` statements in the workflow code don't do anything, so it's not a problem to leave them in.
    However they will clutter up your console output, so we recommend removing them when you're done troubleshooting the issue.

### 3.3. Change the output of the SAMTOOLS_INDEX process into a tuple that keeps the input file and its index together

The simplest way to ensure a BAM file and its index stay closely associated is to package them together into a tuple coming out of the index task.

!!! note

    A **tuple** is a finite, ordered list of elements that is commonly used for returning multiple values from a function. Tuples are particularly useful for passing multiple inputs or outputs between processes while preserving their association and order.

First, let's change the output of the `SAMTOOLS_INDEX` process to include the BAM file in its output declaration.

_Before:_

```groovy title="hello-genomics.nf" linenums="32"
output:
    path "${input_bam}.bai"
```

_After:_

```groovy title="hello-genomics.nf" linenums="32"
output:
    tuple path(input_bam), path("${input_bam}.bai")
```

This way, each index file will be tightly coupled with its original BAM file, and the overall output of the indexing step will be a single channel containing pairs of files.

### 3.4. Change the input to the GATK_HAPLOTYPECALLER process to be a tuple

Since we've changed the 'shape' of the output of the first process in the workflow, we need to update the input definition of the second process to match.

Specifically, where we previously declared two separate input paths in the input block of the `GATK_HAPLOTYPECALLER` process, we now declare a single input matching the structure of the tuple emitted by `SAMTOOLS_INDEX`.

_Before:_

```groovy title="hello-genomics.nf" linenums="49"
input:
    path input_bam
    path input_bam_index
```

_After:_

```groovy title="hello-genomics.nf" linenums="49"
input:
    tuple path(input_bam), path(input_bam_index)
```

Of course, since we've now changed the shape of the inputs that `GATK_HAPLOTYPECALLER` expects, we need to update the process call accordingly in the workflow body.

### 3.5. Update the call to GATK_HAPLOTYPECALLER in the workflow block

We no longer need to provide the original `reads_ch` to the `GATK_HAPLOTYPECALLER` process, since the BAM file is now bundled (in the form of a symlink) into the channel output by `SAMTOOLS_INDEX`.

As a result, we can simply delete that line.

_Before:_

```groovy title="hello-genomics.nf" linenums="84"
GATK_HAPLOTYPECALLER(
    reads_ch,
    SAMTOOLS_INDEX.out,
```

_After:_

```groovy title="hello-genomics.nf" linenums="84"
GATK_HAPLOTYPECALLER(
    SAMTOOLS_INDEX.out,
```

That is all the re-wiring that is necessary to solve the index mismatch problem.

### 3.6. Run the workflow to verify it works correctly on all three samples every time

Of course, the proof is in the pudding, so let's run the workflow again a few times to make sure this will work reliably going forward.

```bash
nextflow run hello-genomics.nf
```

This time (and every time) everything should run correctly:

```console title="Output"
 N E X T F L O W   ~  version 24.10.0

 ┃ Launching `hello-genomics.nf` [special_goldstine] DSL2 - revision: 4cbbf6ea3e

executor >  local (6)
[d6/10c2c4] SAMTOOLS_INDEX (1)       | 3 of 3 ✔
[88/1783aa] GATK_HAPLOTYPECALLER (2) | 3 of 3 ✔
```

If you'd like, you can use `.view()` again to peek at what the contents of the `SAMTOOLS_INDEX` output channel looks like:

```groovy title="hello-genomics.nf" linenums="92"
SAMTOOLS_INDEX.out.view()
```

You'll see the channel contains the three expected tuples (file paths truncated for readability).

```console title="Output"
[.../4c/e16099*/reads_son.bam, .../4c/e16099*/reads_son.bam.bai]
[.../42/e70b8b*/reads_father.bam, .../42/e70b8b*/reads_father.bam.bai]
[.../18/23b4bb*/reads_mother.bam, .../18/23b4bb*/reads_mother.bam.bai]
```

That will be much safer, going forward.

### Takeaway

You know how to make your workflow run on multiple samples (independently).

### What's next?

Make it easier to handle samples in bulk.

---

## 4. Make the workflow accept a text file containing a batch of input files

A very common way to provide multiple data input files to a workflow is to do it with a text file containing the file paths.
It can be as simple as a text file listing one file path per line and nothing else, or the file can contain additional metadata, in which case it's often called a samplesheet.

Here we are going to show you how to do the simple case.

### 4.1. Examine the provided text file listing the input file paths

We already made a text file listing the input file paths, called `sample_bams.txt`, which you can find in the `data/` directory.

```txt title="sample_bams.txt"
/workspace/gitpod/hello-nextflow/data/bam/reads_mother.bam
/workspace/gitpod/hello-nextflow/data/bam/reads_father.bam
/workspace/gitpod/hello-nextflow/data/bam/reads_son.bam
```

As you can see, we listed one file path per line, and they are absolute paths.

!!! note

    The files we are using here are just on your Gitpod's local filesystem, but we could also point to files in cloud storage.

### 4.2. Update the parameter default

Let's switch the default value for our `reads_bam` input parameter to point to the `sample_bams.txt` file.

_Before:_

```groovy title="hello-genomics.nf" linenums="7"
// Primary input
params.reads_bam = [
    "${projectDir}/data/bam/reads_mother.bam",
    "${projectDir}/data/bam/reads_father.bam",
    "${projectDir}/data/bam/reads_son.bam"
]
```

_After:_

```groovy title="hello-genomics.nf" linenums="7"
// Primary input (file of input files, one per line)
params.reads_bam = "${projectDir}/data/sample_bams.txt"
```

This way we can continue to be lazy, but the list of files no longer lives in the workflow code itself, which is a big step in the right direction.

### 4.3. Update the channel factory to read lines from a file

Currently, our input channel factory treats any files we give it as the data inputs we want to feed to the indexing process.
Since we're now giving it a file that lists input file paths, we need to change its behavior to parse the file and treat the file paths it contains as the data inputs.

Fortunately we can do that very simply, just by adding the [`.splitText()` operator](https://www.nextflow.io/docs/latest/reference/operator.html#operator-splittext) to the channel construction step.

_Before:_

```groovy title="hello-genomics.nf" linenums="68"
// Create input channel (single file via CLI parameter)
reads_ch = Channel.fromPath(params.reads_bam)
```

_After:_

```groovy title="hello-genomics.nf" linenums="68"
// Create input channel from a text file listing input file paths
reads_ch = Channel.fromPath(params.reads_bam).splitText()
```

!!! tip

    This is another great opportunity to use the `.view()` operator to look at what the channel contents look like before and after applying an operator.

### 4.4. Run the workflow to verify that it works correctly

Let's run the workflow one more time.

```bash
nextflow run hello-genomics.nf -resume
```

This should produce the same result as before, right?

```console title="Output"
 N E X T F L O W   ~  version 24.10.0

 ┃ Launching `hello-genomics.nf` [sick_albattani] DSL2 - revision: 46d84642f6

[18/23b4bb] SAMTOOLS_INDEX (1)       | 3 of 3, cached: 3 ✔
[12/f727bb] GATK_HAPLOTYPECALLER (3) | 3 of 3, cached: 3 ✔
```

Yes! In fact, Nextflow correctly detects that the process calls are exactly the same, and doesn't even bother re-running everything, since we were running with `-resume`.

And that's it! Our simple variant calling workflow has all the basic features we wanted.

### Takeaway

You know how to make a multi-step linear workflow handle a file containing input file paths.

More generally, you've learned how to use essential Nextflow components and logic to build a pipeline that does real work, taking into account the idiosyncrasies of bioinformatics file formats and tool requirements.

### What's next?

Celebrate your success and take an extra long break!

In the next training module, you'll learn how to use a few additional Nextflow features (including more channel operators) to develop pipelines with more complex plumbing.
