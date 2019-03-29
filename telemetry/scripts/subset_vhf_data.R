# Last updated: 29 March 2019

# Objective: Subset VHF data to only include points from May to September. Points will be used in our field planning process to verify that our sampling points provide adequate coverage of where moose are actually going.

# Author: A. Droghini (adroghini@alaska.edu)
#         Alaska Center for Conservation Science

# Load required libraries
library(lubridate)
library(tidyverse)

# Create Month column for subsetting
# Create Week column for future binning by time of year
subset.vhf <- vhf.data %>% 
  mutate(Month = month(LMT_Date)) %>% 
  filter(Month < 11 & Month >4) %>% 
  select(-Month)  %>% 
  mutate(Week = paste(year(LMT_Date),week(LMT_Date),sep="-"))

# Export as .csv
write.csv(subset.vhf,"collar_data/subset_vhf_data.csv",row.names=FALSE)
