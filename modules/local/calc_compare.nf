process COMPARE_CALC {
    label 'process_single'

    container "ghcr.io/break-through-cancer/bulktcr:latest"

    publishDir "${params.output}/compare_output/", mode: "copy", overwrite: "true"
    
    input:
    path sample_utf8
    path data_dir

    output:
    path 'jaccard_mat.csv', emit: jaccard_mat
    path 'sorensen_mat.csv', emit: sorensen_mat
    path 'morisita_mat.csv', emit: morisita_mat

    script:
    """
    calc_compare.py \
        -s $sample_utf8 \
        -p $projectDir 
    """
}
