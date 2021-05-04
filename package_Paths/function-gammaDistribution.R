# Objective: Generate a random set of numbers from a gamma distribution whose parameters are estimated from the empirical distribution of step lengths for the population of interest.

# Author: A. Droghini (adroghini@alaska.edu)

# User-specified arguments:
# 01. dist: numeric vector of empirical step length distances

gammaDistribution <-
  
  function(dist) {
    dist <- as.numeric(dist)
    dist <- subset(dist, !is.na(dist))
    
    # Cannot have values of 0- will throw an error. Replace 0 values with the smallest, non-zero minimum distance, as done in the amt package.
    minDist <- min(dist[dist != 0])
    dist[dist == 0] <- minDist
    
    # Fit data to gamma distribution. Use lower argument to constrain estimated parameters to positive numbers only, as required by gamma distribution. Parameters estimated using MLE.
    fitGamma <- MASS::fitdistr(x = dist,
                               densfun = "gamma",
                               lower = c(0, 0))
    
    return(fitGamma)
    
  }