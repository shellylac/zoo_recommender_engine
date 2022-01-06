#These are the functions that will become the plumber script

#load R libraries
library(here)
library(plumber)
library(tidyverse)
library(recommenderlab)

#load the dataset and project details
user_matrix <- readRDS(here("input_data", "user_project_matrix.rds"))
preference_matrix <- readRDS(here("input_data", "binary_preference_matrix.rds"))
projects <- readRDS(here("input_data", "project_details.rds"))


#*****************************************************
#Get predictions for user

#function to convert users data to correct format
convert_user <- function(user_id){
  user_df <- user_matrix[user_id,]
  user_real <- as(as.matrix(user_df), "realRatingMatrix")
  user_binary <- binarize(user_real, minRating = 1)
  return(user_binary)
}

#function to convert project_ids to project_names etc
#Finish this - and vectorize it!!
convert_project <- function(project_id) {

}

#function to get predictions for a user
predict <- function(user_id, valid_projects){

  #check if user_id exists
  if (!all(is.na(user_matrix["1",]))) {

    # get the user data to predict for
    newdat <- convert_user(user_id)

    # Build the IBCF model
    scheme <- preference_matrix %>%
      evaluationScheme(method = "cross", k = 4, train  = 0.8, given  = -1)

    recomm_model <- Recommender(getData(scheme, 'train'),
                          method = "IBCF",
                          param = list(k = 5))

    # return predictions from model
    preds <- as(predict(recomm_model,
                        newdata = newdat,
                        n = 5), "list")$`1`


  } else {

    #here return empty table
  }





  pred_projects <- valid_projects %>%
    filter(project_id %in% str_remove(preds, "P.")) %>%
    select(slug)

  message("\n", "Projects predicted for user:")
  print(pred_projects)

}

test_predictions(valid_projects, model_project_ids)
