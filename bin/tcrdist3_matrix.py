#!/usr/bin/env python3

import argparse
import os
import re

import numpy as np
import pandas as pd
from tcrdist.repertoire import TCRrep

def transform_trbv(trbv):
    """Convert gene names from Adaptive ImmunoSEQ to IMGT format."""
    if not isinstance(trbv, str):
        return trbv  # Return as-is if not a string
    
    # Convert locus name
    trbv = trbv.replace("TCRBV", "TRBV")
    
    # Remove zero padding from gene name (TCRBV07 to TRBV7)
    trbv = re.sub(r'(?<=TRBV)0*(\d+)', r'\1', trbv)  
    
    # Remove zero padding from subgroup (TCRBV7-02 to TRBV7-2)
    trbv = re.sub(r'-(0\d+)', lambda m: f'-{int(m.group(1))}', trbv)  
    
    # Convert "-orXX_XX" to "/OR#-#" for orphon genes
    trbv = re.sub(r'-or0?(\d+)_0?(\d+)', r'/OR\1-\2', trbv)
    
    # Add *01 if allele group not specified
    if not re.search(r'\*\d{2}$', trbv):
        trbv += "*01"
    
    return trbv

def remove_locus(gene_name):
    """Remove the -## gene position from TRBV names unless the gene contains /OR."""
    if '/OR' in gene_name:
        return gene_name
    else:
        return re.sub(r'-(\d+)\*', '*', gene_name)

def split_and_check_genes(gene_name):
    """Split combined TCRBV genes (e.g., TCRBV06-02/06-03*01 to TCRBV06-02*01 and TCRBV06-03*01."""
    if '/' in gene_name and not re.search(r'/OR\d+-\d+', gene_name):  # Ensure it's not an orphon
        base, allele = gene_name.split("*") if "*" in gene_name else (gene_name, "01")
        prefix_match = re.match(r"(TCRBV\d+)", gene_name)
        prefix = prefix_match.group(1) if prefix_match else "TCRBV"  # Fallback just in case
        genes = base.split("/")  # Split the genes
        return [f"{prefix}-{g.split('-')[-1]}*{allele}" for g in genes]
    return [gene_name]

split_and_check_genes("TCRBV06-02/06-03*01")

def test_cases():
    test_cases = [
        ("TCRBV07", "TRBV7*01", "TRBV7*01"),
        ("TCRBV27", "TRBV27*01", "TRBV27*01"),
        ("TCRBV07-02", "TRBV7-2*01", "TRBV7*01"),
        ("TCRBV17-02", "TRBV17-2*01", "TRBV17*01"),
        ("TCRBV10-03*02", "TRBV10-3*02", "TRBV10*02"),
        ("TCRBV07-02*01", "TRBV7-2*01", "TRBV7*01"),
        ("TCRBV10-or09_02*01", "TRBV10/OR9-2*01", "TRBV10/OR9-2*01"),
    ]
    
    print("Testing transform_trbv:")
    for trbv_input, transform_trbv_output, remove_locus_output in test_cases:
        result = transform_trbv(trbv_input)
        print(f"Input: {trbv_input} | Expected: {transform_trbv_output} | Result: {result}")
        assert result == transform_trbv_output, f"Test failed for {trbv_input}"
    
    print("Testing remove_locus:")
    for trbv_input, transform_trbv_output, remove_locus_output in test_cases:
        result2 = remove_locus(transform_trbv_output)
        print(f"Input: {transform_trbv_output} | Expected: {remove_locus_output} | Result: {result2}")
        assert result2 == remove_locus_output, f"Test failed for {transform_trbv_output}"
    
    split_cases = [
        ("TCRBV06-02/06-03*01", ["TCRBV06-02*01", "TCRBV06-03*01"]),
        ("TCRBV12-03/12-04", ["TCRBV12-03*01","TCRBV12-04*01"])
    ]
    print("Testing split_and_check_genes:")
    for split_input, split_output, in split_cases:
        result3 = split_and_check_genes(split_input)
        print(f"Input: {split_input} | Expected: {split_output} | Result: {result3}")
        assert result3 == split_output, f"Test failed for {split_input}"

test_cases()

def find_matching_gene(row, db):
    # Collect all possible genes from vMaxResolved and vGeneNameTies
    possible_genes = set()  # Use a set to avoid duplicates
    
    if pd.notna(row["vMaxResolved"]):
        possible_genes.add(row["vMaxResolved"])  # Always include vMaxResolved
    
    if pd.notna(row["vGeneNameTies"]):
        possible_genes.update(row["vGeneNameTies"].split(","))  # Add vGeneNameTies genes
    
    for gene in possible_genes:
        # If the gene contains multiple variants (e.g., TCRBV03-01/03-02*01), split and check both
        if "/" in gene and not re.search(r"/OR\d+-\d+", gene):  # Avoid /OR cases
            sub_genes = split_and_check_genes(gene)
            for sub_gene in sub_genes:
                sub_gene = transform_trbv(sub_gene)  # Ensure correct *0# format
                if sub_gene in db["id"].values:
                    return sub_gene
        
        # Direct match in db
        transform_gene = transform_trbv(gene)
        if transform_gene in db["id"].values:
            return transform_gene
        
        # Try removing -## and checking again
        modified_gene = remove_locus(transform_gene)
        if modified_gene in db["id"].values:
            return modified_gene
        
    transform_row = transform_trbv(row["vMaxResolved"])
    print(f'No match found for {transform_row}')
    
    return transform_row  # Return original vMaxResolved if no match is found

# Parse input arguments
parser = argparse.ArgumentParser(description="Take positional args")

parser.add_argument("sample_tsv")
parser.add_argument("ref_database")
parser.add_argument("cores", type=int)

args = parser.parse_args()

print(f"sample_tsv: {args.sample_tsv}")
print(f"ref_database: {args.ref_database}")
print(f"cores: {args.cores}")

sample_tsv = args.sample_tsv

# Get the basename
basename = os.path.splitext(os.path.basename(sample_tsv))[0]

# --- 1. Convert Adaptive output to tcrdist db format ---
db = pd.read_table(args.ref_database, delimiter = '\t')

db = db[db['organism']=='human']

df = pd.read_table(sample_tsv, delimiter = '\t')

df = df[['nucleotide', 'aminoAcid', 'vMaxResolved', 'vGeneNameTies', 'count (templates/reads)']]
df["vMaxResolved"] = df.apply(lambda row: find_matching_gene(row, db), axis=1)

df = df.rename(columns={'nucleotide': 'cdr3_b_nucseq',
                    'aminoAcid': 'cdr3_b_aa',
                    # 'CDR3a': 'cdr3_a_aa', 
                    'vMaxResolved': 'v_b_gene',
                    # 'TRBJ': 'j_b_gene',
                    'count (templates/reads)': 'count'})

df = df[df['cdr3_b_aa'].notna()]
df = df[df['v_b_gene'].notna()]
df = df.drop('vGeneNameTies', axis=1)

# --- 2. Calculate sparse distance matrix ---
tr = TCRrep(cell_df = df,
            organism = 'human',
            chains = ['beta'],
            db_file = 'alphabeta_gammadelta_db.tsv',
            compute_distances = False)
tr.cpus = args.cores
tr.compute_distances()

np.savetxt(f"{basename}_distance_matrix.csv", tr.pw_beta, delimiter=",", fmt="%d")

clone_df = tr.clone_df
clone_df.to_csv(f"{basename}_clone_df.csv", index=False)
