# Summary statistics for observed and random paths

# Obj: Calculate mean difference between observed and random covariates.

# Author: A. Droghini (adroghini@alaska.edu)

rm(list=ls())

# Define Git directory ----
git_dir <- "C:/ACCS_Work/GitHub/southwest-alaska-moose/package_Statistics/"

#### Load packages and data ----
source(paste0(git_dir,"init.R"))

paths <- read_csv(file=paste(pipeline_dir,
                             "01-dataPrepForAnalyses",
                             "allPaths_meanCovariates_scaled.csv",
                             sep="/"))

#### Format data ----

# Simplify dataframe
# Restrict to only variables we'll be using in the explanatory model
# Use unscaled version of forest & tundra edge to facilitate interpretation
# Shorten variable names

paths <- paths %>% 
  dplyr::select(mooseYear_id,fullPath_id,calfStatus,response,elevation_mean, roughness_mean,forest_edge_mean,tundra_edge_mean,alnus_mean,salshr_mean) %>% 
  rename(elevation = elevation_mean,
         roughness = roughness_mean,
         forest_mean = forest_edge_mean,
         tundra_mean = tundra_edge_mean,
         alnus = alnus_mean,
         salshr = salshr_mean)

#### Calculate differences ----

# Create modified dataset where every row of random path contains values of its matched observed path
# The dataset will be n times shorter than the original, where n is the number of observed paths

obs <- paths %>% 
  filter(response == 1) %>% 
  dplyr::select(-c(calfStatus,response,fullPath_id))

random <- paths %>% 
  filter(response == 0) %>% 
  dplyr::select(-c(response))

pathDiff <- left_join(random,obs,by="mooseYear_id", suffix = c("_random","_obs"))

# Calculate absolute difference
pathDiff <- pathDiff %>%
  arrange(by_group = "mooseYear_id") %>% 
  mutate(elevation_difference = abs(elevation_obs - elevation_random),
         roughness_difference = abs(roughness_obs - roughness_random),
         forest_edge_difference = abs(forest_mean_obs - forest_mean_random),
         tundra_edge_difference = abs(tundra_mean_obs - tundra_mean_random),
         alnus_difference = abs(alnus_obs - alnus_random),
         salshr_difference = abs(salshr_obs - salshr_random)) %>% 
  dplyr::select(mooseYear_id,calfStatus,elevation_difference:salshr_difference)

# Split into calfStatus = 1 and calfStatus = 0
calf <- pathDiff %>% 
  filter(calfStatus == 1)

no_calf <- pathDiff %>% 
  filter(calfStatus == 0)

summary(calf[,3:8])
summary(no_calf[,3:8])

sd(calf$elevation_difference)
sd(no_calf$elevation_difference)

# Clean workspace
rm(list=ls())
