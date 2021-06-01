# -*- coding: utf-8 -*-
# ---------------------------------------------------------------------------
# Prepare forest edge covariate
# Author: Timm Nawrocki
# Last Updated: 2021-05-27
# Usage: Must be executed in an ArcGIS Pro Python 3.6 installation.
# Description: "Prepare forest edge covariate" calculates the minimum inverse density-weighted distance from the summed cover of white spruce, black spruce, and deciduous trees.
# ---------------------------------------------------------------------------

# Import packages
import arcpy
import os
from package_GeospatialProcessing import arcpy_geoprocessing
from package_GeospatialProcessing import calculate_idw_distance
from package_GeospatialProcessing import create_minimum_raster
from package_GeospatialProcessing import sum_rasters

# Set root directory
drive = 'N:/'
root_folder = 'ACCS_Work'

# Define data folder
data_folder = os.path.join(drive, root_folder, 'Projects/WildlifeEcology/Moose_SouthwestAlaska/Data')
work_geodatabase = os.path.join(data_folder, 'Moose_SouthwestAlaska.gdb')

# Define input rasters
study_area = os.path.join(data_folder, 'Data_Input/southwestAlaska_StudyArea.tif')
raster_picgla = os.path.join(data_folder, 'Data_Input/vegetation/picgla.tif')
raster_picmar = os.path.join(data_folder, 'Data_Input/vegetation/picmar.tif')
raster_dectre = os.path.join(data_folder, 'Data_Input/vegetation/dectre.tif')

# Define output raster
raster_treecover = os.path.join(data_folder, 'Data_Input/vegetation/TreeCover.tif')
forest_edge = os.path.join(data_folder, 'Data_Input/edge_distance/southwestAlaska_ForestEdge.tif')

# Create tree cover raster if it does not already exist
if arcpy.Exists(raster_treecover) == 0:
    # Define input and output arrays
    sum_inputs = [study_area, raster_picgla, raster_picmar, raster_dectre]
    sum_outputs = [raster_treecover]

    # Create key word arguments
    sum_kwargs = {'work_geodatabase': work_geodatabase,
                  'input_array': sum_inputs,
                  'output_array': sum_outputs
                  }

    # Sum tree cover rasters
    print('Summing tree cover rasters...')
    arcpy_geoprocessing(sum_rasters, **sum_kwargs)
    print('----------')
else:
    print('Tree cover raster already exists.')
    print('----------')

# Define a maximum foliar cover value from the tree cover raster
maximum_cover = int(arcpy.GetRasterProperties_management(raster_treecover, 'MAXIMUM').getOutput(0))

# Iterate through all possible cover values greater than or equal to 10% and calculate the inverse density-weighted distance for that value
n = 10
edge_rasters = []
while n <= maximum_cover:
    # Define output raster
    if n < 10:
        edge_raster = os.path.join(data_folder, 'Data_Input/edge_distance', 'forest_edge_0' + str(n) + '.tif')
    else:
        edge_raster = os.path.join(data_folder, 'Data_Input/edge_distance', 'forest_edge_' + str(n) + '.tif')

    # Calculate edge raster if it does not already exist
    if arcpy.Exists(edge_raster) == 0:
        try:
            # Define input and output arrays
            edge_inputs = [raster_treecover]
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
minimum_outputs = [forest_edge]

# Create key word arguments
minimum_kwargs = {'cell_size': 10,
                  'output_projection': 3338,
                  'value_type': '32_BIT_SIGNED',
                  'no_data': '-999',
                  'work_geodatabase': work_geodatabase,
                  'input_array': minimum_inputs,
                  'output_array': minimum_outputs
                  }

# Calculate minimum inverse density-weighted distance
print('Creating minimum value raster...')
arcpy_geoprocessing(create_minimum_raster, **minimum_kwargs)
print('----------')
