# Objective: Plot and look at variograms to explore space use patterns. Preliminary step before fitting a movement model and generating an aKDE

# Working through vignette: https://ctmm-initiative.github.io/ctmm/articles/variogram.html


# Author: Amanda Droghini (adroghini@alaska.edu)
#         Alaska Center for Conservation Science

# Load packages and data----
rm(list=ls())
library(ctmm)
load("pipeline/03c_interpolateData/mooseData.Rdata")

source("scripts/function-plotVariograms.R") # calls varioPlot function

# Prepare and explore data----
# Convert to telemetry object
# Stick with default projection for now, but may want to switch to a user-defined proj. with origin around Nushagak River: https://gis.stackexchange.com/questions/118125/proj4js-is-this-correct-implementation-of-azimuthal-equidistant-relative-to-an
gpsData <- ctmm::as.telemetry(mooseData)

# Plot tracks
plot(gpsData,col=rainbow(length(gpsData)))

# Plot variograms----
varioPlot(gpsData)

# Many of the zoomed in plots are non-linear, indicating continuity in the animal's velocity (from variogram vignette)
# Most of the variograms don't fit well. Some indicate migratory or seasonal movements. I ran the variograms with uninterpolated data since the interpolation gets rid of the data stored in the DOP column, but the results were the same since location error is only taken into account during the model fitting process.

# We can fit a linear model like OU to see by how much we would need to coarsen our timescale for use in common analytical methods like SSF
# internal numbers in ctmm use SI units of meters and seconds
# Gaps in the data are acceptable and fully accounted for in both variogram estimation and model fitting. Shouldn't be an issue since we interpolated to create a regular time series

rm(varioPlot)

