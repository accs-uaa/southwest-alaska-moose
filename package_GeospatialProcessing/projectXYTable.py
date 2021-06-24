# -*- coding: utf-8 -*-
# ---------------------------------------------------------------------------
# Project xy table
# Author: Timm Nawrocki
# Last Updated: 2020-11-30
# Usage: Must be executed in an ArcGIS Pro Python 3.6 installation.
# Description: "Project xy table" is a function that converts xy data in a csv table to a feature class and projects the feature class.
# ---------------------------------------------------------------------------

# Define a function to convert and project xy coordinates from a csv table
def project_xy_table(**kwargs):
    """
    Description: projects xy coordinates from a table to a feature class
    Inputs: 'coordinate_fields' -- a list of the names of the fields for X and Y coordinates (in that order)
            'input_projection' -- the machine number for the input projection
            'output_projection' -- the machine number for the output projection
            'transformation' -- the geographic transformation to apply in the projection (can be null)
            'work_geodatabase' -- path to a file geodatabase that will serve as the workspace
            'input_array' -- an array containing the csv table
            'output_array' -- an array containing the output feature class
    Returned Value: Returns a feature class to disk in a shapefile or geodatabase
    Preconditions: requires an input csv table with latitude and longitude fields
    """

    # Import packages
    import arcpy
    import datetime
    import os
    import time

    # Parse key word argument inputs
    longitude_field = kwargs['coordinate_fields'][0]
    latitude_field = kwargs['coordinate_fields'][1]
    input_projection = kwargs['input_projection']
    output_projection = kwargs['output_projection']
    transformation = kwargs['transformation']
    work_geodatabase = kwargs['work_geodatabase']
    input_csv = kwargs['input_array'][0]
    output_feature = kwargs['output_array'][0]

    # Define intermediate files
    point_feature = os.path.join(work_geodatabase, 'point_feature')

    # Set overwrite option
    arcpy.env.overwriteOutput = True

    # Set workspace
    arcpy.env.workspace = work_geodatabase

    # Define the input and output projection
    initial_projection = arcpy.SpatialReference(input_projection)
    target_projection = arcpy.SpatialReference(output_projection)

    # Start timing function
    iteration_start = time.time()
    print(f'\tConverting point table to feature class...')
    # Convert xy coordinates to table feature class
    arcpy.management.XYTableToPoint(input_csv, point_feature, longitude_field, latitude_field, '', initial_projection)
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
    print(f'\tProjecting xy coordinates...')
    # Project xy coordinates
    arcpy.management.Project(point_feature, output_feature, target_projection, transformation, initial_projection, '', '', '')
    # Remove old coordinates and add new coordinates
    arcpy.management.DeleteField(output_feature, [longitude_field, latitude_field])
    arcpy.management.AddXY(output_feature)
    # Delete point feature if it exists
    if arcpy.Exists(point_feature) == 1:
        arcpy.management.Delete(point_feature)
    # End timing
    iteration_end = time.time()
    iteration_elapsed = int(iteration_end - iteration_start)
    iteration_success_time = datetime.datetime.now()
    # Report success
    print(
        f'\tCompleted at {iteration_success_time.strftime("%Y-%m-%d %H:%M")} (Elapsed time: {datetime.timedelta(seconds=iteration_elapsed)})')
    print('\t----------')
    out_process = 'Successfully converted and projected coordinates.'
    return out_process
