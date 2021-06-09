# -*- coding: utf-8 -*-
# ---------------------------------------------------------------------------
# Prepare lake covariate
# Author: Timm Nawrocki
# Last Updated: 2021-06-01
# Usage: Must be executed in an ArcGIS Pro Python 3.6 installation.
# Description: "Prepare lake covariate" extracts lake and pond features from the NHD, converts the features to rasters, and extracts to the study area.
# ---------------------------------------------------------------------------

# Import packages
import arcpy
import os
from package_GeospatialProcessing import arcpy_geoprocessing
from package_GeospatialProcessing import extract_features_to_raster
from package_GeospatialProcessing import extract_to_boundary

# Set root directory
drive = 'N:/'
root_folder = 'ACCS_Work'

# Define data folder
data_folder = os.path.join(drive, root_folder, 'Projects/WildlifeEcology/Moose_SouthwestAlaska/Data')
work_geodatabase = os.path.join(data_folder, 'Moose_SouthwestAlaska.gdb')

# Define input datasets
study_area = os.path.join(data_folder, 'Data_Input/southwestAlaska_StudyArea.tif')
nhd_waterbodies = os.path.join(drive, root_folder, 'Data/inlandwaters/NHD_H_02_GDB.gdb/Hydrography/NHDWaterbody')

# Define output rasters
lake_intermediate = os.path.join(data_folder, 'Data_Input/hydrography/lake_intermediate.tif')
lake_covariate = os.path.join(data_folder, 'Data_Input/hydrography/lake.tif')

# Define input and output arrays
raster_inputs = [study_area, nhd_waterbodies]
raster_outputs = [lake_intermediate]

# Create key word arguments
raster_kwargs = {'cell_size': 10,
                 'input_projection': 4269,
                 'output_projection': 3338,
                 'geographic_transformation': '',
                 'where_clause': 'FType = 390',
                 'value_field': 'FType',
                 'work_geodatabase': work_geodatabase,
                 'input_array': raster_inputs,
                 'output_array': raster_outputs
                 }

# Convert features to raster
print('Converting feature class to raster...')
arcpy_geoprocessing(extract_features_to_raster, **raster_kwargs)
print('----------')

# Define input and output arrays
extract_inputs = [lake_intermediate, study_area, study_area]
extract_outputs = [lake_covariate]

# Create key word arguments
extract_kwargs = {'no_data_replace': 0,
                  'work_geodatabase': work_geodatabase,
                  'input_array': extract_inputs,
                  'output_array': extract_outputs
                  }

# Extract raster to study area
print('Extracting raster to study area...')
arcpy_geoprocessing(extract_to_boundary, **extract_kwargs)
print('----------')

# Delete intermediate lake raster if it exists
if arcpy.Exists(lake_intermediate) == 1:
    arcpy.management.Delete(lake_intermediate)
