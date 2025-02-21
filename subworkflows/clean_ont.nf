include { FILTER_LOW_COMPLEXITY } from '../modules/local/ont_lc_filter/filter_low_complexity'
include { SUBSET_HIGH_COMPLEXITY } from '../modules/local/seqkit_subset/subset_high_complexity'
include { FILTLONG } from '../modules/nf-core/filtlong/main'


workflow CLEAN_ONT {
    take:
        input_reads // [meta, [short_reads_1, short_reads_2], long_reads]
    
    main:

        // First, clean low complexity regions
        if (params.do_clean_ont_filter_lc) {
            ch_long_reads = input_reads.map { it -> [it[0], it[2]] }
            // TODO: Add a check to see if the image from params exists
            FILTER_LOW_COMPLEXITY(ch_long_reads)

            ch_filter_lc = FILTER_LOW_COMPLEXITY.out.bed

            ch_merged_lc = ch_long_reads.join(ch_filter_lc)
                .map { meta, reads, bed -> [meta, reads, bed] }

            SUBSET_HIGH_COMPLEXITY(ch_merged_lc)

            ch_lc_cleaned = SUBSET_HIGH_COMPLEXITY.out.reads.join(input_reads)
                .map { meta, new_long_reads, short_reads, _old_long_reads -> [meta, short_reads, new_long_reads] }
        }
        else {
            ch_lc_cleaned = input_reads
        }

        // Then filter by length
        if ( params.do_clean_ont_filter_general ) {
            FILTLONG(ch_lc_cleaned)
            clean_ont_reads = FILTLONG.out.reads
        }
        else {
            clean_ont_reads = ch_lc_cleaned
        }

        ch_out = clean_ont_reads.join(input_reads)
            .map { meta, new_long_reads, short_reads, _old_long_reads -> [meta, short_reads, new_long_reads] }

    emit:
        clean_reads = ch_out
}
