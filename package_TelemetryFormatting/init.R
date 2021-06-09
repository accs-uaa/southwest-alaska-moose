# Define directories
drive <- "C:"
root_folder <- "ACCS_Work/GMU_17_Moose"
input_dir <- file.path(drive, root_folder, "Data_01_Input")
pipeline_dir <- file.path(drive, root_folder, "Data_02_Pipeline")
output_dir <- file.path(drive, root_folder, "Data_03_Output")

# Data management packages
library(plyr)
library(tidyverse)
library(lubridate)
library(readxl)

# Spatial packages
library(geosphere)
library(sf)
library(sp)
library(ggmap)

# Animal movement packages
library(move)
library(ctmm)
library(tlocoh)

# Statistics packages
library(MASS)
library(circular)