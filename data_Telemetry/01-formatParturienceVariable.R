# Objective: For every cow, create a variable "Boolean Parturience" that tracks the survival of calves during calving season. This variable will be used to develop separate models for a) females with calf-at-heel (birthing sites) and b) females without calves. For now, we treat twins or triplets as single boolean Calf-At-Heel. If one calf of a twin set dies, then the cow remains in Calf-At-Heel (1) status. We may add a variable of # of calves in the future.
# We drop observations of pregnant cows that have not yet given birth. These observations were originally coded as 0s, but we recoded them as 3s in MS Excel to make it easy to drop them here. The reason we drop them is because we do not want to conflate the movement patterns/vegetation selection of females on their way to birthing site to females with calf-at-heel (if coded as 1) or to females with dead/no calf (at or on their way to foraging sites).

# Author: A. Droghini (adroghini@alaska.edu)

# Load packages and data----
source("package_TelemetryFormatting/init.R")

calf2018 <- read_excel("data/calvingSeason/Parturience2018-2019.xlsx",
                       sheet="2018_noLeadingZeroes",range="A1:AG67")
calf2019 <- read_excel("data/calvingSeason/Parturience2018-2019.xlsx",
                       sheet="2019_noLeadingZeroes",range="A1:AH84")

load(file="pipeline/telemetryData/gpsData/01_createDeployMetadata/deployMetadata.Rdata")

# Format data ----

# Convert date columns to long form
# For 2019, drop 1 bull moose from dataset
calf2018 <- calf2018 %>%
  pivot_longer(cols="11 May 2018":"23 June 2018",names_to="AKDT_Date",
               values_to="calfStatus")

calf2019 <- calf2019 %>%
  pivot_longer(cols="11 May 2019":"6 June 2019",names_to="AKDT_Date",
               values_to="calfStatus") %>%
  dplyr::filter(!Notes=="Bull" | is.na(Notes)) # need to specify to is.na

# Combine both years into single data frame
calfData <- rbind(calf2018,calf2019)

# Add collar ID using moose ID as a key
calfData <- left_join(calfData,deploy,by=c("Moose_ID"="animal_id"))

# Create boolean calfAtHeel status
# Drop observations that are coded as NA (unobserved) and "3" (cow pregnant, calf not yet born)
calfData <- calfData %>%
  dplyr::filter(!(calfStatus == 3 | is.na(calfStatus))) %>% 
  mutate(calfAtHeel = case_when(calfStatus > 1 ~ 1,
                               calfStatus <= 1 ~ calfStatus)) %>%
  dplyr::select(deployment_id,sensor_type,AKDT_Date,calfAtHeel)

# Convert date to POSIX object
calfData$AKDT_Date <- as.Date(calfData$AKDT_Date,format="%e %B %Y")

#### Export data----
# As.Rdata file rather than .csv because I don't want to deal with reclassifying my dates
save(calfData,file="pipeline/telemetryData/parturienceData.Rdata")

# Clean workspace
rm(list=ls())