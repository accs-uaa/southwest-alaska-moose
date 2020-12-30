# Objective: Run conditional logistic regression.

# Author: A. Droghini (adroghini@alaska.edu)

#### Load packages and data ----
rm(list=ls())
source("package_logisticModel/init.R")
paths <- read_csv(file="pipeline/paths/allPaths_forModel_meanCovariates.csv")

#### Convert edge variables ----
# Original distance and topographic units are in meters
# Express distance units as 1/10 of a km instead
# If we use this in final model, move to previous script.

paths <- paths %>% 
  mutate(forest_edge_mean = forest_edge_mean/100,
         tundra_edge_mean = tundra_edge_mean/100)

#### Attempt 1: Run two models ----

#### Split data into calf-at-heel versus no calf
pathsWithCalf <- paths %>% 
  filter(calfAtHeel==1)

pathsWithoutCalf <- paths %>% 
  filter(calfAtHeel==0)

summary(pathsWithCalf)
summary(pathsWithoutCalf)

# Drop Picea mariana - not a lot of it in study area, both sets do not have a lot of variation for the variable (for paths with calves: 0 to 0.3, without calves: 0 to 1.7). 

# Some areas of GMU 17 e.g. Mulchatna River corridor does have a lot of PICMAR. If predictions look very weird, we can create a composite "spruce" variable.

# Paths with calves
clogit(formula = response ~ elevation_mean + roughness_mean + forest_edge_mean +
         tundra_edge_mean + alnus_mean + betshr_mean + dectre_mean +
         erivag_mean + picgla_mean + salshr_mean +
         wetsed_mean + strata(mooseYear_id),
       data = pathsWithCalf)

# Paths without calves
# Full model does not converge - distribution of elevation, roughness, forest_edge, and erivag is problematic
clogit(formula = response ~ tundra_edge_mean + alnus_mean + betshr_mean + 
         dectre_mean + salshr_mean + picgla_mean +
         wetsed_mean + strata(mooseYear_id),
       data = pathsWithoutCalf)

#### Attempt 2: Run single model ----
# With calfAtHeel as grouping variable
paths$calfAtHeel <- as.factor(paths$calfAtHeel)

clogit(formula = response ~ elevation_mean + roughness_mean + forest_edge_mean +
         tundra_edge_mean + alnus_mean + betshr_mean + dectre_mean +
         erivag_mean + picgla_mean + salshr_mean +
         wetsed_mean + strata(mooseYear_id),
       data = paths)
