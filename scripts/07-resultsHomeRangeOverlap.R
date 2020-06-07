# Objective: Describe proportion of home range overlap across seasons.

# Author: A. Droghini (adroghini@alaska.edu)
#         Alaska Center for Conservation Science

#### Load packages and data----
rm(list=ls())
source("scripts/init.R")

gc()
memory.limit(10000000000000)

load("pipeline/06e_generateHomeRanges/homeRanges03.Rdata")
#### Generate seasonal pair combinations----
modNames <- as.list(names(homeRanges))
comboNames <- expand.grid(x = modNames, y = modNames)
comboNames$x <- as.character(comboNames$x)
comboNames$y <- as.character(comboNames$y)

### Get rid of redundant entries

# Remove mirrored pairs
# Solution from: https://stackoverflow.com/questions/17017374/how-to-expand-grid-with-string-elements-the-half
comboNames <- t(apply(comboNames, 1, sort))
comboNames <- as.data.frame(comboNames[!duplicated(comboNames),])

# Remove duplicates
# Remove pairs with IDs that aren't the same
comboNames <- comboNames %>% 
  dplyr::rename(x = V1, y = V2) %>% 
  filter(!x==y) %>% 
  mutate(id.x = word(x,start=1,sep="_"),
         id.y = word(y,start=1,sep="_")) %>% 
  filter(id.x == id.y)

rm(modNames)

#### Calculate overlap between seasonal pairs ----

# Create list to store results
overlapResults <- list()

# Calculate overlap for each pair (x-y) in comboNames
# What is the non- for loop way to do this?
Sys.time()
for (i in 1:nrow(comboNames)) {
  name01 <- comboNames$x[i]
  name02 <- comboNames$y[i]
  overlapResults[[i]] <- overlap(c(homeRanges[which(names(homeRanges)==name01)],homeRanges[which(names(homeRanges)==name02)]))
}
Sys.time()

rm(i,name01,name02)

#### Format data ----
overlapResults <- data.frame(matrix(unlist(overlapResults), 
                                    nrow=length(overlapResults), 
                                    byrow=T))

overlapResults <- overlapResults %>% 
  mutate(id.x = comboNames$x,
         id.y = comboNames$y,
         seasons = paste(word(id.x,start=3,sep="_"),
                         word(id.x,start=2,sep="_"),
                         word(id.y,start=3,sep="_"),
                         word(id.y,start=2,sep="_"),sep="_")) %>% 
  dplyr::select(id.x,id.y,X2,X6,X10,seasons) %>% 
  dplyr::rename(low = X2,est = X6,high = X10)

rm(modNames,comboNames)

#### Export table----
write_csv(overlapResults,"output/homeRangeOverlap.csv")

#### Plot results ----
cbPalette <- c("#999999", "#E69F00", "#56B4E9", "#009E73", "#F0E442", "#0072B2", "#D55E00", "#CC79A7")

overlapResults %>% mutate(id.no = seq(1:nrow(overlapResults))) %>% 
  ggplot(aes(y=est,x=id.no,fill=seasons))+
  geom_point(size=2,pch=21) + 
  scale_fill_manual(values=cbPalette) +
  scale_x_continuous(name="Home range pairs") +
  scale_y_continuous(name="Proportion of overlap") +
  theme_minimal() +
  theme(legend.position = "right",axis.text.x=element_blank())

rm(list=ls())