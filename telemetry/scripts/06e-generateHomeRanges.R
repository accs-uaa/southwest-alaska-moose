# Objectives: For selected seasonal IDs, fit top model and estimate home range using aKDE.

# Author: A. Droghini (adroghini@alaska.edu)
#         Alaska Center for Conservation Science

#### Load packages and data----
rm(list=ls())
source("scripts/init.R")
load("pipeline/06c_selectFinalModels/finalModels.Rdata")
load("pipeline/06b_applyCalibration/calibratedData.Rdata")

# Specify extent
ee <- extent(calibratedData)

# Split data into two chunks ----
# Need to do this to avoid memory limit error
# Work laptop has 16 GB of RAM, which is not enough even after increasing memory limit and trying to run on "fresh" (rebooted) computer

# Order IDs alphabetically so that all home ranges for a given ID are contained in a single data chunk
ids <- names(finalMods)
ids <- ids[order(ids)]

calibratedData <- calibratedData[ids]
finalMods <- finalMods[ids]

# names(finalMods) == ids # Check
# names(calibratedData) == id

# Create two datasets
data1 <- calibratedData[1:14]
mods1 <- finalMods[1:14]
data2 <- calibratedData[15:34]
mods2 <- finalMods[15:34]

rm(calibratedData,finalMods,ids)

#### Generate aKDE ----

# Use weights = TRUE to account for gaps in data

### Run first set
gc() # Clear up memory
Sys.time()
homeRanges02 <- akde(data=data2, CTMM=mods2,weights=TRUE,grid=ee)
Sys.time()

# Export homeRanges02
save(homeRanges02,file="pipeline/06e_generateHomeRanges/homeRanges02.Rdata")

# Clear up memory
rm(data2,mods2,homeRanges02)
gc()

homeRanges01 <- akde(data=data1, CTMM=mods1,
                    weights=TRUE,grid=ee)

save(homeRanges01,file="pipeline/06e_generateHomeRanges/homeRanges01.Rdata")

rm(data1,ee,mods1)

# Merge home ranges back into one master file
load("pipeline/06e_generateHomeRanges/homeRanges02.Rdata")
homeRanges <- list(homeRanges01,homeRanges02)
homeRanges <- flatten(homeRanges)

save(homeRanges,file="pipeline/06e_generateHomeRanges/homeRanges.Rdata")

rm(list=ls())