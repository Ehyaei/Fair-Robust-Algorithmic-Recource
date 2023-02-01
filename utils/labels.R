############################################################
#                                                          #
#                Label Generating Functions                #
#                                                          #
############################################################

# ------------------------------------------ #
#               Linear Label
# ------------------------------------------ #

lin_bernouli_tag <- function(data, features, w, b){
  data[,features, with = F] %>%
    .[,ID:=.I] %>%
    .[,label:= {x <- unlist(.SD); e <- exp(sum(x*w)); rbinom(1,1,e/(1+e))}, by=.(ID)] %>% 
    .[["label"]]
}


lin_uniform_tag <- function(data, features, w, b){
  data[,features, with = F] %>%
    .[,ID:=.I] %>%
    .[,label:= {x <- unlist(.SD); e <- (1+exp(sum(x*w)))^{-1}; as.integer(runif(1) > e)}, by=.(ID)] %>% 
    .[["label"]]
}


lin_const_tag <- function(data, features, w, b){
  data[,features, with = F] %>%
    .[,ID:=.I] %>%
    .[,label:= {x <- unlist(.SD);  as.integer(sum(x*w)<b)}, by=.(ID)] %>% 
    .[["label"]]
}

# ------------------------------------------ #
#               Non-Linear Label
# ------------------------------------------ #

nlm_bernouli_tag <- function(data, features, w, b){
  data[,features, with = F] %>%
    .[,ID:=.I] %>%
    .[,label:= {x <- unlist(.SD); e <- exp(sum(x^2*w)); rbinom(1,1,e/(1+e))}, by=.(ID)] %>% 
    .[["label"]]
}


nlm_uniform_tag <- function(data, features, w, b){
  data[,features, with = F] %>%
    .[,ID:=.I] %>%
    .[,label:= {x <- unlist(.SD); e <- (1+exp(sum(x*w)^2))^{-1}; as.integer(runif(1) > e)}, by=.(ID)] %>% 
    .[["label"]]
}


nlm_const_tag <- function(data, features, w, b){
  data[,features, with = F] %>%
    .[,ID:=.I] %>%
    .[,label:= {x <- unlist(.SD);  as.integer(sqrt(sum(x^2*w))<b)}, by=.(ID)] %>% 
    .[["label"]]
}

# ------------------------------------------ #
#               Loan Label
# ------------------------------------------ #

loan_tag <- function(data, features, w, b){
  data[, ID:= .I] %>% 
    .[,label:=  rbinom(1, 1, (1 + exp(-0.3*(-x4 -x5 + x6 + x7 + x6*x7)))^(-1)), by = ID] %>% 
    .[, ID:= NULL] %>% 
    .[["label"]]
}


# ------------------------------------------ #
#               Adult Label
# ------------------------------------------ #

adult_tag <- function(data, features, beta, delta){
  as.data.table(data)  %>% 
    .[,features, with = F] %>%
    .[,ID:=.I] %>%
    .[,label:= {x <- unlist(.SD);  as.integer(1/(1 + exp(-beta["b0"]- sum(x*beta[features])))> delta)}, 
      by=.(ID)] %>% 
    .[["label"]]
}
