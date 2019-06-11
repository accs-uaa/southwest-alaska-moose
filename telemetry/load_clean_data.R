## Adopted script from AniMove 2019, script called 'Lesson2.2_2019_LoadExportData.R'

# This script starts with accessing the SW moose data file from 
# Movebank, which was standard practice during the workshop. This
# ensured that the data was standardized.

library(move)  
library(tidyverse)

setwd("T:/Zoology/Paul/ADF&G Region4/southwest-alaska-moose/telemetry")


###################################
## GETTING TRACKING DATA INTO R ###
###################################

###--------------------------------------------####
### 1. Directly downloading data from Movebank ####
###--------------------------------------------####

### store the movebank credentials
#cred <- movebankLogin(username="R-Book", password="Obstberg1")
## or

### browse the database ###
## search for studies using keywords included in the study name
searchMovebankStudies(x="SW Alaska moose", login=cred)

## if previous function produced an error, then:
#### ---- set the curlHandle if necessary ---------------------------#######
#curl <- getCurlHandle()
#options(RCurlOptions = list(capath = system.file("CurlSSL", "cacert.pem",
#                                                 package = "RCurl"),
 #                           ssl.verifypeer = FALSE, ssl.verifyhost = FALSE))
#curlSetOpt(.opts = list(proxy = 'proxyserver:port'), curl = curl)
##### ---------------------------------------------------------------######

## get the metadata of the study
getMovebankStudy(study="SW Alaska moose",login=cred)

## check for reference data of animals, depolyments and tags
getMovebankReferenceTable(study="SW Alaska moose",login=cred)[1:4,]

## check reference data of animals
animals <- getMovebankAnimals(study="SW Alaska moose",login=cred)[1:4,]
head(animals)

### Download the location data ##
## You can also download the data through Movebank, which I did
# during the workshop. But, want to work towards doing all of this
# through R.

## get all data
moose <- getMovebankData(study="SW Alaska moose",login=cred)

# The command above doesn't give the animal ID's, so call
# out by name
#moose.wnames <- getMovebankData(study="SW Alaska moose", animalName = c("M1718H20", "M1718H10", "M1718H11", "M1718H06", "M1718H07",
      #                                                                  "M1718H02", "M1718H13", "M1718H08", "M1718H15", "M1718H12",
      #                                                                  "M1718H01", "M1718H18", "M1718H14", "M1718H16", "M1718H04",
       #                                                                 "M1718H05", "M1718H03", "M1718H19", "M1718H17", "M1718H09"), login=cred)
# provides the same info, only by tag id

head(moose)
moose.df <- as.data.frame(moose)
summary(moose.df)



#Save downloaded file
#write.csv(moose, file="sw.alaska.moose.csv")




## get only bat "191"
#moose.M1718H01 <- getMovebankData(study="SW Alaska moose", animalName="	M1718H01", login=cred)
#bat191

## get data for a specific time range e.g. between "2002-06-02 23:06:15"
## and "2002-06-11 22:18:25". Time format: 'yyyyMMddHHmmssSSS'
#bats.subset <- getMovebankData(study="Parti-colored bat Safi Switzerland",
#                               login=cred,timestamp_start="20020602230615000",
 #                              timestamp_end="20020611221825000")
#bats.subset


## when there is an error because duplicated timestamps are present. This is one solution, but to use with care. More further down
# mystudy <- getMovebankData(study="MyStudyName", login=cred, removeDuplicatedTimestamps=T)



###------------------------------------------------------###
### 2. Reading in a .csv file downloaded from a Movebank ###
###------------------------------------------------------###

#I manually downloaded the file from Movebank rather than accessing with 
# an R script

#moose.mov <- move("SW Alaska moose.csv")
#summary(moose.mov)

## ---- also read EvData .zip files or tar-compressed csv exports -----------------------------
# PS: could be useful when the .csv file is huge
#batsTemp <- move("Parti-colored bat Safi Switzerland-5752797914261819198.zip")
# this data set was annotated with temperature data with the EnvData tool from movebank


###----------------------------------------------###
### 3. Creating a move object from any data set: ###
###----------------------------------------------###
# read the data and store in a data frame
file <- read.csv("SW Alaska moose.csv", as.is=T)
str(file)

# first make sure the date/time is correct
# PS: match the data forma in the file
file$timestamp <- as.POSIXct(file$timestamp,format="%Y-%m-%d %H:%M:%S",tz="UTC")


# also ensure that timestamps and individuals are ordered
file <- file[order(file$tag.local.identifier, file$timestamp),]

