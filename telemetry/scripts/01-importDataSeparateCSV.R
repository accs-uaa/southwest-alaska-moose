# Objective: Import data from GPS collars. Combine all data files into a single dataframe that can be used for analyses. Data for each moose are stored as separate .csv files

# Data run up to beginning of August 2019

# Author: A. Droghini (adroghini@alaska.edu)
#         Alaska Center for Conservation Science

# Load packages and data files----
library(plyr)
library(tidyverse)

dataFiles <-list.files(file.path('collar_data/gps'),full.names = TRUE,pattern=".csv")

# Read in each file and combine into single dataframe
# "No" column is not unique across all individuals, but is unique within each individual
# Sorted in decreasing order? (newest to oldest)
# Change "No" column so that numbers go from oldest to newest. Rename as RowID

for (i in 1:length(dataFiles)) {
  f <- dataFiles[i]
  
  temp <- read.csv(f,stringsAsFactors = FALSE)
  # print(max(temp$No)+1==length(temp$No))
  
  temp <- temp %>% 
  arrange(-No)
  
  if (i == 1) {
    gpsData <- temp
    
  } else {
    gpsData <- rbind(gpsData, temp)
  }
}

# Clean workspace
rm(f,i,temp,dataFiles)

# Remove extra columns----
names(gpsData)
summary(gpsData)
length(unique(gpsData$CollarID))

# List of changes to make to dataframe:
# See https://www.vectronic-aerospace.com/wp-content/uploads/2016/04/Manual_GPS-Plus-X_v1.2.1.pdf) page 125 for meaning of column names

# Drop the following columns: 
# 1. "Activity", "X3D_Error..m."
# Reason: Columns have the same value across all rows
# 2. "Main..V.", "Beacon..V."
# Reason: Unnecessary for analyses, tells you about collar battery life 
# 3. "SCTS_Date", "SCTS_Time"
# Reason: this is not the date/time of the fix
# All C.N. and Sat/Sats columns. Reason: All NAs
# 5. ECEF columns
# 6. No.1 and No.2. Reason: Duplicate from No
# Reason: No need for "earth-fixed" coordinates (https://en.wikipedia.org/wiki/ECEF). Use UTM or Lat/Long 

dropCols <- c("No","X3D_Error..m.",
               "SCTS_Date", "SCTS_Time",names(gpsData)[c(19:43,45:47,49:50)],
               "ECEF_X..m.","ECEF_Y..m.","ECEF_Z..m.")

gpsData <- gpsData %>% 
  select(-dropCols)

#### Export----
save(gpsData, file="pipeline/01_importData/gpsRaw_Aug2019.Rdata")

# Clean workspace
rm(dropCols,gpsData)
