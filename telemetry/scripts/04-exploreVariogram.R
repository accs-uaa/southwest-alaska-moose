# Objective: Generate aKDEs for each individual

# Author: Amanda Droghini (adroghini@alaska.edu)
#         Alaska Center for Conservation Science

# Working through vignette: https://ctmm-initiative.github.io/ctmm/articles/variogram.html

# Load packages and data----
aibrary(ctmm)
load("output/gps_cleanSpaceTime.Rdata")

source("scripts/function-plotVariograms.R") # calls varioPlot function

# Convert to as.telemetry object
# Stick with default projection for now, but may want to switch to a user-defined proj. with origin around Nushagak River: https://gis.stackexchange.com/questions/118125/proj4js-is-this-correct-implementation-of-azimuthal-equidistant-relative-to-an
gpsData <- as.telemetry(gpsMove)

# Plot tracks
# Distances are within the range shown in the vignette, where the individuals are considered as 'relatively range resident'
plot(gpsData,col=rainbow(length(gpsData)))

# Plot variograms
varioPlot(gpsData)

# Exclude individuals M30927a, M30928a, M30928b, M35172
# Too few data points to reach asymptote
# Many of the zoomed in plots are non-linear, indicating continuity in the animal's velocity (from variogram vignette)
# We can fit a linear model like OU to see by how much we would need to coarsen our timescale for use in common analytical methods like SSF
# internal numbers in ctmm use SI units of meters and seconds
# Random gaps in the data are acceptable and fully accounted for in both variogram estimation and model fitting

# 