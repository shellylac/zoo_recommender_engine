# zoo_recommender_system

A [Zooniverse](https://www.zooniverse.org/) projects recommendation system for individual Zooniverse users - wrapped in a JSON API.

## Installation

Use Docker and Docker Compose to install dependencies, alternatively use your local R install to get the system running.

1. Run `docker-compose build` to build the recommender API container

2. Run `docker-compose up` to serve the recommender API on the localhost

- requires the ratings matrix and project dataset to have been created (see below)

## Usage

### To prepare the data for the recommender engine

1. Get a bash console for using R scripts `docker-compose run --rm --service-ports --entrypoint bash recommender-api`

2. Run the code to generate the model inputs `Rscript ./R/binary_rating_analysis.R`

- This sources the R script "./R/load_prep_data.R" which reads in three datasets and formats them for analyses:
  - 2021_user_classification_counts.csv
  - 2021_user_first_last_classification.csv
  - launch_approved_projects_20-Dec-2021.txt
- The script also saves the .rds datafiles needed for analyses/recommendation in the input_data folder

### To run the recommender api

1. Run `docker-compose up`

Alternatively from within the docker bash shell run `Rscript ./R/run.R`

Then can use the swagger interface to query the API.

#### Endpoints

- `GET /recommend?user_id=10`

Fetch the recommeded Zooniverse projects for user with ID 10

```sh
curl http://localhost:8000/recommend?user_id=10
```
