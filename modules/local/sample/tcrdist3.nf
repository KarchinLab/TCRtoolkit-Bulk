process TCRDIST3_MATRIX {
    tag "${sample_meta.sample}"
    container "ghcr.io/karchinlab/tcrtoolkit-bulk:main"

    input:
    tuple val(sample_meta), path(count_table)
    val matrix_sparsity
    val distance_metric
    path ref_db

    output:
    tuple val(sample_meta), path("${sample_meta.sample}_distance_matrix.*"), emit: 'tcrdist_output'
    path "${sample_meta.sample}_clone_df.csv", emit: 'clone_df'
    path "matrix_maximum_value.txt", emit: 'max_matrix_value'

    script:
    """
    # Run tcrdist3 on input
    tcrdist3_matrix.py ${count_table} ${sample_meta.sample} ${matrix_sparsity} ${distance_metric} ${ref_db} ${task.cpus}
    """
}

process TCRDIST3_HISTOGRAM_CALC {
    tag "${sample_meta.sample}"
    label 'process_high'
    container "ghcr.io/karchinlab/tcrtoolkit-bulk:main"

    input:
    tuple val(sample_meta), path(distance_matrix)
    val matrix_sparsity
    val distance_metric
    val global_max_value

    output:
    tuple val(sample_meta), path("${sample_meta.sample}_histogram_data.npz"), emit: 'histogram_data'
    path "${sample_meta.sample}_histogram_ymax.txt", emit: 'max_histogram_count'

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
        sparse_matrix = sp.load_npz(input_path).tocoo()

        # Extract the lower triangle values (excluding diagonal)
        mask = sparse_matrix.row > sparse_matrix.col
        lower_triangle = sparse_matrix.data[mask]

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
    np.savez("${sample_meta.sample}_histogram_data.npz", counts=counts, bin_edges=bin_edges)

    # Save max count value for y-axis standardization
    with open("${sample_meta.sample}_histogram_ymax.txt", "w") as f:
        f.write(f"{int(counts.max())}\\n")
    EOF
    """
}

process TCRDIST3_HISTOGRAM_PLOT {
    tag "${sample_meta.sample}"
    label 'process_low'
    container "ghcr.io/karchinlab/tcrtoolkit-bulk:main"

    input:
    tuple val(sample_meta), path(histogram_data_npz)
    val y_max

    output:
    path "${sample_meta.sample}_pairwise_distance_distribution_standardized.png", emit: 'final_histogram'

    script:
    """
    python - <<EOF
    import numpy as np
    import matplotlib.pyplot as plt
    import matplotlib.ticker as ticker

    # Load histogram data
    data = np.load("${histogram_data_npz}")
    counts = data["counts"]
    bin_edges = data["bin_edges"]
    bin_centers = (bin_edges[:-1] + bin_edges[1:]) / 2

    # Plot
    plt.figure(figsize=(8, 5))
    plt.bar(bin_centers, counts, width=np.diff(bin_edges), edgecolor='black')

    # X-ticks logic (copied from earlier)
    min_val = bin_edges[0]
    max_val = bin_edges[-1] - 1
    xtick_range = max_val - min_val
    if xtick_range <= 10:
        step = 1
    elif xtick_range <= 50:
        step = 5
    else:
        step = 25
    plt.xticks(np.arange(min_val, max_val + 1, step))

    plt.xlabel("Pairwise Distance")
    plt.ylabel("Frequency (log scale)")



    plt.yscale("log")
    plt.ylim(0.9, max(10, ${y_max}))  # avoid zero on log scale

    # Standardized ticks at 10^0, 10^1, etc.
    yticks = np.logspace(0, int(np.ceil(np.log10(${y_max}))), base=10)
    plt.yticks(yticks)
    plt.gca().yaxis.set_major_locator(ticker.LogLocator(base=10.0, subs=(1.0,), numticks=10))
    # plt.gca().yaxis.set_minor_locator(ticker.NullLocator()) 
    
    plt.title("Distribution of Beta Chain Pairwise Distances - ${sample_meta.sample}")
    plt.savefig("${sample_meta.sample}_pairwise_distance_distribution_standardized.png", dpi=300, bbox_inches="tight")
    plt.close()
    EOF
    """
}
