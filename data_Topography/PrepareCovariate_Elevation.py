# -*- coding: utf-8 -*-
# ---------------------------------------------------------------------------
# Prepare elevation covariate
# Author: Timm Nawrocki
# Last Updated: 2021-05-25
# Usage: Must be executed in an ArcGIS Pro Python 3.6 installation.
# Description: "Prepare elevation covariate" merges and extracts raster tiles into a single raster.
# ---------------------------------------------------------------------------

# Import packages
import os
from package_GeospatialProcessing import arcpy_geoprocessing
from package_GeospatialProcessing import create_minimum_raster

# Set root directory
drive = 'N:/'
root_folder = 'ACCS_Work'

# Define data folder
data_folder = os.path.join(drive, root_folder, 'Projects/WildlifeEcology/Moose_SouthwestAlaska/Data')
work_geodatabase = os.path.join(data_folder, 'Moose_SouthwestAlaska.gdb')

# Define input rasters
study_area = os.path.join(data_folder, 'Data_Input/southwestAlaska_StudyArea.tif')
elevation_C5 = os.path.join(drive,
                            root_folder,
                            'Data/topography/Composite_10m_Beringia/integer/gridded_select/Grid_C5/Elevation_Composite_10m_Beringia_AKALB_Grid_C5.tif')
elevation_C6 = os.path.join(drive,
                            root_folder,
                            'Data/topography/Composite_10m_Beringia/integer/gridded_select/Grid_C6/Elevation_Composite_10m_Beringia_AKALB_Grid_C6.tif')
elevation_D5 = os.path.join(drive,
                            root_folder,
                            'Data/topography/Composite_10m_Beringia/integer/gridded_select/Grid_D5/Elevation_Composite_10m_Beringia_AKALB_Grid_D5.tif')
elevation_D6 = os.path.join(drive,
                            root_folder,
                            'Data/topography/Composite_10m_Beringia/integer/gridded_select/Grid_D6/Elevation_Composite_10m_Beringia_AKALB_Grid_D6.tif')
elevation_E5 = os.path.join(drive,
                            root_folder,
                            'Data/topography/Composite_10m_Beringia/integer/gridded_select/Grid_E5/Elevation_Composite_10m_Beringia_AKALB_Grid_E5.tif')
# Define output raster
elevation_covariate = os.path.join(data_folder, 'Data_Input/topography/elevation.tif')

# Define input and output arrays
combine_inputs = [study_area, elevation_C5, elevation_C6, elevation_D5, elevation_D6, elevation_E5]
combine_outputs = [elevation_covariate]

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
print('Combining raster tiles...')
arcpy_geoprocessing(create_minimum_raster, **combine_kwargs)
print('----------')
