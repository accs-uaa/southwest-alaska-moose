## Objective: Combine well-performing models from different runs into a single file.

# Criteria for final model:
# 1. Lowest AIC
# 2. Visual assessments from variograms (both zoomed in @ 12 hour lag and zoomed out)
# 3. DOF > 5. From Christen Fleming: the default "pHREML" estimator requires a DOF of 4-5 for reasonable bias (ctmm-user Google group)
# 4. Confirm range residency (within the season of interest) by looking at tau[position] parameter

# Author: A. Droghini (adroghini@alaska.edu)
#         Alaska Center for Conservation Science

#### Load data and packages----
rm(list=ls())
source("scripts/init.R")
source("scripts/function-loadObject.R")

modelsToInclude <- read_excel(path= "output/topModels_annotated.xlsx",sheet = "models to include")

#### Combine model runs into a single list ----

# List of files to load
files <- list.files(path="pipeline/05c_ctmmModelSelection/temp/data",pattern="fitModels",full.names=TRUE)

# Create new names since every file loads as "fitModels"
fileNames <- list.files(path="pipeline/05c_ctmmModelSelection/temp/data",pattern="fitModels",full.names=FALSE)
fileNames <- gsub(".Rdata", "", fileNames)

# Load files (appended by date so they all load separately) and combine them into one master list
allRuns <- list(mapply(load_obj, files, fileNames))[[1]]
names(allRuns) = fileNames

#### Include only well-performing models ----

# Create empty list and vector to store results
finalMods = list()
finalNames <- as.character()

# Iterate through model runs and select only the models in "models to include"

for (i in 1:length(allRuns)) {
  listName <- names(allRuns)[i]
  date <- as.Date(unlist(strsplit(listName,split="_"))[2])
  modNames <- unique((modelsToInclude %>% filter(modelDate == date))$modelName)
  goodModels <- allRuns[[listName]][modNames]
  
  finalMods <- append(finalMods,list(goodModels))
  finalNames<- c(finalNames,listName)
}

# Add names to final list
# Drop lists with a length of 0 (these were model runs with no models to keep)
# Remove list hierarchy with model run dates
names(finalMods) <- as.character(modelNames)
finalMods <- Filter(length, finalMods)
finalMods <- flatten(finalMods)

# Select only top models from all possible models
finalNames <- names(finalMods)
finalMods <- lapply(1:length(finalMods), 
                    function(i) finalMods[[i]][1][[1]]) 
names(finalMods) <- finalNames

# Export and clear workspace
save(finalMods,file="pipeline/06c_selectFinalModels/finalModels.Rdata")
rm(list=ls())