# Objective: Create animation of moose paths to examine seasonal movements and migratory behaviors

# Load packages and data----
rm(list=ls())
source("scripts/init.R")
load("pipeline/03b_cleanLocations/cleanLocations.Rdata") 

# Create tlocoh object
coords<-gpsClean[,9:10]
data <- xyt.lxy(xy=coords,dt=gpsClean$datetime,proj4string=CRS("+proj=longlat +datum=WGS84 +no_defs +ellps=WGS84 +towgs84=0,0,0"),id=gpsClean$deployment_id,dup.dt.check = TRUE)

rm(coords)

# Create animation----

# Plotting parameters
# Generate a color for each individual
# Remove black and grays - hard to see dark shades in GE

allColors <- colors(distinct = TRUE)
allColors <- allColors[which(!grepl("gray|black",allColors))]
set.seed(52)
plotColors <- sample(allColors, 24)

# Specify file path and name of individual kml layers
filePath <- "pipeline/04b_animatePaths/temp/animateLocations"
ids <- unique(gpsClean$deployment_id)

# Generate kml
# Thin to one point per day
lxy.exp.kml(data, file=filePath, col=plotColors,id = ids, skip = 12, overwrite = TRUE, compress = FALSE, pt.scale = 0.3, show.path = FALSE)

# Clean workspace
rm(list=ls())