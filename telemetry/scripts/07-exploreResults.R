# Objectives:

# 1. Describe home range size
# 2. Describe philopatry: % overlap across years
# 3. What proportion of the population are (long-distance) migrants? For this we can look at:
  # a) % overlap between seasonal home ranges
  # b) distance between seasonal home ranges
# 4. Relate variation in home range size and season to environmental covariates

# Author: A. Droghini (adroghini@alaska.edu)
#         Alaska Center for Conservation Science

#### Load packages and data----
rm(list=ls())
source("scripts/init.R")
load("pipeline/06e_generateHomeRanges/homeRanges.Rdata")

#### Explore results: Home range size ----
hrSize <- lapply(1:length(homeRanges), 
                 function(i) 
                   summary(homeRanges[[i]])$CI)

names(hrSize) <- names(homeRanges)

# Convert to dataframe 
# Results are in sq. km
hrSize <- ldply (hrSize, data.frame)

# Format data frame for easy analyses
hrSize <- hrSize %>% 
  mutate(season = word(.id,start=3,sep="_"),
         year = word(.id,start=2,sep="_"),
         id = word(.id,start=1,sep="_")) %>% 
  rename(modelName = .id) %>% 
  dplyr::select(modelName,season,year,id,everything())

# Summarize home range size by season
hrSize %>% group_by(season) %>% 
               summarise(
                        av.est = mean(est),
                         sd.est = sd(est),
                         max.est = max(est),
                        min.est = min(est),
                         n = length(est))

# Plotting parameters
cbPalette <- c("#999999", "#E69F00", "#56B4E9", "#009E73", "#F0E442", "#0072B2", "#D55E00", "#CC79A7")

hrSize %>%
  ggplot(aes(x=est,fill = factor(season))) + 
  geom_histogram(binwidth=20,color="grey20")  + 
  scale_fill_manual(values=cbPalette,name="Season") +
  scale_x_continuous(name = "Home range size (sq. km)",breaks=seq(0,160,by=20))+
  scale_y_continuous(name="Frequency",breaks=seq(0,20,by=3),limits = c(0,15))+
  theme_minimal()+
  theme(legend.position = "top")


hrSize %>% filter(season=="summer") %>% group_by(id) %>% 
  pivot_wider(values_from=est,names_from=year,id_cols=id) %>% 
  mutate(difference = abs(y1 - y2)) %>% 
  filter(!is.na(difference)) %>% 
  ggplot(aes(x=y1,y=y2,label = id))+
  geom_abline(slope=1, intercept=0,linetype=3)+
  geom_text(size = 3.25,nudge_x = 0,nudge_y = -5,label.padding = unit(0.1, "lines")) +
  geom_point(size=2, shape=21,fill=cbPalette[8],color="black") +
  scale_x_continuous(name="Year 1",limits=c(0,100),breaks=seq(0,200,by=20))+
  scale_y_continuous(name="Year 2",limits=c(0,160),breaks=seq(0,200,by=40))+
  theme_bw()+
  theme(panel.grid.minor = element_blank(),
        panel.border = element_blank(),
          axis.line = element_line(colour = "black"))

# Export
write_csv(hrSize,"output/homeRangeSizes.csv")

#### Explore results: Seasonal overlap and philopatry ----
for (i in 2:length(homeRanges)) {
  currentName <- unlist(strsplit(names(homeRanges)[i],split="_"))[1]
  previousName <- unlist(strsplit(names(homeRanges)[i-1],split="_"))[1]
  futureName <- unlist(strsplit(names(homeRanges)[i+2],split="_"))[1]
  
  if (currentName == previousName & i == 2) {
    toSelect <- c(homeRanges[i],homeRanges[i-1])
    overlapEst <- as.data.frame(overlap(toSelect))[2,c(1,3,5)]
    overlapEst$id <- rownames(overlapEst)
    overlapEst$compare <- unlist(strsplit(colnames(overlapEst)[1],split="[.]"))[1]
    colnames(overlapEst)[1:3] <- unlist(strsplit(colnames(overlapEst)[1:3],split="[.]"))[c(2,4,6)]
    overlapEst <- overlapEst[,c(4,c(1:3,5))]
    
  }
  else if (currentName == previousName) {
    toSelect <- c(homeRanges[i],homeRanges[i-1])
    temp <- as.data.frame(overlap(toSelect))[2,c(1,3,5)]
    temp$id <- rownames(temp)
    temp$compare <- unlist(strsplit(colnames(temp)[1],split="[.]"))[1]
    colnames(temp)[1:3] <- unlist(strsplit(colnames(temp)[1:3],split="[.]"))[c(2,4,6)]
    overlapEst <- rbind.fill(overlapEst,temp)
  }
  else if (currentName == futureName & !is.na(futureName)) {
    toSelect <- c(homeRanges[i],homeRanges[i+2])
    temp <- as.data.frame(overlap(toSelect))[2,c(1,3,5)]
    temp$id <- rownames(temp)
    temp$compare <- unlist(strsplit(colnames(temp)[1],split="[.]"))[1]
    colnames(temp)[1:3] <- unlist(strsplit(colnames(temp)[1:3],split="[.]"))[c(2,4,6)]
    overlapEst <- rbind.fill(overlapEst,temp)
  }
  else {
  }
}

overlapEst <- overlapEst %>% 
  mutate(seasons = paste(word(overlapEst$id,start=3,sep="_"),word(overlapEst$id,start=2,sep="_"),word(overlapEst$compare,start=3,sep="_"),word(overlapEst$compare,start=2,sep="_"),sep="_"))

overlapEst %>% mutate(idx = seq(1:nrow(overlapEst))) %>% 
                        ggplot(aes(y=est,x=idx,color=seasons))+
  geom_point()

# Export as shapefiles
memory.limit(10000000000000)
fileName <- paste(getwd(),"pipeline/06e_generateHomeRanges/homeRanges4",sep="/")

ctmm::writeRaster(homeRanges[[1]],DF="PMF",
               filename=fileName,format = "GTiff",
               level.UD=0.9,level=0.95,progress="text", options="COMPRESS=LZW")

writeShapefile(homeRanges,
               folder=filePath, file=names(homeRanges),
               level.UD=0.95)


lapply(1:length(homeRanges), function (i) writeShapefile(homeRanges[[i]],
                                                         folder=filePath, file=names(homeRanges[i]),
                                                         level.UD=0.95))

rm(list=ls())