process COMPARE_CONCATENATE {
    label 'process_low'
    container "ghcr.io/break-through-cancer/bulktcr:latest"

    input:
    path samplesheet_utf8
    path data_folder

    output:
    path "${params.project_name}_tcr.txt", emit: "concat_cdr3"

    script:
    """
    # Concatenate input Adaptive files and process metadata
    gliph2_preprocess.py $data_folder ${params.project_name} $samplesheet_utf8
    """
}