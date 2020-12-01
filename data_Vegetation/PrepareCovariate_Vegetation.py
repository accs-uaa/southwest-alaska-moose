# -*- coding: utf-8 -*-
# ---------------------------------------------------------------------------
# Prepare vegetation cover covariates
# Author: Timm Nawrocki
# Last Updated: 2020-12-01
# Usage: Must be executed in an ArcGIS Pro Python 3.6 installation.
# Description: "Prepare vegetation cover covariates" extracts foliar cover maps to the study area boundary to ensure matching extents.
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
vegetation_folder = os.path.join(drive, root_folder, 'Projects/VegetationEcology/AKVEG_QuantitativeMap/Data')
work_geodatabase = os.path.join(data_folder, 'Moose_SouthwestAlaska.gdb')

# Define input datasets
study_area = os.path.join(data_folder, 'Data_Input/southwestAlaska_StudyArea.tif')
raster_alnus = os.path.join(vegetation_folder, 'Data_Output/rasters_final/northAmericanBeringia_alnus.tif')
raster_betshr = os.path.join(vegetation_folder, 'Data_Output/rasters_final/northAmericanBeringia_betshr.tif')
raster_dectre = os.path.join(vegetation_folder, 'Data_Output/rasters_final/northAmericanBeringia_dectre.tif')
raster_erivag = os.path.join(vegetation_folder, 'Data_Output/rasters_final/northAmericanBeringia_erivag.tif')
raster_salshr = os.path.join(vegetation_folder, 'Data_Output/rasters_final/northAmericanBeringia_salshr.tif')
raster_wetsed = os.path.join(vegetation_folder, 'Data_Output/rasters_final/northAmericanBeringia_wetsed.tif')

# Define output raster
cover_alnus = os.path.join(data_folder, 'Data_Input/vegetation/alnus.tif')
cover_betshr = os.path.join(data_folder, 'Data_Input/vegetation/betshr.tif')
cover_dectre = os.path.join(data_folder, 'Data_Input/vegetation/dectre.tif')
cover_erivag = os.path.join(data_folder, 'Data_Input/vegetation/erivag.tif')
cover_salshr = os.path.join(data_folder, 'Data_Input/vegetation/salshr.tif')
cover_wetsed = os.path.join(data_folder, 'Data_Input/vegetation/wetsed.tif')

# Group inputs and outputs
rasters_initial = [raster_alnus, raster_betshr, raster_dectre, raster_erivag, raster_salshr, raster_wetsed]
rasters_output = [cover_alnus, cover_betshr, cover_dectre, cover_erivag, cover_salshr, cover_wetsed]

# Iterate through all inputs to create all outputs
n = 0
while n < len(rasters_initial):
    # Define input and output arrays
    extract_inputs = [rasters_initial[n], study_area, study_area]
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
