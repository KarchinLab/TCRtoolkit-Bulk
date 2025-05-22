#!/usr/bin/env python

import argparse
import pandas as pd

# do any processing of the samplesheet here
def samplesheet(samplesheet, data_dir):
    ss = pd.read_csv(samplesheet, sep=',')
    ss.to_csv('samplesheet_utf8.csv', index=False, encoding='utf-8-sig')
    
    stats = ss.describe()
    stats.to_csv('samplesheet_stats.csv', index=False, encoding='utf-8-sig')
    
    print(ss.head())

def main():
    # initialize parser
    parser = argparse.ArgumentParser()
    parser.add_argument('-s', '--samplesheet', 
                        metavar='samplesheet', 
                        type=str, 
                        help='sample metadata passed in through samples CSV file')

    parser.add_argument('-d', '--data_dir',
                        metavar='data_dir',
                        type=str,
                        help='path to data directory')

    args = parser.parse_args()

    samplesheet(args.samplesheet, args.data_dir)

if __name__ == "__main__":
    main()