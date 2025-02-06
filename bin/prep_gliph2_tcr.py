#!/usr/bin/env python3

"""
prep_gliph2_tcr.py
Input: adaptive TSV files
Output: ${project_name}_tcr.txt
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
parser.add_argument("project_name")
parser.add_argument("samplesheet")

# Parse the arguments
args = parser.parse_args()

# Print the arguments
print("data_dir: ", args.data_dir)
print("project_name: ", args.project_name)
print("samplesheet: ", args.samplesheet)

samplesheet = pd.read_csv(args.samplesheet, header=0)
data_dir = args.data_dir + "/"
tsv_files = glob.glob(os.path.join(data_dir, "*.tsv"))

# Load each file as element in dictionary
tsv_dict = {}
for file in tsv_files:
    # read each tsv into entry of a dictionary
    tsv_dict[file] = pd.read_csv(file, sep="\t", header=0)
    
    # add a column to current df tsv_dict[file] with sample_id from samplesheet
    subject_id = samplesheet.loc[samplesheet.file == file]['subject_id']
    condition = samplesheet.loc[samplesheet.file == file]['sample']
    tsv_dict[file]['subject:condition'] = subject_id + ':' + condition
    

# Concatenate all dataframes in dictionary
df = pd.concat(tsv_dict.values())
df['CDR3a'] = 'NA'
df = df[['aminoAcid', 'vGeneName', 'jGeneName', 'CDR3a', 'subject:condition', 'count (templates/reads)']]

# Rename columns
df = df.rename(columns={'aminoAcid': 'CDR3b', 
                        'vGeneName': 'TRBV',
                        'jGeneName': 'TRBJ',
                        # 'HLA_column_name': 'HLA', if hla_file input exists, incorporate it here
                        'subject:condition': 'patient',
                        'count (templates/reads)': 'counts'})

# Filter out rows of the df with missing CDR3b values
df = df[df['CDR3b'].notna()]

# Write df to csv with the name ${project_name}_tcr.txt
df.to_csv(args.project_name + "_tcr.txt", sep="\t", index=False, header=False)

