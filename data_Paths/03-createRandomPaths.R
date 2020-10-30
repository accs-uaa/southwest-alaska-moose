# Objective: Using each randomly generated start point, create a random path that contains the same number of points as the observed path it was based on

# Author: A. Droghini (adroghini@alaska.edu)

#### Load packages and data----
rm(list=ls())

load(file="pipeline/telemetryData/gpsData/04-formatForCalvingSeason/gpsCalvingSeason.Rdata")

angles <- as.numeric(read_csv(file="pipeline/paths/randomRadians.csv",col_names=FALSE)$X1)
distances <- as.numeric(read_csv(file="pipeline/paths/randomDistances.csv",col_names=FALSE)$X1)

startPoints <- read_csv(file="pipeline/paths/tempResults.csv")

#### Define function variables ----

# Calculate total number of points per moose-Year path
pathLength <- (plyr::count(gpsCalvingSeason, "mooseYear_id"))$freq

#### Test function ----
start <- results[1,]

pathLength <- 40

for (p in 1:nrow(start)) {
  
  initX <- start$x
  initY <- start$y
  
  n = 1 # set ticker
  
  while (n <= pathLength) {
  
  # draw random bearing and distance from distribution
  randomBearing <- sample(x = angles,
                          size = 1,
                          replace = TRUE)
  
  randomDistance <- sample(x = distances,
                           size = 1,
                           replace = TRUE)
  
  # calculate new coordinates given distance and bearing
  # bearings are measured clockwise from due north
  randomX <- randomDistance * sin(randomBearing) + initX
  randomY <- randomDistance * cos(randomBearing) + initY
  
  initX <- randomX # need to append to some kind of df
  initY <- randomY
  
  n <- n + 1
  }
}