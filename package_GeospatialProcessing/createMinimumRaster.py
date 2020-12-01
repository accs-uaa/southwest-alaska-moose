# -*- coding: utf-8 -*-
# ---------------------------------------------------------------------------
# Create minimum raster
# Author: Timm Nawrocki
# Last Updated: 2020-11-01
# Usage: Must be executed in an ArcGIS Pro Python 3.6 installation.
# Description: "Create minimum raster" is a function that creates a new raster from a set of existing rasters using a minimum value rule and extracts to a study area.
# ---------------------------------------------------------------------------

# Define a function to create a minimum raster from multiple numeric input rasters
def create_minimum_raster(**kwargs):
    """
    Description: merges all input rasters in an array and extracts to study area
    Inputs: 'cell_size' -- a cell size for the output raster
            'output_projection' -- the machine number for the output projection
            'value_type' -- the raster value type
            'no_data' -- the raster no data value
            'work_geodatabase' -- path to a file geodatabase that will serve as the workspace
            'input_array' -- an array containing the study area raster (must be first) and all input rasters from which to calculate the minimum (order does not matter)
            'output_array' -- an array containing the output minimum raster
    Returned Value: Returns a raster dataset on disk containing the minimum value raster
    Preconditions: requires existing numeric raster datasets of the same value type
    """

    # Import packages
    import arcpy
    from arcpy.sa import ExtractByMask
    from arcpy.sa import Raster
    import datetime
    import os
    import time

    # Parse key word argument inputs
    cell_size = kwargs['cell_size']
    output_projection = kwargs['output_projection']
    value_type = kwargs['value_type']
    no_data = kwargs['no_data']
    work_geodatabase = kwargs['work_geodatabase']
    input_rasters = kwargs['input_array']
    study_area = input_rasters.pop(0)
    output_raster = kwargs['output_array'][0]

    # Define intermediate files
    output_location = os.path.split(output_raster)[0]
    mosaic_name = 'merged_raster.tif'
    mosaic_raster = os.path.join(output_location, mosaic_name)

    # Set overwrite option
    arcpy.env.overwriteOutput = True

    # Set workspace
    arcpy.env.workspace = work_geodatabase

    # Use two thirds of cores on processes that can be split.
    arcpy.env.parallelProcessingFactor = "66%"

    # Set snap raster and extent
    arcpy.env.snapRaster = study_area
    arcpy.env.extent = Raster(study_area).extent

    # Define the target projection
    composite_projection = arcpy.SpatialReference(output_projection)

    # Start timing function
    iteration_start = time.time()
    print(f'\tMerging {len(input_rasters)} rasters using minimum value...')
    # Mosaic input rasters to new raster using minimum
    arcpy.MosaicToNewRaster_management(input_rasters,
                                       output_location,
                                       mosaic_name,
                                       composite_projection,
                                       value_type,
                                       cell_size,
                                       '1',
                                       'MINIMUM',
                                       'FIRST'
                                       )
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
    print(f'\tExtracting merged raster to study area...')
    # Extract raster to study area
    extract_raster = ExtractByMask(mosaic_raster, study_area)
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
    # Delete mosaic raster if it exists
    if arcpy.Exists(mosaic_raster) == 1:
        arcpy.Delete_management(mosaic_raster)
    # End timing
    iteration_end = time.time()
    iteration_elapsed = int(iteration_end - iteration_start)
    iteration_success_time = datetime.datetime.now()
    # Report success
    print(
        f'\tCompleted at {iteration_success_time.strftime("%Y-%m-%d %H:%M")} (Elapsed time: {datetime.timedelta(seconds=iteration_elapsed)})')
    print('\t----------')
    out_process = 'Successfully created minimum raster.'
    return out_process
