# Objective: Create animation of moose paths to examine seasonal movements and migratory behaviors

# Load packages and data----
rm(list=ls())
library(tlocoh) # Can also use moveVis but I was having problem aligning my data
load("pipeline/03c_interpolateData/mooseData.Rdata") 

# Convert moveStak to locoh object
data <- move.lxy(mooseData, use.utm = FALSE)

# Create animation----

# Plotting parameters
# Generate a color for each individual
allColors <- colors(distinct = TRUE)
allColors <- allColors[which(!grepl("gray",allColors))]
set.seed(52)
plotColors <- sample(allColors, 24)

# Specify file path and name of individual kml layers
filePath <- "pipeline/04b_animatePaths/temp/animateLocations"
ids <- unique(mooseData@idData$deployment_id)

# Generate kml
lxy.exp.kml(data, file=filePath, col=plotColors,id = ids, skip = 12, overwrite = TRUE, compress = FALSE, pt.scale = 0.3, show.path = FALSE, path.col = NULL, path.opaque = 80, path.lwd = 3)
