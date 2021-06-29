# -*- coding: utf-8 -*-
# ---------------------------------------------------------------------------
# Extract Covariates to Points
# Author: Timm Nawrocki
# Last Updated: 2020-03-25
# Usage: Must be executed in R 4.0.0+.
# Description: "Extract Covariates to Points" extracts data from rasters to points representing actual and random moose paths.
# ---------------------------------------------------------------------------

rm(list = ls())

# Define Git directory ----
git_dir <- "C:/ACCS_Work/GitHub/southwest-alaska-moose/package_Paths/"

#### Load packages and data ----
source(paste0(git_dir,"init.R"))

# Define input folders for vegetation covariates
topography_folder = paste(input_dir,
                          'topography',
                          sep = '/')

edge_folder = paste(input_dir,
                    'edge_distance',
                    sep = '/')

vegetation_folder = paste(input_dir,
                          'vegetation',
                          sep = '/')

hydrography_folder = paste(input_dir,
                           'hydrography',
                           sep = '/')


# Define output csv file
output_csv = paste(pipeline_dir,
                   '06-extractCovariates',
                   'allPoints_extractedCovariates.csv',
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
print(predictors_all) # Should be 19

# Generate a stack of all covariate rasters
print('Creating raster stack...')
start = proc.time()
predictor_stack = stack(predictors_all)
end = proc.time() - start
print(end[3])

# Read path data and extract covariates
print('Extracting covariates...')
start = proc.time()
path_data = readOGR(dsn=geoDB,layer="allPaths_AKALB")
path_extracted = data.frame(path_data@data, raster::extract(predictor_stack, path_data))
end = proc.time() - start
print(end[3])

# Convert field names to standard
path_extracted = path_extracted %>%
  dplyr::rename(forest_edge = southwestAlaska_ForestEdge) %>%
  dplyr::rename(tundra_edge = southwestAlaska_TundraEdge)

# Export data as a csv
write.csv(path_extracted, file = output_csv, fileEncoding = 'UTF-8')
print('Finished extracting to paths.')
print('----------')
rm(list=ls())