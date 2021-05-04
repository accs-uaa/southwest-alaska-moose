# Objective: Explore amt package. There are two functions that might be useful for our path-selection function: a) random_steps and b) fit_distr for generating theoretical distributions from step lengths and turning angles.

# Author: A. Droghini (adroghini@alaska.edu)

#### Load packages and data---
rm(list=ls())
source("package_Paths/init.R")
data("deer")

#### Explore random steps----
# The random_steps function cannot be used "as is" to achieve what we want.
# Our idea is to generate 'random' paths that have the same starting location as the original point. Each subsequent point along a path is generated from the previous location and from the distributions of step lengths & turning angles.
# In the random_steps function, each random point is independent of the random points that were generated before it.
ssf1 <- deer %>% steps_by_burst() %>% random_steps(n_control = 10)
ssf2 <- ssf1 %>% 
  filter(burst_ == "1" & step_id_ < 10 & case_ == FALSE)

# Explore step length distribution----
# amt uses fit_distr, which is a wrapper function for fitdist from the fitdistrplus package: https://github.com/jmsigner/amt/blob/master/R/fit_distr.R

# Check to make sure I can replicate results...
sl_distr <- fit_distr(ssf1$sl_, "gamma") # gives parameters
fitdistrplus::fitdist(ssf1$sl_, "gamma", keepdata = FALSE, lower = 0)
# scale = 1/rate
# parameters are the same 

# Generate random step lengths based on gamma distribution
# Compare amt::random_numbers function to base R rgamma
# Using parameters generated above

rand_sl <- random_numbers(sl_distr, n = 1e+05)
hist(rand_sl,
     breaks=100,
     xlab="rand_sl",main="")
hist(rgamma(n = 1e+05, shape=0.77, scale = 472.3),
     breaks=100,
     xlab="rand_sl",main="")

# Explore turning angle distribution----
# fit_distr uses circular package
ta_distr <- fit_distr(ssf1$ta_, "vonmises") # gives parameters
x <- circular::as.circular(ssf1$ta_, type = "angles", 
                           units = "radians", 
                           template = "none",
                           modulo = "asis", 
                           zero = 0, 
                           rotation = "counter")
fit <- circular::mle.vonmises(x) # gives parameters from circular. kappa param is the same. amt sets mu to zero: make_distribution(name = "vonmises", params = list(kappa = kappa, mu = 0)).
# If kappa  is zero, the distribution is uniform, and for small kappa , it is close to uniform.
# μ is a measure of location (the distribution is clustered around μ)


x <- rvonmises(n=1e+05, mu=circular(0), kappa=fit$kappa)
hist(x)
# The following two lines are in the amt code but I don't know what they do??
# hist(x) doesn't work on circular object
## ok so instead of having numbers from 0 to 2pi, the following lines just make the numbers go from -pi (-180) to pi (+180)
x <- x %% (2 * pi)
x <- ifelse(x > base::pi, x - (2 * base::pi), x)


x <- as.numeric(x)



rand_ta <- random_numbers(ta_distr, n = 1e+05) # results are very close when n is very large.
hist(rand_ta)
hist(x)
