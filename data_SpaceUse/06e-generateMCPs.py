# Objectives: Create convex hull polygon for every individual moose for every year. These polygons will be used in our habitat selection analysis to define a bounding geometry within which to generate a random initial location for our random paths. Can also be used to compare home range estimates with other studies in Alaska.

# Author: A. Droghini (adroghini@alaska.edu), Alaska Center for Conservation Science

# Load modules
import arcpy
import os

# Set root directory
drive = 'C:\\'
root_folder = 'Users\\adroghini\\Documents\\GitHub\\southwest-alaska-moose'

# Set overwrite option
arcpy.env.overwriteOutput = True

# Define working geodatabase
geodatabase = os.path.join(drive, root_folder, 'gis\\mooseHomeRanges.gdb')
arcpy.env.workspace = geodatabase # Needs to be set for Minimum Bounding Geometry code to run

# Define inputs
input_projection = 3338
input_csv = os.path.join(drive, root_folder, 'output\\telemetryData\\cleanedGPSdata.csv')
x_coords = "Easting"
y_coords = "Northing"
unique_id = "mooseYear"

# Define outputs
output_layer = "telemetry_layer"
output_shapefile = "cleanedGPSdata"
output_polygon = os.path.join(geodatabase,"convexHulls")

# Define the initial projection
initial_projection = arcpy.SpatialReference(input_projection)

# Convert CSV to ESRI Shapefile
arcpy.MakeXYEventLayer_management(input_csv, x_coords, y_coords, output_layer, spatial_reference=initial_projection)
arcpy.conversion.FeatureClassToFeatureClass(in_features = output_layer, out_path = geodatabase, out_name = output_shapefile)

# Create convex hull polygon for each moose
arcpy.MinimumBoundingGeometry_management(output_shapefile,
                                         output_polygon, "CONVEX_HULL", group_option = "LIST", group_field = unique_id)