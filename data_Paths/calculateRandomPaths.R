# Objective: Create random paths against which to compare real paths. Random paths have the same starting location and the same number of points (steps) as their real counterparts. The distributions of step lengths and turning angles are drawn from theoretical distributions, whose parameters were obtained by fitting data from our study population.

# Author: A. Droghini (adroghini@alaska.edu)

#### Load packages and data ----
load(file="pipeline/telemetryData/gpsData/04-formatForCalvingSeason/gpsCalvingSeason.Rdata")

angles <- as.numeric(read_csv(file="pipeline/paths/randomRadians.csv",col_names=FALSE)$X1)
distances <- as.numeric(read_csv(file="pipeline/paths/randomDistances.csv",col_names=FALSE)$X1)

#### Format data ----

# Create  dataframe that includes starting location for every moose-Year and number of total steps
# We can simply filter by RowID, since this variable numbers every location based on date-time (from earliest to latest) for each moose-Year path.

temp <- gpsCalvingSeason %>%
  filter(RowID==1) %>% 
  dplyr::select(mooseYear_id,Easting,Northing)

# Define variables for function
x <- temp$Easting
y <- temp$Northing
ids <- vector("list", 42)
names(ids) <- temp$mooseYear_id

# Calculate total number of points per moose-Year path
# Each random path will contain the same number of points as the observed path it was based on
pathLength <- (plyr::count(gpsCalvingSeason, "mooseYear_id"))$freq

rm(temp)

#### Calculate random coordinates ----

# https://stackoverflow.com/questions/7222382/get-lat-long-given-current-point-distance-and-bearing
# https://www.fcc.gov/media/radio/find-terminal-coordinates
# geosphere package returns longitude and latitude given starting location (in degrees), a bearing (in degrees), and a distance (in meters). Default values for radius and flattening of the Earth is for WGS 84
# Error between this function and FCC website is a lot less than 10 m i.e. within the margin of error of our raster layers

######## Might be easier to calculate using Eastings/Northings- bypasses the Earth radius problem ######## not sure.. If the distances are anything larger than a few miles they will diverge from the globe and be up in the air???   
#otherwise can use geosphere package destPoint, but i don't know if we need to specify a radius because we are so far north??

# https://math.stackexchange.com/questions/143932/calculate-point-given-x-y-angle-and-distance

createRandomPoints <- function(x,y,pathLength,ids,
                               angles,distances){
  
  for (a in 1:length(x)) {
    cat("Generating random points for path", names(ids[a]), "\n")
    
    initX = x[a] # define starting location for moose-Year path 'a'
    initY = y[a]
    
    numberOfPoints = pathLength[a]
    
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
        randomPoints <- data.frame(x = randomX, y = randomY)
      } else {
        randomPoints[n, 1] <- randomX
        randomPoints[n, 2] <- randomY
      }
      
      # Before moving onto next moose-Year path, add all generated random points to the ids list, which is where we will be storing our results
      if (n == 10) {
        ids[[a]] <- c(ids[[a]],
                      list(randomX = randomPoints$x, randomY = randomPoints$y))
      } else {
        
      }
      
      # Move onto the next point to be generated for this moose-Year path.
      n = n + 1
      
    }
    
  }

  return(ids)
  
}

# Test function
results <- createRandomPoints(x,y,pathLength,ids,angles,distances)