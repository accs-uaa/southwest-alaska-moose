# Obj: Create new CSV files for analysis to avoid having to 

# Author: A. Droghini (adroghini@alaska.edu)

rm(list=ls())

# Define Git directory ----
git_dir <- "C:/ACCS_Work/GitHub/southwest-alaska-moose/package_Statistics/"

#### Load packages and data ----
source(paste0(git_dir,"init.R"))

paths <- read_csv(file=paste(pipeline_dir,
                             "07-summarizeByPath",
                             "allPaths_meanCovariates.csv",
                             sep="/"))

##### Define output csv files
output_scale <- paste(pipeline_dir,
                     "01-dataPrepForAnalyses",
                     "allPaths_meanCovariates_scaled.csv", sep="/")

output_calf <- paste(pipeline_dir,
                      "01-dataPrepForAnalyses",
                      "allPaths_calves.csv", sep="/")

output_no_calf <- paste(pipeline_dir,
                      "01-dataPrepForAnalyses",
                      "allPaths_no_calves.csv", sep="/")
### Standardize variables ----
# Convert edge variables so that all covariates are on a similar scale
# Original distance and topographic units are in meters
# Express distance units as 1/10 of a km instead

paths_scale <- paths %>% 
  mutate(forest_edge_scaled = forest_edge_mean/100,
         tundra_edge_scaled = tundra_edge_mean/100)

write_csv(paths_scale, file=output_scale)

### Split data into calf versus no calf ----

# We'll be running 2 separate models: one for cows w/ calves, one for cows w/o calves. Cannot include calving status as a splitting variable in a conditional framework, since calving status is the same for both observed and random paths.

calf <- paths_scale %>% 
  filter(calfStatus==1)

no_calf <- paths_scale %>% 
  filter(calfStatus==0)

write_csv(calf, file=output_calf)
write_csv(no_calf, file = output_no_calf)

# Clear workspace
rm(list=ls())