process OLGA {
    tag "${sample_meta[0]}"
    label 'process_low'
    container "ghcr.io/break-through-cancer/bulktcr:latest"
    
    input:
    tuple val(sample_meta), path(count_table)
    
    output:
    path "${count_table.baseName}_tcr_generation_probabilities.tsv", emit: "olga_output"
    
    script:
    """
    # Extract vector of cdr3 aa, dropping null values
    
    cat > dropAA.py <<EOF
    
    import pandas as pd
    
    df = pd.read_csv("${count_table}", sep="\t")
    df = df.dropna(subset=["aminoAcid"])
    df = df["aminoAcid"]
    df.to_csv("output.tsv", sep="\t", index=False, header=False)
    
    EOF
    
    python dropAA.py
    
    olga-compute_pgen --humanTRB -i output.tsv -o "${count_table.baseName}_tcr_generation_probabilities.tsv"
    """
}
