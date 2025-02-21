workflow INPUT {
    main:
        if ( file(params.input).getExtension() == "csv" ) {
            ch_input_rows = Channel.fromPath(params.input).splitCsv(header: true).map {
                row -> 
                    def id = row.id
                    def short_reads_1 = row.short_reads_1
                    def short_reads_2 = row.short_reads_2
                    def long_reads = row.long_reads
                    def short_reads = (short_reads_1 && short_reads_2) ? [short_reads_1, short_reads_2] : []
                    return [id, short_reads, long_reads]
            }
        }
        else {
            exit 1, "Unknown input file format: ${file(params.input).getExtension()}"
        }

        ch_raw_reads = ch_input_rows.map {
            row ->
                def meta = [:]
                meta.id = row[0]
                return [meta, row[1], row[2]]
        }

    emit:
        input_reads = ch_raw_reads
}
