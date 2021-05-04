# Objectives: Subset telemetry data to include only calving season. Add boolean calfStatus variable and create unique ID for each moose-Year-calfStatus combination. Explore sample size to ensure sufficient relocations for each moose-Year.

# Notes: 
# 1) We define the calving season as the period from May 10th to first week of June
# Based on Kassie's work on the Watana moose population and available data from aerial surveys.
# End dates of daily aerial surveys: June 4 for 2018, June 6 for 2019, 31 May for 2020.
# 2) VHF individuals had very few relocations during the calving season (57% of moose-year-calves had fewer than 5 relocs). In addition, generating random paths will be complicated by the inconsistent time intervals between relocations (not daily). We think it will be more worthwhile to keep the VHF data for model validation and do not include VHF individuals in this script.

# Author: A. Droghini (adroghini@alaska.edu)

rm(list = ls())

# Define Git directory ----
git_dir <- "C:/Work/GitHub/southwest-alaska-moose/package_TelemetryFormatting/"

#### Load packages and functions ----
source(paste0(git_dir,"init.R"))

#### data -----
load(file=paste0(pipeline_dir,"03b_cleanLocations/","cleanLocations.Rdata"))
load(file=paste0(pipeline_dir,"01-formatParturienceVariable/","parturienceData.Rdata"))

#### Format telemetry data ----

# Restrict to calving season
gpsClean <- gpsClean %>%
  mutate(AKDT_Date = as.Date(datetime))

#### Add boolean parturience variable ----

# Omit sensor_type column from calfData
calfData <- calfData %>%
  dplyr::select(-sensor_type)

# Join datasets
gpsClean <- left_join(gpsClean,calfData,by = c("deployment_id", "AKDT_Date"))

# Drop observations that do not have a calf status associated with it
calvingSeason <- gpsClean %>% 
  dplyr::filter(!is.na(calfStatus))

# Quick plot check - use one season as test
calvingSeason %>% 
  dplyr::filter(year(AKDT_Date) == 2018) %>% 
  ggplot(aes(AKDT_Date,calfStatus)) + 
  geom_point() +
  scale_x_date(date_breaks = ("4 days")) +
  theme_bw()

# Check if there are any mortality signals- would no longer actively selecting for habitat at that point...
unique(calvingSeason$mortalityStatus) # only normal or NA
calvingSeason <- dplyr::select(.data=calvingSeason,-mortalityStatus)

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

# 24 unique female individuals
length(unique(calvingSeason$deployment_id)) 

# Sampling unit is the path = moose x year x calf 
# Total of 80 paths
# 49 paths with calves, 31 without
length(unique(calvingSeason$mooseYear_id)) 
nrow(calvingSeason %>% filter(calfStatus=="1") %>% 
       distinct(mooseYear_id))

# Number of locations per path ranges from 12 to 324
# 12 paths have fewer than 30 relocations
n <- plyr::count(calvingSeason, "mooseYear_id")
nrow(n) 
summary(n$freq)
nrow(n %>% dplyr::filter(freq < 30)) 

# Determine average time between relocations across paths
# Median & mean time interval: 2 hours
# Minimum: 1.96 h
# Maximum: 4 h
gpsMove <- move::move(x=calvingSeason$Easting,y=calvingSeason$Northing,
                      time=calvingSeason$datetime,
                      data=calvingSeason,proj=CRS("+init=epsg:3338"),
                      animal=calvingSeason$mooseYear_id, sensor="gps")

timeLag <- unlist(lapply(timeLag(gpsMove, units='hours'),  c, NA))
summary(timeLag)

#### Export data ----
# Save as .Rdata file
save(calvingSeason, file=paste0(pipeline_dir,
                                "04-formatForCalvingSeason/",
                                "gpsCalvingSeason.Rdata"))

write_csv(calvingSeason, file=paste0(output_dir,
                                     "animalData/",
                                     "cleanedGPSCalvingSeason.csv"))
rm(list = ls())