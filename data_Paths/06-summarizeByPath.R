# Objective: Summarize point-level variables as the mean for each path. Exclude random paths that have more than XX of lake. Randomly select 10 paths from the subset of the "lake-free" random paths for use in future modeling.

# Note: Coordinates are now in projected geographic system NAD83 (2011) Alaska Albers EPSG:6393

# Author: A. Droghini (adroghini@alaska.edu)

#### Load packages and data ----
rm(list=ls())
source("package_Paths/init.R")
paths <- read_csv(file="pipeline/paths/allPaths_extracted.csv")

#### Summarize data ----
# Calculate mean for every variable of interest
meanPaths <- paths %>% 
  dplyr::select(mooseYear_id,fullPath_id,calfAtHeel,response,elevation:wetsed) %>% 
  group_by(mooseYear_id,fullPath_id) %>%
  dplyr::summarise(across(calfAtHeel:wetsed, mean, .names = "{.col}_mean")) %>% 
    rename(calfAtHeel = calfAtHeel_mean, response = response_mean) %>% 
  ungroup()

# Calculate total number (sum) of points that are in a lake
lakeSum <- paths %>% 
  group_by(fullPath_id) %>% 
  dplyr::summarise(lake_sum = sum(lake))

# Join lakeSum with meanPaths
meanPaths <- left_join(meanPaths,lakeSum,by="fullPath_id")

rm(lakeSum,paths)

#### Exclude random paths in lake ----
# Use observed paths to determine threshold of exclusion

# For every path, calculate total number of points that are in a lake
meanPaths %>% dplyr::filter(response=="1") %>% 
  dplyr::summarise(mean = mean(lake_sum),max=max(lake_sum))

# Exclude random paths that have more than 10 points in a lake
# Make an exception for path M30104.2019.calf0, which only has 9 random path iterations with <= 10 points in a lake
meanPaths <- meanPaths %>% 
  dplyr::filter( (mooseYear_id!="M30104.2019.calf0" & lake_sum <= 10) | 
                   (mooseYear_id=="M30104.2019.calf0" & lake_sum <= 11)) %>% 
  dplyr::select(-lake_sum)

#### Select 10 random paths for every observed path ----
randomPaths <- meanPaths %>% 
  dplyr::filter(response=="0") %>%
  group_by(mooseYear_id) %>% 
  dplyr::sample_n(10)

# Create final dataset that includes 10 random paths and 1 observed path
allPaths <- meanPaths %>% 
  dplyr::filter(response=="1") %>% 
  rbind(randomPaths)

#### Export data ----
write_csv(allPaths,file="pipeline/paths/allPaths_forModel_meanCovariates.csv")

rm(list=ls())