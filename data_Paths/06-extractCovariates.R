# -*- coding: utf-8 -*-
# ---------------------------------------------------------------------------
# Extract Covariates to Points
# Author: Timm Nawrocki
# Last Updated: 2020-03-25
# Usage: Must be executed in R 4.0.0+.
# Description: "Extract Covariates to Points" extracts data from rasters to points representing actual and random moose paths.
# ---------------------------------------------------------------------------

# Load packages

# Set root directory
drive = 'C:'
root_folder = 'Users/adroghini/Documents/GitHub/southwest-alaska-moose'
covar_folder = 'data/covariates'
output_folder = 'pipeline/paths'
gis_folder = 'gis'
package_folder = 'package_Paths'

# Load packages
path_package = paste(drive,
                     root_folder,
                     package_folder,
                     'init.R',
                     sep = '/')

source(path_package)

# Define input folders
geodatabase = paste(drive,
                    root_folder,
                    gis_folder,
                    'mooseHomeRanges.gdb',
                    sep = '/')

topography_folder = paste(drive,
                          root_folder,
                          covar_folder,
                          'topography',
                          sep = '/')
edge_folder = paste(drive,
                    root_folder,
                    covar_folder,
                    'edge_distance',
                    sep = '/')

vegetation_folder = paste(drive,
                          root_folder,
                          covar_folder,
                          'vegetation',
                          sep = '/')

hydrography_folder = paste(drive,
                           root_folder,
                           covar_folder,
                           'hydrography',
                           sep = '/')


# Define output csv file
output_csv = paste(drive,
                   root_folder,
                   output_folder,
                   'allPaths_extracted.csv',
                   sep = '/')

# Create a list of all predictor rasters
predictors_topography = list.files(topography_folder, pattern = 'tif$', full.names = TRUE)
predictors_edge = list.files(edge_folder, pattern = 'tif$', full.names = TRUE)
predictors_vegetation = list.files(vegetation_folder, pattern = 'tif$', full.names = TRUE)
predictors_hydrography = list.files(hydrography_folder, pattern = 'tif$', full.names = TRUE)
predictors_all = c(predictors_topography,
                   predictors_edge,
                   predictors_vegetation,
                   predictors_hydrography)
print(paste('Number of predictor rasters: ', length(predictors_all), sep = ''))
print(predictors_all) # Should be 13

# Generate a stack of all covariate rasters
print('Creating raster stack...')
start = proc.time()
predictor_stack = stack(predictors_all)
end = proc.time() - start
print(end[3])

# Read path data and extract covariates
print('Extracting covariates...')
start = proc.time()
path_data = readOGR(dsn=geodatabase,layer="allPaths_AKALB")

path_extracted = data.frame(path_data@data, raster::extract(predictor_stack, path_data))
end = proc.time() - start
print(end[3])

# Convert field names to standard
path_extracted = path_extracted %>%
  dplyr::rename(forest_edge = southwestAlaska_ForestEdge) %>%
  dplyr::rename(tundra_edge = southwestAlaska_TussockTundraEdge)

# Export data as a csv
write.csv(path_extracted, file = output_csv, fileEncoding = 'UTF-8')
print('Finished extracting to paths.')
print('----------')
rm(list=ls())