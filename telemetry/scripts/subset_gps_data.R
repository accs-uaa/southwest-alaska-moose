# Last updated: 29 March 2019

# Objective: Subset GPS data to remove autocorrelation between consecutive fixes. The points that remain will be used in our field planning process to verify that our sampling points provide adequate coverage of where moose are actually going.

# Author: A. Droghini (adroghini@alaska.edu)
#         Alaska Center for Conservation Science

# Load required libraries
library(plyr)
library(tidyverse)
library(lubridate)

# Only looking at summer data (from May to October, inclusively)
summer.data <- gps.data %>% 
  mutate(Month = month(LMT_Date)) %>% 
  filter(Month >= 5 & Month <= 10) %>% 
  select(-Month) %>% 
  mutate(Week = paste(year(LMT_Date),week(LMT_Date),sep="-"))

# Create Date/Time column
# Convert to POSIX item
Sys.setenv(TZ="GMT") 
# DST-free timezone equivalent to UTC Date/Time columns
summer.data$DateTime <- paste(summer.data$UTC_Date,summer.data$UTC_Time, sep=" ")
summer.data$DateTime <- as.POSIXct(strptime(summer.data$DateTime, format="%Y-%m-%d %H:%M:%S",tz="GMT"))

# Calculate fix rate (time interval between two consecutive fixes)
# Check for outliers
# Fix rate should be 120 min (3 hours)
for (i in 2:nrow(summer.data)) {
  if (summer.data$CollarID[i] == summer.data$CollarID[i - 1]) {
    summer.data$FixRate[i] <-
      difftime(summer.data$DateTime[i], summer.data$DateTime[i - 1], units = "mins")
  }
}

rm(i)

# Summarize Fix Rate results
fix.summary <- summer.data %>%
  group_by(CollarID) %>%
  summarise(
    obs = length(CollarID),
    start.time = min(DateTime),
    end.time = max(DateTime),
    mean.fix = mean(FixRate,na.rm=TRUE), # first row is NA (no previous fix)
    sd.fix = sd(FixRate,na.rm=TRUE),
    max.fix = max(FixRate,na.rm=TRUE), 
    min.fix = min(FixRate,na.rm=TRUE)
  )

# Remove rows with Time Since Fix < 100
summer.data <- summer.data %>% 
  filter(FixRate >=100)

rm(fix.summary)

# Keep one fix rate per day per moose, selected at random
# Not a perfect way to do it, but super quick to code :-)
# Becomes nightmarish real fast..
subset.gps <- summer.data %>% 
  group_by(CollarID,LMT_Date) %>% 
  sample_n(1)

# Export file for plotting in GIS
write.csv(subset.gps,"collar_data/subset_gps_data.csv",row.names=FALSE)

# Merge with vhf for Timm
names(subset.gps)
subset.gps <- subset.gps %>% 
  select(CollarID, AnimalID,LMT_Date,LMT_Time,Lat_Y,
         Long_X,DateTime,Collar_Type,Week)

subset.all <- plyr::rbind.fill(subset.gps,subset.vhf)
write.csv(subset.gps,"collar_data/subset_combined.csv",row.names=FALSE)
