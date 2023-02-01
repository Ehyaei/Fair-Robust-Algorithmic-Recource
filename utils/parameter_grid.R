############################################################
#                                                          #
#           Generate Simulation Parameters Grid            #
#                                                          #
############################################################

pars_teble <- expand.grid(
  b = c(0),
  delta = c(1, 0.5, 0.1),
  learn_type = c("aware", "unaware"),
  stringsAsFactors = FALSE
) %>% data.table()

w_pars <- data.table(
  w = list(c(0, 1, 1), c(1, 1, 1)),
  w_type = c("unaware", "aware")
)

tag_pars <- data.table(
  tagger = c(lin_const_tag, nlm_const_tag),
  tag_type = c("LIN", "NLM")
)  

classifier_c <- data.table(
  classifier = c(h2o_GLM, h2o_GBM, h2o_SVM),
  classifier_type = c("GLM", "GBM", "SVM")
)  

models <- data.table(
  "scm" = c(s_lin, s_anm, s_loan),
  "in_scm" = c(s_inverse_lin, s_inverse_anm, s_inverse_loan),
  "noise" = c(s_noise, s_noise, loan_noise),
  "scm_type" = c("LIN", "ANM", "SYN")
)

parametrs <- tidyr::crossing(pars_teble, w_pars, tag_pars, 
                             classifier_c, models) %>% 
  mutate(b = if_else(tag_type == "NLM", b + 2, b)) %>% 
  mutate(tagger = if_else(scm_type == "SYN", list(loan_tag), tagger)) %>% 
  mutate(tag_type = if_else(scm_type == "SYN", "SYN", tag_type)) %>% 
  mutate(w = if_else(scm_type == "SYN", list(-1), w)) %>% 
  mutate(w_type = if_else(scm_type == "SYN", "", w_type)) %>% 
  mutate(b = if_else(scm_type == "SYN", -1, b)) %>% 
  mutate(learn_type = if_else(scm_type == "SYN", "aware", learn_type)) %>% 
  unique()

rm(pars_teble, models, w_pars, tag_pars, sclassifier_c, classifier_c)
write_rds(parametrs, "simulations/parameter_grid.rds")
