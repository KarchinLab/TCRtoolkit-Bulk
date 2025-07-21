FROM condaforge/miniforge3:24.9.2-0

# Copy the environment file into /tmp
COPY env.yml /tmp/env.yml

# Install system dependencies
RUN apt-get update \
    && apt-get install -y \
    build-essential \
    curl \
    gcc \
    g++ \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# Update the conda base environment with required packages
WORKDIR /tmp
RUN conda env update -n base --file env.yml

# Install quarto
RUN mkdir -p /opt/quarto/1.6.42 \
    && curl -o quarto.tar.gz -L \
        "https://github.com/quarto-dev/quarto-cli/releases/download/v1.6.42/quarto-1.6.42-linux-amd64.tar.gz" \
    && tar -zxvf quarto.tar.gz \
        -C "/opt/quarto/1.6.42" \
        --strip-components=1 \
    && rm quarto.tar.gz 

# Install R package not available via conda
RUN Rscript -e "remotes::install_github('HetzDra/turboGliph')"
RUN Rscript -e "remotes::install_github('kalaga27/tcrpheno')"

# Add quarto to the PATH
ENV PATH="/opt/quarto/1.6.42/bin:${PATH}"

# Add LD_LIBRARY_PATH for pandas
ENV LD_LIBRARY_PATH=/opt/conda/lib
