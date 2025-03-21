process TCRDIST3_MATRIX {
    tag "${sample_meta[0]}"
    label 'process_high'
    container "ghcr.io/break-through-cancer/bulktcr:latest"

    input:
    tuple val(sample_meta), path(count_table)
    path ref_db

    output:
    path "${count_table.baseName}_distance_matrix.csv", emit: 'distance_matrix'
    path "${count_table.baseName}_clone_df.csv", emit: 'clone_df'
    
    script:
    """
    # Extract the basename
    basename=\$(basename ${count_table} .tsv)

    # Run tcrdist3 on input
    tcrdist3_matrix.py ${count_table} ${ref_db} ${task.cpus}
    """
}