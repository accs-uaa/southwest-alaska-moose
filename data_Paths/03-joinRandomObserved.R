# Objective: Format & join random and observed paths so that covariates can be extracted from points.

# Author: A. Droghini (adroghini@alaska.edu)

#### Load data and packages----
rm(list=ls())
source("package_Paths/init.R")
observed <- read_csv("pipeline/paths/observedPaths.csv")
random <- read_csv("pipeline/paths/randomPaths.csv")

#### Format data ----

# Create logistic response
random$logitResponse <- "0"
observed$logitResponse <- "1"

# Remove superfluous rows from observed paths
# Rename columns to match random paths
names(observed)
observed <- observed %>% 
  dplyr::select(mooseYear_id,RowID,Easting,Northing,calfAlive,logitResponse) %>% 
  rename(x = Easting, y = Northing, pointID = RowID) %>% 
  mutate(fullPath_id = paste(mooseYear_id,"observed",sep="-"),
         fullPoint_id = paste(mooseYear_id,"observed",pointID,
                              sep="-"))

# Join datasets
allPaths <- rbind.fill(observed,random)

# calfAlive variable -- should I have dropped beginning NAs before generating paths? Also, I don't think clogit will work if we don't have info for random calfAlive?!

#### Export data----
write_csv(allPaths,"pipeline/paths/allPaths.csv")