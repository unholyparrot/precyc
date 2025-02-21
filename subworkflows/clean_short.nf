include { FASTP } from '../modules/nf-core/fastp/main' 

workflow CLEAN_SHORT {
    take:
        input_reads // [meta, short_reads]
    
    main:
        FASTP(
            input_reads, 
            params.fastp_adapter_fasta ? params.fastp_adapter_fasta : [],
            params.fastp_discard_trimmed_pass,
            params.fastp_save_trimmed_fail,
            params.fastp_save_merged
            )
        ch_out = FASTP.out.reads

    emit:
        cleaned_short_reads = ch_out
}
