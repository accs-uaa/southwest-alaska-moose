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

# Functions
source("package_TelemetryFormatting/function-collarRedeploys.R")
source("package_TelemetryFormatting/function-subsetIDTimeLags.R")
source("package_TelemetryFormatting/function-plotOutliers.R")
