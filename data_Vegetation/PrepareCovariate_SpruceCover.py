# -*- coding: utf-8 -*-
# ---------------------------------------------------------------------------
# Prepare spruce cover covariates
# Author: Timm Nawrocki
# Last Updated: 2020-11-01
# Usage: Must be executed in an ArcGIS Pro Python 3.6 installation.
# Description: "Prepare spruce cover covariates" extracts the foliar cover maps for black spruce and white spruce to the ranges for black spruce and white spruce to eliminate erroneous model predictions beyond the ranges of the species.
# ---------------------------------------------------------------------------

# Import packages
import os
from package_GeospatialProcessing import arcpy_geoprocessing
from package_GeospatialProcessing import extract_to_boundary

# Set root directory
drive = 'N:/'
root_folder = 'ACCS_Work'

# Define data folder
data_folder = os.path.join(drive, root_folder, 'Projects/WildlifeEcology/Moose_SouthwestAlaska/Data')
work_geodatabase = os.path.join(data_folder, 'Moose_SouthwestAlaska.gdb')

# Define input datasets
snap_raster = os.path.join(data_folder, 'Data_Input/southwestAlaska_StudyArea.tif')
range_picgla = os.path.join(data_folder, 'Data_Input/auxiliary_data/range_PiceaGlauca.shp')
range_picmar = os.path.join(data_folder, 'Data_Input/auxiliary_data/range_PiceaMariana.shp')
raster_picgla = os.path.join(data_folder, 'Data_Input/vegetation/northAmericanBeringia_picgla.tif')
raster_picmar = os.path.join(data_folder, 'Data_Input/vegetation/northAmericanBeringia_picmar.tif')

# Define output raster
cover_picgla = os.path.join(data_folder, 'Data_Input/vegetation/northAmericanBeringia_picgla_extract.tif')
cover_picmar = os.path.join(data_folder, 'Data_Input/vegetation/northAmericanBeringia_picmar_extract.tif')

# Group inputs and outputs
rasters_initial = [raster_picgla, raster_picmar]
ranges = [range_picgla, range_picmar]
rasters_output = [cover_picgla, cover_picmar]

# Iterate through all inputs to create all outputs
n = 0
while n < len(rasters_initial):
    # Define input and output arrays
    extract_inputs = [rasters_initial[n], ranges[n], snap_raster]
    extract_outputs = [rasters_output[n]]

    # Create key word arguments
    extract_kwargs = {'work_geodatabase': work_geodatabase,
                      'input_array': extract_inputs,
                      'output_array': extract_outputs
                      }

    # Calculate minimum inverse density-weighted distance
    print(f'Extracting {os.path.split(rasters_initial[n])[1]} to boundary...')
    arcpy_geoprocessing(extract_to_boundary, **extract_kwargs)
    print('----------')

    # Increase iterator
    n += 1
