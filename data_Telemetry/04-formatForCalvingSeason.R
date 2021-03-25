# Objectives: Subset telemetry data to include only calving season. Add boolean calfStatus variable and create unique ID for each moose-Year-calfStatus combination. Explore sample size to ensure sufficient relocations for each moose-Year.

# Notes: 
# 1) We define the calving season as the period from May 10th to first week of June
# Based on Kassie's work on the Watana moose population and available data from aerial surveys.
# End dates of daily aerial surveys: June 4 for 2018, June 6 for 2019, 31 May for 2020.
# 2) VHF individuals had very few relocations during the calving season (57% of moose-year-calves had fewer than 5 relocs). In addition, generating random paths will be complicated by the inconsistent time intervals between relocations (not daily). We think it will be more worthwhile to keep the VHF data for model validation and do not include VHF individuals in this script.

# Author: A. Droghini (adroghini@alaska.edu)

#### Load packages and data ----
source("package_TelemetryFormatting/init.R")
load("pipeline/telemetryData/gpsData/03b_cleanLocations/cleanLocations.Rdata")
load(file="pipeline/telemetryData/parturienceData.Rdata")

#### Format telemetry data ----

# Restrict to calving season
# Create date column to merge with parturience data, which does not have a timestamp
gpsClean <- gpsClean %>%
  mutate(AKDT_Date = as.Date(datetime)) %>%
  dplyr::select(-c(UTC_Date,UTC_Time)) %>%
  dplyr::filter( (month(AKDT_Date) == 5 & 
                    day(AKDT_Date) >= 10) | 
                   (year(AKDT_Date) == 2018 
                    & month(AKDT_Date) == 6 
                    & day(AKDT_Date) <= 4) |
                   (year(AKDT_Date) == 2019 
                    & month(AKDT_Date) == 6 
                    & day(AKDT_Date) <= 6))

# Check that the filtering worked
summary(gpsClean$AKDT_Date)
unique(gpsClean$AKDT_Date)

# Check if there are any mortality signals- would no longer actively selecting for habitat at that point...
unique(gpsClean$mortalityStatus) # only normal or NA
gpsClean <- dplyr::select(.data=gpsClean,-mortalityStatus)

#### Add boolean parturience variable ----

# Omit sensor_type column from calfData
calfData <- calfData %>%
  dplyr::select(-sensor_type)

# Join datasets
calvingSeason <- left_join(gpsClean,calfData,by = c("deployment_id", "AKDT_Date"))

# Drop observations that do not have a calf status associated with it (either coded as -999 or NA)
calvingSeason <- calvingSeason %>% 
  dplyr::filter(!(is.na(calfStatus) | calfStatus == -999))

#### Encode moose-Year-calf ID ----
# Recode deployment_id to include year and calf status
# We are treating paths from different calving seasons as independent
calvingSeason <- calvingSeason %>%
  mutate(mooseYear_id = paste(deployment_id,year(AKDT_Date),
                              paste0("calf",calfStatus),sep="_"))

# Create RowID variable for sorting
calvingSeason <- calvingSeason %>%
  group_by(mooseYear_id) %>%
  arrange(datetime,.by_group=TRUE) %>%
  dplyr::mutate(RowID = row_number(datetime)) %>%
  ungroup()

#### Explore sample size ----

# Calculate number of relocations per moose-year
n <- plyr::count(calvingSeason, "mooseYear_id")

summary(n$freq)

# Minimum number of points per path is 4. How many have less than 30 relocations?
nrow(n %>% dplyr::filter(freq < 30)) # 13 moose-year-calf paths

# All of our variables will be normalized to # of samples.

# How many moose? How many moose-Years?
length(unique(calvingSeason$deployment_id)) # 24 unique female individuals
length(unique(calvingSeason$mooseYear_id)) # 82 moose-year-calf paths

# How many moose-years with calves for at least part of the season?
nrow(calvingSeason %>% filter(calfStatus=="1") %>% 
       distinct(mooseYear_id)) # 49 paths with calves

#### Export data ----
# Save as .Rdata file
save(calvingSeason, file="pipeline/telemetryData/gpsData/04-formatForCalvingSeason/gpsCalvingSeason.Rdata")
write_csv(calvingSeason, "output/telemetryData/cleanedGPSCalvingSeason.csv")
rm(list = ls())