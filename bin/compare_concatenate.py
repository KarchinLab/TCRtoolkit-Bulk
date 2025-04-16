#!/usr/bin/env python3

"""
gliph2_preprocess.py
Input: adaptive TSV files
Output: $concatenated_cdr3.txt
"""

# Import modules
import argparse
import glob
import os
import pandas as pd

# Initialize the parser
parser = argparse.ArgumentParser(description="Take positional args")

# Add positional arguments
parser.add_argument("data_dir")
parser.add_argument("samplesheet")

# Parse the arguments
args = parser.parse_args()

# Print the arguments
print("data_dir: ", args.data_dir)
print("samplesheet: ", args.samplesheet)

samplesheet = pd.read_csv(args.samplesheet, header=0)

dfs = []
for index, row in samplesheet.iterrows():
    file_path = os.path.basename(row['file'])
    file_path = os.path.join(args.data_dir, file_path)
    print(f"Loading {file_path}")
    
    # Read the TSV file into a dataframe
    df = pd.read_csv(file_path, sep="\t", header=0)
    
    # Get metadata
    subject_id = row['subject_id']
    timepoint = row['timepoint']
    origin = row['origin']
        
    # Add patient column
    df['patient'] = f"{subject_id}:{timepoint}_{origin}"
    df['sample'] = row['sample']
    
    # Select relevant columns
    df = df[['aminoAcid', 'vGeneName', 'jGeneName', 'patient', 'count (templates/reads)', 'sample']]
    dfs.append(df)


# Concatenate all the dataframes into one
df_combined = pd.concat(dfs)

# Rename columns as required
df_combined = df_combined.rename(columns={
    'aminoAcid': 'CDR3b',
    'vGeneName': 'TRBV',
    'jGeneName': 'TRBJ',
    'count (templates/reads)': 'counts'
})
df_combined = df_combined[df_combined['CDR3b'].notna()]

df_combined.to_csv(f"concatenated_cdr3.txt", sep="\t", index=False, header=True)
