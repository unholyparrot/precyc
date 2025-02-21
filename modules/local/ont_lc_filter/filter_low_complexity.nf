process FILTER_LOW_COMPLEXITY {
    tag "$meta.id"
    label 'process_medium'
    
    container "${params.path_to_local_containers}/lc_filter.sif"
    
    input:
    tuple val(meta), path(reads)
    
    output:
    tuple val(meta), path("*.bed"), emit: bed
    tuple val(meta), path("*.tsv"), emit: table
    tuple val(meta), path("*.log"), emit: log
    
    when:
    task.ext.when == null || task.ext.when

    script:
    def prefix = task.ext.prefix ?: "${meta.id}"
    def config = params.low_complexity_config ? "--config ${params.low_complexity_config}" : ""

    """
    run_filter \
        --input ${reads} \
        --out_pattern ${prefix} \
        --num_processes $task.cpus \
        $config
    """
}
