# Objectives: Explore empirical distribution of step lengths and turning angles for GPS data. Generate random distribution based on theoretical distributions: gamma for step length and von Mises/uniform for turning angles. Generate different distributions depending on calfAtHeel status.

# Code to generate theoretical distributions was adapted from the source code for the amt::distributions function (https://github.com/jmsigner/amt/)

# Relevant literature:
# 1) Forester JD, Im HK, Rathouz PJ. 2009. Accounting for animal movement in estimation of resource selection functions: Sampling and data analysis. Ecology 90:3554–3565.

# 2) Signer J, Fieberg J, Avgar T. 2019. Animal movement tools (amt): R package for managing tracking data and conducting habitat selection analyses. Ecology and Evolution 9:880–890.

# Author: A. Droghini (adroghini@alaska.edu)

#### Load packages and data----
source("package_Paths/init.R")
load(file="pipeline/telemetryData/gpsData/04-formatForCalvingSeason/gpsCalvingSeason.Rdata")

#### Format data----

# Separate calfAtHeel = 0 from calfAtHeel1
calf1 <- gpsCalvingSeason %>% 
  dplyr::filter(calfAtHeel==1)

calf0 <- gpsCalvingSeason %>% 
  dplyr::filter(calfAtHeel==0)

# Create move object
# Coordinates are in WGS 84
tracks1 <- move::move(calf1$longX, calf1$latY, 
                     time=calf1$datetime,
                     animal=calf1$mooseYear_id,
                     sensor=calf1$sensor_type,
                     proj = sp::CRS("+proj=longlat +datum=WGS84 +no_defs +ellps=WGS84 +towgs84=0,0,0"))

tracks0 <- move::move(calf0$longX, calf0$latY, 
                      time=calf0$datetime,
                      animal=calf0$mooseYear_id,
                      sensor=calf0$sensor_type,
                      proj = sp::CRS("+proj=longlat +datum=WGS84 +no_defs +ellps=WGS84 +towgs84=0,0,0"))

#### Calculate movement metrics ----
# Calculate time lags, step lengths, and bearing between locations
calf1$time_interval <- unlist(lapply(move::timeLag(tracks1, units="hours"),  c, NA))
calf1$bearing_degrees <- unlist(lapply(move::angle(tracks1), c, NA))
calf1$distance_meters <- unlist(lapply(move::distance(tracks1), c, NA))

calf0$time_interval <- unlist(lapply(move::timeLag(tracks0, units="hours"),  c, NA))
calf0$bearing_degrees <- unlist(lapply(move::angle(tracks0), c, NA))
calf0$distance_meters <- unlist(lapply(move::distance(tracks0), c, NA))

#### Plot empirical distributions -----
hist(calf1$bearing_degrees,
     main="Empirical distribution of bearings",
     xlab="Bearing (degrees)")

hist(calf0$bearing_degrees,
     main="Empirical distribution of bearings",
     xlab="Bearing (degrees)")
# No evidence of directional persistence.

hist(calf1$distance_meters)
hist(log(calf1$distance_meters))
summary(calf1$distance_meters) 

hist(calf0$distance_meters)
hist(log(calf0$distance_meters))
summary(calf0$distance_meters) # A few large distances (>8 km), but nothing that is impossible to achieve in 2 hours.

rm(tracks0,tracks1)

#### Gamma distribution for distances ----

# Create numeric vector of empirical step length distances
distances1 <- (calf1 %>% 
  filter(!is.na(distance_meters)) %>% 
  dplyr::select(distance_meters))$distance_meters

distances0 <- (calf0 %>% 
                filter(!is.na(distance_meters)) %>% 
                dplyr::select(distance_meters))$distance_meters

# Cannot have values of 0- will throw an error. Replace 0 values with the smallest, non-zero minimum distance, as done in the amt package.
minDist <- min(distances1[distances1 !=0])
distances1[distances1 == 0] <- minDist

minDist <- min(distances0[distances0 !=0])
distances0[distances0 == 0] <- minDist

# Fit data to gamma distribution. Use lower argument to constrain estimated parameters to positive numbers only, as required by gamma distribution. Parameters estimated using MLE.
fitGamma1 <- MASS::fitdistr(x = distances1, 
                           densfun = "gamma", lower = c(0,0))
fitGamma0 <- MASS::fitdistr(x = distances0, 
                            densfun = "gamma", lower = c(0,0))

#### Uniform distribution for angles ----
# Use the Von Mises distribution (appropriate for circular data)
# Requires two parameters: μ (mean = median = mode) and κ
# If κ = 0, distribution is uniform

# Check to see that our empirical data approximates a uniform distribution
turnAngles1 <- (calf1 %>% 
                filter(!is.na(bearing_degrees)) %>% 
                dplyr::select(bearing_degrees))$bearing_degrees
turnAngles1 <- circular::rad(turnAngles1)
fitVM1 <- circular::as.circular(turnAngles1, type = "angles", 
                           units = "radians", 
                           template = "none",
                           modulo = "asis", 
                           zero = 0, 
                           rotation = "counter")

turnAngles0 <- (calf0 %>% 
                  filter(!is.na(bearing_degrees)) %>% 
                  dplyr::select(bearing_degrees))$bearing_degrees
turnAngles0 <- circular::rad(turnAngles0)
fitVM0 <- circular::as.circular(turnAngles0, type = "angles", 
                                units = "radians", 
                                template = "none",
                                modulo = "asis", 
                                zero = 0, 
                                rotation = "counter")
# Get parameters
circular::mle.vonmises(fitVM1)
circular::mle.vonmises(fitVM0)
# κ = 0.016 and 0.041 - distribution is approx. uniform.

#### Generate random distances and angles ----
randomDistances1 <- rgamma(n = 1e+06, shape=fitGamma1$estimate[[1]], 
                          rate = fitGamma1$estimate[[2]])
randomDistances0 <- rgamma(n = 1e+06, shape=fitGamma0$estimate[[1]], 
                           rate = fitGamma0$estimate[[2]])

# For random angles, set κ = 0 to generate a uniform distribution
# Set μ = 0, meaning left and right turns are equally likely. This is a property of the circular uniform distribution (https://en.wikipedia.org/wiki/Circular_uniform_distribution); also Avgar et al. 2016
randomAngles <- circular::rvonmises(n=1e+06, mu=circular(0), 
                          kappa=0)

# Convert 'circular' structure to numeric vector
randomAngles <- as.numeric(randomAngles) 
hist(randomAngles)

#### Export random numbers ----
write_csv(as.data.frame(randomDistances1), 
          file="pipeline/paths/randomDistances_calf1.csv",
          col_names = FALSE)
write_csv(as.data.frame(randomDistances0), 
          file="pipeline/paths/randomDistances_calf0.csv",
          col_names = FALSE)
write_csv(as.data.frame(randomAngles), 
          file="pipeline/paths/randomRadians.csv",
          col_names = FALSE)

#### Clean workspace ----
rm(list=ls())