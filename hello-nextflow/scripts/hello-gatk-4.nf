/*
 * Pipeline parameters
 */

// Primary input (list of input files, one per line)
params.reads_bam = "${projectDir}/data/sample_bams.txt"

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

workflow {

    // Create input channel from list of input files in plain text
    reads_ch = Channel.fromPath(params.reads_bam).splitText()

    // Create channels for the accessory files (reference and intervals)
    ref_ch          = Channel.fromPath(params.reference).collect()
    ref_index_ch    = Channel.fromPath(params.reference_index).collect()
    ref_dict_ch     = Channel.fromPath(params.reference_dict).collect()
    intervals_ch    = Channel.fromPath(params.intervals).collect()

    // Create index file for input BAM file
    SAMTOOLS_INDEX(reads_ch)

    // Call variants from the indexed BAM file
    GATK_HAPLOTYPECALLER(
        SAMTOOLS_INDEX.out,
        ref_ch,
        ref_index_ch,
        ref_dict_ch,
        intervals_ch
    )
}