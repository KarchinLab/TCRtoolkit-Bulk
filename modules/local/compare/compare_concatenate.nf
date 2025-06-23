process COMPARE_CONCATENATE {
    label 'process_low'
    container "ghcr.io/karchinlab/tcrtoolkit-bulk:main"

    input:
    path samplesheet_utf8

    output:
    path "concatenated_cdr3.txt", emit: "concat_cdr3"

    script:
    """
    # Concatenate input Adaptive files and process metadata
    compare_concatenate.py $samplesheet_utf8
    """
}