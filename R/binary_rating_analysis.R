#Load libraries and data
library(here)

source(here("R", "load_prep_data.R"))
#loads objects: "valid_projects" "zoo_data"

#********************************************
#Create the BINARY ratings matrix
user_ids_vec <- zoo_data %>% pull(user_id)

zoo_wide <- zoo_data %>%
  pivot_wider(id_cols = user_id,
              names_from = project_id,
              values_from = num_classifications,
              names_glue = "P.{project_id}",
              values_fill = NA) %>%
  #we make the user_id col into rownames
  column_to_rownames("user_id")

zoo_ratings <- as.matrix(zoo_wide)
real_ratings <- as(zoo_ratings, "realRatingMatrix")
binary_ratings <- binarize(real_ratings, minRating = 1)
binary_ratings

image(binary_ratings[1:50, 1:50])

#********************************************
#Look for and remove Outliers

#distributions of the number of users per project:
n_users <- colCounts(binary_ratings)
qplot(n_users) +
  stat_bin(binwidth = 100) +
  ggtitle("Distribution of the number of users")
qplot(n_users[n_users < 8000 & n_users > 5]) + stat_bin(binwidth = 3)

# Remove projects with < 5 users
binary_ratings_filtered <- binary_ratings[, colCounts(binary_ratings) >= 5 ]
binary_ratings_filtered

#Now we have some users with no projects
sum(rowCounts(binary_ratings_filtered) == 0)

#So only keep users that have classified on at least 5 projects
binary_ratings_filtered <- binary_ratings_filtered[rowCounts(binary_ratings_filtered) >= 5, ]
binary_ratings_filtered

#distributions of the number of users per project:
#projects_per_users <- rowCounts(binary_ratings_filtered)
#range(projects_per_users)
#qplot(projects_per_users) +  stat_bin(binwidth = 1)
#qplot(projects_per_users[projects_per_users < 20 ]) + stat_bin(binwidth = 1)


#********************************************
# Run an assortment of algorithms to see which works best

scheme <- binary_ratings_filtered %>%
  evaluationScheme(method = "cross",
                   k      = 4,
                   train  = 0.8,
                   given  = -1)

algorithms <- list(
  #"association rules" = list(name = "AR", param = list(supp = 0.1, conf = 0.01)),
  "random"  = list(name = "RANDOM", param = NULL),
  "popular" = list(name  = "POPULAR", param = NULL),
  "IBCF_10" = list(name  = "IBCF", param = list(k = 5)), # k=10 or 30 did worse then k = 5
  "UBCF_nn500" = list(name  = "UBCF", param = list(method = "Cosine", nn = 50)) # nn = 100 and 500 did worse
  )

results <- recommenderlab::evaluate(scheme,
                                    algorithms,
                                    type  = "topNList",
                                    n     = c(1, 3, 5, 10, 15, 20)
)

#View results from each of the algorithms in turn
results$random %>% getConfusionMatrix()
results$IBCF %>% getConfusionMatrix()

#********************************************
# Visualise the results

# see here for details: https://diegousai.io/2019/03/market-basket-analysis-part-2-of-3/

#Put the previous steps into a function (to use with map() below)
avg_conf_matr <- function(results) {
  tmp <- results %>%
    getConfusionMatrix()  %>%
    as.list()
  as.data.frame( Reduce("+",tmp) / length(tmp)) %>%
    select('n', 'precision', 'recall', 'TPR', 'FPR')
}

# Using map() to iterate function across all models
results_tbl <- results %>%
  map(avg_conf_matr) %>%
  # Turning into an unnested tibble
  enframe() %>%
  # Unnesting to have all variables on same level
  unnest(cols = c(value))

#Classification models performance can be compared using the ROC curve,
# which plots the true positive rate (TPR) against the false positive rate (FPR).

results_tbl %>%
  ggplot(aes(FPR, TPR, colour = fct_reorder2(as.factor(name), FPR, TPR))) +
  geom_line() +
  geom_label(aes(label = n))  +
  labs(title = "ROC curves",
       colour = "Model") +
  theme_grey(base_size = 14)


results_tbl %>%
  ggplot(aes(recall, precision,
             colour = fct_reorder2(as.factor(name),  precision, recall))) +
  geom_line() +
  geom_label(aes(label = n))  +
  labs(title = "Precision-Recall curves",
       colour = "Model") +
  theme_grey(base_size = 14)


#***********************************************
# Build the IBCF model
recomm <- Recommender(getData(scheme, 'train'),
                      method = "IBCF",
                      param = list(k = 5))

recomm

#***********************************************
# Make predictions from the model

(model_project_ids <- binary_ratings_filtered@data@itemInfo$labels)
valid_projects <- valid_projects %>%
  mutate(in_model = ifelse(project_id %in% str_remove(model_project_ids, "P."), 1, 0))

#These are random animal projects:
(random <- c(11, 14, 75, 4179))
#These are random astrophysics projects:
(random <- c(39, 73, 1338))
#These are random arts/not science projects:
(random <- c(4405, 5042, 5352, 6406))
#These are Cam's ones:
(random <- zoo_data %>%
  filter(user_id == 6) %>%
  pull(project_id) %>%
  as.character())

random_project_strings <- paste0("P.", random)

newdat <- data.frame(project_id = model_project_ids, value = 0) %>%
  mutate(value = ifelse(project_id %in% random_project_strings, 1, 0)) %>%
  # Spread into sparse matrix format
  pivot_wider(names_from = project_id, values_from = value, values_fill = 0) %>%
  # Change to a matrix
  as.matrix() %>%
  # Convert to recommenderlab class 'binaryRatingsMatrix'
  as("binaryRatingMatrix")

pred_projids <- as(predict(recomm, newdata = newdat, n = 5), 'list')$`1`
(pred_projects <- valid_projects %>%
  mutate(new_project_id = paste0("P.", project_id)) %>%
  filter(new_project_id %in% pred_projids) %>%
  select(slug))


#*****************************************************
#Function to test random predictions
test_predictions <- function(valid_projects, model_project_ids){
  random_proj_ids <- sample(model_project_ids, 5)

  user_details <- valid_projects %>%
    filter(project_id %in% str_remove(random_proj_ids, "P.")) %>%
    select(slug)

  message("Chosen user has classified on these projects:")
  print(user_details)

  #create the new data binary rating matrix
  newdat <- data.frame(project_id = model_project_ids, value = 0) %>%
    mutate(value = ifelse(project_id %in% random_proj_ids, 1, 0)) %>%
    # Spread into sparse matrix format
    pivot_wider(names_from = project_id, values_from = value, values_fill = 0) %>%
    # Change to a matrix
    as.matrix() %>%
    # Convert to recommenderlab class 'binaryRatingsMatrix'
    as("binaryRatingMatrix")

  preds <- as(predict(recomm, newdata = newdat, n = 5), "list")$`1`

  pred_projects <- valid_projects %>%
    filter(project_id %in% str_remove(preds, "P.")) %>%
    select(slug)

  message("\n", "Projects predicted for user:")
  print(pred_projects)

}

test_predictions(valid_projects, model_project_ids)
