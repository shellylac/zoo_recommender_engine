library(here)

# Source script to load data and recommender model
source(here("R", "data_model_prep.R"))

#* Return recommendations for a specified user
#* @param user_id The user_id for which to predict project recommendations
#* @get /recommend
function(user_id) {

  # User_id needs to be character type
  user_id <- as.character(user_id)

  # get the user data to predict for
  newdat <- preference_matrix[
    preference_matrix@data@itemsetInfo$itemsetID == user_id,
  ]

  model_predictions <- predict(recomm_model, newdata = newdat, n = 5)

  pred_projects <- as.numeric(gsub(
    "P.", "",
    as(model_predictions, "list")[[1]]
  ))

  project_table <- proj_details(pred_projects, projects)

  return(project_table)
}

# To interactively test:
# library(plumber)
# r <- plumb(here("R", "recommend_projects.R"))
# r$run(port = 8000)
#
# Or alternative method:
# root <- pr(here("R", "recommend_projects.R"))
# root %>% pr_run(port = 8000, docs = F)

# In cmd line then can issue query:
# curl http://localhost:8000/recommend?user_id=6
