############################################################
#                                                          #
#   Load functions From Fair Inference On Outcomes Paper   #
#                                                          #
############################################################

source("initiate_scripts.R")
source("utils/fit_models.R")

# ----------------------------------------------------------
#                   Computations Parameters
# ----------------------------------------------------------

l_u = 1.05
l_l = 0.95
tau_u = min(l_u, 1/l_l)
tau_l = max(l_l, 1/l_u)

# ----------------------------------------------------------
#                  Load Data
# ----------------------------------------------------------

# Read ASCIncome 2018 dataset
income <- read_csv("datasets/ASCIncome.csv")

income = income[,c("label", "SEX", "RAC1P", "AGEP", "POBP", "MAR", "SCHL", "OCCP", 
  "WKHP", "COW")]

# Create Train and Test Data
ids <- sample(1:nrow(income), floor(nrow(income)*0.75))
train <- income[ids,] 
test <- income[-ids,]

# ----------------------------------------------------------
#                  Structural Relations
# ----------------------------------------------------------

fmla_MAR   <- as.formula("MAR   ~  SEX + RAC1P + AGEP + POBP")
fmla_SCHL  <- as.formula("SCHL  ~  SEX + RAC1P + AGEP + POBP + MAR")
fmla_OCCP  <- as.formula("OCCP  ~  SEX + RAC1P + AGEP + POBP + MAR + SCHL")
fmla_WKHP  <- as.formula("WKHP  ~  SEX + RAC1P + AGEP + POBP + MAR + SCHL")
fmla_COW   <- as.formula("COW   ~  SEX + RAC1P + AGEP + POBP + MAR + SCHL")
fmla_label <- as.formula("label ~  SEX + RAC1P + AGEP + POBP + MAR + SCHL + OCCP + WKHP + COW")


# ----------------------------------------------------------
#                  Fitting Unconstrained GLM and LM
# ----------------------------------------------------------
# This Function mainly is derived from:
# https://github.com/raziehna/fair-inference-on-outcomes

beta_lm = fit_models(train, 
                     fmla_MAR, 
                     fmla_SCHL,
                     fmla_OCCP,
                     fmla_WKHP,
                     fmla_COW,
                     fmla_label)

# ----------------------------------------------------------
#                  Find Delta by Cross-validate
# ----------------------------------------------------------

deltas = seq(0, 1, by = 0.1)
beta <- beta_lm$beta_label
features <- setdiff(names(beta), "(Intercept)")
names(beta)[1] = "b0"

ws = test[,features] %>% 
  as.matrix() %*% 
  beta[features]

accuracy = rep(0, length(deltas))
for(i in 1:length(deltas)){
  prediction = as.integer(1/(1+exp(-beta["b0"]- ws)) > deltas[i])
  accuracy[i] <- round(100*sum(test$label == prediction)/nrow(test),2)
}

delta <- deltas[which.max(accuracy)]

############################################################
#                                                          #
#                        Search Grid                       #
#                                                          #
############################################################

raw_grid = income
raw_grid[["label"]] = adult_tag(raw_grid, features, beta, delta)
search_grid = raw_grid[raw_grid$label == 1, ]
search_grid$label = NULL
search_grid = as.data.table(search_grid)

############################################################
#                                                          #
#                      Find Instances                      #
#                                                          #
############################################################

source("utils/scm_utils.R")
f2t1 <- function(x) twins(x, s_adult, s_inverse_adult, 1)
f1t2 <- function(x) twins(x, s_adult, s_inverse_adult, 2)


factuals = as.data.table(test)
factuals[,label:= NULL]
factual_names = colnames(factuals)

ftDF <- rbind(
  cbind(
    factuals[SEX == 1] %>% 
      setnames(paste0("f_", factual_names)),
    apply(factuals[SEX == 1], 1, f1t2) %>% t() %>% 
      as.data.table() %>% 
      setnames(paste0("t_", factual_names))
  ),
  cbind(
    factuals[SEX == 2] %>% 
      setnames(paste0("f_", factual_names)),
    apply(factuals[SEX == 2], 1, f2t1) %>% t() %>% 
      as.data.table() %>% 
      setnames(paste0("t_", factual_names))
  )
)

ftDF[["t_label"]] <- ftDF[,paste0("t_", factual_names), with = F] %>% 
  setnames(factual_names) %>% 
  adult_tag(features, beta, delta)

ftDF[["f_label"]] <- ftDF[,paste0("f_", factual_names), with = F] %>% 
  setnames(factual_names) %>% 
  adult_tag(features, beta, delta)

# TODO Plot unfairness bond

instances = ftDF[t_label == 0 & f_label == 0] %>% 
  .[,paste0("f_", factual_names), with = F] %>% 
  setnames(factual_names) #%>% 
  # sample_n(1000)

############################################################
#                                                          #
#                   Find Optimal Action                    #
#                                                          #
############################################################
source("utils/recourse.R")

immutable = c("SEX","RAC1P")
continuous = c("MAR", "SCHL", "OCCP", "WKHP", "COW")
categorical = c("SEX","RAC1P",  "AGEP", "POBP")

instances = instances %>%
  mutate(
    optimal_cost = 0,
    twin_optimal_cost = 0)

for(j in 1:nrow(instances)){
  instance = instances[j,features, with = F] %>% unlist()
  
  # Find Twin 
  if(instance["SEX"] == 1){
    twin <- twins(instance, s_adult, s_inverse_adult, 2)  
  } else {
    twin <- twins(instance, s_adult, s_inverse_adult, 1)
  }
  
  names(twin) = names(instance)
  
  # ---------------------------------------------
  #         Find Twins and Optimal Action
  # ---------------------------------------------
  
  opt_act <- optimal_action(instance, 
                            search_grid,
                            continuous ,
                            categorical,
                            immutable)
  
  instances$optimal_cost[j] = opt_act$cost
  
  # ---------------------------------------------
  #         Find Twins and Optimal Action
  # ---------------------------------------------
  
  twin_opt_act <- optimal_action(twin,
                                 search_grid, 
                                 continuous ,
                                 categorical,
                                 immutable)
  
  instances$twin_optimal_cost[j] = twin_opt_act$cost
  print(j)
}

write_rds(instances,"data/instances_with_cost.rds")



