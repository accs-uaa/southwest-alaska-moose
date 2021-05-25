# Purpose: Create smoothed study area boundary that includes Bristol Bay Lowlands + Ahklun Mountains (Alaska Unified Ecoregions from Nowacki et al. 2003), Togiak National Wildlife Refuge, and ADF&G Game Management Unit (GMU) 17.

# This script:
# 1) Selects the Bristol Bay Lowlands and the Ahklun Mountains from the Alaska Unified Ecoregions shapefile. The output is a polygon that contains only those 2 ecoregions.
# 2) Smooths and buffers GMU 17 polygon to minimize gaps and jagged joins.
# 3) Smooths and buffers Togiak NWR polygon.
# 4) Merge all 3 polygons, transform to raster, and clip to mainland Alaska only.
# 5) Convert back to polygon for cartographic purposes.

# Author: A. Droghini (adroghini@alaska.edu)
# Alaska Center for Conservation Science

# Import modules
import arcpy
from arcpy.sa import *
import os

# Check out ArcGIS Spatial Analyst extension license
arcpy.CheckOutExtension("Spatial")

# Define root directory
drive = 'C:\\'
root_folder = 'ACCS_Work\\GMU_17_Moose'

# Define GIS folder and set workspace
data_folder = os.path.join(drive, root_folder, 'GIS')
geodatabase = os.path.join(data_folder, 'Moose_SouthwestAlaska.gdb')
arcpy.env.workspace = geodatabase

# Set overwrite option
arcpy.env.overwriteOutput = True

# Set snap raster and cell size
snap_raster = os.path.join(data_folder, 'northAmericanBeringia_ModelArea.tif')
arcpy.env.snapRaster = snap_raster
arcpy.env.cellSize = snap_raster

# Define inputs
input_projection = 3338

input_ecoregion = "Alaska_UnifiedEcoregions"
input_GMU17 = "SouthwestAlaska_GMU17"
input_Togiak = "SouthwestAlaska_Togiak"

# Define Select by Attributes parameters
field_name = "COMMONER"
where_clause = """{} IN ('Bristol Bay Lowlands', 'Ahklun Mountains')""".format(arcpy.AddFieldDelimiters(input_ecoregion, field_name))

# Define buffer and smoothing tolerances
# Buffer values were chosen to minimize gaps and non-smooth boundaries between the polygons
tolerance_10km = 10000
buffer_6km = "6000 Meters"
buffer_1km = "1000 Meters"

# Define outputs
output_ecoregion = "StudyArea_Ecoregions"

temp_smooth_GMU17 = "StudyArea_GMU17_Smooth"
temp_smooth_Togiak = "StudyArea_Togiak_Smooth"
temp_merge_all = "StudyArea_Merged"
temp_buffer_all = "StudyArea_Buffer"

output_GMU17 = "StudyArea_GMU17_Smooth_Buffer"
output_Togiak = "StudyArea_Togiak_Smooth_Buffer"
output_final_polygon = "StudyArea_Boundary"

output_raster = os.path.join(drive, root_folder, 'Data_01_Input\\southwestAlaska_StudyArea.tif')

# Define the initial projection
initial_projection = arcpy.SpatialReference(input_projection)

# Prepare ecoregions polygon
# Within Unified Ecoregions of Alaska shapefile, select only Bristol Bay Lowlands and Ahklun Mountains and write selection to new feature class.
study_area_ecoregions = arcpy.SelectLayerByAttribute_management(input_ecoregion,
                                        "NEW_SELECTION",
                                        where_clause)

arcpy.CopyFeatures_management(study_area_ecoregions, output_ecoregion)

# Prepare GMU 17 polygon
arcpy.cartography.SmoothPolygon(input_GMU17, temp_smooth_GMU17, "PAEK", tolerance_10km)
arcpy.analysis.Buffer(temp_smooth_GMU17, output_GMU17, buffer_6km, method = "PLANAR")

# Prepare Togiak polygon
# Use same settings as GMU 17
arcpy.cartography.SmoothPolygon(input_Togiak, temp_smooth_Togiak, "PAEK", tolerance_10km)
arcpy.analysis.Buffer(temp_smooth_Togiak, output_Togiak, buffer_6km, method = "PLANAR")

# Prepare final polygon
# Merge all polygons, add 1 km buffer, dissolve, and smooth
arcpy.management.Merge([output_ecoregion,output_GMU17,output_Togiak], temp_merge_all, "ADD_SOURCE_INFO")
arcpy.analysis.Buffer(temp_merge_all, temp_buffer_all, buffer_1km, method = "PLANAR", dissolve_option = "ALL")
arcpy.cartography.SmoothPolygon(temp_buffer_all, output_final_polygon, "PAEK", tolerance_10km)

# Create raster by clipping raster of North American Beringia to study area extent
# Removes anything that is off the mainland i.e., water, islands
# For use in modelling and analyses
mask_raster = ExtractByMask(snap_raster, output_final_polygon)

arcpy.management.CopyRaster(mask_raster, output_raster, pixel_type="1_BIT")

# Convert back to polygon for cartographic purposes
# Overwrite output_final_polygon
arcpy.conversion.RasterToPolygon(output_raster, output_final_polygon)

# Delete intermediate products
arcpy.Delete_management([temp_smooth_GMU17,temp_smooth_Togiak,temp_merge_all, temp_buffer_all])