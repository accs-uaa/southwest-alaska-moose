# Objective: This function generates movement paths using randomly generated turning angles, step lengths, and starting locations. Each random path has the same number of points as the observed path on which it is based. Step lengths and turning angles are randomly sampled from theoretical distributions, whose parameters were obtained by fitting data from our study population.

# Author: A. Droghini (adroghini@alaska.edu)

# User-specified arguments ----

# randomPoints = a dataframe where each row represents a randomly generated coordinate (ESPG = 3338).

# pathInfo = a dataframe that contains a list of each sampling unit (i.e., animal individuals or moose-year-status in our case), calf status, number of points to be generated for each path (i.e., path length), and number of paths to be generated for each moose-year .

# dist = a list that contains vectors of turning angles and distances used to generate a random coordinate. Turning angles are in radians and distances are in meters.

# Output ----

# The output is a nested list that has the same number of components as the number of observed paths. Each component has n number of elements, where n = numberOfPaths. Each n is a list of 2 elements, x and y, which contain l number of paired xy coordinates, where l = pathLength.

# Notes ----
# Typical formula for calculating (x2,y2) uses cos(theta) for x and sin(theta) for y. This formula assumes that theta is a standard angle measured CCW from the positive x-axis (East).
# In this function, we use sin(theta) for x and cos(theta) for y because angles represent bearings, which are measured clockwise from North.
# This formula may not be suitable if distances are anything larger than a few miles.

# Function ----
createRandomPaths <-
  function(randomPoints, pathInfo, dist) {

ids <- unique(pathInfo$idYearStatus)
pathsList <- vector("list", length(ids))
names(pathsList) <- ids

for (i in 1:length(ids)) {
  
  # Define variables
  idYearCalf <- ids[i]
  pathInfo_id <- subset(pathInfo, idYearStatus == idYearCalf)
  idOnly <- str_split(idYearCalf,pattern="_")[[1]][1]
  startPoints <- subset(randomPoints, deployment_id == idOnly)
  length <- pathInfo_id$length  
  status <- pathInfo_id$status
  numberOfPaths <- pathInfo_id$numberOfPaths
  
  # Start ticker for number of paths
  # Cycle through as many random start points as the number of paths specified
  a = 1
  
  while (a <= numberOfPaths) {
    
    # Specify starting coordinates and dataframe to store results
    start_X <- startPoints$POINT_X[a]
    start_Y <- startPoints$POINT_Y[a]
    pathsDf <- data.frame(x = start_X, y = start_Y)
    
    cat("Generating",length,
      "random points for moose-year",idYearCalf,
      "..... path", a, "of", numberOfPaths, "\n")
    
    cat("Initial coordinates are", start_X, start_Y, "\n")
    
    # Generate path that is the same length as observed path
    # Start ticker b = 2 because initial location has already been generated.
    b = 2
    
    while (b <= length) {
      # Draw random bearing and distance from distribution
      # Distance distribution is different depending on reproductive status
      randomBearing <- sample(x = dist$angles,
                              size = 1,
                              replace = TRUE)
      
      if (status == 1) {
        randomDistance <- sample(x = dist$distCalf1,
                                 size = 1,
                                 replace = TRUE)
      } else {
        randomDistance <- sample(x = dist$distCalf0,
                                 size = 1,
                                 replace = TRUE)
      }
      
      
      # Calculate new coordinates. Overwrite original ones.
      start_X <- randomDistance * sin(randomBearing) + start_X
      start_Y <- randomDistance * cos(randomBearing) + start_Y
      
      # Add results to a dataframe
      pathsDf[b, 1:2] <- rbind(start_X, start_Y)
      
      b <- b + 1
    }
    
    # Add results to list
    pathsList[i][[1]][[a]] <-
      list(x = as.numeric(pathsDf$x),
           y = as.numeric(pathsDf$y))
    
    a <- a + 1
    
    }
 
}
return(pathsList)
  }