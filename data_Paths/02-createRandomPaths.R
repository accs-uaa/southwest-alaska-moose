# Objective: Generate 10 random paths for every moose-year path. Each random path has the same starting location and the same number of points as the observed path on which it is based. Step lengths and turning angles are randomly sampled from theoretical distributions, whose parameters were obtained by fitting data from our study population.

# Author: A. Droghini (adroghini@alaska.edu)

#### Load packages and data----
rm(list=ls())
source("package_Paths/init.R")
load(file="pipeline/telemetryData/gpsData/04-formatForCalvingSeason/gpsCalvingSeason.Rdata")

angles <- as.numeric(read_csv(file="pipeline/paths/randomRadians.csv",col_names=FALSE)$X1)
distances <- as.numeric(read_csv(file="pipeline/paths/randomDistances.csv",col_names=FALSE)$X1)

#### Create data ----

# Obtain starting location for every moose-year path
# Calculate number of points for every path
startPts <- gpsCalvingSeason %>%
  filter(RowID==1) %>% 
  dplyr::select(mooseYear_id,Easting,Northing)

startPts$length <- (plyr::count(gpsCalvingSeason, "mooseYear_id"))$freq

rm(gpsCalvingSeason)

# Create a list for storing random paths
# The list will contain a named component for every moose-year
allIDs <- unique(startPts$mooseYear_id)
pathsList <- vector("list", length(allIDs))
names(pathsList) <- allIDs

#### Run createRandomPaths function ----
pathsList <- createRandomPaths(initPts = startPts, numberOfPaths = 10, 
                               ids = allIDs, pathLength = startPts$length,
                               angles = angles, distances = distances)

##### Notes ----
# https://stackoverflow.com/questions/7222382/get-lat-long-given-current-point-distance-and-bearing
# https://www.fcc.gov/media/radio/find-terminal-coordinates
# geosphere package returns longitude and latitude given starting location (in degrees), a bearing (in degrees), and a distance (in meters). Default values for radius and flattening of the Earth is for WGS 84
# Error between this function and FCC website is a lot less than 10 m i.e. within the margin of error of our raster layers

######## Might be easier to calculate using Eastings/Northings- bypasses the Earth radius problem ######## not sure.. If the distances are anything larger than a few miles they will diverge from the globe and be up in the air???   
#otherwise can use geosphere package destPoint, but i don't know if we need to specify a radius because we are so far north??

# https://math.stackexchange.com/questions/143932/calculate-point-given-x-y-angle-and-distance