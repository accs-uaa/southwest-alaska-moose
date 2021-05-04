# Objectives: Explore empirical distribution of step lengths and turning angles for GPS data. Generate random distribution based on theoretical distributions: gamma for step length and von Mises/uniform for turning angles. 

# We generated different step length distributions based on calfAtHeel status because movement patterns of cows with calves are very different than patterns of cows without calves.

# Code to generate theoretical distributions was adapted from the source code for the amt::distributions function (https://github.com/jmsigner/amt/)

# Relevant literature:
# 1) Forester JD, Im HK, Rathouz PJ. 2009. Accounting for animal movement in estimation of resource selection functions: Sampling and data analysis. Ecology 90:3554–3565.

# 2) Signer J, Fieberg J, Avgar T. 2019. Animal movement tools (amt): R package for managing tracking data and conducting habitat selection analyses. Ecology and Evolution 9:880–890.

# Author: A. Droghini (adroghini@alaska.edu)

rm(list = ls())

# Define Git directory ----
git_dir <- "C:/Work/GitHub/southwest-alaska-moose/package_Paths/"

#### Load packages and functions ----
source(paste0(git_dir,"init.R"))
source(paste0(git_dir,"function-exploreMoveMetrics.R"))
source(paste0(git_dir,"function-gammaDistribution.R"))
source(paste0(git_dir,"function-vonMisesDistribution.R"))

#### Load data ----
load(file=paste0(pipeline_dir,"04-formatForCalvingSeason/","gpsCalvingSeason.Rdata"))

#### Explore movement metrics ----
# Some deviation from uniform in bearings plot for cows with calves
# Step lengths: cows w/o calves show a few large distances (>6 km), but nothing that is impossible to achieve in 2 hours
calvingSeason$sensor_type <- "GPS"
dataCalf1 <- exploreMoveMetrics(calvingSeason,group=1)
dataCalf0 <- exploreMoveMetrics(calvingSeason,group=0)
summary(dataCalf1$distance_meters)
summary(dataCalf0$distance_meters)

#### Generate gamma distribution ----
# For distances

# Fit gamma distribution to data
# Generate random numbers
# Set seed for reproducibility

# For paths with calves
set.seed(121190)
fitGamma <- gammaDistribution(dataCalf1$distance_meters) 
distCalf1 <- rgamma(n = 1e+06,
                    shape = fitGamma$estimate[[1]],
                    rate = fitGamma$estimate[[2]])

rm(fitGamma)

# For paths without calves
set.seed(062687)
fitGamma <- gammaDistribution(dataCalf0$distance_meters) 
distCalf0 <- rgamma(n = 1e+06,
                    shape = fitGamma$estimate[[1]],
                    rate = fitGamma$estimate[[2]])

#### Generate random angles ----
# Fit Von Mises distribution, which is appropriate for circular data
# Requires two parameters: μ (mean = median = mode) and κ

# First, check to see that our empirical data approximates a uniform distribution (κ = 0)
# In this case, κ = 0.0089 and 0.02
vonMisesDistribution(dataCalf1$bearing_degrees)
vonMisesDistribution(dataCalf0$bearing_degrees)

# Generate only one set of random numbers to use for both paths with & without calves
# Set κ = 0 to generate a uniform distribution
# Set μ = 0, meaning left and right turns are equally likely. This is a property of the circular uniform distribution (https://en.wikipedia.org/wiki/Circular_uniform_distribution); also Avgar et al. 2016
set.seed(010658)
randomAngles <- circular::rvonmises(n=1e+06, mu=circular(0), 
                          kappa=0)

# Convert 'circular' structure to numeric vector
randomAngles <- as.numeric(randomAngles) 
hist(randomAngles)

#### Export random numbers ----
write_csv(as.data.frame(distCalf1), 
          file=paste0(pipeline_dir,"01-generateDistributions/",
                      "randomDistances_calf1.csv"),
          col_names = FALSE)
write_csv(as.data.frame(distCalf0), 
          file=paste0(pipeline_dir,"01-generateDistributions/",
                      "randomDistances_calf0.csv"),
          col_names = FALSE)
write_csv(as.data.frame(randomAngles), 
          file=paste0(pipeline_dir,"01-generateDistributions/",
                      "randomRadians.csv"),
          col_names = FALSE)

# Export as .Rdata list for use in the next script
dist <- list(randomAngles,distCalf1,distCalf0)
names(dist) <- (c("angles","distCalf1","distCalf0"))
save(dist, file=paste0(pipeline_dir,"01-generateDistributions/",
                       "theoreticalDistributions.Rdata"))

#### Clean workspace ----
rm(list=ls())