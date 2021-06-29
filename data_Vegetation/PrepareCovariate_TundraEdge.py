# -*- coding: utf-8 -*-
# ---------------------------------------------------------------------------
# Prepare tundra edge covariate
# Author: Timm Nawrocki
# Last Updated: 2021-06-22
# Usage: Must be executed in an ArcGIS Pro Python 3.6 installation.
# Description: "Prepare tundra covariate" calculates the minimum inverse density-weighted distance from the cover of Eriophorum vaginatum, Dryas Dwarf Shrubs, and Barren from the NLCD 2016.
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
raster_erivag = os.path.join(data_folder, 'Data_Input/vegetation/erivag.tif')
raster_dryas = os.path.join(data_folder, 'Data_Input/vegetation/dryas.tif')
raster_barren = os.path.join(data_folder, 'Data_Input/vegetation/barren.tif')

# Define output raster
raster_tundracover = os.path.join(data_folder, 'Data_Input/vegetation/TundraCover.tif')
tundra_edge = os.path.join(data_folder, 'Data_Input/edge_distance/southwestAlaska_TundraEdge.tif')

# Create tundra cover raster if it does not already exist
if arcpy.Exists(raster_tundracover) == 0:
    # Define input and output arrays
    sum_inputs = [study_area, raster_erivag, raster_dryas, raster_barren]
    sum_outputs = [raster_tundracover]

    # Create key word arguments
    sum_kwargs = {'work_geodatabase': work_geodatabase,
                  'input_array': sum_inputs,
                  'output_array': sum_outputs
                  }

    # Sum tundra cover rasters
    print('Summing tundra cover rasters...')
    arcpy_geoprocessing(sum_rasters, **sum_kwargs)
    print('----------')
else:
    print('Tundra cover raster already exists.')
    print('----------')

# Define a maximum foliar cover value from the tundra cover raster
maximum_cover = int(arcpy.management.GetRasterProperties(raster_tundracover, 'MAXIMUM').getOutput(0))
print(f'Maximum cover value is {maximum_cover}%.')
print('----------')

# Iterate through all possible cover values greater than or equal to 10% and calculate the inverse density-weighted distance for that value
n = 10
edge_rasters = []
while n <= maximum_cover:
    # Define output raster
    if n < 10:
        edge_raster = os.path.join(data_folder, 'Data_Input/edge_distance', 'tundra_edge_0' + str(n) + '.tif')
    else:
        edge_raster = os.path.join(data_folder, 'Data_Input/edge_distance', 'tundra_edge_' + str(n) + '.tif')

    # Calculate edge raster if it does not already exist
    if arcpy.Exists(edge_raster) == 0:

        # Determine if the number of cells for target value
        values = {}
        with arcpy.da.SearchCursor(raster_tundracover, ['VALUE', 'COUNT']) as rows:
            for row in rows:
                values[row[0]] = row[1]
        count = values.get(n, 0)

        # If number of cells is greater than zero, perform edge calculation
        if count > 0:
            # Define input and output arrays
            edge_inputs = [study_area, raster_tundracover]
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
        else:
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
minimum_outputs = [tundra_edge]

# Create key word arguments
minimum_kwargs = {'cell_size': 10,
                  'output_projection': 3338,
                  'value_type': '32_BIT_SIGNED',
                  'no_data': '-32768',
                  'work_geodatabase': work_geodatabase,
                  'input_array': minimum_inputs,
                  'output_array': minimum_outputs
                  }

# Calculate minimum inverse density-weighted distance
print('Creating minimum value raster...')
arcpy_geoprocessing(create_minimum_raster, **minimum_kwargs)
print('----------')
