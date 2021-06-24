# -*- coding: utf-8 -*-
# ---------------------------------------------------------------------------
# Sum rasters
# Author: Timm Nawrocki
# Last Updated: 2020-11-01
# Usage: Must be executed in an ArcGIS Pro Python 3.6 installation.
# Description: "Sum rasters" is a function that sums n number of rasters and returns a single output raster.
# ---------------------------------------------------------------------------

# Define a function to sum n number of rasters
def sum_rasters(**kwargs):
    """
    Description: calculates the sum of all input rasters in an array
    Inputs: 'work_geodatabase' -- path to a file geodatabase that will serve as the workspace
            'input_array' -- an array containing a raster study area (must be first) and all input rasters to be summed
            'output_array' -- an array containing the output summed raster
    Returned Value: Returns a raster dataset on disk containing the summed values
    Preconditions: requires existing numeric raster datasets of the same value type
    """

    # Import packages
    import arcpy
    from arcpy.sa import Con
    from arcpy.sa import ExtractByMask
    from arcpy.sa import IsNull
    from arcpy.sa import Raster
    import datetime
    import time

    # Parse key word argument inputs
    work_geodatabase = kwargs['work_geodatabase']
    input_rasters = kwargs['input_array']
    study_area = input_rasters.pop(0)
    output_raster = kwargs['output_array'][0]
    input_length = len(input_rasters)

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
    print(f'\tAdding rasters 1 and 2 of {input_length}...')
    # Prepare the first two rasters in the input list
    raster_one = input_rasters.pop(0)
    raster_two = input_rasters.pop(0)
    # Convert null values to zeros
    cover_one = Con(IsNull(Raster(raster_one)), 0, Raster(raster_one))
    cover_two = Con(IsNull(Raster(raster_two)), 0, Raster(raster_two))
    # Sum the first two rasters in the input list
    summed_raster = cover_one + cover_two
    # End timing
    iteration_end = time.time()
    iteration_elapsed = int(iteration_end - iteration_start)
    iteration_success_time = datetime.datetime.now()
    # Report success
    print(f'\tCompleted at {iteration_success_time.strftime("%Y-%m-%d %H:%M")} (Elapsed time: {datetime.timedelta(seconds=iteration_elapsed)})')
    print('\t----------')

    # If the remaining input raster list length is greater than zero, iteratively add other rasters
    if len(input_rasters) > 0:
        for raster in input_rasters:
            # Start timing function
            iteration_start = time.time()
            raster_number = input_rasters.index(raster) + 3
            print(f'\tAdd raster {raster_number} of {input_length}...')
            # Convert null values to zeros
            cover_raster = Con(IsNull(Raster(raster)), 0, Raster(raster))
            # Add raster to the previous sum
            summed_raster = summed_raster + cover_raster
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
    print(f'\tExtracting the summed raster to study area...')
    # Extract the summed raster to the study area
    extract_raster = ExtractByMask(summed_raster, study_area)
    # End timing
    iteration_end = time.time()
    iteration_elapsed = int(iteration_end - iteration_start)
    iteration_success_time = datetime.datetime.now()
    # Report success
    print(
        f'\tCompleted at {iteration_success_time.strftime("%Y-%m-%d %H:%M")} (Elapsed time: {datetime.timedelta(seconds=iteration_elapsed)})')
    print('\t----------')

    # Determine raster type and no data value
    no_data_value = Raster(raster_one).noDataValue
    type_number = arcpy.management.GetRasterProperties(raster_one, 'VALUETYPE').getOutput(0)
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
    print(f'\tSaving summed raster to disk as {value_type} raster with NODATA value of {no_data_value}...')
    # Start timing function
    iteration_start = time.time()
    # Save the summed raster to disk
    arcpy.management.CopyRaster(extract_raster,
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
    arcpy.management.BuildRasterAttributeTable(output_raster, "Overwrite")
    # End timing
    iteration_end = time.time()
    iteration_elapsed = int(iteration_end - iteration_start)
    iteration_success_time = datetime.datetime.now()
    # Report success
    print(
        f'\tCompleted at {iteration_success_time.strftime("%Y-%m-%d %H:%M")} (Elapsed time: {datetime.timedelta(seconds=iteration_elapsed)})')
    print('\t----------')
    out_process = 'Successfully summed rasters.'
    return out_process
