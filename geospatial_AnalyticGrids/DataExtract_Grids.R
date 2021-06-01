# -*- coding: utf-8 -*-
# ---------------------------------------------------------------------------
# Extract Covariates to Grids
# Author: Timm Nawrocki
# Last Updated: 2020-11-30
# Usage: Must be executed in R 4.0.0+.
# Description: "Extract Covariates to Grids" extracts data from rasters to prediction grids.
# ---------------------------------------------------------------------------

# Set root directory
root_folder = 'N:/ACCS_Work/Projects/WildlifeEcology/Moose_SouthwestAlaska/Data'

# Define input grid list
grid_file = paste(root_folder,
                 'Data_Input/grids/gridMinor_selected.xlsx',
                 sep ='/')

# Define input folders
grid_folder = 'N:/ACCS_Work/Data/analyses/gridMinor'
topography_folder = paste(root_folder,
                          'Data_Input/topography',
                          sep = '/')
edge_folder = paste(root_folder,
                         'Data_Input/edge_distance',
                         sep = '/')
vegetation_folder = paste(root_folder,
                         'Data_Input/vegetation',
                         sep = '/')
output_folder = paste(root_folder,
                      'Data_Output/extracted_grids',
                      sep = '/')

# Install required libraries if they are not already installed.
Required_Packages <- c('dplyr', 'raster', 'rgdal', 'sp', 'stringr')
New_Packages <- Required_Packages[!(Required_Packages %in% installed.packages()[,"Package"])]
if (length(New_Packages) > 0) {
  install.packages(New_Packages)
}
# Import required libraries for geospatial processing: dplyr, raster, rgdal, sp, and stringr.
library(dplyr)
library(raster)
library(readxl)
library(rgdal)
library(sp)
library(stringr)

# Define input grid list
grid_table = read_xlsx(grid_file, sheet = 'minor_grids')
grid_list = pull(grid_table, var = 'Minor')
grid_length = length(grid_list)

# Create a list of all predictor rasters
predictors_topography = list.files(topography_folder, pattern = 'tif$', full.names = TRUE)
predictors_edge = list.files(edge_folder, pattern = 'tif$', full.names = TRUE)
predictors_vegetation = list.files(vegetation_folder, pattern = 'tif$', full.names = TRUE)
predictors_all = c(predictors_topography,
                   predictors_edge,
                   predictors_vegetation)
print(paste('Number of predictor rasters: ', length(predictors_all), sep = ''))

# Generate a stack of all predictor rasters
print('Creating raster stack...')
start = proc.time()
predictor_stack = stack(predictors_all)
end = proc.time() - start
print(end[3])

# Loop through all grids with site data and extract covariates to sites
count = 1
for (grid in grid_list) {

  # Define output csv file
  output_csv = paste(output_folder, '/', grid, '.csv', sep = '')

  # If output csv file does not already exist, extract covariates to grid
  if (!file.exists(output_csv)) {
    print(paste('Extracting predictor data to Grid ', grid, ' (', count, ' of ', grid_length, ')...', sep=''))

    # Create full path to grid raster
    grid_file = paste(grid_folder, '/', 'Grid_', grid, '.tif', sep = '')

    # Convert raster to spatial dataframe of points
    grid_raster = raster(grid_file)
    grid_points = data.frame(rasterToPoints(grid_raster, spatial=FALSE))
    grid_points = grid_points[,1:2]

    # Read site data and extract covariates
    print('Extracting covariates...')
    start = proc.time()
    grid_extracted = data.frame(grid_points, extract(predictor_stack, grid_points))
    end = proc.time() - start
    print(end[3])

    # Find plot level mean values and convert field names to standard
    grid_extracted = grid_extracted %>%
      rename(forest_edge = southwestAlaska_ForestEdge) %>%
      rename(tundra_edge = southwestAlaska_TussockTundraEdge)

    # Export data as a csv
    write.csv(grid_extracted, file = output_csv, fileEncoding = 'UTF-8')
    print(paste('Finished extracting data to Grid ', grid, '.', sep = ''))
    print('----------')
  } else {
    print(paste('File for Grid ', grid, ' already exists.', sep = ''))
    print('----------')
  }

  # Increase the count by one
  count = count + 1
}
