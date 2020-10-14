# Objective: Format VHF data similar to GPS data so that both can be used in a habitat selection analysis.

# Author: A. Droghini (adroghini@alaska.edu)

# Load packages and data----
library(tidyverse)
library(readxl)

flightData <- read_excel("data/calvingSeason/dbo_FlightIndex.xlsx",sheet="dbo_FlightIndex")
vhfData <- read_excel("data/calvingSeason/dbo_MooseRadioTelemetry.xlsx",sheet="dbo_MooseRadioTelemetry")

load("pipeline/01_createDeployMetadata/deployMetadata.Rdata")

# Format data----

# Join vhfData with deploy data to get collar ID (where applicable)
# Drop entries that have neither coordinates nor a waypoint (n = 167)
# Drop entries for which sensor_type = GPS since we will be using GPS collar data for those individuals
# Drop entries for which sensor_type = "none". Not enough observations for these individuals and no daily calf status since they couldn't be consistently relocated.
vhfData <- left_join(vhfData,deploy,by=c("Moose_ID"="animal_id")) %>% 
  select(Moose_ID,deployment_id,sensor_type,Lat_DD,Lon_DD,FlightIndex_ID,Waypoint) %>% 
  filter(!(is.na(Lat_DD)&is.na(Waypoint))) %>% 
  filter(sensor_type=="VHF")

# Join vhfData with flightData to obtain date of observation
# Rename lat lon columns to match with GPS data formatting
flightData <- select(.data=flightData,FlightIndex_ID,Flight_Date)

vhfData <- left_join(vhfData,flightData,by="FlightIndex_ID") %>% 
  select(-FlightIndex_ID) %>% 
  rename(AKDT_Date = Flight_Date,latY = Lat_DD, longX = Lon_DD)

# Convert date to as.Date object 
vhfData$AKDT_Date <- as.Date(vhfData$AKDT_Date,format="%Y-%m-%d")

#### Explore sample size ----
table(vhfData$deployment_id,vhfData$sensor_type)

#### Export data----

# As.Rdata file rather than .csv because I don't want to deal with reclassifying my dates
save(vhfData,file="pipeline/calvingSeason/01_formatData/vhfData.Rdata")

# Clean workspace
rm(list=ls())