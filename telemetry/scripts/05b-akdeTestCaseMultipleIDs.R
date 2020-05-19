# Load packages and data----
source("scripts/init.R")
library(readxl)
source("scripts/function-plotVariograms.R") # calls varioPlot function

load("pipeline/03b_cleanLocations/cleanLocations.Rdata")
load("pipeline/02b_calibrateData/uereModel.Rdata")

migDates <- read_excel(path= "data/migrationDates.xlsx")


### Super janky subset until I make a function----
idsToTest <- unique(migDates$deployment_id)

gpsToTest <- gpsClean %>% 
  filter(deployment_id %in% idsToTest)

gpsToTest <- gpsToTest %>% 
  mutate(homeRangeID = case_when(
    deployment_id == migDates$deployment_id[1] & as_date(datetime) >= migDates$start[1] & as_date(datetime) <= migDates$end[1] ~ paste(migDates$deployment_id[1],migDates$year[1],migDates$season[1],sep="_"),
    deployment_id == migDates$deployment_id[2] & as_date(datetime) >= migDates$start[2] & as_date(datetime) <= migDates$end[2] ~ paste(migDates$deployment_id[2],migDates$year[2],migDates$season[2],sep="_"),
    deployment_id == migDates$deployment_id[3] & as_date(datetime) >= migDates$start[3] & as_date(datetime) <= migDates$end[3] ~ paste(migDates$deployment_id[3],migDates$year[3],migDates$season[3],sep="_"),
    deployment_id == migDates$deployment_id[4] & as_date(datetime) >= migDates$start[4] & as_date(datetime) <= migDates$end[4] ~ paste(migDates$deployment_id[4],migDates$year[4],migDates$season[4],sep="_"),
    deployment_id == migDates$deployment_id[5] & as_date(datetime) >= migDates$start[5] & as_date(datetime) <= migDates$end[5] ~ paste(migDates$deployment_id[5],migDates$year[5],migDates$season[5],sep="_"),
    deployment_id == migDates$deployment_id[6] & as_date(datetime) >= migDates$start[6] & as_date(datetime) <= migDates$end[6] ~ paste(migDates$deployment_id[6],migDates$year[6],migDates$season[6],sep="_"),
    deployment_id == migDates$deployment_id[7] & as_date(datetime) >= migDates$start[7] & as_date(datetime) <= migDates$end[7] ~ paste(migDates$deployment_id[7],migDates$year[7],migDates$season[7],sep="_"),
    deployment_id == migDates$deployment_id[8] & as_date(datetime) >= migDates$start[8] & as_date(datetime) <= migDates$end[8] ~ paste(migDates$deployment_id[8],migDates$year[8],migDates$season[8],sep="_"),
    deployment_id == migDates$deployment_id[9] & as_date(datetime) >= migDates$start[9] & as_date(datetime) <= migDates$end[9] ~ paste(migDates$deployment_id[9],migDates$year[9],migDates$season[9],sep="_"),
    deployment_id == migDates$deployment_id[10] & as_date(datetime) >= migDates$start[10] & as_date(datetime) <= migDates$end[10] ~ paste(migDates$deployment_id[10],migDates$year[10],migDates$season[10],sep="_")
    )) %>% 
  filter(!is.na(homeRangeID))

unique(gpsToTest$homeRangeID)

# Convert to telemetry object----

gpsData <- gpsToTest %>% 
  dplyr::select(RowID,latY,longX,Easting, Northing,
                DOP,FixType,datetime,homeRangeID)

gpsData <- move(x=gpsData$Easting,y=gpsData$Northing,
                time=gpsData$datetime,
                data=gpsData,proj=CRS("+init=epsg:32604"),
                animal=gpsData$homeRangeID, sensor="gps")

gpsData <- ctmm::as.telemetry(gpsData,timezone="UTC",projection=CRS("+init=epsg:32604"))

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
