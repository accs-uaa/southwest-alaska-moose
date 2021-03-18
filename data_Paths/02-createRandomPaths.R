# Objective: Generate 100 random paths for every moose-year path. Each random path has the same starting location and the same number of points as the observed path on which it is based. Step lengths and turning angles are randomly sampled from theoretical distributions, whose parameters were obtained by fitting data from our study population.
# From these 100 paths, we will select a random subset of 10 paths that do not cross non-habitat e.g. lakes.

# Author: A. Droghini (adroghini@alaska.edu)

#### Load packages and data----
rm(list=ls())
source("package_Paths/init.R")
load(file="pipeline/telemetryData/gpsData/04-formatForCalvingSeason/gpsCalvingSeason.Rdata")

angles <- as.numeric(read_csv(file="pipeline/paths/randomRadians.csv",col_names=FALSE)$X1)
distances1 <- as.numeric(read_csv(file="pipeline/paths/randomDistances_calf1.csv",col_names=FALSE)$X1)
distances0 <- as.numeric(read_csv(file="pipeline/paths/randomDistances_calf0.csv",col_names=FALSE)$X1)

#### Create data ----

# Obtain starting location for every moose-year path
# Calculate number of points for every path
startPts <- gpsCalvingSeason %>%
  filter(RowID==1) %>% 
  dplyr::select(mooseYear_id,Easting,Northing,calfAtHeel)

startPts$length <- (plyr::count(gpsCalvingSeason, "mooseYear_id"))$freq

# Create a list for storing random paths
# The list will contain a named component for every moose-year
allIDs <- unique(startPts$mooseYear_id)
pathsList <- vector("list", length(allIDs))
names(pathsList) <- allIDs

#### Run createRandomPaths function ----
numPaths <- 100

pathsList <- createRandomPaths(initPts = startPts, numberOfPaths = numPaths, 
                               ids = allIDs, pathLength = startPts$length,
                               angles = angles, distances1 = distances1,
                               distances0 = distances0,
                               calfStatus = startPts$calfAtHeel)

# Clean workspace
rm(angles,distances1,distances0,createRandomPaths,allIDs)

#### Convert to dataframe ----
pathsDf <- lapply(pathsList, function(x) do.call(rbind, x))
pathsDf <- data.table::rbindlist(pathsDf,use.names=FALSE,idcol=TRUE)
pathsDf$rowID <- as.integer(row.names(pathsDf))

# The result is wide dataframe where each row represents points along the path. X and Y coordinates are listed as columns. If >1 random path is generated per observed paths, all the x coordinates will be listed first, followed by all of the ys. E.g. if 2 random paths are generates, columns "V1" and "V2" represent the 1st and 2nd iterations of random x coordinates. Columns "V3" and "V4" represent the 1st and 2nd iterations of random y coordinates. Columns "V1" and "V3" form a xy pair.

# Specify start and end of coordinate column names to pivot_longer on. Names depend on the number of paths that are generated.
colx1 <- "V1"
colx2 <- paste0("V",numPaths)
coly1 <- paste0("V",(numPaths+1))
coly2 <- paste0("V",(numPaths*2))

# Pivot dataframe into long format and generate sequential number for every x,y, coordinate in a path, treating X and Y coordinate columns separately.

pathsX <- pathsDf %>% 
  pivot_longer(cols=all_of(colx1):all_of(colx2),names_to="pathID",names_prefix="V",values_to=c("x")) %>% 
  dplyr::select(-c(all_of(coly1):all_of(coly2))) %>% 
  mutate(pathID = as.numeric(pathID)) %>% 
  arrange(.id,pathID,rowID)

pathsY <- pathsDf %>% 
  pivot_longer(cols=all_of(coly1):all_of(coly2),
               names_to="pathID",names_prefix="V",values_to=c("y")) %>% 
  dplyr::select(-c((all_of(colx1):all_of(colx2)))) %>% 
  mutate(pathID = (as.numeric(pathID)-numPaths)) %>% 
  arrange(.id,pathID,rowID)

randomPaths <- left_join(pathsX,pathsY,by=c(".id","pathID","rowID")) %>%
  mutate(fullPath_id = paste(.id,pathID,sep="-")) %>% 
  group_by(fullPath_id) %>% 
  arrange(.id,pathID,rowID) %>% 
  dplyr::mutate(pointID = row_number(rowID), 
                fullPoint_id = paste(.id,pathID,pointID,sep="-")) %>% 
  rename(mooseYear_id = .id) %>% 
  dplyr::select(mooseYear_id,pathID,pointID,x,y,fullPath_id,fullPoint_id)

# Clean workspace
rm(pathsDf,pathsList,pathsX,pathsY,startPts)

#### Combine random & observed paths ----

# Create logistic response
randomPaths$response <- "0"
gpsCalvingSeason$response <- "1"

# Add calfAtHeel variable to randomPaths
# This variable will be used to split paths into two groups (cows with and without calves) and run two separate models
statusObserved <- gpsCalvingSeason %>% 
  dplyr::select(mooseYear_id,RowID,calfAtHeel,deployment_id)

randomPaths <- left_join(randomPaths,
                    statusObserved,by=c("mooseYear_id"="mooseYear_id",
                                        "pointID"="RowID"))
rm(statusObserved)

# Remove superfluous rows from observed paths
# Rename columns to match random paths
names(gpsCalvingSeason)
gpsCalvingSeason <- gpsCalvingSeason %>% 
  dplyr::select(mooseYear_id,RowID,Easting,Northing,calfAtHeel,
                response,deployment_id) %>% 
  rename(x = Easting, y = Northing, pointID = RowID) %>% 
  mutate(pathID = "observed",
         fullPath_id = paste(mooseYear_id,pathID,sep="-"),
         fullPoint_id = paste(mooseYear_id,pathID,pointID,
                              sep="-"))

# Join datasets
allPaths <- rbind.fill(gpsCalvingSeason,randomPaths)

#### Export data----
# To verify results in GIS
# Projection is EPSG = 3338, NAD 83 Alaska Albers
write_csv(allPaths,file="pipeline/paths/allPaths.csv")

# Clear workspace
rm(list=ls())