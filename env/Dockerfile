FROM rocker/r-ver:4.4.2

RUN apt-get update && apt-get install -y --no-install-recommends \
    libcurl4-openssl-dev \
    libssl-dev \
    libxml2-dev \
    zlib1g-dev \
    libgit2-dev \
    libfontconfig1-dev \
    libharfbuzz-dev \
    libfribidi-dev \
    libfreetype6-dev \
    libpng-dev \
    libtiff5-dev \
    libjpeg-dev \
    git \
    && rm -rf /var/lib/apt/lists/*

RUN R -q -e "install.packages(c('readr','dplyr','tidyr','tibble','ggplot2','vegan','jsonlite','data.table','optparse','stringr','purrr'), repos='https://cloud.r-project.org')"

WORKDIR /work
