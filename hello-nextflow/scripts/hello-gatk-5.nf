/*
 * Pipeline parameters
 */

// Primary input
params.reads_bam = "${workflow.projectDir}/data/bam/*.bam"

// Accessory files
params.reference = "${workflow.projectDir}/data/ref/ref.fasta"
params.reference_index = "${workflow.projectDir}/data/ref/ref.fasta.fai"
params.reference_dict = "${workflow.projectDir}/data/ref/ref.dict"
params.calling_intervals = "${workflow.projectDir}/data/ref/intervals.bed"

/*
 * Generate BAM index file
 */
process SAMTOOLS_INDEX {

    container 'community.wave.seqera.io/library/samtools:1.20--b5dfbd93de237464'
    conda "bioconda::samtools=1.19.2"

    publishDir 'results', mode: 'copy'

    input:
        path input_bam

    output:
        tuple path(input_bam), path("${input_bam}.bai")

    """
    samtools index '$input_bam'
    """
}

/*
 * Call variants with GATK HaplotypeCaller in GVCF mode
 */
process GATK_HAPLOTYPECALLER {

    container "community.wave.seqera.io/library/gatk4:4.5.0.0--730ee8817e436867"
    conda "bioconda::gatk4=4.5.0.0"
    
    publishDir 'results', mode: 'copy'

    input:
        tuple path(input_bam), path(input_bam_index)
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
    def vcfs_line = vcfs.collect { "-V ${it}" }.join(' ')
    """
    gatk GenomicsDBImport \
        ${vcfs_line} \
        --genomicsdb-workspace-path ${cohort_name}_gdb \
        -L ${interval_list}

    gatk GenotypeGVCFs \
        -R ${ref_fasta} \
        -V gendb://${cohort_name}_gdb \
        -O ${cohort_name}.joint.vcf \
        -L ${interval_list}
    """
}

workflow {

    // Create input channel from BAM files
    bam_ch = Channel.fromPath(params.reads_bam, checkIfExists: true)
    

    // Reference objects
    ref_file       = file(params.reference)
    ref_index_file = file(params.reference_index)
    ref_dict_file  = file(params.reference_dict)
    intervals_file = file(params.calling_intervals)

    // Create index file for input BAM file
    SAMTOOLS_INDEX(bam_ch)

    // Call variants from the indexed BAM file
    GATK_HAPLOTYPECALLER(
        SAMTOOLS_INDEX.out,
        ref_file,
        ref_index_file,
        ref_dict_file,
        intervals_file
    )

    // Collect variant calling outputs across samples
    all_vcfs = GATK_HAPLOTYPECALLER.out[0].collect()
    all_tbis = GATK_HAPLOTYPECALLER.out[1].collect()

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
}