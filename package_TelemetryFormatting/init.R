# Define file directories
input_dir <- "C:/Work/GMU_17_Moose/data_01_Input/"
pipeline_dir <- "C:/Work/GMU_17_Moose/data_02_Pipeline/"
output_dir <- "C:/Work/GMU_17_Moose/data_03_Output/"

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