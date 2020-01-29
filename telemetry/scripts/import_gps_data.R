# Objective: Import data from GPS collars. Combine all data files into a single dataframe that can be used for analyses.

# Author: A. Droghini (adroghini@alaska.edu)
#         Alaska Center for Conservation Science

# Last updated: 29 Jan 2020

# Load packages and data files----
# Data were downloaded from Vectronic on 5 Nov 2019
# Data for each moose are stored as separate .csv files

library(plyr)
library(tidyverse)

data.files <-list.files(file.path('collar_data/gps'),full.names = TRUE,pattern=".csv")

# Read in each file and combine into single dataframe
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

# Remove extra columns----
names(gps.data)
summary(gps.data)
# length(unique(gps.data$CollarID))
# unique(X3D_Error..m.)


# List of changes to make to dataframe:
# See https://www.vectronic-aerospace.com/wp-content/uploads/2016/04/Manual_GPS-Plus-X_v1.2.1.pdf) page 125 for meaning of column names

# Drop the following columns: 
# 1. "Activity", "X3D_Error..m."
# Reason: Columns have the same value across all rows
# 2. "Main..V.", "Beacon..V."
# Reason: Unnecessary for analyses, tells you about collar battery life 
# 3. "SCTS_Date", "SCTS_Time"
# Reason: this is not the date/time of the fix
# 4. AnimalID , GroupID, all C.N. and Sat/Sats columns
# Reason: All NAs
# 5. ECEF columns
# Reason: No need for "earth-fixed" coordinates (https://en.wikipedia.org/wiki/ECEF). Use UTM or Lat/Long 

# Rename Latitude.... ; Longitude.... ; Temp...C. ; Height..m.

# Add column to differentiate between VHF & GPS data

drop.cols <- c("Activity", "X3D_Error..m.", "Main..V.", "Beacon..V.",
               "SCTS_Date", "SCTS_Time",names(gps.data)[19:43],"AnimalID","GroupID",
               "ECEF_X..m.","ECEF_Y..m.","ECEF_Z..m.")

gps.data <- gps.data %>% 
  select(-drop.cols) %>% 
  rename(Long_X = "Longitude....", Lat_Y = "Latitude....", Temp_C = "Temp...C.",
         Height_m = "Height..m.") 

# Code CollarID as factor
gps.data <- gps.data %>% 
  mutate(CollarID=as.factor(CollarID))
  
rm(drop.cols)

#### Export----
save(gps.data, file="output/gps_raw.Rdata")

