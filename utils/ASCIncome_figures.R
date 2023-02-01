############################################################
#                                                          #
#                      Adult Figures                       #
#                                                          #
############################################################
source("utils/plot_utils.R")
sex_palette = c("#00AFBB", "#E7B800")
label_palette = c( "#8EDFE5", "#E5948E")

income <- read_csv("datasets/ASCIncome.csv") %>% 
  mutate(SEX = ifelse(SEX == 1, "Male", "Female")) %>% 
  mutate(label = ifelse(label == 1, "> 50k$", "< 50k$")) %>% 
  mutate(label = factor(label, levels = c("> 50k$","< 50k$"), ordered =TRUE))

adult <- read_rds("data/instances_with_cost.rds") %>% 
  mutate(SEX = ifelse(SEX == 1, "Male", "Female")) %>% 
  mutate(cost_ratio = optimal_cost/twin_optimal_cost) %>% 
  mutate(additional_pay = round(100*(optimal_cost + twin_optimal_cost)/optimal_cost))

# ----------------------------------------------
#                  Gender Ratio 
# ----------------------------------------------

p <- ggplot(income, aes(x = SEX, fill = label))+
  geom_bar(color = "transparent", alpha = 0.5, position = "fill") +
  theme_Publication()+
  labs(x = NULL, y = NULL, fill = NULL)+
  scale_fill_manual(values = label_palette)+
  scale_y_continuous(labels = scales::percent)
p
ggsave("images/adult_label_by_SEX.pdf",p,device = cairo_pdf, width = 15, 
       height = 24, units = "cm")

# ----------------------------------------------
#                  Cost Ratio 
# ----------------------------------------------

p <- ggplot(subset(adult, cost_ratio < 4), aes(x = cost_ratio, fill = SEX))+
  # geom_histogram(color = "transparent", alpha = 0.5, binwidth = 0.05) +
  geom_density(aes(y = ..count..*0.5 ), color = "transparent", alpha = 0.5, binwidth = .5)+
  theme_Publication()+
  labs(x = NULL, y = NULL, fill = NULL)+
  scale_fill_manual(values = sex_palette)+
  scale_y_continuous(labels = scales::comma)
p
ggsave("images/adult_cost_ratio_by_SEX.pdf",p,device = cairo_pdf, width = 25, 
       height = 20, units = "cm")


# ----------------------------------------------
#                  Cost Ratio 
# ----------------------------------------------

p <- ggplot(subset(adult, additional_pay < 1000), aes(x = additional_pay, fill = SEX))+
  geom_density(aes(y = ..count..*5 ), color = "transparent", alpha = 0.5, binwidth = 5) +
  theme_Publication()+
  labs(x = NULL, y = NULL, fill = NULL)+
  scale_fill_manual(values = sex_palette)
p
ggsave("images/additional_recourse_cost_by_SEX.pdf",p,device = cairo_pdf, width = 20, 
       height = 15, units = "cm")

