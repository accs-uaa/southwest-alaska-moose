# -*- coding: utf-8 -*-
# ---------------------------------------------------------------------------
# Merge extracted grids
# Author: Timm Nawrocki
# Last Updated: 2021-06-26
# Usage: Must be executed in R 4.0.0+.
# Description: "Merge extracted grids" merges the primary extraction data with the updated tundra edge data.
# ---------------------------------------------------------------------------

# Set root directory
root_folder = 'N:/ACCS_Work/Projects/WildlifeEcology/Moose_SouthwestAlaska/Data'

# Define input grids
original_folder = paste(root_folder,
                        'Data_Output/extracted_grids',
                        sep ='/')
tundra_folder = paste(root_folder,
                      'Data_Output/extracted_grids_tundra',
                      sep = '/')

# Define output folder
output_folder = paste(root_folder,
                      'Data_Output/extracted_grids_merge',
                      sep = '/')

# Import required libraries for geospatial processing: dplyr, stringr, tidyr.
library(dplyr)
library(stringr)
library(tidyr)

# Define input grid list
grids_list = list.files(path = original_folder, pattern = 'csv', full.names = FALSE)

# Loop through grids and merge original with updated tundra data
for (grid in grids_list) {
  # Define grid files
  original_grid = paste(original_folder,
                        grid,
                        sep = '/')
  tundra_grid = paste(tundra_folder,
                      grid,
                      sep = '/')
  output_grid = paste(output_folder,
                      grid,
                      sep = '/')
  
  # Import grid files to tables
  original_data = read.csv(original_grid, encoding = 'UTF-8')
  tundra_data = read.csv(tundra_grid, encoding = 'UTF-8')
  
  # Prepare tundra data for merge
  tundra_data = tundra_data %>%
    mutate(join_name = paste(x, y, sep = '_')) %>%
    select(-X, -x, -y)
  
  # Prepare original data for merge
  original_data = original_data %>%
    mutate(join_name = paste(x, y, sep = '_')) %>%
    select(-X, -tundra_edge)
  
  # Join original data to tundra edge
  merged_data = original_data %>%
    left_join(tundra_data, by = 'join_name') %>%
    select(-join_name)
  
  # Export data as a csv
  write.csv(merged_data, file = output_grid, fileEncoding = 'UTF-8')
  print(paste('Finished extracting data to Grid ', grid, '.', sep = ''))
  print('----------')
}
