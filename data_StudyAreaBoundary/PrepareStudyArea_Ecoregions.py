# Purpose: Create smoothed study area boundary that includes:
# Bristol Bay Lowlands + Ahklun Mountains Ecoregions (Nowacki et al. 2003)
# Togiak Refuge
# ADF&G Game Management Unit (GMU) 17

# Author: A. Droghini (adroghini@alaska.edu)
# Alaska Center for Conservation Science

# Import modules
import arcpy
import os

# Define root directory
drive = 'C:\\'
root_folder = 'Work\\GMU_17_Moose'

# Set workspace
geodatabase = os.path.join(drive, root_folder, 'GIS\\mooseHomeRanges.gdb')
arcpy.env.workspace = geodatabase

# Set overwrite option
arcpy.env.overwriteOutput = True

# Define inputs
input_polygon = "Alaska_UnifiedEcoregions"
input_projection = 3338
field_name = "COMMONER"
where_clause = """{} IN ('Bristol Bay Lowlands', 'Ahklun Mountains')""".format(arcpy.AddFieldDelimiters(input_polygon, field_name))

# Define output
output_polygon = "StudyArea_Ecoregions"

# Set projection
initial_projection = arcpy.SpatialReference(input_projection)

# Within Unified Ecoregions of Alaska shapefile, select 2 ecoregions:
# Bristol Bay Lowlands and Ahklun Mountains
study_area_ecoregions = arcpy.SelectLayerByAttribute_management(input_polygon,
                                        "NEW_SELECTION",
                                        where_clause)

# Write the selected features to a new feature class
arcpy.CopyFeatures_management(study_area_ecoregions, output_polygon)