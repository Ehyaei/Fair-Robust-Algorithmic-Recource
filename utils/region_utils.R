############################################################
#                                                          #
#                  Positive and Negative                   #
#                                                          #
############################################################

positive <- function(data, 
                     label, 
                     immutable = NULL){
  data[label==1][, setdiff(colnames(data),c(immutable,label)), with=FALSE]
}

negative <- function(data, 
                     label, 
                     immutable = NULL){
  data[label==0][, setdiff(colnames(data),c(immutable,label)), with=FALSE]
}

############################################################
#                                                          #
#                    Decision Boundary                     #
#                                                          #
############################################################

desicion_boundary <- function(tagged_grid, 
                              immutable, 
                              continuous, 
                              label){
  
  # https://rpubs.com/ZheWangDataAnalytics/DecisionBoundary
  
  if(length(continuous)!=2) print("This function is only for 2D features")
  tagged_grid[[label]] = as.numeric(as.character(tagged_grid[[label]]))
  tagged_grid$class = tagged_grid[[immutable]]
  
  .dc <- function(data){
    key = unique(data$class)
    data[[immutable]] = NULL
    data[["class"]] = NULL
    data = as.data.frame(data)
    dc = getContourLines(data)
    dc[["LID"]] = NULL
    dc[["GID"]] = NULL
    dc[["PID"]] = NULL
    dc[["z"]] = NULL
    dc[[immutable]] = key
    colnames(dc)[1:3] = c("group", continuous)
    dc = dc[, c(immutable, continuous,"group")]
    as.data.table(dc)
  }
  
  dc = tagged_grid[,c(immutable, continuous,label ,"class"), with  = F] %>% 
    as.data.frame()  %>% 
    group_split(class) %>% 
    lapply(., .dc) %>% 
    rbindlist()
  
  return(dc)
}

############################################################
#                                                          #
#                       Convex Hull                        #
#                                                          #
############################################################

grid_convex_hull <- function(tagged_grid, 
                             immutable, 
                             continuous, 
                             label){
  if(length(continuous)!=2) print("This function is only for 2D features")
  
  .ch <- function(data){
    hpts <- chull(data[,continuous, with = F])
    hpts <- c(hpts, hpts[1])
    data[hpts, ]
  }
  
  hc = split(tagged_grid, by = c(immutable, label)) %>% 
    lapply(., .ch) %>% 
    rbindlist()
}

############################################################
#                                                          #
#                       Concave Hull                       #
#                                                          #
############################################################

grid_concave_hull <- function(tagged_grid, 
                              immutable, 
                              continuous, 
                              label,
                              concavity = 1){
  if(length(continuous)!=2) print("This function is only for 2D features")
  
  .ch <- function(data){
    im_key = unique(data[[immutable]])
    lb_key = unique(data[[label]])
    
    pl <- concaveman(as.matrix(data[,continuous, with = F]),
                     concavity = concavity, length_threshold = 0.001) %>% 
      st_polygon(x = list(.)) %>%
      st_sfc() %>%
      st_sf() %>% 
      st_buffer(dist = 0.001)
    
    concave = data.table(pl) 
    concave[[immutable]] = im_key
    concave[[label]] = lb_key
    
    return(concave[,c(immutable, label, "geometry"), with = F])
  }
  
  hc = split(tagged_grid, by = c(immutable, label)) %>% 
    lapply(., .ch) %>% 
    rbindlist()
  
  hc[x1 == 1][label == 0][["geometry"]] = 
    st_difference(hc[x1 == 1][label == 0][["geometry"]], 
                  hc[x1 == 1][label == 1][["geometry"]])
  hc[x1 == 0][label == 0][["geometry"]] = 
    st_difference(hc[x1 == 0][label == 0][["geometry"]], 
                  hc[x1 == 0][label == 1][["geometry"]])
  
  
  hc
}


############################################################
#                                                          #
#                    Poly To Data.Frame                    #
#                                                          #
############################################################

polyggon_to_df <- function(concave_hull, continuous, immutable, label = "labal"){
  concave_df = list()
  for(s in 1:nrow(concave_hull)){
    poly_region = lapply(concave_hull$geometry[s][[1]], FUN = function(x){
      df <- as.data.frame(x) %>% setnames(continuous)
      df$id <- paste0(sample(letters, 6), collapse = "")
      return(df)
    }) %>% rbindlist()
    poly_region[[immutable]] = concave_hull[[immutable]][s]
    poly_region[[label]] = concave_hull[[label]][s]
    concave_df[[s]] = poly_region
  }
  rbindlist(concave_df)
}

