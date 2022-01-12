# zoo_recommender_system

## To prepare the data for the recommender engine

Run the R script "./R/binary_rating_analysis.R"

- This sources the R script "./R/load_prep_data.R" which reads in three datasets and formats them for analyses:
  - 2021_user_classification_counts.csv", "2021_user_first_last_classification.csv", "launch_approved_projects_20-Dec-2021.txt"
- The script also saves the .rds datafiles needed for analyses/recommendation in the input_data folder

## To run the recommender api

Run the R script "./R/run.R"
