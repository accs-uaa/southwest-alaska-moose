# -*- coding: utf-8 -*-
# ---------------------------------------------------------------------------
# Prepare roughness covariate
# Author: Timm Nawrocki
# Last Updated: 2021-05-25
# Usage: Must be executed in an ArcGIS Pro Python 3.6 installation.
# Description: "Prepare roughness covariate" merges and extracts raster tiles into a single raster.
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
roughness_C5 = os.path.join(drive,
                            root_folder,
                            'Data/topography/Composite_10m_Beringia/integer/gridded_select/Grid_C5/Roughness_Composite_10m_Beringia_AKALB_Grid_C5.tif')
roughness_C6 = os.path.join(drive,
                            root_folder,
                            'Data/topography/Composite_10m_Beringia/integer/gridded_select/Grid_C6/Roughness_Composite_10m_Beringia_AKALB_Grid_C6.tif')
roughness_D5 = os.path.join(drive,
                            root_folder,
                            'Data/topography/Composite_10m_Beringia/integer/gridded_select/Grid_D5/Roughness_Composite_10m_Beringia_AKALB_Grid_D5.tif')
roughness_D6 = os.path.join(drive,
                            root_folder,
                            'Data/topography/Composite_10m_Beringia/integer/gridded_select/Grid_D6/Roughness_Composite_10m_Beringia_AKALB_Grid_D6.tif')
roughness_E5 = os.path.join(drive,
                            root_folder,
                            'Data/topography/Composite_10m_Beringia/integer/gridded_select/Grid_E5/Roughness_Composite_10m_Beringia_AKALB_Grid_E5.tif')

# Define output raster
roughness_covariate = os.path.join(data_folder, 'Data_Input/topography/roughness.tif')

# Define input and output arrays
combine_inputs = [study_area, roughness_C5, roughness_C6, roughness_D5, roughness_D6, roughness_E5]
combine_outputs = [roughness_covariate]

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