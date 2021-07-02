# createTable function
# This function creates a data frame that summarizes the main estimates from a conditional logistic regression
# E.g. to be used in the Results section of a scientific manuscript

# Autor: A. Droghini (adroghini@alaska.edu), Alaska Center for Conservation Science

createTable <- function(model_summary, correct = "BY") {
  
  # Create empty data frame
  num_rows <- length(dimnames(model_summary$coefficients)[[1]])
  model_table <-
    data.frame(row.names = 1:num_rows)
  
  # Populate data frame
  model_table$covariate <- dimnames(model_summary$coefficients)[[1]]
  model_table$coef <- model_summary$coefficients[, 1]
  model_table$SE <- model_summary$coefficients[, 3]
model_table$exp_coef <- model_summary$coefficients[, 2]
model_table$lower_95 <- model_summary$conf.int[, 3]
model_table$upper_95 <- model_summary$conf.int[, 4]
model_table$p_value <-
  p.adjust(model_summary$coefficients[, 5], method = correct)

return(model_table)
}
