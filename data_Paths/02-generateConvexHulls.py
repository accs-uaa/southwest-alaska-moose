# Objectives: Create convex hull polygon for every moose using the entirety of that moose's telemetry data (all years, all seasons). These polygons will be used in our habitat selection analysis to define a bounding geometry within which to generate a random initial location for our random paths. Can also be used to compare home range estimates with other studies in Alaska.

# Author: A. Droghini (adroghini@alaska.edu), Alaska Center for Conservation Science

# Load modules
import arcpy
import os

# Set root directory
drive = 'C:\\'
root_folder = 'ACCS_Work\\GMU_17_Moose'

# Set overwrite option
arcpy.env.overwriteOutput = True

# Define working geodatabase
geodatabase = os.path.join(drive, root_folder, 'GIS\\Moose_SouthwestAlaska.gdb')
arcpy.env.workspace = geodatabase # Needs to be set for Minimum Bounding Geometry code to run

# Define inputs
input_projection = 3338
input_csv = os.path.join(drive, root_folder, 'Data_03_Output\\animalData\\cleanedGPSdata.csv')
study_area = os.path.join(geodatabase, "StudyArea_Boundary")
x_coords = "Easting"
y_coords = "Northing"
unique_id = "deployment_id"

# Define outputs
output_layer = "telemetry_layer"
output_shapefile = "cleanedGPSdata"
temp_convex = os.path.join(geodatabase,"convexHulls_temp")
temp_convex_buffer = os.path.join(geodatabase, "convexHulls_buffer")
output_convex = os.path.join(geodatabase, "convexHulls")
buffer_dist = "2 Kilometers"

# Define the initial projection
initial_projection = arcpy.SpatialReference(input_projection)

# Convert CSV to ESRI Shapefile
print("Converting csv to shapefile...")

arcpy.MakeXYEventLayer_management(input_csv, x_coords, y_coords, output_layer, spatial_reference=initial_projection)
arcpy.conversion.FeatureClassToFeatureClass(in_features = output_layer, out_path = geodatabase, out_name = output_shapefile)

# Create convex hull polygon for each moose
print("Creating convex hull...")
arcpy.MinimumBoundingGeometry_management(output_shapefile,
                                         temp_convex, "CONVEX_HULL", group_option = "LIST", group_field = unique_id)

# Buffer by 2 kilometers
arcpy.analysis.Buffer(temp_convex, temp_convex_buffer, buffer_distance_or_field = buffer_dist)

# Clip to study area boundary
print("Clipping to study area...")
arcpy.analysis.Clip(temp_convex_buffer, study_area, output_convex)

# Remove temporary files
files_Delete = [temp_convex,temp_convex_buffer]

for i in files_Delete:
    if arcpy.Exists(i):
        arcpy.Delete_management(i)

print("Creating convex hulls complete...")