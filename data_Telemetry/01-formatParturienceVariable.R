# Objective: For every cow, create a variable "Boolean Parturience" that tracks the survival of calves during calving season. This variable will be used in our path selection function to explore the effect of reproductive status on habitat selection. For now, we treat twins or triplets as single boolean Calf-At-Heel. If one calf of a twin set dies, then the cow remains in Calf-At-Heel (1) status. We may add a variable of # of calves in the future.

# Author: A. Droghini (adroghini@alaska.edu)

# Load packages and data----
source("package_TelemetryFormatting/init.R")

calf2018 <- read_excel("data/calvingSeason/Parturience2018-2019.xlsx",sheet="2018",range="A1:AG67")
calf2019 <- read_excel("data/calvingSeason/Parturience2018-2019.xlsx",sheet="2019",range="A1:AH84")

load(file="pipleine/telemetryData/gpsData/01_createDeployMetadata/deployMetadata.Rdata")

# Format data ----

# Convert date columns to long form
# For 2019, drop 1 bull moose from dataset
calf2018 <- calf2018 %>%
  pivot_longer(cols="11 May 2018":"23 June 2018",names_to="date",values_to="calfStatus")

calf2019 <- calf2019 %>%
  pivot_longer(cols="11 May 2019":"6 June 2019",names_to="date",values_to="calfStatus") %>%
  filter(Notes!="Bull")

# Combine both years into single data frame
calfData <- rbind(calf2018,calf2019)

# Add collar ID using moose ID as a key
calfData <- left_join(calfData,deploy,by=c("Moose_ID"="animal_id"))

# Create boolean calfAlive status
calfData <- calfData %>%
  mutate(calfAlive = case_when(calfStatus > 1 ~ 1,
                               calfStatus <= 1 ~ calfStatus)) %>%
  select(deployment_id,sensor_type,date,calfAlive)

# Convert date to POSIX object
calfData$date <- as.Date(calfData$date,format="%e %B %Y")

#### Export data----

# As.Rdata file rather than .csv because I don't want to deal with reclassifying my dates
save(calfData,file="pipeline/calvingSeason/01_formatData/calfData.Rdata")

# Clean workspace
rm(list=ls())
