# Objective: For every cow, create a variable "Boolean Parturience" that tracks the survival of calves during calving season. This variable will be used in our path selection function to explore the effect of reproductive status on habitat selection. For now, we treat twins or triplets as single boolean Calf-At-Heel. If one calf of a twin set dies, then the cow remains in Calf-At-Heel (1) status. We may add a variable of # of calves in the future.

# Author: A. Droghini (adroghini@alaska.edu)

# Load packages and data----
library(tidyverse)
library(readxl)

calf2018 <- read_excel("data/calvingSeason/Parturience2018-2019.xlsx",sheet="2018",range="A1:AG67")

# Format data----
# Convert date to POSIX object 

# Add collar ID using moose ID as a key