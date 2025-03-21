process GLIPH2_PLOT {
    label 'process_single'
    container "ghcr.io/break-through-cancer/bulktcr:latest"

    input:
    path gliph2_report_template
    path cluster_member_details
    path convergence_groups

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
        -P clusters:$cluster_member_details \
        -P cluster_stats:$convergence_groups \
        --to html
    """
}
