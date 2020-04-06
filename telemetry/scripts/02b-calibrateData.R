# Objective: See if we can use existing data to calibrate telemetry error.

# Author: A. Droghini (adroghini@alaska.edu)
#         Alaska Center for Conservation Science

# Vignette: https://ctmm-initiative.github.io/ctmm/articles/error.html

#### Load data and packages----
rm(list = ls())
source("scripts/init.R")
load("pipeline/01_importData/gpsRaw.Rdata") # GPS telemetry data

#### Explore potential calibration data----
# Several IDs were recording when they were at the Vectronic factory in Berlin
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
# Need to read up on DOP value used in collars. Combo of horizontal and vertical?
calibTestData <- as.telemetry(test,timezone="UTC",projection=CRS("+init=epsg:32633"))

names(calibTestData)

plot(calibTestData[3:4],col=rainbow(2)) # some IDs look way off and I wonder if the collars were moved. For now, just stick to IDs whose plots don't have any huge outliers. Not trying to fudge the numbers here but results make a lot more sense when certain IDs are omitted

# Limit to only a few IDs for now
test <- test %>% 
  filter(tag_id == "30104" | tag_id == "30105" | tag_id == "30928" |
           tag_id == "30931" | tag_id == "30933" | tag_id == "30938" |
         tag_id == "35173")

calibTestData <- as.telemetry(test,timezone="UTC",projection=CRS("+init=epsg:32633"))

#### Fit data to calibration model----
# Estimated errors are actually a lot higher than I would expect
# Problem:only have validated 3D class
# Moose dataset has three fix types: val. GPS-3D, GPS-3D, GPS-2D
calibModel <- uere.fit(calibTestData)
summary(calibModel)

#### Model selection----
# Unfortunately we have no variation in "class" but we can see if calibrated data performs better than data with no DOP information
modNoDOP  <- lapply(calibTestData,function(t){ t$HDOP  <- NULL; t })

modelFit.noDOP  <- uere.fit(modNoDOP)

summary(list(DOP=calibModel,noDOP=modelFit.noDOP)) # Model that takes DOP into account performs much better

rm(gpsData)


#### Add telemetry errors to moose data----
# Probably want to do this before identifying and removing outliers

load("pipeline/02_formatData/formattedData.Rdata")

gpsData <- gpsData %>% 
  rename(location.long = longX, location.lat = latY, class = FixType)

calibData <- as.telemetry(gpsData,timezone="UTC",projection = CRS("+init=epsg:32604"))

uere(calibData) <- calibModel
names(calibData[[1]])
plot(calibData[[3]],error=2, xlim=c(558000,560000))
