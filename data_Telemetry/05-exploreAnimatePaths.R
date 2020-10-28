# Objective: Create animation of moose paths to examine movements during calving period.

# Author: Amanda Droghini (adroghini@alaska.edu)

# Load packages and data ----
rm(list=ls())
source("package_TelemetryFormatting/init.R")
load(file="pipeline/telemetryData/gpsData/04-formatForCalvingSeason/gpsCalvingSeason.Rdata")

# Create tlocoh object
gpsCalvingSeason <- gpsCalvingSeason %>% arrange(animal_id)

coords <- as.data.frame(gpsCalvingSeason %>% dplyr::select(Easting,Northing))

data <- xyt.lxy(xy=coords,dt=gpsCalvingSeason$datetime,proj4string=CRS("+init=epsg:32604"),
                id=gpsCalvingSeason$animal_id,dup.dt.check = TRUE)

rm(coords)

# Create animation----

# Generate a color for each individual
# Remove black and grays - hard to see dark shades in Google Earth
allColors <- colors(distinct = TRUE)
allColors <- allColors[which(!grepl("gray|black",allColors))]
set.seed(52)
plotColors <- sample(allColors, 24)

# Specify file path and name of individual kml layers
filePath <- "pipeline/telemetryData/animateLocs_calvingSeason"
ids <- unique(gpsCalvingSeason$animal_id)

# Generate kml
# Thin to two points per day
lxy.exp.kml(data, file=filePath, col=plotColors,id = ids, skip = 6, overwrite = TRUE, compress = FALSE, pt.scale = 0.3, show.path = TRUE)

# Clean workspace
rm(list=ls())