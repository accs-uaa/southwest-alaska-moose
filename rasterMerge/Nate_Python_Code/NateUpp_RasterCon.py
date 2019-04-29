import arcpy
import os
from arcpy import env

env.overwriteOutput = True

#Define path 
path = r'C:\Users\nupp3\OneDrive\Documents\ArcGIS\Projects\SouthwestAlaska_Floodplanes'

#Define in feature Mosaic
in_ras = 'Southwest_Alaska_Merge.tif'

#Define the full path of the in object
pre_mosaic= os.path.join(path, in_ras)

#Define out raster name
out_ras = 'Southwest_Alaska_Floodplains_Threshold.tif'


#Use arcpy.sa.Con to create a thresh
post_mosaic = arcpy.sa.Con(pre_mosaic, 1 , 0,"VALUE >= 0.42613")

#Save it
post_mosaic.save(os.path.join(path, out_ras))