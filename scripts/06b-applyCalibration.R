# Objectives: Convert to telemetry object and calibrate data. This will allow us to fit a movement model with telemetry error taken into account.

# Author: A. Droghini (adroghini@alaska.edu)
#         Alaska Center for Conservation Science

# Load packages and data----
rm(list=ls())
source("scripts/init.R")
load("pipeline/06a_splitByMigrationDates/seasonalData.Rdata")
load("pipeline/02b_calibrateData/uereModel.Rdata") # calibration data

# Convert to telemetry object----
# Use newid instead of deployment_id to map separate home ranges for the same individual
# Should I be using UTM coordinates (Easting and Northing) instead??
calibratedData <- seasonalData %>% 
  dplyr::select(latY,longX,
                DOP,FixType,datetime,newid) %>% 
  rename(longitude = longX, latitude = latY, 
         class = FixType,animal_id = newid)

calibratedData <- ctmm::as.telemetry(calibratedData,timezone="UTC",projection=CRS("+init=epsg:32604"))

# Plot tracks
plot(calibratedData,col=rainbow(length(calibratedData)))

# Calibrate data ----
uere(calibratedData) <- calibModel
names(calibratedData[[1]]) # VAR.xy column appears

# Export ----
save(calibratedData,file="pipeline/06b_applyCalibration/calibratedData.Rdata")

rm(list=ls())