is.data.frame(file)
#moose.df <- moose.df %>% 
#  arrange(tag_local_identifier, timestamp)

# convert a data frame into a move object
moose.mov <- move(x=file$location.long,y=file$location.lat,
             time=as.POSIXct(file$timestamp,format="%Y-%m-%d %H:%M:%S",tz="UTC"),
             data=file,proj=CRS("+proj=longlat +ellps=WGS84"),
             animal=file$tag.local.identifier, sensor="gps")
plot(moose.mov)

###---------------------------------------------###
### download data from Movebank Data Repository ###
###---------------------------------------------###
#repos <- getDataRepositoryData("doi:10.5441/001/1.2k536j54")
#repos


###---------------------------------------------------###
### example of how to deal with duplicated timestamps ###
###---------------------------------------------------###

### buffalo data 
#buffalo <- move("Kruger African Buffalo, GPS tracking, South Africa.csv.gz")

## one solution is to use the argument removeDuplicatedTimestamps=T. But use with care! as duplicates are removed randomly. Additional information could be lost.
#buffaloNoDupl <- move("Kruger African Buffalo, GPS tracking, South Africa.csv.gz", removeDuplicatedTimestamps=T)

## example to remove duplicates timestamps in a controlled way:
## create a data frame
#buffalo.df <- read.csv('Kruger African Buffalo, GPS tracking, South Africa.csv.gz', as.is=TRUE)

## get a quick overview
#head(buffalo.df, n=2)

## first make sure the date/time is correct
#buffalo.df$timestamp <- as.POSIXct(buffalo.df$timestamp, format="%F %T ", tz="UTC")

## also ensure that timestamps and individuals are ordered
#moose.mov <- moose.mov[order(moose.mov$individual.local.identifier, moose.mov$timestamp),]
#str(moose.mov)


## get the duplicated timestamps
#dup <- getDuplicatedTimestamps(buffalo.df)
#dup[1]

## get an overview of the amount of duplicated timestamps
#table(unlist(lapply(dup,function(x)length(x)))) 

#buffalo.clean <- buffalo.df
## we will keep the posititon that results in the shortest distance between the previous and the next location
## A while loop will ensure that the loop continues untill each duplicate is removed
## ==> loop starts here
#while(length(dup <- getDuplicatedTimestamps(buffalo.clean))>0){
 # allrowsTOremove <- lapply(1:length(dup), function(x){
 #   rown <- dup[[x]]
    # checking if the positions are exaclty the same for all timestamps
 #   if(any(duplicated(buffalo.clean[rown,c("timestamp", "location.long", "location.lat", "individual.local.identifier")]))){
  #    dup.coor <- duplicated(buffalo.clean[rown,c("timestamp", "location.long", "location.lat", "individual.local.identifier")])
 #     rowsTOremove <- rown[dup.coor] # remove duplicates
  #  }else{
  #    # subset for the individual, as distances should be measured only within the individual
  #    # create a row number ID to find the duplicated time stamps in the subset per individual
  #    buffalo.clean$rowNumber <- 1:nrow(buffalo.clean)
  #    ind <- unlist(strsplit(names(dup[x]),split="|", fixed=T))[1]
   #   subset <- buffalo.clean[buffalo.clean$individual.local.identifier==ind,]
      
      # if the duplicated positions are in the middle of the table
   #   if(subset$rowNumber[1]<rown[1] & subset$rowNumber[nrow(subset)]>max(rown)){
        # calculate total distance throught the first alternate location
   #     dist1 <- sum(distHaversine(subset[subset$rowNumber%in%c((rown[1]-1),(max(rown)+1)),c("location.long", "location.lat")],
     #                              subset[subset$rowNumber==rown[1],c("location.long", "location.lat")]))
        # calculate total distance throught the second alternate location
    #    dist2 <- sum(distHaversine(subset[subset$rowNumber%in%c((rown[1]-1),(max(rown)+1)),c("location.long", "location.lat")],
   #                                subset[subset$rowNumber==rown[2],c("location.long", "location.lat")]))
        # omit the aternate location that produces the longer route
   #     if(dist1<dist2){rowsTOremove <- rown[2]}else{rowsTOremove <- rown[1]}
  #    }
