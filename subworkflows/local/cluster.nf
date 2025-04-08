
/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    IMPORT LOCAL MODULES
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/

include { GLIPH2_TURBOGLIPH } from '../../modules/local/gliph2_turbogliph'
include { GLIPH2_PLOT } from '../../modules/local/gliph2_plot'
include { TCRDIST3_MATRIX } from '../../modules/local/tcrdist3_matrix'

/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    RUN MAIN SUBWORKFLOW
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/

workflow CLUSTER {

    take:
    samplesheet_utf8
    sample_map

    main:

    // 1. Run GLIPH2

    GLIPH2_TURBOGLIPH(
        samplesheet_utf8,
        file(params.data_dir)
    )

    // 2. Plot GLIPH2 results
    // GLIPH2_PLOT(
    //     params.gliph2_report_template,
    //     GLIPH2_TURBOGLIPH.out.cluster_member_details,
    //     GLIPH2_TURBOGLIPH.out.convergence_groups
    //     )
    
    TCRDIST3_MATRIX(
        sample_map,
        file(params.db_path)
    )
    
    // emit:
    // cluster_html
    // versions = SAMPLESHEET_CHECK.out.versions // channel: [ versions.yml ]
}