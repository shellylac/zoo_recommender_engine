# zoo_recommender_system

A Zooniverse projects recommendation system for individual Zooniverse users - wrapped in a JSON API.

## Installation

Use Docker and Docker Compose to install dependencies, alternatively use your R install to get the system running.

1. Run `docker-compose build` to build the recommender API container

2. Run `docker-compose up` to serve the recommender API on localhost

Alternatively run `docker-compose run --rm --service-ports --entrypoint bash recommender-api` to start a bash shell in a recommender-api container.

## Usage

### To prepare the data for the recommender engine

Run the R script to generate the model datafiles

1. Get a bash console for using R scripts `docker-compose run --rm --service-ports --entrypoint bash recommender-api`
2. Run the code to generate the model inputs `./R/binary_rating_analysis.R`

- This sources the R script "./R/load_prep_data.R" which reads in three datasets and formats them for analyses:
  - 2021_user_classification_counts.csv
  - 2021_user_first_last_classification.csv
  - launch_approved_projects_20-Dec-2021.txt
- The script also saves the .rds datafiles needed for analyses/recommendation in the input_data folder

### To run the recommender api

Run the R script `./R/run.R` or `docker-compose up`

Then can use the swagger interface to query the API

#### Endpoints

- `GET /recommend?user_id=1`

Fetch the recommeded Zooniverse projects for user with ID 1

``` sh
curl http://localhost:8000/recommend?user_id=1
```
