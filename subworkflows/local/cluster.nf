
/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    IMPORT LOCAL MODULES
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/

include { GLIPH2        } from '../../modules/local/gliph2'
include { PROCESS_SAMPLESHEET   } from '../../modules/local/process_samplesheet'
include { TURBO_GLIPH2   } from '../../modules/local/turbogliph'
include { PLOT_GLIPH2   } from '../../modules/local/plot_gliph2'
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

    // GLIPH2( samplesheet_utf8,
    //         file(params.data_dir),
    //         file(params.ref_files),
    //         params.project_name,
    //         params.local_min_pvalue,
    //         params.p_depth,
    //         params.global_convergence_cutoff,
    //         params.simulation_depth,
    //         params.kmer_min_depth,
    //         params.local_min_OVE,
    //         params.algorithm,
    //         params.all_aa_interchangeable )

    // PROCESS_SAMPLESHEET(
    //     samplesheet_utf8,
    //     file(params.data_dir),
    //     params.project_name
    // )

    TURBO_GLIPH2(
        // PROCESS_SAMPLESHEET.out.processed_samplesheet
        samplesheet_utf8,
        file(params.data_dir),
        params.project_name
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