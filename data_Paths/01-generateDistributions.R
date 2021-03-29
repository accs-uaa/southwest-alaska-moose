# Objectives: Explore empirical distribution of step lengths and turning angles for GPS data. Generate random distribution based on theoretical distributions: gamma for step length and von Mises/uniform for turning angles. 

# We generated different step length distributions based on calfAtHeel status because movement patterns of cows with calves are very different than patterns of cows without calves.

# Code to generate theoretical distributions was adapted from the source code for the amt::distributions function (https://github.com/jmsigner/amt/)

# Relevant literature:
# 1) Forester JD, Im HK, Rathouz PJ. 2009. Accounting for animal movement in estimation of resource selection functions: Sampling and data analysis. Ecology 90:3554–3565.

# 2) Signer J, Fieberg J, Avgar T. 2019. Animal movement tools (amt): R package for managing tracking data and conducting habitat selection analyses. Ecology and Evolution 9:880–890.

# Author: A. Droghini (adroghini@alaska.edu)

#### Load packages and data----
source("package_Paths/init.R")
load(file="pipeline/telemetryData/gpsData/04-formatForCalvingSeason/gpsCalvingSeason.Rdata")

#### Explore movement metrics ----
calvingSeason$sensor_type <- "GPS"
dataCalf1 <- exploreMoveMetrics(calvingSeason,group=1)
dataCalf0 <- exploreMoveMetrics(calvingSeason,group=0)

# Histograms of bearings show no evidence of directional persistence.

# Summary for cows w/o calves show a few large distances (>8 km), but nothing that is impossible to achieve in 2 hours.

#### Generate gamma distribution for distances ----
dist1 <- gammaDistribution(dataCalf1$distance_meters) 
dist0 <- gammaDistribution(dataCalf0$distance_meters) 

#### Generate random angles ----
# Use the Von Mises distribution (appropriate for circular data)
# Requires two parameters: μ (mean = median = mode) and κ

# Check to see that our empirical data approximates a uniform distribution
# If κ = 0, distribution is uniform
vonMisesDistribution(dataCalf1$bearing_degrees)
vonMisesDistribution(dataCalf0$bearing_degrees)
# κ = 0.005 and 0.036 - distribution is approx. uniform.

# To get random angles, set κ = 0 to generate a uniform distribution
# Set μ = 0, meaning left and right turns are equally likely. This is a property of the circular uniform distribution (https://en.wikipedia.org/wiki/Circular_uniform_distribution); also Avgar et al. 2016
randomAngles <- circular::rvonmises(n=1e+06, mu=circular(0), 
                          kappa=0)

# Convert 'circular' structure to numeric vector
randomAngles <- as.numeric(randomAngles) 
hist(randomAngles)

#### Export random numbers ----
write_csv(as.data.frame(dist1), 
          file="pipeline/paths/randomDistances_calf1.csv",
          col_names = FALSE)
write_csv(as.data.frame(dist0), 
          file="pipeline/paths/randomDistances_calf0.csv",
          col_names = FALSE)
write_csv(as.data.frame(randomAngles), 
          file="pipeline/paths/randomRadians.csv",
          col_names = FALSE)

# Export as .Rdata list for use in the next script
dist <- list(randomAngles,dist1,dist0)
names(dist) <- (c("angles","distCalf1","distCalf0"))
save(dist, file="pipeline/paths/theoreticalDistributions.Rdata")

#### Clean workspace ----
rm(list=ls())