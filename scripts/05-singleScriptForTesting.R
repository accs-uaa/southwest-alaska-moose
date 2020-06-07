# This script is used for testing purposes. It combines several processes so that it can quickly be executed. 

# We determined migration patterns of moose by looking at animated movement paths (in Google Earth) and MSD/NSD plots. We used these methods to inform cut-off dates of seasonal home ranges for migratory moose. For resident (or what we thought were resident) moose, we started by plotting annual home ranges, starting with the date of collar deployment. Once we had tentative start/end dates for seasonal or annual home ranges, we ran through this script and looked at the resulting variograms to assess stationarity. If an asymptote was not reached, we went back to the drawing board-- Did we need to change start/end date? This was an iterative, manual process. Once we had satisfactory variograms, we fitted our data to hypothetical movement models and selected the top-ranked model using models and functions in the ctmm package.

#### Load packages and data----
rm(list=ls())
# source("scripts/init.R")
load("pipeline/03b_cleanLocations/cleanLocations.Rdata")
load("pipeline/02b_calibrateData/uereModel.Rdata") # calibration data
source("scripts/function-plotVariograms.R") # calls varioPlot function

migDates <- read_excel(path= "output/migrationDates.xlsx",sheet = "newAttempts")

#### Split data according to start/end dates----

newids <- paste(migDates$deployment_id,migDates$year,migDates$season,sep="_")

ids <- migDates$deployment_id

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
                do(tail(., n=1))) %>% 
  arrange(newid)

temp$type = rep(x=c("start","end"),length.out=(nrow(temp)))

temp <- temp %>% pivot_wider(id_cols=newid, names_from=type,values_from = UTC_Date)

View(temp)

#### Calibration data----

# Convert to telemetry object----
# Use newid instead of deployment_id to map separate home ranges for the same individual
# Should I be using UTM coordinates (Easting and Northing) instead??
calibratedData <- seasonalData %>% 
  dplyr::select(latY,longX,
                DOP,FixType,datetime,newid) %>% 
  rename(longitude = longX, latitude = latY, 
         class = FixType,animal_id = newid)

calibratedData <- ctmm::as.telemetry(calibratedData,timezone="UTC",projection=CRS("+init=epsg:32604"))

# Plot tracks
plot(calibratedData,col=rainbow(length(calibratedData)))

# Calibrate data ----
uere(calibratedData) <- calibModel
names(calibratedData[[1]]) # VAR.xy column appears

#### Plot variograms ----

varioPlot(calibratedData,
          filePath=paste("pipeline/05c_ctmmModelSelection/temp/variograms/",Sys.Date(),"/",sep=""),zoom = FALSE)

dev.off()