# TCRtoolkit-Bulk: A T Cell Repertoire Analysis Platform

![TCRtoolkit-banner](./assets/images/TCRtoolkit-banner.png)

Thanks for checking out `TCRtoolkit-Bulk`, the platform for bulk T Cell Repertoire analysis! `TCRtoolkit-Bulk` is wrapped in NextFlow, written in python, and uses Docker to manage dependencies.

<p align="center">
    <img src=assets/TCR_Bulk_profiling.png/>
</p>

We currently support bulk TCRseq data from Adaptive Biotechnologies.

##  Requirements

1. Nextflow

Nextflow can be used on any POSIX-compatible system (Linux, OS X, WSL). It requires Bash 3.2 (or later) and Java 11 (or later, up to 18) to be installed.

```{bash}
wget -qO- https://get.nextflow.io | bash
chmod +x nextflow
```

The nextflow executable is now available to run on the command line. The executable can be moved to a directory in your $PATH variable so you can run it from any directory.

2. Docker

`TCRtoolkit-Bulk` runs in Docker containers available [here](https://hub.docker.com/repository/docker/karchinlab/bulktcr/general). Depending on what operating system you are running (Linux, MacOS, WSL), please refer to the [Docker documentation](https://docs.docker.com/engine/install/) for installation instructions.

3. TCRtoolkit-Bulk

```{bash}
git clone https://github.com/KarchinLab/TCRtoolkit-Bulk.git
cd TCRtoolkit-Bulk
```


## Quick Start

Below is a minimal example of how to run the pipeline. The `minimal-example` dataset provided is a small subset of the dataset from this manuscript by [Tumeh and Ribas et al. (2014)](https://www.nature.com/articles/nature13954). Note that the results are simply for demonstration purposes and are not intended for biological interpretation.

```
## from the TCRtoolkit-Bulk directory
nextflow run main.nf --data_dir test_data/minimal-example \
    --samplesheet test_data/minimal-example/samplesheet.csv \
    --outdir out-minimal-dev \
    --max_memory 10GB --max_cpus 4
```