#
      # incase the duplicated timestamps are the first positions
   #   if(subset$rowNumber[1]==rown[1]){
   #     dist1 <- sum(distHaversine(subset[subset$rowNumber==(max(rown)+1),c("location.long", "location.lat")],
   #                                subset[subset$rowNumber==rown[1],c("location.long", "location.lat")]))
    #    dist2 <- sum(distHaversine(subset[subset$rowNumber==(max(rown)+1),c("location.long", "location.lat")],
    #                               subset[subset$rowNumber==rown[2],c("location.long", "location.lat")]))
    #    if(dist1<dist2){rowsTOremove <- rown[2]}else{rowsTOremove <- rown[1]}
    #  }
      
      # incase the duplicated timestamps are the last positions
    #  if(subset$rowNumber[nrow(subset)]==max(rown)){
    #    dist1 <- sum(distHaversine(subset[subset$rowNumber==(rown[1]-1),c("location.long", "location.lat")],
    #                               subset[subset$rowNumber==rown[1],c("location.long", "location.lat")]))
     #   dist2 <- sum(distHaversine(subset[subset$rowNumber==(rown[1]-1),c("location.long", "location.lat")],
      #                             subset[subset$rowNumber==rown[2],c("location.long", "location.lat")]))
      #  if(dist1<dist2){rowsTOremove <- rown[2]}else{rowsTOremove <- rown[1]}
    #  }
  #  }
  #  return(rowsTOremove)
#  })
 # buffalo.clean <- buffalo.clean[-unique(sort(unlist(allrowsTOremove))),]
  #buffalo.clean$rowNumber <- NULL
}
## ==> and ends here

# define the data.frame as a move object after cleaning
#buffalo <- move(x=buffalo.clean$location.long,
#                y=buffalo.clean$location.lat,
 #               time=buffalo.clean$timestamp,
 #               data=buffalo.clean,
  #              proj=CRS("+proj=longlat +datum=WGS84"),
  #              animal=buffalo.clean$individual.local.identifier,
  #              sensor=buffalo.clean$sensor.type)



#################
## PROJECTION ###
#################
## check projection 
projection(moose.mov)

## reproject: match the layers I want to use
# come back to this
#mooseproj <- spTransform(moose.mov, CRSobj="+proj=utm +zone=32 +ellps=WGS84 +datum=WGS84 +units=m +no_defs")
#projection(BatsProj)

#PS: Can search spTransform for Move object for assistance

##############################
### MOVE/MOVESTACK OBJECTS ###
##############################

### Movestack object (multiple indiv) #####
moose.mov
str(moose.mov)
## access the information 
n.indiv(moose.mov)  # # of individuals = 20
namesIndiv(moose.mov)   #their names
n.locs(moose.mov)  # # of locations
idData(moose.mov)  # the id's


########################
#### OUTPUTTING DATA ###
########################
#Save movestack object for later use. It should be all 
# formatted rather than having to recreate the formatting.
# This will be useful (hopefully) when doing an SSF
save(moose.mov, file="moose.mov.Rdata")

# Can also get a specific individual
X30102 <- moose.mov[['X30102']]  # separate names by comma if want muliple animals
X30102





## save the move object for later
# PS: preferred method since it is ready as a move object for analysis
save(X30102, file="X30102.Rdata")

## save as a text file
#buffaloDF <- as.data.frame(buffalo)
#write.table(buffaloDF, file="buffalo_cleaned.csv", sep=",", row.names = FALSE)

## save as a shape file
#writeOGR(buffalo, getwd(), layer="buffalo", driver="ESRI Shapefile")

## kml or kmz of movestack ##
#library("plotKML")
# open a file to write the content
#kml_open('buf.kml')
# write the movement data individual-wise
#for(i in levels(trackId(buffalo)))
 # kml_layer(as(buffalo[[i]],'SpatialLines'))
# close the file
#kml_close('buf.kml')


## export KML using writeOGR ##
#for(i in 1:nrow(buffalo@idData)){
 # writeOGR(as(buffalo[[i]], "SpatialPointsDataFrame"),
  #         paste(row.names(buffalo@idData)[i],
   #              ".kml", sep=""),
    #       row.names(buffalo@idData)[i], driver="KML")

  #writeOGR(as(buffalo[[i]], "SpatialLinesDataFrame"),
   #      paste(row.names(buffalo@idData)[i],
    #           "-track.kml", sep=""),
     #    row.names(buffalo@idData)[i], driver="KML")

  #print(paste("Exported ", row.names(buffalo@idData)[i],
   #         " successfully.", sep=""))
#}


###################################
#### MAPPING MOVEMENT DATA ########
###################################

## basic plots ###
plot(X30102)
plot(X30102, xlab="Longitude", ylab="Latitude",type="b", pch=16, cex=0.5)

