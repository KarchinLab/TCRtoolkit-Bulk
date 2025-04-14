#!/usr/bin/env python3

import argparse
import os
import re

import numpy as np
import pandas as pd
from tcrdist.repertoire import TCRrep

def transform_trbv(trbv):
    """Convert TCRBV notation back to TRBV format, remove zero padding before *, and handle /OR cases."""
    if not isinstance(trbv, str):
        return trbv  # Return as-is if not a string
    
    trbv = trbv.replace("TCRBV", "TRBV")  # Convert TCRBV → TRBV
    
    # Remove zero padding from main number (TCRBV07 → TRBV7)
    trbv = re.sub(r'(?<=TRBV)0*(\d+)', r'\1', trbv)  
    
    # Remove zero padding from subgroup (TCRBV7-02 → TRBV7-2)
    trbv = re.sub(r'-(0\d+)', lambda m: f'-{int(m.group(1))}', trbv)  
    
    # Convert "-orXX_XX" format back to "/OR#-#"
    trbv = re.sub(r'-or0?(\d+)_0?(\d+)', r'/OR\1-\2', trbv)
    
    # Add *01 if allele group not specified
    if not re.search(r'\*\d{2}$', trbv):
        trbv += "*01"
    
    return trbv

def remove_locus(gene_name):
    """If gene is in TCRBVXX-##*0# format, try removing the -##."""
    return re.sub(r'-(\d+)\*', '*', gene_name)

def split_and_check_genes(gene_name):
    """Handle cases where two genes are combined (TCRBVXX-YY/XX-ZZ*0#) and return both separately."""
    if '/' in gene_name and not re.search(r'/OR\d+-\d+', gene_name):  # Ensure it's not an OR case
        base, star_part = gene_name.split("*") if "*" in gene_name else (gene_name, "01")  
        genes = base.split("/")  # Split the genes
        return [f"{g}*{star_part}" for g in genes]  # Reattach the *0# part to both genes
    return [gene_name]  # Return as list for consistency

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
