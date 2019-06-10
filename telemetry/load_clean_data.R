## Adopted script from AniMove 2019, script called 'Lesson2.2_2019_LoadExportData.R'

# This script starts with accessing the SW moose data file from 
# Movebank, which was standard practice during the workshop. This
# ensured that the data was standardized.

library(move)  

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
cred <- movebankLogin() # specially useful when sharing scripts with colleagues

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
moose.wnames <- getMovebankData(study="SW Alaska moose", animalName = c("M1718H20", "M1718H10", "M1718H11", "M1718H06", "M1718H07",
                                                                        "M1718H02", "M1718H13", "M1718H08", "M1718H15", "M1718H12",
                                                                        "M1718H01", "M1718H18", "M1718H14", "M1718H16", "M1718H04",
                                                                        "M1718H05", "M1718H03", "M1718H19", "M1718H17", "M1718H09"), login=cred)
# provides the same info, only by tag id

#Continue here on Tues, 6/11/19 with data cleaning and exploration

head(moose.wnames)
summary(moose)


## get only bat "191"
#moose.M1718H01 <- getMovebankData(study="SW Alaska moose", animalName="	M1718H01", login=cred)
#bat191

## get data for a specific time range e.g. between "2002-06-02 23:06:15"
## and "2002-06-11 22:18:25". Time format: 'yyyyMMddHHmmssSSS'
bats.subset <- getMovebankData(study="Parti-colored bat Safi Switzerland",
                               login=cred,timestamp_start="20020602230615000",
                               timestamp_end="20020611221825000")
bats.subset


## when there is an error because duplicated timestamps are present. This is one solution, but to use with care. More further down
# mystudy <- getMovebankData(study="MyStudyName", login=cred, removeDuplicatedTimestamps=T)



###------------------------------------------------------###
### 2. Reading in a .csv file downloaded from a Movebank ###
###------------------------------------------------------###
bats <- move("Parti-colored bat Safi Switzerland.csv")
bats

## ---- also read EvData .zip files or tar-compressed csv exports -----------------------------
# PS: could be useful when the .csv file is huge
batsTemp <- move("Parti-colored bat Safi Switzerland-5752797914261819198.zip")
# this data set was annotated with temperature data with the EnvData tool from movebank


###----------------------------------------------###
### 3. Creating a move object from any data set: ###
###----------------------------------------------###
# read the data and store in a data frame
file <- read.csv("Parti-colored bat Safi Switzerland.csv", as.is=T)
str(file)

# first make sure the date/time is correct
# PS: match the data forma in the file
file$timestamp <- as.POSIXct(file$timestamp,format="%Y-%m-%d %H:%M:%S",tz="UTC")

# also ensure that timestamps and individuals are ordered
file <- file[order(file$individual.local.identifier, file$timestamp),]

# convert a data frame into a move object
Bats <- move(x=file$location.long,y=file$location.lat,
             time=as.POSIXct(file$timestamp,format="%Y-%m-%d %H:%M:%S",tz="UTC"),
             data=file,proj=CRS("+proj=longlat +ellps=WGS84"),
             animal=file$individual.local.identifier, sensor="gps")
Bats


###---------------------------------------------###
### download data from Movebank Data Repository ###
###---------------------------------------------###
repos <- getDataRepositoryData("doi:10.5441/001/1.2k536j54")
repos


###---------------------------------------------------###
### example of how to deal with duplicated timestamps ###
###---------------------------------------------------###

### buffalo data 
buffalo <- move("Kruger African Buffalo, GPS tracking, South Africa.csv.gz")

## one solution is to use the argument removeDuplicatedTimestamps=T. But use with care! as duplicates are removed randomly. Additional information could be lost.
buffaloNoDupl <- move("Kruger African Buffalo, GPS tracking, South Africa.csv.gz", removeDuplicatedTimestamps=T)

## example to remove duplicates timestamps in a controlled way:
## create a data frame
buffalo.df <- read.csv('Kruger African Buffalo, GPS tracking, South Africa.csv.gz', as.is=TRUE)

## get a quick overview
head(buffalo.df, n=2)

## first make sure the date/time is correct
buffalo.df$timestamp <- as.POSIXct(buffalo.df$timestamp, format="%F %T ", tz="UTC")

## also ensure that timestamps and individuals are ordered
buffalo.df <- buffalo.df[order(buffalo.df$individual.local.identifier, buffalo.df$timestamp),]

