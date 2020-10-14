# Objective: For every cow, create a variable "Boolean Parturience" that tracks the survival of calves during calving season. This variable will be used in our path selection function to explore the effect of reproductive status on habitat selection. For now, we treat twins or triplets as single boolean Calf-At-Heel. If one calf of a twin set dies, then the cow remains in Calf-At-Heel (1) status. We may add a variable of # of calves in the future.

# Author: A. Droghini (adroghini@alaska.edu)

# Load packages and data----
library(tidyverse)
library(readxl)

calf2018 <- read_excel("data/calvingSeason/Parturience2018-2019.xlsx",sheet="2018",range="A1:AG67")

load("pipeline/01_createDeployMetadata/deployMetadata.Rdata")

# Format data----

# Add collar ID using moose ID as a key
calf2018 <- left_join(calf2018,deploy,by=c("Moose_ID"="animal_id"))

# Convert date columns to long form
calf2018 <- calf2018 %>% 
  pivot_longer(cols="11 May 2018":"23 June 2018",names_to="date",values_to="calfStatus") %>% 
  mutate(calfAlive = case_when(calfStatus > 1 ~ 1,
                               calfStatus <= 1 ~ calfStatus)) %>% 
  select(deployment_id,sensor_type,date,calfAlive)

# Convert date to POSIX object 
class(calf2018$date)
calf2018$date <- as.POSIXct(calf2018$date,format="%e %B %Y")