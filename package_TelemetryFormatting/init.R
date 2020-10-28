# Data management packages
library(plyr)
library(tidyverse)
library(lubridate)
library(readxl)

# Spatial packages
library(geosphere)
library(sf)
library(sp)

# Animal movement packages
library(move)
library(ctmm)
library(tlocoh)

# Statistics packages
library(fitdistrplus)
library(circular)

# Functions
source("package_TelemetryFormatting/function-collarRedeploys.R")
source("package_TelemetryFormatting/function-subsetIDTimeLags.R")
source("package_TelemetryFormatting/function-plotOutliers.R")
