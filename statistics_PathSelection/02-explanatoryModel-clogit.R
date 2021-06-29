# Objectives: Run two sets of conditional logistic regression models: 1) cows w/ calves (observed vs random), 2) cows w/o calves.

# Hypothesis: We expect all female moose to maximize willow availability and protective cover. Female moose avoid terrain that imposes high energetic costs to movement as inferred from roughness (standard deviation of elevation). Cows with calves should select more strongly for willow and protective cover in response to increased energetic demand and predation risk.

# Sub-hypothesis 1: Female moose select for higher willow abundance than other shrub aggregates (alder and birch shrubs).
# Sub-hypothesis 2: Female moose select for higher tree abundance and lower distance from forest edge than Eriophorum abundance or distance from tussock tundra edge.

# Alternate 1: Cows with calves select more strongly for cover, but not for willow, relative to cows without calves. Increased predation risk is the driving force that cows with calves respond to, at the expense of meeting their nutritional needs.

# Alternate 2: Cows with calves have greater movement rates and select less strongly for willow availability and protective cover, resulting in more random movements, relative to non-parturient cows. Cows with calves move erratically and often to avoid predators at the expense of both meeting their nutritional needs and remaining close to cover.

# Author: A. Droghini (adroghini@alaska.edu)

rm(list=ls())

# Define Git directory ----
git_dir <- "C:/ACCS_Work/GitHub/southwest-alaska-moose/package_Statistics/"

#### Load packages and data ----
source(paste0(git_dir,"init.R"))

calf <- read_csv(file=paste(pipeline_dir,
                             "01-dataPrepForAnalyses",
                             "paths_calves.csv",
                             sep="/"))

no_calf <- read_csv(file=paste(pipeline_dir,
                             "01-dataPrepForAnalyses",
                             "paths_no_calves.csv",
                             sep="/"))


##### Define output csv files
output_calf <- paste(output_dir,
                                  "pathSelectionFunction",
                                  "clogit_results_calf.csv", sep="/")

output_no_calf <- paste(output_dir,
                                  "pathSelectionFunction",
                                  "clogit_results_no_calf.csv", sep="/")

#### Run models ----

# Paths with calves
model_summary <- summary(survival::clogit(formula = response ~ elevation_mean + roughness_mean + forest_edge_scaled + tundra_edge_scaled + alnus_mean + salshr_mean + strata(mooseYear_id), data = calf))

model_table <- data.frame(row.names=1:length(dimnames(model_summary$coefficients)[[1]]))
model_table$variable <- dimnames(model_summary$coefficients)[[1]]
model_table$coef <- model_summary$coefficients[,1]
model_table$exp_coef <- model_summary$coefficients[,2]
model_table$SE <- model_summary$coefficients[,3]
model_table$p_values <- p.adjust(model_summary$coefficients[,5], method = "BY")

knitr::kable(model_table)

write_csv(model_table, file=output_calf)

# Paths without calves
model_summary <- summary(survival::clogit(formula = response ~ elevation_mean + roughness_mean + forest_edge_scaled + tundra_edge_scaled + alnus_mean + salshr_mean + strata(mooseYear_id), data = no_calf))

model_table <- data.frame(row.names=1:length(dimnames(model_summary$coefficients)[[1]]))
model_table$variable <- dimnames(model_summary$coefficients)[[1]]
model_table$coef <- model_summary$coefficients[,1]
model_table$exp_coef <- model_summary$coefficients[,2]
model_table$SE <- model_summary$coefficients[,3]
model_table$p_values <- p.adjust(model_summary$coefficients[,5], method = "BY")

knitr::kable(model_table)

write_csv(model_table, file=output_no_calf)

#### Clear workspace ----
rm(list=ls())