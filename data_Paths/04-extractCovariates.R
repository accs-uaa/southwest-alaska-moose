# -*- coding: utf-8 -*-
# ---------------------------------------------------------------------------
# Extract Covariates to Points
# Author: Timm Nawrocki
# Last Updated: 2020-11-30
# Usage: Must be executed in R 4.0.0+.
# Description: "Extract Covariates to Points" extracts data from rasters to points representing actual and random moose paths.
# ---------------------------------------------------------------------------

# Set root directory
drive = 'C:'
root_folder = 'Users/adroghini/Documents/GitHub/southwest-alaska-moose/data/covariates'

# Define input folders
path_folder = paste(drive,
                    root_folder,
                    'paths',
                    sep = '/')

# geodb = "C:/Users/adroghini/Documents/GitHub/southwest-alaska-moose/gis/mooseHomeRanges.gdb"

topography_folder = paste(drive,
                          root_folder,
                          'topography',
                          sep = '/')
edge_folder = paste(drive,
                    root_folder,
                    'edge_distance',
                    sep = '/')
vegetation_folder = paste(drive,
                          root_folder,
                          'vegetation',
                          sep = '/')

# Define input site metadata
path_shapefile = paste(path_folder,
                  'allPaths_AKALB.shp',
                  sep = '/')

# Install required libraries if they are not already installed.
Required_Packages <- c('dplyr', 'raster', 'rgdal', 'sp', 'stringr', 'tidyr')
New_Packages <- Required_Packages[!(Required_Packages %in% installed.packages()[,"Package"])]
if (length(New_Packages) > 0) {
  install.packages(New_Packages)
}

# Import required libraries for geospatial processing: dplyr, raster, rgdal, sp, and stringr.
library(dplyr)
library(raster)
library(rgdal)
library(sp)
library(stringr)

# Define output csv file

# output_csv = paste(path_folder, 'allPaths_extracted.csv', sep = '/')
output_csv = "C:/Users/adroghini/Documents/GitHub/southwest-alaska-moose/pipeline/paths/allPaths_extracted.csv"

# Create a list of all predictor rasters
predictors_topography = list.files(topography_folder, pattern = 'tif$', full.names = TRUE)
predictors_edge = list.files(edge_folder, pattern = 'tif$', full.names = TRUE)
predictors_vegetation = list.files(vegetation_folder, pattern = 'tif$', full.names = TRUE)
predictors_all = c(predictors_topography,
                   predictors_edge,
                   predictors_vegetation)
print(paste('Number of predictor rasters: ', length(predictors_all), sep = ''))
print(predictors_all)

# Generate a stack of all covariate rasters
print('Creating raster stack...')
start = proc.time()
predictor_stack = stack(predictors_all)
end = proc.time() - start
print(end[3])

# Read path data and extract covariates
print('Extracting covariates...')
start = proc.time()
path_data = readOGR(dsn = path_shapefile)
# path_data = readOGR(dsn=geodb,layer="allPaths_AKALB")

path_extracted = data.frame(path_data@data, extract(predictor_stack, path_data))
end = proc.time() - start
print(end[3])

# Convert field names to standard
path_extracted = path_extracted %>%
  rename(forest_edge = southwestAlaska_ForestEdge) %>%
  rename(tundra_edge = southwestAlaska_TussockTundraEdge)
    
# Export data as a csv
write.csv(path_extracted, file = output_csv, fileEncoding = 'UTF-8')
print('Finished extracting to paths.')
print('----------')
rm(list=ls())