# Objective: Fit movement models and estimate home range for a single moose, M30935. This is an island moose and the closest thing we have to good variogram + a range resident

# Working through vignette: https://ctmm-initiative.github.io/ctmm/articles/variogram.html

# Author: Amanda Droghini (adroghini@alaska.edu)
#         Alaska Center for Conservation Science

# Load data and packages----
source("scripts/init.R")
load("pipeline/03b_cleanLocations/cleanLocations.Rdata") # don't use interpolated data for now... need to revist that script
load("pipeline/02b_calibrateData/uereModel.Rdata")

# Prepare data----
gpsClean <- gpsClean %>% 
  filter(deployment_id == "M30935") %>% 
  dplyr::rename(location.long = longX, location.lat = latY,class=FixType) %>%
  dplyr::select(deployment_id,location.long,location.lat,DOP,class,datetime)

# Convert to telemetry object
gpsData <- ctmm::as.telemetry(gpsClean,timezone="UTC",projection=CRS("+init=epsg:32604"))

# Add calibration information
uere(gpsData) <- calibModel

names(gpsData) # column VAR.xy now present

rm(gpsClean,calibModel)

# Model selection----

# Use ctmm.guess (=variogram.fit) to obtain initial "guess" parameters, which can then be passed onto to ctmm.fit
# Use ctmm.select to choose top-ranked model, which will be used to generate aKDEs
# Do not use ctmm.fit - ctmm.fit() returns a model of the same class as the guess argument i.e. an OUF model with anisotropic covariance.
initParam <- ctmm.guess(gpsData,interactive=FALSE)

# Takes a while to run
fitModel <- ctmm.select(gpsData,initParam,verbose=TRUE)

summary(fitModel)
names(fitModel)
summary(fitModel[[1]])

# Plot variogram with model fit----
vario <- ctmm::variogram(gpsData, dt = 2 %#% "hour")
plot(vario,CTMM=fitModel,col.CTMM=c("red","purple","blue","green"),fraction=0.65,level=0.5,main="M30935")

xlim <- c(0,12 %#% "hour")
plot(vario,CTMM=fitModel,col.CTMM=c("red","purple","blue","green"),xlim=xlim,level=0.5)

#### Generate AKDE ----
oufAnisoModel <- fitModel[[1]]
ouAnisoModel <- fitModel[[2]]

# Choose weights = TRUE because sampling interval may not always be exactly two hours since we're using uninterpolated data
rangeEstOUF <- akde(gpsData,CTMM=oufAnisoModel,weights=TRUE)
rangeEstOU <- akde(gpsData,CTMM = ouAnisoModel,weights=TRUE)

# Calculate extent for plotting
plotExtent <- extent(list(rangeEstOUF,rangeEstOU),level=0.95)

summary(rangeEstOUF)
summary(rangeEstOU) # Second best model (ou aniso) gives very similar estimates

#### Plot aKDE ----
plot(gpsData,UD=rangeEstOUF,xlim=plotExtent$x,ylim=plotExtent$y)
title("weighted OUF AKDE for M30935")

plot(gpsData,UD=rangeEstOU,xlim=plotExtent$x,ylim=plotExtent$y)
title("weighted OU AKDE for M30935")

#### Split data by years ----
# Check timestamp here--- using 1 Jan gives me some timestamps from that date. filter function is using LMT instead of UTC spec.
# Playing around with data... 
# How would HR estimates change if we were to start July 1? can only see that for 2018-2019 period, but let's run it anyway

data2018 <- gpsData %>% 
  filter(timestamp>"2018-07-01" & timestamp < "2019-07-01")
summary(data2018$timestamp)

data2019 <- gpsData %>% 
  filter(timestamp>="2019-07-01 00:00:00" & timestamp < "2020-07-01 00:00:00")

data2018 <- ctmm::as.telemetry(data2018,timezone="UTC",projection=CRS("+init=epsg:32604"))
data2019 <- ctmm::as.telemetry(data2019,timezone="UTC",projection=CRS("+init=epsg:32604"))

# Add calibration information
uere(data2018) <- calibModel
uere(data2019) <- calibModel

yearlyData <- list("2018" = data2018, "2019" = data2019)

#### Run models----
initParam <- lapply(yearlyData[1:length(yearlyData)], function(b) ctmm.guess(b,interactive=FALSE) )

# Takes a while to run
fitYearlyModels <- lapply(1:length(yearlyData), function(i) ctmm.select(yearlyData[[i]],initParam[[i]],verbose=TRUE) )

names(fitYearlyModels) <- names(yearlyData[1:length(yearlyData)])

lapply(fitYearlyModels,function(x) summary(x))


# Plot variogram with model fit----
for (i in 1:length(yearlyData)){
  id <- names(yearlyData)[[i]]
  vario <- variogram(yearlyData[[i]], dt = 2 %#% "hour")
  fitOneId<-fitYearlyModels[[i]]
  plot(vario,CTMM=fitOneId,col.CTMM=c("red","purple","blue","green"),fraction=0.65,level=0.5,main=id)
}

rm(fitOneId, i, id)
#### Generate AKDE ----
ouf2018 <- fitYearlyModels[[1]]$`OUF anisotropic`
ouf2019 <- fitYearlyModels[[2]]$`OUF anisotropic`
oufJuly2018 <- fitYearlyModels[[1]]$`OUF anisotropic`
oufJuly2019 <- fitYearlyModels[[2]]$`OUF anisotropic`
# Choose weights = TRUE because sampling interval may not always be exactly two hours since we're using uninterpolated data
hr2018 <- akde(data2018,CTMM=ouf2018,weights=TRUE)
hr2019 <- akde(data2019,CTMM = ouf2019,weights=TRUE)
hr2018 <- akde(data2018,CTMM=oufJuly2018,weights=TRUE)
hr2019 <- akde(data2019,CTMM = oufJuly2019,weights=TRUE)
# Calculate extent for plotting
plotExtent <- extent(list(ouf2018,ouf2019))

summary(hr2018) # est size is 21.6 sq km (16.0 - 28.0)
summary(hr2019) # est size is 14.1 (11.4 - 17.0)

#### Plot aKDE ----
# Use locations for both years to see how well the model fits when data are withheld
plot(gpsData,UD=hr2018,xlim=plotExtent$x,ylim=plotExtent$y)
title("M30935 2018")

plot(gpsData,UD=hr2019,xlim=plotExtent$x,ylim=plotExtent$y)
title("M30935 2019")

#### Calculate overlap ----
# Wasn't able to get it to work when using UD objects (hr2018 instead of ouf2018)
# When applied to ctmm object, returns the overlap of the two Gaussian distributions. 
# Resulting value is bounded between 0 and 1. Value of 1 indicates the two distributions are identical.

hrBothYears <- list("y2018"=ouf2018,"y2019"=ouf2019)
overlap(hrBothYears) 

hrBothYears <- c(hr2018,hr2019)
overlap(hrBothYears)
