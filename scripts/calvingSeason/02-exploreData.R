# Objective: Explore empirical distribution of step lengths and turning angles for a) GPS and b) VHF data.

# Author: A. Droghini (adroghini@alaska.edu)

#### Load packages and data----
library(tidyverse)
library(move)
load(file="pipeline/calvingSeason/01_formatData/allRelocationData.Rdata")

#### Format data----
# Both GPS collars and VHF relocation coordinates were in WGS 84
tracks <- move::move(allData$longX, allData$latY, time=allData$datetime,
                     animal=allData$deployment_id,
                     proj = sp::CRS("+proj=longlat +datum=WGS84 +no_defs +ellps=WGS84 +towgs84=0,0,0"))

#### Calculate movement metrics----
tracks$angles <- unlist(lapply(angle(tracks), c, NA))
tracks$distanceMeters <- unlist(lapply(move::distance(tracks), c, NA))
# Native speed units are in m/s
tracks$speedKmh <- (unlist(lapply(move::speed(tracks),c, NA )))*3.6

# For VHF, timestamp is not consistently one day. 
hist(tracks$angles)
hist(tracks$distanceMeters/1000)
max(tracks$distanceMeters,na.rm=TRUE)
which(tracks$distanceMeters>110000)
allData[c(723:726),]
allData[c(924:931),]
