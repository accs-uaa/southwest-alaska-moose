# Objective: Fit several movement models (OUF, ouf, OU, IID) and select the best one for each moose. Required for generating aKDE

# Working through vignette: https://ctmm-initiative.github.io/ctmm/articles/variogram.html


# Author: Amanda Droghini (adroghini@alaska.edu)
#         Alaska Center for Conservation Science

# Load data and packages----
library(ctmm)
load("pipeline/03c_interpolateData/mooseData.Rdata")

# Prepare data----

# Convert to telemetry object
gpsData <- ctmm::as.telemetry(mooseData)

# Exclude individuals M30927a, M30928a, M30928b, M35172
# Variogram reveals too few data points to reach asymptote
idsToExclude <- c("M30927a","M30928a", "M30928b", "M35172")
gpsDataExcluded <- gpsData[-unlist(lapply(idsToExclude, function(x) grep(x, names(gpsData)) ) ) ]
names(gpsDataExcluded)

rm(idsToExclude)

# Model selection----

# Use ctmm.guess (=variogram.fit) to obtain initial "guess" parameters, which can then be passed onto to ctmm.fit
# Use ctmm.select to choose top-ranked model, which will be used to generate aKDEs
# Do not use ctmm.fit - ctmm.fit() returns a model of the same class as the guess argument i.e. an OUF model with anisotropic covariance.

initParam <- lapply(gpsDataExcluded[1:length(gpsDataExcluded)], function(b) ctmm.guess(b,interactive=FALSE) )

# Takes ~3 hours to run
fitMoveModels <- lapply(1:length(gpsDataExcluded), function(i) ctmm.select(gpsDataExcluded[[i]],initParam[[i]],verbose=TRUE) )

# Add names to list items
names(fitMoveModels) <- names(gpsDataExcluded[1:length(gpsDataExcluded)])

# Export results
save(fitMoveModels,file="pipeline/05a_ctmmModelSelection/fitMoveModels.RData")

# View top model for each individual
# Why is dof.area so low for individuals with the same number of locations?
lapply(fitMoveModels,function(x) summary(x)) #

# Plot variogram with model fit----

for (i in 1:length(gpsDataExcluded)){
id <- names(gpsDataExcluded)[[i]]
vario <- variogram(gpsDataExcluded[[i]], dt = 2 %#% "hour")
fitOneId<-fitMoveModels[[i]]
plot(vario,CTMM=fitOneId,col.CTMM=c("red","purple","blue","green"),fraction=0.65,level=0.5,main=id)
}


xlim <- c(0,12 %#% "hour")
plot(vario,CTMM=fitOneId,col.CTMM=c("red","purple","blue","green"),xlim=xlim,level=0.5)
