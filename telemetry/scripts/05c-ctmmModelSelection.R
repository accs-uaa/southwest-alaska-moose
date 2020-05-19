# Objectives: 1. Plot variograms for seasonal home ranges. Doing so allows us to check whether our cut-off dates need to be modified e.g. capturing part of migration.
#             2. Reject home ranges with terrible variograms.
#             3. Fit ctmm models to the remaining good ones.

# Author: A. Droghini (adroghini@alaska.edu)
#         Alaska Center for Conservation Science

#### Load packages and data----
rm(list=ls())
source("scripts/init.R")
source("scripts/function-plotVariograms.R") # calls varioPlot function
load("pipeline/05b_applyCalibration/calibratedData.Rdata")

#### Plot variograms----
varioPlot(calibratedData,filePath="pipeline/05c_ctmmModelSelection/temp/",
          zoom = FALSE)

#### Subset decent HRs only----
names(calibratedData)
decentRanges <- names(calibratedData)[c(1:3,6:9)]
calibratedData <- calibratedData[decentRanges]

rm(decentRanges, varioPlot)

#### Run models on decent HRs----

# Generate initial "guess" parameters
# See akdeTestCase for notes
initParam <- lapply(calibratedData[1:length(calibratedData)], 
                    function(b) ctmm.guess(b,CTMM=ctmm(error=TRUE),
                                           interactive=FALSE) )

# Takes a while to run
fitMoveModels <- lapply(1:length(gpsData), function(i) ctmm.select(gpsData[[i]],initParam[[i]],verbose=TRUE) )

# Add names to list items
names(fitMoveModels) <- names(gpsData[1:length(gpsData)])


# View top model for each individual
# Why is dof.area so low for individuals with the same number of locations?
lapply(fitMoveModels,function(x) summary(x)) #

# Plot variogram with model fit----
for (i in 1:length(gpsData)){
  id <- names(gpsData)[[i]]
  vario <- variogram(gpsData[[i]], dt = 2 %#% "hour")
  fitOneId<-fitMoveModels[[i]]
  plot(vario,CTMM=fitOneId,col.CTMM=c("red","purple","blue","green"),fraction=0.65,level=0.5,main=id)
}

xlim <- c(0,12 %#% "hour")
plot(vario,CTMM=fitOneId,col.CTMM=c("red","purple","blue","green"),xlim=xlim,level=0.5)

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