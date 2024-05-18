/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    VALIDATE & PRINT PARAMETER SUMMARY
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/

// Validate pipeline parameters
def checkPathParamList = [ params.samplesheet, params.data_dir ]
for (param in checkPathParamList) { if (param) { file(param, checkIfExists: true) } }

// Check mandatory parameters
if (params.samplesheet) { samplesheet = file(params.samplesheet) } else { exit 1, 'Samplesheet not specified. Please, provide a --samplesheet=/path/to/samplesheet.csv !' }
if (params.data_dir) { data_dir = params.data_dir } else { exit 1, 'Data directory not specified. Please, provide a --data_dir=/path/to/data_dir !' }
if (params.output) { output = params.output } else { exit 1, 'Output directory not specified. Please, provide a --output=/path/to/output !' }

/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    IMPORT LOCAL MODULES/SUBWORKFLOWS
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/

//
// SUBWORKFLOW: Consisting of a mix of local and nf-core/modules
//

include { INPUT_CHECK } from '../subworkflows/local/input_check'
include { SAMPLE      } from '../subworkflows/local/sample'
include { COMPARE     } from '../subworkflows/local/compare'
include { CLUSTER     } from '../subworkflows/local/cluster'

/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    RUN MAIN WORKFLOW
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/


workflow TCRTOOLKIT_BULK {

    println("Running TCRTOOLKIT_BULK workflow...")

    // Split the workflow_level parameter into a list of levels
    def levels = params.workflow_level.tokenize(',')

    // Checking input tables
    INPUT_CHECK( file(params.samplesheet) )

    // Running sample level analysis
    if (levels.contains('sample') || levels.contains('complete')) {
        SAMPLE( INPUT_CHECK.out.sample_map )
    }

    // Running comparison analysis
    if (levels.contains('compare') || levels.contains('complete')) {
        COMPARE( INPUT_CHECK.out.samplesheet_utf8,
                 params.project_name )
    }

    // Running clustering analysis
    if (levels.contains('cluster') || levels.contains('complete')) {
        CLUSTER ( INPUT_CHECK.out.samplesheet_utf8 )
    }
    
}

/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    COMPLETION EMAIL AND SUMMARY
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/

// workflow.onComplete {

//     log.info(workflow.success ? "Finished tcrtoolkit-bulk!" : "Please check your inputs.")

// }

/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    THE END
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/
