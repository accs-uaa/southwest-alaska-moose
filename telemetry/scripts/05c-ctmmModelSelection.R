# Objectives: 

# 1) Generate variograms for seasonal home ranges to assess stationarity. If an asymptote is not reached, go back to the drawing board-- Do you need to change start/end date? This is a highly iterative, manual process.

# 2) Run movement models for the variograms that seem promising (liberally defined). ctmm_select considers several movement models that differ with respect to their autocorrelation structure. These are described in Calabrese et al. (2016) DOI: 10.1111/2041-210X.12559

# Author: A. Droghini (adroghini@alaska.edu)
#         Alaska Center for Conservation Science

#### Load packages and data----
rm(list=ls())
source("scripts/init.R")
source("scripts/function-plotVariograms.R") # calls varioPlot function
load("pipeline/05b_applyCalibration/calibratedData.Rdata")
migDates <- read_excel(path= "output/migrationDates.xlsx",sheet = "variogramAssess")

#### Plot variograms----

#### Notes
# testOne variograms run on: migDates <- read_excel(path= "output/migrationDates.xlsx",sheet = "migrationDates")
# testTwo + onwards run on: migDates <- read_excel(path= "output/migrationDates.xlsx",sheet = "variogramAssess")

varioPlot(calibratedData,
          filePath="pipeline/05c_ctmmModelSelection/temp/testFive/testFive",
          zoom = FALSE)

#### Subset decent HRs only----
names(calibratedData)

decentRanges <- migDates %>% 
        dplyr::mutate(new_id = paste(migDates$deployment_id,migDates$year,migDates$season,sep="_")) %>% 
        subset(run == "y")
decentRanges <- decentRanges$new_id

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

# Latest run of 50 seasonal home ranges took 28 hours to run
Sys.time() # "2020-05-22 17:24:41.64709 AKDT"
fitModels <- lapply(1:length(calibratedData), 
                    function(i) ctmm.select(data=calibratedData[[i]],
                                            CTMM=initParam[[i]],
                                            verbose=TRUE,trace=TRUE, cores=0,
                                            method = "pHREML") )
Sys.time() #"2020-05-23 23:46:08.31888 AKDT"

# The warning "pREML failure: indefinite ML Hessian" is normal if some autocorrelation parameters cannot be well resolved.

# Add seasonal animal ID names to fitModels list
names(fitModels) <- names(calibratedData)

# Export results
save(fitModels,file="pipeline/05c_ctmmModelSelection/fitModels.Rdata")
save(initParam,file="pipeline/05c_ctmmModelSelection/initParam.Rdata")