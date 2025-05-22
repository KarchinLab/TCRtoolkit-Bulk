
/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    IMPORT LOCAL MODULES
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/

include { SAMPLE_CALC } from '../../modules/local/sample_calc'
include { SAMPLE_PLOT } from '../../modules/local/sample_plot'
include { TCRDIST3_MATRIX } from '../../modules/local/tcrdist3_matrix'
include { TCRDIST3_HISTOGRAM_CALC } from '../../modules/local/tcrdist3_histogram_calc'
include { TCRDIST3_HISTOGRAM_PLOT } from '../../modules/local/tcrdist3_histogram_plot'
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
        params.matrix_sparsity,
        params.distance_metric,
        file(params.db_path)
    )

    TCRDIST3_MATRIX.out.max_matrix_value
        .map { it.text.trim().toDouble() }
        .collect()
        .map { values -> values.max() }
        .set { global_x_max_value }

    // Use `global_max_value` in downstream processes or print it
    global_x_max_value.view { "Global x max matrix value: $it" }

    TCRDIST3_HISTOGRAM_CALC( 
        TCRDIST3_MATRIX.out.tcrdist_output,
        params.matrix_sparsity,
        params.distance_metric,
        global_x_max_value
    )

    TCRDIST3_HISTOGRAM_CALC.out.max_histogram_count
        .map { it.text.trim().toDouble() }
        .collect()
        .map { values -> values.max() }
        .set { global_y_max_value }

    // Use `global_max_value` in downstream processes or print it
    global_y_max_value.view { "Global y max matrix value: $it" }

    TCRDIST3_HISTOGRAM_PLOT( 
        TCRDIST3_HISTOGRAM_CALC.out.histogram_data,
        global_y_max_value
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