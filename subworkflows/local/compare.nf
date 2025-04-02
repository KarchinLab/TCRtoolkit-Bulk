
/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    IMPORT LOCAL MODULES
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/

include { COMPARE_CALC  } from '../../modules/local/compare_calc'
include { COMPARE_PLOT  } from '../../modules/local/compare_plot'

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
    data_dir

    main:
    COMPARE_CALC( sample_utf8,
                  data_dir )

    COMPARE_PLOT( sample_utf8,
                  COMPARE_CALC.out.jaccard_mat,
                  COMPARE_CALC.out.sorensen_mat,
                  COMPARE_CALC.out.morisita_mat,
                  file(params.compare_stats_template),
                  project_name
                  )
    
    // emit:
    // compare_stats_html
    // versions = SAMPLESHEET_CHECK.out.versions // channel: [ versions.yml ]
}