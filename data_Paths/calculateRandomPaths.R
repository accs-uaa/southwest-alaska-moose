# Objective: Create random paths against which to compare real paths. Random paths have the same starting location and the same number of points (steps) as their real counterparts. The distributions of step lengths and turning angles are drawn from theoretical distributions, whose parameters were obtained by fitting data from our study population.

# Author: A. Droghini (adroghini@alaska.edu)

#### Load packages and data ----
load(file="pipeline/telemetryData/gpsData/04-formatForCalvingSeason/gpsCalvingSeason.Rdata")

degrees <- as.numeric(read_csv(file="pipeline/paths/randomDegrees.csv",col_names=FALSE)$X1)
distances <- as.numeric(read_csv(file="pipeline/paths/randomDistances.csv",col_names=FALSE)$X1)
  
#### Calculate random coordinates ----

# https://stackoverflow.com/questions/7222382/get-lat-long-given-current-point-distance-and-bearing
# https://www.fcc.gov/media/radio/find-terminal-coordinates
# geosphere package returns longitude and latitude given starting location (in degrees), a bearing (in degrees), and a distance (in meters). Default values for radius and flattening of the Earth is for WGS 84
# Error between this function and FCC website is a lot less than 10 m i.e. within the margin of error of our raster layers

# Earth radius for 59.23N (mean ~ median of moose latitude): https://rechneronline.de/earth-radius

# From initial starting location
temp <- gpsCalvingSeason[1,5:4]
coords <- c(temp$longX,temp$latY)


create_random_points <- function(coords,bearingDist,distanceDist){
  randomBearing <- sample(x=degrees,
                          size=1,
                          replace=TRUE)
  randomDistance <- sample(x=distances,
                           size=1,
                           replace=TRUE)
  geosphere::destPoint(p=coords, b=randomBearing, d=randomDistance)
}