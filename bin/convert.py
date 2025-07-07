#!/usr/bin/env python3

import argparse
import json
import logging

import pandas as pd
from Bio.Seq import Seq

def configure_logging(args):
    """
    Configure logging based on the given arguments.
    """
    logger = logging.getLogger("convert")  # or use __name__ for module-level granularity

    ch = logging.StreamHandler()

    if args.verbose:
        logger.setLevel(logging.DEBUG)
        ch.setLevel(logging.DEBUG)
    else:
        logger.setLevel(logging.INFO)
        ch.setLevel(logging.INFO)

    formatter = logging.Formatter(
        "%(asctime)s - %(name)s - %(levelname)s - %(message)s"
    )
    ch.setFormatter(formatter)
    if not logger.hasHandlers():
        logger.addHandler(ch)

def add_logging_args(parser):
    parser.add_argument(
        "-v",
        "--verbose",
        default=False,
        action="store_true",
        help="Enable verbose logging",
    )

def derive_junction_fields(row):
    try:
        seq = row["nucleotide"]
        aa = row["aminoAcid"]
        start = row["vIndex"] - row["vDeletion"]
        end = row["jIndex"] + row["jDeletion"]
        junction = seq[start:end]

        best_frame = None
        for frame in range(3):
            try:
                translated = str(Seq(junction[frame:]).translate(to_stop=True))
                if translated == aa:
                    best_frame = frame
                    break
            except Exception:
                logger.exception(f"Error translating junction from frame {frame}")
                continue
        if best_frame is None:
            best_frame = 0

        full_aa = str(Seq(seq[best_frame:]).translate(to_stop=True))
        return pd.Series([seq, junction, aa, full_aa, best_frame])
    except Exception:
        logger.exception(f"Error deriving junction fields")
        return pd.Series(["", "", "", "", pd.NA])

def resolve_gene_call(gene_name, gene_allele, gene_name_ties, gene_allele_ties):
    # Step 1: Resolve GeneName
    if isinstance(gene_name, str) and gene_name.strip():
        name = gene_name.strip().split('/')[0]  # Pick first in case of tie like TCRBV03-01/03-02
    elif isinstance(gene_name_ties, str) and gene_name_ties.strip():
        name = gene_name_ties.strip().split(',')[0].split('/')[0]  # First in ties
    else:
        return None  # Cannot resolve gene name

    # Step 2: Resolve GeneAllele
    if isinstance(gene_allele, str) and gene_allele.strip():
        allele = gene_allele.strip()
    elif isinstance(gene_allele, (int, float)) and not pd.isna(gene_allele):
        allele = str(int(gene_allele)).zfill(2)
    elif isinstance(gene_allele_ties, str) and gene_allele_ties.strip():
        allele = gene_allele_ties.strip().split(',')[0].zfill(2)
    else:
        allele = '01'  # Default allele if nothing provided

    return f"{name}*{allele}"

def make_cigar(aligned_length, deletions):
    matches = aligned_length - deletions
    return f"{matches}M{deletions}D"

def derive_cigars(row):
    v_cigar = make_cigar(row["vIndex"], row["vDeletion"])
    j_cigar = make_cigar(row["jDeletion"], 0)  # Conservative: assuming matches up to jIndex
    d_len = row["dIndex"] + row["d3Deletion"] - row["d5Deletion"] if row["dIndex"] >= 0 else 0
    d_cigar = make_cigar(d_len, row["d5Deletion"] + row["d3Deletion"]) if d_len > 0 else ""
    return pd.Series([v_cigar, d_cigar, j_cigar])

def status_to_productive(status):
    if isinstance(status, str) and status.strip().lower() == "in":
        return "T"
    return "F"


def convert_all_adaptive_to_imgt(df, imgt_lookup, return_unmapped=False):
    """
    Converts Adaptive gene/allele names in V(D)J columns to IMGT allele names using a lookup table.
    Operates on 'v_call', 'j_call', 'd_call', and 'c_call' if present.

    Parameters:
    -----------
    df : pd.DataFrame
        Input DataFrame containing TCR annotation columns.
    lookup_path : str
        Path to the lookup table file (TSV format expected).
    return_unmapped : bool
        If True, returns a dictionary of unmapped values per column.

    Returns:
    --------
    df : pd.DataFrame
        DataFrame with original columns overwritten with IMGT-formatted values and original values preserved.
    unmapped (optional) : dict
        Dictionary mapping column names to lists of unmapped original values.
    """
    # Load lookup table
    lookup_df = imgt_lookup

    # Melt to long format
    long_lookup = pd.melt(
        lookup_df,
        id_vars=["IMGT allele name"],
        value_vars=[
            "Adaptive gene name 1", "Adaptive gene name 2",
            "Adaptive allele name 1", "Adaptive allele name 2"
        ],
        var_name="source",
        value_name="adaptive"
    ).dropna()

    # Remove duplicates and build mapping
    long_lookup = long_lookup.drop_duplicates(subset=["adaptive"])
    adaptive_to_imgt = dict(zip(long_lookup["adaptive"], long_lookup["IMGT allele name"]))

    # Columns to try converting
    target_columns = ["v_call", "j_call", "d_call", "c_call"]
    unmapped = {}

    for col in target_columns:
        if col in df.columns:
            # Preserve original
            adaptive_col = f"{col}_adaptive"
            df[adaptive_col] = df[col]

            # Convert to IMGT
            df[col] = df[adaptive_col].map(adaptive_to_imgt)

            # Track unmapped if needed
            if return_unmapped:
                missing = df[df[col].isna()][adaptive_col].dropna().unique().tolist()
                if missing:
                    unmapped[col] = missing

    if return_unmapped:
        return df, unmapped

    return df

