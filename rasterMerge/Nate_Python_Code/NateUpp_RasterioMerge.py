# Read the folder into a list,
# convert to a src list
# Combine all rasters using GDAL rasterio
# Spatial analyist arcpy.sa.con to seperate the combined raster into binary 1 0

import os
import gdal
import numpy

import rasterio
from rasterio.merge import merge



#create a list for input files
input_list = []

#Set the directory for input files
tif_directory = r'C:\Users\nupp3\OneDrive\Documents\ArcGIS\Projects\SouthwestAlaska_Floodplanes\output_tifs'


#Define out raster
output_raster = r'C:\Users\nupp3\OneDrive\Documents\ArcGIS\Projects\SouthwestAlaska_Floodplanes\Southwest_Alaska_Merge.tif'

# Create a list of Arctic DEM raster tiles
tif_list = []
for file in os.listdir(tif_directory):
    if file.endswith('tif'):
        tif_list.append(os.path.join(tif_directory, file))


#empty list for datafiles that will be part of mosaic
src_files_to_mosaic = []

#Read in and open as src rasterio
for fp in tif_list:
    src = rasterio.open(fp)
    src_files_to_mosaic.append(src)


mosaic, out_trans = merge(src_files_to_mosaic)
out_meta = src.meta.copy()
out_meta.update({"driver": "GTiff",
                 "height": mosaic.shape[1],
                 "width": mosaic.shape[2],
                 "transform": out_trans
                })
                
with rasterio.open(output_raster, 'w', **out_meta) as dest:
    dest.write(mosaic)

