process TURBO_GLIPH2 {

    label 'process_single'
    publishDir "${params.output}/turbo_gliph2", mode: 'copy'
    container "ghcr.io/break-through-cancer/bulktcr:latest"

    cpus 4
    memory 8.GB

    input:
    path processed_samplesheet

    output:
    path "all_motifs.csv", emit: 'all_motifs'
    path "selected_motifs.csv", emit: 'selected_motifs'
    path "global_enrichment.csv", emit: 'global_enrichment'
    path "connections.csv", emit: 'connections'
    path "cluster_properties.csv", emit: 'cluster_properties'
    path "cluster_list.csv", emit: 'cluster_list'
    path "parameters.txt", emit: 'parameters'

    script:
    """
    #!/usr/bin/env Rscript

    library(turboGliph)

    df <- read.csv("$processed_samplesheet", sep = '\t', stringsAsFactors = FALSE, check.names = FALSE)

    result <- turboGliph::gliph2(
        cdr3_sequences = df,
        lcminp = ${params.local_min_pvalue},
        p_depth = ${params.p_depth},
        global_convergence_cutoff = ${params.global_convergence_cutoff},
        sim_depth = ${params.simulation_depth},
        kmer_mindepth = ${params.kmer_min_depth},
        lcminove = ${params.local_min_OVE},
        all_aa_interchangeable = FALSE,
        n_cores = ${task.cpus}
    )

    write.csv(result[["motif_enrichment"]][["all_motifs"]], "all_motifs.csv", row.names = FALSE)
    write.csv(result[["motif_enrichment"]][["selected_motifs"]], "selected_motifs.csv", row.names = FALSE)
    write.csv(result[["global_enrichment"]], "global_enrichment.csv", row.names = FALSE)
    write.csv(result[["connections"]], "connections.csv", row.names = FALSE)
    write.csv(result[["cluster_properties"]], "cluster_properties.csv", row.names = FALSE)
    write.csv(result[["cluster_list"]], "cluster_list.csv", row.names = FALSE)
    write.table(result[["parameters"]], "parameters.txt", sep = "\t", row.names = FALSE, quote = FALSE, stringsAsFactors = FALSE)

    """

}
