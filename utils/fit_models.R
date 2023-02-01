############################################################
#                                                          #
#                        Fit Model                         #
#                                                          #
############################################################

fit_logistic <- function(data, fmla){
  beta = glm(fmla, data, family = "binomial")$coefficients
  return(beta)
}

fit_regression <- function(data, fmla){
  beta = lm(fmla, data)$coefficients
  return(beta)
}

fit_models <- function(data,fmla_MAR, fmla_SCHL, fmla_OCCP, fmla_WKHP, fmla_COW,fmla_label){
  beta_MAR   = fit_regression(data, fmla_MAR)
  beta_SCHL  = fit_regression(data, fmla_SCHL)
  beta_OCCP  = fit_regression(data, fmla_OCCP)
  beta_WKHP  = fit_regression(data, fmla_WKHP)
  beta_COW   = fit_regression(data, fmla_COW)
  beta_label = fit_logistic(data, fmla_label)
  
  return(list(beta_MAR   = beta_MAR, 
              beta_SCHL  = beta_SCHL, 
              beta_OCCP  = beta_OCCP, 
              beta_WKHP  = beta_WKHP, 
              beta_COW   = beta_COW,
              beta_label = beta_label))
}

