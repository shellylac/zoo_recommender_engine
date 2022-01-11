# To run api
library(plumber)
r <- plumb("recommend_projects.R")
r$run(port = 8000,  host="0.0.0.0")


# Or alternative method:
# root <- pr("recommend_projects.R")
# root %>% pr_run(port = 8000, docs = F)

# In cmd line then can issue query:
# curl http://localhost:8000/recommend?user_id=6
