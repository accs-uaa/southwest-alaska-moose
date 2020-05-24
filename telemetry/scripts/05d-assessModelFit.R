# Objectives: Assess model fit and create a subset that includes only the "decent" ones for which home ranges will be generated. Model fit is assessed in several ways:

# 1. AIC

# 2. DOF and RMPSE

# 3. Visual estimate- variogram with theoretical plotted overlain.

# Author: A. Droghini (adroghini@alaska.edu)
#         Alaska Center for Conservation Science

#### Load packages and data ----
rm(list=ls())
source("scripts/init.R")
load("pipeline/05c_ctmmModelSelection/fitModels.Rdata")

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
topModel <- distinct(modelSummary,.id, .keep_all=TRUE) 

# Export 
# write_csv forced UTF-8 encoding, but will have to select Data/From Text in MS Excel if you want the symbols to show up currently
names(modelSummary) <- enc2utf8(names(modelSummary))
write_csv(modelSummary,"output/modelRuns/modelSelectionTable.csv")
write_csv(topModel,"output/modelRuns/topModels.csv")

# Can you reject certain models based on DOF alone???

#### Plot variogram with model fit----
filePath <- "pipeline/05d_ctmmModelSelection/temp/"

lapply(1:length(calibratedData), 
       function (a) {
         plotName <- paste(names(fitModels[a]),"modelFit",sep="_")
         plotPath <- paste(filePath,plotName,sep="")
         finalName <- paste(plotPath,"png",sep=".")
         
         plot(variogram(calibratedData[[a]], dt = 2 %#% "hour"),
              CTMM=fitModels[[a]][1],
              col.CTMM=c("red","purple","blue","green"),
              fraction=0.65,
              level=0.5,
              main=names(fitModels[a]))
         
         dev.copy(png,finalName)
         dev.off()
         
       }
)

# Can also look at zoomed in plot
# Not coded
# xlim <- c(0,12 %#% "hour")
# plot(vario,CTMM=fitOneId,col.CTMM=c("red","purple","blue","green"),xlim=xlim,level=0.5)

rm(filePath)

#### Select seasonal IDs that have decent model fits----
# Only pick the top-ranking model for each seasonal ID
names(fitModels)
decentModels <- names(fitModels)[c(1,3,4,5,7)]
decentModels <- fitModels[decentModels]
decentModels <- lapply(1:length(decentModels), 
                       function(i) decentModels[[i]][1][[1]]) # Wow, so many nested lists :-/

# Export
save(decentModels,file="pipeline/05d_ctmmModelSelection/decentModels.Rdata")

rm(list=ls())