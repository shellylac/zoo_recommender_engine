# start from the rocker/r-ver:3.5.0 image
FROM rstudio/plumber

# # install the linux libraries needed for plumber
# RUN apt-get update -qq && apt-get install -y \
#   libssl-dev \
#   libcurl4-gnutls-dev

# install plumber
RUN R -e "install.packages(c('here', 'recommenderlab', 'data.table', 'tidyverse', 'lubridate', 'skimr'))"

# copy model and scoring script
WORKDIR /app
RUN mkdir input_data
RUN mkdir R

# Inject these files in at runtime via volume mounts from local computer file system
# ADD ./input_data/binary_preference_matrix.rds ./input_data/
# ADD ./input_data/project_details.rds ./input_data/

ADD ./R/ ./R/
ADD ./R/run.R /app

# open port 8000 to traffic
EXPOSE 8000

# when the container starts, start the main.R script
CMD ["Rscript", "/app/run.R"]
