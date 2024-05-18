process GLIPH2 {
    // tag "${sample_utf8}"
    label 'process_single'

    // beforeScript 'export DOCKER_OPTS="-v $${params.data_dir}:$${params.data_dir}"'

    container "domebraccia/bulktcr:1.0"

    input:
    path samplesheet_utf8
    path demo_folder

    output:
    path 'gliph2_output.csv', emit: 'gliph2_output'

    script:
    """
    #!/bin/bash

    # Testing
    echo "Running GLIPH2"
    ls -l $samplesheet_utf8
    ls -l $demo_folder/demo.cfg
    touch gliph2_output.csv
    
    # =============================================== #

    # Actually Run GLIPH2
    cd $demo_folder
    /opt/gliph2/irtools -c demo.cfg
    """

}