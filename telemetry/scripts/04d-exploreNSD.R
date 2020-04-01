library(adehabitatLT)
library(tidyverse)
load("pipeline/03b_cleanLocations/cleanLocations.Rdata")

idsToSelect<-c("M30102")

# Create spatial object----

# Convert move object to a data.frame 
# Testing stuff to figure out the best way to deal with move<-->data.frame conversion
mooseData <- gpsMove@data
xy <- gpsMove@coords
ids <- gpsMove@trackId
timestamps <- gpsMove@timestamps

dataLT <- as.ltraj(xy,timestamps,ids)
names(dataLT) <- unique(ids)

# Function for plotting NSD over time for each individual
plotNSD <- function(telemList){
  require(ggplot2)
  
  listToSeq <- lapply(telemList, function(x)as.data.frame(x, stringsAsFactors = FALSE))
  
  drawPlot <- function(data, name){
   
    ggplot(data = data) +
      geom_line(
        aes(x = date, y = R2n * 0.000001),
        color = "#09557f",
        alpha = 0.6,size = 0.6) +
      labs(x = "Time",
           y = "NSD (km^2)") +
      scale_x_datetime(position = "top",
        date_breaks = "4 months",
        date_minor_breaks = "1 month",
        date_labels = "%Y %b"
      ) +
      ggtitle(paste("Net squared displacement for",name)) +
  theme_minimal() +
      theme(plot.title = element_text(hjust = 0.5))
  
    # save plot
    filePath <- paste0("pipeline/04d_exploreNSD/temp/",name,".png")
    
    ggsave(
      filePath,
      device = "png",
      scale = 1,
      width = 50,
      height = 20,
      units = "cm",
      dpi = 300)
 
  }

  lapply(seq_along(listToSeq), function(i){drawPlot(listToSeq[[i]], names(listToSeq)[i])})
  
}

plotNSD(dataLT)
        