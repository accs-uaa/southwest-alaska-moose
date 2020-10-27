# Objective: Combine VHF and GPS data into a single file. Subset to include only calving season.

# Author: A. Droghini (adroghini@alaska.edu)

#### Load packages and data ----
library(plyr)
library(tidyverse)
library(lubridate)

load("pipeline/calvingSeason/01_formatData/vhfData.Rdata")
load("pipeline/03b_cleanLocations/cleanLocations.Rdata")

#### Format data ----

# Create datetime variable. Exact time of observation in unknown - Set everything to 08:00 and assume relocations on subsequent days were spaced 24 h apart (given flight times and duration, this relocation is ~ 24 hours +/- 4 h)
# Set timezone to UTC to conform with Movebank requirements and to standardize with GPS dataset
# Because all flights were no earlier than mid-morning, AKDT Date = UTC Date (UTC is 8 hours ahead)
vhfData <- vhfData %>%
  dplyr::rename(animal_id = Moose_ID) %>% 
  mutate(datetime = as.POSIXct(paste(AKDT_Date, "08:00:00", sep=" "),
         format="%Y-%m-%d %T",
         tz="UTC"))

# Create sensor_type == GPS for GPS data
gpsClean <- gpsClean %>% 
  mutate(sensor_type = "GPS", AKDT_Date = as.Date(datetime)) %>% 
  dplyr::select(-c(UTC_Date,UTC_Time,Easting,Northing))

# Combine VHF & GPS data
allData <- plyr::rbind.fill(vhfData,gpsClean)

#### Sample size decisions----

# Restrict to calving season only
# We define the calving season as the period from May 10th to June 15th
# Might have to be revised since data on calf status ends on the first week of June
allData <- allData %>% 
  dplyr::filter( (month(AKDT_Date) == 5 & day(AKDT_Date) >= 10) | (month(AKDT_Date) == 6 & day(AKDT_Date) >= 15))

# Check if there are any mortality signals- would no longer actively selecting for habitat at that point...
unique(allData$mortalityStatus) # only normal or NA if VHF
allData <- dplyr::select(.data=allData,-mortalityStatus)

# Recode deployment_id to include year
# We are treating paths from different calving seasons as independent
allData <- allData %>% 
  mutate(mooseYear_id = paste(deployment_id,year(AKDT_Date),sep="."))

# Create RowID variable for sorting
allData <- allData %>%
  group_by(mooseYear_id) %>% 
  arrange(datetime,.by_group=TRUE) %>% 
  dplyr::mutate(RowID = row_number(datetime)) %>%
  ungroup()

# Calculate number of relocations per moose-year
# How many relocations is too few?
n <- plyr::count(allData, "mooseYear_id") 

n <- left_join(n,allData,by="mooseYear_id") %>% 
  filter(!(duplicated(mooseYear_id))) %>% 
  select(mooseYear_id,freq,sensor_type)
  
temp <- n %>% filter(sensor_type=="VHF")
hist(temp$freq,
     main="Number of VHF relocations per moose-year",
     xlab="Number of relocations",ylab="Number of moose-years",
     xlim = c(0,20),ylim=c(0,50),
     col="#0072B2",border = "#FFFFFF")

n <- n %>% 
  filter(freq >= 15) %>% 

n <- n$deployment_id

allData <- allData %>% 
  filter(deployment_id %in% n)

rm(n)

#### Export data ----
# Save as .Rdata file
save(allData, file="pipeline/calvingSeason/01_formatData/allRelocationData.Rdata")

rm(list = ls())