## plot on the world ###
library(mapdata)
library(scales)
#map('worldHires', col="grey", fill=T)
#points(t(colMeans(coordinates(X30102))), col=alpha('red',0.5), pch=16)
#points(t(colMeans(coordinates(X30102))), col='cyan')

## plot on the world, zooms in ####
(e<-bbox(extent(X30102)*5))
# note here that the brackets around the assignment ensure that the result is also printed to the console
#map('worldHires', xlim = e[1, ], ylim = e[2, ])
#points(X30102)
#lines(X30102)

## plot on google background ####
library("ggmap")
library("mapproj")
## coerce move object to a data frame
moose_df <- as.data.frame(X30102)
## request map data from google
m <- get_map(e, zoom=9, source="google", maptype="terrain")
## plot the map and add the locations separated by individual id
ggmap(m)+geom_path(data=moose_df, aes(x=location.long, y=location.lat))

## we can also add a scalebar
library(ggsn)
xylim <- as.numeric(attributes(m)$bb)
ggmap(m)+geom_path(data=moose_df, aes(x=location.long, y=location.lat))+
  scalebar(x.min = xylim[2], x.max = xylim[4],
           y.min = xylim[1], y.max = xylim[3],
           dist = 10, dist_unit="km", transform=T, model = 'WGS84',anchor=c(x=-158.3,y=59.0),st.size=3)

####################################################
####### REMOVING OUTLIERS BASED ON MAPPING #########
####################################################

#load("buffalo_cleaned.Rdata") # buffalo

#PS: Look at the data from the .Rdata
#summary(buffalo)

## Create gray scale
#buffaloGray<-gray((nrow(idData(buffalo))-1):0/nrow(idData(buffalo)))
## Plot with gray scale
#plot(buffalo, col=buffaloGray, xlab="Longitude", ylab##="Latitude")

## get the position of the coordinate that has the max #longitude
#which.max(coordinates(buffalo)[,1])
## drop the point with the largest coordinate values
#buffalo <- buffalo[-which.max(coordinates(buffalo)[,1])]
#plot(buffalo, col=buffaloGray, xlab="Longitude", ylab#="Latitude")
## save the clean dataset for the following days
#save(buffalo, file="buffalos.Rdata")


#################################################
### TEMPORAL ORGANIZATION OF THE TRAJECTORIES ###
#################################################
## number of locations
n.locs(X30102)

## time lag between locations
timeLags <- timeLag(X30102, units='hours') # important: always state the units!

## distribution of timelags
timeLagsVec <- unlist(timeLags)
summary(timeLagsVec)
hist(timeLagsVec, breaks=50, main=NA, xlab="Time lag in hours")
#arrows(24.5,587.5,20.7,189.7, length=0.1)
#arrows(49.5,587.5,45.7,189.7, length=0.1)

## distribution of timelags longer than 2h
hist(timeLagsVec[timeLagsVec>2], breaks="FD", main=NA, xlab="Time lag in hours")
## count of locations per timebin
summary(as.factor(round(timeLagsVec, 4)), maxsum=5)

## nb locations per hour
ts <- timestamps(X30102)
library('lubridate')
#transform timestemps into local time of study for better interpretation
tsLocal <- with_tz(ts, tzone="America/Anchorage")
tapply(tsLocal, hour(tsLocal), length)

## nb locations per month and hour
tapply(tsLocal, list(month(tsLocal),hour(tsLocal)), length)


#########################################
### SPATIAL ORGANIZATION OF THE TRACK ###
#########################################

### distance between locations ###
dist <- unlist(distance(X30102))
summary(dist)
hist(dist)

### speed between locations ###
# PS: in meters per second. Can also help detect outliers
speeds <- unlist(speed(X30102))
summary(speeds)   # PS: We see an outlier in the Max
hist(speeds, breaks="FD")

###########
## MCP ###
###########
library(adehabitatHR)
#X330 <- bats[["X330"]]  #PS: individiual x330
X30102$id <- "X30102"
mcpX30102<-mcp(as(X30102[,'id'], 'SpatialPointsDataFrame'))
#plot(X30102, type="n", bty="na", xlab="Longitude", ylab="Latitude")
plot(mcpX30102, col="grey90", lty=2, lwd=1.25, add=TRUE)
points(X30102, pch=16)
#points(X30102, pch=1, col="white")
legend("topright", as.character("95% MCP"), fill="grey90", bty="n")
mcpX30102
# Note: area value seems strange. That is because our used locations are in the geographic coordinates system (long/lat). adehabitatHR calculated the area acording to the units of the projection, in this case decimal degrees


