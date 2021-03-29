# -*- coding: utf-8 -*-
# ---------------------------------------------------------------------------
# Convert Paths
# Author: Timm Nawrocki
# Last Updated: 2020-03-25
# Usage: Must be executed in an ArcGIS Pro Python 3.6 installation.
# Description: "Convert Paths" converts a set of xy points stored in a csv table to a feature class stored in a geodatabase.
# ---------------------------------------------------------------------------

# Import packages
import arcpy
import os

# Set root directory
drive = 'C:\\'
root_folder = 'Users\\adroghini\\Documents\\GitHub\\southwest-alaska-moose'

# Set overwrite option
arcpy.env.overwriteOutput = True

# Define geodatabase
geodatabase = os.path.join(drive, root_folder, 'gis\\mooseHomeRanges.gdb')

# Define input data
input_csv = os.path.join(drive, root_folder, 'pipeline\\paths\\allPaths.csv')
input_projection = 3338
x_coords = "x"
y_coords = "y"

# Define output shapefile
output_layer = "allPaths_layer"
output_shapefile = "allPaths_AKALB"

# Define the initial projection
initial_projection = arcpy.SpatialReference(input_projection)

# Convert csv to shapefile
arcpy.MakeXYEventLayer_management(input_csv, x_coords, y_coords, output_layer, spatial_reference=initial_projection)
arcpy.conversion.FeatureClassToFeatureClass(in_features=output_layer, out_path=geodatabase, out_name=output_shapefile)
