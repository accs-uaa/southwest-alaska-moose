# Objectives: Export a subset of "test moose" to play around with in Migration Mapper (https://migrationinitiative.org/content/migration-mapper)
# Trying to figure out the best way to determine cut-offs for seasonal movements. We can then use these cut-offs to generate seasonal aKDEs
# Subset moose were selected because they show different movement patterns: 
## M30102 and M30103 contract their ranges in late winter (January - April)
## M30894 shows a classic migration pattern from summer to winter range
## M30935 is a resident island moose

# Load packages and data----
rm(list=ls())
source("scripts/init.R")
load("pipeline/03b_cleanLocations/cleanLocations.Rdata")

# List of moose to select
idsToSelect<-c("M30102", "M30103", "M30894","M30935")

# Create spatial object----

# Convert from POSIX.ct to character otherwise export step will throw an error
gpsClean$datetime<-as.character(gpsClean$datetime)

gpsClean <- gpsClean %>% 
  dplyr::select(RowID,latY,longX,datetime,Easting,Northing,deployment_id) 

# Convert to sf object
moose_sf = st_as_sf(gpsClean, coords = c("longX","latY"), crs = "+proj=longlat +datum=WGS84 +no_defs +ellps=WGS84 +towgs84=0,0,0")

# Check projection
st_is_longlat(moose_sf)

# Export to shapefile----
filePath<-"pipeline/04c_exportShapefile"
st_write(moose_sf, paste0(filePath, "/", "subsetMoose.shp"), factorsAsCharacter = TRUE, delete_layer = TRUE)

rm(list=ls())