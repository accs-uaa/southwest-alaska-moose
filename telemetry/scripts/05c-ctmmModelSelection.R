# Objective: Run movement models for the variograms that seem promising (liberally defined). ctmm_select considers several movement models that differ with respect to their autocorrelation structure. These are described in Calabrese et al. (2016) DOI: 10.1111/2041-210X.12559

# Author: A. Droghini (adroghini@alaska.edu)
#         Alaska Center for Conservation Science

#### Load packages and data----
rm(list=ls())
source("scripts/init.R")
source("scripts/function-plotVariograms.R") # calls varioPlot function
load("pipeline/05b_applyCalibration/calibratedData.Rdata")

migDates <- read_excel(path= "output/migrationDates.xlsx",sheet = "newAttempts")

#### Subset decent HRs only----
decentRanges <- migDates %>% 
        dplyr::mutate(new_id = paste(migDates$deployment_id,migDates$year,migDates$season,sep="_")) %>% 
        subset(run == "y")

decentRanges <- decentRanges$new_id

calibratedData <- calibratedData[decentRanges]

# Export
fileName <- paste("pipeline/05c_ctmmModelSelection/temp/data/modelData_",Sys.Date(),".Rdata",sep="")
save(calibratedData,file=fileName)

rm(decentRanges, varioPlot,fileName,migDates)

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

# 50 seasonal home ranges took 28 hours to run
# 13 seasonal home ranges took 5 hours to run
Sys.time() # 2020-05-30 18:01:57.313426 AKDT
fitModels <- lapply(1:length(calibratedData), 
                    function(i) ctmm.select(data=calibratedData[[i]],
                                            CTMM=initParam[[i]],
                                            verbose=TRUE,trace=TRUE, cores=0,
                                            method = "pHREML") )
Sys.time() # 2020-05-31 04:56:48.10169 AKDT

# Add seasonal animal ID names to fitModels list
names(fitModels) <- names(calibratedData)

# The warning "pREML failure: indefinite ML Hessian" is normal if some autocorrelation parameters cannot be well resolved.

# Export results
save(fitModels,file=paste("pipeline/05c_ctmmModelSelection/temp/data/fitModels_",Sys.Date()-1,".Rdata",sep=""))
save(initParam,file=paste("pipeline/05c_ctmmModelSelection/temp/data/initParam_",Sys.Date()-1,".Rdata",sep=""))