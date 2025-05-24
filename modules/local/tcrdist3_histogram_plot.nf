process TCRDIST3_HISTOGRAM_PLOT {
    tag "${sample_meta[0]}"
    label 'process_low'
    container "ghcr.io/karchinlab/tcrtoolkit-bulk:main"

    input:
    tuple val(sample_meta), path(histogram_data_npz)
    val y_max

    output:
    path "${sample_meta[0]}_pairwise_distance_distribution_standardized.png", emit: 'final_histogram'

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
    
    plt.title("Distribution of Beta Chain Pairwise Distances - ${sample_meta[0]}")
    plt.savefig("${sample_meta[0]}_pairwise_distance_distribution_standardized.png", dpi=300, bbox_inches="tight")
    plt.close()
    EOF
    """
}
