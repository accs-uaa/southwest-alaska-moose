# Objective: Plot results from our distance analysis, which calculated the Euclidean distance between moose home ranges. We are interested in the distances between seasonal home ranges to get a sense of how far moose are migrating.

# Distances were calculated for all home ranges within 1,000 kilometers of each other. Expressed in meters.

# Load data and packages ----
source("scripts/init.R")
distances <- read_csv("pipeline/07_resultsHomeRangeDistance/allDistances.csv")

# Format data ----
# Create columns to indicate which season-pairs were considered
# Include only records that compare home ranges belonging to the same individual
# Remove duplicate distances, which result from mirrored season-pairs

distances <- distances %>% 
  mutate(season = word(modelName,start=3,sep="_"),
         season_1 = word(modelName_1,start=3,sep="_"),
         dist_km = NEAR_DIST / 1000) %>% 
  filter(mooseID == mooseID_1) %>% 
  distinct(NEAR_DIST,.keep_all = TRUE) %>% 
  dplyr::rowwise() %>% 
  mutate(seasonPair = paste(season_1,season,sep="-"))

# Plotting parameters ----
cbPalette <- c("#777777", "#E69F00", "#56B4E9", "#009E73", "#0072B2", "#D55E00", "#CC79A7")[c(2:4,6:7)]

# Create ordered dummy factor for dotchart
distances <- distances %>% 
  mutate(seasonForPlot = str_replace_all(seasonPair,c("summer-summer"="b-b","summer-fall"="c-c","summer-winter"="d-d")))
distances$seasonForPlot <- as.factor(distances$seasonForPlot)

# Plot ----
# OK, this is kind of weird, but I *love* the look of the dotchart.. The only thing I can't seem to figure out is the legend. So we're going to do some Photoshop magic to make this work by using the legend created by ggplot

png(filename="output/figures/edits/homeRangeDistance.png", width=17,height=10,units="cm",res=600)

dotchart(distances$dist_km,groups=distances$seasonForPlot,
         labels=as.factor(distances$mooseID),
         color = cbPalette[distances$seasonForPlot], 
         xlab = "Distance between home range centroids (km)",cex=0.7,
         pt.cex=1.2,pch=20,frame.plot=TRUE,xlim=c(0,30))

dev.off()

ggplot(distances, aes(dist_km, mooseID)) +
  geom_point(aes(colour = factor(seasonForPlot)), size = 4) +
  scale_colour_manual(values = cbPalette, name = "Season-pair",labels=c("annual-annual","summer-summer","summer-fall","summer-winter")) +
  scale_x_continuous(breaks = seq(0, 30, by = 5), name = "Distance between home range centroids (km)") +
  scale_y_discrete(name = "Moose ID") +
  theme_minimal() +
  theme(panel.grid.minor = element_blank(), legend.position = "top",legend.text = element_text(size=14),legend.title=element_text(size=16))

ggsave(
  "homeRangeDistance_Legend.png",
  device = "png",
  path = "output/figures/edits",
  width = 30,
  height = 10,
  units = "cm"
)

# Clean workspace----
rm(list=ls())