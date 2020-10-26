# Objective: Explore empirical distribution of step lengths and turning angles for a) GPS and b) VHF data.

# Author: A. Droghini (adroghini@alaska.edu)

#### Load packages and data----
library(tidyverse)
library(move)
load(file="pipeline/calvingSeason/01_formatData/allRelocationData.Rdata")

#### Format data----
# Both GPS collars and VHF relocation coordinates were in WGS 84
tracks <- move::move(allData$longX, allData$latY, time=allData$datetime,
                     animal=allData$mooseYear_id,
                     sensor=allData$sensor_type,
                     proj = sp::CRS("+proj=longlat +datum=WGS84 +no_defs +ellps=WGS84 +towgs84=0,0,0"))

#### Calculate movement metrics----

# Calculate time lags between locations
allData$timeLag <- unlist(lapply(timeLag(tracks, units="hours"),  c, NA))

allData$angles_degrees <- unlist(lapply(angle(tracks), c, NA))
allData$distance_meters <- unlist(lapply(move::distance(tracks), c, NA))
# Native speed units are in m/s
allData$speed_kmh <- (unlist(lapply(move::speed(tracks),c, NA )))*3.6

# For VHF, timestamp is not consistently one day. 
hist(tracks$angles)
summary(tracks$angles)

hist(tracks$distanceMeters/1000)
summary(tracks$distanceMeters)
