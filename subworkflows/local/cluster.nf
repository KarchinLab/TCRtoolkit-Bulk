
/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    IMPORT LOCAL MODULES
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/

include { GLIPH2  } from '../../modules/local/gliph2'
// include { PLOT_GLIPH2  } from '../../modules/local/plot_gliph2'
// include { GIANA } from '../../modules/local/giana'

/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    RUN MAIN SUBWORKFLOW
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/

workflow CLUSTER {

    take:
    samplesheet_utf8

    main:

    // Groovy code to run GLIPH2 or GIANA based on user input (example)
    // if (meta_data.cluster_method == "GLIPH2") {
    //     GLIPH2( )
    // } else if (meta_data.cluster_method == "GIANA") {
    //     GIANA( )
    // } else {
    //     error("Invalid cluster_method. Please choose either GLIPH2 or GIANA.")
    // }

    // 1. Run GLIPH2

    GLIPH2( samplesheet_utf8,
            file("${params.data_dir}/test_data/*") )

    // 2. Plot GLIPH2 results
    // PLOT_GLIPH2(
    //     GLIPH2.out.clusters,
    //     GLIPH2.out.cluster_stats,
    //     meta_data
    //     )
    
    // emit:
    // cluster_html
    // versions = SAMPLESHEET_CHECK.out.versions // channel: [ versions.yml ]
}