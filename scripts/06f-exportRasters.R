# Objectives: Export akde home ranges as rasters for visualization and manipulation in GIS.

# Author: A. Droghini (adroghini@alaska.edu)
#         Alaska Center for Conservation Science


# Export as rasters -----
fileName <- paste(getwd(),"pipeline/06e_generateHomeRanges/rasters/",sep="/")

# level.UD doesn't give me anything different, regardless of value?

laply(1:length(homeRanges),function(x) 
  ctmm::writeRaster(homeRanges[[x]],DF="PDF",
                    filename=paste(fileName,names(homeRanges[x]),sep="/"),
                    format = "GTiff",
                    level=0.95, 
                    options="COMPRESS=LZW"),.progress = "text")

# Normalize rasters using the Transformation / Normalize tool in: Evans JS, Oakleaf J, Cushman SA (2014) An ArcGIS Toolbox for Surface Gradient and Geomorphometric Modeling, version 2.0-0. URL: https://github.com/jeffreyevans/GradientMetrics Accessed: 2020 June 05.

SpatialPointsDataFrame.telemetry(homeRanges)
writeShapefile(homeRanges,
               folder=filePath, file=names(homeRanges),
               level.UD=0.95)


lapply(1:length(homeRanges), function (i) writeShapefile(homeRanges[[i]],
                                                         folder=filePath, file=names(homeRanges[i]),
                                                         level.UD=0.95))

rm(list=ls())