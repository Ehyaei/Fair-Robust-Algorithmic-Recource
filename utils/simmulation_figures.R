
library(tidyverse)

############################################################
#                                                          #
#                 Load All Simulation Data                 #
#                                                          #
############################################################

list.files("simulations/recourse_table/", full.names = T) -> simFiles 
parametrs <- readr::read_rds("simulations/parameter_grid.rds") 

simDfList = list()  

for(i in 1:length(simFiles)){
  path = simFiles[i]
  iteration = str_extract(path, "\\d+") %>% as.integer() 
  df <- read_rds(file = path) %>% 
    mutate(
      id = iteration,
      learn_type = parametrs$learn_type[iteration]
      )
  simDfList[[i]] = df
}

bind_rows(simDfList) -> simDf



############################################################
#                                                          #
#                 Create Simulation Table                  #
#                                                          #
############################################################

simDf %>% 
  filter(scm_type != "SYN") %>% 
  filter(delta == 0.1) %>% 
  group_by(scm_type, tag_type, w_type, classifier_type, learn_type) %>% 
  summarize(
    uf = round(max(abs(optimal_cost - twin_optimal_cost), na.rm = T) / mean(optimal_cost, na.rm = T),2),
    ruf = round(max(abs(optimal_robust_cost - twin_optimal_robust_cost), na.rm = T)/mean(optimal_robust_cost, na.rm = T),2)
    ) %>% 
  mutate(fr = 0.00) %>% 
  pivot_wider(
    names_from = c("scm_type", "tag_type"),
    values_from = c("uf", "ruf", "fr")) -> res_tab


rows_name <- c("w_type", "learn_type", "classifier_type")
ordered_cols = c("uf_LIN_LIN", "ruf_LIN_LIN", "fr_LIN_LIN", "uf_ANM_LIN", "ruf_ANM_LIN",  "fr_ANM_LIN",   
"uf_LIN_NLM", "ruf_LIN_NLM", "fr_LIN_NLM", "uf_ANM_NLM",   "ruf_ANM_NLM",  "fr_ANM_NLM" )

res_tab = res_tab[,c(rows_name, ordered_cols)] %>% 
  mutate(classifier_type =  factor(classifier_type, levels = c("GLM","SVM", "GBM"))) %>% 
  arrange(w_type,  learn_type, classifier_type) %>% 
  mutate(label = ifelse(learn_type == "aware", paste0(classifier_type, "$(A,X)$"),
                         paste0(classifier_type, "$(X)$")))

line = rep(" ",12)
for(i in 1:nrow(df)){
  line[i] = paste("&",paste(df[i,],collapse = " & "), "\\\\") %>% gsub("NA", " ",.)  
}
cat(paste0(line, collapse = "\n"))


############################################################
#                                                          #
#                  Crete Simulation Plot                   #
#                                                          #
############################################################


syn <- simDf %>% 
  filter(scm_type == "SYN")

p <- ggplot(syn, aes(y = optimal_robust_cost/twin_optimal_robust_cost, x = as.factor(delta))) + 
  geom_violin(trim=TRUE,adjust = 1.5) +
  facet_grid(.~classifier_type)+
  stat_summary(fun.y=median, geom="point", size=2, color="red")+
  theme_Publication()+
  labs(x = "Delta", y = "Robust Cost/twin's Robust Cost", fill = NULL)+
  ylim(c(0,5))
p
ggsave("images/syn_cost_ratio_by_DELTA.pdf",p,device = cairo_pdf, width = 25, 
       height = 20, units = "cm")

