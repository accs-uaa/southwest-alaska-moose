# Objectives: For selected seasonal IDs, fit top model and estimate home range using aKDE.

# Author: A. Droghini (adroghini@alaska.edu)
#         Alaska Center for Conservation Science

#### Load packages and data----
rm(list=ls())
source("scripts/init.R")
load("pipeline/06c_selectFinalModels/finalModels.Rdata")
load("pipeline/06b_applyCalibration/calibratedData.Rdata")

#### Generate aKDE ----

# Use weights = TRUE to account for gaps in data
Sys.time()
homeRanges <- akde(data=calibratedData, CTMM=finalMods,
                                     weights=TRUE)
Sys.time()

#### Explore results ----
lapply(1:length(homeRanges), 
       function(i) 
        summary(homeRanges[[i]]))

# Plot
lapply(1:length(homeRanges), 
       function(i) 
         plot(subsetData[[i]],UD=homeRanges[[i]],main=names(homeRanges)[[i]]))

#### Determining seasonal overlap
overlap(homeRanges[1:2])
overlap(homeRanges[4:5])

# Export as shapefiles
filePath <- paste(getwd(),"pipeline/05d_generateHomeRanges",sep="/")

lapply(1:length(homeRanges), function (i) writeShapefile(homeRanges[[i]],
               folder=filePath, file=names(homeRanges[i]),
               level.UD=0.95))

rm(list=ls())