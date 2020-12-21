# Objectives: Subset telemetry data to include only calving season. Add boolean calfAtHeel variable and create unique ID for each moose-Year-calfAtHeel combination. Explore sample size to ensure sufficient relocations for each moose-Year. 

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
# End dates are based on end of daily aerial surveys. Some observations were made two weeks later (~23 June) - we don't want to include those.
allData <- allData %>%
  dplyr::filter( (month(AKDT_Date) == 5 & day(AKDT_Date) >= 10) | (year(AKDT_Date) == 2018 & month(AKDT_Date) == 6 & day(AKDT_Date) <= 4) |
                   (year(AKDT_Date) == 2019 & month(AKDT_Date) == 6 & day(AKDT_Date) <= 6) )

# Check if there are any mortality signals- would no longer actively selecting for habitat at that point...
unique(allData$mortalityStatus) # only normal or NA
allData <- dplyr::select(.data=allData,-mortalityStatus)

#### Add boolean parturience variable ----

# Omit sensor_type column from calfData
calfData <- calfData %>% 
  dplyr::select(-sensor_type)

# Join datasets
calvingSeason <- left_join(allData,calfData,by = c("deployment_id", "AKDT_Date"))

# Drop observations that do not have a calfAtHeel status
calvingSeason <- calvingSeason %>% 
  dplyr::filter(!is.na(calfAtHeel))

#### Encode moose-Year-calf ID ----
# Recode deployment_id to include year and calfAtHeel status
# We are treating paths from different calving seasons as independent
calvingSeason <- calvingSeason %>%
  mutate(mooseYear_id = paste(deployment_id,year(AKDT_Date),paste0("calf",calfAtHeel),sep="."))

# Create RowID variable for sorting
calvingSeason <- calvingSeason %>%
  group_by(mooseYear_id) %>%
  arrange(datetime,.by_group=TRUE) %>%
  dplyr::mutate(RowID = row_number(datetime)) %>%
  ungroup()

#### Explore sample size ----

# Calculate number of relocations per moose-year
n <- plyr::count(calvingSeason, "mooseYear_id")

n <- left_join(n,calvingSeason,by="mooseYear_id") %>%
  filter(!(duplicated(mooseYear_id))) %>%
  dplyr::select(mooseYear_id,freq,sensor_type)

# For VHF data ----
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

#### Drop VHF data ----
gpsCalvingSeason <- calvingSeason %>%
  dplyr::filter(sensor_type=="GPS")

rm(n,temp)

#### Sample size for GPS data ----

# Summary statistics for GPS data
temp <- n %>% filter(sensor_type=="GPS")
summary(temp$freq)

# Minimum number of points per path is 4. How many have less than 30 relocations?
n <- as.character(filter(n,sensor_type == "GPS" & freq < 30)$mooseYear_id) 

temp <- gpsCalvingSeason %>%
  dplyr::filter(mooseYear_id %in% n)

unique(temp$animal_id) # 8 individuals

# All of our variables will be normalized to # of samples.

# How many moose? How many moose-Years?
length(unique(gpsCalvingSeason$deployment_id)) # 24 unique female individuals
length(unique(gpsCalvingSeason$mooseYear_id)) # 59 moose-Year-calf Paths

# How many moose-Years with calves for at least part of the season?
nrow(gpsCalvingSeason %>% filter(calfAtHeel=="1") %>% 
       distinct(mooseYear_id)) # 34 moose-Year Paths with calves

#### Export data ----
# Save as .Rdata file
save(gpsCalvingSeason, file="pipeline/telemetryData/gpsData/04-formatForCalvingSeason/gpsCalvingSeason.Rdata")
write_csv(gpsCalvingSeason, "output/telemetryData/cleanedGPSCalvingSeason.csv")
rm(list = ls())