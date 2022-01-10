# These are the functions required by the plumnber function

# load R libraries
library(here)
library(recommenderlab)

# load the dataset and project details
preference_matrix <- readRDS(here("input_data", "binary_preference_matrix.rds"))
projects <- readRDS(here("input_data", "project_details.rds"))

# function to link project_ids to their URL slugs
proj_details <- function(proj_id, project_data) {
  filtered <- project_data[
    project_data$project_id %in% proj_id,
    c("project_id", "slug_end")
  ]
}

# Build the IBCF model
scheme <- evaluationScheme(
  data = preference_matrix,
  method = "cross",
  k = 4,
  train = 0.8,
  given = -1
)

recomm_model <- Recommender(getData(scheme, "train"),
  method = "IBCF",
  param = list(k = 5)
)
