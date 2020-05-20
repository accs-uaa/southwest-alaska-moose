# Objectives: For selected seasonal IDs, fit top model and estimate home range using aKDE.

# Author: A. Droghini (adroghini@alaska.edu)
#         Alaska Center for Conservation Science

#### Load packages and data----
rm(list=ls())
source("scripts/init.R")
load("pipeline/05c_ctmmModelSelection/decentModels.Rdata")
load("pipeline/05b_applyCalibration/calibratedData.Rdata")

# Subset calibratedData to only include select seasonal IDs
idNames <- names(decentModels)
subsetData <- calibratedData[idNames]
rm(calibratedData,idNames)

#### Generate aKDE ----

# Pick the top-ranked model for every seasonal ID
# Wow, so many nested lists :-/
bestModels <- lapply(1:length(decentModels), 
                     function(i) decentModels[[i]][1][[1]])

# Use weights = TRUE to account for gaps in data
Sys.time()
homeRanges <- akde(data=subsetData, CTMM=bestModels,
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

# Export to use for later
save.image("pipeline/05b_akdeTestCase/multipleIds.Rdata")

rm(list=ls())