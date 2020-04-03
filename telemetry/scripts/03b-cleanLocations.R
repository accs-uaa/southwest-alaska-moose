# Objective: Examine dataset for spatial outliers based on analysis of movement metrics and trajectories

# Author: A. Droghini (adroghini@alaska.edu)

# Note: I have reran this script with the newest (Mar/Apr 2020 data)
# The number of outliers detected in the Examine distance outliers section stayed the same, but I would have to rerun + relook at the ctmm plots to see if any new outliers came up (since August 2019).
# Since I'm still in the exploratory phase, I'm not sure if it's worth spending half a day combing through this plots again right now. 

# Load data and packages----
source("scripts/init.R")
source("scripts/function-plotOutliers.R")

load("pipeline/03a_cleanFixRate/cleanFixRate.Rdata")


#### Calculate movement metrics----

## Distances
# Units are in meters
# Not sure what a reasonable sustained (2-hour speed) is but... moose can run. 
# Covering distances of 10 km in two hours is probably not ridiculous
gpsMove <- move(x=gpsClean$Easting,y=gpsClean$Northing,
                time=gpsClean$datetime,
                data=gpsClean,proj=CRS("+init=epsg:32604"),
                animal=gpsClean$deployment_id, sensor="gps")

gpsClean$distanceMeters <- unlist(lapply(move::distance(gpsMove), c, NA))

summary(gpsClean$distanceMeters) # NAs should equal number of individuals

#### Examine distance outliers----

which(gpsClean$distanceMeters>8000) # 5 entries

# Plot some of these to see if anything ~~fishy~~ is going on
plotOutliers(gpsClean,18105,18140) # looks fine
plotOutliers(gpsClean,66200,66500) # kind of weird but I think it's normal, she eventually goes back to her usual HR and who knows what goes on during calving 
plotOutliers(gpsClean,65200,67000)
plotOutliers(gpsClean,66550,66650) # looks ok

plotOutliers(gpsClean,90500,90650) # looks weird. two consecutive fixes had distances >9km: 90599 and 90600
temp <- plotOutliers(gpsClean,90570,90610,output=TRUE) 
# I would lean towards deleting 90600 and interpolating
which(row.names(temp)==90600)
temp <- temp[-31,]
plotOutliers(temp,1,40) # looks good now. 

rm(temp)

#### Examine speed outliers----
# Units are in m/s

gpsClean$speedKmh <- (unlist(lapply(move::speed(gpsMove),c, NA )))*3.6
summary(gpsClean$speedKmh) # Highest speeds are related to the very high distances we examined in the step before.    

#### Using the ctmm::outlie function----
# Generate ctmm::outlie plots for each individual
# High-speed segments are in blue, while distant locations are in red
# The plots identify other movement outliers, but I can't really figure out how to isolate problematic data points.

ctmmData <- ctmm:as.telemetry(gpsMove)
ids <- names(ctmmData)

# Grab some coffee in the break room while this runs
for (i in 1:length(ids)){
  ctmm::outlie(ctmmData[[i]],plot=TRUE,main=ids[i])
  plotName <- paste("outliers",ids[i],sep="")
  filePath <- paste("pipeline/03b_cleanLocations/temp/",plotName,sep="")
  finalName <- paste(filePath,"png",sep=".")
  dev.copy(png,finalName)
  dev.off()
  rm(plotName,filePath,finalName)
}

rm(i,ids,ctmmData)
dev.off()

# Checking out some wonky-looking movements based on the ctmm plots

# M30102
subsetOutlier <- subset(gpsClean,deployment_id=="M30102")
plotOutliers(subsetOutlier,1,nrow(subsetOutlier)) # can't identify anything

# M30103
subsetOutlier <- subset(gpsClean,deployment_id=="M30103")
plotOutliers(subsetOutlier,1,nrow(subsetOutlier))
subsetOutlier %>% filter(longX> (-158.43) & longX < (-158.38) & latY < (59.19) & latY > (59.16))
plotOutliers(subsetOutlier,4800,5000) # need to fix Row ID 4894
plotOutliers(subsetOutlier,5460,5500) # fine
plotOutliers(subsetOutlier,5770,5790) # need to fix Row ID 5778
subsetOutlier <- subsetOutlier %>% filter(RowID!=5778 & RowID!=4894)
plotOutliers(subsetOutlier,1,nrow(subsetOutlier)) # fixes the issues

# M30929
subsetOutlier <- subset(gpsClean,deployment_id=="M30929")
plotOutliers(subsetOutlier,1,nrow(subsetOutlier)) # based on ctmm plot, there seem to be a couple of outliers but on this plot I can only easily identify one
subsetOutlier %>% 
  filter(longX> (-159.03) & longX < (-159.0) & latY < (59.2) & latY > (59.15)) # rowID 2351
plotOutliers(subsetOutlier,2300,2400)
subsetOutlier <- subsetOutlier %>% filter(RowID!=2351)
plotOutliers(subsetOutlier,1,nrow(subsetOutlier)) # fixes the issue

# M30930
subsetOutlier <- subset(gpsClean,deployment_id=="M30930")
plotOutliers(subsetOutlier,1,nrow(subsetOutlier))
subsetOutlier %>% 
  filter(longX> (-158.37) & longX < (-158.3) & latY < (59.2) & latY > (59.18)) # row ID 3616
plotOutliers(subsetOutlier,3500,3640)
subsetOutlier <- subsetOutlier %>% filter(RowID!=3616)
plotOutliers(subsetOutlier,1,nrow(subsetOutlier)) # fixes the issue

# M30935
subsetOutlier <- subset(gpsClean,deployment_id=="M30935")
plotOutliers(subsetOutlier,1,nrow(subsetOutlier))
subsetOutlier %>% 
  filter(longX> (-157.94) & longX < (-157.92) & latY < (58.95) & latY > (58.93)) # row ID 1856
plotOutliers(subsetOutlier,1800,1880)
subsetOutlier <- subsetOutlier %>% filter(RowID!=1856)
plotOutliers(subsetOutlier,1,nrow(subsetOutlier))

# other plots look OK

rm(subsetOutlier,plotOutliers)

#### Commit changes----
# Restart from move object since we will have to recalculate speed and distances

# In addition to these location outliers, remove records with DOP > 5
# See Frair et al. 2010; https://www.ncbi.nlm.nih.gov/pmc/articles/PMC2894963/
nrow(subset(gpsClean,DOP>5)) # 
# Only gets rid of 44 records 

gpsClean <- gpsClean %>% 
  filter(DOP <= 5 & !(deployment_id == "M30937" & RowID == 5789 | 
             deployment_id=="M30103" & RowID == 5778 |
             deployment_id=="M30103" & RowID == 4894 | 
             deployment_id == "M30929" & RowID == 2351 |
             deployment_id=="M30930" & RowID == 3616 |
             deployment_id=="M30935" & RowID == 1856))
# Deleted 50 rows

#### Save files----
save(gpsClean,file="pipeline/03b_cleanLocations/cleanLocations.Rdata")

# Clean workspace
rm(list=ls())