# Objectives: Plot Net Squared Displacement (NSD) and Mean Squared Displacement (MSD) for each moose.

# Author: A. Droghini (adroghini@alaska.edu)

# Load packages and data----
rm(list=ls())
source("scripts/init.R")
source("scripts/function-plotNSD.R")
source("scripts/function-plotMSD.R")
load("pipeline/03b_cleanLocations/cleanLocations.Rdata")

#### Explore effect of start date on MSD plots ----
# Three possibilities:
# 1. No edits (most start in April)
# 2. July 1
# 3. January 1

# Use UTC Date for now, 12 hour difference probably doesn't matter.

# Some collars were only deployed in 2019
# Use ifelse statement to account for that

## Start date: June
gpsJune <- gpsClean %>% 
  mutate(UTC_Date = as.Date(UTC_Date,format="%m/%d/%Y")) %>%    
  filter(
    ifelse(grepl("M1719",animal_id), 
           UTC_Date >= as.Date("06/01/2019",format="%m/%d/%Y"),
           UTC_Date >= as.Date("06/01/2018",format="%m/%d/%Y"))
  )

## Start date: July
gpsJuly <- gpsClean %>% 
  mutate(UTC_Date = as.Date(UTC_Date,format="%m/%d/%Y")) %>%    
  filter(
    ifelse(grepl("M1719",animal_id), 
           UTC_Date >= as.Date("07/01/2019",format="%m/%d/%Y"),
           UTC_Date >= as.Date("07/01/2018",format="%m/%d/%Y"))
  )

# Check to see that all IDs start on July 1st of their deployment year
View(gpsJuly[!duplicated(gpsJuly$animal_id),])

nrow(gpsClean) - nrow(gpsJuly) # number of obs lost from filtering

## Start date: August
gpsAug <- gpsClean %>% 
  mutate(UTC_Date = as.Date(UTC_Date,format="%m/%d/%Y")) %>%    
  filter(
    ifelse(grepl("M1719",animal_id), 
           UTC_Date >= as.Date("08/01/2019",format="%m/%d/%Y"),
           UTC_Date >= as.Date("08/01/2018",format="%m/%d/%Y"))
  )

## Start date: August
gpsSep <- gpsClean %>% 
  mutate(UTC_Date = as.Date(UTC_Date,format="%m/%d/%Y")) %>%    
  filter(
    ifelse(grepl("M1719",animal_id), 
           UTC_Date >= as.Date("09/01/2019",format="%m/%d/%Y"),
           UTC_Date >= as.Date("09/01/2018",format="%m/%d/%Y"))
  )


## Start date: January
gpsJan <- gpsClean %>% 
  mutate(UTC_Date = as.Date(UTC_Date,format="%m/%d/%Y")) %>%    
  filter(
    ifelse(grepl("M1719",animal_id), 
           UTC_Date >= as.Date("01/01/2020",format="%m/%d/%Y"),
           UTC_Date >= as.Date("01/01/2019",format="%m/%d/%Y"))
  )

nrow(gpsClean) - nrow(gpsJan) # number of obs lost from filtering

# Number of observations per individual
print(as_tibble(gpsJan %>% group_by(animal_id) %>% 
  summarize(n = length(UTC_Date)) %>% 
  ungroup()),
  n=100)

# Create spatial object ----
# Convert data.frame to adehabitat ltraj object
# Extract XY coordinates, timestamp, and moose ID from gpsClean

gpsToLtraj <- gpsSep # switch this out depending on start date

coords <- gpsToLtraj[,9:10]
dataLT <- as.ltraj(xy = coords, date = gpsToLtraj$datetime, id = gpsToLtraj$deployment_id)
names(dataLT) <- unique(gpsToLtraj$deployment_id)

rm(coords)

# Plot Mean Squared Displacement----
# estimate MSD over 1 week
# ideally should use interpolated data for this because rollapplyr works on no of observations regardless of whether data are gappy or not
# for now, assuming even two-hour fix rate, want a rolling mean to be taken every 12 per day * 7 days = 84 observations
plotMSD(dataLT)

# Plot Net Squared Displacement----
plotNSD(dataLT)

# Clean workspace----
rm(list=ls())
