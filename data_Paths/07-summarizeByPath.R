# Objective: Summarize point-level variables as the mean for each path. Exclude random paths that have more than 10 points in a lake. Randomly select 10 paths from the subset of the "lake-free" random paths for use in statistical modeling.

# Author: A. Droghini (adroghini@alaska.edu)

rm(list=ls())

# Define Git directory ----
git_dir <- "C:/ACCS_Work/GitHub/southwest-alaska-moose/package_Paths/"

# Load packages and data ----
source(paste0(git_dir,"init.R"))

paths <- read_csv(paste(pipeline_dir, "06-extractCovariates",
                         "allPaths_extracted.csv",
                         sep="/"))

# Define output csv file ----
output_csv = paste(pipeline_dir,
                   "07-summarizeByPath",
                   "allPaths_meanCovariates_forModelRun.csv", sep="/")

#### Summarize data ----
# Calculate mean for every variable of interest
meanPaths <- paths %>% 
  dplyr::select(mooseYear_id,fullPath_id,calfStatus,response,
                elevation:lake) %>% 
  dplyr::group_by(mooseYear_id,fullPath_id) %>%
  dplyr::summarise(across(calfStatus:lake, 
                          mean, .names = "{.col}_mean"),.groups="keep") %>%
  dplyr::rename(calfStatus = calfStatus_mean, response = response_mean) %>% 
  ungroup()

# Calculate total number (sum) of points that are in a lake
lakeSum <- paths %>% 
  group_by(fullPath_id) %>% 
  dplyr::summarise(lake_sum = sum(lake))

# Join lakeSum with meanPaths
meanPaths <- left_join(meanPaths,lakeSum,by="fullPath_id")

# Select 10 random paths 

# Exclude random paths in lake
# Use observed paths to determine threshold of exclusion
# For every path, calculate total number of points that are in a lake
meanPaths %>% dplyr::filter(response=="1") %>% 
  dplyr::summarise(mean = mean(lake_sum),max=max(lake_sum))

# Mean number of points in lake for observed paths is 0.338, max is 3.

# Exclude random paths that have more than 3 points in a lake and select 10 random paths for every observed path.
set.seed(3256572)
randomPaths <- meanPaths %>% 
  dplyr::filter(response=="0" & lake_sum <= 3) %>%
  group_by(mooseYear_id) %>% 
  dplyr::sample_n(10)

# Check that there are 10 random paths for each ID
randomPaths %>% 
  dplyr::count(mooseYear_id) %>% 
  filter (n<10)

# Check that the mean # of points in a lake is +/- similar to the mean for observed paths (0.338)
randomPaths %>% ungroup %>% dplyr::summarise(mean = mean(lake_sum),max=max(lake_sum))
# Mean for random paths is 0.32 lake points/path.

# Create final dataset that includes 10 random paths and 1 observed path
allPaths <- meanPaths %>% 
  dplyr::filter(response=="1") %>% 
  rbind(randomPaths)
# Should have 880 rows (80 observed + 80*10 random)

#### Export data ----
write_csv(allPaths, file= output_csv)

rm(list=ls())