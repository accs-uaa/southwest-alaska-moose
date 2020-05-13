# Objective: Plot Mean Squared Displacement for every individual. Export plots.

# estimates MSD over 84 observations (width)
# assuming a gap-free, two-hour fix rate, want a rolling mean to be taken every week
# 12 obs per day * 7 days = 84 observations

# rollapplyr defaults to align="right" i.e. the mean is calculated based on the observation + previous timesteps only
# partial = TRUE means that a rolling mean is calculated even though no. of obs < specified width (otherwise the first value for the rolling mean would start at the nth observation and all others would be dropped or NA if fill=NA)

# Adapted from: Singh, N. J., Allen, A. M., & Ericsson, G. 2016. Quantifying Migration Behaviour Using Net Squared Displacement Approach: Clarifications and Caveats. PLoS ONE. https://doi.org/10.1371/journal.pone.0149594

# Author: A. Droghini (adroghini@alaska.edu)

plotMSD <- function(data){
  require(ggplot2)
  require(zoo)
  require(lubridate)

  listToSeq <- lapply(data, function(x)as.data.frame(x, stringsAsFactors = FALSE))

  calculateMSD <- function(data, name){
    NSD <- data$R2n * 0.000001
    date <- data$date
    zooObj <- zoo(NSD,date)
    startDate <- as.character(month(date[1],label=TRUE,abbr=TRUE))
    startYear <- as.character(year(date[1]))
    startMonth <- as.character(month(date[1]))
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
      ggtitle(paste("Mean squared displacement for",name,"\n",
                    "Start date: 01",startDate)) +
      theme_minimal() +
      theme(plot.title = element_text(hjust = 0.5))

    # save plot
    filePath <- paste0("pipeline/04d_exploreNSD/temp/", name, "_MSD_",startYear,"_",startMonth,".png")

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
