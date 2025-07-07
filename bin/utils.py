#!/usr/bin/env python3

"""
Description: utility functions for plotting simple TCR repertoire statistics

Authors: Domenick Braccia
"""

## import packages
import time
import pandas as pd
import matplotlib.pyplot as plt
import seaborn as sns
from scipy.spatial import distance

def TicTocGenerator():
    # Generator that returns time differences
    ti = 0           # initial time
    tf = time.time() # final time
    while True:
        ti = tf
        tf = time.time()
        yield tf-ti # returns the time difference

TicToc = TicTocGenerator() # create an instance of the TicTocGen generator

# This will be the main function through which we define both tic() and toc()
def toc(tempBool=True):
    # Prints the time difference yielded by generator instance TicToc
    tempTimeInterval = next(TicToc)
    if tempBool:
        print( "Elapsed time: %f seconds.\n" %tempTimeInterval )

def tic():
    # Records a time in TicToc, marks the beginning of a time interval
    toc(False)

# Defining sample comparison functions
def jaccard_index(sample1, sample2):
    set1 = set(sample1)
    set2 = set(sample2)
    intersection = len(set1.intersection(set2))
    union = len(set1.union(set2))
    return intersection / union

def sorensen_index(sample1, sample2):
    set1 = set(sample1)
    set2 = set(sample2)
    intersection = len(set1.intersection(set2))
    return 2 * intersection / (len(set1) + len(set2))

def morisita_horn_index(dfs, sample1, sample2):
    # create sets of amino acid sequences
    set1 = set(dfs[sample1]['junction_aa'])
    set2 = set(dfs[sample2]['junction_aa'])

    # identify union of sets
    union = set1.union(set2)

    # get counts of aa sequences in sample1 and sample2
    df1 = dfs[sample1].groupby('junction_aa')['duplicate_count'].sum().reindex(union).fillna(0)
    df2 = dfs[sample2].groupby('junction_aa')['duplicate_count'].sum().reindex(union).fillna(0)
    n1i = df1.values
    n2i = df2.values

    # calculate product of counts
    products = n1i * n2i

    # calculate simpson index values for sample1 and sample2
    print(type(df1))
    X = df1.sum()
    Y = df2.sum()

    s1_si = sum(count**2 for count in df1)/(X**2)
    s2_si = sum(count**2 for count in df2)/(Y**2)

    numerator = 2 * sum(products)
    denominator = (s1_si + s2_si) * (X * Y)
    return numerator / denominator

def jensen_shannon_distance(sample1, sample2):
    # Merge the two samples based on junction_aa column
    merged = pd.merge(sample1, sample2, on='junction_aa', how='outer', suffixes=('_1', '_2')).fillna(0)
    # Enter probability distributions into the distance function
    return distance.jensenshannon(merged['duplicate_count_1'], merged['duplicate_count_2'])