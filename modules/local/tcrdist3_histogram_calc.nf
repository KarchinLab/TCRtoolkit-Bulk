process TCRDIST3_HISTOGRAM_CALC {
    tag "${sample_meta[0]}"
    label 'process_medium'
    container "ghcr.io/karchinlab/tcrtoolkit-bulk:main"

    input:
    tuple val(sample_meta), path(distance_matrix)
    val matrix_sparsity
    val distance_metric
    val global_max_value

    output:
    tuple val(sample_meta), path("${sample_meta[0]}_histogram_data.npz"), emit: 'histogram_data'
    path "${sample_meta[0]}_histogram_ymax.txt", emit: 'max_histogram_count'

    script:
    """
    python - <<EOF
    import os
    import numpy as np
    import matplotlib.pyplot as plt
    import scipy.sparse as sp

    input_path = "${distance_matrix}"
    ext = os.path.splitext(input_path)[1].lower()

    if ext == ".csv":
        full_matrix = np.loadtxt(input_path, delimiter=',')
        lower_triangle = full_matrix[np.tril_indices(full_matrix.shape[0], k=-1)]
    elif ext == ".npz":
        sparse_matrix = sp.load_npz(input_path)

        # Extract the lower triangle values (excluding diagonal)
        lower_triangle = sparse_matrix[np.tril_indices(sparse_matrix.shape[0], k=-1)]

        # Remove values equal to 0 (i.e., not within cutoff radius)
        lower_triangle = lower_triangle[lower_triangle != 0]

        # Replace -1 with 0 to reflect true zero-distance pairs
        lower_triangle = np.where(lower_triangle == -1, 0, lower_triangle)

    min_val = 0
    if "${matrix_sparsity}" == "sparse" and "${distance_metric}" == "levenshtein":
        max_val = 6
    elif "${matrix_sparsity}" == "sparse" and "${distance_metric}" == "tcrdist":
        max_val = 50
    else:
        max_val = ${global_max_value}

    if lower_triangle.size == 0:
        print("No valid pairwise distances — creating empty histogram.")
        bin_edges = np.arange(min_val, max_val + 2)
        counts = np.zeros(len(bin_edges) - 1)
    else:
        bin_edges = np.arange(min_val, max_val + 2)
        counts, _ = np.histogram(lower_triangle, bins=bin_edges)

    # Save histogram data
    np.savez("${sample_meta[0]}_histogram_data.npz", counts=counts, bin_edges=bin_edges)

    # Save max count value for y-axis standardization
    with open("${sample_meta[0]}_histogram_ymax.txt", "w") as f:
        f.write(f"{int(counts.max())}\\n")
    EOF
    """
}
