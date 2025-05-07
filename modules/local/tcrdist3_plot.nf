process TCRDIST3_PLOT {
    tag "${sample_meta[0]}"
    label 'process_high'
    label 'process_high_memory'
    container "ghcr.io/break-through-cancer/bulktcr:latest"

    input:
    tuple val(sample_meta), path(distance_matrix)

    output:
    path "${sample_meta[0]}_pairwise_distance_distribution.png", emit: 'beta_histogram'

    script:
    """
    python - <<EOF
    import numpy as np
    import matplotlib.pyplot as plt

    distances = np.loadtxt("${distance_matrix}", delimiter=',')
    lower_triangle = distances[np.tril_indices(distances.shape[0], k=-1)]
    counts, bin_edges = np.histogram(lower_triangle, bins=100)

    plt.figure(figsize=(8, 5))
    plt.bar((bin_edges[:-1] + bin_edges[1:]) / 2, counts, width=np.diff(bin_edges), edgecolor='black')
    plt.xlabel("Pairwise Distance")
    plt.ylabel("Frequency (log scale)")
    plt.yscale("log")
    plt.title("Distribution of Beta Chain Pairwise Distances - ${sample_meta[0]}")
    plt.savefig("${sample_meta[0]}_pairwise_distance_distribution.png", dpi=300, bbox_inches="tight")
    plt.close()
    EOF
    """
}