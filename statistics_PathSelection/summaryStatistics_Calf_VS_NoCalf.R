# Obj: Calculate summary statistics (median and standard deviation) for observed paths a) with calves and b) without calves. Display results as a table to include in manuscript.

# Author: A. Droghini (adroghini@alaska.edu)

rm(list=ls())

# Define Git directory ----
git_dir <- "C:/ACCS_Work/GitHub/southwest-alaska-moose/package_Statistics/"

#### Load packages and data ----
source(paste0(git_dir,"init.R"))

# Load data
calf <- read_csv(file=paste(pipeline_dir,
                            "01-dataPrepForAnalyses",
                            "allPaths_calves.csv",
                            sep="/"))

no_calf <- read_csv(file=paste(pipeline_dir,
                               "01-dataPrepForAnalyses",
                               "allPaths_no_calves.csv",
                               sep="/"))

# Define output csv
output_csv <- paste(output_dir,"pathSelectionFunction","summary_calf_vs_no_calf.csv",sep="/")

#### Define function ----

# Wrapper function to calculate median and SD to use in sapply
# Round to 2 decimal places
summary_function <- function(x){
  list(round(median(x),digits=2),round(sd(x),digits=2))
}

#### Format data ----

# Include observed paths only
# Only include variables that are in the explanatory model
calf <- calf %>% 
  filter(response == 1) %>%
  dplyr::select(mooseYear_id,calfStatus,elevation_mean, roughness_mean,forest_edge_mean,tundra_edge_mean,alnus_mean,salshr_mean)

no_calf <- no_calf %>% 
  filter(response == 1) %>%
  dplyr::select(mooseYear_id,calfStatus,elevation_mean, roughness_mean,forest_edge_mean,tundra_edge_mean,alnus_mean,salshr_mean)

#### Summarize data ----

# Calculate summary statistics for paths with calves
calf_summary <- as.data.frame(sapply(calf[,3:8],FUN=summary_function))

calf_summary <- calf_summary %>% 
  mutate(statistic = c("median_calf","st_dev_calf")) %>% 
  pivot_longer(cols = c(1:6)) %>% 
  pivot_wider(names_from = "statistic")

# Without calves
no_calf_summary <- as.data.frame(sapply(no_calf[,3:8],FUN=summary_function))

no_calf_summary <- no_calf_summary %>% 
  mutate(statistic = c("median_no_calf","st_dev_no_calf")) %>% 
  pivot_longer(cols = c(1:6)) %>% 
  pivot_wider(names_from = "statistic")

# Join data frames to produce summary table
summary_table <- left_join(calf_summary,no_calf_summary,by="name")

# Final formatting ----

summary_table <- summary_table %>% 
  dplyr::rename(Variable = name) %>% 
  dplyr::mutate(Units = c("Meters","Meters","Meters","Meters","Percent foliar cover","Percent foliar cover"),
                median_calf = as.numeric(median_calf),
                st_dev_calf = as.numeric(st_dev_calf),
                median_no_calf = as.numeric(median_no_calf),
                st_dev_no_calf = as.numeric(st_dev_no_calf)) %>% 
  dplyr::select(Variable,Units,everything())
  
# Relabel variables
summary_table$Variable <- summary_table$Variable %>% 
  sub(pattern="_mean",replacement="") %>% 
  sub(pattern="_edge",replacement=" Edge") %>% 
  sub(pattern="salshr",replacement="Salix Shrub") %>% 
  str_to_title() 

# Export table
# Perform final formatting in Excel
write_csv(summary_table,file=output_csv)

# Empty workspace
rm(list=ls())