#This script loads and interrogates the data

#load data wrangling packages
library(data.table)
library(tidyverse)
library(lubridate)
library(skimr)
#load path setting package
library(here)

#Load Datasets
user_counts <- fread(here('input_data', '2021_user_classification_counts.csv'))
user_firstlast <- fread(here('input_data', '2021_user_first_last_classification.csv'))
valid_projects <- fread(here('input_data', 'launch_approved_projects_20-Dec-2021.csv'), header = F,
                        col.names = c("project_id", "slug")) %>%
                  mutate(exists = TRUE)
valid_projects

#Merge into one data set
zoo_data_full <- user_counts %>%
  left_join(user_firstlast, by = c("user_id", "project_id")) %>%
  left_join(valid_projects, by = "project_id") %>%
  #Keep only valid projects (removes beta testing projects)
  filter(exists == T) %>%
  select(-exists, -slug) %>%
  arrange(user_id, project_id)
zoo_data_full
skim(zoo_data_full)

##**********************************************
# Why do some records not have matching create/updated times?
#Cause grant didn't extract the data properly - ignore for now
#sum(is.na(zoo_data$created_at)); sum(is.na(zoo_data$updated_at))
#32152

# What does workflow_id indicate?
#Workflow id  = different tasks on a project.

#  - what does it mean when there are >1 workflow_ids for the same time?
#user_id project_id workflow_id num_subjects          created_at          updated_at   time_spent
#2:       6      12552       17227            1 2021-02-11 17:30:03 2021-04-05 09:01:13 5.264664e+01
#3:       6      12552       17988           33 2021-02-11 17:30:03 2021-04-05 09:01:13 5.264664e+01
# Sum up the num_selected for these

# What does a time difference of 0 mean (created_at, updated_at are equal)? It means 0 secs!
#user_id project_id workflow_id num_subjects          created_at          updated_at time_spent
#1:  165259      12268       18505            1 2021-11-17 18:31:53 2021-11-17 18:31:53          0

# What does a time difference of > 1 day mean?
# This is simply the time between their first and last classification on a project in this year
# meaningless

#zoo_data_full <- zoo_data %>%
#  filter(!is.na(created_at)) %>%
#  mutate(time_spent = time_length(interval(created_at, updated_at, "UTC"), "day"))
##**********************************************

#Update dataset without timestamps and with counts per project rather than per workflow_id
zoo_data <- zoo_data_full %>%
  select(-created_at, -updated_at, -workflow_id) %>%
  group_by(user_id, project_id) %>%
  summarise(num_classifications = sum(num_subjects)) %>%
  ungroup()
zoo_data


#Explore the data
#Number unique =
length(unique(zoo_data$user_id)) #181607
length(unique(zoo_data$project_id)) #331

#Distribution of projects per user
project_per_user <- zoo_data %>% group_by(user_id) %>% tally()
range(project_per_user$n)
project_per_user %>%
  filter(n > 3 & n < 30) %>%
  ggplot(aes(x = n)) +
  geom_histogram(binwidth = 1)

#Distribution of users per project
users_per_project <- zoo_data %>% group_by(project_id) %>% tally()
range(users_per_project$n)
users_per_project %>%
  filter(n < 3000) %>%
  ggplot(aes(x = n)) +
  geom_histogram(binwidth = 300)

#Distribution of number of classifications
range(zoo_data$num_classifications)
#[1]      1 221202

min_max_norm <- function(x) {
  (x - min(x)) / (max(x) - min(x))
}
test <- zoo_data %>%
  mutate(norm_class = normalit(num_classifications)) %>%
  mutate(scaled_class = scale(num_classifications))

zoo_data %>%
  mutate(norm_class = normalit(num_classifications)) %>%
  mutate(scaled_class = scale(num_classifications)) %>%
  #filter(num_classifications < 2000) %>%
  ggplot(aes(x = norm_class)) +
  geom_histogram(binwidth = 0.1)

#How do number of classifications vary by project_id
zoo_data %>%
  group_by(project_id) %>%
  summarise(mean_class = mean(num_classifications),
            max_class = max(num_classifications),
            sd_class = sd(num_classifications)) %>%
  arrange(desc(sd_class))

# 1:We will keep only users who have classified on >= 3 projects and <= 50
# 2:We will keep only projects that have had >= 20 users and <5000 users
# 3:We will exclude project 12552 and 12616
# 4:We will normalise the num_classifications

users_keep <- zoo_data %>%
  group_by(user_id) %>%
  tally() %>%
  filter(n >= 3 & n <= 50)

projects_keep <- zoo_data %>%
  group_by(project_id) %>%
  tally() %>%
  filter(n >= 20 & n <= 5000)

#Filter dataset for above conditions
zoo_data_filtered <- zoo_data %>%
  filter(user_id %in% users_keep$user_id) %>%
  #filter(project_id %in% projects_keep$project_id) %>%
  filter(!(project_id %in% c(12552, 12616)))

#********************************************
# Create a smaller datset to play with
#zoo_small <- sample_n(zoo_data_filtered, 10000)
#********************************************
user_ids_vec <- zoo_data_filtered %>% pull(user_id)

zoo_wide <- zoo_data_filtered %>%
  pivot_wider(id_cols = user_id,
              names_from = project_id,
              values_from = num_classifications,
              names_glue = "P.{project_id}",
              values_fill = NA) %>%
  #we make the user_id col into rownames
  column_to_rownames("user_id")


#Recommenderlab
library(recommenderlab)
zoo_ratings <- as.matrix(zoo_wide)
ratings_matrix <- as(zoo_ratings, "realRatingMatrix")
ratings_matrix_norm <- normalize(ratings_matrix)
#image(ratings_matrix[1:50, 1:50])


#********************************************
# Sub-sample to have a test data set
set.seed(1234)
zoo_small <- sample(ratings_matrix_norm, 20000)
#********************************************
#*

scheme <- zoo_small %>%
  evaluationScheme(method = "split",
                   k      = 1,
                   train  = 0.8,
                   given  = -1)

algorithms <- list(
  "popular items"     = list(name  = "POPULAR", param = NULL),
  "item-based CF"     = list(name  = "IBCF", param = list(k = 5)),
  "user-based CF"     = list(name  = "UBCF", param = list(method = "Cosine", nn = 500))
)

results <- recommenderlab::evaluate(scheme,
                                    algorithms,
                                    type  = "topNList",
                                    n     = c(1, 3, 5, 10, 15, 20)
)

