# R Base API Dockerfile with Plumber
# Production-ready R API server

FROM rocker/r-base:4.4.0

# Metadata
LABEL maintainer="Organiser <jessiorg@github.com>"
LABEL description="R Base API with Plumber for data analysis and trading calculations"
LABEL version="1.0.0"

# Set environment variables
ENV DEBIAN_FRONTEND=noninteractive \
    TZ=UTC \
    R_MAX_VSIZE=4Gb

# Install system dependencies
RUN apt-get update && apt-get install -y --no-install-recommends \
    # Build tools
    build-essential \
    gfortran \
    # Libraries
    libcurl4-openssl-dev \
    libssl-dev \
    libxml2-dev \
    libsodium-dev \
    # Utilities
    curl \
    wget \
    git \
    vim \
    && rm -rf /var/lib/apt/lists/*

# Install R packages
RUN R -e "install.packages(c( \
    'plumber', \
    'jsonlite', \
    'future', \
    'promises', \
    # Statistical packages
    'stats', \
    'MASS', \
    # Time series
    'forecast', \
    'tseries', \
    'zoo', \
    'xts', \
    # Trading/Financial
    'TTR', \
    'quantmod', \
    'PerformanceAnalytics', \
    # Data manipulation
    'dplyr', \
    'tidyr', \
    'lubridate', \
    # Utilities
    'logger', \
    'dotenv' \
  ), repos='https://cran.rstudio.com/')"

# Create app directory
WORKDIR /app

# Create directories
RUN mkdir -p /app/api/endpoints /app/api/utils /var/log

# Copy API files
COPY api/ /app/api/

# Expose port
EXPOSE 8000

# Health check
HEALTHCHECK --interval=30s --timeout=10s --start-period=30s --retries=3 \
    CMD curl -f http://localhost:8000/health || exit 1

# Run the API
CMD ["Rscript", "/app/api/plumber.R"]