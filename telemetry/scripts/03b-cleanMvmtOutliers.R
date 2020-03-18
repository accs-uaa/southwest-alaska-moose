# Objective: Examine dataset for spatial outliers based on analysis of movement metrics and trajectories

# Author: A. Droghini (adroghini@alaska.edu)

# Load data and packages----

library(ggmap)
library(mapproj)

load("output/gps_cleaned_TimeLags.Rdata")

source("scripts/function-plotOutliers.R")

# Convert to dataframe for plotting
gpsClean <- as.data.frame(gpsMove)

# Plot all individuals----

# Print bounding box extent 
# Multiplicative factor to extend slightly beyond locations
(studyArea<-bbox(extent(gpsMove)*1.2))

# Request map data from Google
mapData <- get_map(studyArea, zoom=9, source="google", maptype="terrain")

# Plot map and add the locations
# This takes a hot second
ggmap(mapData)+
  geom_path(data=gpsClean, aes(x=longX, y=latY,colour=as.factor(deployment_id)))

#### Calculate movement metrics----

## Distances
# Distances are in meters
# Speeds are in m/s
# Not sure what a reasonable sustained (2-hour speed) is but... moose can run. 
# Covering distances of 10 km in two hours is probably not ridiculous
gpsClean$distanceMeters <- unlist(lapply(move::distance(gpsMove), c, NA))
summary(gpsClean$distanceMeters)

which(gpsClean$distanceMeters>9000)

# Plot some of these to see if anything ~~fishy~~ is going on

plotOutliers(gpsClean,66550,66650) # looks ok
temp <- plotOutliers(gpsClean,90500,90650,output=TRUE) # that looks weird. two consecutive fixes had distances >9km: 90599 and 90600



gpsClean$speedMps <- unlist(lapply(move::speed(gpsMove),c, NA ))
summary(speeds)   # PS: We see an outlier in the Max
hist(speeds, breaks="FD")




#### Investigate location outliers----
# Using the ctmm::outlie function
# Generate ctmm::outlie plots for each individual
# High-speed segments are in blue, while distant locations are in red

ctmmData <- as.telemetry(gpsMove)
ids <- names(ctmmData)
movementMetrics <- data.frame(row.names = ids)

# Grab some coffee in the break room while this runs

for (i in 1:length(ids)){
  out <- outlie(ctmmData[[i]],plot=TRUE,main=ids[i])
  movementMetrics$minSpeed[i] <- min(out$speed)
  movementMetrics$meanSpeed[i] <- mean(out$speed)
  movementMetrics$maxSpeed[i] <- max(out$speed)
  movementMetrics$minDistKm[i] <- min(out$distance)/1000
  movementMetrics$meanDistKm[i] <- mean(out$distance)/1000
  movementMetrics$maxDistKm[i] <- max(out$distance)/1000
  plotName <- paste("outliers",ids[i],sep="")
  filePath <- paste("output/plots/",plotName,sep="")
  finalName <- paste(filePath,"png",sep=".")
  dev.copy(png,finalName)
  dev.off()
}

rm(plotName,filePath,finalName,i,ids,out,ctmmData)
dev.off()
