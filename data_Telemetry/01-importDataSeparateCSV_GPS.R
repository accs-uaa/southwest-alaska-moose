# Objective: Import data from GPS collars. Combine all data files into a single dataframe that can be used for analyses. Data for each moose are stored as separate .csv files

# Last data download: 14 Mar 2021 by Kassie

# Author: A. Droghini (adroghini@alaska.edu)
#         Alaska Center for Conservation Science

# Define Git directory ----
git_dir <- "C:/Work/GitHub/southwest-alaska-moose/package_TelemetryFormatting/"

#### Load packages ----
source(paste0(git_dir,"init.R"))

# Load data files ----
# Use pattern="GPS" to drop Mortality files
# Should have 22 files
filePath <- paste0(input_dir,"/telemetry")
dataFiles <- list.files(file.path(filePath),full.names = TRUE,pattern="GPS")

# Read in each file and combine into single dataframe
# "No" column is not unique across all individuals, but is unique within each individual
# Doesn't really matter whether No is by increasing or decreasing date since we will reorder use the datetime column.

for (i in 1:length(dataFiles)) {
  f <- dataFiles[i]

  temp <- read.csv(f,stringsAsFactors = FALSE)

  temp <- temp %>%
  arrange(No)

  if (i == 1) {
    gpsData <- temp

  } else {
    gpsData <- plyr::rbind.fill(gpsData, temp)
  }
}

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

gpsData <- gpsData %>%
  dplyr::select(No, CollarID, UTC_Date,UTC_Time, LMT_Date, LMT_Time,
         Latitude....,Longitude....,Mort..Status,DOP,FixType,Easting,Northing)

####Export----
save(gpsData, file=paste0(pipeline_dir,"01_importData/gpsRaw.Rdata"))

# Clean workspace
rm(list=ls())