# therefore we have to project our data into a equidistant projection
library("rgeos")
#Work with the the movestack
moose.mov$id <- trackId(moose.mov) 
mcpData<-mcp(as(moose.mov[,'id'],'SpatialPointsDataFrame'))
#first option: reproject locations, than calculate mcp
# Now let's project the study area and locations to WGS84 and Unit 4

#Project all of the moose in the movestack object
moose.proj <- spTransform(moose.mov, CRS("+proj=utm +zone=4 +datum=WGS84"))

#Found EPSG code for NAD83 projection in meters https://spatialreference.org/ref/epsg/?search=alaska&srtext=Search
moose.proj1 <- spTransform(moose.mov, CRS("+init=epsg:3338")) # This matches the ACCS Veg layer
str(moose.proj1)           
#Calculate MCP for each moose
mcpData.proj <- mcp(as(moose.proj1[, 'id'],'SpatialPointsDataFrame'))
mcpData.proj

plot(moose.proj[["X30102"]], bty="na", xlab="Longitude", ylab="Latitude")
plot(mcpData.proj[mcpData.proj$id=="X30102",], add=TRUE)


############
## Kernel ##
############
# creating a very simple density plot
library(raster)
template <- raster(extent(moose.proj[[1]]))
res(template)<-500
count <- rasterize(split(moose.proj)[[1]], template,field=1,  fun="count")
plot(count, col=grey(10:0/12))
plot(mcpData.proj[1,], add=TRUE)
points(moose.proj[[1]], pch=16, cex=0.5)
# Note: the result is highly dependent on the chosen cell size. In this case 500x500m


# kernel implementation by "adehabitatHR" library
library(adehabitatHR)
library(scales)
X30102 <- moose.proj[['X30102']]
kern1 <- kernelUD(as(X30102, "SpatialPoints"), h=500)
kern2 <- kernelUD(as(X30102, "SpatialPoints"))
kern3 <- kernelUD(as(X30102, "SpatialPoints"), h=2000)
kern4 <- kernelUD(as(X30102, "SpatialPoints"), h="LSCV")
par(mfrow=c(2,2))
par(mar=c(1,0.5,3,0.5))
kern <- c("kern1", "kern2", "kern3", "kern4")
hName <- c("h=500",
           "h='ad-hoc'",
           "h=2000",
           "h=LSCV")
for(i in 1:4){
  plot(getverticeshr(get(kern[i])))
  points(X30102, pch=16, cex=0.75, col=alpha("black", 0.2))
  points(X30102, cex=0.75)
  title(hName[i])
}
# Note to plot:
# - h: degree of smoothness or how tightly the data should be hugged by the distribution function
# - h="LSCV": h calculated from the data via least square cross validation
# - h="ad-hoc": h calcuated from the data via sample size and spatial spread

#PS: low value, tighter fit around the data

# kernel implementation by "ks" library
library(ks) 
library(scales)
pos <- coordinates(X30102)
H.bcv <- Hbcv(x=pos)
H.pi <- Hpi(x=pos) 
H.lscv <- Hlscv(x=pos) 
H.scv <- Hscv(x=pos) 

par(mfrow=c(2,2))
par(mar=c(1,0.5,3,0.5))
H <- c("H.bcv", "H.pi", "H.lscv", "H.scv")
hT <- c("Biased cross-validation (BCV)",
        "Plug-in",
        "Least-squares cross-validation",
        "Smoothed cross-validation")
for(i in 1:4){
  fhat <- kde(x=pos, H=get(H[i]), compute.cont=TRUE) 
  plot(fhat, cont=c(75, 50, 5), bty="n", 
       xaxt="n", yaxt="n", 
       xlab=NA, ylab=NA, asp=1)
  points(X30102, pch=16, cex=0.75, col=alpha("black", 0.2))
  title(hT[i])
}



###########
## LoCoH ##
###########
# check vignettes
par(list(mfrow=c(2,2), mar=c(2,2,2,2)))
library(move)
library(maptools)
library(adehabitatHR)
data(leroy)
# data need to be transformed into a equidistant projection because method relies on distance calculations
leroy <- spTransform(leroy, center=TRUE)

