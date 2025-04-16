process GLIPH2_TURBOGLIPH {
    label 'process_high'
    label 'process_high_compute'
    label 'process_high_memory'
    container "ghcr.io/break-through-cancer/bulktcr:latest"

    input:
    path concat_cdr3

    output:
    path "all_motifs.txt", emit: 'all_motifs'
    path "clone_network.txt", emit: 'clone_network'
    path "cluster_member_details.txt", emit: 'cluster_member_details'
    path "convergence_groups.txt", emit: 'convergence_groups'
    path "global_similarities.txt", emit: 'global_similarities'
    path "local_similarities.txt", emit: 'local_similarities'
    path "parameter.txt", emit: 'gliph2_parameters'
    
    script:
    """
    # R script starts here
    cat > run_gliph2.R <<EOF
    #!/usr/bin/env Rscript

    library(turboGliph)

    # During testing, including TRBJ column was causing issues in clustering step. Removing and reinserting afterwards.
    df <- read.csv("$concat_cdr3", sep = "\t", stringsAsFactors = FALSE, check.names = FALSE)
    df2 <- subset(df, select = c('CDR3b', 'TRBV', 'patient', 'counts'))

    result <- turboGliph::gliph2(
        cdr3_sequences = df2,
        result_folder = "./",
        lcminp = ${params.local_min_pvalue},
        sim_depth = ${params.simulation_depth},
        kmer_mindepth = ${params.kmer_min_depth},
        lcminove = ${params.local_min_OVE},
        all_aa_interchangeable = FALSE,
        n_cores = ${task.cpus}
    )
    
    df3 <- read.csv('cluster_member_details.txt', sep = '\t', stringsAsFactors = FALSE, check.names = FALSE)
    df3 <- merge(df3, df[, c("CDR3b", "TRBV", "patient", "TRBJ", 'counts')], by = c("CDR3b", "TRBV", "patient", 'counts'), all.x = TRUE)
    write.table(df3, "cluster_member_details.txt", sep = "\t", row.names = FALSE, quote = FALSE)

    EOF

    # Run the R script
    Rscript run_gliph2.R

    # Convert the tab-separated .txt file to .csv file
    # cat all_motifs.txt | sed 's/\t/,/g' > all_motifs.csv
    # cat clone_network.txt | sed 's/\t/,/g' > clone_network.csv
    # cat cluster_member_details.txt | sed 's/\t/,/g' > cluster_member_details.csv
    # cat convergence_groups.txt | sed 's/\t/,/g' > convergence_groups.csv
    # cat global_similarities.txt | sed 's/\t/,/g' > global_similarities.csv

    # Rename local_similarities file to standardize output name
    input_file="local_similarities_*.txt"
    cat \$input_file > local_similarities.txt
    """
}