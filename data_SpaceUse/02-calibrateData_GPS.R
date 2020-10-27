# Objective: Calibrate telemetry error.

# Author: A. Droghini (adroghini@alaska.edu)
#         Alaska Center for Conservation Science

# Vignette: https://ctmm-initiative.github.io/ctmm/articles/error.html

#### Load data and packages----
rm(list = ls())
source("scripts/init.R")
load("pipeline/01_importData/gpsRaw.Rdata") # GPS telemetry data

#### Explore calibration data----
# Collars were recording when they were at the Vectronic factory in Berlin (52.5°N, 13.4°E)
# Filter these out to see if we can use them in a calibration model

test <- gpsData %>% 
  dplyr::mutate(datetime = as.POSIXct(paste(gpsData$UTC_Date, gpsData$UTC_Time), format="%m/%d/%Y %I:%M:%S %p",tz="UTC")) %>% 
  dplyr::rename(location.long = "Longitude....", location.lat = "Latitude....", tag_id = CollarID, 
                mortalityStatus = "Mort..Status",
                class=FixType) %>% 
  filter(!(is.na(location.long) | is.na(location.lat) | is.na(UTC_Date))) %>% 
  filter(location.long > 0) %>% 
  dplyr::select(tag_id,location.long,location.lat,DOP,class,datetime)

plot(test$location.lat,test$location.long)

# Convert to as.telemetry object
# Use UTM projection for Germany: https://spatialreference.org/ref/epsg/wgs-84-utm-zone-33n/
# Need to read up on DOP value used in collars. Combo of horizontal and vertical? Emailed Vectronic on 6 Apr 2020
calibTestData <- as.telemetry(test,timezone="UTC",projection=CRS("+init=epsg:32633"))

names(calibTestData)

lapply(calibTestData, function(x) plot(x,col=rainbow(2))) # some IDs look way off and I wonder if the collars were moved while they were recording. For now, just stick to IDs whose plots don't have any huge outliers. Not trying to fudge the numbers here but results make a lot more sense when certain IDs are omitted

#### Fit data to calibration model----

# Use only IDs with good-looking plots
test <- test %>% 
  filter(tag_id == "30104" | tag_id == "30105" | tag_id == "30928" |
           tag_id == "30931" | tag_id == "30933" | tag_id == "30938" |
         tag_id == "35173")

unique(test$class)
# Problem: only have validated 3D class
# Whereas our moose dataset has three fix types: val. GPS-3D, GPS-3D, GPS-2D
# So we can't apply class-specific (if present) location calibration

calibTestData <- as.telemetry(test,timezone="UTC",projection=CRS("+init=epsg:32633"))
calibModel <- uere.fit(calibTestData)
summary(calibModel)
# Estimated errors are slightly higher than I would expect

#### Model selection----
# Unfortunately we have no variation in "class" but we can see if calibrated data performs better than data with no DOP information
modNoDOP  <- lapply(calibTestData,function(t){ t$HDOP  <- NULL; t })

modelFit.noDOP  <- uere.fit(modNoDOP)

summary(list(DOP=calibModel,noDOP=modelFit.noDOP)) # Model that takes DOP into account performs much better

rm(gpsData)

# As a check, we could use data from M30938, RowID >= 6991 to see if estimated errors are similar. This is a mortality (so no movement) and the collars was known to have been left outside during this time. Estimated errors are similar.

#### Export UERE data----
# This can then be appended to as.telemetry objects prior to analyses

save(calibModel, file="pipeline/02b_calibrateData/uereModel.Rdata")

rm(list=ls())