leroy.mcp <- mcp(as(leroy, "SpatialPoints"), percent=95)
plot(leroy.mcp, col=grey(0.9), lty=2, lwd=2)
points(leroy, col="#00000060", pch=16, cex=0.5)
lines(leroy, col="#00000030")
title("Minimum convex polygon")
# include "k" number of closest neighbour locations
kLoc <- LoCoH.k(as(leroy, "SpatialPoints"), k=75)
plot(kLoc, col=grey((0:length(kLoc)/length(kLoc))*0.7), border=NA)
title("k-NNCH LoCoH")
# include location within a radius "r"
rLoc <- LoCoH.r(as(leroy, "SpatialPoints"), r=800)
plot(rLoc, col=grey((0:length(rLoc)/length(rLoc))*0.7), border=NA)
title("r-NNCH LoCoH")
# sum of distances of included neighbour locations to root location is "a"
aLoc <- LoCoH.a(as(leroy, "SpatialPoints"), a=9000)
plot(aLoc, col=grey((0:length(aLoc)/length(aLoc))*0.7), border=NA)
title("a-NNCH LoCoH")



## area changes depending on the choice of k, r, or a
dev.off()# to reset the ploting environment
par(mfrow=c(1,3))
kLocArea <- LoCoH.k.area(as(leroy, "SpatialPoints"), 
                         krange=floor(seq(75, 500, length=10)), 
                         percent=90)
title("k-NNCH LoCoH")
rLocArea <- LoCoH.r.area(as(leroy, "SpatialPoints"), 
                         rrange=seq(500, 1600, 100), 
                         percent=90)
title("r-NNCH LoCoH")
aLocArea <- LoCoH.a.area(as(leroy, "SpatialPoints"), 
                         arange=seq(5000, 13000, 1000), 
                         percent=90)
title("a-NNCH LoCoH")


##############
## t- LoCoH ##
##############
# check website and vignettes: http://tlocoh.r-forge.r-project.org/
# for installation go to: http://tlocoh.r-forge.r-project.org/#installation
library(tlocoh)
leroy.lxy <- move.lxy(leroy) # tlocoh has its own object, class lxy
## calculate a series of hullsets with different number of "k" nearst neighbours. by setting s=0, time is ignored
leroy.lxy <- lxy.nn.add(leroy.lxy, s=0, k=seq(5, 105, 10))
leroy.lhs <- lxy.lhs(leroy.lxy, k=seq(5, 105, 10), s=0)
leroy.lhs <- lhs.iso.add(leroy.lhs)


## plotting the results from above to see how the value of "k" affects area
par(mfrow=c(1,2))
par(list(mar=c(5, 4, 4, 2) + 0.1), bty="n")
iso.info.all <- do.call(rbind, lapply(leroy.lhs, function(myhs) do.call(rbind, lapply(myhs$isos, function(myiso) data.frame(id = myhs[["id"]], mode = myhs[["mode"]], s = myhs[["s"]], param.val = myhs[[myhs[["mode"]]]], sort.metric = myiso[["sort.metric"]], myiso[["polys"]]@data[c("iso.level","area")])))))
iso.info.all$area <- iso.info.all$area/(1000*1000)
plot(area~param.val, type="n", data=iso.info.all, xlab="Number of neighbours (k)", ylab=expression(paste("Area in ", km^2, sep="")), ylim=c(-0.1, 16.1))
for(i in 1:length(unique(iso.info.all$iso.level))){
  tmp <- iso.info.all[iso.info.all$iso.level==unique(iso.info.all$iso.level)[i],]
  lines(area~param.val, type="l", data=tmp, lty=i)
}
legend("topleft", as.character(unique((iso.info.all$iso.level))), lty=1:length(unique(iso.info.all$iso.level)), cex=0.6, bty="n")
par(mar=c(1,1,1,1))
plot(leroy.lhs[[8]]$isos[[1]]$polys, col=grey((0.7*seq(0.1,0.99,length=5))), border=NA)
points(leroy, col="#00000060", pch=16, cex=0.5)
lines(leroy, col="#00000030")
text(0,3000,"k-NNCH LoCoH for k=75", pos=4, cex=0.75)
legend(-1636, -2018, as.character(unique((iso.info.all$iso.level))), fill=grey((0.7*seq(0.1,0.99,length=5))), cex=0.6, bty="n")


