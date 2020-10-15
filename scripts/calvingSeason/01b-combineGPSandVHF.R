# Objective: Combine VHF and GPS data into a single file. Subset to include only calving season.

# Author: A. Droghini (adroghini@alaska.edu)

#### Load packages and data ----
library(plyr)
library(tidyverse)
library(lubridate)
library(amt)

load("pipeline/calvingSeason/01_formatData/vhfData.Rdata")
load("pipeline/03b_cleanLocations/cleanLocations.Rdata")

#### Format data ----

# Create RowID for VHF data
# Create datetime variable for use with amt package. Exact time of observation in unknown - Set everything to 08:00 and assume relocations on subsequent days were spaced 24 h apart (given flight times and duration, this relocation is ~ 24 hours +/- 4 h)
# Set timezone to UTC to conform with Movebank requirements and to standardize with GPS dataset
# Because all flights were no earlier than mid-morning, AKDT Date = UTC Date (UTC is 8 hours ahead)
vhfData <- vhfData %>% 
  group_by(deployment_id) %>% 
  arrange(AKDT_Date) %>% 
  dplyr::mutate(RowID = row_number(AKDT_Date)) %>% 
  arrange(deployment_id,RowID) %>% 
  ungroup() %>% 
  rename(animal_id = Moose_ID) %>% 
  mutate(datetime = as.POSIXct(paste(AKDT_Date, "08:00:00", sep=" "),
         format="%Y-%m-%d %T",
         tz="UTC"))

# Create sensor_type == GPS for GPS data
gpsClean <- gpsClean %>% 
  mutate(sensor_type = "GPS", AKDT_Date = as.Date(datetime)) %>% 
  select(-c(UTC_Date,UTC_Time,Easting,Northing))

# Combine VHF & GPS data
allData <- plyr::rbind.fill(vhfData,gpsClean)

# Restrict to calving season only
# We define the calving season as the period from May 10th to June 15th
# Might have to be revised since data on calf status ends on the first week of June
allData <- allData %>% 
  dplyr::filter( (month(AKDT_Date) == 5 & day(AKDT_Date) >= 10) | (month(AKDT_Date) == 6 & day(AKDT_Date) >= 15))

# Check if there are any mortality signals- would no longer actively selecting for habitat at that point...
unique(allData$mortalityStatus) # only normal or NA if VHF
allData <- select(.data=allData,-mortalityStatus)

#### Export data ----
# Save as .Rdata file
save(allData, file="pipeline/calvingSeason/01_formatData/allRelocationData.Rdata")

rm(list = ls())