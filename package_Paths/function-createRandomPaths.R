# Objective: This function generates a specified number of random paths for each observed path. Each random path has the same starting location and the same number of points as the observed path on which it is based. Step lengths and turning angles are randomly sampled from theoretical distributions, whose parameters were obtained by fitting data from our study population.

# Author: A. Droghini (adroghini@alaska.edu)

# User-specified arguments ----

# 01. initPts = a dataframe where each row represents that starting XY coordinates of the observed paths. XY coordinates must be stored in columns named Easting and Northing

# 02. numberOfPaths = # of random paths to generate for every observed moose-year path

# 03. pathLength = # of points to be generated for each path. can be a single number or a vector with the same length and ordering as the number of ids/observed paths.

# 04. angles = vector of turning angles, in radians, from which to randomly sample an angle that is used to generate a random XY coordinate.

# 05. distances = vector of distances (step lengths), in meters, from which to randomly sample a distance that is used to generate a random XY coordinate.

# Output ----

# The output is a nested list that has the same number of components as the number of observed paths. Each component has n number of elements, where n = numberOfPaths. Each n is a list of 2 elements, x and y, which contain l number of paired xy coordinates, where l = pathLength.

# Notes ----
# Typical formula for calculating (x2,y2) uses cos(theta) for x and sin(theta) for y. This formula assumes that theta is a standard angle measured CCW from the positive x-axis (East).
# In this function, we use sin(theta) for x and cos(theta) for y because angles represent bearings, which are measured clockwise from North.
# This formula may not be suitable if distances are anything larger than a few miles.

# Function ----
createRandomPaths <-
  function(initPts, numberOfPaths, ids, pathLength, angles, distances) {
    for (p in 1:nrow(initPts)) {
      # Ticker for number of paths
      a = 1
      
      while (a <= numberOfPaths) {
        # Define variables
        startX <- initPts$Easting[p]
        startY <- initPts$Northing[p]
        
        id <- ids[p]
        length <- pathLength[p]
        
        pathsDf <- data.frame(x = startX, y = startY)
        
        cat(
          "Generating",
          length,
          "random points for moose-year",
          id,
          "..... path",
          a,
          "of",
          numberOfPaths,
          "\n"
        )
        
        cat("Initial coordinates are", startX, startY, "\n")
        
        # Ticker for path length
        # Start at b = 2 because initial location has already been generated.
        
        b = 2
        
        while (b <= length) {
          # Draw random bearing and distance from distribution
          randomBearing <- sample(x = angles,
                                  size = 1,
                                  replace = TRUE)
          
          randomDistance <- sample(x = distances,
                                   size = 1,
                                   replace = TRUE)
          
          # Calculate new coordinates
          startX <- randomDistance * sin(randomBearing) + startX
          startY <- randomDistance * cos(randomBearing) + startY
          
          # Add results to a dataframe
          pathsDf[b, 1:2] <- rbind(startX, startY)
          
          b <- b + 1
        }
        
        # Add results to a list
        pathsList[p][[1]][[a]] <-
          list(x = as.numeric(pathsDf$x),
               y = as.numeric(pathsDf$y))
        
        a <- a + 1
        
      }
      
    }
    return(pathsList)
  }