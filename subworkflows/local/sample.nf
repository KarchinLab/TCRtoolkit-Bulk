
/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    IMPORT LOCAL MODULES
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/

include { SAMPLE_CALC } from '../../modules/local/sample/sample_calc'
include { SAMPLE_PLOT } from '../../modules/local/sample/sample_plot'
include { TCRDIST3_MATRIX; TCRDIST3_HISTOGRAM_CALC; TCRDIST3_HISTOGRAM_PLOT} from '../../modules/local/sample/tcrdist3'
include { OLGA_PGEN_CALC; OLGA_HISTOGRAM_CALC; OLGA_HISTOGRAM_PLOT; OLGA_WRITE_MAX } from '../../modules/local/sample/olga'
include { CONVERGENCE } from '../../modules/local/sample/convergence'
include { TCRPHENO } from '../../modules/local/sample/tcrpheno'
include { VDJDB_GET; VDJDB_VDJMATCH } from '../../modules/local/sample/tcrspecificity'

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
                     storeDir: "${params.outdir}/sample")
        .set { sample_stats_csv }

    SAMPLE_CALC.out.v_family_csv
        .collectFile(name: 'v_family.csv', sort: true,
                     storeDir: "${params.outdir}/sample")
        .set { v_family_csv }

    SAMPLE_CALC.out.d_family_csv
        .collectFile(name: 'd_family.csv', sort: true,
                     storeDir: "${params.outdir}/sample")
        .set { d_family_csv }

    SAMPLE_CALC.out.j_family_csv
        .collectFile(name: 'j_family.csv', sort: true,
                     storeDir: "${params.outdir}/sample")
        .set { j_family_csv }

    /////// =================== PLOT SAMPLE ===================  ///////

    SAMPLE_PLOT (
        file(params.samplesheet),
        file(params.sample_stats_template),
        sample_stats_csv,
        v_family_csv
        )

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

    OLGA_PGEN_CALC ( sample_map )

    OLGA_PGEN_CALC.out.olga_xmin
        .map { it.text.trim().toDouble() }
        .collect()
        .map { values -> values.min() }
        .set { olga_x_min_value }
    olga_x_min_value.view { "Olga x min matrix value: $it" }

    OLGA_PGEN_CALC.out.olga_xmax
        .map { it.text.trim().toDouble() }
        .collect()
        .map { values -> values.max() }
        .set { olga_x_max_value }
    olga_x_max_value.view { "Olga x max matrix value: $it" }

    OLGA_HISTOGRAM_CALC ( OLGA_PGEN_CALC.out.olga_pgen, olga_x_min_value, olga_x_max_value )

    OLGA_HISTOGRAM_CALC.out.olga_ymax
        .map { it.text.trim().toDouble() }
        .collect()
        .map { values -> values.max() }
        .set { olga_y_max_value }
    olga_y_max_value.view { "Olga y max matrix value: $it" }

    OLGA_HISTOGRAM_PLOT( OLGA_HISTOGRAM_CALC.out.olga_histogram, olga_y_max_value )

    OLGA_WRITE_MAX(
        olga_x_min_value,
        olga_x_max_value,
        olga_y_max_value
    )

    CONVERGENCE ( sample_map )

    TCRPHENO ( sample_map )

    VDJDB_GET ()

    VDJDB_VDJMATCH (sample_map, VDJDB_GET.out.ref_db)

    // emit:
    // sample_stats_csv
    // v_family_csv
    // sample_meta_csv
    // versions = SAMPLESHEET_CHECK.out.versions // channel: [ versions.yml ]
}