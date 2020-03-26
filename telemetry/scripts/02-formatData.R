# Objective: Format data: Rename columns, recode collar ID to take into account redeployments.

# Author: A. Droghini (adroghini@alaska.edu)
#         Alaska Center for Conservation Science

#### Load packages and data----
library(tidyverse)
library(rgdal)

load("pipeline/01_importData/gps_raw.Rdata") # GPS telemetry data
load("pipeline/01_createDeployMetadata/deployMetadata.Rdata") # Deployment metadata file

source("scripts/function-collarRedeploys.R")

#### Format GPS data----

# 1. Filter out records for which Date Time, Lat, or Lon is NA
# 2. Filter out records with long values of 13.xx, which is in Germany where collars are manufactured
# 3. Combine date and time in a single column ("datetime")
## Use UTC time zone to conform with Movebank requirements
# 4. Rename Latitude.... ; Longitude.... ; Temp...C. ; Height..m.

gpsData <- gpsData %>% 
  dplyr::mutate(datetime = as.POSIXct(paste(gpsData$UTC_Date, gpsData$UTC_Time), 
                               format="%m/%d/%Y %I:%M:%S %p",tz="UTC")) %>% 
  dplyr::rename(longX = "Longitude....", latY = "Latitude....", tempC = "Temp...C.",
         height_m = "Height..m.", tag_id = CollarID, mortalityStatus = "Mort..Status") %>% 
  filter(!(is.na(longX) | is.na(latY) | is.na(UTC_Date))) %>% 
  filter(longX < -152)

## Generate Eastings and Northings----
# This makes calculation of movement metrics easier
coordLatLong = SpatialPoints(cbind(gpsData$longX, gpsData$latY), proj4string = CRS("+proj=longlat"))
coordLatLong # check that signs are correct

# Transform coordinates to UTM
# Use EPSG=32604 for WGS84, UTM Zone 4N
coordUTM <- spTransform(coordLatLong, CRS("+init=epsg:32604"))
coordUTM <- as.data.frame(coordUTM)
gpsData$Easting <- coordUTM[,1]
gpsData$Northing <- coordUTM[,2]
rm(coordUTM,coordLatLong)

#### Correct redeploys----

# Filter deployment metadata to include only GPS data and redeploys
# Redeploys are differentiated from non-redeploys because they end in a letter
redeployList <- deploy %>% 
  filter(sensor_type == "GPS" & (grepl(paste(letters, collapse="|"), deployment_id))) %>% 
  dplyr::select(deployment_id,tag_id,deploy_on_timestamp,deploy_off_timestamp) 

# Format LMT Date column as POSIX data type for easier filtering
gpsData$LMT_Date = as.POSIXct(strptime(gpsData$LMT_Date, 
                                       format="%m/%d/%Y",tz="America/Anchorage"))

# Use tagRedeploy function to evaluate whether a tag is unique or has been redeployed
gpsData$tagStatus <- tagRedeploy(gpsData$tag_id,redeployList$tag_id)

# The next part is janky because my function writing skills are not great
# The makeRedeploysUnique function only works on redeploys so I need to filter out redeploys & then merge back in with the rest of the data
# The function also identifies "errors" e.g. when the collar is left active in the office between deployments. I need to filter these out manually before merging back
gpsRedeployOnly <- subset(gpsData,tagStatus=="redeploy")
gpsUniqueOnly <- subset(gpsData,tagStatus!="redeploy")

gpsRedeployOnly$deployment_id <- apply(X=gpsRedeployOnly,MARGIN=1,FUN=makeRedeploysUnique,redeployData=redeployList)

# Filter out errors and rbind with non-redeploys
gpsRedeployOnly <- subset(gpsRedeployOnly,deployment_id!="error")
gpsUniqueOnly$deployment_id <- paste0("M",gpsUniqueOnly$tag_id,sep="")

gpsData <- rbind(gpsUniqueOnly,gpsRedeployOnly)

# Check
unique(gpsData$deployment_id)
length(unique(gpsData$deployment_id)) # Should be 24

# Clean workspace
rm(gpsRedeployOnly,gpsUniqueOnly,redeployList,makeRedeploysUnique,tagRedeploy)


#### Create unique row number----
# For each device, according to date/time
# Note that RowID is now unique within but not across individuals

gpsData <- gpsData %>% 
group_by(deployment_id) %>% 
  arrange(datetime) %>% 
  dplyr::mutate(RowID = row_number(datetime)) %>% 
  arrange(deployment_id,RowID) %>% 
  ungroup() %>% 
  dplyr::select(RowID,everything())
 

# Join with deployment metadata to get individual animal ID
# Useful when uploading into Movebank.
deploy <- deploy %>% dplyr::select(animal_id,deployment_id)
gpsData <- left_join(gpsData,deploy,by="deployment_id")
rm(deploy)

# Coerce back to dataframe (needed for move package)
gpsData <- as.data.frame(gpsData)

# Save as .Rdata file
save(gpsData, file="pipeline/02_formatData/gps_formatted.Rdata")