## get the duplicated timestamps
dup <- getDuplicatedTimestamps(buffalo.df)
dup[1]

## get an overview of the amount of duplicated timestamps
table(unlist(lapply(dup,function(x)length(x)))) 

buffalo.clean <- buffalo.df
## we will keep the posititon that results in the shortest distance between the previous and the next location
## A while loop will ensure that the loop continues untill each duplicate is removed
## ==> loop starts here
while(length(dup <- getDuplicatedTimestamps(buffalo.clean))>0){
  allrowsTOremove <- lapply(1:length(dup), function(x){
    rown <- dup[[x]]
    # checking if the positions are exaclty the same for all timestamps
    if(any(duplicated(buffalo.clean[rown,c("timestamp", "location.long", "location.lat", "individual.local.identifier")]))){
      dup.coor <- duplicated(buffalo.clean[rown,c("timestamp", "location.long", "location.lat", "individual.local.identifier")])
      rowsTOremove <- rown[dup.coor] # remove duplicates
    }else{
      # subset for the individual, as distances should be measured only within the individual
      # create a row number ID to find the duplicated time stamps in the subset per individual
      buffalo.clean$rowNumber <- 1:nrow(buffalo.clean)
      ind <- unlist(strsplit(names(dup[x]),split="|", fixed=T))[1]
      subset <- buffalo.clean[buffalo.clean$individual.local.identifier==ind,]
      
      # if the duplicated positions are in the middle of the table
      if(subset$rowNumber[1]<rown[1] & subset$rowNumber[nrow(subset)]>max(rown)){
        # calculate total distance throught the first alternate location
        dist1 <- sum(distHaversine(subset[subset$rowNumber%in%c((rown[1]-1),(max(rown)+1)),c("location.long", "location.lat")],
                                   subset[subset$rowNumber==rown[1],c("location.long", "location.lat")]))
        # calculate total distance throught the second alternate location
        dist2 <- sum(distHaversine(subset[subset$rowNumber%in%c((rown[1]-1),(max(rown)+1)),c("location.long", "location.lat")],
                                   subset[subset$rowNumber==rown[2],c("location.long", "location.lat")]))
        # omit the aternate location that produces the longer route
        if(dist1<dist2){rowsTOremove <- rown[2]}else{rowsTOremove <- rown[1]}
      }
      
      # incase the duplicated timestamps are the first positions
      if(subset$rowNumber[1]==rown[1]){
        dist1 <- sum(distHaversine(subset[subset$rowNumber==(max(rown)+1),c("location.long", "location.lat")],
                                   subset[subset$rowNumber==rown[1],c("location.long", "location.lat")]))
        dist2 <- sum(distHaversine(subset[subset$rowNumber==(max(rown)+1),c("location.long", "location.lat")],
                                   subset[subset$rowNumber==rown[2],c("location.long", "location.lat")]))
        if(dist1<dist2){rowsTOremove <- rown[2]}else{rowsTOremove <- rown[1]}
      }
      
      # incase the duplicated timestamps are the last positions
      if(subset$rowNumber[nrow(subset)]==max(rown)){
        dist1 <- sum(distHaversine(subset[subset$rowNumber==(rown[1]-1),c("location.long", "location.lat")],
                                   subset[subset$rowNumber==rown[1],c("location.long", "location.lat")]))
        dist2 <- sum(distHaversine(subset[subset$rowNumber==(rown[1]-1),c("location.long", "location.lat")],
                                   subset[subset$rowNumber==rown[2],c("location.long", "location.lat")]))
        if(dist1<dist2){rowsTOremove <- rown[2]}else{rowsTOremove <- rown[1]}
      }
    }
    return(rowsTOremove)
  })
  buffalo.clean <- buffalo.clean[-unique(sort(unlist(allrowsTOremove))),]
  buffalo.clean$rowNumber <- NULL
}
## ==> and ends here

# define the data.frame as a move object after cleaning
buffalo <- move(x=buffalo.clean$location.long,
                y=buffalo.clean$location.lat,
                time=buffalo.clean$timestamp,
                data=buffalo.clean,
                proj=CRS("+proj=longlat +datum=WGS84"),
                animal=buffalo.clean$individual.local.identifier,
                sensor=buffalo.clean$sensor.type)



#################
## PROJECTION ###
#################
## check projection 
projection(Bats)

