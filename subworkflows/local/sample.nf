
/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    IMPORT LOCAL MODULES
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/

include { SAMPLE_CALC } from '../../modules/local/sample_calc'
include { SAMPLE_PLOT } from '../../modules/local/sample_plot'
include { TCRDIST3_MATRIX } from '../../modules/local/tcrdist3_matrix'
include { TCRDIST3_PLOT } from '../../modules/local/tcrdist3_plot'
include { OLGA } from '../../modules/local/olga'
include { CONVERGENCE } from '../../modules/local/convergence'

/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    RUN MAIN WORKFLOW
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/

workflow SAMPLE {

    take:
    sample_map

    main:

    /////// =================== CALC SAMPLE ===================  ///////

    SAMPLE_CALC( sample_map )

    SAMPLE_CALC.out.sample_csv
        .collectFile(name: 'sample_stats.csv', sort: true, 
                     storeDir: "${params.output}/sample")
        .set { sample_stats_csv }

    SAMPLE_CALC.out.v_family_csv
        .collectFile(name: 'v_family.csv', sort: true,
                     storeDir: "${params.output}/sample")
        .set { v_family_csv }
        
    SAMPLE_CALC.out.d_family_csv
        .collectFile(name: 'd_family.csv', sort: true,
                     storeDir: "${params.output}/sample")
        .set { d_family_csv }
        
    SAMPLE_CALC.out.j_family_csv
        .collectFile(name: 'j_family.csv', sort: true,
                     storeDir: "${params.output}/sample")
        .set { j_family_csv }


    TCRDIST3_MATRIX(
        sample_map,
        file(params.db_path)
    )

    TCRDIST3_PLOT(
        TCRDIST3_MATRIX.out.tcr_output
    )

    /////// =================== PLOT SAMPLE ===================  ///////

    SAMPLE_PLOT (
        file(params.samplesheet),
        file(params.sample_stats_template),
        sample_stats_csv,
        v_family_csv
        )
    
    OLGA ( sample_map )
    
    CONVERGENCE ( sample_map )
    
    // emit:
    // sample_stats_csv
    // v_family_csv
    // sample_meta_csv
    // versions = SAMPLESHEET_CHECK.out.versions // channel: [ versions.yml ]
}