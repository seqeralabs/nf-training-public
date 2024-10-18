# Part 2: Hello GATK

The [GATK](https://gatk.broadinstitute.org/) (Genome Analysis Toolkit) is a widely used software package developed by the Broad Institute to analyze high-throughput sequencing data. We're going to use GATK and a related tool, [Samtools](https://www.htslib.org/), in a very basic pipeline that identifies genomic variants through a method called **variant calling**.

![GATK pipeline](img/gatk-pipeline.png)

!!! note

    Don't worry if you're not familiar with GATK or genomics in general. We'll summarize the necessary concepts as we go, and the workflow implementation principles we demonstrate here apply broadly to any command line tool that takes in some input files and produce some output files.

A full variant calling pipeline typically involves a lot of steps. For simplicity, we are only going to look at the core variant calling steps.

### Method overview

1. Generate an index file for each BAM input file using Samtools
2. Run the GATK HaplotypeCaller on each BAM input file to generate per-sample variant calls in GVCF (Genomic Variant Call Format)

<figure class="excalidraw">
--8<-- "docs/hello_nextflow/img/haplotype-caller.excalidraw.svg"
</figure>

### Dataset

-   **A reference genome** consisting of a small region of the human chromosome 20 (from hg19/b37) and its accessory files (index and sequence dictionary).
-   **Three whole genome sequencing samples** corresponding to a family trio (mother, father and son), which have been subset to a small portion on chromosome 20 to keep the file sizes small. The sequencing data is in [BAM](https://samtools.github.io/hts-specs/SAMv1.pdf) (Binary Alignment Map) format, i.e. genome sequencing reads that have already been mapped to the reference genome.
-   **A list of genomic intervals**, i.e. coordinates on the genome where our samples have data suitable for calling variants, provided in BED format.

---

## 0. Warmup: Run Samtools and GATK directly

Just like in the Hello World example, we want to try out the commands manually before we attempt to wrap them in a workflow. The difference here is that we're going to use Docker containers to obtain and run the tools.

!!! note

     Make sure you're in the correct working directory:
     `cd /workspace/gitpod/hello-nextflow`

### 0.1. Index a BAM input file with Samtools

#### 0.1.1. Pull the samtools container

```bash
docker pull community.wave.seqera.io/library/samtools:1.20--b5dfbd93de237464
```

#### 0.1.2. Spin up the container interactively

```bash
docker run -it -v ./data:/data community.wave.seqera.io/library/samtools:1.20--b5dfbd93de237464
```

#### 0.1.3. Run the indexing command

```bash
samtools index /data/bam/reads_mother.bam
```

#### 0.1.4. Check that the BAM index has been produced

```bash
ls /data/bam/
```

This should show:

```console title="Output"
reads_father.bam      reads_mother.bam      reads_mother.bam.bai  reads_son.bam
```

Where `reads_mother.bam.bai` has been created as an index to `reads_mother.bam`.

#### 0.1.5. Exit the container

```bash
exit
```

### 0.2. Call variants with GATK HaplotypeCaller

#### 0.2.1. Pull the GATK container

```bash
docker pull community.wave.seqera.io/library/gatk4:4.5.0.0--730ee8817e436867
```

#### 0.2.2. Spin up the container interactively

```bash
docker run -it -v ./data:/data community.wave.seqera.io/library/gatk4:4.5.0.0--730ee8817e436867
```

#### 0.2.3. Run the variant calling command

```bash
gatk HaplotypeCaller \
        -R /data/ref/ref.fasta \
        -I /data/bam/reads_mother.bam \
        -O reads_mother.g.vcf \
        -L /data/ref/intervals.bed \
        -ERC GVCF
```

#### 0.2.4. Check the contents of the output file

```bash
cat reads_mother.g.vcf
```

#### 0.2.5. Exit the container

```bash
exit
```

---

## 1. Write a single-stage workflow that runs Samtools index on a BAM file

#### 1.1. Define the indexing process

```groovy title="hello-gatk.nf"
/*
 * Generate BAM index file
 */
process SAMTOOLS_INDEX {

    container 'community.wave.seqera.io/library/samtools:1.20--b5dfbd93de237464'

    publishDir 'results', mode: 'copy'

    input:
        path input_bam

    output:
        path "${input_bam}.bai"

    """
    samtools index '$input_bam'
    """
}
```

#### 1.2. Add parameter declarations up top

```groovy title="hello-gatk.nf"
/*
 * Pipeline parameters
 */

// Primary input
params.reads_bam = "${projectDir}/data/bam/reads_mother.bam"
```

#### 1.3. Add workflow block to run SAMTOOLS_INDEX

```groovy title="hello-gatk.nf"
workflow {

    // Create input channel (single file via CLI parameter)
    reads_ch = Channel.fromPath(params.reads_bam)

    // Create index file for input BAM file
    SAMTOOLS_INDEX(reads_ch)
}
```

#### 1.4. Run it to verify you can run the indexing step

```bash
nextflow run hello-gatk.nf
```

Should produce something like:

```console title="Output"
N E X T F L O W  ~  version 24.02.0-edge
Launching `hello-gatk.nf` [compassionate_cray] DSL2 - revision: 9b97744397
executor >  local (1)
[bf/072bd7] process > SAMTOOLS_INDEX (1) [100%] 1 of 1 ✔
```

### Takeaway

You know how to wrap a real bioinformatics tool in a single-step Nextflow workflow.

### What's next?

Add a second step that consumes the output of the first.

---

## 2. Add a second step that runs GATK HaplotypeCaller on the indexed BAM file

#### 2.1. Define the variant calling process

```groovy title="hello-gatk.nf"
/*
 * Call variants with GATK HaplotypeCaller in GVCF mode
 */
process GATK_HAPLOTYPECALLER {

    container "community.wave.seqera.io/library/gatk4:4.5.0.0--730ee8817e436867"

    publishDir 'results', mode: 'copy'

    input:
        path input_bam
        path input_bam_index
        path ref_fasta
        path ref_index
        path ref_dict
        path interval_list

    output:
        path "${input_bam}.g.vcf"
        path "${input_bam}.g.vcf.idx"

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

#### 2.2. Add definitions for accessory inputs

```groovy title="hello-gatk.nf"
// Accessory files
params.reference        = "${projectDir}/data/ref/ref.fasta"
params.reference_index  = "${projectDir}/data/ref/ref.fasta.fai"
params.reference_dict   = "${projectDir}/data/ref/ref.dict"
params.intervals        = "${projectDir}/data/ref/intervals.bed"
```

#### 2.3. Make a value channel for each of the accessory files

Add this to the workflow block (after the `reads_ch` creation):

```groovy title="hello-gatk.nf"
// Create channels for the accessory files (reference and intervals)
ref_file        = file(params.reference)
ref_index_file  = file(params.reference_index)
ref_dict_file   = file(params.reference_dict)
intervals_file  = file(params.intervals)
```

This will load each of the accessory files in its own single-element value channel.

#### 2.4. Add a call to the workflow block to run GATK_HAPLOTYPECALLER

```groovy title="hello-gatk.nf"
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

#### 2.4. Run the workflow to verify that the variant calling step works

```bash
nextflow run hello-gatk.nf -resume
```

Now we see the two processes being run:

```console title="Output"
N E X T F L O W  ~  version 24.02.0-edge
Launching `hello-gatk.nf` [lethal_keller] DSL2 - revision: 30a64b9325
executor >  local (2)
[97/0f85bf] process > SAMTOOLS_INDEX (1)       [100%] 1 of 1 ✔
[2d/43c247] process > GATK_HAPLOTYPECALLER (1) [100%] 1 of 1 ✔
```

If you check the work directory, you'll find the output file `reads_mother.bam.g.vcf`. Because this is a small test file, you can click on it to open it and view the contents, which consist of 92 lines of header metadata followed by a list of genomic variant calls, one per line.

!!! note

    A GVCF is a special kind of VCF that contains non-variant records as well as variant calls. The first actual variant call in this file occurs at line 175:

    ```
    20_10037292_10066351	3480	.	C	CT,<NON_REF>	503.03	.	DP=23;ExcessHet=0.0000;MLEAC=2,0;MLEAF=1.00,0.00;RAW_MQandDP=82800,23	GT:AD:DP:GQ:PL:SB	1/1:0,18,0:18:54:517,54,0,517,54,517:0,0,7,11
    ```

### Takeaway

You know how to make a very basic two-step variant calling workflow.

### What's next?

Make the workflow handle multiple samples in bulk.

---

## 3. Adapt the workflow to run on a batch of samples

#### 3.1. Turn the input parameter declaration into a list of the three samples

_Before:_

```groovy title="hello-gatk.nf"
// Primary input
params.reads_bam = "${projectDir}/data/bam/reads_mother.bam"
```

_After:_

```groovy title="hello-gatk.nf"
// Primary input (list of three samples)
params.reads_bam = [
    "${projectDir}/data/bam/reads_mother.bam",
    "${projectDir}/data/bam/reads_father.bam",
    "${projectDir}/data/bam/reads_son.bam"
]
```

#### 3.2. Run the workflow to verify that it runs on all three samples

```bash
nextflow run hello-gatk.nf -resume
```

Uh-oh! It will probably fail with an error like this:

```console title="Output"
ERROR ~ Error executing process > 'GATK_HAPLOTYPECALLER (2)'

Caused by:
  Process `GATK_HAPLOTYPECALLER (2)` terminated with an error exit status (2)

Command executed:

  gatk HaplotypeCaller         -R ref.fasta         -I reads_father.bam         -O reads_father.bam.g.vcf         -L intervals.bed         -ERC GVCF

Command exit status:
  2

Command error:
```

And buried in the GATK command error output, there will be a line like this:

```
A USER ERROR has occurred: Traversal by intervals was requested but some input files are not indexed.
```

This is because the script as written so far is not safe for running on multiple samples, because the order of items in the output channel is not guaranteed to match the order of items in the original input channel. This causes the wrong files to be paired up in the second step. So we need to make sure the BAM files and their index files travel together through the channels.

#### 3.3. Change the output of the SAMTOOLS_INDEX process into a tuple that keeps the input file and its index together

_Before:_

```groovy title="hello-gatk.nf"
output:
    path "${input_bam}.bai"
```

_After:_

```groovy title="hello-gatk.nf"
output:
    tuple path(input_bam), path("${input_bam}.bai")
```

#### 3.4. Change the input to the GATK_HAPLOTYPECALLER process to be a tuple

_Before:_

```groovy title="hello-gatk.nf"
input:
    path input_bam
    path input_bam_index
```

_After:_

```groovy title="hello-gatk.nf"
input:
    tuple path(input_bam), path(input_bam_index)
```

#### 3.5. Update the call to GATK_HAPLOTYPECALLER in the workflow block

_Before:_

```groovy title="hello-gatk.nf"
GATK_HAPLOTYPECALLER(
    reads_ch,
    SAMTOOLS_INDEX.out,
```

_After:_

```groovy title="hello-gatk.nf"
GATK_HAPLOTYPECALLER(
    SAMTOOLS_INDEX.out,
```

#### 3.6. Run the workflow to verify it works correctly on all three samples now

```bash
nextflow run hello-gatk.nf -ansi-log false
```

This time everything should run correctly:

```console title="Output"
N E X T F L O W  ~  version 24.02.0-edge
Launching `hello-gatk.nf` [adoring_hopper] DSL2 - revision: 8cad21ea51
[e0/bbd6ef] Submitted process > SAMTOOLS_INDEX (3)
[71/d26b2c] Submitted process > SAMTOOLS_INDEX (2)
[e6/6cad6d] Submitted process > SAMTOOLS_INDEX (1)
[26/73dac1] Submitted process > GATK_HAPLOTYPECALLER (1)
[23/12ed10] Submitted process > GATK_HAPLOTYPECALLER (2)
[be/c4a067] Submitted process > GATK_HAPLOTYPECALLER (3)
```

### Takeaway

You know how to make a variant calling workflow run on multiple samples (independently).

### What's next?

Make it easier to handle samples in bulk.

---

## 4. Make it nicer to run on arbitrary samples by using a list of files as input

#### 4.1. Look at the `data/sample_bam.txt` text file, which is listing the input paths

```csv title="sample_bams.txt"
/workspace/gitpod/hello-nextflow/data/bam/reads_mother.bam
/workspace/gitpod/hello-nextflow/data/bam/reads_father.bam
/workspace/gitpod/hello-nextflow/data/bam/reads_son.bam
```

#### 4.2. Update the parameter default

_Before:_

```groovy title="hello-gatk.nf"
// Primary input
params.reads_bam = [
    "${projectDir}/data/bam/reads_mother.bam",
    "${projectDir}/data/bam/reads_father.bam",
    "${projectDir}/data/bam/reads_son.bam"
]
```

_After:_

```groovy title="hello-gatk.nf"
// Primary input (list of input files, one per line)
params.reads_bam = "${projectDir}/data/sample_bams.txt"
```

#### 4.3. Update the channel factory to read lines from a file

_Before:_

```groovy title="hello-gatk.nf"
// Create input channel (single file via CLI parameter)
reads_ch = Channel.fromPath(params.reads_bam)
```

_After:_

```groovy title="hello-gatk.nf"
// Create input channel from list of input files in plain text
reads_ch = Channel.fromPath(params.reads_bam).splitText()
```

#### 4.4. Run the workflow to verify that it works correctly

```bash
nextflow run hello-gatk.nf -resume -ansi-log false
```

This should produce essentially the same result as before:

```console title="Output"
N E X T F L O W  ~  version 24.02.0-edge
Launching `hello-gatk.nf` [backstabbing_raman] DSL2 - revision: 5378632b71
[56/5f8548] Cached process > SAMTOOLS_INDEX (1)
[69/7a0ce1] Cached process > SAMTOOLS_INDEX (3)
[f1/6ae50e] Cached process > SAMTOOLS_INDEX (2)
[49/abf910] Cached process > GATK_HAPLOTYPECALLER (1)
[03/4407cd] Cached process > GATK_HAPLOTYPECALLER (2)
[af/2ea71a] Cached process > GATK_HAPLOTYPECALLER (3)
```

### Takeaway

You know how to make a variant calling workflow handle a file containing input samples.

### What's next?

Add a joint genotyping step that combines the data from all the samples.

---

## 5. Stretch goal: Add joint genotyping step

To complicate matters a little, the GATK variant calling method calls for a consolidation step where we combine and re-analyze the variant calls obtained per sample in order to obtain definitive 'joint' variant calls for a group or _cohort_ of samples (in this case, the family trio).

![Joint analysis](img/joint-calling.png)

This involves using a GATK tool called GenomicsDBImport that combines the per-sample calls into a data store (analogous to a database), followed by another GATK tool, GenotypeGVCFs, which performs the actual 'joint genotyping' analysis. These two tools can be run in series within the same process.

One slight complication is that these tools require the use of individually specified VCF files, and the syntax of the GenomicsDBImport tool looks like this:

```bash title="hello-gatk.nf"
gatk GenomicsDBImport \
    -V sample1.vcf.gz \
    -V sample2.vcf.gz \
    -V sample3.vcf.gz \
    ...
```

So to perform joint genotyping, we will need to collect all VCF files together in a single process and construct a command line for GenomicsDBImport.

#### 5.1. Write a process called GATK_JOINTGENOTYPING that wraps GenomicsDBImport and GenotypeGVCFs

```groovy title="hello-gatk.nf"
/*
 * Consolidate GVCFs and apply joint genotyping analysis
 */
process GATK_JOINTGENOTYPING {

    container "community.wave.seqera.io/library/gatk4:4.5.0.0--730ee8817e436867"

    publishDir 'results', mode: 'copy'

    input:
        path vcfs
        path idxs
        val cohort_name
        path ref_fasta
        path ref_index
        path ref_dict
        path interval_list

    output:
        path "${cohort_name}.joint.vcf"
        path "${cohort_name}.joint.vcf.idx"

    script:
    """
    gatk GenomicsDBImport \
        -V ${vcfs} \
        --genomicsdb-workspace-path ${cohort_name}_gdb \
        -L ${interval_list}

    gatk GenotypeGVCFs \
        -R ${ref_fasta} \
        -V gendb://${cohort_name}_gdb \
        -O ${cohort_name}.joint.vcf \
        -L ${interval_list}
    """
}
```

#### 5.2. Add default value for the cohort name parameter up top

```groovy title="hello-gatk.nf"
// Base name for final output file
params.cohort_name = "family_trio"
```

#### 5.3. Gather the outputs of GATK_HAPLOTYPECALLER across samples using `collect()`

We collect the VCFs and their indices separately in order to list only the VCFs in the command we're going to construct. Since we'll give all of those files together to the joint genotyping process, we don't have to worry about the order of files like we did earlier.

Add this after the call to GATK_HAPLOTYPECALLER:

```groovy title="hello-gatk.nf"
// Collect variant calling outputs across samples
all_vcfs = GATK_HAPLOTYPECALLER.out[0].collect()
all_tbis = GATK_HAPLOTYPECALLER.out[1].collect()
```

!!! tip

    You can view the contents of the channel after performing this collect operation using `.view()`

#### 5.4. Add a call to the workflow block to run GATK_JOINTGENOTYPING

```groovy title="hello-gatk.nf"
// Consolidate GVCFs and apply joint genotyping analysis
GATK_JOINTGENOTYPING(
    all_vcfs,
    all_tbis,
    params.cohort_name,
    ref_file,
    ref_index_file,
    ref_dict_file,
    intervals_file
)
```

#### 5.5. Run the workflow

```bash
nextflow run hello-gatk.nf -resume
```

Oh no! The pipeline produces an error. When we dig into the console output, we can see the command executed isn't correct:

```bash
Command executed:

  gatk GenomicsDBImport -V reads_mother.bam.g.vcf reads_father.bam.g.vcf reads_son.bam.g.vcf --genomicsdb-workspace-path family_trio_gdb -L intervals.bed

  gatk GenotypeGVCFs -R ref.fasta -V gendb://family_trio_gdb -O family_trio.joint.vcf -L intervals.bed
```

Can you spot the error? We gave `gatk GenomicsDBImport` multiple VCF files for a single `-V` argument, but the tool expects a separate `-V` argument for each VCF file.

#### 5.6. Construct a command line with a separate `-V` argument for each input VCF

We use some string manipulations to repeat the VCFs with the argument `-V`, and replace `-V ${vcfs}` with the resulting `${vcfs_line}`:

_Before:_

```groovy title="hello-gatk.nf"
    script:
    """
    gatk GenomicsDBImport \
        -V ${vcfs} \
        --genomicsdb-workspace-path ${cohort_name}_gdb \
        -L ${interval_list}
```

_After:_

```groovy title="hello-gatk.nf"
    script:
    def vcfs_line = vcfs.collect { "-V ${it}" }.join(' ')
    """
    gatk GenomicsDBImport \
        ${vcfs_line} \
        --genomicsdb-workspace-path ${cohort_name}_gdb \
        -L ${interval_list}
```

#### 5.7. Run the workflow to verify that it generates the final VCF output as expected

```bash
nextflow run hello-gatk.nf -resume
```

Now we see the additional process show up in the log output (showing the compact view):

```console title="Output"
N E X T F L O W  ~  version 24.02.0-edge
Launching `hello-gatk.nf` [nauseous_thompson] DSL2 - revision: b346a53aae
executor >  local (7)
[d1/43979a] process > SAMTOOLS_INDEX (2)       [100%] 3 of 3 ✔
[20/247592] process > GATK_HAPLOTYPECALLER (3) [100%] 3 of 3 ✔
[14/7145b6] process > GATK_JOINTGENOTYPING (1) [100%] 1 of 1 ✔
```

You can find the final output file, `family_trio.joint.vcf`, in the work directory for the last process. Click on it to open it and you'll see 40 lines of metadata header followed by just under 30 jointly genotyped variant records (meaning at least one of the family members has a variant genotype at each genomic position listed).

!!! tip

    Keep in mind the data files covered only a tiny portion of chromosome 20; the real size of a variant callset would be counted in millions of variants. That's why we use only tiny subsets of data for training purposes!

### Takeaway

You know how to make a joint variant calling workflow that outputs a cohort VCF.

### What's next?

Celebrate your success and take an extra long break! This was tough and you deserve it.

In future trainings, you'll learn more sophisticated methods for managing inputs and outputs, as well as modularizing your code, testing it, and configuring execution.

**Good luck!**
