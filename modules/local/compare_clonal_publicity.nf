process COMPARE_CLONAL_PUBLICITY {
    label 'process_low'
    container "ghcr.io/break-through-cancer/bulktcr:latest"

    input:
    path concat_cdr3

    output:
    path "cdr3_sharing.tsv", emit: "shared_cdr3"
    path "sample_mapping.tsv", emit: "sample_mapping"

    script:
    """
    # Concatenate input Adaptive files and process metadata
    compare_clonal_publicity.py $concat_cdr3
    """
}