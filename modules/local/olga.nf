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
    df = df.dropna(subset=["aminoAcid"])
    df = df["aminoAcid"]
    df.to_csv("output.tsv", sep="\t", index=False, header=False)
    EOF

    python dropAA.py

    olga-compute_pgen --humanTRB -i output.tsv -o "${sample_meta[0]}_tcr_pgen.tsv"

    python - <<EOF
    import pandas as pd
    import numpy as np
    import matplotlib.pyplot as plt

    # Load TSV with no header
    df = pd.read_csv('${sample_meta[0]}_tcr_pgen.tsv', sep='\t', header=None, usecols=[0, 1], names=['CDR3b', 'probability'])

    # Drop rows where pgen is 0
    df = df[df['probability'] != 0]
    log_probs = np.log10(df['probability'])

    # Plot histogram
    plt.figure(figsize=(8, 5))
    plt.hist(log_probs, bins=30, density=True, edgecolor='black')

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