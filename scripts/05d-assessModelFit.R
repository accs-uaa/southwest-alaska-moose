# Objectives: Assess model fit and create a subset that includes only the "decent" ones for which home ranges will be generated. Model fit is assessed in several ways:

# 1. AIC

# 2. DOF and RMPSE

# 3. Visual estimate- variogram with theoretical plotted overlain.

# Author: A. Droghini (adroghini@alaska.edu)
#         Alaska Center for Conservation Science

#### Load packages and data ----
rm(list=ls())
source("scripts/init.R")
load("pipeline/05c_ctmmModelSelection/temp/data/fitModels.Rdata")
load("pipeline/05c_ctmmModelSelection/temp/data/modelData.Rdata")

names(fitModels) == names(calibratedData)

#### View model selection table ----

# Place model selection parameters in df
modelSummary <- lapply(fitModels,function(x) summary(x))
modelSummary <- plyr::ldply(modelSummary, rbind)

# Place model name in df
modelRows <- lapply(fitModels,function(x) row.names(summary(x)))
modelRows <- plyr::ldply(modelRows, rbind)
modelRows <- modelRows %>% 
  pivot_longer(cols = -.id,
               values_to="model",names_to="rank",
               values_drop_na = TRUE)

modelSummary <- cbind(modelRows,modelSummary)
# Delete duplicate id column. Join doesn't work because .id is not a unique key
modelSummary <- modelSummary[,-4]

# Subset only the highest ranked models
topModels <- distinct(modelSummary,.id, .keep_all=TRUE) 

#### Export tables ----
# write_csv forces UTF-8 encoding, but will have to select Data/From Text in MS Excel if you want the symbols to show up currently
names(modelSummary) <- enc2utf8(names(modelSummary))
write_csv(modelSummary,path=paste("pipeline/05d_assessModelFit/temp/modelSelection/allModels_",Sys.Date()-1,".csv",sep=""))
write_csv(topModels,path=paste("pipeline/05d_assessModelFit/temp/modelSelection/topModels_",Sys.Date()-1,".csv",sep=""))

rm(topModels,modelRows,modelSummary)

#### Plot variogram with model fit----
filePath <- paste("pipeline/05d_assessModelFit/temp/variograms/",Sys.Date()-1,"/",sep="")

lapply(1:length(calibratedData), 
       function (a) {
         plotName <- paste(names(fitModels[a]),sep="_")
         plotPath <- paste(filePath,plotName,sep="")
         finalName <- paste(plotPath,"png",sep=".")
         
         plot(variogram(calibratedData[[a]], dt = 2 %#% "hour",CI="Gauss"),
              CTMM=fitModels[[a]][1:2],
              col.CTMM=c("red","blue","purple","green"),
              fraction=1,
              ylim=c(0,8000000),
              level=c(0.5,0.95),
              main=names(fitModels[a]))
         
         dev.copy(png,finalName)
         dev.off()
         
       }
)

### Zoomed in plot

lapply(1:length(calibratedData), 
       function (a) {
         plotName <- paste(names(fitModels[a]),"zoomIn",sep="_")
         plotPath <- paste(filePath,plotName,sep="")
         finalName <- paste(plotPath,"png",sep=".")
         
         plot(variogram(calibratedData[[a]], dt = 2 %#% "hour",CI="Gauss"),
              CTMM=fitModels[[a]][1:2],
              col.CTMM=c("red","blue","purple","green"),
              fraction=1,
              xlim = c(0,12 %#% "hour"),
              level=c(0.5,0.95),
              main=names(fitModels[a]))
         
         dev.copy(png,finalName)
         dev.off()
         
       }
)

rm(filePath)