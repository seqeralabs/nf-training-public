#!/usr/bin/env nextflow

/*
 * Pipeline parameters
 */

// Primary input (file of input files, one per line)
params.reads_bam = "${projectDir}/data/sample_bams.txt"

// Accessory files
params.reference = "${projectDir}/data/ref/ref.fasta"
params.reference_index = "${projectDir}/data/ref/ref.fasta.fai"
params.reference_dict = "${projectDir}/data/ref/ref.dict"
params.intervals = "${projectDir}/data/ref/intervals.bed"

// Base name for final output file
params.cohort_name = "family_trio"

workflow {

    // Create input channel from a text file listing input file paths
    reads_ch = Channel.fromPath(params.reads_bam).splitText()

    // Load the file paths for the accessory files (reference and intervals)
    ref_file = file(params.reference)
    ref_index_file = file(params.reference_index)
    ref_dict_file = file(params.reference_dict)
    intervals_file = file(params.intervals)

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

    // Collect variant calling outputs across samples
    all_gvcfs_ch = GATK_HAPLOTYPECALLER.out[0].collect()
    all_idxs_ch = GATK_HAPLOTYPECALLER.out[1].collect()

    // Combine GVCFs into a GenomicsDB datastore
    GATK_GENOMICSDB(
        all_gvcfs_ch,
        all_idxs_ch,
        intervals_file,
        params.cohort_name
    )
}

/*
 * Generate BAM index file
 */
process SAMTOOLS_INDEX {
    container 'community.wave.seqera.io/library/samtools:1.20--b5dfbd93de237464'
    publishDir 'results_genomics', mode: 'symlink'

    input:
    path input_bam

    output:
    tuple path(input_bam), path("${input_bam}.bai")

    script:
    """
    samtools index '${input_bam}'
    """
}

/*
 * Call variants with GATK HaplotypeCaller
 */
process GATK_HAPLOTYPECALLER {
    container "community.wave.seqera.io/library/gatk4:4.5.0.0--730ee8817e436867"
    publishDir 'results_genomics', mode: 'symlink'

    input:
    tuple path(input_bam), path(input_bam_index)
    path ref_fasta
    path ref_index
    path ref_dict
    path interval_list

    output:
    path "${input_bam}.g.vcf", emit: vcf
    path "${input_bam}.g.vcf.idx", emit: idx

    script:
    """
    gatk HaplotypeCaller \\
        -R ${ref_fasta} \\
        -I ${input_bam} \\
        -O ${input_bam}.g.vcf \\
        -L ${interval_list} \\
        -ERC GVCF
    """
}

/*
 * Combine GVCFs into GenomicsDB datastore
 */
process GATK_GENOMICSDB {
    container "community.wave.seqera.io/library/gatk4:4.5.0.0--730ee8817e436867"
    publishDir 'results_genomics', mode: 'symlink'

    input:
    path all_gvcfs
    path all_idxs
    path interval_list
    val cohort_name

    output:
    path "${cohort_name}_gdb"

    script:
    def gvcfs_line = all_gvcfs.collect { gvcf -> "-V ${gvcf}" }.join(' ')
    """
    gatk GenomicsDBImport \\
        ${gvcfs_line} \\
        -L ${interval_list} \\
        --genomicsdb-workspace-path ${cohort_name}_gdb
    """
}
