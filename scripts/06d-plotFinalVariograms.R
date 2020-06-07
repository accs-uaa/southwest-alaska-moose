# Objective: Plot variograms to assess model fit, both for long and short (12 hour) time lags. Preliminary variograms were already plotted prior to selecting the final models, and poorly fitting models were discarded.

# Author: A. Droghini (adroghini@alaska.edu)
#         Alaska Center for Conservation Science

##### Load packages and data ----
load(file="pipeline/06c_selectFinalModels/finalModels.Rdata")
load(file="pipeline/06b_applyCalibration/calibratedData.Rdata")
source("scripts/function-variogramWithModelFit.R")

# Reorder lists so order of names match
finalMods <- finalMods[names(calibratedData)]
names(calibratedData) == names(finalMods)

#### Plot variograms -----
varioPlot(calibratedData, "pipeline/06d_plotVariograms/",
          finalMods,zoom=TRUE)


