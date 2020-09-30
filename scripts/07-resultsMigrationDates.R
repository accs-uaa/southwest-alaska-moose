# Objectives: Describe earliest and latest dates of migration initiation. The idea is to create a table that is similar to Table 10 in Ballard et al. 1991

# Ballard WB, Whitman JS, Reed DJ. 1991. Population dynamics of moose in south-central Alaska. Wildlife Monographs 114:3–49.

# Load data and packages ----
rm(list=ls())
source("scripts/init.R")
migDates <- read_excel(path= "output/topModels_annotated.xlsx",sheet = "models to include")
deployDates <- read_csv("output/deployMetadataMovebank.csv")

# length(unique(migDates$modelName)) # should be 34

# Format  data ----

# Issues to address:

# 1. In some cases, we had to excluded certain dates within a season because movements were atypical and throwing off the rest of the variogram (the individual later resumed normal behavior). This was restricted to dates in Sep when the individual was on its summer home range. I assume the atypical movements are in response to the fall rut. Anyway! Because of the way we chose to break up the dates, we end up having two entries for the same ID-season-year. We need to collapse these into a single entry so we can proceed with summarizing the data in the next step.

# 2. In future iterations, I'll need to modify my naming convention. y1 / y2 in the model names doesn't refer to a specific year. For individuals that were collared in 2019 and thus have only one year of data, I ended up referring to them as "y1".

# Figure out which individuals had collars deployed in 2019 and for which "y1" should be 2019

deploy2019 <- deployDates %>% 
  filter(sensor_type == "GPS" & year(deploy_on_timestamp) == 2019) %>% 
  mutate(realYear = 2019) %>% 
  dplyr::select(deployment_id,realYear)

migDates <- left_join(migDates,deploy2019,by="deployment_id")

migDates <- migDates %>%
  mutate(
    realYear = case_when(
      season == "winter" & grepl(pattern = "y1", x = modelName) ~ "2018",
      season == "winter" &
        grepl(pattern = "y2", x = modelName) ~ "2019",
      is.na(realYear) ~ word(
        string = start,
        start = 1,
        sep = "-"
      ),
      TRUE ~ "2019"
    )
  ) %>% 
  dplyr::select(deployment_id,modelName,realYear,season, start,end)

rm(deployDates,deploy2019)

# Summarize data ----
# Exclude resident individuals, since it doesn't make sense to speak of earliest arrival/departure time for annual home ranges.
datesUnique <- migDates %>% filter(season!="annual") %>% 
  dplyr::group_by(modelName) %>% 
  dplyr::summarize(arrival = min(start),departure=max(end))

migDates <- migDates %>% 
  dplyr::select(modelName,season,realYear) %>% 
  distinct(modelName,.keep_all=TRUE)

datesUnique <- left_join(datesUnique,migDates, by="modelName",keep=FALSE)

migTable <- datesUnique %>% 
  dplyr::group_by(realYear,season) %>% 
  dplyr::summarize(earliest.arrival = min(arrival),latest.arrival=max(arrival),
                   earliest.dep = min(departure),latest.dep=max(departure),n=length(arrival))