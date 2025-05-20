process TCRDIST3_PLOT {
    tag "${sample_meta[0]}"
    label 'process_medium'
    container "ghcr.io/karchinlab/tcrtoolkit-bulk:main"

    input:
    tuple val(sample_meta), path(distance_matrix)

    output:
    path "${sample_meta[0]}_pairwise_distance_distribution.png", emit: 'beta_histogram'

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
    # Determine bin edges: one bin per integer value
    min_val = lower_triangle.min()
    max_val = lower_triangle.max()
    xtick_range = max_val - min_val

    plt.figure(figsize=(8, 5))

    if xtick_range > 50:
        counts, bin_edges = np.histogram(lower_triangle, bins=100)
        plt.bar((bin_edges[:-1] + bin_edges[1:]) / 2, counts, width=np.diff(bin_edges), edgecolor='black')
    else:
        bins = np.arange(min_val, max_val + 2)  # +2 to include rightmost edge
        counts, bin_edges = np.histogram(lower_triangle, bins=bins)
        
        if xtick_range <= 10:
            step = 1
        else:
            step = 5
        plt.bar(bins[:-1], counts, width=1.0, align='center', edgecolor='black')
        plt.xticks(np.arange(0, max_val + 1, step = step))

    plt.xlabel("Pairwise Distance")
    plt.ylabel("Frequency (log scale)")
    plt.yscale("log")
    plt.title("Distribution of Beta Chain Pairwise Distances - ${sample_meta[0]}")
    plt.savefig("${sample_meta[0]}_pairwise_distance_distribution.png", dpi=300, bbox_inches="tight")
    plt.close()
    EOF
    """
}