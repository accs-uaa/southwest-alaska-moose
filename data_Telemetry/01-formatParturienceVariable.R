# Objective: For every cow, create a variable "Boolean Parturience" that tracks the survival of calves during calving season. This variable will be used to develop separate models for a) females with calf-at-heel (birthing sites) and b) females without calves. For now, we treat twins or triplets as single boolean Calf-At-Heel. If one calf of a twin set dies, then the cow remains in Calf-At-Heel (1) status. We may add a variable of # of calves in the future.

# We drop observations of pregnant cows that have not yet given birth. These observations were originally coded as 0s, but we recoded them as 3s in MS Excel to make it easy to drop them here. The reason we drop them is because we do not want to conflate the movement patterns/vegetation selection of females on their way to birthing site to females with calf-at-heel (if coded as 1) or to females with dead/no calf (at or on their way to foraging sites).

# Author: A. Droghini (adroghini@alaska.edu)

# Load packages and data----
source("package_TelemetryFormatting/init.R")

calf2018 <- read_excel("data/calvingSeason/Parturience2018-2020.xlsx",
                       sheet="2018_noLeadingZeroes",range="A1:AG67")
calf2019 <- read_excel("data/calvingSeason/Parturience2018-2020.xlsx",
                       sheet="2019_noLeadingZeroes",range="A1:AH84")
calf2020 <- read_excel("data/calvingSeason/Parturience2018-2020.xlsx",
                       sheet="2020_noLeadingZeroes",range="A1:U84")

load(file="pipeline/telemetryData/gpsData/01_createDeployMetadata/deployMetadata.Rdata")

# Format data ----

# Convert date columns to long form
calf2018 <- calf2018 %>%
  pivot_longer(cols="11 May 2018":"23 June 2018",names_to="AKDT_Date",
               values_to="calfStatus")

calf2019 <- calf2019 %>%
  pivot_longer(cols="11 May 2019":"6 June 2019",names_to="AKDT_Date",
               values_to="calfStatus")

calf2020 <- calf2020 %>%
  pivot_longer(cols=2:21,names_to="AKDT_Date",
               values_to="calfStatus")

# Combine all years into single data frame
calfData <- plyr::rbind.fill(calf2018,calf2019,calf2020)

# Add collar ID using moose ID as a key
calfData <- left_join(calfData,deploy,by=c("Moose_ID"="animal_id"))

# Create boolean calf status
# Recode observations that are coded as "3" (cow pregnant, calf not yet born) to "-999"
# -999 can also mean unobserved, but in the context of this analysis those two situations are functionally the same
# Recode "2" (twins) as 1. Not differentiating between twins and single calves in this analysis.
# Drop "M1719H03" - this is a bull moose that isn't included in our deployment dataset
calfData <- calfData %>%
  mutate(calfStatus = case_when(calfStatus == 3 ~ -999,
                                calfStatus == 2 ~ 1,
                               calfStatus <= 1 ~ calfStatus),
         AKDT_Date = as.Date(calfData$AKDT_Date,format="%e %B %Y")) %>%
  dplyr::filter(Moose_ID != "M1719H03") %>% 
  dplyr::select(deployment_id,sensor_type,AKDT_Date,calfStatus)

### QA/QC ----
unique(calfData$calfStatus)
unique(calfData$deployment_id)
length(unique(subset(calfData,sensor_type=="GPS")$deployment_id)) # 24
length(unique(subset(calfData,sensor_type=="VHF")$deployment_id)) #55

#### Export data ----
# As .csv file for data sharing
write_csv(calfData, "output/telemetryData/parturienceData.csv")

# As.Rdata file to use in subsequent scripts because I don't want to deal with reclassifying my dates
save(calfData,file="pipeline/telemetryData/parturienceData.Rdata")

# Clean workspace
rm(list=ls())