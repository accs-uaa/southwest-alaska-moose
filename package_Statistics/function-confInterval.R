# This function returns the confidence intervals for a conditional logistic / hazard model
# Source code retrieved using getAnywhere(summary.coxph) and slightly modified
# Can be used when presenting results on a scale other than a 1-unit increase in the covariates

  conf_int = function(beta, se, conf.int = 0.95)  {
    z <- qnorm((1 + conf.int) / 2, 0, 1)
    tmp <- cbind(exp(beta - z * se),
                 exp(beta + z * se))
    dimnames(tmp) <- list(names(beta), c(
      paste("lower .", round(100 *
                               conf.int, 2), sep = ""),
      paste("upper .",
            round(100 * conf.int, 2), sep = "")
    ))
    
    return(tmp)
  }
  