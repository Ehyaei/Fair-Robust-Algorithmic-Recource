############################################################
#                                                          #
#                   Start Computing Loop                   #
#                                                          #
############################################################

simulation_iteration <- function(k, parametrs) {
  
  # -----------------------------------
  #           set Parameters
  # -----------------------------------
  
  # 0. Iteration Info
  
  scm_type        <<- parametrs$scm_type[k]         # SCM Type
  w_type          <<- parametrs$w_type[k]           # Coefficient Type
  tag_type        <<- parametrs$tag_type[k]         # Tagger Type
  classifier_type <<- parametrs$classifier_type[k]  # Classifier Type
  learn_type      <<- parametrs$learn_type[k]       # Classifier Feature Type
  
  # 1. Constant Features
  
  n <- 10000                                       # Number of SCM generation sample
  categorical <<- c("x1")                           # categorical variables
  immutable <<- "x1"                                # Immutable variable
  label <<- "label"                                 # Label name
  length_out <<- 300                                # grid number of bins
  split_ratio <<- 0.2                               # Split Ratio of train and test
  continuous <<- c("x2","x3")                       # Continuous variables
  if(scm_type == "SYN") continuous <<- c("x6","x7")
  
  # 2. Changing Features
  
  scm <<- parametrs$scm[k] %>% .[[1]]               # SCM Structural mapping
  in_scm <<- parametrs$in_scm[k] %>% .[[1]]         # SCM inverse mapping
  noise <<- parametrs$noise[k] %>% .[[1]]           # SCM Noise Function
  w <<- parametrs$w[k] %>% .[[1]]                   # Coefficient of Tagger 
  b <<- parametrs$b[k] %>% .[[1]]                   # Intercept of Tagger 
  classifier <<- parametrs$classifier[k] %>% .[[1]] # Classifier Model 
  delta <<- parametrs$delta[k] %>% .[[1]]           # Perturbation radius
  categorical_metric <<- discete_metric             # Categorical metrics
  continuous_metric <<- l2_norm                     # Continuous Metric
  product_norm <<- l2_product_norm                  # Product Norm
  tagger <<- parametrs$tagger[k] %>% .[[1]]         # Tagger Function 
  if(scm_type == "SYN") tagger <<- loan_tag         # When SCM is Synthetic
  show_plot <<- FALSE                               # Show Plot Option
  only_plot <<- FALSE                               # If we want Only Update Plots
  
  # 3. H2o Start Up Config
  
  h2o.init()
  h2o.no_progress()
  
  # -----------------------------------
  #           Generate SCM
  # -----------------------------------
  
  data = generate_scm(scm,
                      n, 
                      noise)
  
  # Sample instance
  instance = data[1,] %>% unlist()
  
  # -----------------------------------
  #           Generate SCM
  # -----------------------------------
  
  
  if(scm_type == "SYN"){
    grid <- scm_grid (scm, 100000, noise)
    # continuous_grid = as.data.table(expand.grid(
    #   x6 = seq(min(grid$x6), max(grid$x6), length.out = 100),
    #   x7 = seq(min(grid$x7), max(grid$x7), length.out = 100)
    # ))
    # grid = crossing(select(grid, -x6,-x7), continuous_grid)
    
  } else{
    grid <- action_grid(data,
                        instance,
                        continuous,
                        categorical,
                        immutable,
                        length_out)
    
  }
  
  # -----------------------------------
  #           Add Labels
  # -----------------------------------
  
  # Operational Feature
  features = c(categorical, continuous)
  
  # All Feature
  all_feature = colnames(data)
  
  # Add tag to data
  data[["label"]] = tagger(data, all_feature, w, b)
  
  # Check Plot
  scm_generator_plot(data, 
                     continuous,
                     label,
                     scm_type, 
                     tag_type, 
                     w_type, 
                     b, 
                     k,
                     show = show_plot)
  # -----------------------------------
  #   Find Factuals and Positive Grid
  # -----------------------------------
  
  if(learn_type == "unaware"){
    model_features = setdiff(all_feature, immutable)
  } else {
    model_features = all_feature
  }
  
  fit <- model_fit(data,
                   grid, 
                   classifier, 
                   split_ratio,
                   model_features, 
                   label)
  
  best_model  <- fit$best_model
  tagged_test <- fit$tagged_test
  tagged_grid <- fit$tagged_grid
  accuracy    <- fit$accuracy
  
  
  # -----------------------------------
  #         Find Valid Instant
  # -----------------------------------
  
  factuals = test_to_cf(tagged_test, 
                        immutable, 
                        label, 
                        best_model
  )
  
  instances = factuals[label == 0]
  
  # -------------------------------------------------------
  #   Find Convex Hull and Decision Boundary Grid
  # -------------------------------------------------------
  if(scm_type == "SYN") concavity = 2 else concavity = 1 
  concave_hull = grid_concave_hull(tagged_grid, immutable, continuous, label, concavity) 
  
  # -------------------------------------------------------
  #                   Find Search Grid
  # -------------------------------------------------------
  
  des_boundary = desicion_boundary(tagged_grid, immutable, continuous, label)
  des_boundary = des_boundary %>% 
    sample_n(min(10000, nrow(des_boundary)))
  
  des_boundary_label <- add_label(des_boundary, best_model)
  
  search_grid <- des_boundary_label %>%
    filter(label == 1) %>% 
    mutate(group = NULL) 
  
  # Reduce search space to 1000 points
  search_grid = search_grid %>% 
    sample_n(min(1000, nrow(search_grid)))
  
  # Check Plot!
  model_boundary_plot(immutable,
                      label,
                      continuous, 
                      concave_hull, 
                      search_grid, 
                      scm_type, 
                      tag_type, 
                      w_type, 
                      b,
                      classifier_type,
                      learn_type,
                      k, 
                      show = show_plot)
  
  
  # ---------------------------------------------
  #         Counterfactual ball
  # ---------------------------------------------
  
  ball = counterfactual_ball(data,
                             continuous,
                             categorical, 
                             delta = delta,
                             n_sample = 100)
  
  # -----------------------------------
  #         Second Loop
  # -----------------------------------
  
  result <- data.table(
    id = 1:min(nrow(instances), 100),
    scm_type = scm_type, 
    tag_type = tag_type, 
    w_type = w_type, 
    b = b,
    classifier_type = classifier_type,
    learn_type = learn_type,
    delta = delta, 
    accuracy = accuracy,
    optimal_cost = 0,
    twin_optimal_cost = 0,
    optimal_robust_cost = 0,
    twin_optimal_robust_cost = 0
  )
  
  pb <- progress_bar$new(total = nrow(result))
  
  if(!only_plot){iterations_count = nrow(result)} else iterations_count = 1
  
  for(j in 1:iterations_count){
    instance = instances[j,] %>% unlist()
    
    # Find Twin 
    if(instance[immutable] == 1){
      twin <- twins(instance, scm, in_scm, 0)  
    } else {
      twin <- twins(instance, scm, in_scm, 1)
    }
    
    # ---------------------------------------------
    #         Additive Counterfactual Ball
    # ---------------------------------------------
    
    acp_ball <- ACP(instance,
                    scm, 
                    in_scm,
                    ball
    )
    
    twin_acp_ball <- ACP(twin,
                         scm, 
                         in_scm,
                         ball
    )
    
    # -----------------------------------
    #         Find Optimal Action
    # -----------------------------------
    
    opt_act <- optimal_action(instance, 
                              search_grid,
                              continuous ,
                              categorical,
                              immutable)
    
    result$optimal_cost[j] = opt_act$cost
    
    robust_opt_act <- optimal_robust_action(acp_ball, 
                                            search_grid, 
                                            continuous ,
                                            categorical,
                                            immutable)
    result$optimal_robust_cost[j] = robust_opt_act$cost
    
    # ---------------------------------------------
    #         Find Twins and Optimal Action
    # ---------------------------------------------
    
    twin_opt_act <- optimal_action(twin,
                                   search_grid, 
                                   continuous ,
                                   categorical,
                                   immutable)
    
    result$twin_optimal_cost[j] = twin_opt_act$cost
    
    twin_robust_opt_act <- optimal_robust_action(twin_acp_ball, 
                                                 search_grid, 
                                                 continuous ,
                                                 categorical,
                                                 immutable)
    
    result$twin_optimal_robust_cost[j] = twin_robust_opt_act$cost
    pb$tick()
  }
  
  title <- sprintf("SCM:%s_label:%s_w:%s_b:%s_h:%s_delta:%s",
                   scm_type, tag_type, w_type, as.character(b),
                   classifier_type, delta)
  
  if(!only_plot){write_rds(result, paste0("simulations/recourse_table/", k, "_", title,".rds"))}
  
  ############################################################
  #                                                          #
  #                       Plot Results                       #
  #                                                          #
  ############################################################
  
  recourse_plot(
    instance, 
    twin, 
    continuous ,
    categorical,
    immutable,
    label,
    acp_ball, 
    twin_acp_ball,
    concave_hull,
    opt_act,
    twin_opt_act,
    robust_opt_act,
    twin_robust_opt_act,  
    search_grid, 
    scm_type, 
    tag_type, 
    w_type, 
    b,
    classifier_type,
    learn_type,
    delta,
    k, 
    show = show_plot)
  
  # ------------------------------------
  print(paste("Iteration: ", k, "Finished at:",Sys.time()))
  h2o.shutdown(prompt = FALSE)
  
  rm(list = ls())
  gc()
}
