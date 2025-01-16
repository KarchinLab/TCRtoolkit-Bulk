process GLIPH2 {

    label 'process_single'
    publishDir "${params.output}/gliph2_output", mode: 'copy'
    container "domebraccia/bulktcr:1.0"

    cpus 32
    memory 64.GB

    input:
    path samplesheet_utf8
    path data_folder
    path ref_files
    val project_name
    val local_min_pvalue
    val p_depth
    val global_convergence_cutoff
    val simulation_depth
    val kmer_min_depth
    val local_min_OVE
    val algorithm
    val all_aa_interchangeable

    output:
    path "${params.project_name}_cluster.csv", emit: 'clusters'
    path "${params.project_name}_cluster.txt", emit: 'cluster_stats'

    script:
    """
    
    # 1. Prep _tcr.txt file
    prep_gliph2_tcr.py $data_folder $project_name $samplesheet_utf8

    # 2. Write the config file
    echo "# GLIPH2 configuration file
    out_prefix=$project_name
    cdr3_file=${project_name}_tcr.txt
    refer_file=ref_CD4.txt
    v_usage_freq_file=ref_V_CD4.txt
    cdr3_length_freq_file=ref_L_CD4.txt
    local_min_pvalue=$local_min_pvalue
    p_depth = $p_depth
    global_convergence_cutoff = $global_convergence_cutoff
    simulation_depth=$simulation_depth
    kmer_min_depth=$kmer_min_depth
    local_min_OVE=$local_min_OVE
    algorithm=$algorithm
    all_aa_interchangeable=$all_aa_interchangeable" > ${project_name}.cfg

    # 3. If hla_file file exists, add it to cfg file
    #if [ -f hla_file ]; then
    #    echo "hla_file=${project_name}_hla.txt" >> ${project_name}.cfg
    #fi

    # 4. Move necessary files to data_folder
    #cp ${project_name}_tcr.txt $data_folder
    cp $ref_files/ref* .
    
    # 5. Run GLIPH2
    #cd $data_folder
    /opt/gliph2/irtools -c ${project_name}.cfg
    """

}