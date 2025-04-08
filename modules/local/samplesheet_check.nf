process SAMPLESHEET_CHECK {
    tag "${samplesheet}"
    label 'process_single'
    container "ghcr.io/break-through-cancer/bulktcr:latest"

    input:
    path samplesheet

    output:
    path 'samplesheet_utf8.csv'    , emit: samplesheet_utf8
    path 'samplesheet_stats.txt'

    script: 
    """
    #!/bin/bash
    
    iconv -t utf-8 $samplesheet > samplesheet_utf8.csv

    csvstat samplesheet_utf8.csv > samplesheet_stats.txt
    """

    stub:
    """
    #!/bin/bash

    touch samplesheet_utf8.csv
    touch samplesheet_stats.txt
    """
}
