# -*- coding: utf-8 -*-
# ---------------------------------------------------------------------------
# Convert and Project Paths
# Author: Timm Nawrocki
# Last Updated: 2020-11-30
# Usage: Must be executed in an ArcGIS Pro Python 3.6 installation.
# Description: "Convert and Project Paths" converts a set of xy points stored in a csv table to shapefile and reprojects the data to an output coordinate system.
# ---------------------------------------------------------------------------

# Import packages
import os
from package_GeospatialProcessing import arcpy_geoprocessing
from package_GeospatialProcessing import project_xy_table

# Set root directory
drive = 'N:/'
root_folder = 'ACCS_Work'

# Define data folder
data_folder = os.path.join(drive, root_folder, 'Projects/WildlifeEcology/Moose_SouthwestAlaska/Data')
work_geodatabase = os.path.join(data_folder, 'Moose_SouthwestAlaska.gdb')

# Define input data
path_csv = os.path.join(data_folder, 'Data_Input/paths/allPaths.csv')

# Define output shapefile
path_shapefile = os.path.join(data_folder, 'Data_Input/paths/allPaths_AKALB.shp')

# Define input and output arrays
project_inputs = [path_csv]
project_outputs = [path_shapefile]

# Create key word arguments
project_kwargs = {'coordinate_fields': ['x', 'y'],
                  'input_projection': 32604,
                  'output_projection': 3338,
                  'transformation': 'WGS_1984_(ITRF00)_To_NAD_1983',
                  'work_geodatabase': work_geodatabase,
                  'input_array': project_inputs,
                  'output_array': project_outputs
                  }

# Combine raster tiles
print('Converting coordinates...')
arcpy_geoprocessing(project_xy_table, **project_kwargs)
print('----------')