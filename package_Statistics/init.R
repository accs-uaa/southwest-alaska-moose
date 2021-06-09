# Define directories
drive <- "C:"
root_folder <- "ACCS_Work/GMU_17_Moose"
input_dir <- file.path(drive, root_folder, "Data_01_Input")
pipeline_dir <- file.path(drive, root_folder, "Data_02_Pipeline")
output_dir <- file.path(drive, root_folder, "Data_03_Output")

# Data management packages
library(tidyverse)

# Statistics packages
library(survival)