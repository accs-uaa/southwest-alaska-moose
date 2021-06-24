# -*- coding: utf-8 -*-
# ---------------------------------------------------------------------------
# Combine raster classes
# Author: Timm Nawrocki
# Last Updated: 2021-06-21
# Usage: Must be executed in an ArcGIS Pro Python 3.6+ installation.
# Description: "Combine raster classes" is a function that creates a new raster from a set of existing rasters by selecting only particular classes from each.
# ---------------------------------------------------------------------------

# Define a function to create a raster from multiple categorical input rasters
def combine_raster_classes(**kwargs):
    """
    Description: merges all input rasters in an array and extracts to study area
    Inputs: 'value_type' -- the raster value type
            'no_data' -- the raster no data value
            'statements' -- select by attribute SQL queries to perform for each input raster
            'out_value' -- output value to assign to combined raster
            'work_geodatabase' -- path to a file geodatabase that will serve as the workspace
            'input_array' -- an array containing the study area raster (must be first) and input rasters to combine (order must match the order of statements)
            'output_array' -- an array containing the output raster
    Returned Value: Returns a raster dataset on disk containing the combined raster
    Preconditions: requires existing categorical raster datasets
    """

    # Import packages
    import arcpy
    from arcpy.sa import Con
    from arcpy.sa import ExtractByAttributes
    from arcpy.sa import ExtractByMask
    from arcpy.sa import Raster
    from arcpy.sa import SetNull
    import datetime
    import time

    # Parse key word argument inputs
    value_type = kwargs['value_type']
    no_data = kwargs['no_data']
    statement = kwargs['statement']
    out_value = kwargs['out_value']
    work_geodatabase = kwargs['work_geodatabase']
    study_area = kwargs['input_array'][0]
    input_raster = kwargs['input_array'][1]
    output_raster = kwargs['output_array'][0]

    # Set overwrite option
    arcpy.env.overwriteOutput = True

    # Set workspace
    arcpy.env.workspace = work_geodatabase

    # Use two thirds of cores on processes that can be split.
    arcpy.env.parallelProcessingFactor = "66%"

    # Set snap raster, extent, and cell size
    arcpy.env.snapRaster = study_area
    arcpy.env.extent = Raster(study_area).extent
    arcpy.env.cellSize = "MINOF"

    # Start timing function
    iteration_start = time.time()
    print(f'\tExtracting input raster by attributes...')
    # Extract raster by attributes
    attribute_raster = ExtractByAttributes(Raster(input_raster), statement)
    # End timing
    iteration_end = time.time()
    iteration_elapsed = int(iteration_end - iteration_start)
    iteration_success_time = datetime.datetime.now()
    # Report success
    print(f'\tCompleted at {iteration_success_time.strftime("%Y-%m-%d %H:%M")} (Elapsed time: {datetime.timedelta(seconds=iteration_elapsed)})')
    print('\t----------')

    # Start timing function
    iteration_start = time.time()
    print(f'\tSetting output and null values...')
    # Convert raster values to output value
    reclass_raster = Con(attribute_raster, out_value, 0, 'VALUE > 0')
    # Set zero values to null
    null_raster = SetNull(reclass_raster, reclass_raster, 'VALUE = 0')
    # End timing
    iteration_end = time.time()
    iteration_elapsed = int(iteration_end - iteration_start)
    iteration_success_time = datetime.datetime.now()
    # Report success
    print(
        f'\tCompleted at {iteration_success_time.strftime("%Y-%m-%d %H:%M")} (Elapsed time: {datetime.timedelta(seconds=iteration_elapsed)})')
    print('\t----------')

    # Start timing function
    iteration_start = time.time()
    print(f'\tExtracting raster to study area...')
    # Extract raster to study area
    extract_raster = ExtractByMask(null_raster, study_area)
    # End timing
    iteration_end = time.time()
    iteration_elapsed = int(iteration_end - iteration_start)
    iteration_success_time = datetime.datetime.now()
    # Report success
    print(
        f'\tCompleted at {iteration_success_time.strftime("%Y-%m-%d %H:%M")} (Elapsed time: {datetime.timedelta(seconds=iteration_elapsed)})')
    print('\t----------')

    # Start timing function
    iteration_start = time.time()
    print(f'\tSaving extracted raster to disk...')
    # Save the summed raster to disk
    arcpy.CopyRaster_management(extract_raster,
                                output_raster,
                                '',
                                '',
                                no_data,
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
    print(
        f'\tCompleted at {iteration_success_time.strftime("%Y-%m-%d %H:%M")} (Elapsed time: {datetime.timedelta(seconds=iteration_elapsed)})')
    print('\t----------')
    out_process = 'Successfully merged raster categories.'
    return out_process
