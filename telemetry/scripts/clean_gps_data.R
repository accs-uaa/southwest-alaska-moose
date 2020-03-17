# Objective: Examine GPS data for issues: outliers, duplicates, and skips.
# Last updated: 29 Jan 2020

# Author: A. Droghini (adroghini@alaska.edu)
#         Alaska Center for Conservation Science

#### Load packages and data----
library(tidyverse)
library(move)
library(ctmm)

load("output/gps_raw.Rdata") # GPS telemetry data
load("output/deployMetadata.Rdata") # Deployment metadata file
source("scripts/function-collarRedeploys.R")

#### Format GPS data----

# 1. Filter out records for which Date Time, Lat, or Lon is NA
# 2. Combine date and time in a single column ("datetime")
## Use UTC time zone to conform with Movebank requirements
# 3. Rename Latitude.... ; Longitude.... ; Temp...C. ; Height..m.

gpsData <- gpsData %>% 
  filter(!(is.na("Latitude....") | is.na("Longitude....") | is.na(UTC_Date))) %>%
  mutate(datetime = as.POSIXct(paste(gpsData$UTC_Date, gpsData$UTC_Time), 
                               format="%m/%d/%Y %I:%M:%S %p",tz="UTC")) %>% 
  dplyr::rename(longX = "Longitude....", latY = "Latitude....", tempC = "Temp...C.",
         height_m = "Height..m.", tag_id = CollarID, mortalityStatus = "Mort..Status")

#### Correct redeploys----

# Filter deployment metadata to include only GPS data and redeploys
# Redeploys are differentiated from non-redeploys because they end in a letter
redeployList <- deploy %>% 
  filter(sensor_type == "GPS" & (grepl(paste(letters, collapse="|"), deployment_id))) %>% 
  select(deployment_id,tag_id,deploy_on_timestamp,deploy_off_timestamp) 

# Format LMT Date column as POSIX data type for easier filtering
gpsData$LMT_Date = as.POSIXct(strptime(gpsData$LMT_Date, 
                                       format="%m/%d/%Y",tz="America/Anchorage"))

# Use tagRedeploy function to evaluate whether a tag is unique or has been redeployed
gpsData$tagStatus <- tagRedeploy(gpsData$tag_id,redeployList$tag_id)

# The next part is janky because my function writing skills are not great
# The makeRedeploysUnique function only works on redeploys so I need to filter out redeploys & then merge back in with the rest of the data
# The function also identifies "errors" e.g. when the collar is left active in the office between deployments. I need to filter these out manually before merging back
gpsRedeployOnly <- subset(gpsData,tagStatus=="redeploy")
gpsUniqueOnly <- subset(gpsData,tagStatus!="redeploy")

gpsRedeployOnly$deployment_id <- apply(X=gpsRedeployOnly,MARGIN=1,FUN=makeRedeploysUnique,redeployData=redeployList)

# Filter out errors and rbind with non-redeploys
gpsRedeployOnly <- subset(gpsRedeployOnly,deployment_id!="error")
gpsUniqueOnly$deployment_id <- paste0("M",gpsUniqueOnly$tag_id,sep="")

gpsData <- rbind(gpsUniqueOnly,gpsRedeployOnly)

# Check
unique(gpsData$deployment_id)
length(unique(gpsData$deployment_id)) # Should be 24

# Clean workspace
rm(gpsRedeployOnly,gpsUniqueOnly,redeployList,makeRedeploysUnique,tagRedeploy)

#### Create unique row number----
# For each device, according to date/time
# Note that RowID is now unique within but not across individuals
gpsData <- gpsData %>% 
group_by(deployment_id) %>% 
  arrange(datetime) %>% 
  dplyr::mutate(RowID = row_number()) %>% 
  arrange(deployment_id,RowID) %>% 
  ungroup() %>% 
  select(RowID,everything())
 

# Join with deployment metadata to get individual animal ID


#### Explore data for outliers----

# Coerce back to dataframe (needed for move package)
gpsData <- as.data.frame(gpsData) 

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
n.indiv(gpsMove) # no of individuals
n.locs(gpsMove) # no of locations per individuals

#### Check for additional outliers----
# See vignette: https://ctmm-initiative.github.io/ctmm/articles/error.html
# This is always so hacky & iterative, and I never have a good workflow for this
# 
# 1. Check time lags. A lot of the times the problems stem for unidentified redeployments or collar issues at the start/end of deployment
# 1. Check loctaion outliers. 
# 2. Investigate outliers manually. Consider: 1- Missed fixes, 2- Impossible speeds or distances, 3- Impossible locations

ctData <- as.telemetry(gpsMove)
ids <- names(ctData)

# Time lags between locations
timeLags <- timeLag(gpsMove, units='hours')
# Fix rate is 2 hours

# Print summaries & plots
lagSummary <- data.frame(row.names = ids)

for (i in 1:length(ids)){
  timeL <- timeLags[[i]]
  lagSummary$min[i] <- min(timeL)
  
  lagSummary$mean[i] <- mean(timeL)
  lagSummary$sd[i] <- sd(timeL)
  lagSummary$max[i] <- max(timeL)
  
  hist(timeL,main=ids[i],xlab="Hours")
  plotName <- paste("timeLags",ids[i],sep="")
  filePath <- paste("output/plots/",plotName,sep="")
  finalName <- paste(filePath,"png",sep=".")
  dev.copy(png,finalName)
  dev.off()

}

rm(plotName,filePath,finalName,i)

# Collars with time lag issues----
subset(lagSummary, max > 2.05)$ids

# M30927 & M30928 were redeployed. Need to recode (done at a later step).

