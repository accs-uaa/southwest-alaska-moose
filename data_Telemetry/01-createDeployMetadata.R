# Objective: Create a deployment data file that conforms to Movebank data standards. Identify and rename duplicate IDs (signifying collar redeployments) so that each animal ID is unique.

# Movebank Attribute Dictionary: https://www.movebank.org/cms/movebank-content/movebank-attribute-dictionary

# Last updated: 11 Mar 2020

# Author: A. Droghini (adroghini@alaska.edu)
#         Alaska Center for Conservation Science

#### Load libraries and data ----
# dbo_CollarDeployment.xlsx is an export from Access DB table
source("package_TelemetryFormatting/init.R")
deploy <- readxl::read_xlsx("D:/sw_ak_moose/data/dbo_CollarDeployment.xlsx")

names(deploy)
summary(deploy)

#### Format data ----
# Add, rename, and transform columns to conform to Movebank attributes
# Use _ instead of - because R doesn't like dashes

# Add sensor_type column to differentiate between GPS, VHF, and visual only. Add animal_taxon column.

# Split Collar_Deployment_Notes into animal_comments and deployment_end_comments depending on nature of comments.
# Add deployment_end_type: if Notes indicate Mortality, code as "dead", otherwise NA.

# Animal ID should be unique for each individual-- probably Moose ID column
# Tag ID refers to the collar ID and is not necessarily unique across individuals- Collar_Serial
# Need to create a Deployment ID that uniquely identifies tags that have been redeployed on different animals. This is achieved by the code chunk that starts with group_by() and ends at ungroup(). If length of Collar_Serial group > 1, add letter suffixes "a", "b" to the existing Collar_Serial number. For all Collar_Serials, add an "M" so that the column does not get read as numeric during export/import.

# Drop extraneous columns: "Collar_Deployment_ID","Collar_Deployment_Notes","Collar_Serial"
deploy <- deploy %>%
  mutate("sensor_type" = case_when(
    startsWith(Collar_Serial,"3") ~ "GPS",
    startsWith(Collar_Serial,"6") ~ "VHF",
    TRUE ~ "none"),
    "animal_comments" = case_when(
      grepl("Oppertunistic",Collar_Deployment_Notes) ~ "Opportunistic Seen",
      TRUE ~ NA_character_),
    "deployment_end_comments" = case_when(
      grepl("Recovered",Collar_Deployment_Notes) ~ Collar_Deployment_Notes,
      TRUE ~ NA_character_),
    "deployment_end_type" =   case_when(
      grepl("Mort",Collar_Deployment_Notes) ~ "dead",
      TRUE ~ NA_character_)) %>%
  dplyr::rename("animal_id" = "Moose_ID",
         "deploy_on_timestamp"= Deployment_Start, "deploy_off_timestamp" = Deployment_End,
         "ring_id" = Collar_Visual,"tag_comments" = Collar_Status,
         "tag_id" = Collar_Serial) %>%
  group_by(tag_id) %>%
  dplyr::mutate(id = row_number()) %>%
  add_tally() %>%
  mutate(deployment_id = case_when(
    n > 1 ~ paste0("M",tag_id,sapply(id, function(i) letters[i]),sep=""),
    TRUE ~ paste0("M",tag_id,sep=""))) %>%
  ungroup() %>%
  select("animal_id","deployment_id","tag_id","sensor_type","deploy_on_timestamp",
         "deploy_off_timestamp","tag_comments","ring_id",
         "animal_comments","deployment_end_type","deployment_end_comments") %>%
  add_column("animal_taxon" = "Alces alces", .before= 1) %>%
  arrange(deployment_id)

#### QA/QC
# Check that timestamps are correctly interpreted
str(deploy)

# Quick summary- how many collars do we have?
deploy %>%
  filter(sensor_type != "none") %>%
  group_by(sensor_type) %>%
  summarize(animals = length(sensor_type),
            startDate = min(deploy_on_timestamp))

unique(deploy$deployment_id)

#### Export data ----
# Export as .Rdata file
save(deploy, file="pipleine/telemetryData/gpsData/01_createDeployMetadata/deployMetadata.Rdata")

# Export as .csv for Movebank upload
# Movebank throws errors when certain columns are coded as NA
# Set "NA" to blanks
# Also get rid of visual only observations
deployMovebank <- deploy %>%
  filter(sensor_type != "none")
write.csv(deployMovebank,"output/deployMetadataMovebank.csv",row.names=FALSE,na="")

# Clean up workspace
rm(deploy,deployMovebank)
