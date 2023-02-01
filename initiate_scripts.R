############################################################
#                                                          #
#                      Load Packages                       #
#                                                          #
############################################################
library(tidyverse)
library(data.table)
library(contoureR)
library(h2o)
library(cxhull)
library(latex2exp)
library(ggforce)
library(latex2exp)
library(sf)
library(concaveman)
library(progress)

# Clear Console
options(warn=-1)
options(sf_use_s2 = TRUE) # user does this
############################################################
#                                                          #
#                      Load Functions                      #
#                                                          #
############################################################

source("utils/scm_models.R")
source("utils/scm_utils.R")
source("utils/labels.R")
source("utils/recourse.R")
source("utils/plot_utils.R")
source("utils/models.R")
source("utils/region_utils.R")
source("utils/simulation_analysis_plots.R")
source("utils/simulation_iteration.R")

if(!file.exists("simulations/parameter_grid.rds")) source("utils/parameter_grid.R")


