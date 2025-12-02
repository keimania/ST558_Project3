FROM rstudio/plumber

# Install system dependencies
RUN apt-get update -qq && apt-get install -y \
    libssl-dev \
    libcurl4-gnutls-dev \
    libpng-dev \
    libxml2-dev \
    libsodium-dev \
    pandoc

# Install R packages
RUN R -e "install.packages(c('tidyverse', 'tidymodels', 'ranger', 'plumber'))"

# Copy the API script and data
COPY API.R API.R
COPY diabetes_binary_health_indicators_BRFSS2015.csv diabetes_binary_health_indicators_BRFSS2015.csv

# Expose the specific port : 8000
EXPOSE 8000

ENTRYPOINT ["R", "-e", "pr <- plumber::plumb('API.R'); pr$run(host='0.0.0.0', port=8000)"]