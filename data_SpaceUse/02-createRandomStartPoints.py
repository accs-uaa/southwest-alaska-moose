# ---------------------------------------------------------------------------
# Create random start points.
# Author: A. Droghini (adroghini@alaska.edu), Alaska Center for Conservation Science
# Description: Generates 100 random points within the convex hull polygons that we created (coarsely representing the annual home range of individual female moose).
# Purpose: We'll use these points as starting locations for generating random paths. We'll compare the vegetation and topographical covariates of these random paths to covariates of observed paths.
# ---------------------------------------------------------------------------

# Import packages
import arcpy
import os
import pandas
# Set root directory
drive = 'C:\\'
root_folder = 'Users\\adroghini\\Documents\\GitHub\\southwest-alaska-moose'

# Set overwrite option
arcpy.env.overwriteOutput = True

# Set workspace
geodatabase = os.path.join(drive, root_folder, 'gis\\mooseHomeRanges.gdb')
arcpy.env.workspace = geodatabase

# Set projection
input_projection = 3338
initial_projection = arcpy.SpatialReference(input_projection)

#  Define outputs
output_name = "randomStartPts"
boundaries = "convexHulls"
number_of_pts = 100

# Define inputs
# We want to be able to retrace each random point to the ID of the moose/home range it was generated from.
input_csv = os.path.join(drive, root_folder, 'output\\telemetryData\\cleanedGPSdata.csv')

# Create list of unique moose IDs
# Repeat this list as many times as there are points
gpsData = pandas.read_csv(input_csv)
unique_id = gpsData.deployment_id.unique()
unique_id = unique_id.repeat(number_of_pts)

# Create 100 random points within the boundaries of the convex hull polygons that represent moose home ranges
arcpy.CreateRandomPoints_management(out_path = geodatabase, out_name = output_name, constraining_feature_class = boundaries, number_of_points_or_field = number_of_pts)

# Add coordinate fields
arcpy.AddXY_management(output_name)

# Still need to code ----
# Create fields for random values
fieldInt = "fieldInt"
fieldFlt = "fieldFlt"
arcpy.AddField_management(outName, fieldInt, "LONG")  # add long integer field
arcpy.AddField_management(outName, fieldFlt, "FLOAT") # add float field