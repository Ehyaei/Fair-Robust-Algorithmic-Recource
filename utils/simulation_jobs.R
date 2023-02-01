############################################################
#                   simulation_iteration                   #
############################################################

args <- commandArgs(trailingOnly = TRUE)
if (length(args) < 1){stop('I think you forgot your parameters')}
k <- as.integer(args[1])

flush.console()

# Load Libraries

suppressMessages(library(readr))


source("initiate_scripts.R")
parametrs <- read_rds("simulations/parameter_grid.rds")

# Add Function Its Arguments
simulation_iteration(k, parametrs)
