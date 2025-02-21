#!/usr/bin/env nextflow

include { INPUT } from './subworkflows/input.nf'
include { QC_CONTROLS } from './subworkflows/quality_control.nf'
include { JUST_CLEAN } from './workflows/just_clean.nf'
include { PRECYCLER } from './workflows/precycler.nf'
include { MULTIQC } from './modules/nf-core/multiqc/main' 

process DUMP_PARAMETERS {
    publishDir "${params.outdir}", mode: 'copy'

    output:
    path "params.json"

    exec:
    def json = new groovy.json.JsonBuilder(params).toPrettyString()
    task.workDir.resolve("params.json").text = json
}

workflow {

    // Add parameter logging
    log.info """
    ===========================================
    ONT Cleaning Pipeline
    ==========================================="""

    // Print all parameters
    params.each { k,v ->
        log.info "${k.padRight(15)}: $v"
    }
    log.info "==========================================="   
    
    DUMP_PARAMETERS()
    INPUT()

    if (params.job == 'qc') {
        QC_CONTROLS(INPUT.out.input_reads, 'pre_filter')
        MULTIQC(QC_CONTROLS.out.multiqc_files.collect(), [], [], [], [], [])
    }

    else if (params.job == 'clean') {
        JUST_CLEAN(INPUT.out.input_reads)
        MULTIQC(JUST_CLEAN.out.multiqc_files.collect(), [], [], [], [], [])
    }

    else if (params.job == 'precycler') {
        if (params.do_clean) {
            JUST_CLEAN(INPUT.out.input_reads)
            MULTIQC(JUST_CLEAN.out.multiqc_files.collect(), [], [], [], [], [])
            clean_reads = JUST_CLEAN.out.clean_reads.map { meta, _short_reads, long_reads -> [meta, long_reads] }
        } else {
            clean_reads = INPUT.out.input_reads.map { meta, _short_reads, long_reads -> [meta, long_reads] }
        }
        PRECYCLER(clean_reads)
    }

    else {
        log.info "No job specified"
    }
}