## calculate hullset with "a" cumulative distance to nearst neighbours
par(mfrow=c(1,1))
par(list(mar=c(5, 4, 4, 2) + 0.1), bty="o")
leroy.lxy <- lxy.nn.add(leroy.lxy, s=0, a=9000)
leroy.lhs <- lxy.lhs(leroy.lxy, a=9000, s=0, iso.levels = seq(0.1, 0.99, length=10))
leroy.lhs <- lhs.iso.add(leroy.lhs, iso.levels = seq(0.1, 0.99, length=10))
plot(leroy.lhs[[1]]$isos[[1]]$polys, col=grey((0.7*seq(0.1,0.99,length=10))), border=NA)
points(leroy, col="#00000060", pch=16, cex=0.5)
lines(leroy, col="#00000030")
title(expression(paste("a-NNCH LoCoH for ", a <= 9000, sep="")))

## plot to decide which s value to choose, based on a temporal scale
leroy.lxy <- move.lxy(leroy)
leroy.lxy <- lxy.ptsh.add(leroy.lxy)
# Note: select a "s" so that 40-80% of the hulls are time selected. In this case 0.05
# "s" depends on the sampling schedule and the map units


## plot to decide which s value to choose, based on time scaled distance
lxy.plot.sfinder(leroy.lxy, delta.t=3600*c(6,12,24,36,48,54,60))
# Note: s=0.05 kind of fits with the dayly behaviour


## again calculate a series of hullsets with different number of "k" nearst neighbours, but this time with the estimated "s" value
leroy.lxy <- lxy.nn.add(leroy.lxy, s=0.05, k=seq(10, 100, 10))
leroy.lhs <- lxy.lhs(leroy.lxy, s=0.05, k=seq(10, 100, 10))
leroy.lhs <- lhs.iso.add(leroy.lhs, k=seq(10, 100, 10))

## plot the resutls from above
lhs.plot.isoear(leroy.lhs)
# Note: the amount of edge (holes) should not be to large. Probably want to choose 1st minima
plot(leroy.lhs, iso=TRUE, record=TRUE)
# Note (both plots): isopleth 10% contains 10% of locations; isopleth 100% contains 100% of the locations


## different plot but containing same info as above
par(mfrow=c(1,2))
par(list(mar=c(5, 6, 4, 2) + 0.1), bty="n")
iso.info.all <- do.call(rbind, lapply(leroy.lhs, function(myhs) do.call(rbind, 
                                                                        lapply(myhs$isos, function(myiso) data.frame(id = myhs[["id"]], 
                                                                                                                     mode = myhs[["mode"]], s = myhs[["s"]], param.val = myhs[[myhs[["mode"]]]], 
                                                                                                                     sort.metric = myiso[["sort.metric"]], myiso[["polys"]]@data[c("iso.level", "area", "edge.len")])))))
plot(I(edge.len/area)~param.val, type="n", data=iso.info.all, 
     xlab="Number of neighbours (k)", 
     ylab=expression(edge%/%area))
for(i in 1:length(unique(iso.info.all$iso.level))){
  tmp <- iso.info.all[iso.info.all$iso.level==unique(iso.info.all$iso.level)[i],]
  lines(I(edge.len/area)~param.val, type="l", data=tmp, lty=i)
}
legend("topright", as.character(unique((iso.info.all$iso.level))), lty=1:length(unique(iso.info.all$iso.level)), cex=0.6, bty="n")
par(mar=c(1,1,1,1))
plot(leroy.lhs[[5]]$isos[[1]]$polys, col=grey((0.7*seq(0.1,0.99,length=5))), border=NA)
points(leroy, col="#00000060", pch=16, cex=0.5)
lines(leroy, col="#00000030")
text(0,3000,"k-NNCH LoCoH for k=50", pos=4, cex=0.75)
legend(-1636, -2018, as.character(unique((iso.info.all$iso.level))), fill=grey((0.7*seq(0.1,0.99,length=5))), cex=0.6, bty="n")
par(mfrow=c(1,1))

#PS: need to take time to understand as they are sensitive
#     to any chnages
#   the above methods are assuming independent data
# but we want to take advantage of the correlated movement data


################
## dBBMM & UD ##
################
#PS: occurrence distribution

library(move)
leroy <- move(system.file("extdata","leroy.csv.gz",package="move"))
leroy <- spTransform(leroy, center=TRUE)
# check timeLag of data. If there are timelags shorter than intended, 
#use the argument "timestep" in the dBBMM function, to make sure calculation odes not take forever
summary(timeLag(leroy,"mins")) 
BB.leroy <- brownian.bridge.dyn(leroy, ext=.45, dimSize=150, location.error=20, margin=11, window.size=31)
plot(BB.leroy)
# Note to plot: 
# - all pixels sum up to 1 (total time tracked)
# - the values correspond to the proportion of the time tracked that the animal spent in that area
# - in this case, a pixel with value 0.035 means that leroy spend 3.5% from the total tracking time in that pixel 
# - these results are very useful to find out where the animal spend how much time, and e.g. relate it to environmental variables

