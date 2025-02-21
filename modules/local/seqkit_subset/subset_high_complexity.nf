process SUBSET_HIGH_COMPLEXITY {
    tag "$meta.id"
    label 'process_medium'

    conda "${moduleDir}/environment.yml"
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/seqkit:2.8.1--h9ee0642_0' :
        'biocontainers/seqkit:2.8.1--h9ee0642_0' }"
    
    input:
    tuple val(meta), path(reads), path(bed)
    
    output:
    tuple val(meta), path("*.lc_filtered.fastq.gz"), emit: reads

    when:
    task.ext.when == null || task.ext.when

    script:
    def prefix = task.ext.prefix ?: "${meta.id}"
    
    """
    seqkit subseq --bed ${bed} ${reads} -j $task.cpus | seqkit replace -p ":\\." -j $task.cpus | gzip > ${prefix}.lc_filtered.fastq.gz
    """
}
