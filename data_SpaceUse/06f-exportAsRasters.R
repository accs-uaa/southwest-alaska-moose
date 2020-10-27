# Objectives: Export akde home ranges as rasters for visualization and manipulation in GIS.

# Author: A. Droghini (adroghini@alaska.edu)
#         Alaska Center for Conservation Science

gc()
memory.limit(10000000000000)
source("scripts/function-exportAKDE.R")
# Export as rasters -----

# List files
files <- list.files("pipeline/06e_generateHomeRanges",pattern="\\d+",full.names = TRUE)

filePath <- paste(getwd(),"pipeline/06f_exportAsRasters",sep="/")

# I reach my memory limit after files 2/3 complete, so I ran the third file separately. In any case, this takes a while.
# Issue: the function doesn't stop on its own, even after it creates all the rasters? 
lapply(files,export_akdes,file_path=filePath)
export_akdes(files,file_path=filePath)

# level.UD doesn't give me anything different, regardless of value?

# Normalize rasters using the Transformation / Normalize tool in: Evans JS, Oakleaf J, Cushman SA (2014) An ArcGIS Toolbox for Surface Gradient and Geomorphometric Modeling, version 2.0-0. URL: https://github.com/jeffreyevans/GradientMetrics Accessed: 2020 June 05.

#### Export telemetry data points ----
SpatialPointsDataFrame.telemetry(homeRanges)
writeShapefile(homeRanges,
               folder=filePath, file=names(homeRanges),
               level.UD=0.95)


lapply(1:length(homeRanges), function (i) writeShapefile(homeRanges[[i]],
                                                         folder=filePath, file=names(homeRanges[i]),
                                                         level.UD=0.95))

rm(list=ls())