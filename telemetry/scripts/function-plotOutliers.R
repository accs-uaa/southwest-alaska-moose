# Produces a quick plot (and a subset dataframe if output=TRUE) to visualize spatial outliers

plotOutliers <- function(data,minIndex,maxIndex,output = NULL) {
  require(ggmap)
  
  temp <- data[minIndex:maxIndex,c(1:5,8:9,18:21)]
  print(unique(temp$deployment_id))
  studyArea<-matrix(c(min(temp$longX)-0.1,min(temp$latY)-0.07,
                      max(temp$longX)+0.05,max(temp$latY))+0.05, nrow = 2)
  mapData <- get_map(studyArea, zoom=9, source="google", maptype="terrain")
  ggmap(mapData)+
    geom_path(data=temp, aes(x=longX, y=latY))
  
  if(!is.null(output)) 
  return(temp)
  }