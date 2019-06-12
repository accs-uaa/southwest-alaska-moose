#Paul Schuette
# June 12, 2019
# AniMove

## Adopted script from AniMove 2019, script called 'Lesson2.2_2019_LoadExportData.R'

# This script starts with accessing the SW moose data file from 
# Movebank, which was standard practice during the workshop. This
# ensured that the data was standardized.
# I proceed to then prepare the data for Step Selection Functions (SSFs)

# Load packages
library(move)  
library(tidyverse)
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

#Set Working Directory
setwd("T:/Zoology/Paul/ADF&G Region4/southwest-alaska-moose/telemetry")

###################################
## GETTING TRACKING DATA INTO R ###
###################################
###------------------------------------------------------###
### Reading in a .csv file downloaded from a Movebank###
###  Can alsoe create a move object from other data sets
###------------------------------------------------------###
#I manually downloaded the file from Movebank rather than accessing with 
# an R script

file <- read.csv("SW Alaska moose.csv", as.is=T)
str(file)

# first make sure the date/time is correct
file$timestamp <- as.POSIXct(file$timestamp,format="%Y-%m-%d %H:%M:%S",tz="UTC")

# also ensure that timestamps and individuals are ordered
file <- file[order(file$tag.local.identifier, file$timestamp),]

is.data.frame(file)

# convert a data frame into a move object
moose.mov <- move(x=file$location.long,y=file$location.lat,
                  time=as.POSIXct(file$timestamp,format="%Y-%m-%d %H:%M:%S",tz="UTC"),
                  data=file,proj=CRS("+proj=longlat +ellps=WGS84"),
                  animal=file$tag.local.identifier, sensor="gps")
plot(moose.mov)

#################
## PROJECTION ###
#################
## check projection 
projection(moose.mov)

## reproject: match the layers I want to use
moose.mov.prj <- spTransform(moose.mov, CRSobj=("+proj=aea +lat_1=55 +lat_2=65 +lat_0=50 +lon_0=-154 +x_0=0 +y_0=0 +datum=NAD83 +units=m +no_defs +ellps=GRS80 +towgs84=0,0,0"))
projection(moose.mov.prj)
head(moose.mov.prj)

##############################
### MOVE/MOVESTACK OBJECTS ###
##############################

### Movestack object (multiple indiv) #####
moose.mov.prj
str(moose.mov.prj)
## access the information 
n.indiv(moose.mov.prj)  # # of individuals = 20
namesIndiv(moose.mov.prj)   #their names; X30102, etc.
n.locs(moose.mov.prj)  # # of locations per animal
idData(moose.mov.prj)  # links the tags to the animals

########################
#### OUTPUTTING DATA ###
########################
#Save movestack object for later use. It should be all 
# formatted rather than having to recreate the formatting.
# This will be useful (hopefully) when doing an SSF

#save(moose.mov.prj, file="moose.mov.prj.Rdata")  #use this in 'moose.ssf.r'
#Bjoern suggested saveRDS rather than saving as .RData 
# could then start with readRDS if didn't want to run 
# the initial steps again to format data into a Movestack.
saveRDS(moose.mov.prj, file="moose.mov.prj.RDS")

#But, I will proceed with the moose.mov.prj
summary(moose.mov.prj)

#Convert MoveStack to amt::track object
#=====================
#  Currently, there is no conversion function from 
# move::moveStack to amt::track implemented, so we do it by hand
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

#sampling rate
summarize_sampling_rate(M1718H20)

#Import raster
landcover.nlcd <- raster("C:/Users/paschuette/Documents/GIS/nlcd_veg_clip_2.tif")
projection(landcover.nlcd)  

#Plot the raster
par(mar = c(2, 2, 2, 2))
raster::plot(landcover.nlcd)
#raster::plot(landcover.nlcd, 1)  # if a raster stack

#Plot the points on top of the raster
points(y_ ~ x_, data = moose_tracks, col = factor(moose_tracks$id))