# investigating... 103
which(ids=="M30103")
id <- gpsMove[[2]]
id <- id@data
timeL <- timeLags[[2]]
which(timeL>2.05)

View(id[1:20,]) # 1. Solution: Delete start (n=6). Time lags are erratic for the first few days.
View(id[970:985,]) # No data on 28 Jun 2018 but doesn't seemed to have moved much. Can we apply Kalman filtering?
test <- id[960:985,]
plot(test$Long_X, test$Lat_Y, type="b") 
rm(test)

# investigating... 104
which(ids=="M30104")
id <- gpsMove[[3]]
id <- id@data
timeL <- timeLags[[3]]
which(timeL>2.05)
View(id[965:975,]) # Same issue as M30103. Conspiracy!

# investigating... 105
id <- gpsMove[[4]]
id <- id@data
timeL <- timeLags[[4]]
which(timeL>2.05)
View(id[1:10,]) # 1. Solution: Delete start (n=5).
View(id[1704:1715,]) #2. No data for 3AM fix on 8/26/2018. Need to solve*

# investigating... M30894
id <- gpsMove[[5]]
id <- id@data
timeL <- timeLags[[5]]
which(timeL>2.05)
View(id[1:15,]) # 1. Solution: Delete start (n=8).
View(id[1315:1345,]) #2. Missing two fixes at 11AM on two consecutive days. Need to solve*
View(id[6900:6910,]) # Missing a couple of other fixes- should be able to interpolate.

# investigating... M30930
which(ids=="M30930")
id <- gpsMove[[9]]
id <- id@data
timeL <- timeLags[[9]]
which(timeL>2.05) # Missing a couple of non-consecutive fixes- should be able to interpolate.

# investigating... M30931
id <- gpsMove[[10]]
id <- id@data
timeL <- timeLags[[10]]
which(timeL>2.05) # Missing a couple of non-consecutive fixes- should be able to interpolate.
View(id[1:10,]) # 1. Solution: Delete start (n=5).

# investigating... M30932
id <- gpsMove[[11]]
id <- id@data
timeL <- timeLags[[11]]
which(timeL>2.05) # Missing a couple of non-consecutive fixes- should be able to interpolate.

# investigating... M30933
id <- gpsMove[[12]]
id <- id@data
timeL <- timeLags[[12]]
which(timeL>2.05) # Only missing one

# investigating... M30935
id <- gpsMove[[14]]
id <- id@data
timeL <- timeLags[[14]]
which(timeL>2.05) 
View(id[1:10,]) # 1. Solution: Delete start (n=5). Only missing one more.

# investigating... M30937
id <- gpsMove[[15]]
id <- id@data
timeL <- timeLags[[15]]
which(timeL>2.05) 
View(id[1:12,]) # 1. Delete start (n=7). Only missing three more scattered throughout data set.

# investigating... M30938
id <- gpsMove[[16]]
id <- id@data
timeL <- timeLags[[16]]
which(timeL>2.05) # Missing a couple of non-consecutive fixes
View(id[6650:6670,]) 

# investigating... M309389
id <- gpsMove[[17]]
id <- id@data
timeL <- timeLags[[17]]
which(timeL>2.05) # Missing a couple of non-consecutive fixes

# investigating... M30940
id <- gpsMove[[18]]
id <- id@data
timeL <- timeLags[[18]]
which(timeL>2.05) # 1. Delete start (n=7). Only missing two more. 	
View(id[1:12,])

# investigating... M35172
id <- gpsMove[[19]]
id <- id@data
timeL <- timeLags[[19]]
which(timeL>2.05) # Missing a couple of non-consecutive fixes	

# Total number of rows deleted: 6 + 5 + 8 +5 +5 +7 +7 = 43

# Make changes to gpsData for easier filtering & then re-convert to move object

gpsClean <- gpsData %>% 
  filter(!(CollarID == "M30103" & RowID < 144 | CollarID == "M30105" & RowID < 129 |
             CollarID == "M30894" & RowID < 112 | CollarID == "M30931" & RowID < 109 | 
             CollarID == "M30935" & RowID < 109 | CollarID == "M30937" & RowID < 111 | 
             CollarID == "M30940" & RowID < 112))

# 43 rows less than gpsData

# Convert gpsClean to move object
gpsMove <- move(x=gpsClean$Long_X,y=gpsClean$Lat_Y,
                time=gpsClean$datetime,
                data=gpsClean,proj=CRS("+proj=longlat +ellps=WGS84"),
                animal=gpsClean$CollarID, sensor="gps")
ctData <- as.telemetry(gpsMove)
ids <- names(ctData)

# Workspace clean-up
rm(id,timeLags,timeL,lagSummary)

#### Investigate location outliers----
# Using the ctmm::outlie function
# Generate ctmm::outlie plots for each individual
# High-speed segments are in blue, while distant locations are in red

# Grab some coffee in the break room while this runs
ctmmSummary <- data.frame(row.names = ids)

for (i in 1:length(ids)){
  out <- outlie(ctData[[i]],plot=TRUE,main=ids[i])
  ctmmSummary$minSpeed[i] <- min(out$speed)
  ctmmSummary$meanSpeed[i] <- mean(out$speed)
  ctmmSummary$maxSpeed[i] <- max(out$speed)
  ctmmSummary$minDist[i] <- min(out$distance)
  ctmmSummary$meanDist[i] <- mean(out$distance)
  ctmmSummary$maxDist[i] <- max(out$distance)
  plotName <- paste("outliers",ids[i],sep="")
  filePath <- paste("output/plots/",plotName,sep="")
  finalName <- paste(filePath,"png",sep=".")
  dev.copy(png,finalName)
  dev.off()
}

rm(plotName,filePath,finalName,i,ids)
dev.off()