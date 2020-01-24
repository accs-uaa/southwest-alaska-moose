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
library(ggplot2)
library(RStoolbox)
library(animove)
library(survival)
library(MASS)
library(dplyr)
library(nlme)
library(pbs)
library(circular)
library(CircStats)
library(ssf)
library(move)
library(ctmm)

#load data
#dat <- read_csv("data/Martes pennanti LaPoint New York.csv") %>%
 # filter(!is.na(`location-lat`)) %>%
#  select(x = `location-long`, y = `location-lat`,
 #        t = `timestamp`, id = `tag-local-identifier`) %>%
#  filter(id %in% c(1465, 1466, 1072, 1078, 1016, 1469))
#dat_1 <- dat %>% filter(id == 1016)

#Load movestack file that was saved during the loading and cleaning of moose data from Movebank
#This files contains all 20 animals

#mooose.mov <- load("moose.mov.RData")
#mooose.mov.prj <- 

load("moose.mov.prj.RData")
str(moose.mov.prj)

#moose.mov.prj[["M1718H20"]]

names(mooose.mov.prj)

class(moose.mov.prj)
#Convert MoveStack to amt::track object
#=====================
#  Currently, there is no conversion function from move::moveStack to amt::track implemented, so we do it by hand
# I adopted this from Bjoern's Animove script "buffalo_example_amt_2019.Rmd"
track_list <- lapply(split(moose.mov.prj), 
                     function(mv) amt::mk_track(as.data.frame(mv),
                                                coords.x1, coords.x2, timestamps, 
                                                id = individual.local.identifier,
                                                crs = sp::CRS("+proj=aea +lat_1=55 +lat_2=65 +lat_0=50 +lon_0=-154 +x_0=0 +y_0=0 +datum=NAD83 +units=m +no_defs +ellps=GRS80 +towgs84=0,0,0")))

moose_tracks <- bind_rows(track_list)

# We need to call mk_track again to add the projection information.
# This gets lost in the bind_rows function
moose_tracks <- amt::mk_track(moose_tracks, x_, y_, t_, id = id, crs = sp::CRS("+proj=aea +lat_1=55 +lat_2=65 +lat_0=50 +lon_0=-154 +x_0=0 +y_0=0 +datum=NAD83 +units=m +no_defs +ellps=GRS80 +towgs84=0,0,0"))

#Always inspect your data: summary statistics
#============================================
summary(moose_tracks)
# X30102 tag id, animal id is M1718H20
#Can also just load one animal and then convert
M1718H20 <- filter(moose_tracks, id == "M1718H20")
summary(M1718H20)

summarize_sampling_rate(M1718H20)

#Import raster
landcover.nlcd <- raster("C:/Users/paschuette/Documents/GIS/nlcd_veg_clip_2.tif")

projection(landcover.nlcd)  #the raster didn't have a projection set
# projection(landcover.nlcd) <- CRS("+proj=aea +lat_1=55 +lat_2=65 +lat_0=50 +lon_0=-154 +x_0=0 +y_0=0 +ellps=WGS84 +datum=WGS84 +units=m +no_defs") #set the projection

raster::plot(landcover.nlcd)
#raster::plot(landcover.nlcd, 1)  # if a raster stack

#get_crs(moose_tracks)
#moose_tracks_prj <- transform_coords(moose_tracks, sp::CRS("+proj=aea +lat_1=55 +lat_2=65 +lat_0=50 +lon_0=-154 +x_0=0 +y_0=0 +datum=NAD83 +units=m +no_defs +ellps=GRS80 +towgs84=0,0,0"))
#get_crs(moose_tracks_prj)
#head(moose_tracks_prj)
#head(moose_tracks)

points(y_ ~ x_, data = moose_tracks, col = factor(moose_tracks$id))

#OR, plot just one individual
raster::plot(landcover.nlcd)
points(y_ ~ x_, data = M1718H20)

plot(y_ ~ x_, data = M1718H20)
#raster::plot(landcover.nlcd,add=T)

#Look at step lengths
hist(step_lengths(M1718H20)) #most steps are <500m

which(step_lengths(M1718H20)>1000)

#The very first step is unusually long; let us plot the first day in red on top of the full trajectory.
plot(M1718H20, type = "l", asp = 1)

#lines(filter(M1718H20, t_ < min(t_) + days(1)), col = "red")

step_lengths(M1718H20)[[424]]  #gives the length of a particular step

#Thin movement data and split to bursts
#===================================
#  - We reduce the data set to observations that are within a certain time step range. 
#The SSF assumes Brownian motion, so we should thin sufficiently, 
#so that the velocities of successive steps are uncorrelated. See presentation by Chris. 
# In the buffalo example, they switched from 1 hr fix rate to 3 hrs. 
#- There is some tolerance around the target time interval of 3 hours. 
#When two observations are separated by less than the threshold, 
#the second observation is removed
#- When two observations are separated by more than the upper threshold, 
#the observations are assigned to different bursts.
#It is a good idea to perform the analysis at several temporal scales, 
#i.e. different step durations.
#The initial sampling rate of cilla is about 1 hour:

library(ctmm)
M1718H20_telemetry <- as.telemetry(mooose.mov.prj[["M1718H20"]])    #X30102

# zoom(variogram(cilla_telemetry))
plot(variogram(M1718H20_telemetry), xlim = c(0, 10 * 3600))
zoom(variogram(M1718H20_telemetry))


#ACCS Vegetation layer
landcover.accs <- raster("C:/Users/paschuette/Documents/GIS/AlaskaVegetationWetlandComposite_20180412.tif")
projection(landcover.accs)
raster::plot(landcover.accs)

#Resample at 2 hr intervals
stps <- track_resample(M1718H20, rate = hours(2), tolerance = minutes(15)) %>%
  filter_min_n_burst(min_n = 3) %>% steps_by_burst() %>%
  time_of_day(include.crepuscule = FALSE)