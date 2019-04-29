import arcpy
import os


raster_directory = r'C:\Users\nupp3\OneDrive\Documents\ArcGIS\Projects\SouthwestAlaska_Floodplanes\output_rasters'

tif_directory = r'C:\Users\nupp3\OneDrive\Documents\ArcGIS\Projects\SouthwestAlaska_Floodplanes\output_tifs'

# Create a list of Arctic DEM raster tiles
tile_list = []
for file in os.listdir(raster_directory):
    if file.endswith('img'):
        tile_list.append(os.path.join(raster_directory, file))
        
# Convert to tif
for file in tile_list:
    out_raster = os.path.join(tif_directory, os.path.splitext(os.path.split(file)[1])[0] + '.tif')
    arcpy.CopyRaster_management(file, out_raster, '', '', '', '', '', '32_BIT_FLOAT', 'NONE', 'NONE')