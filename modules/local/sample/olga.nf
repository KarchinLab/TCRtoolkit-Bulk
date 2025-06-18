process OLGA {
    tag "${sample_meta[0]}"
    label 'process_low'
    container "ghcr.io/karchinlab/tcrtoolkit-bulk:main"

    input:
    tuple val(sample_meta), path(count_table)

    output:
    path "${sample_meta[0]}_tcr_pgen.tsv", emit: "olga_output"
    path "${sample_meta[0]}_tcr_pgen_histogram.png"

    script:
    """
    # Extract vector of cdr3 aa, dropping null values
    cat > dropAA.py <<EOF
    import pandas as pd

    df = pd.read_csv("${count_table}", sep="\t")
    df = df.dropna(subset=["junction_aa"])
    df = df["junction_aa"]
    df.to_csv("output.tsv", sep="\t", index=False, header=False)
    EOF

    python dropAA.py

    olga-compute_pgen --humanTRB -i output.tsv -o "${sample_meta[0]}_pgen.tsv"

    python - <<EOF
    import pandas as pd
    import numpy as np
    import matplotlib.pyplot as plt

    # Load count and probability generation tables and merge
    df1 = pd.read_csv("${count_table}", sep="\t")
    df1 = df1.dropna(subset=["junction_aa"])
    df2 = pd.read_csv('${sample_meta[0]}_pgen.tsv', sep='\t', header=None, usecols=[0, 1], names=['junction_aa', 'pgen'])
    merged_df = pd.merge(df1, df2, on='junction_aa', how='left')
    merged_df.to_csv("${sample_meta[0]}_tcr_pgen.tsv", sep="\t", index=False)

    # Drop rows where pgen is 0
    merged_df = merged_df[merged_df['pgen'] != 0]
    log_probs = np.log10(merged_df['pgen'])
    cdr3_counts = merged_df['duplicate_count']

    # Plot histogram
    plt.figure(figsize=(8, 5))
    plt.hist(log_probs, bins=30, density=True, weights=cdr3_counts, edgecolor='black')

    # Label with LaTeX formatting
    plt.xlabel('log_10 Generation Probability')
    plt.ylabel('Probability Density')
    plt.title(f'${sample_meta[0]} TCR Generation Probability Histogram')
    # plt.grid(True)

    # Save to file
    plt.savefig("${sample_meta[0]}_tcr_pgen_histogram.png", dpi=300, bbox_inches="tight")
    plt.close()
    EOF
    """
}