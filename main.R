############################################################
#                                                          #
#                   Simulation Jobs                        #
#                                                          #
############################################################

# source("initiate_scripts.R")
parametrs <- readr::read_rds("simulations/parameter_grid.rds") 

for(i in 1:nrow(parametrs)){
  system(sprintf("Rscript --vanilla utils/simulation_jobs.R %s", i))
  print(i)
}

############################################################
#                                                          #
#                 Check Missing Iterations                 #
#                                                          #
############################################################

runed_id <- stringr::str_extract(list.files("plots/counterfactual_balls/"), "\\d+") 
running_id  = setdiff(1:nrow(parametrs), as.integer(runed_id))

for(i in running_id){
  system(sprintf("Rscript --vanilla utils/simulation_jobs.R %s", i))
  print(i)
}


system("pkill java")

