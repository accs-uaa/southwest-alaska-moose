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

rm(fillMissedFixes,splitData)

# Convert back to moveStack object----
# I don't understand the structure of a move object....
mooseData <- moveStack(interpolateData)

# Additional 207 records were created

# See which individuals had the most records added in
n.locs(gpsMove) 
n.locs(mooseData)

# Those numbers makes sense seeing as approximately half of all individuals have no data for at least one entire day (12 fixes * 12 ids = 144), in addition to other missed fixes + ~35 manually inserted missed fixes when weeding out outliers

# Check to see that interpolated locations are within study area extent
plot(mooseData@coords)

rm(interpolateData,gpsData,gpsMove)

# Save object
save(mooseData,file="pipeline/03c_interpolateData/mooseData.Rdata")
