# Objectives: Generate potential movement models to seasonal IDs. Assess model fit using variograms. Continue with only seasonal IDs that have good model fit. For the rest, go back to the drawing board-- Do you need to change start/end date?

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

# Generate initial "guess" parameters using ctmm.guess (=variogram.fit) 
# Guess parameters can then be passed onto to ctmm.fit
initParam <- lapply(calibratedData[1:length(calibratedData)], 
                    function(b) ctmm.guess(b,CTMM=ctmm(error=TRUE),
                                           interactive=FALSE) )

# Fit movement models to the data
# Using initial guess parameters and ctmm.select
# ctmm.select will rank models and the top model can be chosen to generate an aKDE
# Do not use ctmm.fit - ctmm.fit() returns a model of the same class as the guess argument i.e. an OUF model with anisotropic covariance.
# Takes a while to run
Sys.time() #"2020-05-19 10:51:24.884263 AKDT"
fitModels <- lapply(1:length(calibratedData), 
                    function(i) ctmm.select(data=calibratedData[[i]],
                                            CTMM=initParam[[i]],
                                            verbose=TRUE,trace=TRUE, cores=0,
                                            method = "pHREML") )
Sys.time() #"2020-05-19 14:51:13.756195 AKDT"

# The warning "pREML failure: indefinite ML Hessian" is normal if some autocorrelation parameters cannot be well resolved.

# Add seasonal animal ID names to fitModels list
names(fitModels) <- names(calibratedData)

# Export results
save(fitModels,file="pipeline/05c_ctmmModelSelection/fitModels.Rdata")

#### Assess model performance ----

# View model selection table for each ID
# OUF always top model
# the two instances where isotropic is chosen over anisotropic (M30104_y1_summer and M30104_y2_summer) have AICs that are within <2.5 of each other
lapply(fitModels,function(x) summary(x))

# Can you reject certain models based on DOF alone???

#### Plot variogram with model fit----
filePath <- "pipeline/05c_ctmmModelSelection/temp/"

lapply(1:length(calibratedData), 
       function (a) {
       plotName <- paste(names(fitModels[a]),"modelFit",sep="_")
       plotPath <- paste(filePath,plotName,sep="")
       finalName <- paste(plotPath,"png",sep=".")
       
         plot(variogram(calibratedData[[a]], dt = 2 %#% "hour"),
              CTMM=fitModels[[a]][1],
              col.CTMM=c("red","purple","blue","green"),
              fraction=0.65,
              level=0.5,
              main=names(fitModels[a]))
         
         dev.copy(png,finalName)
         dev.off()
         
         }
       )

# Can also look at zoomed in plot
# Not coded
# xlim <- c(0,12 %#% "hour")
# plot(vario,CTMM=fitOneId,col.CTMM=c("red","purple","blue","green"),xlim=xlim,level=0.5)

rm(filePath)

#### Select seasonal IDs that have decent model fits----
# Only pick the top-ranking model for each seasonal ID
names(fitModels)
decentModels <- names(fitModels)[c(1,3,4,5,7)]
decentModels <- fitModels[decentModels]
decentModels <- lapply(1:length(decentModels), 
       function(i) decentModels[[i]][1][[1]]) # Wow, so many nested lists :-/

# Export
save(decentModels,file="pipeline/05c_ctmmModelSelection/decentModels.Rdata")

rm(list=ls())