## extract the utilization distribution (UD)
udleroy <- getVolumeUD(BB.leroy)
plot(udleroy, col=terrain.colors(100))

#PS: green areas include the highest 20% of locations

## from the ud object, also the contours can be extracted
plot(leroy, col="#00000060", pch=16, cex=0.5, bty="n", xaxt="n", yaxt="n", xlab=NA, ylab=NA)
lines(leroy, col="#00000030")
contour(udleroy, levels=c(0.5, 0.95), add=TRUE, lwd=c(2, 1), lty=c(2,1))
title("Dynamic brownian bridge")

## plotting the UD95 on google map
library(ggmap)
library(ggplot2)
cl95 <- raster2contour(BB.leroy, levels=0.95)
cl95LL <- spTransform(cl95, CRS("+proj=longlat"))
cl95df <- data.frame(do.call("rbind", coordinates(cl95LL)[[1]]))
cl95df$polyN <- rep(1:length(coordinates(cl95LL)[[1]]), lapply(coordinates(cl95LL)[[1]], nrow))
leroyDF <- as.data.frame(spTransform(leroy,"+proj=longlat"))
m <- get_map(bbox(extent(cl95LL)*1.5), zoom=13, source="google", maptype="hybrid")
ggmap(m)+geom_path(data=cl95df, aes(x=X1,y=X2,group=polyN),color="red")+
  geom_path(data=leroyDF, aes(x=location.long, y=location.lat),alpha=0.2)+
  geom_point(data=leroyDF, aes(x=location.long, y=location.lat),alpha=0.3, shape=20)+
  labs(x="",y="")+
  theme(axis.text=element_blank(),axis.ticks=element_blank())+ 
  theme(legend.position="none")



## checking for effect of margin and window size on the results
par(mfrow=c(3,3), mar=c(1,2,2,1))
margins <- c(15, 9, 3)
windows <- c(101, 67, 33)
runs <- expand.grid(margins, windows)
for(i in 1:nrow(runs)){
  BB.leroy <- brownian.bridge.dyn(leroy, dimSize=150, location.error=20, margin=runs[i,1],
                                  window.size=runs[i,2], time.step=2, ext=2)
  udleroy <- getVolumeUD(BB.leroy)
  udleroy99 <- udleroy
  udleroy99[udleroy99>0.99] <- NA
  udleroy99 <- trim(udleroy99,padding=5)
  contour(udleroy99, levels=c(0.5, 0.95), bty="n", xaxt="n", 
          yaxt="n", xlab=NA, ylab=NA, asp=1)
  mtext(paste("Margin = ", runs[i,1], sep=""), 2)
  mtext(paste("Window size = ", runs[i,2]), 3)
}
# Note to plot: no need to worry all to much about the window size and the margin, as do not have a major impact on the resutls



### effect of sampling frequency and tracking duration on area
dev.off()
par(mfrow=c(1,1))
par(list(mar=c(5, 4, 4, 2) + 0.1), bty="o")
set.seed(3628492)
steps <- 100000
prop=seq(0.01,1,0.01)

track <- as(simm.crw(date=1:steps, h=1, r=0.8), "Move")
thin <- lapply(prop, function(x) track[round(seq(1, steps, length.out=steps * x)), ])
short <- lapply(prop, function(x) track[1:round(steps * x),])
ThinAreas <- lapply(lapply(lapply(thin, as, "SpatialPoints"), kernelUD), kernel.area, percent=95)
ShortAreas <- lapply(lapply(lapply(short, as, "SpatialPoints"), kernelUD), kernel.area, percent=95)

plot(I(unlist(ThinAreas)/min(unlist(ThinAreas)))~seq(1:100), 
     xlab="Percent of the track", 
     ylab="Relative area", ylim=c(0,1.75), 
     type="l", lwd=2, lty=1)
lines(I(unlist(ShortAreas)/max(unlist(ShortAreas)))~seq(1:100), lty=2, lwd=2)
abline(h=1)
legend("topright", c("Thinned trajectory", "Shortened trajectory"), lty=c(1,2), lwd=c(2,2), bty="n")
# Note to plot: 
# - in this case using the kernelUD, when sampling frequency is lower, i.e. thinned trajectory,
# than the estimated UD is larger than when the sampling frequency is higher
# - the longer the trajectory, the larger the UD



