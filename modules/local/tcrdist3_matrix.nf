process TCRDIST3_MATRIX {
    tag "${sample_meta[0]}"
    container "ghcr.io/karchinlab/tcrtoolkit-bulk:main"

    input:
    tuple val(sample_meta), path(count_table)
    val matrix_sparsity
    val distance_metric
    path ref_db

    output:
    tuple val(sample_meta), path("${sample_meta[0]}_distance_matrix.*"), emit: 'tcrdist_output'
    path "${sample_meta[0]}_clone_df.csv", emit: 'clone_df'
    path "matrix_maximum_value.txt", emit: 'max_matrix_value'
    
    script:
    """
    # Run tcrdist3 on input
    tcrdist3_matrix.py ${count_table} ${sample_meta[0]} ${matrix_sparsity} ${distance_metric} ${ref_db} ${task.cpus}
    """
}