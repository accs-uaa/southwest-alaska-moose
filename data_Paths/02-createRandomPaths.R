# Objective: Generate 10 random paths for every moose-year path. Each random path has the same starting location and the same number of points as the observed path on which it is based. Step lengths and turning angles are randomly sampled from theoretical distributions, whose parameters were obtained by fitting data from our study population.

# Author: A. Droghini (adroghini@alaska.edu)

#### Load packages and data----
rm(list=ls())
source("package_Paths/init.R")
load(file="pipeline/telemetryData/gpsData/04-formatForCalvingSeason/gpsCalvingSeason.Rdata")

angles <- as.numeric(read_csv(file="pipeline/paths/randomRadians.csv",col_names=FALSE)$X1)
distances <- as.numeric(read_csv(file="pipeline/paths/randomDistances.csv",col_names=FALSE)$X1)

#### Create data ----

# Obtain starting location for every moose-year path
# Calculate number of points for every path
startPts <- gpsCalvingSeason %>%
  filter(RowID==1) %>% 
  dplyr::select(mooseYear_id,Easting,Northing)

startPts$length <- (plyr::count(gpsCalvingSeason, "mooseYear_id"))$freq

rm(gpsCalvingSeason)

# Create a list for storing random paths
# The list will contain a named component for every moose-year
allIDs <- unique(startPts$mooseYear_id)
pathsList <- vector("list", length(allIDs))
names(pathsList) <- allIDs

#### Run createRandomPaths function ----
pathsList <- createRandomPaths(initPts = startPts, numberOfPaths = 10, 
                               ids = allIDs, pathLength = startPts$length,
                               angles = angles, distances = distances)

# Clean workspace
rm(angles,distances,createRandomPaths,allIDs)

#### Convert to dataframe ----
# Columns represent paths
# Rows represent sequential points at those paths
pathsDf <- lapply(pathsList, function(x) do.call(rbind, x))
pathsDf <- data.table::rbindlist(pathsDf,use.names=FALSE,idcol=TRUE)
pathsDf$rowID <- as.integer(row.names(pathsDf))

# Pivot dataframe into long format so that all coordinate columns are collapsed to an x,y column pair
# Generate sequential number for every x,y, coordinate in a path

pathsX <- pathsDf %>% 
  pivot_longer(cols=V1:V10,names_to="pathID",names_prefix="V",values_to=c("x")) %>% 
  dplyr::select(-c(V11:V20)) %>% 
  mutate(pathID = as.numeric(pathID)) %>% 
  arrange(.id,pathID,rowID)

pathsY <- pathsDf %>% 
  pivot_longer(cols=V11:V20,names_to="pathID",names_prefix="V",values_to=c("y")) %>% 
  dplyr::select(-c(V1:V10)) %>% 
  mutate(pathID = as.numeric(pathID)-10) %>% 
  arrange(.id,pathID,rowID)

randomPaths <- left_join(pathsX,pathsY,by=c(".id","pathID","rowID")) %>%
  mutate(fullPath_id = paste(.id,pathID,sep="-")) %>% 
  group_by(fullPath_id) %>% 
  arrange(.id,pathID,rowID) %>% 
  dplyr::mutate(pointID = row_number(rowID), fullPoint_id = paste(.id,pathID,pointID,sep="-")) %>% 
  rename(mooseYear_id = .id) %>% 
  dplyr::select(mooseYear_id,pathID,pointID,x,y,fullPath_id,fullPoint_id)
