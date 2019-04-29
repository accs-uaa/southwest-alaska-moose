# Read the folder into a list,
# convert to a src list
# Combine all rasters using GDAL rasterio
# Spatial analyist arcpy.sa.con to seperate the combined raster into binary 1 0

import os
import gdal
import numpy
import PIL
from PIL import Image


import rasterio
from rasterio.merge import merge
from rasterio.plot import show
import glob
import matplotlib


#create a list for input files
input_list = []

#Set the directory for input files
in_dir = r'C:\Users\nupp3\OneDrive\Documents\ArcGIS\Projects\SouthwestAlaska_Floodplanes\output_rasters'


## An attempt to convert .img to .tif


# read in the files from directory
for root, dirs, files in os.walk(in_dir):
    for file in files:
        if file.endswith('.img'):
            img = Image.open(os.path.join(in_dir,file))
            f_name = os.path.splitext(os.path.basename(file))[0]
            img.save(f_name,'.tif')
            input_list.append(os.path.join(in_dir,file))
            

##



#Define out raster
out_ras = r'C:\Users\nupp3\OneDrive\Documents\ArcGIS\Projects\SouthwestAlaska_Floodplanes\Southwest_Alaska_merge.img'

#Search Criteria
search_criteria = "*.img" or "*.rrd"  # Having problems with missing data, so I included the .rrd's to see if it would help
for_glob = os.path.join(in_dir, search_criteria)


    

#Define the glob list input
dem_fps = glob.glob(for_glob)


#empty list for datafiles that will be part of mosaic
src_files_to_mosaic = []

#convert to src
for fp in dem_fps:
    src = rasterio.open(fp)
    src_files_to_mosaic.append(src)

src.dataset_mask()

#Merge all rasters, two outputs, a mosaic of all imgs, and the transform.
mosaic, out_trans = merge(src_files_to_mosaic)



#Copy the meta_data
m_data = src.meta.copy()

#Update meta
m_data.update({ "crs": ""
                "height": mosaic.shape[1],
                "width": mosaic.shape[2],
                "transform": out_trans
                
                }
            )


with rasterio.open(out_ras,"w",**m_data) as dest:
    dest.write(mosaic)



