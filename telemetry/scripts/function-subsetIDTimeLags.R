# This function takes a moose ID and a timeStep. It returns a dataframe that includes data for only the specified unit. It also prints row indices for which the fix rate is greater than the threshold specified (timeStep). Time units of timeStep should match units of date/time column in dataframe)

subsetTimeLags <- function(id,timeStep) {
  n = which(ids==id)
  subsetID <- gpsMove[[n]]
  subsetID <- subsetID@data
  timeLag <- timeLags[[n]]
  cat("Row indices with time step greater than",timeStep,":")
  print(which(timeLag>timeStep)) 
  return(subsetID)
}


