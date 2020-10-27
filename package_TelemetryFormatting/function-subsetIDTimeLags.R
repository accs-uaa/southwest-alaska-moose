# This function takes a moose ID and a timeStep. It returns a dataframe that includes data for only the specified unit. It also prints row indices for which the fix rate is less than or greater than the threshold specified (timeStep). Time units of timeStep should match units of date/time column in dataframe)

# Step lengths can be calculated by specifying stepLengths = TRUE

subsetTimeLags <- function(id,minTimeStep,maxTimeStep,stepLengths = NULL) {
  require(tidyverse)
  n = which(ids==id)
  subsetID <- gpsMove[[n]]
  subsetID <- subsetID@data
  timeLag <- timeLags[[n]]
  cat("Evaluating...",id,'\n',"Row indices with time step less than",minTimeStep,":")
  print(which(timeLag<minTimeStep)) 
  cat("Row indices with time step greater than",maxTimeStep,":")
  print(which(timeLag>maxTimeStep)) 
 
  if(!is.null(stepLengths)) 
    subsetID <- subsetID %>% 
    dplyr::mutate(z=Easting+1i*Northing, 
                  steps=c(NA,diff(z)), #NA for 1st step length
                  steplength_m=Mod(steps)) %>%
    dplyr::select(-c(z,steps))
  
  return(subsetID)
}