def adaptive_to_airr(input_df, basename, imgt_lookup, airr_schema):
    df = input_df

    required = ["nucleotide", "aminoAcid", "vGeneName", "dGeneName", "jGeneName",
                "vDeletion", "n1Insertion", "d5Deletion", "d3Deletion", "n2Insertion", "jDeletion",
                "vIndex", "n1Index", "dIndex", "n2Index", "jIndex"]
    missing = [col for col in required if col not in df.columns]
    if missing:
        raise ValueError(f"Missing required columns: {missing}")

    df[["sequence", "junction", "junction_aa", "sequence_aa", "frame"]] = df.apply(derive_junction_fields, axis=1)
    df[["v_cigar", "d_cigar", "j_cigar"]] = df.apply(derive_cigars, axis=1)

    df[['v_call', 'd_call', 'j_call']] = df.apply(
    lambda row: pd.Series({
        'v_call': resolve_gene_call(
            row.get('vGeneName'), row.get('vGeneAllele'),
            row.get('vGeneNameTies'), row.get('vGeneAlleleTies')
        ),
        'd_call': resolve_gene_call(
            row.get('dGeneName'), row.get('dGeneAllele'),
            row.get('dGeneNameTies'), row.get('dGeneAlleleTies')
        ),
        'j_call': resolve_gene_call(
            row.get('jGeneName'), row.get('jGeneAllele'),
            row.get('jGeneNameTies'), row.get('jGeneAlleleTies')
        ),
    }),
    axis=1
)
    df["productive"] = df["sequenceStatus"].apply(status_to_productive)

    df.rename(columns={"count (templates/reads)": "duplicate_count",
                       "frequencyCount (%)": "duplicate_frequency_percent"}, inplace=True)

    df["cdr3Length"] = df["junction_aa"].apply(lambda x: len(x) if pd.notnull(x) else 0)

    df["junction_length"] = df["junction"].apply(lambda x: len(x) if pd.notnull(x) else 0)
    df["junction_aa_length"] = df["junction_aa"].apply(lambda x: len(x) if pd.notnull(x) else 0)
    df["rev_comp"] = False

    # Load schema
    schema = airr_schema
    required = schema["Rearrangement"]["required"]
    properties = list(schema["Rearrangement"]["properties"].keys())

    # Add missing required fields as blank
    for col in required:
        if col not in df.columns:
            df[col] = pd.NA

    # Identify all boolean columns from schema
    bool_cols = [
        name for name, spec in schema["Rearrangement"]["properties"].items()
        if spec.get("type") == "boolean"
    ]

    true_vals = {"true", "t", "1", "yes"}
    false_vals = {"false", "f", "0", "no"}

    def normalize_bool(val):
        if pd.isna(val):
            return pd.NA
        val_str = str(val).strip().lower()
        if val_str in true_vals:
            return "true"
        elif val_str in false_vals:
            return "false"
        return pd.NA 

    for col in bool_cols:
        if col in df.columns:
            df[col] = df[col].apply(normalize_bool)

    # Order columns
    ordered_cols = [col for col in properties if col in df.columns]

    # Append additional Adaptive columns
    df = df[ordered_cols + ['duplicate_frequency_percent']]

    # Assuming df contains a column 'v_call' with Adaptive names
    df, unmapped = convert_all_adaptive_to_imgt(df, imgt_lookup, return_unmapped=True)

    logger.info("Unmapped entries:", unmapped)

    output_path = f"{basename}_airr.tsv"
    df.to_csv(output_path, sep="\t", index=False)
    logger.info(f"AIRR-compatible file written to: {output_path}")

if __name__ == "__main__":
    # Parse input arguments
    parser = argparse.ArgumentParser(description="Take positional args")

    parser.add_argument(
        "sample_tsv",
        type=str,
        help="Path to TSV file containing TCR count table.",
    )

    parser.add_argument(
        "basename",
        type=str,
        help="Sample ID name for output files.",
    )

    parser.add_argument(
        "imgt_lookup",
        type=str,
        help="Path to reference database file for matching IMGT to adaptive genes.",
    )

    parser.add_argument(
        "airr_schema",
        type=str,
        help="Path to airr json schema for validating adaptive conversion.",
    )

    add_logging_args(parser)
    args = parser.parse_args()

    configure_logging(args)
    logger = logging.getLogger("convert")

    logger.info("Beginning Adaptive Immunoseq to AIRR format conversion...")
    if args.verbose:
        logger.debug("Verbose logging enabled")

    logger.info(f"sample_tsv: {args.sample_tsv}")
    logger.info(f"basename: {args.basename}")
    logger.info(f"imgt_lookup: {args.imgt_lookup}")
    logger.info(f"airr_schema: {args.airr_schema}")

    input_df = pd.read_csv(args.sample_tsv, sep="\t")
    imgt_lookup = pd.read_csv(args.imgt_lookup, sep="\t")
    with open(args.airr_schema) as f:
        airr_schema = json.load(f)
    basename = args.basename

    adaptive_to_airr(input_df, basename, imgt_lookup, airr_schema)