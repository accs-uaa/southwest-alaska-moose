# Last updated: 21 May 2019

# Objective: Import data from GPS and VHF collars. Combine all data files into a single dataframe that can be used for analyses.

# Author: A. Droghini (adroghini@alaska.edu)
#         Alaska Center for Conservation Science

# Load required packages
library(plyr)
library(tidyverse)
library(readxl)

# Read in moose collar data
# Data were downloaded from Vectronic on 22 Mar 2019
# Data for each moose are stored as separate .csv files

#data.files <-list.files(file.path('collar_data/vectronic'),full.names = TRUE,pattern=".csv")
data.files <-list.files(file.path('collar_data'),full.names = TRUE,pattern=".csv")


# Read in each file and combined into single dataframe
# "No" column is not unique across all individuals, but is unique within each individual
# Sorted in decreasing order? (newest to oldest)
# Change "No" column so that numbers go from oldest to newest. Rename as RowID

for (i in 1:length(data.files)) {
  f <- data.files[i]
  
  temp <- read.csv(f,stringsAsFactors = FALSE)
  # print(max(temp$No)+1==length(temp$No))
  
  temp <- temp %>% 
  arrange(-No) %>% 
  mutate(No = seq(1,length(No),by=1)) %>% 
  rename(RowID = No)
  
  if (i == 1) {
    gps.data <- temp
    
  } else {
    gps.data <- rbind(gps.data, temp)
  }
}

# Clean workspace
rm(f,i,temp,data.files)

# Examine dataframe attributes
# names(gps.data)
# length(unique(gps.data$CollarID))
# unique(X3D_Error..m.)
# Checked - CollarID and AnimalID have a 1:1 relationship

# List of changes to make to dataframe:
# See https://www.vectronic-aerospace.com/wp-content/uploads/2016/04/Manual_GPS-Plus-X_v1.2.1.pdf) page 125 for meaning of column names

# Drop the following columns: "Origin", "Activity", "Sats", "X3D_Error..m."
# Columns only have the same value across all rows
# Drop "Main..V.", "Beacon..V." - unnecessary for analyses, tells you about collar battery life 
# Drop "SCTS_Date", "SCTS_Time" - this is note the date/time of the fix

# Code CollarID and AnimalID as factors
# Rename Latitude..Â.. ; Longitude..Â.. ; Temp..Â.C. ; Height..m.

# Add column to differentiate between VHF & GPS data

drop.cols <- c("Origin", "Activity", "Sats", "X3D_Error..m.", "Main..V.", "Beacon..V.",
               "SCTS_Date", "SCTS_Time")

gps.data <- gps.data %>% 
  select(-drop.cols) %>% 
  rename(Long_X = "Longitude..Â..", Lat_Y = "Latitude..Â..", Temp_C = "Temp..Â.C.",
         Height_m = "Height..m.") %>% 
  mutate(CollarID=as.factor(CollarID),
         AnimalID=as.factor(AnimalID),
         Collar_Type = "GPS")
  
rm(drop.cols)

# Load VHF data
vhf.data <- read_excel("collar_data/vhf_moose_data.xlsx")

names(vhf.data)
# For now, keep only "Flight_Date", "Moose_ID", "Lat_DD", "Lon_DD"
# Add column to differentiate between VHF & GPS data
# Rename columns to match with gps.data
# Get rid of entries with no lat or lon

vhf.data <- vhf.data %>% 
  select("Flight_Date", "Moose_ID", "Lat_DD", "Lon_DD") %>% 
  rename(Long_X = "Lon_DD", Lat_Y = "Lat_DD", AnimalID = Moose_ID,
         LMT_Date = Flight_Date) %>% 
  mutate(Collar_Type = "VHF") %>% 
  filter(!is.na(Lat_Y) | !is.na(Long_X))

# Fix typo for longitude of one point (identified in GIS)
outlier <- which(vhf.data$Long_X=="-58.89396")
vhf.data[outlier,]$Long_X <- -158.89396
rm(outlier)

# Remove outlier in Bristol Bay
vhf.data <- vhf.data %>% 
  filter(!(Long_X=="-157.9081" & vhf.data$Lat_Y=="58.038"))

# Final merge
telem.data <- rbind.fill(gps.data,vhf.data)

#view data
head(telem.data)


# Write the merged GPS and VHF collar data file to .csv for viewing
# and prep for Movebank

# Need to get date and time in one column
library(lubridate)

telem.data <- telem.data %>% 
  mutate(datetime = as.POSIXct(paste(telem.data$UTC_Date, telem.data$UTC_Time), format="%Y-%m-%d %H:%M:%S"))

telem.data <- telem.data %>% 
  select(CollarID, AnimalID, datetime, Lat_Y, Long_X, Collar_Type, Temp_C, FixType)

#Should check with ADF&G to determine if data collected in WGS94, NAD83, or other projection

head(telem.data)
summary(telem.data)

#Just work with the GPS collar data
telem.data <- telem.data %>% 
  filter(Collar_Type == "GPS")

# There are long's in the 13's, which is in Germany where collars manufactured. Remove.
telem.data <- telem.data %>% 
  filter(Long_X < 0)

head(telem.data)

#This file can be uploaded to Movebank
write.csv(telem.data, file="swmoose.telem.data.csv")
