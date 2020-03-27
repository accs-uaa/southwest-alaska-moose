# Objective: Generate aKDEs for each individual

# Author: Amanda Droghini (adroghini@alaska.edu)
#         Alaska Center for Conservation Science

# Working through vignette: https://ctmm-initiative.github.io/ctmm/articles/variogram.html

# Load packages and data----
rm(list=ls())
library(ctmm)
library(tidyverse)
load("pipeline/03c_interpolateData/mooseData.Rdata")

source("scripts/function-plotVariograms.R") # calls varioPlot function

# Convert to as.telemetry object
# Stick with default projection for now, but may want to switch to a user-defined proj. with origin around Nushagak River: https://gis.stackexchange.com/questions/118125/proj4js-is-this-correct-implementation-of-azimuthal-equidistant-relative-to-an
gpsData <- ctmm::as.telemetry(mooseData)

# Plot tracks
# Distances are within the range shown in the vignette, where the individuals are considered as 'relatively range resident'
plot(gpsData,col=rainbow(length(gpsData)))

# Plot variograms
varioPlot(gpsData)

# Many of the zoomed in plots are non-linear, indicating continuity in the animal's velocity (from variogram vignette)
# We can fit a linear model like OU to see by how much we would need to coarsen our timescale for use in common analytical methods like SSF
# internal numbers in ctmm use SI units of meters and seconds
# Random gaps in the data are acceptable and fully accounted for in both variogram estimation and model fitting

# Exclude individuals M30927a, M30928a, M30928b, M35172
# Too few data points to reach asymptote
idsToExclude <- c("M30927a","M30928a", "M30928b", "M35172")
gpsDataExcluded <- gpsData[-unlist(lapply(idsToExclude, function(x) grep(x, names(gpsData)) ) ) ]
names(gpsDataExcluded)

# Use ctmm.guess (=variogram.fit) to obtain initial "guess" parameters, which can then be passed onto to ctmm.fit
# Use ctmm.select to choose top-ranked model, which will be used to generate aKDEs
# Do not use ctmm.fit - ctmm.fit() returns a model of the same class as the guess argument i.e. an OUF model with anisotropic covariance.
initParam <- lapply(gpsDataExcluded[1:length(gpsDataExcluded)], function(b) ctmm.guess(b,interactive=FALSE) )

# Takes several hours
fitMoveModels <- lapply(1:length(gpsDataExcluded), function(i) ctmm.select(gpsDataExcluded[[i]],initParam[[i]],verbose=TRUE) )

names(fitMoveModels) <- names(gpsDataExcluded[1:length(gpsDataExcluded)])

# Export results
save(fitMoveModels,file="pipeline/04_exploreVariogram/fitMoveModels.RData")

# View top model for each individual
lapply(fitMvmtModel,function(x) summary(x)[1]) # 


