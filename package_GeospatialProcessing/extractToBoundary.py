# -*- coding: utf-8 -*-
# ---------------------------------------------------------------------------
# Extract to Boundary
# Author: Timm Nawrocki
# Last Updated: 2020-11-01
# Usage: Must be executed in an ArcGIS Pro Python 3.6 installation.
# Description: "Extract to Boundary" is a function that extracts raster data to a feature or raster boundary. All no data values are reset to a user-defined value.
# ---------------------------------------------------------------------------

# Define a function to extract raster data to a boundary
def extract_to_boundary(**kwargs):
    """
    Description: extracts a raster to a boundary
    Inputs: 'no_data_replace' -- a value to replace no data values
            'work_geodatabase' -- path to a file geodatabase that will serve as the workspace
            'input_array' -- an array containing the target raster to extract (must be first), the boundary feature class or raster (must be second), and the grid raster (must be third)
            'output_array' -- an array containing the output raster
    Returned Value: Returns a raster dataset
    Preconditions: the initial raster must exist on disk and the boundary and grid datasets must be created manually
    """

    # Import packages
    import arcpy
    from arcpy.sa import Con
    from arcpy.sa import IsNull
    from arcpy.sa import ExtractByMask
    from arcpy.sa import Raster
    import datetime
    import time

    # Parse key word argument inputs
    no_data_replace = kwargs['no_data_replace']
    work_geodatabase = kwargs['work_geodatabase']
    input_raster = kwargs['input_array'][0]
    boundary_data = kwargs['input_array'][1]
    grid_raster = kwargs['input_array'][2]
    output_raster = kwargs['output_array'][0]

    # Set overwrite option
    arcpy.env.overwriteOutput = True

    # Set workspace
    arcpy.env.workspace = work_geodatabase

    # Set snap raster and extent
    arcpy.env.snapRaster = grid_raster
    arcpy.env.extent = Raster(grid_raster).extent

    # Start timing function
    print(f'\tConverting no data values to {no_data_replace}...')
    iteration_start = time.time()
    # Convert no data values to data
    nonull_raster = Con(IsNull(Raster(input_raster)), no_data_replace, Raster(input_raster))
    # End timing
    iteration_end = time.time()
    iteration_elapsed = int(iteration_end - iteration_start)
    iteration_success_time = datetime.datetime.now()
    # Report success
    print(
        f'\tCompleted at {iteration_success_time.strftime("%Y-%m-%d %H:%M")} (Elapsed time: {datetime.timedelta(seconds=iteration_elapsed)})')
    print('\t----------')

    # Start timing function
    print('\tExtracting raster to boundary dataset...')
    iteration_start = time.time()
    # Extract raster to study area
    extracted_raster = ExtractByMask(nonull_raster, boundary_data)
    # End timing
    iteration_end = time.time()
    iteration_elapsed = int(iteration_end - iteration_start)
    iteration_success_time = datetime.datetime.now()
    # Report success
    print(
        f'\tCompleted at {iteration_success_time.strftime("%Y-%m-%d %H:%M")} (Elapsed time: {datetime.timedelta(seconds=iteration_elapsed)})')
    print('\t----------')

    # Determine raster type and no data value
    no_data_value = Raster(input_raster).noDataValue
    type_number = arcpy.GetRasterProperties_management(input_raster, 'VALUETYPE').getOutput(0)
    value_types = ['1_BIT',
                   '2_BIT',
                   '4_BIT',
                   '8_BIT_UNSIGNED',
                   '8_BIT_SIGNED',
                   '16_BIT_UNSIGNED',
                   '16_BIT_SIGNED',
                   '32_BIT_UNSIGNED',
                   '32_BIT_SIGNED',
                   '32_BIT_FLOAT',
                   '64_BIT']
    value_type = value_types[int(type_number)]
    print(f'\tSaving extracted raster to disk as {value_type} raster with NODATA value of {no_data_value}...')
    # Save extracted raster to disk
    arcpy.CopyRaster_management(extracted_raster,
                                output_raster,
                                '',
                                '',
                                no_data_value,
                                'NONE',
                                'NONE',
                                value_type,
                                'NONE',
                                'NONE',
                                'TIFF',
                                'NONE',
                                'CURRENT_SLICE',
                                'NO_TRANSPOSE')
    # End timing
    iteration_end = time.time()
    iteration_elapsed = int(iteration_end - iteration_start)
    iteration_success_time = datetime.datetime.now()
    # Report success
    print(f'\t\tCompleted at {iteration_success_time.strftime("%Y-%m-%d %H:%M")} (Elapsed time: {datetime.timedelta(seconds=iteration_elapsed)})')
    print('\t\t----------')
    out_process = f'\tSuccessfully extracted raster data to boundary.'
    return out_process
