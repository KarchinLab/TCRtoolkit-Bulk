
/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    IMPORT LOCAL MODULES
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/

include { CALC_COMPARE  } from '../../modules/local/calc_compare.nf'
include { PLOT_COMPARE  } from '../../modules/local/plot_compare.nf'

/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    RUN MAIN SUBWORKFLOW
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/

workflow COMPARE {

    // println("Welcome to the BULK TCRSEQ pipeline! -- COMPARE ")

    take:
    sample_utf8
    project_name

    main:
    CALC_COMPARE( sample_utf8 )

    PLOT_COMPARE( sample_utf8,
                  CALC_COMPARE.out.jaccard_mat,
                  CALC_COMPARE.out.sorensen_mat,
                  CALC_COMPARE.out.morisita_mat,
                  file(params.compare_stats_template),
                  project_name
                  )
    
    // emit:
    // compare_stats_html
    // versions = SAMPLESHEET_CHECK.out.versions // channel: [ versions.yml ]
}