# Objective: Import data from GPS collars. Data were provided as a single shapefile.

# Data were downloaded by Kassie on 31 March 2020.

# Author: A. Droghini (adroghini@alaska.edu)
#         Alaska Center for Conservation Science

# Load packages and data files----
library(sf)

gpsData <- st_read("data/Moose_2020-03-31.shp")

#### Export----
save(gpsData, file="pipeline/01_importData/gpsRaw.Rdata")
