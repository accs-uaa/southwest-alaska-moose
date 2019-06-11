# SSF Modeling
# AniMove 2019
# Paul Schuette, June 11, 2019

# Following the amt package vignette

# Download rasters for the NLCD landcover 2011 (https://www.mrlc.gov/data/nlcd-2011-land-cover-alaska-0)
# and the ACCS Vegetation layer (https://composite.accs.axiomdatascience.com/#map)


setwd("T:/Zoology/Paul/ADF&G Region4/southwest-alaska-moose/telemetry")

# Load packages
library(raster)
library(lubridate)
library(amt)

#load data
#dat <- read_csv("data/Martes pennanti LaPoint New York.csv") %>%
 # filter(!is.na(`location-lat`)) %>%
#  select(x = `location-long`, y = `location-lat`,
 #        t = `timestamp`, id = `tag-local-identifier`) %>%
#  filter(id %in% c(1465, 1466, 1072, 1078, 1016, 1469))
#dat_1 <- dat %>% filter(id == 1016)

#Load movestack file that was saved during the loading and cleaning of moose data from Movebank
#This files contains all 20 animals

mooose.mov <- load("moose.mov.RData")
str(moose.mov)

#Convert MoveStack to amt::track object
#=====================
#  Currently, there is no conversion function from move::moveStack to amt::track implemented, so we do it by hand
# I adopted this from Bjoern's Animove script "buffalo_example_amt_2019.Rmd"
track_list <- lapply(split(moose.mov), 
                     function(mv) amt::mk_track(as.data.frame(mv),
                                                coords.x1, coords.x2, timestamps, 
                                                id = individual.local.identifier,
                                                crs = sp::CRS("+init=epsg:3338")))

moose_tracks <- bind_rows(track_list)

# We need to call mk_track again to add the projection information.
# This gets lost in the bind_rows function
moose_tracks <- amt::mk_track(moose_tracks, x_, y_, t_, id = id, crs = sp::CRS("+init=epsg:3338"))

#Always inspect your data: summary statistics
#============================================
summary(moose_tracks)

#Can also just load one animal and then convert
M1718H20 <- filter(moose_tracks, id == "M1718H20")
summary(M1718H20)

summarize_sampling_rate(M1718H20)

#Resample at 2 hr intervals
stps <- track_resample(M1718H20, rate = hours(2), tolerance = minutes(15)) %>%
  filter_min_n_burst(min_n = 3) %>% steps_by_burst() %>%
  time_of_day(include.crepuscule = FALSE)