# Objective: Fit a Von Mises distribution to turning angle data to verify that the empirical distribution approximates the uniform distribution. The function returns the mu and kappa parameters of the fitted distribution.

# Author: A. Droghini (adroghini@alaska.edu)

# User-specified arguments:
# 01. angles: numeric vector of turning angles for the population of interest
vonMisesDistribution <-
  
  function(angles) {
    angles <- as.numeric(angles)
    angles <- subset(angles,!is.na(angles))
    
    angles <- circular::rad(angles)
    
    fitVonMises <- circular::as.circular(
      angles,
      type = "angles",
      units = "radians",
      template = "none",
      modulo = "asis",
      zero = 0,
      rotation = "counter"
    )
    
    print(circular::mle.vonmises(fitVonMises))
    
  }