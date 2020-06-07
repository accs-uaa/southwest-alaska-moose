# Objectives: Explore and describe variation in home range size.

# Author: A. Droghini (adroghini@alaska.edu)
#         Alaska Center for Conservation Science

#### Set initial requirements ----
rm(list=ls())
gc()
memory.limit(10000000000000) # Increase memory limit
source("scripts/init.R")
source("scripts/function-homeRangeSize.R")

#### Load and process data ----

# List home range .Rdata files to load
# pattern="//d+" returns only files with 1+ digits in the name
files <- list.files("pipeline/06e_generateHomeRanges/",pattern="\\d+",full.names = TRUE)

# Iterate through vector of file names and apply summarizeHomeRange function, which extracts home range size estimates for every moose-season
# Results are stored as a list
hrList <- plyr::alply(files,.margins = 1,.progress = "text",
                      .fun = summarizeHomeRange)

# Format data ----

# Convert to dataframe 
# Area is in sq. km
hrSize <- data.frame(do.call(rbind.data.frame, hrList))

# Parse out model name to add separate columns for season, year, and moose ID
hrSize <- hrSize %>% 
  mutate(season = word(.id,start=3,sep="_"),
         year = word(.id,start=2,sep="_"),
         id = word(.id,start=1,sep="_")) %>% 
  rename(modelName = .id) %>% 
  dplyr::select(modelName,season,year,id,everything())

#### Summary statistics ----
# By season
hrSize %>% group_by(season) %>% 
  summarise(
    av.est = mean(est),
    sd.est = sd(est),
    max.est = max(est),
    min.est = min(est),
    n = length(est))

#### Plot results ----
# Plotting parameters
cbPalette <- c("#999999", "#E69F00", "#56B4E9", "#009E73", "#F0E442", "#0072B2", "#D55E00", "#CC79A7")

# Frequency distribution of home range size with 20 sq km bin widths, grouped by season

hrSize %>%
  ggplot(aes(x=est,fill = factor(season))) + 
  geom_histogram(binwidth=20,color="grey20")  + 
  scale_fill_manual(values=cbPalette,name="Season") +
  scale_x_continuous(name = "Home range size (sq. km)",breaks=seq(0,160,by=20))+
  scale_y_continuous(name="Frequency",breaks=seq(0,20,by=3),limits = c(0,15))+
  theme_minimal()+
  theme(legend.position = "top",panel.grid.minor = element_blank())

# Correlation of summer home range sizes across years, with 1:1 line shown
# Home range size is fairly similar across years
hrSize %>% filter(season=="summer") %>% group_by(id) %>% 
  pivot_wider(values_from=est,names_from=year,id_cols=id) %>% 
  mutate(difference = abs(y1 - y2)) %>% 
  filter(!is.na(difference)) %>% 
  ggplot(aes(x=y1,y=y2,label = id))+
  geom_abline(slope=1, intercept=0,linetype=3)+
  geom_text(size = 3.25,nudge_x = 0,nudge_y = -5) +
  geom_point(size=2, shape=21,fill=cbPalette[8],color="black") +
  scale_x_continuous(name="Year 1",limits=c(0,100),breaks=seq(0,200,by=20))+
  scale_y_continuous(name="Year 2",limits=c(0,160),breaks=seq(0,200,by=40))+
  theme_bw()+
  theme(panel.grid.minor = element_blank(),
        panel.border = element_blank(),
        axis.line = element_line(colour = "black"))

# Export results ----
write_csv(hrSize,"output/homeRangeSizes.csv")

rm(list=ls())