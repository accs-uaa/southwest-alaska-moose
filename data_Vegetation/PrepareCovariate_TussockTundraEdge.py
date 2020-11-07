# -*- coding: utf-8 -*-
# ---------------------------------------------------------------------------
# Prepare tussock tundra edge covariate
# Author: Timm Nawrocki
# Last Updated: 2020-11-03
# Usage: Must be executed in an ArcGIS Pro Python 3.6 installation.
# Description: "Prepare tussock tundra covariate" calculates the minimum inverse density-weighted distance from the cover of Eriophorum vaginatum.
# ---------------------------------------------------------------------------

# Import packages
import arcpy
import os
from package_GeospatialProcessing import arcpy_geoprocessing
from package_GeospatialProcessing import calculate_idw_distance
from package_GeospatialProcessing import create_minimum_raster

# Set root directory
drive = 'N:/'
root_folder = 'ACCS_Work'

# Define data folder
data_folder = os.path.join(drive, root_folder, 'Projects/WildlifeEcology/Moose_SouthwestAlaska/Data')
work_geodatabase = os.path.join(data_folder, 'Moose_SouthwestAlaska.gdb')

# Define input rasters
study_area = os.path.join(data_folder, 'Data_Input/southwestAlaska_StudyArea.tif')
raster_erivag = os.path.join(data_folder, 'Data_Input/vegetation/northAmericanBeringia_erivag.tif')

# Define output raster
tussock_edge = os.path.join(data_folder, 'Data_Input/edge_distance/southwestAlaska_TussockTundraEdge.tif')

# Define a maximum foliar cover value from the Eriophorum vaginatum cover raster
maximum_cover = int(arcpy.GetRasterProperties_management(raster_erivag, 'MAXIMUM').getOutput(0))

# Iterate through all possible cover values greater than or equal to 5% and calculate the inverse density-weighted distance for that value
n = 5
edge_rasters = []
while n <= maximum_cover:
    # Define output raster
    if n < 10:
        edge_raster = os.path.join(data_folder, 'Data_Input/edge_distance', 'tundra_edge_0' + str(n) + '.tif')
    else:
        edge_raster = os.path.join(data_folder, 'Data_Input/edge_distance', 'tundra_edge_' + str(n) + '.tif')

    # Calculate edge raster if it does not already exist
    if arcpy.Exists(edge_raster) == 0:
        try:
            # Define input and output arrays
            edge_inputs = [raster_erivag]
            edge_outputs = [edge_raster]

            # Create key word arguments
            edge_kwargs = {'work_geodatabase': work_geodatabase,
                           'target_value': n,
                           'input_array': edge_inputs,
                           'output_array': edge_outputs
                           }

            # Calculate the inverse density-weighted distance for n% cover
            print(f'Calculating inverse density weighted distance where foliar cover = {n}%...')
            arcpy_geoprocessing(calculate_idw_distance, **edge_kwargs)
            print('----------')
        except:
            print(f'Foliar cover never equals {n}% cover.')
            print('----------')
    else:
        print(f'Inverse density weighted distance for {n}% foliar cover already exists.')
        print('----------')

    # Append raster to list if it exists
    if arcpy.Exists(edge_raster) == 1:
        # Append output raster path to list
        edge_rasters = edge_rasters + [edge_raster]

    # Increase the iterator by one
    n += 1

# Define input and output arrays
minimum_inputs = [study_area] + edge_rasters
minimum_outputs = [tussock_edge]

# Create key word arguments
minimum_kwargs = {'cell_size': 10,
                  'output_projection': 3338,
                  'work_geodatabase': work_geodatabase,
                  'input_array': minimum_inputs,
                  'output_array': minimum_outputs
                  }

# Calculate minimum inverse density-weighted distance
print('Creating minimum value raster...')
arcpy_geoprocessing(create_minimum_raster, **minimum_kwargs)
print('----------')
