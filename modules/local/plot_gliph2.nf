process PLOT_GLIPH2 {
    
    // tag "${}"
    label 'process_single'
    container "ghcr.io/break-through-cancer/bulktcr:latest"
    publishDir "${params.output}/reports/", mode: "copy", overwrite: "true"

    input:
    path gliph2_report_template
    path clusters
    path cluster_stats

    output:
    path 'gliph2_report.html'

    script:   
    """
    ## copy quarto notebook to output directory
    cp $gliph2_report_template gliph2_report.qmd

    ## render qmd report to html
    quarto render gliph2_report.qmd \
        -P project_name:$params.project_name \
        -P workflow_cmd:'$workflow.commandLine' \
        -P project_dir:$projectDir \
        -P clusters:$clusters \
        -P cluster_stats:$cluster_stats \
        --to html
    """
    
    }
