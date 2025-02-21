process SUBSAMPLE {
    input:
    tuple val(meta), path(reads)

    output:
    tuple val(meta), path("*.fastq"), emit: fastq
    tuple val(meta), path("*.yaml"), emit: yaml
    tuple val(meta), path("*.log"), emit: log
    path "versions.yml", emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    def args = task.ext.args ?: ''
    def prefix = task.ext.prefix ?: "${meta.id}"

    """
    ${params.path_to_local_binaries}/autocycler subsample \
        $args \
        --reads ${reads} \
        --out_dir . \
        --genome_size ${params.genome_size} 2> autocycler_subsample.log
    mv subsample.yaml ${prefix}_subsample.yaml
    mv autocycler_subsample.log ${prefix}_autocycler_subsample.log
    for bc in *.fastq; do
        basename=\$(basename \$bc)
        mv "\$bc" "${prefix}_\${basename}"
    done

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        autocycler: \$(${params.path_to_local_binaries}/autocycler --version | sed 's/Autocycler v//')
    END_VERSIONS
    """
}