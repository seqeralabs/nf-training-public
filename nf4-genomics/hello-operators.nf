#!/usr/bin/env nextflow

/*
 * Pipeline parameters
 */

// Primary input (file of input files, one per line)
params.reads_bam = "${projectDir}/data/sample_bams.txt"

// Output directory
params.outdir = "results_genomics"

// Accessory files
params.reference        = "${projectDir}/data/ref/ref.fasta"
params.reference_index  = "${projectDir}/data/ref/ref.fasta.fai"
params.reference_dict   = "${projectDir}/data/ref/ref.dict"
params.intervals        = "${projectDir}/data/ref/intervals.bed"

/*
 * Generate BAM index file
 */
process SAMTOOLS_INDEX {

    container 'community.wave.seqera.io/library/samtools:1.20--b5dfbd93de237464'

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

/*
 * Call variants with GATK HaplotypeCaller
 */
process GATK_HAPLOTYPECALLER {

    container "community.wave.seqera.io/library/gatk4:4.5.0.0--730ee8817e436867"

    publishDir params.outdir, mode: 'symlink'

    input:
        tuple path(input_bam), path(input_bam_index)
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

workflow {

    // Create input channel from a text file listing input file paths
    reads_ch = Channel.fromPath(params.reads_bam).splitText()

    // Load the file paths for the accessory files (reference and intervals)
    ref_file        = file(params.reference)
    ref_index_file  = file(params.reference_index)
    ref_dict_file   = file(params.reference_dict)
    intervals_file  = file(params.intervals)

    // Create index file for input BAM file
    SAMTOOLS_INDEX(reads_ch)

    // Call variants from the indexed BAM file
    GATK_HAPLOTYPECALLER(
        SAMTOOLS_INDEX.out,
        ref_file,
        ref_index_file,
        ref_dict_file,
        intervals_file
    )
}
