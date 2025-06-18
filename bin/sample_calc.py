#!/usr/bin/env python3
"""
Description: this script calculates the clonality of a TCR repertoire

@author: Domenick Braccia
@contributor: elhanaty
"""

## import packages
import argparse
import pandas as pd
import numpy as np
from scipy.stats import entropy
import numpy as np
import csv
import re

def calc_sample_stats(sample_meta, counts):
    """Calculate sample level statistics of TCR repertoire."""

    ## first pass stats
    clone_counts = counts['duplicate_count']
    clone_entropy = entropy(clone_counts, base=2)
    num_clones = len(clone_counts)
    num_TCRs = sum(clone_counts)
    clonality = 1 - clone_entropy / np.log2(num_clones)
    simpson_index = sum(clone_counts**2)/(num_TCRs**2)
    simpson_index_corrected = sum(clone_counts*(clone_counts-1))/(num_TCRs*(num_TCRs-1))

    ## tcr productivity stats
    def tf_to_bool(val):
        return {"T": True, "F": False}.get(val, val)

    counts["productive"] = counts["productive"].map(tf_to_bool)

    # count number of productive clones
    num_prod = sum(counts['productive'])
    num_nonprod = num_clones - num_prod
    pct_prod = num_prod / num_clones
    pct_nonprod = num_nonprod / num_clones

    ## cdr3 info
    cdr3_lens = counts['junction_aa_length']
    productive_cdr3_avg_len = np.mean([x*3 for x in cdr3_lens if x > 0])

    ## Calculate convergence for each T cell receptor
    aas = counts[counts.junction_aa.notnull()].junction_aa.unique()
    dict_df = {}
    for aa in aas:
        dict_df[aa] = {'counts': counts[counts.junction_aa == aa]}
        # append key value pair to dict_df[aa] with key convergence equal to the number of rows in counts
        dict_df[aa]['convergence'] = len(counts[counts.junction_aa == aa])

    ## calculate the number of covergent TCRs for each sample
    num_convergent = 0
    for aa in aas:
        if dict_df[aa]['convergence'] > 1:
            num_convergent += 1    

    ## calculate ratio of convergent TCRs to total TCRs
    ratio_convergent = num_convergent/len(aas)

    ## add in patient meta_data such as responder status to sample_stats.csv
    # read in metadata file
    # meta_data = pd.read_csv(args.meta_data, sep=',', header=0)

    # filter out metadata for the current sample
    # current_meta = meta_data[meta_data['patient_id'] == sample_meta[1]]

    # write above values to csv file
    with open('sample_stats.csv', 'w') as csvfile:
        writer = csv.writer(csvfile)
        writer.writerow([sample_meta[0], sample_meta[1], sample_meta[2], sample_meta[3],
                         num_clones, num_TCRs, simpson_index, simpson_index_corrected, clonality,
                         num_prod, num_nonprod, pct_prod, pct_nonprod,
                         productive_cdr3_avg_len, num_convergent, ratio_convergent])

    # store v_family gene usage in a dataframe
    def extract_trb_family(allele):
        if pd.isna(allele):
            return None
        match = re.match(r'(TRB[V|D|J])(\d+)', allele)
        return f"{match.group(1)}{match.group(2)}" if match else None

    # Apply to each column
    counts['vFamilyName'] = counts['v_call'].apply(extract_trb_family)
    counts['dFamilyName'] = counts['d_call'].apply(extract_trb_family)
    counts['jFamilyName'] = counts['j_call'].apply(extract_trb_family)

    # Compute gene usage frequency per family
    v_family = counts['vFamilyName'].value_counts(dropna=False).to_frame().T.sort_index(axis=1)
    d_family = counts['dFamilyName'].value_counts(dropna=False).to_frame().T.sort_index(axis=1)
    j_family = counts['jFamilyName'].value_counts(dropna=False).to_frame().T.sort_index(axis=1)

    # generate a list of all possible columns names from TCRBV01-TCRBV30
    all_v_fam = [f'TRBV{i}' for i in range(1, 31)]

    # generate a list of all possible columns names from TCRBD01-TCRBD02
    all_d_fam = [f'TRBD{i}' for i in range(1, 3)]

    # generate a list of all possible columns names from TCRBJ01-TCRBJ02
    all_j_fam = [f'TRBJ{i}' for i in range(1, 3)]

    # add missing columns to v_family dataframe by reindexing
    v_family_reindex = v_family.reindex(columns=all_v_fam, fill_value=0)
    d_family_reindex = d_family.reindex(columns=all_d_fam, fill_value=0)
    j_family_reindex = j_family.reindex(columns=all_j_fam, fill_value=0)

    # add sample_meta columns to v_family_reindex and make them the first three columns
    v_family_reindex.insert(0, 'origin', sample_meta[3])
    v_family_reindex.insert(0, 'timepoint', sample_meta[2])
    v_family_reindex.insert(0, 'patient_id', sample_meta[1])
    d_family_reindex.insert(0, 'origin', sample_meta[3])
    d_family_reindex.insert(0, 'timepoint', sample_meta[2])
    d_family_reindex.insert(0, 'patient_id', sample_meta[1])
    j_family_reindex.insert(0, 'origin', sample_meta[3])
    j_family_reindex.insert(0, 'timepoint', sample_meta[2])
    j_family_reindex.insert(0, 'patient_id', sample_meta[1])

    # Write v_family_reindex to csv file with no header and no index
    v_family_reindex.to_csv('v_family.csv', header=False, index=False)
    d_family_reindex.to_csv('d_family.csv', header=False, index=False)
    j_family_reindex.to_csv('j_family.csv', header=False, index=False)

    # # store dictionaries in a list and output to pickle file
    # gene_usage = [v_family, d_family, j_family]     ## excluding v_genes, d_genes, j_genes
    # with open('gene_usage_' + str(metadata[1] + '_' + str(metadata[2] + '_' + str(metadata[3]))) + '.pkl', 'wb') as f:
    #     pickle.dump(gene_usage, f)

def main():
    # initialize parser
    parser = argparse.ArgumentParser(description='Calculate clonality of a TCR repertoire')

    # add arguments
    parser.add_argument('-s', '--sample_meta', 
                        metavar='sample_meta', 
                        type=str, 
                        help='sample metadata passed in through samples CSV file')
    parser.add_argument('-c', '--count_table', 
                        metavar='count_table', 
                        type=argparse.FileType('r'), 
                        help='counts file in TSV format')

    args = parser.parse_args() 

    ## convert metadata to list
    sample_meta = args.sample_meta[1:-1].split(', ')

    # Read in the counts file
    counts = pd.read_csv(args.count_table, sep='\t', header=0)

    calc_sample_stats(sample_meta, counts)

if __name__ == "__main__":
    main()