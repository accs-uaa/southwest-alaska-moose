# Objectives: Generate aKDE home ranges for selected seasonal IDs.

# Author: A. Droghini (adroghini@alaska.edu)
#         Alaska Center for Conservation Science

#### Load packages and data----
rm(list=ls())
source("scripts/init.R")
load("pipeline/06c_selectFinalModels/finalModels.Rdata")
load("pipeline/06b_applyCalibration/calibratedData.Rdata")

#### Specify extent ----
# Get extent for each telemetry set
ee <- lapply(calibratedData,function(x) extent(x))
ee <- data.frame(matrix(unlist(ee), 
                  nrow=length(ee), 
                  byrow=T))
colnames(ee) <- c("min.x","max.x","min.y","max.y")

# Find absolute minimum and maximum
# Pad it to prevent home ranges from getting cut off
eeMatrix <- c(min(ee$min.x)-100000,max(ee$max.x)+10000,min(ee$min.y)-10000,max(ee$min.y)+100000)
eeMatrix<-matrix(data=eeMatrix,nrow=2,ncol=2,dimnames=list(c("min","max")))
colnames(eeMatrix)<-c("x","y")
ee <- as.data.frame(eeMatrix)

rm(eeMatrix)

# Split data into three chunks ----
# Need to do this to avoid memory limit error
# Work laptop has 16 GB of RAM, which is not enough even after increasing memory limit and trying to run on "fresh" (rebooted) computer

# Order calibratedData and finalMods alphabetically by IDs
ids <- names(finalMods)
ids <- ids[order(ids)]

calibratedData <- calibratedData[ids]
finalMods <- finalMods[ids]

# Create separate datasets

# !!! To make life easier when calculating home range overlap (in subsequent script), make sure data are split in such a way that all home ranges for a given individual are contained in the same data chunk !!!

names(ids)


data1 <- calibratedData[1:11]
mods1 <- finalMods[1:11]
data2 <- calibratedData[12:22]
mods2 <- finalMods[12:22]
data3 <- calibratedData[23:34]
mods3 <- finalMods[23:34]

rm(calibratedData,finalMods,ids)

#### Generate aKDE ----

# Use weights = TRUE to account for gaps in data

### Run first set
gc() # Clear up memory
memory.limit(10000000000000) # Increase memory limit

Sys.time()
homeRanges01 <- akde(data=data1, CTMM=mods1,weights=TRUE,grid=ee)
Sys.time()

# Export homeRanges01
save(homeRanges01,file="pipeline/06e_generateHomeRanges/homeRanges01.Rdata")

# Clear up memory
rm(data1,mods1,homeRanges01)
gc()

#### Run second set----
Sys.time()
homeRanges02 <- akde(data=data2, CTMM=mods2,
                    weights=TRUE,grid=ee)
Sys.time()
save(homeRanges02,file="pipeline/06e_generateHomeRanges/homeRanges02.Rdata")

# Clear up memory
rm(data2,mods2,homeRanges02)
gc()

#### Run third set----
Sys.time()
homeRanges03 <- akde(data=data3, CTMM=mods3,
                     weights=TRUE,grid=ee)
Sys.time()

save(homeRanges03,file="pipeline/06e_generateHomeRanges/homeRanges03.Rdata")

save(ee,file="pipeline/06e_generateHomeRanges/gridExtent.Rdata")

rm(list=ls())