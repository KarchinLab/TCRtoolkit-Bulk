FROM condaforge/miniforge3:24.9.2-0

# Copy the environment file into /tmp
COPY env.yml /tmp/env.yml
# ENV DEBIAN_FRONTEND=noninteractive

# Update the mamba base environment with required packages
WORKDIR /tmp
RUN mamba env update -n base --file env.yml

# Install system dependencies
# RUN apt-get update \
#     && apt-get install -y --no-install-recommends \
#     curl \
#     libcurl4-openssl-dev \
#     libxml2-dev \
#     libssl-dev \
#     zlib1g-dev \
#     && apt-get clean \
#     && rm -rf /var/lib/apt/lists/*
RUN apt-get update \
    && apt-get install -y curl \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# Install quarto
RUN mkdir -p /opt/quarto/1.6.40 \
    && curl -o quarto.tar.gz -L \
        "https://github.com/quarto-dev/quarto-cli/releases/download/v1.6.40/quarto-1.6.40-linux-amd64.tar.gz" \
    && tar -zxvf quarto.tar.gz \
        -C "/opt/quarto/1.6.40" \
        --strip-components=1 \
    && rm quarto.tar.gz 

# Install R
RUN mamba install -y r-base=4.4.2 \
    && mamba clean -afy

RUN conda install r-igraph

# Install R packages, including igraph binary
RUN Rscript -e "install.packages('remotes', repos='https://cran.r-project.org')" \
    && Rscript -e "remotes::install_github('HetzDra/turboGliph')"

# Add quarto to the PATH
ENV PATH="/opt/quarto/1.6.40/bin:${PATH}"
