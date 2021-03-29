# -*- coding: utf-8 -*-
# ---------------------------------------------------------------------------
# Extract features to raster
# Author: Timm Nawrocki
# Last Updated: 2020-12-22
# Usage: Must be executed in an ArcGIS Pro Python 3.6 installation.
# Description: "Extract features to raster" is a function that selects features by user-defined attribute and converts the selected features to raster.
# ---------------------------------------------------------------------------

# Define a function to convert selected features to raster
def extract_features_to_raster(**kwargs):
    """
    Description: selects features by attribute and converts to raster
    Inputs: 'cell_size' -- a cell size for the output raster
            'input_projection' -- the machine number for the input projection
            'output_projection' -- the machine number for the output projection
            'geographic_transformation -- the string representation of the appropriate geographic transformation (blank if none required)
            'where_clause' -- a SQL query that will define the selected features
            'work_geodatabase' -- path to a file geodatabase that will serve as the workspace
            'input_array' -- an array containing the study area raster (must be first), and the target feature class (must be second)
            'output_array' -- an array containing the output raster
    Returned Value: Returns a raster dataset
    Preconditions: the initial raster must exist on disk and the boundary and grid datasets must be created manually
    """

    # Import packages
    import arcpy
    from arcpy.sa import Con
    from arcpy.sa import IsNull
    from arcpy.sa import Raster
    import datetime
    import os
    import time

    # Parse key word argument inputs
    cell_size = kwargs['cell_size']
    input_projection = kwargs['input_projection']
    output_projection = kwargs['output_projection']
    geographic_transformation = kwargs['geographic_transformation']
    where_clause = kwargs['where_clause']
    value_field = kwargs['value_field']
    work_geodatabase = kwargs['work_geodatabase']
    study_area = kwargs['input_array'][0]
    input_feature = kwargs['input_array'][1]
    output_raster = kwargs['output_array'][0]

    # Define intermediate datasets
    feature_projected = os.path.join(work_geodatabase, 'feature_projected')
    intermediate_raster = os.path.join(os.path.split(output_raster)[0], 'feature_raster.tif')

    # Set overwrite option
    arcpy.env.overwriteOutput = True

    # Set workspace
    arcpy.env.workspace = work_geodatabase

    # Set snap raster
    arcpy.env.snapRaster = study_area

    # Define the input and output projection
    initial_projection = arcpy.SpatialReference(input_projection)
    target_projection = arcpy.SpatialReference(output_projection)

    # Start timing function
    print('\tProjecting feature class...')
    iteration_start = time.time()
    # Project feature class
    arcpy.management.Project(input_feature,
                             feature_projected,
                             target_projection,
                             geographic_transformation,
                             initial_projection,
                             'NO_PRESERVE_SHAPE',
                             '',
                             'NO_VERTICAL'
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
    print('\tConverting select features to raster...')
    iteration_start = time.time()
    # Select data from feature class
    input_layer = arcpy.management.SelectLayerByAttribute(feature_projected,
                                                          'NEW_SELECTION',
                                                          where_clause,
                                                          'NON_INVERT'
                                                          )
    # Convert features to raster
    arcpy.conversion.FeatureToRaster(input_layer,
                                     value_field,
                                     intermediate_raster,
                                     cell_size
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
    print('\tConverting values to one...')
    iteration_start = time.time()
    # Convert values to one and null to zero
    nonull_raster = Con(IsNull(Raster(intermediate_raster)), 0, 1)
    arcpy.CopyRaster_management(nonull_raster,
                                output_raster,
                                '',
                                '0',
                                '-128',
                                'NONE',
                                'NONE',
                                '8_BIT_SIGNED',
                                'NONE',
                                'NONE',
                                'TIFF',
                                'NONE',
                                'CURRENT_SLICE',
                                'NO_TRANSPOSE')
    # Delete intermediate datasets if each exists
    if arcpy.Exists(feature_projected) == 1:
        arcpy.management.Delete(feature_projected)
    if arcpy.Exists(intermediate_raster) == 1:
        arcpy.management.Delete(intermediate_raster)
    # End timing
    iteration_end = time.time()
    iteration_elapsed = int(iteration_end - iteration_start)
    iteration_success_time = datetime.datetime.now()
    # Report success
    print(
        f'\tCompleted at {iteration_success_time.strftime("%Y-%m-%d %H:%M")} (Elapsed time: {datetime.timedelta(seconds=iteration_elapsed)})')
    print('\t----------')
    out_process = f'\tSuccessfully extracted raster data to boundary.'
    return out_process
