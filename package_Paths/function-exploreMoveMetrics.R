# Objective: This function produces simple plots and summary statistics to examine empirical distributions of step lengths and turning angles. The output is a dataframe that is subset based on binary group membership.

# Author: A. Droghini (adroghini@alaska.edu)

# User-specified arguments ----

# 01. gpsData: a dataframe that can be converted into a move object. Coordinates for this dataset are in WGS 84.
# 02. group: binary group membership value (1 or 0) by which to subset data.

exploreMoveMetrics <-
  
  function(gpsData, group, step="log") {
    if (group == 1) {
      gpsData <- gpsData %>%
        dplyr::filter(calfStatus == 1)
      
      cat("Movement metrics for ... cows with calf \n")
      
    } else {
      gpsData <- gpsData %>%
        dplyr::filter(calfStatus == 0)
      
      cat("Movement metrics for ... cows without calf \n")
    }
    
    tracks <- move::move(
      gpsData$longX,
      gpsData$latY,
      time = gpsData$datetime,
      animal = gpsData$mooseYear_id,
      sensor = gpsData$sensor_type,
      proj = sp::CRS(
        "+proj=longlat +datum=WGS84 +no_defs +ellps=WGS84 +towgs84=0,0,0"
      )
    )
    
    gpsData$time_interval <-
      unlist(lapply(move::timeLag(tracks, units = "hours"),  c, NA))
    gpsData$bearing_degrees <-
      unlist(lapply(move::angle(tracks), c, NA))
    gpsData$distance_meters <-
      unlist(lapply(move::distance(tracks), c, NA))
    
    hist(gpsData$bearing_degrees,
         main = "Empirical distribution of bearings",
         xlab = "Bearing (degrees)")
    
    if (step == "untransformed") {
    hist(gpsData$distance_meters,
         main = "Empirical distribution of step lengths",
         xlab = "Distance (meters)")
    } else {
      hist(log(gpsData$distance_meters),
         main = "Log-transformed distribution of step lengths",
         xlab = "Logarithmic distance (meters)") }
    
    cat("Descriptive statistics of step length \n")
    print(summary(gpsData$distance_meters))
    return(gpsData)
  }
