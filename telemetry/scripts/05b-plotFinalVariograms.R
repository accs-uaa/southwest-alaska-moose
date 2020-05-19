# Objectives: 1. Plot variograms for seasonal home ranges. Doing so allows us to check whether our cut-off dates need to be modified e.g. capturing part of migration. 
#             2. Calibrate data. 

# Author: A. Droghini (adroghini@alaska.edu)
#         Alaska Center for Conservation Science

# Load packages and data----
rm(list=ls())
source("scripts/init.R")
load("pipeline/05a_splitByMigrationDates/seasonalData.Rdata")

# Convert to telemetry object----
gpsData <- gpsToTest %>% 
  dplyr::select(RowID,latY,longX,Easting, Northing,
                DOP,FixType,datetime,homeRangeID)

gpsData <- move(x=gpsData$Easting,y=gpsData$Northing,
                time=gpsData$datetime,
                data=gpsData,proj=CRS("+init=epsg:32604"),
                animal=gpsData$homeRangeID, sensor="gps")

gpsData <- ctmm::as.telemetry(gpsData,timezone="UTC",projection=CRS("+init=epsg:32604"))



source("scripts/function-plotVariograms.R") # calls varioPlot function
load("pipeline/02b_calibrateData/uereModel.Rdata")
# Calibrate data
# For some reason this breaks it???
# uere(gpsData) <- calibModel

# gpsData[[1]]@UERE

# Plot tracks
plot(gpsData,col=rainbow(length(gpsData)))

# Plot variograms----
varioPlot(gpsData)

rm(gpsToTest,idsToTest,varioPlot,gpsClean,migDates)

# Run them models----
# See akdeTestCase for notes
initParam <- lapply(gpsData[1:length(gpsData)], function(b) ctmm.guess(b,interactive=FALSE) )

# Takes a while to run
fitMoveModels <- lapply(1:length(gpsData), function(i) ctmm.select(gpsData[[i]],initParam[[i]],verbose=TRUE) )

names(fitMoveModels) <- names(gpsData[1:length(gpsData)])

lapply(fitMoveModels,function(x) summary(x)) #

# Plot
for (i in 1:length(gpsData)){
  id <- names(gpsData)[[i]]
  vario <- variogram(gpsData[[i]], dt = 2 %#% "hour")
  fitOneId<-fitMoveModels[[i]]
  plot(vario,CTMM=fitOneId,col.CTMM=c("red","purple","blue","green"),fraction=0.65,level=0.5,main=id)
}

# Generate akde for the 3 HRs that look most promising
names(fitMoveModels) # 1, 3, 6

# fit best model
m30102y1annual <- fitMoveModels[[1]]$`OUF anisotropic`
m30102y2annual <- fitMoveModels[[3]]$`OUF anisotropic`
m30103y2annual <- fitMoveModels[[6]]$`OUF anisotropic`

# home range
hr.m30102y1annual <- akde(gpsData[[1]],CTMM=m30102y1annual,weights=TRUE)
hr.m30102y2annual <- akde(gpsData[[3]],CTMM=m30102y2annual,weights=TRUE)
hr.m30103y2annual <- akde(gpsData[[6]],CTMM=m30103y2annual,weights=TRUE)


# summary
summary(hr.m30102y1annual)
summary(hr.m30102y2annual)
summary(hr.m30103y2annual)

plot(gpsData[[1]],UD=hr.m30102y1annual)
plot(gpsData[[3]],UD=hr.m30102y2annual)
plot(gpsData[[6]],UD=hr.m30103y2annual)

rm(i,id)

# Export to use for later
save.image("pipeline/05b_akdeTestCase/multipleIds.Rdata")

rm(list=ls())