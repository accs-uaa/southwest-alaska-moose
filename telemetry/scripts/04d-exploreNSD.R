# Objectives: Plot Net Squared Displacement (NSD) and Mean Squared Displacement (MSD) for each moose.
# MSD function adapted from: Singh, N. J., Allen, A. M., & Ericsson, G. (2016). Quantifying Migration Behaviour Using Net Squared Displacement Approach: Clarifications and Caveats. PLoS ONE. https://doi.org/10.1371/journal.pone.0149594

# Author: A. Droghini (adroghini@alaska.edu)

# Load packages and data----
rm(list=ls())
library(adehabitatLT)
library(tidyverse)
library(zoo)
load("pipeline/03b_cleanLocations/cleanLocations.Rdata")

# Create spatial object----

# Convert move object to a data.frame 
# Testing stuff to figure out the best way to deal with move<-->data.frame conversion
mooseData <- gpsMove@data
xy <- gpsMove@coords
ids <- gpsMove@trackId
timestamps <- gpsMove@timestamps

dataLT <- as.ltraj(xy,timestamps,ids)
names(dataLT) <- unique(ids)

rm(mooseData,xy,ids,timestamps,gpsMove)

# Plot Net Squared Displacement----
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
    filePath <- paste0("pipeline/04d_exploreNSD/temp/",name,"_NSD.png")
    
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


# Plot Mean Squared Displacement----
# estimate MSD over 1 week
# ideally should use interpolated data for this because rollapplyr works on no of observations regardless of whether data are gappy or not
# for now, assuming even two-hour fix rate, want a rolling mean to be taken every 12 per day * 7 days = 84 observations
# rollapplyr defaults to align="right". means that the mean is calculated based on the observation + previous timesteps only
# partial = TRUE means that a rolling mean is calculated even though no. of obs < specified width (otherwise the first value for the rolling mean would start at the nth observation and all others would be dropped or NA if fill=NA)

plotMSD <- function(data){
  require(ggplot2)
  require(zoo)
  
  listToSeq <- lapply(data, function(x)as.data.frame(x, stringsAsFactors = FALSE))
  
  calculateMSD <- function(data, name){
    
    NSD <- data$R2n * 0.000001
    date <- data$date
    zooObj <- zoo(NSD,date)
    
    MSD <- rollapplyr(zooObj,width=84,partial=TRUE,FUN = mean)
    MSD <- coredata(MSD)
    
    ggplot() +
      geom_line(
        aes(x = date, y = MSD),
        color = "#09557f",
        alpha = 0.6,size = 0.6) +
      labs(x = "Time",
           y = "MSD (km^2)") +
      scale_x_datetime(position = "top",
                       date_breaks = "3 months",
                       date_minor_breaks = "1 month",
                       date_labels = "%Y %b"
      ) +
      ggtitle(paste("Mean squared displacement for",name)) +
      theme_minimal() +
      theme(plot.title = element_text(hjust = 0.5))
    
    # save plot
    filePath <- paste0("pipeline/04d_exploreNSD/temp/", name, "_MSD.png")
    
    ggsave(
      filePath,
      device = "png",
      scale = 1,
      width = 50,
      height = 20,
      units = "cm",
      dpi = 300)
    
  }

  lapply(seq_along(listToSeq), function(i){calculateMSD(listToSeq[[i]], names(listToSeq)[i])})
  
}

plotMSD(dataLT)

# Clean workspace----
rm(plotMSD,plotNSD,dataLT)
