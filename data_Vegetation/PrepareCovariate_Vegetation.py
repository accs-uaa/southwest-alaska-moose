# -*- coding: utf-8 -*-
# ---------------------------------------------------------------------------
# Prepare vegetation cover covariates
# Author: Timm Nawrocki
# Last Updated: 2021-05-26
# Usage: Must be executed in an ArcGIS Pro Python 3.6 installation.
# Description: "Prepare vegetation cover covariates" extracts foliar cover maps to the study area boundary to ensure matching extents.
# ---------------------------------------------------------------------------

# Import packages
import arcpy
import os
from package_GeospatialProcessing import arcpy_geoprocessing
from package_GeospatialProcessing import create_minimum_raster

# Set root directory
drive = 'N:/'
root_folder = 'ACCS_Work'

# Define data folder
data_folder = os.path.join(drive, root_folder, 'Projects/WildlifeEcology/Moose_SouthwestAlaska/Data')
vegetation_folder = os.path.join(drive, root_folder,
                                 'Projects/VegetationEcology/AKVEG_QuantitativeMap/Data/Data_Output/rasters_final/round_20210402')
work_geodatabase = os.path.join(data_folder, 'Moose_SouthwestAlaska.gdb')

# Define study area
study_area = os.path.join(data_folder, 'Data_Input/southwestAlaska_StudyArea.tif')

# Define major grids
grids_major = ['C5', 'C6',
               'D5', 'D6',
               'E5']

# Define map groups
map_groups = ['alnus', 'betshr', 'dectre', 'dryas', 'empnig', 'erivag', 'picgla', 'picmar', 'rhoshr', 'salshr', 'sphagn', 'vaculi',
              'vacvit', 'wetsed']

# Iterate through all inputs to create all outputs
for group in map_groups:
    # Define input rasters
    raster_C5 = os.path.join(vegetation_folder, group, 'NorthAmericanBeringia_' + group + '_C5.tif')
    raster_C6 = os.path.join(vegetation_folder, group, 'NorthAmericanBeringia_' + group + '_C6.tif')
    raster_D5 = os.path.join(vegetation_folder, group, 'NorthAmericanBeringia_' + group + '_D5.tif')
    raster_D6 = os.path.join(vegetation_folder, group, 'NorthAmericanBeringia_' + group + '_D6.tif')
    raster_E5 = os.path.join(vegetation_folder, group, 'NorthAmericanBeringia_' + group + '_E5.tif')

    # Define output raster
    raster_output = os.path.join(data_folder, 'Data_Input/vegetation', group + '.tif')

    # If output raster does not already exist, create output raster
    if arcpy.Exists(raster_output) == 0:
        # Define input and output arrays
        combine_inputs = [study_area, raster_C5, raster_C6, raster_D5, raster_D6, raster_E5]
        combine_outputs = [raster_output]

        # Create key word arguments
        combine_kwargs = {'cell_size': 10,
                          'output_projection': 3338,
                          'value_type': '16_BIT_SIGNED',
                          'no_data': '-32768',
                          'work_geodatabase': work_geodatabase,
                          'input_array': combine_inputs,
                          'output_array': combine_outputs
                          }

        # Combine raster tiles
        print(f'Combining raster tiles for {group}...')
        arcpy_geoprocessing(create_minimum_raster, **combine_kwargs)
        print('----------')

    else:
        print(f'Output raster for {group} already exists.')
        print('----------')
