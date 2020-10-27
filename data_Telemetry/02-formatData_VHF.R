# Objective: Import VHF dataset & format it similar to GPS data so that both can be used in a habitat selection analysis.

# Author: A. Droghini (adroghini@alaska.edu)

# Load packages and data----
source("package_TelemetryFormatting/init.R")

flightData <- read_excel("data/calvingSeason/dbo_FlightIndex.xlsx",sheet="dbo_FlightIndex")
vhfData <- read_excel("data/calvingSeason/dbo_MooseRadioTelemetry.xlsx",sheet="dbo_MooseRadioTelemetry")

load("pipeline/01_createDeployMetadata/deployMetadata.Rdata")

# Format data ----

# Join vhfData with deploy data to get collar ID (where applicable)
# Add negative sign to longitude entries that do not have any.
# Drop entries that do not have coordinates. some entries have a waypoint number but no coordinates- these cases need to be dropped as well (coordinates were lost)
# Only include entries for which sensor_type = VHF. For GPS, no need for relocations since we will be using GPS collar data for those individuals. For sensor_type = "none", not enough observations for these individuals and no daily calf status since they couldn't be consistently relocated.
vhfData <- left_join(vhfData,deploy,by=c("Moose_ID"="animal_id")) %>%
  mutate(longX = case_when (Lon_DD < 0 ~ Lon_DD,
                            Lon_DD > 0 ~ Lon_DD*-1)) %>%
  select(Moose_ID,deployment_id,sensor_type,Lat_DD,longX,FlightIndex_ID) %>%
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
vhfData <- vhfData %>%
  filter(!(Lat_DD < 58.5 | longX > -80))

# Explore sample size
table(vhfData$deployment_id,vhfData$sensor_type)

# Join with Flight Data ----
# Join vhfData with flightData to obtain date of observation
# Rename lat lon columns to match with GPS data formatting
flightData <- select(.data=flightData,FlightIndex_ID,Flight_Date)

vhfData <- left_join(vhfData,flightData,by="FlightIndex_ID") %>%
  select(-FlightIndex_ID) %>%
  rename(AKDT_Date = Flight_Date,latY = Lat_DD)

# Convert date to as.Date object
vhfData$AKDT_Date <- as.Date(vhfData$AKDT_Date,format="%Y-%m-%d")

#### Export data----
# As.Rdata file rather than .csv because I don't want to deal with reclassifying my dates
save(vhfData,file="pipeline/telemetryData/vhfData/vhfData.Rdata")

write_csv(vhfData,file="output/cleanedVHFdata.csv")

# Clean workspace
rm(list=ls())
