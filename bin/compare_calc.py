#!/usr/bin/env python3
"""
Description: this script calculates overlap measures between TCR repertoires

@author: Domenick Braccia
"""

import argparse
import pandas as pd
import numpy as np
import os
import sys
import csv
from scipy.stats import entropy
from utils import jaccard_index, sorensen_index, morisita_horn_index #, jensen_shannon_distance

print('-- ENTERED compare_calc.py--')
print('-- THE TIME IS: --' + str(pd.Timestamp.now()))

# initialize parser
parser = argparse.ArgumentParser(description='Calculate clonality of a TCR repertoire')

# add arguments
parser.add_argument('-s', '--sample_utf8', 
                    metavar='sample_utf8', 
                    type=str, 
                    help='sample CSV file initially passed to nextflow run command')
# parser.add_argument('-m', '--meta_data',
#                     metavar='meta_data',
#                     type=str,
#                     help='metadata CSV file initially passed to nextflow run command')

args = parser.parse_args() 

## Read in sample table CSV file
## convert metadata to list
s = args.sample_utf8
sample_utf8 = pd.read_csv(args.sample_utf8, sep=',', header=0)
print('sample_utf8 looks like this: ' + str(sample_utf8))
print('sample_utf8 columns: \n')
print(sample_utf8.columns)

# Read in metadata table CSV file
# meta_data = pd.read_csv(args.meta_data, sep=',', header=0)
# print('meta_data looks like this: ' + str(meta_data))
# print('meta_data columns: \n')
# print(meta_data.columns)

# Import TCR count tables into dictionary of dataframes
files = sample_utf8['file']
dfs = {}
for file in files:
    # load data
    df = pd.read_csv(file, sep='\t', header=0)
    dfs[file] = df

print('number of files in dfs: ' + str(len(dfs)))

## calculate the jaccard index between each sample pair in dfs and store in an nxn matrix and write to file
samples = list(dfs.keys())

print('- calculating jaccard index... -')
jaccard_mat = np.zeros((len(samples), len(samples)))
for i, sample1 in enumerate(samples):
    for j, sample2 in enumerate(samples):
        # calculate jaccard index
        value = jaccard_index(dfs[sample1]['junction_aa'], dfs[sample2]['junction_aa'])
        # store in numpy array
        jaccard_mat[i, j] = value

# define column and index names
sample_names= [os.path.basename(sample).split('.')[0] for sample in samples]
jaccard_df = pd.DataFrame(jaccard_mat, columns=sample_names, index=sample_names)

# save jacard_df to csv
jaccard_df.to_csv('jaccard_mat.csv', index=True, header=True)

## calculate the sorensen index between each sample pair in dfs and store in an nxn matrix and write to file
print('- calculating sorensen index... -')
sorensen_mat = np.zeros((len(samples), len(samples)))
for i, sample1 in enumerate(samples):
    for j, sample2 in enumerate(samples):
        # calculate sorensen index
        value = sorensen_index(dfs[sample1]['junction_aa'], dfs[sample2]['junction_aa'])
        # store in numpy array
        sorensen_mat[i, j] = value

# define column and index names
sorensen_df = pd.DataFrame(sorensen_mat, columns=sample_names, index=sample_names)

# save sorensen_df to csv
sorensen_df.to_csv('sorensen_mat.csv', index=True, header=True)

## calculate the morisita index between each sample pair in dfs and store in an nxn matrix and write to file
print('- calculating morisita index... -')
morisita_mat = np.zeros((len(samples), len(samples)))
for i in range(len(samples)):
    print('-- on sample ' + str(i) + ' --')
    for j in range(i+1):
        # calculate morisita index
        value = morisita_horn_index(dfs, samples[i], samples[j])
        # store in numpy array
        morisita_mat[i, j] = value

# Copy the lower triangle to the upper triangle
morisita_mat = morisita_mat + morisita_mat.T - np.diag(morisita_mat.diagonal())

# define column and index names
morisita_df = pd.DataFrame(morisita_mat, columns=sample_names, index=sample_names)

# save morisita_df to csv
morisita_df.to_csv('morisita_mat.csv', index=True, header=True)

## calculate jensen shannon distance between each sample pair in dfs and store in an nxn matrix and write to file
# print('- calculating jensen shannon distance... -')
# jsd_mat = np.zeros((len(samples), len(samples)))
# for i, sample1 in enumerate(samples):
#     for j, sample2 in enumerate(samples):
#         # calculate jensen shannon distance
#         value = jensen_shannon_distance(dfs[sample1][['junction_aa', 'duplicate_count']], dfs[sample2][['junction_aa', 'duplicate_count']])
#         # store in numpy array
#         jsd_mat[i, j] = value

# # Copy the lower triangle to the upper triangle
# jsd_mat = jsd_mat + jsd_mat.T - np.diag(jsd_mat.diagonal())

# # define column and index names
# jsd_df = pd.DataFrame(jsd_mat, columns=sample_names, index=sample_names)

# # save jsd_df to csv
# jsd_df.to_csv('jsd_mat.csv', index=True, header=True)

## ========================================================================== ##
