# Objective: Plot Net Squared Displacement for every individual. Export plots.

# NSD is expressed in sq km
# This function assumes the data are a adehabitatLT::ltraj object
# Converting to an ltraj object automatically calculates NSD and stores it in an R2n column, which this function makes use of

# Author: A. Droghini (adroghini@alaska.edu)
#         Alaska Center for Conservation Science


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
