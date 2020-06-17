# Objectives: Calculate Euclidean distance between seasonal home ranges. Doing so will require us to: 1) reclassify existing rasters; 2) convert raster to polygon; 3) convert polygon to points; 4) calculate distance ...

# Author: A. Droghini (adroghini@alaska.edu), Alaska Center for Conservation Science

########### Load modules and set environment ###########
# Load modules
import arcpy
from arcpy.sa import Reclassify
from arcpy.sa import RemapRange
import os
import time

# Check out ArcGIS Spatial Analyst extension license
arcpy.CheckOutExtension("Spatial")

# Set root directory
drive = 'C:\\'
root_folder = 'Users\\adroghini\\Documents\\GitHub\\southwest-alaska-moose\\gis'
raster_folder = os.path.join(drive, root_folder, 'normalizedRasters')

# Set overwrite option
arcpy.env.overwriteOutput = True

# Define working geodatabase
geodatabase = os.path.join(drive, root_folder, 'mooseHomeRanges.gdb')

# Set snap raster
snap_raster = os.path.join(drive, root_folder, 'northAmericanBeringia_ModelArea.tif')
arcpy.env.snapRaster = snap_raster

########### List files and set local variables ###########

# List all raster files
arcpy.env.workspace = raster_folder
files = arcpy.ListRasters("*", "TIF")

raster_list = []
for raster in files:
    rasterPath = os.path.join(raster_folder,raster)
    raster_list.append(rasterPath)

# Set local variables
# Reclassify all values from 1 to 100 as 1
reclassField = "Value"
remap = RemapRange([[1,100,1]])
outPolygon = os.path.join(geodatabase, "outPolygon")

# Set workspace environment
arcpy.env.workspace = geodatabase

# Start timing
iteration_start = time.time()

##### Convert rasters to centroids
for inputRaster in raster_list:

    # Create file names
    modelName = os.path.split(os.path.splitext(inputRaster)[0])[1]
    mooseName = str.split(modelName, sep="_")[0]
    outCentroid = os.path.join(geodatabase, "temp_" + modelName)

    print(f'\tConverting raster to centroid from {modelName} input raster...')

    # Reclassify raster
    outReclassify = Reclassify(inputRaster, reclassField, remap)

    # Convert raster to polygon
    arcpy.RasterToPolygon_conversion(outReclassify, outPolygon, raster_field=reclassField, simplify="NO_SIMPLIFY",
                                 create_multipart_features="SINGLE_OUTER_PART")

    # Convert polygon to point
    arcpy.FeatureToPoint_management(outPolygon, outCentroid, point_location="CENTROID")
    arcpy.Delete_management(outPolygon)

    # Add model name and moose ID as fields
    arcpy.AddField_management(outCentroid, "modelName", field_type = "TEXT", field_length=30,
                              field_is_nullable="NULLABLE")
    arcpy.AddField_management(outCentroid, "mooseID", field_type = "TEXT", field_length=10,
                              field_is_nullable="NULLABLE")

    fields = ['modelName', 'mooseID']

    with arcpy.da.UpdateCursor(outCentroid, fields) as cursor:
        for row in cursor:
            row[0] = modelName
            row[1] = mooseName
            cursor.updateRow(row)

##### End loop / timing
iteration_end = time.time()
iteration_elapsed = int(iteration_end - iteration_start)
iteration_success_time = datetime.datetime.now()
print(f'\tCompleted at {iteration_success_time.strftime("%Y-%m-%d %H:%M")} (Elapsed time: {datetime.timedelta(seconds=iteration_elapsed)})')
print('\t----------')

# Merge all centroid shapefiles into a single feature class

# List all centroids to merge
centroids = arcpy.ListFeatureClasses("temp_*",feature_type="Point")
allCentroids = os.path.join(geodatabase,"allCentroids")

arcpy.Merge_management(inputs=centroids, output=allCentroids)

##### Calculate distances between centroids

# Set parameters
searchRadius = '1000 Kilometers'

# Calculate distances
# The resulting NEAR_DIST value is in the linear unit of the input features coordinate system
arcpy.Near_analysis(in_features=allCentroids, near_features=allCentroids, search_radius=searchRadius, location= 'NO_LOCATION',
                                 angle= 'NO_ANGLE')

# Append modelName field so that you have more than just NearID to go on
arcpy.TableToTable_conversion(in_rows=allCentroids, out_path=geodatabase, out_name="joinTable")
joinTable = os.path.join(geodatabase,"joinTable")
arcpy.JoinField_management(in_data=allCentroids,in_field="NEAR_FID",join_table=joinTable,join_field="OBJECTID",fields=["modelName","mooseID"])

# Delete redundant fields
fieldsToDelete = ["Id","gridcode","ORIG_FID"]

# Delete intermediate products
arcpy.DeleteField_management(allCentroids, fieldsToDelete)

arcpy.Delete_management(joinTable)

# Delete all individual centroid points
filesToDelete = arcpy.ListFeatureClasses("temp_*",feature_type="Point")

for object in filesToDelete:
    arcpy.Delete_management(object)

# Export distance results as .csv table
exportPath = "C:\\Users\\adroghini\\Documents\\GitHub\\southwest-alaska-moose\\pipeline\\07_resultsHomeRangeDistance"
arcpy.TableToTable_conversion(in_rows=allCentroids, out_path=exportPath, out_name="allDistances.csv")