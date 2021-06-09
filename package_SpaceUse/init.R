# Define directories
drive <- "C:"
root_folder <- "ACCS_Work/GMU_17_Moose"
input_dir <- file.path(drive, root_folder, "Data_01_Input")
pipeline_dir <- file.path(drive, root_folder, "Data_02_Pipeline")
output_dir <- file.path(drive, root_folder, "Data_03_Output")
geoDB <- file.path(drive, root_folder, "GIS/Moose_SouthwestAlaska.gdb")

# Data management packages
library(plyr)
library(tidyverse)
library(lubridate)
library(readxl)

# Spatial packages
library(raster)
library(rgdal)
library(sf)

# Time series packages
library(zoo)

# Animal movement packages
library(move)
library(ctmm)
library(tlocoh) # for animating movement paths. Can also use moveVis but I was having problem aligning my data and I wanted something quick
library(adehabitatLT)