## reproject 
BatsProj <- spTransform(Bats, CRSobj="+proj=utm +zone=32 +ellps=WGS84 +datum=WGS84 +units=m +no_defs")
projection(BatsProj)

#PS: Can search spTransform for Move object for assistance

##############################
### MOVE/MOVESTACK OBJECTS ###
##############################

### Move object (1 indiv) ####
bat191
str(bat191)
## access the information 
timestamps(bat191)[1:5]
coordinates(bat191)[1:5,]
namesIndiv(bat191)
n.locs(bat191)
idData(bat191)


### Movestack object (multiple indiv) #####
buffalo
str(buffalo)
## access the information 
n.indiv(buffalo)  # # of individuals
namesIndiv(buffalo)   #their names
n.locs(buffalo)  # # of locations
idData(buffalo)  # the id's

# could also use buffalo@   and it will show you the available options

## get a specific individual
Queen <- buffalo[['Queen']]
Queen
## or several
CillaGabs <- buffalo[[c("Cilla",'Gabs')]]
CillaGabs

## split a movestack
# PS: split provides a list of move objects, i.e. for each individual
#        many of the analyses can only be done for 1 individual at a time
#        Below, we then have each of the 5 buffalo split up for analysis separately
buffalo.split <- split(buffalo)

## stack a list of move objects 
# PS: need to make sure you update the time zone as it is lost during the preceding step
buffalo.stk <- moveStack(buffalo.split, forceTz="UTC")
buffalo.stk@timestamps[1]

buffalo.stk2 <- moveStack(buffalo.split) # if argument forceTz is not stated, the timestamp is converted to the computer timezone
buffalo.stk2@timestamps[1]  #PS: notice that this gives you a different time stamp than above

buffalo.stk3 <- moveStack(list(CillaGabs,Queen),forceTz="UTC")



########################
#### OUTPUTTING DATA ###
########################

## save the move object for later
# PS: preferred method since it is ready as a move object for analysis
save(buffalo, file="buffalo_cleaned.Rdata")

## save as a text file
buffaloDF <- as.data.frame(buffalo)
write.table(buffaloDF, file="buffalo_cleaned.csv", sep=",", row.names = FALSE)

## save as a shape file
writeOGR(buffalo, getwd(), layer="buffalo", driver="ESRI Shapefile")

## kml or kmz of movestack ##
library("plotKML")
# open a file to write the content
kml_open('buf.kml')
# write the movement data individual-wise
for(i in levels(trackId(buffalo)))
  kml_layer(as(buffalo[[i]],'SpatialLines'))
# close the file
kml_close('buf.kml')


## export KML using writeOGR ##
for(i in 1:nrow(buffalo@idData)){
  writeOGR(as(buffalo[[i]], "SpatialPointsDataFrame"),
           paste(row.names(buffalo@idData)[i],
                 ".kml", sep=""),
           row.names(buffalo@idData)[i], driver="KML")

  writeOGR(as(buffalo[[i]], "SpatialLinesDataFrame"),
         paste(row.names(buffalo@idData)[i],
               "-track.kml", sep=""),
         row.names(buffalo@idData)[i], driver="KML")

  print(paste("Exported ", row.names(buffalo@idData)[i],
            " successfully.", sep=""))
}


#########################
### NON LOCATION DATA ###
#########################
## A. Download non location data in move object 
#PS: if you want to also download the extra data, such as accelerometer data
stork <- getMovebankData(study="MPIO white stork lifetime tracking data (2013-2014)",login=cred,
                         animalName="DER AR439",includeExtraSensors=TRUE)
str(stork)
## extract the data frame containing the data for the non-location sensors
stork.acc <- as.data.frame(unUsedRecords(stork))
str(stork.acc)

## B. Download data as a data.frame 
acc <- getMovebankNonLocationData(study="MPIO white stork lifetime tracking data (2013-2014)",
                                  sensorID="Acceleration",
                                  animalName="DER AR439", login=cred)
str(acc)

## sensors available in a specific study
getMovebankSensors(study="MPIO white stork lifetime tracking data (2013-2014)", login=cred)[1:10,]

## all available sensor types on Movebank
getMovebankSensors(login=cred)[,3:5]

## visualize and get basic stats of acceleration data (currently only for eObs tags)
## moveACC : https://gitlab.com/anneks/moveACC




