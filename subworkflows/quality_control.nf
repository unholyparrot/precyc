include { NANOPLOT } from '../modules/local/nanoplot/main'
include { FASTQC as FASTQC_SHORT } from '../modules/nf-core/fastqc/main'
include { FASTQC as FASTQC_LONG } from '../modules/nf-core/fastqc/main'

workflow QC_CONTROLS {
    take:
        input_reads // [meta, [short_reads_1, short_reads_2], long_reads]
        suffix     // String to append to output names (e.g., 'pre_qc' or 'post_qc')
    main:
        ch_multiqc_files = Channel.empty()

        // Modify meta to include the suffix
        input_reads_modified = input_reads.map { meta, short_reads, long_reads ->
            def new_meta = meta.clone()
            new_meta.id = "${meta.id}_${suffix}"
            [new_meta, short_reads, long_reads]
        }

        ch_short_reads = input_reads_modified.map{meta, short_reads, _long_reads -> [meta, short_reads]}.filter {
            _meta, reads -> reads && reads.size() > 0
        }
        ch_long_reads = input_reads_modified.map{meta, _short_reads, long_reads -> [meta, long_reads]}.filter {
            _meta, reads -> reads && reads.size() > 0
        }

        if (params.do_qc_fastqc) {
            FASTQC_SHORT(ch_short_reads)
            ch_multiqc_files = ch_multiqc_files.mix(FASTQC_SHORT.out.zip.collect{it[1]}.ifEmpty([]))
            
            FASTQC_LONG(ch_long_reads)
            ch_multiqc_files = ch_multiqc_files.mix(FASTQC_LONG.out.zip.collect{it[1]}.ifEmpty([]))
        }

        if (params.do_qc_nanoplot) {
            NANOPLOT(ch_long_reads)
            ch_multiqc_files = ch_multiqc_files.mix(NANOPLOT.out.txt.collect{it[1]}.ifEmpty([]))
        }

    emit:
        multiqc_files = ch_multiqc_files
}
