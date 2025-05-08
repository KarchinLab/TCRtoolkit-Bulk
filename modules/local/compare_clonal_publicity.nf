process COMPARE_CLONAL_PUBLICITY {
    label 'process_low'
    container "ghcr.io/break-through-cancer/bulktcr:latest"

    input:
    path concat_cdr3

    output:
    path "cdr3_sharing.tsv", emit: "shared_cdr3"
    path "sample_mapping.tsv", emit: "sample_mapping"
    path "sharing_histogram.png"

    script:
    """
    python - <<EOF
    import pandas as pd
    import numpy as np
    import matplotlib.pyplot as plt

    # Load data
    df = pd.read_csv("${concat_cdr3}", sep="\t")

    # Step 1: Map samples to integers
    sample_mapping = {sample: i + 1 for i, sample in enumerate(df['sample'].unique())}
    df['sample_id'] = df['sample'].map(sample_mapping)

    # Step 2: Group by CDR3b and aggregate sample_ids
    grouped = (
        df.groupby('CDR3b')['sample_id']
        .apply(lambda x: sorted(set(x)))  # remove duplicates if any
        .reset_index()
    )

    # Step 3: Add comma-separated list and total count
    grouped['samples_present'] = grouped['sample_id'].apply(lambda x: ",".join(map(str, x)))
    grouped['total_samples'] = grouped['sample_id'].apply(len)

    # Step 4: Final output — drop raw list
    final_df = grouped[['CDR3b', 'total_samples', 'samples_present']]
    final_df = final_df.sort_values(by='total_samples', axis=0, ascending=False)

    # Step 5: Export both outputs
    final_df.to_csv("cdr3_sharing.tsv", sep="\t", index=False)

    # Also export the sample mapping
    sample_map_df = pd.DataFrame.from_dict(sample_mapping, orient='index', columns=['sample_id']).reset_index()
    sample_map_df.columns = ['patient', 'sample_id']
    sample_map_df.to_csv("sample_mapping.tsv", sep="\t", index=False)



    # Plot histogram
    sharing = final_df['total_samples'].values

    # Create integer bin edges from 0 to max(data)
    bins = np.arange(min(sharing), max(sharing) + 2)  # +2 to include the last value as a bin edge

    plt.figure(figsize=(8, 5))
    plt.hist(sharing, bins=bins, edgecolor='black', align='left')
    plt.xticks(bins[:-1])  # whole number positions and labels
    plt.yscale('log')

    plt.xlabel('Number of Shared Samples')
    plt.ylabel('TCR Sequence Frequency (log scale)')
    plt.title('TCR Sharing Histogram')

    # Save to file
    plt.savefig("sharing_histogram.png", dpi=300, bbox_inches="tight")
    plt.close()

    EOF
    """
}