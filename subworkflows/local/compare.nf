
/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    IMPORT LOCAL MODULES
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/

include { COMPARE_CALC  } from '../../modules/local/compare/compare_calc'
include { COMPARE_PLOT  } from '../../modules/local/compare/compare_plot'
include { COMPARE_CONCATENATE  } from '../../modules/local/compare/compare_concatenate'
include { TCRSHARING_CALC } from '../../modules/local/compare/tcrsharing'
include { GLIPH2_TURBOGLIPH; GLIPH2_PLOT } from '../../modules/local/compare/gliph2'

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
    COMPARE_CALC( sample_utf8, file(data_dir) )

    COMPARE_PLOT( sample_utf8,
                  COMPARE_CALC.out.jaccard_mat,
                  COMPARE_CALC.out.sorensen_mat,
                  COMPARE_CALC.out.morisita_mat,
                  file(params.compare_stats_template),
                  project_name
                  )

    COMPARE_CONCATENATE(
        sample_utf8,
        file(params.data_dir)
    )

    GLIPH2_TURBOGLIPH(
        COMPARE_CONCATENATE.out.concat_cdr3
    )

    TCRSHARING_CALC(
        COMPARE_CONCATENATE.out.concat_cdr3
    )

    // emit:
    // compare_stats_html
    // versions = SAMPLESHEET_CHECK.out.versions // channel: [ versions.yml ]
}