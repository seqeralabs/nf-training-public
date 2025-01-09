# Workflow Description

The aim of the pipeline is to process raw RNA-seq data (in FASTQ format) and obtain the list of small variants, SNVs (SNPs and INDELs) for the downstream analysis. The pipeline is based on the [GATK best practices for variant calling with RNAseq data](https://software.broadinstitute.org/gatk/guide/article?id=3891) and includes all major steps. In addition the pipeline includes SNVs postprocessing and quantification for allele specific expression.

Samples processing is done **independently** for **each replicate**. This includes mapping of the reads, splitting at the CIGAR, reassigning mapping qualities and recalibrating base qualities.

Variant calling is done **simultaneously** on bam files from **all replicates**. This allows to improve coverage of genomic regions and obtain more reliable results.

## Software manuals

Documentation for all software used in the workflow can be found at the following links:

-   [samtools](http://www.htslib.org/doc/samtools.html)
-   [picard `CreateSequenceDictionary`](https://broadinstitute.github.io/picard/command-line-overview.html#CreateSequenceDictionary)
-   [STAR](http://labshare.cshl.edu/shares/gingeraslab/www-data/dobin/STAR/STAR.posix/doc/STARmanual.pdf)
-   [vcftools](https://vcftools.github.io/man_latest.html)
-   [GATK tools](https://software.broadinstitute.org/gatk/gatkdocs/3.6-0/index)
    -   [`SplitNCigarReads`](https://software.broadinstitute.org/gatk/gatkdocs/3.6-0/org_broadinstitute_gatk_tools_walkers_rnaseq_SplitNCigarReads.php)
    -   [`BaseRecalibrator`](https://software.broadinstitute.org/gatk/gatkdocs/3.6-0/org_broadinstitute_gatk_tools_walkers_bqsr_BaseRecalibrator.php)
    -   [`PrintReads`](https://software.broadinstitute.org/gatk/gatkdocs/3.6-0/org_broadinstitute_gatk_tools_walkers_readutils_PrintReads.php)
    -   [`HaplotypeCaller`](https://software.broadinstitute.org/gatk/gatkdocs/3.6-0/org_broadinstitute_gatk_tools_walkers_haplotypecaller_HaplotypeCaller.php)
    -   [`VariantFiltration`](https://software.broadinstitute.org/gatk/gatkdocs/3.6-0/org_broadinstitute_gatk_tools_walkers_filters_VariantFiltration.php)
    -   [`ASEReadCounter`](https://software.broadinstitute.org/gatk/gatkdocs/3.6-0/org_broadinstitute_gatk_tools_walkers_rnaseq_ASEReadCounter.php)

## Pipeline steps

In order to get a general idea of the workflow, all the composing steps, together with the corresponding commands, are explained in the next sections.

### Preparing data

This step prepares input files for the analysis. Genome indexes are created and variants overlapping blacklisted regions are filtered out.

Genome indices with `samtools` and `picard` are produced first. They will be needed for GATK commands such as `Split'N'Trim`:

```bash
samtools faidx genome.fa
picard CreateSequenceDictionary R= genome.fa O= genome.dict
```

Genome index for `STAR`, needed for RNA-seq reads mappings, is created next. Index files are written to the folder `genome_dir` :

```bash
STAR --runMode genomeGenerate \
     --genomeDir genome_dir \
     --genomeFastaFiles genome.fa \
     --runThreadN 4
```

Variants overlapping blacklisted regions are then filtered in order to reduce false positive calls \[optional\]:

```bash
vcftools --gzvcf known_variants.vcf.gz -c \
         --exclude-bed blacklist.bed \
         --recode | bgzip -c \
         > known_variants.filtered.recode.vcf.gz
```

### Mapping RNA-seq reads to the reference

To align RNA-seq reads to the genome we’re using STAR 2-pass approach. The first alignment creates a table with splice-junctions that is used to guide final alignments. The alignments at both steps are done with default parameters.

Additional fields with the read groups, libraries and sample information are added into the final bam file at the second mapping step. As a result we do not need to run Picard processing step from GATK best practices.

STAR 1-pass:

```bash
STAR --genomeDir genome_dir \
     --readFilesIn ENCSR000COQ1_1.fastq.gz ENCSR000COQ1_2.fastq.gz \
     --runThreadN 4 \
     --readFilesCommand zcat \
     --outFilterType BySJout \
     --alignSJoverhangMin 8 \
     --alignSJDBoverhangMin 1 \
     --outFilterMismatchNmax 999
```

Create new genome index using splice-junction table:

```bash
STAR --runMode genomeGenerate \
     --genomeDir genome_dir \
     --genomeFastaFiles genome.fa \
     --sjdbFileChrStartEnd SJ.out.tab \
     --sjdbOverhang 75 \
     --runThreadN 4
```

STAR 2-pass, final alignments:

```bash
STAR --genomeDir genome_dir \
     --readFilesIn ENCSR000COQ1_1.fastq.gz ENCSR000COQ1_2.fastq.gz \
     --runThreadN 4 \
     --readFilesCommand zcat \
     --outFilterType BySJout \
     --alignSJoverhangMin 8 \
     --alignSJDBoverhangMin 1 \
     --outFilterMismatchNmax 999 \
     --outSAMtype BAM SortedByCoordinate \
     --outSAMattrRGline ID:ENCSR000COQ1 LB:library PL:illumina PU:machine SM:GM12878
```

Index the resulting bam file:

```bash
samtools index final_alignments.bam
```

### Split’N'Trim and reassign mapping qualities

The RNA-seq reads overlapping exon-intron junctions can produce false positive variants due to inaccurate splicing. To solve this problem the GATK team recommend to hard-clip any sequence that overlap intronic regions and developed a special tool for this purpose: `SplitNCigarReads`. The tool identifies Ns in the CIGAR string of the alignment and split reads at this position so that few new reads are created.

At this step we also reassign mapping qualities to the alignments. This is important because STAR assign the value `255` (high quality) to “unknown” mappings that are meaningless to GATK and to variant calling in general.

This step is done with recommended parameters from the GATK best practices.

```bash
java -jar /usr/gitc/GATK35.jar -T SplitNCigarReads \
                               -R genome.fa -I final_alignments.bam \
                               -o split.bam \
                               -rf ReassignOneMappingQuality \
                               -RMQF 255 -RMQT 60 \
                               -U ALLOW_N_CIGAR_READS \
                               --fix_misencoded_quality_scores
```

### Base Recalibration

The proposed workflow does not include an indel re-alignment step, which is an optional step in the GATK best practices. We excluded that since it is quite time-intensive and does not really improve variant calling.

We instead include a base re-calibration step. This step allows to remove possible systematic errors introduced by the sequencing machine during the assignment of read qualities. To do this, the list of known variants is used as a training set to the machine learning algorithm that models possible errors. Base quality scores are then adjusted based on the obtained results.

```bash
gatk3 -T BaseRecalibrator \
      --default_platform illumina \
      -cov ReadGroupCovariate \
      -cov QualityScoreCovariate \
      -cov CycleCovariate \
      -knownSites known_variants.filtered.recode.vcf.gz\
      -cov ContextCovariate \
      -R genome.fa -I split.bam \
      --downsampling_type NONE \
      -nct 4 \
      -o final.rnaseq.grp
```

```bash
gatk3 -T PrintReads \
      -R genome.fa -I split.bam \
      -BQSR final.rnaseq.grp \
      -nct 4 \
      -o final.bam
```

### Variant Calling and Variant filtering

The variant calling is done on the uniquely aligned reads only in order to reduce the number of false positive variants called:

```bash
(samtools view -H final.bam; samtools view final.bam| grep -w 'NH:i:1') \
    | samtools view -Sb -  > final.uniq.bam
```

```bash
samtools index final.uniq.bam
```

For variant calling we’re using the GATK tool `HaplotypeCaller` with default parameters:

```bash
ls final.uniq.bam  > bam.list
java -jar /usr/gitc/GATK35.jar -T HaplotypeCaller \
                               -R genome.fa -I bam.list \
                               -dontUseSoftClippedBases \
                               -stand_call_conf 20.0 \
                               -o output.gatk.vcf.gz
```

Variant filtering is done as recommended in the GATK best practices:

-   keep clusters of at least 3 SNPs that are within a window of 35 bases between them
-   estimate strand bias using Fisher’s Exact Test with values > 30.0 (Phred-scaled p-value)
-   use variant call confidence score `QualByDepth` (QD) with values < 2.0. The QD is the QUAL score normalized by allele depth (AD) for a variant.

```bash
java -jar /usr/gitc/GATK35.jar -T VariantFiltration \
                               -R genome.fa -V output.gatk.vcf.gz \
                               -window 35 -cluster 3 \
                               -filterName FS -filter "FS > 30.0" \
                               -filterName QD -filter "QD < 2.0" \
                               -o final.vcf
```

### Variant Post-processing

For downstream analysis we’re considering only sites that pass all filters and are covered with at least 8 reads:

```bash
grep -v '#' final.vcf \
    | awk '$7~/PASS/' \
    | perl -ne 'chomp($_); ($dp)=$_=~/DP\\=(\\d+)\\;/; if($dp>=8){print $_."\\n"};' \
    > result.DP8.vcf
```

Filtered RNA-seq variants are compared with those obtained from DNA sequencing (from Illumina platinum genome project). Variants that are common to these two datasets are "known" SNVs. The ones present only in the RNA-seq cohort only are "novel".

!!! note

    **Known SNVs** will be used for **allele specific expression** analysis.

    **Novel variants** will be used to detect **RNA-editing events**.

We compare two variants files to detect common and different sites:

```bash
vcftools --vcf result.DP8.vcf --gzdiff known_SNVs.filtered.recode.vcf.gz --diff-site --out commonSNPs
```

Here we select sites present in both files ("known" SNVs only):

```bash
awk 'BEGIN{OFS="\t"} $4~/B/{print $1,$2,$3}' commonSNPs.diff.sites_in_files  > test.bed
```

```bash
vcftools --vcf final.vcf --bed test.bed --recode --keep-INFO-all --stdout > known_snps.vcf
```

Plot a histogram with allele frequency distribution for "known" SNVs:

```bash
grep -v '#'  known_snps.vcf \
    | awk -F '\\t' '{print $10}' \
    | awk -F ':' '{print $2}'\
    | perl -ne 'chomp($_); \
    @v=split(/\\,/,$_); if($v[0]!=0 ||$v[1] !=0) \
    {print  $v[1]/($v[1]+$v[0])."\\n"; }' \
    | awk '$1!=1' \
    > AF.4R

gghist.R -i AF.4R -o AF.histogram.pdf
```

Calculate read counts for each "known" SNVs per allele for allele specific expression analysis:

```bash
java -jar /usr/gitc/GATK35.jar \
     -R genome.fa \
     -T ASEReadCounter \
     -o ASE.tsv \
     -I bam.list \
     -sites known_snps.vcf
```
