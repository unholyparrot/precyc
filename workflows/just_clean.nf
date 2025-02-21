include { INPUT } from '../subworkflows/input.nf'
include { QC_CONTROLS as QC_CONTROLS_RAW } from '../subworkflows/quality_control.nf'
include { CLEAN_SHORT } from '../subworkflows/clean_short.nf'
include { CLEAN_ONT } from '../subworkflows/clean_ont.nf'
include { QC_CONTROLS as QC_CONTROLS_FILTERED } from '../subworkflows/quality_control.nf'


workflow JUST_CLEAN {
    take:
        input_reads // [meta, short_reads, long_reads]

    main:
        ch_raw_reads = input_reads
        ch_multiqc_files = Channel.empty()

        // сперва проводим контроль качества
        if (params.do_qc) {
            QC_CONTROLS_RAW(ch_raw_reads, 'pre_filter')
            ch_multiqc_files = ch_multiqc_files.mix(QC_CONTROLS_RAW.out.multiqc_files.collect().ifEmpty([]))
        }
        // потом чистим короткие чтения
        if (params.do_clean_short) {
            // фильтруем, если коротких прочтений нет
            ch_short_reads = ch_raw_reads.map { meta, short_reads, _long_reads -> [meta, short_reads] }
            
            //  объединяем чистые короткие прочтения со старыми длинными прочтениями
            CLEAN_SHORT(ch_short_reads)
            ch_cleaned_short = CLEAN_SHORT.out.cleaned_short_reads.join(ch_raw_reads)
                .map { meta, short_reads, _old_short_reads, long_reads -> [meta, short_reads, long_reads] }
        } else {
            ch_cleaned_short = ch_raw_reads
        }

        // потом чистим длинные чтения
        if (params.do_clean_ont) {
            CLEAN_ONT(ch_cleaned_short)
            ch_clean_reads = CLEAN_ONT.out.clean_reads
        } else {
            ch_clean_reads = ch_cleaned_short
        }

        if (params.do_qc) {
            QC_CONTROLS_FILTERED(ch_clean_reads, 'post_filter')
            ch_multiqc_files = ch_multiqc_files.mix(QC_CONTROLS_FILTERED.out.multiqc_files.collect().ifEmpty([]))
        }

    emit:
        clean_reads = ch_clean_reads
        multiqc_files = ch_multiqc_files
}
