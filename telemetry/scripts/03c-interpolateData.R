# Objective: Create a regular time series by using an interpolation algorithm on missed fixes.

# Author: Amanda Droghini (adroghini@alaska.edu)

# The move::interpolateTime function takes a very literal approach to creating a regular time series
# A timestamp that is one second off (e.g. 00:00:01) will not be included in the final object
# However, as far as I can tell, the location information from that irregular timestamp is still considered, since the location at 00:00:00 will be identical to the location at 00:00:01
# What happens though is that there is a loss of all "non-essential" information that might have been included in that irregular record e.g. DOP, height, temperature
# I don't foresee needing those columns for any future analyses, so I think this loss of information is fine
# This is the same behavior of the zoo::na.approx function

# Load packages and data----
rm(list=ls())

library(move)
library(tidyverse)

load("pipeline/03b_cleanLocations/cleanLocations.Rdata")

# Remove extraneous columns
# Every column whose timestep is not exactly within the specified time interval (i.e. 2 hours) will get interpolated and filled with NAs
gpsData <- as.data.frame(gpsMove)
names(gpsData)

gpsData <- gpsData %>% 
  select(Easting,Northing,datetime,deployment_id)

gpsMove <- move(x=gpsData$Easting,y=gpsData$Northing,
                time=gpsData$datetime,
                data=gpsData,proj=CRS("+init=epsg:32604"),
                animal=gpsData$deployment_id, sensor="gps")

# Interpolate missed fixes----

# Create a mini function... For some reason lapply doesn't work directly with the interpolateTime function?
fillMissedFixes <- function(data){
  moveObj <- data
  interpolateTime(moveObj,
                  time=as.difftime(2,units="hours"),
                  spaceMethod = "euclidean")
}

splitData <- split(gpsMove)

interpolateData <- lapply(splitData,
                          fillMissedFixes)

rm(gpsData,fillMissedFixes,splitData)

# Convert back to moveStack object----
# Slowly starting to understand the structure of a move object....
mooseData <- moveStack(interpolateData)

# Additional 207 records were created

# See which individuals had the most records added in
n.locs(gpsMove) 
n.locs(mooseData)

# Those numbers makes sense seeing as approximately half of all individuals have no data for at least one entire day (12 fixes * 12 ids = 144), in addition to other missed fixes + ~35 manually inserted missed fixes when weeding out outliers

gpsData <- as.data.frame(mooseData)
rownames(gpsData) <- seq(1,nrow(gpsData),by=1)

coords.x1 <- gpsData$coords.x1
coords.x2 <- gpsData$coords.x2
timestamps <- gpsData$timestamps
trackId <- gpsData$trackId
gpsData <- gpsData %>% select(trackId)

gpsMove <- move(x=coords.x1,y=coords.x2,
                time=timestamps,
                proj=CRS("+init=epsg:32604"),
                animal=trackId, sensor="gps")

rm(interpolateData,mooseData,coords.x1,coords.x2,timestamps,trackId,gpsData)

# Save object
save(gpsMove,file="pipeline/03c_interpolateData/mooseData.Rdata")
