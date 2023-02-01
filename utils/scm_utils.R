############################################################
#                                                          #
#                        SCM Utils                         #
#                                                          #
############################################################


# -----------------------------------------

#           Generate SCM Models

generate_scm <- function(scm, 
                         n, 
                         noise){
  k = length(noise(1))  # Find the length of noise
  
  noise(n) %>% 
    apply(1, FUN = scm) %>% 
    t() %>% 
    as.data.table() %>% 
    setNames(paste0("x",1:k))
}

# -----------------------------------------
#           Counterfactual Twins

twins <- function(instance, 
                  scm, 
                  in_scm, 
                  do){
  u = in_scm(instance)
  u[1] = do
  return(scm(u))
}

# -----------------------------------------
#           Additive Intervention Counterfactual  

anm_counterfactual <- function(instance, 
                   scm, 
                   in_scm, 
                   do){
  scm(in_scm(instance)+do)
}


# -----------------------------------------
#           Counterfactual Ball
# -----------------------------------------

counterfactual_ball  <- function(data,
                                 continuous,
                                 categorical,
                                 metric = l2_norm, 
                                 delta = 0.1, 
                                 n_sample = 1000,
                                 ball_length_out = 500,
                                 epsilon = 0.02
                                 ) {
  
  features = c(categorical, continuous)
  
  con_grid_list = list()
  if(length(continuous)>0){
    for (var in continuous) {
      con_grid_list[[var]] = seq(-delta, delta, length.out = ball_length_out)  
    }
  }
  
  # Create Categorical Grids levels
  cat_grid_list = list()
  if(length(categorical)>0){
    for (var in categorical) {
      cat_grid_list[[var]] = unique(data[[var]])
    }
  }
  
  grid_list = c(con_grid_list, cat_grid_list)
  sub_grid <- as.data.table(expand.grid(grid_list))
  
  # Create Grid
  zero = data[1, intersect(colnames(data),features), with = F]
  zero[!is.na(zero)] = 0
  grid = zero[rep(zero[, .I], nrow(sub_grid))]
  
  for (var in colnames(sub_grid)) {
    grid[[var]] = sub_grid[[var]]
  }
  
  dis_values <- grid[,ID:=.I] %>%
    .[,dis:= {v <- unlist(.SD); metric(v,0)}, by=.(ID)] %>% 
    .[["dis"]]
  
    
    ball <- grid[,dis := NULL] %>%
    .[,ID := NULL] %>% 
    .[dis_values <= delta & dis_values >= delta -epsilon ]
  
  
  if(nrow(ball)> n_sample){
    ball = ball[sample(1:nrow(ball), n_sample)]
  }
    
  return(ball)
}

# -----------------------------------------
#           Additive Counterfactual Ball
# -----------------------------------------

ACP <- function(instance,
                scm, 
                in_scm,
                ball
                ){
  
  .cf <-  function(x){
    anm_counterfactual(
    instance, 
    scm, 
    in_scm, 
    x)}
  
  df <- return(apply(ball,MARGIN = 1, FUN = .cf) %>% t() %>% as.data.table())
  
  return(df)
}

# ----------------------------------------------------
#           Extract valid counterfactuals
# ----------------------------------------------------


test_to_cf <- function(tagged_test,
                       immutable,
                       label, 
                       best_model
                       ){
  
  factuals <- negative(tagged_test, label)
  
  factual_names <- colnames(factuals)
  
  f2t0 <- function(x) twins(x, scm, in_scm, 0)
  f2t1 <- function(x) twins(x, scm, in_scm, 1)
  
  l1 = cbind(
    factuals[get(immutable) == 1] %>% 
      setnames(paste0("f_", factual_names)),
    apply(factuals[get(immutable) == 1], 1, f2t0) %>% t() %>% 
      as.data.table()
  )
  
  l0 = cbind(
    factuals[get(immutable) == 0] %>% 
      setnames(paste0("f_", factual_names)),
    apply(factuals[get(immutable) == 0], 1, f2t1) %>% t() %>% 
      as.data.table()
  )
  
  if(nrow(l0)>0 & nrow(l1)>0){
    factuals <- rbind(l0, l1)  
  } else if(nrow(l0)>0){
    factuals <- l0
  } else{
    factuals <- l1
  }
  
  factuals = factuals[,factual_names, with = F]
  
  # Normalized
  add_label(factuals, best_model)
}


