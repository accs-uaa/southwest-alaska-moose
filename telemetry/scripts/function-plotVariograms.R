# This function takes an as.telemetry list and returns the two variogram plots in the ctmm variogram vignette: https://ctmm-initiative.github.io/ctmm/articles/variogram.html

# Code was modified from Dason: https://stackoverflow.com/questions/9048375/extract-names-of-objects-from-list

varioPlot <- function(telemList){
  require(ctmm)
  
  listToSeq <- lapply(telemList, function(x) as.data.frame(x, stringsAsFactors = FALSE))
  
  # Takes a dataframe and the text you want to display
  drawPlot <- function(data, name){
    
    variog <- variogram(data,dt = 2 %#% "hour")
    level <- c(0.5,0.95) # 50% and 95% CIs
    xlim <- c(0,12 %#% "hour") # 0-12 hour window
    
    # Zoomed in plot
    plotName <- paste(name,"zoomIn",sep="_")
    filePath <- paste("pipeline/04_exploreVariogram/temp/",plotName,sep="")
    finalName <- paste(filePath,"png",sep=".")
    
    plot(variog,xlim=xlim,level=level)
    title(paste(name,"zoomed in",sep=" "))
    dev.copy(png,finalName)
    dev.off()
    
    # Zoomed out plot
    plotName <- paste(name,"zoomOut",sep="_")
    filePath <- paste("pipeline/04_exploreVariogram/temp/",plotName,sep="")
    finalName <- paste(filePath,"png",sep=".")
    
    plot(variog,fraction=0.65,level=level)
    title(paste(name,"zoomed out",sep=" "))
    dev.copy(png,finalName)
    dev.off()
    
    }
  
  # Create sequence 1,...,length(listToSeq)
  # Loops over that and then create an anonymous function
  # to send in the information you want to use.
  lapply(seq_along(listToSeq), 
         function(i){drawPlot(listToSeq[[i]], names(listToSeq)[i])})

}