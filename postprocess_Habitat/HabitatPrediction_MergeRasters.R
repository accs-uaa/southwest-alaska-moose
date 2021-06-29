# -*- coding: utf-8 -*-
# ---------------------------------------------------------------------------
# Merge Predicted Rasters
# Author: Timm Nawrocki, Alaska Center for Conservation Science
# Last Updated: 2021-03-30
# Usage: Code chunks must be executed sequentially in R Studio or R Studio Server installation.
# Description: "Merge Predicted Rasters" merges the predicted grid rasters into a single output raster.
# ---------------------------------------------------------------------------

# Set root directory
root_folder = 'N://ACCS_Work/Projects/WildlifeEcology/Moose_SouthwestAlaska/Data/Data_Output/'

# Set map class folder
map_class = 'NoCalf'

# Define input folder
input_folder = paste(root_folder,
                      'predicted_rasters/round_20210629',
                      map_class,
                      sep = '/'
                      )

# Define output folder
output_folder = paste(root_folder,
                      'rasters_final/round_20210629',
                      map_class,
                      sep = '/'
                      )

# Define output file
output_file = paste(output_folder, 
                    '/',
                    'SouthwestAlaska_Moose_Calving_',
                    map_class,
                    '.tif',
                    sep = '')

# Import required libraries for geospatial processing: sp, raster, rgdal, and stringr.
library(sp)
library(raster)
library(rgdal)

# Generate list of raster img files from input folder
raster_files = list.files(path = input_folder, pattern = ".img$", full.names = TRUE)
count = length(raster_files)

# Convert list of files into list of raster objects
start = proc.time()
print(paste('Compiling ', toString(count), ' rasters...'))
raster_objects = lapply(raster_files, raster)
# Add function and filename attributes to list
raster_objects$fun = max
raster_objects$filename = output_file
raster_objects$overwrite = TRUE
raster_objects$options = c('TFW=YES')
end = proc.time() - start
print(paste('Completed in ', end[3], ' seconds.', sep = ''))

# Merge rasters
start = proc.time()
print(paste('Merging ', toString(count), ' rasters...'))
merged_raster = do.call(mosaic, raster_objects)
end = proc.time() - start
print(paste('Completed in ', end[3], ' seconds.', sep = ''))