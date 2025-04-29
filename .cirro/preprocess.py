#!/usr/bin/env python3

from cirro.helpers.preprocess_dataset import PreprocessDataset
import pandas as pd
import numpy as np

# 1. Get parameters from cirro pipeline call
ds = PreprocessDataset.from_running()
ds.logger.info("List of starting params")
ds.logger.info(ds.params)

ds.logger.info('checking ds.files')
ds.logger.info(ds.files.head())
ds.logger.info(ds.files.columns)

# 2. Add samplesheet parameter and set equal to ds.samplesheet
ds.logger.info("Checking samplesheet parameter")
ds.logger.info(ds.samplesheet)
samplesheet = ds.samplesheet

ds.logger.info("Dropping incorrect file path & Merging ds.files w samplesheets")
samplesheet = samplesheet.drop(columns=['file'])
samplesheet2 = samplesheet.merge(ds.files, on='sample', how='left')

samplesheet2.to_csv('samplesheet.csv', index=None)
ds.add_param("samplesheet", "samplesheet.csv")


# 3. Set workflow_level value based on form input
ds.logger.info("Setting workflow_level")
if ds.params['sample_lvl'] == ds.params['compare_lvl'] == True:
    workflow_level = ['complete']
else:
    workflow_lvls = ['sample', 'compare']
    chosen_lvls = [ds.params['sample_lvl'], ds.params['compare_lvl']]
    workflow_level = [i for i, j in zip(workflow_lvls, chosen_lvls) if j]

ds.add_param('workflow_level', ','.join(workflow_level))

ds.logger.info(ds.params)

## 
