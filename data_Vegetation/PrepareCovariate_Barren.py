# -*- coding: utf-8 -*-
# ---------------------------------------------------------------------------
# Prepare barren covariate
# Author: Timm Nawrocki
# Last Updated: 2021-06-21
# Usage: Must be executed in an ArcGIS Pro Python 3.6 installation.
# Description: "Prepare barren covariate" extracts the barren class from the NLCD 2016 and extracts it to the study area boundary.
# ---------------------------------------------------------------------------

# Import packages
import arcpy
import os
from package_GeospatialProcessing import arcpy_geoprocessing
from package_GeospatialProcessing import combine_raster_classes

# Set root directory
drive = 'N:/'
root_folder = 'ACCS_Work'

# Define data folder
data_folder = os.path.join(drive, root_folder, 'Projects/WildlifeEcology/Moose_SouthwestAlaska/Data')
vegetation_folder = os.path.join(drive, root_folder, 'Data/biota/vegetation')
work_geodatabase = os.path.join(data_folder, 'Moose_SouthwestAlaska.gdb')

# Define input rasters
raster_nlcd = os.path.join(vegetation_folder, 'Alaska_NationalLandCoverDatabase/Alaska_NationalLandCoverDatabase_2016_20200213.img')

# Define study area
study_area = os.path.join(data_folder, 'Data_Input/southwestAlaska_ElevationMask_300.tif')

# Define output raster
raster_output = os.path.join(data_folder, 'Data_Input/vegetation/barren.tif')

# Define selection statements
statement_nlcd = 'VALUE = 31'

# If output raster does not already exist, create output raster
if arcpy.Exists(raster_output) == 0:
    # Define input and output arrays
    combine_inputs = [study_area, raster_nlcd]
    combine_outputs = [raster_output]

    # Create key word arguments
    combine_kwargs = {'value_type': '16_BIT_SIGNED',
                      'no_data': '-32768',
                      'statement': statement_nlcd,
                      'out_value': 50,
                      'work_geodatabase': work_geodatabase,
                      'input_array': combine_inputs,
                      'output_array': combine_outputs
                      }

    # Combine raster tiles
    print(f'Combining rasters for barren...')
    arcpy_geoprocessing(combine_raster_classes, **combine_kwargs)
    print('----------')

else:
    print(f'Output raster already exists.')
    print('----------')
