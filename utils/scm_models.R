############################################################
#                                                          #
#                        Lin Model                         #
#                                                          #
############################################################

s_lin = function(u){
  x1 = u[1]
  x2 = 2*x1 + u[2]
  x3 = x1 - x2 + u[3]
  endogenous = c(x1, x2, x3)
  names(endogenous) = paste0("x", 1:length(endogenous))
  return(endogenous)
}

s_inverse_lin = function(x){
  u1 = x[1]
  u2 = x[2]-2*x[1]
  u3 = x[3]-(x[1]-x[2])
  exogenous = c(u1, u2, u3)
  names(exogenous) = paste0("u", 1:length(exogenous))
  return(exogenous)
}

# Test Equations
# ins = s_noise(1)
# round(ins,3) == round(s_inverse_lin(s_lin(ins)),3)

############################################################
#                                                          #
#                        ANM Model                         #
#                                                          #
############################################################

s_anm = function(u){
  x1 = u[1]
  x2 = 2*x1^2 + u[2]
  x3 = x1 * x2 + u[3]
  endogenous = c(x1, x2, x3)
  names(endogenous) = paste0("x", 1:length(endogenous))
  return(endogenous)
}

s_inverse_anm = function(x){
  u1 = x[1]
  u2 = x[2]-2*x[1]^2
  u3 = x[3]- x[1]*x[2]
  exogenous = c(u1, u2, u3)
  names(exogenous) = paste0("u", 1:length(exogenous))
  return(exogenous)
}

# Test Equations
# ins = s_noise(1)
# round(ins,3) == round(s_inverse_anm(s_anm(ins)),3)

############################################################
#                                                          #
#                        NLM Model                         #
#                                                          #
############################################################

s_nlm = function(u){
  x1 = u[1]
  x2 = (2*x1 + u[2])^2
  x3 = (x1 - x2) * u[3]
  endogenous = c(x1, x2, x3)
  names(endogenous) = paste0("x", 1:length(endogenous))
  return(endogenous)
}

s_inverse_nlm = function(x){
  u1 = x[1]
  u2 = sqrt(x[2]) - 2*x[1]
  u3 = x[3]/(x[1] - x[2])
  exogenous = c(u1, u2, u3)
  names(exogenous) = paste0("u", 1:length(exogenous))
  return(exogenous)
}

# Test Equations
# ins = s_noise(1)
# round(ins,3) == round(s_inverse_nlm(s_nlm(ins)),3)


############################################################
#                                                          #
#             Semi-synthetic loan approval SCM             #
#                                                          #
############################################################

s_loan = function(u){
  
  x1 = u[1]                                                                     # x1: Gender
  x2 = -35 + u[2]                                                               # x2: Age
  x3 = -0.5 + (1 + exp(-(-1 + 0.5*x1 + (1 + exp(- 0.1*x2))^(-1) + u[3])))^{-1}  # x3: Education
  x4 =  1 + 0.01*(x2 - 5)*(5 - x2) + x1 + u[4]                                  # x4: Loan 
  x5 = -1 + 0.1*x2 + 2*x1 + x4 + u[5]                                           # x5: Duration
  x6 = -4 + 0.1*(x2 + 35) + 2*x1 + x1*x3 + u[6]                                 # x6: Income
  x7 = -4 + 1.5 *x6 * (x6>0) + u[7]                                             # x7: Saving
  
  endogenous = c(x1, x2, x3, x4, x5, x6, x7)
  names(endogenous) = paste0("x", 1:length(endogenous))
  return(endogenous)
}

s_inverse_loan = function(x){
  
  u1 = x[1]
  u2 = x[2] + 35
  u3 = -log((x[3] + 0.5)^(-1) - 1) - (-1 + 0.5*x[1]+ (1 + exp(- 0.1*x[2]))^(-1))
  u4 = x[4] - ( 1 + 0.01*(x[2] - 5)*(5 - x[2]) + x[1])
  u5 = x[5] - (-1 + 0.1*x[2] + 2*x[1] + x[4])
  u6 = x[6] - (-4 + 0.1*(x[2] + 35) + 2*x[1] + x[1]*x[3])
  u7 = x[7] - (-4 + 1.5 *x[6] * (x[6] > 0))
  
  exogenous = c(u1, u2, u3, u4, u5, u6, u7)
  names(exogenous) = paste0("u", 1:length(exogenous))
  return(exogenous)
}


