# Objective: Import data from VHF collars. 

# Author: A. Droghini (adroghini@alaska.edu)
#         Alaska Center for Conservation Science

# Last updated: 21 May 2019

# Load packages and data files----
library(tidyverse)
library(readxl)
data.files <-list.files(file.path('collar_data/vectronic'),full.names = TRUE,pattern=".csv")

#### Process VHF data----
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
  mutate(Origin = "VHF") %>% 
  filter(!is.na(Lat_Y) | !is.na(Long_X))



#### When picking up VHF collars again, the following code should go in another script that deals with cleaning outliers, etc.
# Fix typo for longitude of one point (identified in GIS)
outlier <- which(vhf.data$Long_X=="-58.89396")
vhf.data[outlier,]$Long_X <- -158.89396
rm(outlier)

# Remove outlier in Bristol Bay
vhf.data <- vhf.data %>% 
  filter(!(Long_X=="-157.9081" & vhf.data$Lat_Y=="58.038"))


