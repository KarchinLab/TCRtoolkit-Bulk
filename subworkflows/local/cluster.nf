
/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    IMPORT LOCAL MODULES
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/

include { TURBO_GLIPH2   } from '../../modules/local/turbogliph'
include { PLOT_GLIPH2   } from '../../modules/local/plot_gliph2'

/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    RUN MAIN SUBWORKFLOW
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/

workflow CLUSTER {

    take:
    samplesheet_utf8

    main:

    // 1. Run GLIPH2

    TURBO_GLIPH2(
        samplesheet_utf8,
        file(params.data_dir),
    )

    // 2. Plot GLIPH2 results
    // PLOT_GLIPH2(
    //     params.gliph2_report_template,
    //     GLIPH2.out.clusters,
    //     GLIPH2.out.cluster_stats
    //     )
    
    // emit:
    // cluster_html
    // versions = SAMPLESHEET_CHECK.out.versions // channel: [ versions.yml ]
}