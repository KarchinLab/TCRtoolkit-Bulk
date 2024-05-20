
/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    IMPORT LOCAL MODULES
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/

include { CALC_SAMPLE } from '../../modules/local/calc_sample.nf'
include { PLOT_SAMPLE } from '../../modules/local/plot_sample.nf'

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

    CALC_SAMPLE( sample_map )

    CALC_SAMPLE.out.sample_csv
        .collectFile(name: 'sample_stats.csv', sort: true, 
                     storeDir: "${params.output}/sample_output")
        .set { sample_stats_csv }

    CALC_SAMPLE.out.v_family_csv
        .collectFile(name: 'v_family.csv', sort: true,
                     storeDir: "${params.output}/sample_output")
        .set { v_family_csv }

    /////// =================== PLOT SAMPLE ===================  ///////

    PLOT_SAMPLE(
        file(params.samplesheet),
        file(params.sample_stats_template),
        sample_stats_csv,
        v_family_csv
        )
    
    // emit:
    // sample_stats_csv
    // v_family_csv
    // sample_meta_csv
    // versions = SAMPLESHEET_CHECK.out.versions // channel: [ versions.yml ]
}