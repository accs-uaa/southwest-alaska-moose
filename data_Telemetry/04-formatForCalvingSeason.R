# Objectives: Subset telemetry data to include only calving season. Encode unique moose-Year. Explore sample size to ensure sufficient relocations for each moose-Year. Add boolean calfAlive variable.

# Author: A. Droghini (adroghini@alaska.edu)

#### Load packages and data ----
source("package_TelemetryFormatting/init.R")
load("pipeline/telemetryData/vhfData.Rdata")
load("pipeline/telemetryData/gpsData/03b_cleanLocations/cleanLocations.Rdata")
load(file="pipeline/telemetryData/parturienceData.Rdata")

#### Format telemetry data ----

# Create datetime variable. Exact time of observation in unknown - Set everything to 08:00 and assume relocations on subsequent days were spaced 24 h apart (given flight times and duration, this relocation is ~ 24 hours +/- 4 h)
# Set timezone to UTC to conform with Movebank requirements and to standardize with GPS dataset
# Because all flights were no earlier than mid-morning, AKDT Date = UTC Date (UTC is 8 hours ahead)
vhfData <- vhfData %>%
  dplyr::rename(animal_id = Moose_ID) %>%
  mutate(datetime = as.POSIXct(paste(AKDT_Date, "08:00:00", sep=" "),
         format="%Y-%m-%d %T",
         tz="UTC"))

# Create sensor_type == GPS for GPS data
gpsClean <- gpsClean %>%
  mutate(sensor_type = "GPS", AKDT_Date = as.Date(datetime)) %>%
  dplyr::select(-c(UTC_Date,UTC_Time))

# Combine VHF & GPS data
allData <- plyr::rbind.fill(vhfData,gpsClean)

#### Restrict to calving season ----

# We define the calving season as the period from May 10th to first week of June
# June 4 for 2018, June 6 for 2019
# Based on Kassie's work on the Watana moose population
# End dates are based on end of daily aerial surveys
allData <- allData %>%
  dplyr::filter( (month(AKDT_Date) == 5 & day(AKDT_Date) >= 10) | (year(AKDT_Date) == 2018 & month(AKDT_Date) == 6 & day(AKDT_Date) <= 4) |
                   (year(AKDT_Date) == 2019 & month(AKDT_Date) == 6 & day(AKDT_Date) <= 6) )

# Check if there are any mortality signals- would no longer actively selecting for habitat at that point...
unique(allData$mortalityStatus) # only normal or NA
allData <- dplyr::select(.data=allData,-mortalityStatus)

#### Encode moose-Year ID ----
# Recode deployment_id to include year
# We are treating paths from different calving seasons as independent
allData <- allData %>%
  mutate(mooseYear_id = paste(deployment_id,year(AKDT_Date),sep="."))

# Create RowID variable for sorting
allData <- allData %>%
  group_by(mooseYear_id) %>%
  arrange(datetime,.by_group=TRUE) %>%
  dplyr::mutate(RowID = row_number(datetime)) %>%
  ungroup()

# Calculate number of relocations per moose-year
n <- plyr::count(allData, "mooseYear_id")

n <- left_join(n,allData,by="mooseYear_id") %>%
  filter(!(duplicated(mooseYear_id))) %>%
  dplyr::select(mooseYear_id,freq,sensor_type)

#### Sample size for VHF data ----
# Plot to show sample distribution for VHF data
temp <- n %>% filter(sensor_type=="VHF")
hist(temp$freq,
     main="Number of VHF relocations per moose-year",
     xlab="Number of relocations",
     ylab="Number of moose-years",
     xlim = c(0,20),ylim=c(0,50),
     col="#0072B2",border = "#FFFFFF")

# Very few relocations (< 10 for most individuals)
# Generating random paths for just the few VHF individuals that have enough relocations will be complicated by the inconsistent time intervals between relocations. While doable, we think it will be more worthwhile to keep the VHF data for model validation.

#### Sample size for GPS data ----

# Summary statistics for GPS data
temp <- n %>% filter(sensor_type=="GPS")
summary(temp$freq)

# Minimum length of defined calving season is 26 days for 2018, 28 days for 2019
# A full set of relocation data should have between 312 and 336 relocations (28 days * 12 fixes per day @ 2 hour fix rates)
# Examine moose-Years that have less than ~300 relocations 
n <- as.character(filter(n,sensor_type == "GPS" & freq < 300)$mooseYear_id) 

temp <- allData %>%
  dplyr::filter(mooseYear_id %in% n)

unique(temp$animal_id)

# These three individuals were identified as mortalities in parturience datasheet
# We'll keep these moose in our dataset Since there is still a decent amount of relocations for each (min: 29). 
# All of our variables will be normalized to # of samples.

#### Drop VHF data ----
gpsCalvingSeason <- allData %>%
  dplyr::filter(sensor_type=="GPS")

rm(n,temp)

#### Add boolean parturience variable ----

# Omit sensor_type column from calfData
calfData <- calfData %>% 
  dplyr::select(-sensor_type)

# Join datasets
gpsCalvingSeason <- left_join(gpsCalvingSeason,calfData,by = c("deployment_id", "AKDT_Date"))

#### Explore sample size ----

# How many moose? How many moose-Years?
length(unique(gpsCalvingSeason$deployment_id)) # 24 unique female individuals
length(unique(gpsCalvingSeason$mooseYear_id)) # 42 moose-Year Paths

# Are there some moose-Years for which we have absolutely no calving data? These will have to be dropped from the model.
gpsCalvingSeason %>% mutate(calfNA = case_when(is.na(calfAlive) ~ 2,
                                               !is.na(calfAlive) ~ calfAlive)) %>% 
  group_by(mooseYear_id) %>% 
  distinct(calfNA) %>% 
  pivot_wider(id_cols = mooseYear_id,names_from=calfNA,
              values_from = calfNA,names_prefix="calf") %>% 
  filter(is.na(calf0) & is.na(calf1))
# Some data exist for all 42 moose-Year paths.

# How many moose-Years with calves for at least part of the season?
nrow(gpsCalvingSeason %>% filter(calfAlive=="1") %>% 
       distinct(mooseYear_id)) # 34 moose-Year Paths with calves

#### Export data ----
# Save as .Rdata file
save(gpsCalvingSeason, file="pipeline/telemetryData/gpsData/04-formatForCalvingSeason/gpsCalvingSeason.Rdata")
write_csv(gpsCalvingSeason, "output/telemetryData/cleanedGPSCalvingSeason.csv")
rm(list = ls())