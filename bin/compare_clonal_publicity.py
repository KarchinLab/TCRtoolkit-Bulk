#!/usr/bin/env python3

"""
compare_clonal_publicity.py
Input: .tsv of CDR3 sequences,
Output: .tsv of TCR sharing across samples, .tsv of sample-sample_id mapping 
"""
import argparse
import pandas as pd

def main():
    # Initialize the parser
    parser = argparse.ArgumentParser(description="Take positional args")
    
    # Add positional arguments
    parser.add_argument(
        "cdr_df",
        type=str,
        help="Input file name, expected to be in TSV format with columns [CDR3b, sample]",
    )
    args = parser.parse_args()
    
    # Load data
    df = pd.read_csv(args.cdr_df, sep="\t")
    
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

if __name__ == "__main__":
    main()