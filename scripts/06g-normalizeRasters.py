# Objectives: Normalize each raster so that values are between 0 and 1. The applied transformation maintains the original shape of the distribution.
# Also do some data management stuff:
# Reproject and snap to raster to align with other data products
# Set 0 values as No Data for mapping purposes
# Convert floating-point raster to integer by multiplying values by 100 to reduce file size.

# Author: A. Droghini (adroghini@alaska.edu), Alaska Center for Conservation Science
# Code for normalization transformation from: Evans J.S., J. Oakleaf, and S.A. Cushman. 2014. An ArcGIS Toolbox for Surface Gradient and Geomorphometric Modeling, version 2.0-0. URL: https://github.com/jeffreyevans/GradientMetrics Accessed: 05 Jun 2020.
# Code for data management stuff from: Nawrocki, T.W. 2020. Beringian Vegetation. Git Repository. Available: https://github.com/accs-uaa/beringian-vegetation

# Load modules
import arcpy
from arcpy import env
from arcpy.sa import *
import os

# Check out ArcGIS Spatial Analyst extension license
arcpy.CheckOutExtension("Spatial")

# Set root directory
drive = 'C:/'
root_folder = 'Users\\adroghini\Documents\GitHub\southwest-alaska-moose'
raster_folder = os.path.join(drive, root_folder, 'pipeline\\06f_exportAsRasters')

# Set overwrite option
env.overwriteOutput = True

# Define working geodatabase
geodatabase = os.path.join(drive, root_folder, 'gis/mooseHomeRanges.gdb')

# Create inputs
cell_size = 40
input_projection = 32604
output_projection = 3338
geographic_transformation = 'WGS_1984_(ITRF00)_To_NAD_1983'
conversion_factor = 100

# Define the initial projection
initial_projection = arcpy.SpatialReference(input_projection)
# Define the target projection
composite_projection = arcpy.SpatialReference(output_projection)

# Set snap raster
snap_raster = os.path.join(drive, root_folder, 'gis/northAmericanBeringia_TotalArea.tif')
arcpy.env.snapRaster = snap_raster

# List all raster files to be processed, including file path
filePath = "C:\\Users\\adroghini\\Documents\\GitHub\\southwest-alaska-moose\\pipeline\\06f_exportAsRasters"

# From @giltay: https://stackoverflow.com/questions/120656/directory-tree-listing-in-python
def listdir_fullpath(d):
    return [os.path.join(d, f) for f in os.listdir(d)]

files = listdir_fullpath(filePath)
files = files[0:2] # test

# Define export directory and names of final rasters
fileNames = os.listdir(filePath)
exportPath = "C:\\Users\\adroghini\\Documents\\GitHub\\southwest-alaska-moose\\gis\\test\\"

# Run function
for i in range(len(files)):
    r = files[i]
    maxVal = arcpy.GetRasterProperties_management(r, "MAXIMUM")
    minVal = arcpy.GetRasterProperties_management(r, "MINIMUM")
    descR = arcpy.Describe(r)
    maxRaster = CreateConstantRaster(maxVal, "FLOAT", descR.MeanCellHeight, descR.extent)

    if minVal != 0:
        minRaster = CreateConstantRaster(minVal, "FLOAT", descR.MeanCellHeight, descR.extent)
        outRaster = (r - minRaster) / (maxRaster - minRaster)
    else:
        outRaster = r / maxRaster

    # Multiply values by 100 and round to integer
    # Use 0.5 to prevent truncation
    integer_raster = Int((Raster(outRaster) * conversion_factor) + 0.5)

    # Set values of 0 as No Data
    null_raster = SetNull("integer_raster", "integer_raster", "VALUE = 0")

    # Define output raster
    final_raster = (exportPath + fileNames[i])

    # Reproject raster
    arcpy.ProjectRaster_management(null_raster,
                                   final_raster,
                                   composite_projection,
                                   'BILINEAR',
                                   cell_size,
                                   geographic_transformation)