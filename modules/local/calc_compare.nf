process CALC_COMPARE {
    // tag "${sample_utf8}"
    label 'process_single'

    // beforeScript 'export DOCKER_OPTS="-v $${params.data_dir}:$${params.data_dir}"'

    container "domebraccia/bulktcr:1.0"

    publishDir "${params.output}/${params.project_name}/compare/", mode: "copy", overwrite: "true"
    
    input:
    path sample_utf8
    // path meta_data

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