#OR, plot just one individual
raster::plot(landcover.nlcd)
points(y_ ~ x_, data = M1718H20)

#Look at step lengths
hist(step_lengths(M1718H20)) #most steps are <500m
which(step_lengths(M1718H20)>1000)
step_lengths(M1718H20)[[424]]  #gives the length of a particular step

#Thin movement data and split to bursts
#===================================
#  We reduce the data set to observations that are within a certain time step range. 
#The SSF assumes Brownian motion, so we should thin sufficiently, 
#so that the velocities of successive steps are uncorrelated. 
# In the buffalo example, they switched from 1 hr fix rate to 3 hrs. 
# When two observations are separated by more than the upper threshold, 
#the observations are assigned to different bursts.
#It is a good idea to perform the analysis at several temporal scales, 
#i.e. different step durations.

#Convert the Movestack to telemetry data
# to look at the autocorrelation structure from
# the ctmm package
moose.telemetry <- as.telemetry(moose.mov.prj)    #X30102
str(moose.telemetry)

#let's look at the moose of interest
moose.telemetry[["X30102"]]  #need to call out by tag id rather than animal id for some reason
par(mar = c(5, 5, 2, 2))
zoom(variogram(moose.telemetry[["X30102"]]))
#Looks like there is autocorrelation up to ~8 days
plot(variogram(moose.telemetry[["X30102"]]), xlim = c(0, 10 * 3600))

#Resample at 2 hr intervals
#Now we resample (subset) to x hour intervals, 
#with a tolerance of x minutes
step_duration <- 2  # 2 hrs
M1718H20 <- track_resample(M1718H20, hours(step_duration), tolerance = minutes(15))

summarize_sampling_rate(M1718H20)

#How many bursts, if we keep 2 hr fix rate
table(M1718H20$burst_)  # 3 bursts; 1392, 1088, and 2414

M1718H20 <- filter_min_n_burst(M1718H20, 3)

#Convert locations to steps. We will have fewer rows in the 
#step data frame than in the track data frame because 
#the final position is not a complete step.
ssf_M1718H20 <- steps_by_burst(M1718H20)

#We still have steps without a turning angle (the first step in a burst)
which(is.na(ssf_M1718H20$ta_))
ssf_M1718H20 <- filter(ssf_M1718H20, !is.na(ta_))

#Empirical distances and turning angles
par(mfrow = c(1, 2))
hist(ssf_M1718H20$sl_, breaks = 20, main = "", 
     xlab = "Distance (m)")
hist(ssf_M1718H20$ta_,  main="",breaks = seq(-pi, pi, len=11),
     xlab="Relative angle (radians)")

#Fit gamma distribution to distances
#PS: the empirical data (observed) steps are the histogram,
#the exponential and gamma distribution fit the empirical data well

fexp <- fitdistr(ssf_M1718H20$sl_, "exponential")
fgamma <- fit_sl_dist(ssf_M1718H20, sl_)
par(mfrow = c(1, 1))
hist(ssf_M1718H20$sl_, breaks = 50, prob = TRUE, 
     xlim = c(0, 8000), ylim = c(0, 2e-3),
     xlab = "Step length (m)", main = "")
plot(function(x) dexp(x, rate = fexp$estimate), add = TRUE, from = 0.1, to = 8000, col = "red")
plot(function(x) dgamma(x, shape = fgamma$fit$estimate["shape"],
                        rate = fgamma$fit$estimate["rate"]), add = TRUE, from = 0.1, to = 8000, col = "blue")
legend("topright", col = c("red", "blue"), lty = 1,
       legend = c("exponential", "gamma"), bty = "n")

#Fit von Mises distribution to angles
#=============================
fvmises <- fit_ta_dist(ssf_M1718H20, ta_)
par(mfrow = c(1, 1))
hist(ssf_M1718H20$ta_, breaks = 50, prob = TRUE, 
     xlim = c(-pi, pi),
     xlab = "Turning angles (degrees)", main = "")
plot(function(x) dvonmises(x, mu = 0, kappa = fvmises$params), add = TRUE, from = -pi, to = pi, col = "red")

