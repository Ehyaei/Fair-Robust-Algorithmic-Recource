############################################################
#                                                          #
#                       Create GRID                        #
#                                                          #
############################################################

action_grid = function(data,
                       instance,
                       continuous,
                       categorical, 
                       immutable = NULL,
                       length_out,
                       add_imutable_grid = TRUE
                       ){
  
  # Extract continuous actionable data set
  con_act = setdiff(continuous,immutable)
  
  # Extract categorical actionable data set
  cat_act = setdiff(categorical, immutable)
  
  # Create Continuous Grids levels
  con_grid_list = list()
  if(length(con_act)>0){
  for (var in con_act) {
    con_grid_list[[var]] = seq(min(data[[var]],na.rm = T), max(data[[var]], na.rm = T),
                           length.out = length_out)  
    }
  }
  
  # Create Categorical Grids levels
  cat_grid_list = list()
  if(length(cat_act)>0){
    for (var in cat_act) {
      cat_grid_list[[var]] = unique(data[[var]])
    }
  }
  
  
  
  # Create Categorical Grids levels
  imm_grid_list = list()
  if(length(immutable) > 0 & add_imutable_grid){
    for (var in immutable) {
      imm_grid_list[[var]] = unique(data[[var]])
    }
  }
  
  # Merge Grids levels and create final grid
  grid_list = c(imm_grid_list, con_grid_list, cat_grid_list)
  sub_grid <- as.data.table(expand.grid(grid_list))
  
  # Create Grid
  instance = as.data.table(t(instance))
  grid = instance[rep(instance[, .I], nrow(sub_grid))]
  for (var in colnames(sub_grid)) {
    grid[[var]] = sub_grid[[var]]
  }
  return(grid)
}

############################################################
#                                                          #
#                        Model Grid                        #
#                                                          #
############################################################

scm_grid <- function(scm, 
                     n, 
                     noise){
  k = length(noise(1))  # Find the length of noise
  
  noise(n) %>% 
    apply(1, FUN = scm) %>% 
    t() %>% 
    as.data.table() %>% 
    setNames(paste0("x",1:k))
}


############################################################
#                                                          #
#                     Cost Functions                       #
#                                                          #
############################################################

l1_norm         <- function(x,y) sqrt(sum(abs(x-y)))
l2_norm         <- function(x,y) sqrt(sum((x-y)^2)) 
linf_norm       <- function(x,y) max(abs(x-y))
discete_metric  <- function(x,y) ifelse(x == y, 1, 0)
trivial_metric  <- function(x,y) 0
l2_product_norm <- function(x,y) sqrt(x^2 + y^2) 

############################################################
#                                                          #
#                      Optimal Action                      #
#                                                          #
############################################################

optimal_action <- function(instance, 
                           search_grid, 
                           continuous,
                           categorical, 
                           immutable, 
                           n_sample = 100000,
                           categorical_metric = l2_norm,
                           continuous_metric = l2_norm, 
                           product_norm = l2_product_norm){
  
  # Filter Data over immutable instance
  for(var in immutable){
    search_grid = search_grid[search_grid[[var]] == instance[[var]]]
  }
  
  # Sample From Points
  if(!is.null(n_sample)) search_grid = search_grid %>% 
      sample_n(min(n_sample, nrow(search_grid)))
  
  # Find continuous distance of instance from positive space
  continuous_actionable = setdiff(continuous, immutable)
  
  if(length(continuous_actionable)>0){
    v_con = instance[continuous_actionable]
    con_dis = search_grid[,ID:= .I][,c(continuous_actionable,"ID"),with = F] %>% 
      .[,dis:= {v <- unlist(.SD); continuous_metric(v,v_con)}, by=.(ID)] %>% 
      .[["dis"]]
  } else{
    con_dis  = rep(0, nrow(search_grid))
  }
  
  # Find categorical distance of instance from positive space
  categorical_actionable = setdiff(categorical, immutable)
  if(length(categorical_actionable)>0){
    v_cat = instance[categorical_actionable]
    
    cat_dis = search_grid[,ID:= .I][,c(categorical_actionable,"ID"),with = F] %>% 
      .[,dis:= {v <- unlist(.SD); categorical_metric(v, v_cat)}, by=.(ID)] %>% 
      .[["dis"]]
  } else{
    cat_dis  = rep(0, nrow(search_grid))
  }
  
  
  
  # Find Total Distance
  distance = product_norm(con_dis, cat_dis)
  
  # Find best cost and counterfactual point
  comCol <- intersect(names(instance), names(search_grid))
  best_grid_point = search_grid[which.min(distance)] %>% .[1] %>% unlist() #[,names(instance),with = F]
  cost = min(distance, na.rm = T)
  point = instance
  point[comCol] = best_grid_point[comCol]
  action = point - instance 
  # return point and cost
  return(list(point = unlist(action), cost = cost))
}

############################################################
#                                                          #
#                 Optimal Recourse Action                  #
#                                                          #
############################################################

optimal_robust_action <- function(acp_ball, 
                                  search_grid, 
                                  continuous ,
                                  categorical, 
                                  immutable, 
                                  n_sample = 100000,
                                  categorical_metric = discete_metric,
                                  continuous_metric = l2_norm, 
                                  product_norm = l2_product_norm){
  
  .opt <- function(x) optimal_action(
    x, 
    search_grid, 
    continuous ,
    categorical, 
    immutable, 
    n_sample,
    categorical_metric,
    continuous_metric, 
    product_norm)

  features = c(categorical, continuous)
  cost_table <- apply(acp_ball, 1, FUN = .opt) %>% 
    lapply(FUN = function(x) as.data.table(t(c(x$point,cost = x$cost)))) %>% 
    rbindlist()
  
  .i = which.max(cost_table$cost)
  action <- cost_table[.i] %>% unlist()
  return(list(point = action[colnames(search_grid)], cost = action["cost"]))
}



############################################################
#                                                          #
#                      Recourse Cost                       #
#                                                          #
############################################################

average_recourse_cost <- function(data, 
                          continuous, 
                          categorical, 
                          immutable,
                          label,
                          grid_search_bins = 0.001, 
                          method, split_ratio = 0.2,
                          categorical_metric = discete_metric,
                          continuous_metric = l2_norm, 
                          product_norm = l2_product_norm
                          ){
  
  # Model Features
  features = c(continuous ,categorical)
  
  # Extract Grid From Data
  grid = get_discretized_action_sets(data, continuous ,categorical, immutable,
                              grid_search_bins)
  
  # Fit Model 
  fit = model_fit(data, grid, method, split_ratio, features, label)
  
  # Positive Grid Space
  search_grid = fit$search_grid
  
  # Factual = Negative Tagged Test
  factual = fit$factual
  
  # Model Accuracy
  accuracy = fit$accuracy
  
  instance = factual[1] %>% unlist()
  best_action = optimal_action(instance, search_grid, continuous ,
                  categorical,immutable, categorical_metric,
                  continuous_metric, product_norm)
}

############################################################
#                                                          #
#                     Normalized Data                      #
#                                                          #
############################################################

normalizer <- function(data, normal_cols, mean_vals, sd_vals){
  for (var in normal_cols) {
    data[[var]] = (data[[var]] - mean_vals[var])/sd_vals[var]
  }
  return(data)
}