# Test Equations
# ins = loan_noise(1)
# round(ins,3) == round(s_inverse_loan(s_loan(ins)),3)

############################################################
#                                                          #
#                Define SCM and its Inverse                #
#                                                          #
############################################################

s_adult = function(u){
  
  x1 =                                                      u[1]    # x1: SEX
  x2 =                                                      u[2]    # x2: RAC1P
  x3 =                                                      u[3]    # x3: AGEP 
  x4 =                                                      u[4]    # x4: POBP
  x5 = c(1, x1, x2, x3, x4)         %*% beta_lm$beta_MAR  + u[5]    # x5: MAR
  x6 = c(1, x1, x2, x3, x4, x5)     %*% beta_lm$beta_SCHL + u[6]    # x6: SCHL
  x7 = c(1, x1, x2, x3, x4, x5, x6) %*% beta_lm$beta_OCCP + u[7]    # x7: OCCP
  x8 = c(1, x1, x2, x3, x4, x5, x6) %*% beta_lm$beta_WKHP + u[8]    # x6: WKHP
  x9 = c(1, x1, x2, x3, x4, x5, x6) %*% beta_lm$beta_COW  + u[9]    # x7: COW
  
  endogenous = c(x1, x2, x3, x4, x5, x6, x7, x8, x9)
  names(endogenous) = paste0("x", 1:length(endogenous))
  return(endogenous)
}

s_inverse_adult = function(x){
  
  u1 =                                                                   x[1]    # x1: SEX
  u2 =                                                                   x[2]    # x2: RAC1P
  u3 =                                                                   x[3]    # x3: AGEP 
  u4 =                                                                   x[4]    # x4: POBP
  u5 = -c(1, x[1], x[2], x[3], x[4])             %*% beta_lm$beta_MAR  + x[5]    # x5: MAR
  u6 = -c(1, x[1], x[2], x[3], x[4], x[5])       %*% beta_lm$beta_SCHL + x[6]    # x6: SCHL
  u7 = -c(1, x[1], x[2], x[3], x[4], x[5], x[6]) %*% beta_lm$beta_OCCP + x[7]    # x7: OCCP
  u8 = -c(1, x[1], x[2], x[3], x[4], x[5], x[6]) %*% beta_lm$beta_WKHP + x[8]    # x6: WKHP
  u9 = -c(1, x[1], x[2], x[3], x[4], x[5], x[6]) %*% beta_lm$beta_COW  + x[9]    # x7: COW
  
  exogenous = c(u1, u2, u3, u4, u5, u6, u7, u8, u9)
  names(exogenous) = paste0("u", 1:length(exogenous))
  return(exogenous)
}

# Test Equations
# ins = test[1,] %>% unlist() %>% .[-1]
# round(ins,3) == round(s_adult(s_inverse_adult(ins)),3)


############################################################
#                                                          #
#                       Noise Model                        #
#                                                          #
############################################################

s_noise = function(n) matrix(c(
  rbinom(n,1,0.5),
  rnorm(n),
  rnorm(n)),ncol = 3)

loan_noise = function(n) matrix(c(
  rbinom(n, 1, 0.5),                   # u1 : Gender
  rgamma(n, shape = 10, scale = 3.5),  # u2 : Age
  rnorm(n, 0, 0.5^2),                  # u3 : Education
  rnorm(n, 0, 2^2),                    # u4 : Loan
  rnorm(n, 0, 3^2),                    # u5 : duration
  rnorm(n, 0, 2^2),                    # u6 : Income
  rnorm(n, 0, 5^2)                     # u7 : Savings
  ),ncol = 7)
