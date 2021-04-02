# Objective: Run conditional logistic regression.

# Author: A. Droghini (adroghini@alaska.edu)

#### Load packages and data ----
rm(list=ls())
source("package_Statistics/init.R")
paths <- read_csv(file="pipeline/paths/allPaths_forModel_meanCovariates.csv")

#### Standardize variables ----
# Convert edge variables
# Original distance and topographic units are in meters
# Express distance units as 1/10 of a km instead

paths <- paths %>% 
  mutate(forest_edge_mean = forest_edge_mean/100,
         tundra_edge_mean = tundra_edge_mean/100)

#### Run models ----
# Cannot combine models since calfStatus is the same for both observed and random paths.

#### Split data into calf versus no calf
pathsWithCalf <- paths %>% 
  filter(calfStatus==1)

pathsWithoutCalf <- paths %>% 
  filter(calfStatus==0)

summary(pathsWithCalf)
summary(pathsWithoutCalf)

# Paths with calves
# Full model fails to converge
# Need to drop picmar_mean
survival::clogit(formula = response ~ elevation_mean + roughness_mean + forest_edge_mean + tundra_edge_mean + alnus_mean + betshr_mean + dectre_mean + erivag_mean + picgla_mean + salshr_mean + wetsed_mean + strata(mooseYear_id), data = pathsWithCalf)

# Paths without calves
# Stability of erivag covariate?
survival::clogit(formula = response ~ elevation_mean + roughness_mean + forest_edge_mean + tundra_edge_mean + alnus_mean + betshr_mean + dectre_mean + erivag_mean + picgla_mean + salshr_mean + wetsed_mean + strata(mooseYear_id), data = pathsWithoutCalf)