# Objective: Examine GPS data for issues: outliers, duplicates, and skips.

# Author: A. Droghini (adroghini@alaska.edu)
#         Alaska Center for Conservation Science

#### Load data and packages----
rm(list = ls())

library(tidyverse)
library(move)
library(ctmm)

load("output/gps_clean_all.Rdata")
source("scripts/function-subsetIDTimeLags.R")

#### Convert to Movebank object----
# According to Vectronic manual (https://vectronic-aerospace.com/wp-content/uploads/2016/04/Manual_GPS-Plus-Collar-Manager-V3.11.3.pdf), Lat/Long is in WGS84. 
# Required for calculating timeLags

gpsMove <- move(x=gpsData$longX,y=gpsData$latY,
                time=gpsData$datetime,
                data=gpsData,proj=CRS("+proj=longlat +ellps=WGS84"),
                animal=gpsData$deployment_id, sensor="gps")

# show(gpsMove)
# show(split(gpsMove))
n.indiv(gpsMove) # no of individuals
n.locs(gpsMove) # no of locations per individuals

# Explore data for outliers----
# See vignette: https://ctmm-initiative.github.io/ctmm/articles/error.html
# This is always so hacky & iterative, and I never have a good workflow for this
# 
# 1. Check location outliers. 
# 2. Check time lags. Fix rate is 2 hours- find instances where fix rate is much smaller/larger. A lot of the times the problems stem from unidentified redeployments (though this should have been addressed in previous script) or collar issues at the start/end of deployment
# 3. Investigate outliers manually. Consider: 1- Missed fixes, 2- Impossible speeds or distances, 3- Impossible locations

# Location outliers----

plot(gpsData$longX, gpsData$latY, xlab="Longitude", ylab="Latitude")

summary(gpsData) 

# Will tackle other, less noticeable location outliers on a case-by-case basis later

#### Check for time lag/fix rate issues----

# Calculate time lags between locations
timeLags <- move::timeLag(gpsMove, units='hours')
ids <- unique(gpsData$deployment_id)

# Generate plots and quantitative summary
timelagSummary <- data.frame(row.names = ids)

for (i in 1:length(ids)){
  timeL <- timeLags[[i]]
  
  timelagSummary$id[i] <- ids[i]
  timelagSummary$min[i] <- min(timeL)
  timelagSummary$mean[i] <- mean(timeL)
  timelagSummary$sd[i] <- sd(timeL)
  timelagSummary$max[i] <- max(timeL)
  
  hist(timeL,main=ids[i],xlab="Hours")
  plotName <- paste("timeLags",ids[i],sep="")
  filePath <- paste("output/plots/outliers/",plotName,sep="")
  finalName <- paste(filePath,"png",sep=".")
  dev.copy(png,finalName)
  dev.off()
  
}

rm(plotName,filePath,finalName,i,timeL)

# Collars with time lag issues----

# Basically all of them have problems.

# min goes from 1.95 to 0.44 and max goes from 2.05 to 3.99, so thresholds don't matter too much

# investigating... M30102
subsetID <- subsetTimeLags("M30102",1.95,2.05) # nothing, good to go.

# investigating... M30103
subsetID <- subsetTimeLags("M30103",1.95,2.05)

View(subsetID[1:10,]) # 1. Collar starts on April 5 2018, but fix rates do not become consistent until April 8 (barely any data from 6-7 Apr). Solution: Delete start (n=6).
View(subsetID[970:985,]) # No data on 28 Jun 2018 but doesn't seemed to have moved much. Can we apply Kalman filtering?

# investigating... M30104
subsetID <- subsetTimeLags("M30104",1.95,2.05)
View(subsetID[965:975,]) # Same issue as M30103- no data on 28 June 2018. Conspiracy! Will have to resolve at later date.

# investigating... M30105
subsetID <- subsetTimeLags("M30105",1.95,2.05)
View(subsetID[1:10,]) # 1. Collar starts on 5 April 2018, but fixes do not become consistent until 6 April (no data from 15:00 5 April to 3:00 6 April). Solution: Delete start (n=5).
View(subsetID[1704:1715,]) #2. No data for 3AM fix on 8/26/2018. Need to interpolate*

# investigating... M30894
subsetID <- subsetTimeLags("M30894",1.95,2.05)

View(subsetID[1:15,]) # 1. Collar starts on 5 April 2018, but fixes do not become consistent until 6 April. Solution: Delete start (n=8).
View(subsetID[1315:1345,]) #2. Missing two fixes at 11AM on 24-25 July 2018. Need to interpolate*
View(subsetID[1995:2005,]) # Missing a fix at 7AM 19 September 2018
View(subsetID[3120:3137,]) # Missing a fix at 1AM 2018-12-22
View(subsetID[4650:4660,]) # Missing a fix at 19:00 2019-04-28
View(id[5827:5833,]) # Missing one whole day (5 Aug 2019). Fix goes from 2019-08-04 15:00:29 to 2019-08-06 17:00:19

