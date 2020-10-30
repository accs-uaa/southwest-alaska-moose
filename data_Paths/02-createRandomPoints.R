# Objective: Create random paths against which to compare real paths. Random paths have the same starting location and the same number of points (steps) as their real counterparts. The distributions of step lengths and turning angles are drawn from theoretical distributions, whose parameters were obtained by fitting data from our study population.

# Author: A. Droghini (adroghini@alaska.edu)

#### Load packages and data ----
load(file="pipeline/telemetryData/gpsData/04-formatForCalvingSeason/gpsCalvingSeason.Rdata")

angles <- as.numeric(read_csv(file="pipeline/paths/randomRadians.csv",col_names=FALSE)$X1)
distances <- as.numeric(read_csv(file="pipeline/paths/randomDistances.csv",col_names=FALSE)$X1)

#### Define arguments for function ----
# The function createRandomPoints requires 5 arguments:

# x = vector of starting X coordinate of each path, in a projected coordinate system
# y = vector of starting Y coordinate of each path, in a projected coordinate system
# id = vector of unique path IDs
# angles = randomly generated angles in radians. in this case, angles were generated using a Von Mises distribution.
# distances = randomly generated distances in meters.

# Starting x y coordinates have a Row ID of 1 in our dataset
# The RowID variable consecutively numbers every location based on date-time (from earliest to latest) for each moose-Year path.

temp <- gpsCalvingSeason %>%
  filter(RowID==1) %>% 
  dplyr::select(mooseYear_id,Easting,Northing)

# Define variables for function
x <- temp$Easting
y <- temp$Northing
ids <- temp$mooseYear_id

rm(temp)

#### Calculate random starting points ----

# https://stackoverflow.com/questions/7222382/get-lat-long-given-current-point-distance-and-bearing
# https://www.fcc.gov/media/radio/find-terminal-coordinates
# geosphere package returns longitude and latitude given starting location (in degrees), a bearing (in degrees), and a distance (in meters). Default values for radius and flattening of the Earth is for WGS 84
# Error between this function and FCC website is a lot less than 10 m i.e. within the margin of error of our raster layers

######## Might be easier to calculate using Eastings/Northings- bypasses the Earth radius problem ######## not sure.. If the distances are anything larger than a few miles they will diverge from the globe and be up in the air???   
#otherwise can use geosphere package destPoint, but i don't know if we need to specify a radius because we are so far north??

# https://math.stackexchange.com/questions/143932/calculate-point-given-x-y-angle-and-distance

createRandomPoints <- function(x,y,ids,
                               angles,distances){
  
  for (a in 1:length(x)) {
    cat("Generating random points for path", ids[a], "\n")
    
    initX = x[a] # define starting location for moose-Year path 'a'
    initY = y[a]
    
    n = 1 # set ticker
    
    while (n < 11) {
      cat("Generating random point", n, "of 10", "\n")
      
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
      
      # Add results to a dataframe
      if (n == 1) {
        randomPoints <- data.frame(x = randomX, y = randomY, 
                                   startX = initX, startY = initY)
      } else {
        randomPoints[n, 1:4] <- rbind(randomX,randomY,
                                                 initX,initY)
      }
      
      # Move onto the next point to be generated for this moose-Year path.
      n = n + 1
      
    }
    
    if (a == 1) {
      randomDf <- randomPoints
    } else {
      randomDf <- rbind(randomPoints,randomDf)
    }
    
  }
  randomDf$id <- rep(ids,each=10)
  return(randomDf)
  
}

# Run function
results <- createRandomPoints(x,y,ids,angles,distances)

##### Export results ----
# Verify in GIS
write_csv(results,"pipeline/paths/tempResults.csv")

# Clean workspace
rm(list=ls())