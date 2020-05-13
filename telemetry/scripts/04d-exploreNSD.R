# Objectives: Plot Net Squared Displacement (NSD) and Mean Squared Displacement (MSD) for each moose.

# Author: A. Droghini (adroghini@alaska.edu)

# Load packages and data----
rm(list=ls())
source("scripts/init.R")
source("scripts/function-plotNSD.R")
source("scripts/function-plotMSD.R")
load("pipeline/03b_cleanLocations/cleanLocations.Rdata")

# Create spatial object ----
# Convert data.frame to adehabitat ltraj object
# Extract XY coordinates, timestamp, and moose ID from gpsClean
coords <- gpsClean[,9:10]
dataLT <- as.ltraj(xy = coords, date = gpsClean$datetime, id = gpsClean$deployment_id)
names(dataLT) <- unique(gpsClean$deployment_id)

rm(coords,gpsClean)

# Plot Net Squared Displacement----
plotNSD(dataLT)

# Plot Mean Squared Displacement----
# estimate MSD over 1 week
# ideally should use interpolated data for this because rollapplyr works on no of observations regardless of whether data are gappy or not
# for now, assuming even two-hour fix rate, want a rolling mean to be taken every 12 per day * 7 days = 84 observations

plotMSD(dataLT)

# Clean workspace----
rm(list=ls())
