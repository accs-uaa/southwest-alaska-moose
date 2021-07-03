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

# Load packages ----
source(paste0(git_dir,"init.R"))
source(paste0(git_dir,"function-createTable.R"))
source(paste0(git_dir,"function-confInterval.R"))

# Load data ----
calf <- read_csv(file=paste(pipeline_dir,
                             "01-dataPrepForAnalyses",
                             "paths_calves.csv",
                             sep="/"))

no_calf <- read_csv(file=paste(pipeline_dir,
                             "01-dataPrepForAnalyses",
                             "paths_no_calves.csv",
                             sep="/"))


# Define output csv files ----
output_calf <- paste(output_dir,
                                  "pathSelectionFunction",
                                  "clogit_results_calf.csv", sep="/")

output_no_calf <- paste(output_dir,
                                  "pathSelectionFunction",
                                  "clogit_results_no_calf.csv", sep="/")

# Run model ----

# Paths with calves
model_fit <- survival::clogit(formula = response ~ elevation_mean + roughness_mean + forest_edge_km + tundra_edge_km + alnus_mean + salshr_mean + strata(mooseYear_id), data = calf)

model_summary <- summary(model_fit, conf.int = 0.95)

# Create table ----
# Apply B-Y correction to p-value
model_table <- createTable(model_summary, correct = "BY")

## Recalculate OR ----

# For foliar cover covariates to place them on a more meaningful scale
# Multiply coefficient by 10 so that the odds is interpreted in terms of a 10% increase in foliar cove
model_table <- model_table %>%
  mutate(exp_coef = case_when (
    covariate == "alnus_mean" |
      covariate == "salshr_mean" ~ exp(coef * 10),
    TRUE ~ exp_coef
  ))

## Recalculate 95% CI ----

# For Alnus
sp <- which(model_table$covariate == "alnus_mean")
beta_sp <- model_table[sp,2] * 10
se_sp <- model_table[sp,3] * 10
model_table[sp,5] <- as.numeric(conf_int(beta = beta_sp, se = se_sp)[1])
model_table[sp,6] <- as.numeric(conf_int(beta = beta_sp, se = se_sp)[2])

# For Salix
sp <- which(model_table$covariate == "salshr_mean")
beta_sp <- model_table[sp,2] * 10
se_sp <- model_table[sp,3] * 10
model_table[sp,5] <- as.numeric(conf_int(beta = beta_sp, se = se_sp)[1])
model_table[sp,6] <- as.numeric(conf_int(beta = beta_sp, se = se_sp)[2])

# Format table ----

# Round values
# p-value = 0 if p < 0.01
model_table <- as.data.frame(cbind(model_table[,1],sapply(model_table[,2:7], FUN = round, digits = 3)))

model_table <- model_table %>% mutate("95% CI" = paste(lower_95,upper_95,sep=", "), p_value = case_when(p_value == "0" ~ "<0.001",
                                      TRUE ~ as.character(p_value)))

# Rename columns
# Drop Std. Err. (presenting 95% CI instead)
model_table <- model_table %>% 
  dplyr::select(-c(SE,lower_95,upper_95)) %>% 
  rename(Covariate = V1,
         Coefficient = coef,
         "Odds Ratio" = exp_coef,
         "p-value" = p_value) %>% 
  dplyr::select("Covariate","Coefficient","Odds Ratio","95% CI","p-value")


knitr::kable(model_table)

# Export table ----
write_csv(model_table, file=output_calf)

# Paths without calves
model_fit <- survival::clogit(formula = response ~ elevation_mean + roughness_mean + forest_edge_km + tundra_edge_km + alnus_mean + salshr_mean + strata(mooseYear_id), data = no_calf)

model_summary <- summary(model_fit, conf.int = 0.95)

# Create table ----
# Apply B-Y correction to p-value
model_table <- createTable(model_summary, correct = "BY")

## Recalculate OR ----

# For foliar cover covariates to place them on a more meaningful scale
# Multiply coefficient by 10 so that the odds is interpreted in terms of a 10% increase in foliar cove
model_table <- model_table %>%
  mutate(exp_coef = case_when (
    covariate == "alnus_mean" |
      covariate == "salshr_mean" ~ exp(coef * 10),
    TRUE ~ exp_coef
  ))

## Recalculate 95% CI ----

# For Alnus
sp <- which(model_table$covariate == "alnus_mean")
beta_sp <- model_table[sp,2] * 10
se_sp <- model_table[sp,3] * 10
model_table[sp,5] <- as.numeric(conf_int(beta = beta_sp, se = se_sp)[1])
model_table[sp,6] <- as.numeric(conf_int(beta = beta_sp, se = se_sp)[2])

# For Salix
sp <- which(model_table$covariate == "salshr_mean")
beta_sp <- model_table[sp,2] * 10
se_sp <- model_table[sp,3] * 10
model_table[sp,5] <- as.numeric(conf_int(beta = beta_sp, se = se_sp)[1])
model_table[sp,6] <- as.numeric(conf_int(beta = beta_sp, se = se_sp)[2])

# Format table ----

# Round values
# p-value = 0 if p < 0.01
model_table <- as.data.frame(cbind(model_table[,1],sapply(model_table[,2:7], FUN = round, digits = 3)))

model_table <- model_table %>% mutate("95% CI" = paste(lower_95,upper_95,sep=", "), p_value = case_when(p_value == "0" ~ "<0.001",
                                                                                                        TRUE ~ as.character(p_value)))

# Rename columns
# Drop Std. Err. (presenting 95% CI instead)
model_table <- model_table %>% 
  dplyr::select(-c(SE,lower_95,upper_95)) %>% 
  rename(Covariate = V1,
         Coefficient = coef,
         "Odds Ratio" = exp_coef,
         "p-value" = p_value) %>% 
  dplyr::select("Covariate","Coefficient","Odds Ratio","95% CI","p-value")


knitr::kable(model_table)

write_csv(model_table, file=output_no_calf)

#### Clear workspace ----
rm(list=ls())
