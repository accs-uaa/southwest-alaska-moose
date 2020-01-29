# Objective: Examine GPS data for issues: outliers, duplicates, and skips.

# Last updated: 29 Jan 2020

# Author: A. Droghini (adroghini@alaska.edu)
#         Alaska Center for Conservation Science
#         With code from P. Schuette and the AniMove 2019 workshop

#### Load packages and data----
library(tidyverse)
library(move)
library(ctmm)

load("output/gps_raw.Rdata")


#### Format and explore data----
# Format date/time: Get date and time in one column. Use UTC timestamp to conform with Movebank requirements
# Add "M" to beginning of CollarID so it is no longer recognized as numeric
# Projection will be addressed in later step

gpsData <- gpsData %>% 
  mutate(datetime = as.POSIXct(paste(gpsData$UTC_Date, gpsData$UTC_Time), format="%m/%d/%Y %I:%M:%S %p",tz="UTC"), CollarID = paste("M", gpsData$CollarID, sep=""))

# Create unique row number for each device, according to date/time
# Coerce back to dataframe (needed for move package)
gpsData <- gpsData %>% 
  group_by(CollarID) %>% 
  arrange(datetime) %>% 
  mutate(RowID = row_number()) %>% 
  arrange(CollarID,RowID) 

gpsData <- as.data.frame(gpsData) 
# Note that RowID is now unique within but not across individuals

# Explore data for outliers
plot(gpsData$Long_X, gpsData$Lat_Y, xlab="Longitude", ylab="Latitude")

# Remove outliers with long values in the 13s, which is in Germany where collars are manufactured

gpsData <- gpsData %>% 
  filter(Long_X < -152)

plot(gpsData$Long_X, gpsData$Lat_Y, xlab="Longitude", ylab="Latitude")

summary(gpsData) # no NAs for Lat, Long

#### Convert to Movebank object----
# According to Vectronic manual (https://vectronic-aerospace.com/wp-content/uploads/2016/04/Manual_GPS-Plus-Collar-Manager-V3.11.3.pdf), Lat/Long is in WGS84. I can't find any information on Easting/Northing column, so using Lat/Long for now
names(gpsMove)

gpsMove <- move(x=gpsData$Long_X,y=gpsData$Lat_Y,
             time=gpsData$datetime,
             data=gpsData,proj=CRS("+proj=longlat +ellps=WGS84"),
             animal=gpsData$CollarID, sensor="gps")

show(gpsMove)
show(split(gpsMove))
n.indiv(gpsMove) #

#### Check for additional outliers----
# See vignette: https://ctmm-initiative.github.io/ctmm/articles/error.html
# This is always so hacky & iterative, and I never have a good workflow for this
# 
# 1. Generate ctmm::outlie plots for each individual. High-speed segments are in blue, while distant locations are in red
# 2. If very large outliers are identified, investigate. Consider: 1- Missed fixes, 2- Impossible speeds or distances, 3- Impossible locations

ctData <- as.telemetry(gpsMove)
ids <- names(ctData)

# Grab some coffee in the break room while this runs
for (i in 1:length(ids)){
  out <- outlie(ctData[[i]],plot=TRUE,main=ids[i])
  summary(out$speed)
  summary(out$distance)
  plotName <- paste("outliers",ids[i],sep="")
  filePath <- paste("output/plots/",plotName,sep="")
  finalName <- paste(filePath,"png",sep=".")
  dev.copy(png,finalName)
  dev.off()
}

rm(plotName,filePath,finalName,i)
dev.off()

# Time lags between locations
timeLags <- timeLag(gpsMove, units='hours')

# Print plots
for (i in 1:length(ids)){
  cat("processing moose", ids[i], sep="\n")
  timeL <- timeLags[[i]]
  hist(timeL,main=ids[i],xlab="Hours")
  plotName <- paste("timeLags",ids[i],sep="")
  filePath <- paste("output/plots/",plotName,sep="")
  finalName <- paste(filePath,"png",sep=".")
  dev.copy(png,finalName)
  dev.off()
  print(summary(timeL))
}

# List of collar issues
# M30927 & M30928 - looks like they've been redeployed
which(ids=="M30927" | ids=="M30928")
id <- gpsMove[[6]]
timeLags <- timeLag(id, units='hours')
timeLags <- unlist(timeLags)
summary(timeLags)

id <- id@data # 

plot(out)
which.max(out$distance)
out[1:10,]


bad <- subset(gpsData,CollarID==unique(gpsData$CollarID)[[4]])[1:15,]
plot(bad$Long_X, bad$Lat_Y, xlab="Longitude", ylab="Latitude",type="b")
bad
#Then, also need a metadata file that includes collar id, animal id, deployment date and end
telem.data.meta <- telem.data %>% 
  arrange(datetime) %>%
  group_by(CollarID) %>% 
  slice(1)

telem.data.meta <- as.data.frame(telem.data.meta)

#change datetime to deployment start date
telem.data.meta <- telem.data.meta %>% 
  rename(Deployment_start = datetime)

#End of deployment, or rather, date of downloading collar data
telem.data.end <- telem.data %>% 
  arrange(desc(datetime)) %>%
  group_by(CollarID) %>% 
  slice(1)

#change datetime to deployment end date
telem.data.end <- telem.data.end %>% 
  rename(Deployment_end = datetime)
as.data.frame(telem.data.end)

#Add column for deployment end date to metadata
telem.data.meta <- telem.data.meta %>% 
  mutate(Deployment_end = telem.data.end$Deployment_end)

#View the data
# We now have a metadata file that will help us identify 
# which tags are deployed on which animals
telem.data.meta

#a list of all animals if want to call out specific animals
#telem.data.meta$AnimalID

#This metadata file can be uploaded to Movebank
write.csv(telem.data.meta, file="swmoose.telem.metadata.csv")

