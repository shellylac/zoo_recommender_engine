# Load and prep data

# load data wrangling packages
library(data.table)
library(tidyverse)
library(lubridate)
library(skimr)

# load path setting package
library(here)

# load Recommenderlab
library(recommenderlab)

#***************************************
# Load Datasets
user_counts <- fread(here("input_data", "2021_user_classification_counts.csv"))
user_firstlast <- fread(here("input_data", "2021_user_first_last_classification.csv"))


projects <- fread(here("input_data", "launch_approved_projects_20-Dec-2021.txt"),
                        sep = NULL)
colnames(projects) <- "project_details"

# Clean up the valid projects dataset
# rexp matches the word at the start of the string, an optional space, then the rest of the string.
# the ? after .* makes it a not-greedy expression
# The parenthesis are subexpressions accessed as backreferences \\1 and \\2.
# rexp <- "^(.*?)\\s(.*)$"

valid_projects <- projects %>%
  separate(project_details, into = c("project_id", "slug_end", "name"), sep = "\\s", extra = "merge") %>%
  mutate(url = paste0("zooniverse.org/projects/", slug_end))
valid_projects

# Save the project list
saveRDS(valid_projects, file = here("input_data", "project_details.rds"))

#***************************************
# Merge into one data set
zoo_data_full <- user_counts %>%
  left_join(user_firstlast, by = c("user_id", "project_id")) %>%
  # Keep only valid projects (removes beta testing projects)
  filter(project_id %in% valid_projects$project_id) %>%
  arrange(user_id, project_id)

# zoo_data_full
# skim(zoo_data_full)

#***************************************
# Update dataset without timestamps and with counts per project rather than per workflow_id
zoo_data <- zoo_data_full %>%
  select(-created_at, -updated_at, -workflow_id) %>%
  group_by(user_id, project_id) %>%
  summarise(num_classifications = sum(num_subjects)) %>%
  ungroup()
# zoo_data

rm(user_counts, user_firstlast, zoo_data_full, valid_projects)
