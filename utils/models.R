############################################################
#                                                          #
#                        GLM Model                         #
#                                                          #
############################################################

h2o_GLM <- function(train,x,y){
  
  # GLM hyperparameters
  glm_hp <- list(
    alpha = seq(0,1,0.1)
  )
  
  # Train Over Grid with Cross validation
  glm_grid <- h2o.grid("glm", x = x, y = y,
                       grid_id = "glm_grid",
                       training_frame = train,
                       nfolds = 5,
                       family = "binomial",
                       lambda_search = TRUE,
                       seed = 1,
                       hyper_params = glm_hp)
  
  # Get the grid results, sorted by validation AUC
  glm_gridperf <- h2o.getGrid(grid_id = "glm_grid",
                              sort_by = "auc",
                              decreasing = TRUE)
  
  # Grab the top GLM model, chosen by validation AUC
  best_glm <- h2o.getModel(glm_gridperf@model_ids[[1]])
  return(best_glm)
}


############################################################
#                                                          #
#                 Gradient Boosting Model                  #
#                                                          #
############################################################

h2o_GBM <- function(train,x,y){
  
  # GBM hyperparameters
  gbm_hp <- list(
    learn_rate = c(0.01, 0.1),
    max_depth = c(3, 5, 9),
    sample_rate = c(0.8, 1.0)
    )
  
  # Train Over Grid with Cross validation
  gbm_grid <- h2o.grid("gbm", x = x, y = y,
                        grid_id = "gbm_grid",
                        training_frame = train,
                        nfolds = 5,
                        ntrees = 100,
                        seed = 1,
                        hyper_params = gbm_hp)
  
  # Get the grid results, sorted by validation AUC
  gbm_gridperf <- h2o.getGrid(grid_id = "gbm_grid",
                               sort_by = "auc",
                               decreasing = TRUE)
  
  # Grab the top GBM model, chosen by validation AUC
  best_gbm <- h2o.getModel(gbm_gridperf@model_ids[[1]])
  return(best_gbm)
}


############################################################
#                                                          #
#                        SVM Model                         #
#                                                          #
############################################################
# https://rpubs.com/GNG/297490

h2o_SVM <- function(train, x, y){
  
  # Train Over Grid with Cross validation
  svm_model <- h2o.psvm(x = x, y = y,
                        training_frame = train,
                        gamma = 0.01,
                        rank_ratio = 0.1,
                        disable_training_metrics = FALSE)
  
  return(svm_model)
}

############################################################
#                                                          #
#                   Deep Learning Model                    #
#                                                          #
############################################################

h2o_DL <- function(train,x,y){
  
  # DL hyperparameters
  hidden_opt <- list(c(20, 20, 20), c(50, 50, 50), c(100, 100, 100))
  l1_opt     <- c(1e-5, 1e-4)
  hidden_drpoutRatios <- list(c(0.2, 0.2, 0.2), c(0.5, 0.5, 0.5))
  
  DL_hp <- list(hidden = hidden_opt, 
                hidden_dropout_ratios = hidden_drpoutRatios, 
                l1 = l1_opt)
  

  
  # Train Over Grid with Cross validation
  DL_grid <- h2o.grid("deeplearning", x = x, y = y,
                      grid_id = "DL_grid",
                      training_frame = train,
                      nfolds = 5,
                      epochs = 500,
                      distribution = "bernoulli",
                      activation = "Maxout",
                      seed = 1,
                      stopping_metric = "AUC",
                      hyper_params = DL_hp)
  
  # Get the grid results, sorted by validation AUC
  DL_gridperf <- h2o.getGrid(grid_id = "DL_grid",
                             sort_by = "auc",
                             decreasing = TRUE)
  
  # Grab the top DL model, chosen by validation AUC
  best_DL <- h2o.getModel(DL_gridperf@model_ids[[1]])
  return(best_DL)
}

############################################################
#                                                          #
#                          Model Fit                       #
#                                                          #
############################################################

model_fit <- function(data,
                      grid, 
                      classifier, 
                      split_ratio = 0.2, 
                      model_features, 
                      label){
  
  # ------------------------------------
  # Initiate H2o
  
  data[[label]] = as.factor(data[[label]])
  hex_data = as.h2o(data)
  hex_grid = as.h2o(grid)
  
  
  split_data = h2o.splitFrame(data = hex_data, ratios = split_ratio)
  test = split_data[[1]]
  train = split_data[[2]]
  
  y <- label
  x <- model_features
  
  best_model <- classifier(train, x, y)
  
  # Accuracy
  perf <- h2o.performance(best_model, test)

  # Positive Space
  grid_label <- h2o.predict(best_model, hex_grid)
  hex_grid[[label]] = grid_label[["predict"]]
  # search_grid = positive(as.data.table(hex_grid), label)
  tagged_grid = as.data.table(hex_grid)
  
  
  # Tagged Test
  test_label <- h2o.predict(best_model, test)
  
  # Accuracy
  accuracy <- sum(test_label[["predict"]] == test[[label]])/nrow(test)
  
  # Replace Test data by new labels
  test[[label]] = test_label[["predict"]]
  tagged_test = as.data.table(test)
  
  
  # Return
  return(list(tagged_grid = tagged_grid, tagged_test = tagged_test,
              accuracy = accuracy, best_model = best_model))
}


############################################################
#                                                          #
#                    Add Label To Data                     #
#                                                          #
############################################################

add_label <- function(data,
                      best_model){
  hex_data = as.h2o(data)
  data_label <- h2o.predict(best_model, hex_data)
  hex_data[["label"]] = data_label[["predict"]]
  as.data.table(hex_data)
}
                      