#Create random steps. We typically get a warning that "Step-lengths or turning angles contained NA, which were removed", because of the missing turning angles at the start of a burst.
#PS: start with set.seed to have a repeatable random number; i.e to get the same
# answer next time we run the analysis
# for each observed step, we create 100 alternatives, which Bjorn says is too low, but
# using for simplicity today (maybe use 200 or more)
# sl_distr: pull step length from the gamma distribution
# ta_distr: pull turning angle from a uniform distribution, pull from all possible angles
set.seed(2)
ssf_M1718H20 <- steps_by_burst(M1718H20)
ssf_M1718H20 <- filter(ssf_M1718H20, !is.na(ta_))
ssf_M1718H20 <- random_steps(ssf_M1718H20, n = 100, sl_distr = "gamma", ta_distr = "unif")

#View the new data set
#Case represents 'true' for the real location, 
#'false' for the random step
ssf_M1718H20

#Sanity check: plot the choice set for a given step
#=============
#my_step_id <- 2
#ggplot(data = filter(ssf_M1718H20, step_id_ == my_step_id | (step_id_ %in% c(my_step_id - 1, my_step_id - 2) & case_ == 1)),
#       aes(x = x2_, y = y2_)) + geom_point(aes(color = factor(step_id_))) + geom_point(data = filter(ssf_M1718H20, step_id_ %in% c(my_step_id, my_step_id - 1, my_step_id - 2) & case_ == 1), aes(x = x2_, y = y2_, color = factor(step_id_), size = 2))
#PS: the red point represents its first location, the green its second, and blue its third. The smaller blue points represent the random locations

#extract covairates
ssf_M1718H20 <- extract_covariates(ssf_M1718H20, (shrub))

# Create environmental covariate for the SSF
# NLCD codes found in the clipped area of interest: 
#0=bareground, 11=open water, 12=perennial ice/snow,
#22=developed, low density, 23=developed, med density, 
#31=barren land, 41=deciduous forest, 42=evergreen forest
# 43=mixed forest, 51=dwarf shrub, 52=shrub/scrub, 
#71=grassland/herbaceous, 72=sedge/herbaceous, 74=moss, 
#90=woody wetlands, 95=emergent herbaceous wetlands

#Two options for working with these categories:
#1. focus on 1 veg class at a time: The location is either
# that type of veg (1) or it is not (0). For example,
# create a variable for wetland (1) or not wetland (0).

#2. Can reclassify to a fewer habitat types
#land_use <- raster("data/landuse_study_area.tif")
#For example, create 5 classes (water and wetland forests, developed
#open spaces, other developed areas, forests and shrubs, and crops) 
#that are merged from a larger number of classes
# rcl <- cbind(c(11, 12, 21:24, 31, 41:43, 51:52, 71:74, 81:82, 90, 95),
#             c(1, 1, 2, 3, 3, 3, 2, 4, 4, 4, 4, 4, 4, 4, 4, 4, 5, 5, 1, 1))
#lu <- reclassify(land_use, rcl)
#names(lu) <- "landuse"

#Option 1: create covariates for shrub (1) or not shrub (0)
shrub <- landcover.nlcd == 52
names(shrub) <- "shrub"
decidfor <- landcover.nlcd == 41
names(decidfor) <- "decidfor"
confor <- landcover.nlcd == 42
names(confor) <- "confor"

#Extract covariates
ssf_M1718H20 <- extract_covariates(ssf_cilla, buffalo_env)



#stps <- track_resample(M1718H20, rate = hours(2), tolerance = minutes(15)) %>%
#  filter_min_n_burst(min_n = 3) %>% steps_by_burst() %>%
 # time_of_day(include.crepuscule = FALSE)
#str(stps)

#ACCS Vegetation layer
landcover.accs <- raster("C:/Users/paschuette/Documents/GIS/AlaskaVegetationWetlandComposite_20180412.tif")
projection(landcover.accs)
raster::plot(landcover.accs)