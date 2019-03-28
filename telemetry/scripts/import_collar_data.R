# Load required packages
library(tidyverse)

# Read in moose collar data
# Data were downloaded from Vectronic on 22 Mar 2019
# Data for each moose are stored as separate .csv files

data.files <-list.files(file.path('collar_data'),full.names = TRUE)


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
    telem.data <- temp
    
  } else {
    telem.data <- rbind(telem.data, temp)
  }
}

# Clean workspace
rm(f,i,temp,data.files)

# Examine dataframe attributes
names(telem.data)
length(unique(telem.data$CollarID))
unique(X3D_Error..m.)
attach(telem.data)
# Checked - CollarID and AnimalID have a 1:1 relationship

# List of changes to make to dataframe:
# See https://www.vectronic-aerospace.com/wp-content/uploads/2016/04/Manual_GPS-Plus-X_v1.2.1.pdf) page 125 for meaning of column names
# Drop the following columns: "Origin", "Activity", "Sats", "X3D_Error..m."
# Columns only have the same value across all rows
# Drop "Main..V." and "Beacon..V." - unnecessary for analyses, tells you about collar battery life 
# Drop SCTS Date/time - this is note the date/time of the fix

# Code CollarID and AnimalID as factors
# Rename Latitude..Â.. ; Longitude..Â.. ; Temp..Â.C. ; Height..m.




