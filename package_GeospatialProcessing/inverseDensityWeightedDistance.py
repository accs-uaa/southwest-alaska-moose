# -*- coding: utf-8 -*-
# ---------------------------------------------------------------------------
# Calculate inverse density-weighted distance
# Author: Timm Nawrocki
# Last Updated: 2020-11-01
# Usage: Must be executed in an ArcGIS Pro Python 3.6 installation.
# Description: "Calculate inverse density-weighted distance" is a function that calculates euclidean distance from raster values and divides distance by density (e.g., foliar cover).
# ---------------------------------------------------------------------------

# Define a function to calculate the inverse density-weighted distance
def calculate_idw_distance(**kwargs):
    """
    Description: calculates the distance/density of an input raster
    Inputs: 'work_geodatabase' -- path to a file geodatabase that will serve as the workspace
            'target_value' -- an integer value of the target foliar cover value
            'input_array' -- an array containing the input raster
            'output_array' -- an array containing the output raster
    Returned Value: Returns a raster dataset on disk containing the IDW Distance values
    Preconditions: requires an input foliar cover raster
    """

    # Import packages
    import arcpy
    from arcpy.sa import EucDistance
    from arcpy.sa import SetNull
    import datetime
    import time

    # Parse key word argument inputs
    work_geodatabase = kwargs['work_geodatabase']
    target_value = kwargs['target_value']
    input_raster = kwargs['input_array'][0]
    output_raster = kwargs['output_array'][0]

    # Set overwrite option
    arcpy.env.overwriteOutput = True

    # Set workspace
    arcpy.env.workspace = work_geodatabase

    # Use two thirds of cores on processes that can be split.
    arcpy.env.parallelProcessingFactor = "66%"

    # Set snap raster
    arcpy.env.snapRaster = input_raster

    # Start timing function
    iteration_start = time.time()
    print(f'\tNullifying raster values other than {target_value}...')
    # Set all values except for the target value to NODATA
    nulled_raster = SetNull(input_raster, 1, f'VALUE <> {target_value}')
    # End timing
    iteration_end = time.time()
    iteration_elapsed = int(iteration_end - iteration_start)
    iteration_success_time = datetime.datetime.now()
    # Report success
    print(f'\tCompleted at {iteration_success_time.strftime("%Y-%m-%d %H:%M")} (Elapsed time: {datetime.timedelta(seconds=iteration_elapsed)})')
    print('\t----------')

    # Start timing function
    iteration_start = time.time()
    print(f'\tCalculating euclidean distance to target value...')
    # Set all values except for the target value to NODATA
    distance_raster = EucDistance(nulled_raster)
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
    print(f'\tWeighting distances by inverse density...')
    # Set all values except for the target value to NODATA
    edge_raster = distance_raster / (target_value / 100)
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
    print(f'\tSaving edge raster to disk...')
    # Save the summed raster to disk
    arcpy.CopyRaster_management(edge_raster,
                                output_raster,
                                '',
                                '',
                                '-999',
                                'NONE',
                                'NONE',
                                '32_BIT_SIGNED',
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
    out_process = f'Successfully calculated inverse density-weighted distance where foliar cover = {target_value}%.'
    return out_process