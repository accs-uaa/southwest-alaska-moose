# Define file directories
input_dir <- "C:/Work/GMU_17_Moose/data_01_Input/"
pipeline_dir <- "C:/Work/GMU_17_Moose/data_02_Pipeline/"
output_dir <- "C:/Work/GMU_17_Moose/data_03_Output/"
geoDB <- "C:/Work/GMU_17_Moose/gis/mooseHomeRanges.gdb"

# Data management packages
library(plyr)
library(tidyverse)
library(data.table)

# Animal movement packages
library(move)
library(amt)

# Statistics packages
library(MASS)
library(circular)

# Spatial packages
library(sp)
library(raster)
library(rgdal)