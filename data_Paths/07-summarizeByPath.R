# Objective: Summarize point-level variables as the mean for each path. Exclude random paths that have more than 10 points in a lake. Randomly select 10 paths from the subset of the "lake-free" random paths for use in statistical modeling.

# Author: A. Droghini (adroghini@alaska.edu)

rm(list=ls())

# Define Git directory ----
git_dir <- "C:/ACCS_Work/GitHub/southwest-alaska-moose/package_Paths/"

# Load packages and data ----
source(paste0(git_dir,"init.R"))

paths <- read_csv(paste(pipeline_dir, "06-extractCovariates",
                         "allPoints_extractedCovariates.csv",
                         sep="/"))

# Define output csv file ----
output_explain = paste(pipeline_dir,
                       "07-summarizeByPath",
                       "paths_meanCovariates_explanatory.csv", sep="/")

output_predict = paste(pipeline_dir,
                   "07-summarizeByPath",
                   "paths_meanCovariates_predictive.csv", sep="/")

#### Exclude data outisde of study area ----

# Drop all paths with lake values of 128 (n=10 paths)
# Value was given to points that are outside of the lake raster = outside of study area boundary (in this case, they fall in the ocean)
to_drop <- as.matrix(paths %>% 
  filter(lake == 128) %>%
  dplyr::select(fullPath_id) %>% 
    dplyr::distinct())

paths <- paths %>% 
  filter(!(fullPath_id %in% to_drop))

# Check
unique(paths$lake)

rm(to_drop)

#### Summarize covariates for every path ----
# Calculate mean for every variable of interest
meanPaths <- paths %>% 
  dplyr::select(mooseYear_id,fullPath_id,calfStatus,response,
                elevation:lake) %>% 
  dplyr::group_by(mooseYear_id,fullPath_id) %>%
  dplyr::summarise(across(calfStatus:lake, 
                          mean, .names = "{.col}_mean"),.groups="keep") %>%
  dplyr::rename(calfStatus = calfStatus_mean, response = response_mean) %>% 
  ungroup()

##### Exclude paths in lakes ----

# Calculate total number (sum) of points that are in a lake
lakeSum <- paths %>% 
  group_by(fullPath_id) %>% 
  dplyr::summarise(lake_sum = sum(lake))

# Join lakeSum with meanPaths
meanPaths <- left_join(meanPaths,lakeSum,by="fullPath_id")

# Exclude random paths in lake
# Use observed paths to determine threshold of exclusion
# For every path, calculate total number of points that are in a lake
meanPaths %>% dplyr::filter(response=="1") %>% 
  dplyr::summarise(mean = mean(lake_sum),max=max(lake_sum))

# Mean number of points in lake for observed paths is 0.338, max 3 # of points are 9, 6, 2.

# Exclude random paths that have more than 3 points in a lake 
allRandomPaths <- meanPaths %>% 
  dplyr::filter(response=="0" & lake_sum <= 3) %>%
  group_by(mooseYear_id)

# Check max # of points in a lake
# Mean for random paths is 0.32 lake points/path.
allRandomPaths %>% ungroup %>% dplyr::summarise(mean = mean(lake_sum),max=max(lake_sum))

# Drop lake covariates from dataframe
allRandomPaths <- allRandomPaths %>% 
  dplyr::select(-c(lake_mean,lake_sum))

#### Select 10 random paths---

# For explanatory models
set.seed(314)

tenRandomPaths <- allRandomPaths %>% 
  dplyr::sample_n(10)

# Check that there are 10 random paths for each ID
tenRandomPaths %>% 
  dplyr::count(mooseYear_id) %>% 
  filter (n!=10)

# Create final explanatory dataset that includes 10 random paths and 1 observed path
# Should have 880 rows (80 observed + 80*10 random)
allPaths_explanatory <- meanPaths %>% 
  dplyr::filter(response=="1") %>% 
  dplyr::select(-c(lake_mean,lake_sum)) %>% 
  rbind(tenRandomPaths)

# Create final predictive dataset that includes all random paths
allPaths_predict <- meanPaths %>% 
  dplyr::filter(response=="1") %>% 
  dplyr::select(-c(lake_mean,lake_sum)) %>% 
  rbind(allRandomPaths)

#### Export data ----
write_csv(allPaths_explanatory, file= output_explain)
write_csv(allPaths_predict, file= output_predict)

rm(list=ls())