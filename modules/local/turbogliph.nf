process TURBO_GLIPH2 {
    label 'process_single'
    publishDir "${params.output}/turbo_gliph2", mode: 'copy'
    container "ghcr.io/break-through-cancer/bulktcr:latest"

    cpus 4
    memory 8.GB

    input:
    // path processed_samplesheet
    path samplesheet_utf8
    path data_folder
    val project_name

    output:
    path "all_motifs.csv", emit: 'all_motifs'
    path "clone_network.csv", emit: 'clone_network'
    path "cluster_member_details.csv", emit: 'cluster_member_details'
    path "convergence_groups.csv", emit: 'convergence_groups'
    path "global_similarities.csv", emit: 'global_similarities'
    path "local_similarities.csv", emit: 'local_similarities'
    path "parameter.txt", emit: 'parameters'
    
    script:
    """
    # Prep _tcr.txt file
    prep_gliph2_tcr.py $data_folder $project_name $samplesheet_utf8

    # R script starts here
    cat > run_gliph2.R <<EOF
    #!/usr/bin/env Rscript

    library(turboGliph)

    df <- read.csv("${project_name}_tcr.txt", sep = "\t", stringsAsFactors = FALSE, check.names = FALSE)

    result <- turboGliph::gliph2(
        cdr3_sequences = df,
        result_folder = "./",
        lcminp = ${params.local_min_pvalue},
        sim_depth = ${params.simulation_depth},
        kmer_mindepth = ${params.kmer_min_depth},
        lcminove = ${params.local_min_OVE},
        all_aa_interchangeable = FALSE,
        n_cores = ${task.cpus}
    )
    EOF

    # Run the R script
    Rscript run_gliph2.R

    # Convert the tab-separated .txt file to .csv file
    cat all_motifs.txt | sed 's/\t/,/g' > all_motifs.csv
    cat clone_network.txt | sed 's/\t/,/g' > clone_network.csv
    cat cluster_member_details.txt | sed 's/\t/,/g' > cluster_member_details.csv
    cat convergence_groups.txt | sed 's/\t/,/g' > convergence_groups.csv
    cat global_similarities.txt | sed 's/\t/,/g' > global_similarities.csv

    input_file="local_similarities_*.txt"
    cat \$input_file | sed 's/\t/,/g' > local_similarities.csv
    """
}