# investigating... M30926
subsetID <- subsetTimeLags("M30926",1.95,2.05)
View(subsetID[1:10,]) # Fix jumps from 2018-04-05 15:00:42 to 2018-04-05 23:00:15. Solution: Delete start (n=5)
View(subsetID[4855:4930,]) # Datasheet said individual died on 15-05-2019. Stays stationary several days before now. Last time to include will be 2019-05-12 09:00:39 (Row ID 4823). This is the first instance where the moose travels to lon 58.82828	lat -158.0130. All points after that jump around this area.

test <- subset(subsetID,RowID>4800&RowID<4824)
plot(test$longX,test$latY,type="b")
rm(test)

# investigating... M30927a
# this is one of our individuals that died. date of death on datasheet is indicated as 22-05-2018, but may be earlier
# Calculate step lengths distances
subsetID <- subsetTimeLags("M30927a",1.95,2.05,stepLengths=TRUE) # no missed fixes identified

# No obvious point at which animal stops moving so don't remove anything off the end for now

# investigating... M30927b
subsetID <- subsetTimeLags("M30927b",1.95,2.05)
View(subsetID[1533:1540,]) # Jumps from 2019-08-06 19:00:43 to 2019-08-07 21:00:29. Need to interpolate*

# investigating... M30928a
# death date on datasheet written as 20-05-2018
subsetID <- subsetTimeLags("M30928a",1.95,2.05,stepLengths=TRUE) 
View(subsetID[1:8,]) # Jumps from 2018-04-05 15:00:39 to 2018-04-06 05:00:16. Solution: Delete start (n=4)
# Get rid of every record with RowID>519. Arbitrary -- Can revisit later


# investigating... M30928b
subsetID <- subsetTimeLags("M30928b",1.95,2.05)
View(subsetID[1108:1112,]) 
View(subsetID[1495:1500,]) # Random missed fixes

# investigating... M30930
subsetID <- subsetTimeLags("M30930",1.95,2.05)
# Missing a couple of non-consecutive fixes- should be able to interpolate.

# investigating... M30931
subsetID <- subsetTimeLags("M30931",1.95,2.05)
View(subsetID[1:7,]) # 1. Solution: Delete start (n=5).
# Missing a couple of other non-consecutive fixes- should be able to interpolate.

# investigating... M30932
subsetID <- subsetTimeLags("M30932",1.95,2.05)
# Missing a couple of non-consecutive fixes- should be able to interpolate.

# investigating... M30933
subsetID <- subsetTimeLags("M30933",1.95,2.05)
# Only missing one

# investigating... M30934
subsetID <- subsetTimeLags("M30934",1.95,2.05) # good to go

# investigating... M30935
subsetID <- subsetTimeLags("M30935",1.95,2.05)
View(subsetID[1:7,]) # 1. Solution: Delete start (n=5).

# investigating... M30936
subsetID <- subsetTimeLags("M30936",1.95,2.05)
View(subsetID[1:10,]) # 1. Delete start (n=8). 

# investigating... M30937
subsetID <- subsetTimeLags("M30937",1.95,2.05)
View(subsetID[1:12,]) # 1. Delete start (n=7). Only missing three more scattered throughout data set.

# investigating... M30938
subsetID <- subsetTimeLags("M30938",1.95,2.05) # good to go

# investigating... M30939
subsetID <- subsetTimeLags("M30939",1.95,2.05) # Missing a couple of non-consecutive fixes

# investigating... M30940
subsetID <- subsetTimeLags("M30940",1.95,2.05)
View(subsetID[1:12,]) # 1. Delete start (n=7). Only missing two more. 

# investigating... M35172
subsetID <- subsetTimeLags("M35172",1.95,2.05)
which(timeL>2.05) # Only missing one fix

# investigating... M35173
subsetID <- subsetTimeLags("M35173",1.95,2.05) # good to go

# Workspace clean-up
rm(ids,timeLags,subsetID,subsetTimeLags)

gpsClean <- gpsData %>% 
  filter(!(deployment_id == "M30103" & RowID <= 6 | deployment_id == "M30105" & RowID <= 5 | 
             deployment_id == "M30894" & RowID <= 8 | deployment_id == "M30926" & RowID <= 5 |
             deployment_id == "M30926" & RowID > 4823 | deployment_id == "M30928a" & RowID <= 4 |
             deployment_id == "M30928a" & RowID > 519 |
             deployment_id == "M30931" & RowID <= 5 | deployment_id == "M30935" & RowID <= 5 | 
             deployment_id == "M30936" & RowID <= 8 | deployment_id == "M30937" & RowID <= 7 |
             deployment_id == "M30940" & RowID <= 7))

# Total number of rows deleted: 293 (~0.3%)

# Convert gpsClean to move object
gpsMove <- move(x=gpsClean$longX,y=gpsClean$latY,
                time=gpsClean$datetime,
                data=gpsClean,proj=CRS("+proj=longlat +ellps=WGS84"),
                animal=gpsClean$deployment_id, sensor="gps")

rm(gpsData, timelagSummary)

#### Check for duplicated timestamps
duplicateTimes <- getDuplicatedTimestamps(x=as.factor(gpsClean$deployment_id),timestamps=gpsClean$datetime,sensorType="gps") # none
rm(duplicateTimes)

# Export cleaned data as movestack object- easier to work with in subsequent scripts
save(gpsMove,file="output/gps_cleanTimeLags.Rdata")