// process to plot sample level statistics
process PLOT_SAMPLE {
    tag "${sample_stats_csv}"
    label 'plot_sample'

    container "domebraccia/bulktcr:1.0"

    publishDir "${params.output}/${params.project_name}/sample/", mode: "copy", overwrite: "true"
    
    input:
    path sample_table
    path sample_stats_template
    path sample_stats_csv
    path v_family_csv

    output:
    path 'sample_stats.html'

    script:    
    """
    ## copy quarto notebook to output directory
    cp $sample_stats_template sample_stats.qmd

    ## render qmd report to html
    quarto render sample_stats.qmd \
        -P project_name:$params.project_name \
        -P workflow_cmd:'$workflow.commandLine' \
        -P project_dir:$projectDir \
        -P sample_table:$sample_table \
        -P sample_stats_csv:$sample_stats_csv \
        -P v_family_csv:$v_family_csv \
        --to html
    """

    stub:
    """
    echo "1"
    """
    
    }