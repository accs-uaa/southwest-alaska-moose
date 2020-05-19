# Objective: For each moose ID, split telemetry data by migration start/end dates to map seasonal home ranges. 

# Start/end dates were determined by examining Mean Squared Displacement, animated movement paths, variograms, and Net Squared Displacement (the latter using the Wyoming Migration Initiative's Migration Mapper: https://migrationinitiative.org/content/migration-mapper). Start/end dates for every ID and season of interest were entered in an Excel datasheet (migrationDates.xlsx).

# Author: A. Droghini (adroghini@alaska.edu)
#         Alaska Center for Conservation Science

#### Load packages and data----
rm(list=ls())
source("scripts/init.R")
load("pipeline/03b_cleanLocations/cleanLocations.Rdata")
migDates <- read_excel(path= "data/migrationDates.xlsx")

#### Split data according to start/end dates----

# Modified from François Guillem's code: https://github.com/tidyverse/dplyr/issues/3936

# Requires the following inputs:

# newids: Unique identifier for each id-year-season.
newids <- paste(migDates$deployment_id,migDates$year,migDates$season,sep="_")

# ids: Vector of moose deployment IDs. The "cases" list must have the same length as newids, so each ID needs to be replicated for as many years and seasons that we are modeling (probably not an absolute, but that's the way I got the function to work).
ids <- migDates$deployment_id

# Start and end dates of each id-year-season.
start <- migDates$start
end <- migDates$end

# Create a list of patterns to be evaluated by case_when
# Essentially the same as writing n case_when arguments: deployment_id == migDate$id[n] & datetime >= migDate$start[n] ... etc.

cases <- lapply(seq_along(newids), function(i) {
  substitute(deployment_id == ids[i] & as_date(datetime) >= start[i] & as_date(datetime) <= end[i] ~ newids[i], list(i = i))
}
)

# Append an additional argument: if there is no pattern match e.g. date falls outside season cut-offs, id is not included in migrationDates table, then newid = "NA"
# Allows for easy exclusion
cases <- append(cases, substitute(FALSE ~ "NA"))

# Apply to telemetry dataset
# Use big-bang operator (!!!): https://rlang.r-lib.org/reference/nse-force.html to splice the 'cases' list into individual arguments that can be evaluated by case_when
# Exclude everything for which newid == NA (no match in migDates dataset)
# What a beauty of a solution though: https://www.youtube.com/watch?v=oL7XdoS5Je4
seasonalData <- gpsClean %>% 
  mutate(newid = case_when(!!!cases)) %>% 
  filter(!is.na(newid))

unique(seasonalData$newid)

# Check
temp <- seasonalData %>% group_by(newid) %>% 
  dplyr::select(newid,UTC_Date) %>% 
  do(head(., n=1))

temp <- rbind(temp,seasonalData %>% group_by(newid) %>% 
  dplyr::select(newid,UTC_Date) %>% 
  do(tail(., n=1)))

temp <- temp %>% arrange(newid)

#### Export seasonal telemetry data----
save(seasonalData,file="pipeline/05a_splitByMigrationDates/seasonalData.Rdata")

rm(list=ls())