process PROCESS_SAMPLESHEET {

    label 'process_single'
    // publishDir "${params.output}/gliph2_output", mode: 'copy'
    container "ghcr.io/break-through-cancer/bulktcr:latest"

    cpus 1
    memory 1.GB

    input:
    path samplesheet_utf8

    output:
    path "${params.project_name}_tcr.txt", emit: 'processed_samplesheet'

    script:
    """
    
    # Prep _tcr.txt file
    prep_gliph2_tcr.py ${params.data_folder} ${params.project_name} $samplesheet_utf8

    """

}
