# load recommenderlab
library(recommenderlab)

# Source script to load data and recommender model
source(here("R", "data_model_prep.R"))

#* @filter cors
cors <- function(res) {
  # we could lock this down to only the service origins we expect traffic from
  # e.g www.zooniverse.org vs * (allow all)
  res$setHeader("Access-Control-Allow-Origin", "*")
  plumber::forward()
}

#* Return recommendations for a specified user
#* @param user_id The user_id for which to predict project recommendations
#* @get /recommend
function(user_id, page_size=5) {

  # User_id needs to be character type
  user_id <- as.character(user_id)
  page_size <- as.character(page_size)

  # get the user data to predict for
  newdat <- preference_matrix[
    preference_matrix@data@itemsetInfo$itemsetID == user_id,
  ]

  model_predictions <- predict(recomm_model, newdata = newdat, n = page_size)

  pred_projects <- as.numeric(gsub(
    "P.", "",
    as(model_predictions, "list")[[1]]
  ))

  project_table <- proj_details(pred_projects, projects)

  return(project_table)
}

