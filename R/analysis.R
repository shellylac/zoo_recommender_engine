
  #load data wrangling packages
  library(data.table)
  library(tidyverse)
  
library(lubridate)

  #load path setting package
  library(here)

  
#Generic Load
  #dataset <- fread(here('folder', 'file_name'), colClasses = 'character')

  
#Generic Save
  #fwrite(new_cohort, file = here('folder', 'file_name'), 
sep = ',', col.names = TRUE, quote = FALSE)