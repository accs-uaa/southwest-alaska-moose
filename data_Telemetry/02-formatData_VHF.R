# Objective: Import VHF dataset & format it similar to GPS data so that both can be used in a habitat selection analysis.

# Author: A. Droghini (adroghini@alaska.edu)

# Define Git directory ----
git_dir <- "C:/Work/GitHub/southwest-alaska-moose/package_TelemetryFormatting/"

#### Load packages ----
source(paste0(git_dir,"init.R"))

#### Load data ----
flightData <- read_excel(paste0(input_dir,"from_access_database/","dbo_FlightIndex.xlsx"),
                         sheet="dbo_FlightIndex")
vhfData <- read_excel(paste0(input_dir,"from_access_database/",
                             "dbo_MooseRadioTelemetry.xlsx"),sheet="dbo_MooseRadioTelemetry")

load(paste0(pipeline_dir,"01_createDeployMetadata/","deployMetadata.Rdata"))

# Format data ----

# Join vhfData with deploy data to get collar ID (where applicable)
# Add negative sign to longitude entries that do not have any.
# Drop entries that do not have coordinates. some entries have a waypoint number but no coordinates- these cases need to be dropped as well (coordinates were lost)
# Only include entries for which sensor_type = VHF. For GPS, no need for relocations since we will be using GPS collar data for those individuals. For sensor_type = "none", not enough observations for these individuals and no daily calf status since they couldn't be consistently relocated.
vhfData <- left_join(vhfData,deploy,by=c("Moose_ID"="animal_id")) %>%
  mutate(longX = case_when (Lon_DD < 0 ~ Lon_DD,
                            Lon_DD > 0 ~ Lon_DD*-1)) %>%
  dplyr::select(Moose_ID,deployment_id,sensor_type,Lat_DD,longX,FlightIndex_ID) %>%
  filter(!(is.na(Lat_DD) | is.na(longX))) %>%
  filter(sensor_type=="VHF")

# QA/QC ----

# Check for coordinate outliers
plot(vhfData$longX~vhfData$Lat_DD) # Examine two weird entries
which(vhfData$longX > -80)
which(vhfData$Lat_DD < 58.5)
vhfData[1060,]
vhfData[10,]
# Delete both of those - 1060 is not in AK and 10 is in the Bering Sea
# Mapping VHF data on our study area map revealed two additional outliers where longX > -156. VHF outliers easier to identify because we know the bounds of Kassie's flights.
vhfData <- vhfData %>%
  filter(!(Lat_DD < 58.5 | longX > -156))

plot(vhfData$longX~vhfData$Lat_DD) # Looks good.

# Explore sample size
table(vhfData$deployment_id,vhfData$sensor_type)

# Join with Flight Data ----
# Join vhfData with flightData to obtain date of observation
# Rename lat lon columns to match with GPS data formatting
flightData <- dplyr::select(.data=flightData,FlightIndex_ID,Flight_Date)

vhfData <- left_join(vhfData,flightData,by="FlightIndex_ID") %>%
  dplyr::select(-FlightIndex_ID) %>%
  rename(AKDT_Date = Flight_Date,latY = Lat_DD)

# Convert date to as.Date object
vhfData$AKDT_Date <- as.Date(vhfData$AKDT_Date,format="%Y-%m-%d")

#### Export data----
# As.Rdata file rather than .csv because I don't want to deal with reclassifying my dates
save(vhfData,file=paste0(pipeline_dir,"02_formatData/","vhfData_formatted.Rdata"))

write_csv(vhfData,file=paste0(output_dir,"animalData/","cleanedVHFdata.csv"))

# Clean workspace
rm(list=ls())