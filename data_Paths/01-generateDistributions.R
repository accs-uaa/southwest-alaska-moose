# Objectives: Explore empirical distribution of step lengths and turning angles for GPS data. Generate random distribution based on theoretical distributions: gamma for step length and von Mises/uniform for turning angles.

# Code to generate theoretical distributions was adapted from the source code for the amt::distributions function (https://github.com/jmsigner/amt/)

# Relevant literature:
# 1) Forester JD, Im HK, Rathouz PJ. 2009. Accounting for animal movement in estimation of resource selection functions: Sampling and data analysis. Ecology 90:3554–3565.

# 2) Signer J, Fieberg J, Avgar T. 2019. Animal movement tools (amt): R package for managing tracking data and conducting habitat selection analyses. Ecology and Evolution 9:880–890.

# Author: A. Droghini (adroghini@alaska.edu)

#### Load packages and data----
source("package_Paths/init.R")
load(file="pipeline/telemetryData/gpsData/04-formatForCalvingSeason/gpsCalvingSeason.Rdata")

#### Format data----
# Coordinates are in WGS 84
tracks <- move::move(gpsCalvingSeason$longX, gpsCalvingSeason$latY, 
                     time=gpsCalvingSeason$datetime,
                     animal=gpsCalvingSeason$mooseYear_id,
                     sensor=gpsCalvingSeason$sensor_type,
                     proj = sp::CRS("+proj=longlat +datum=WGS84 +no_defs +ellps=WGS84 +towgs84=0,0,0"))

#### Calculate movement metrics ----
# Calculate time lags, step lengths, and bearing between locations
gpsCalvingSeason$time_interval <- unlist(lapply(move::timeLag(tracks, units="hours"),  c, NA))
gpsCalvingSeason$bearing_degrees <- unlist(lapply(move::angle(tracks), c, NA))
gpsCalvingSeason$distance_meters <- unlist(lapply(move::distance(tracks), c, NA))

#### Plot empirical distributions -----
hist(gpsCalvingSeason$bearing_degrees,
     main="Empirical distribution of bearings",
     xlab="Bearing (degrees)")
# No evidence of directional persistence.

hist(gpsCalvingSeason$distance_meters)
hist(log(gpsCalvingSeason$distance_meters))
summary(gpsCalvingSeason$distance_meters) # A few large distances (>8 km), but nothing that is impossible to achieve in 2 hours.

rm(tracks)

#### Gamma distribution for distances ----

# Create numeric vector of empirical step length distances
distances <- (gpsCalvingSeason %>% 
  filter(!is.na(distance_meters)) %>% 
  dplyr::select(distance_meters))$distance_meters

# Cannot have values of 0- will throw an error. Replace 0 values with the smallest, non-zero minimum distance (0.08 m for this dataset), as done in the amt package.
minDist <- min(distances[distances !=0])
distances[distances == 0] <- minDist

# Fit data to gamma distribution. Use lower argument to constrain estimated parameters to positive numbers only, as required by gamma distribution. Parameters estimated using MLE.
fitGamma <- MASS::fitdistr(x = distances, 
                           densfun = "gamma", lower = c(0,0))

#### Uniform distribution for angles ----
# Use the Von Mises distribution (appropriate for circular data)
# Requires two parameters: μ (mean = median = mode) and κ
# If κ = 0, distribution is uniform

# Check to see that our empirical data approximates a uniform distribution
turnAngles<- (gpsCalvingSeason %>% 
                filter(!is.na(bearing_degrees)) %>% 
                dplyr::select(bearing_degrees))$bearing_degrees

turnAngles <- circular::rad(turnAngles)
fitVM <- circular::as.circular(turnAngles, type = "angles", 
                           units = "radians", 
                           template = "none",
                           modulo = "asis", 
                           zero = 0, 
                           rotation = "counter")
# Get parameters
circular::mle.vonmises(fitVM)
# κ = 0.041 - distribution is approx. uniform.

#### Generate random distances and angles ----
randomDistances <- rgamma(n = 1e+06, shape=fitGamma$estimate[[1]], 
                          rate = fitGamma$estimate[[2]])

# For random angles, set κ = 0 to generate a uniform distribution
# Set μ = 0, meaning left and right turns are equally likely. This is a property of the circular uniform distribution (https://en.wikipedia.org/wiki/Circular_uniform_distribution); also Avgar et al. 2016
randomAngles <- circular::rvonmises(n=1e+06, mu=circular(0), 
                          kappa=0)

# Convert 'circular' structure to numeric vector
randomAngles <- as.numeric(randomAngles) 
hist(randomAngles)

#### Export random numbers ----
write_csv(as.data.frame(randomDistances), 
          path="pipeline/paths/randomDistances.csv",
          col_names = FALSE)
write_csv(as.data.frame(randomAngles), 
          path="pipeline/paths/randomRadians.csv",
          col_names = FALSE)

#### Clean workspace ----
rm(list=ls())