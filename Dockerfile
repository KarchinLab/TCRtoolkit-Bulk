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

# Install GIANA, patch shebang, symlink for PATH command availability
RUN git init /opt/GIANA && \
    cd /opt/GIANA && \
    git remote add origin https://github.com/s175573/GIANA.git && \
    git fetch --depth 1 origin d38aaf508c204d331f329b2f48f8b247448674bd && \
    git checkout FETCH_HEAD && \
    sed -i '1s|^#!.*|#!/usr/bin/env python3|' /opt/GIANA/GIANA4.1.py && \
    chmod +x /opt/GIANA/GIANA4.1.py && \
    ln -s /opt/GIANA/GIANA4.1.py /usr/local/bin/GIANA

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

# Add to PATH
ENV PATH="/opt/quarto/1.6.42/bin:${PATH}"

# Add LD_LIBRARY_PATH for pandas
ENV LD_LIBRARY_PATH=/opt/conda/lib
