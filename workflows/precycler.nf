include { SUBSAMPLE } from '../modules/local/autocycler/subsample.nf'

workflow PRECYCLER {
    take:
        clean_ont_reads // [meta, long_reads]

    main:
        SUBSAMPLE(clean_ont_reads)

        ch_subsampled_fastq = SUBSAMPLE.out.fastq.transpose().map{ meta, fastq ->
            def subset_num = fastq.getSimpleName().split('_')[-1]
            def new_meta = meta.clone()
            new_meta.subset = subset_num
            [new_meta, fastq]
        }

        ch_subsampled_fastq.view()

}
