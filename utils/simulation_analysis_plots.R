############################################################
#                                                          #
#                    SCM Generator Plot                    #
#                                                          #
############################################################

scm_generator_plot <- function(data, 
                               continuous,
                               label,
                               scm_type, 
                               tag_type, 
                               w_type, 
                               b, 
                               k,
                               show = F){
  
  
  x = continuous[1]
  y = continuous[2]
  id_x = stringr::str_extract(x, "\\d")
  id_y = stringr::str_extract(y, "\\d")
  
  data[[label]] = as.factor(data[[label]])
  
  
  title <- sprintf("SCM:%s  label:%s  w:%s  b:%s",
                   scm_type, tag_type, w_type, b)
  
  p <- ggplot(data, aes_string(x, y, color = label)) + 
    geom_point(size = 0.5) +
    labs(x = TeX(sprintf("$X_%s$",id_x)), y = TeX(sprintf("$X_%s$",id_y))) + 
    scale_color_manual(values = c("#E5948E", "#8EDFE5")) +
    theme_Publication() +
    theme(legend.position = "none") 
  
  ggsave(paste0("plots/scm_models/", k, ": ", gsub("\\s","_",title),".pdf"), 
         p, width = 20, height = 20,  units = "cm", device = cairo_pdf)
  
  ggsave(paste0("plots/scm_models/", k, ": ", gsub("\\s","_",title),".svg"), 
         p, width = 20, height = 20,  units = "cm", device = "svg")
  
  write_rds(data, paste0("simulations/scm_models/", k, ": ", gsub("\\s","_",title),".rds"))
  
  if(show) return(p) else  return("Is Done!")
    
}

############################################################
#                                                          #
#           Model Boundary and Concave Hull Plot           #
#                                                          #
############################################################

model_boundary_plot <- function(immutable, 
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
                                show = F){
  
  x = continuous[1]
  y = continuous[2]
  id_x = stringr::str_extract(x, "\\d")
  id_y = stringr::str_extract(y, "\\d")
  
  title <- sprintf("SCM:%s  label:%s  w:%s  b:%s h:%s l:%s",
                   scm_type, tag_type, w_type, as.character(b),classifier_type, learn_type)
  
  geo_polygon = polyggon_to_df(concave_hull, continuous, immutable, label)
  
  if(scm_type != "SYN"){
    p <- ggplot()+
      geom_sf(data = concave_hull,
              aes(geometry = geometry, fill = label),
              alpha = 0.3, color = "transparent", lwd = 1
      )+ facet_grid(as.formula(paste("~", immutable)))
  } else{
    p <- ggplot()+
      geom_polygon(data = geo_polygon,
                   aes_string(x, y, group = "id", fill = label),
                   alpha = 0.3, color = "transparent")+
      facet_grid(as.formula(paste("~", immutable)))
  }
  
    p = p + geom_point(data = search_grid, aes_string(x, y), size = 0.1, color = "#0077a9")+
    labs(x = TeX(sprintf("$X_%s$",id_x)), y = TeX(sprintf("$X_%s$",id_y))) + 
    theme_Publication() +
    theme(legend.position = "none") +
    scale_fill_manual(values = c("#E5948E", "#8EDFE5")) 
    
  
  
  ggsave(paste0("plots/classifier_boundary/", k, ": ", gsub("\\s","_",title),".pdf"), 
         p, width = 40, height = 20,  units = "cm", device = cairo_pdf)
  ggsave(paste0("plots/classifier_boundary/", k, ": ", gsub("\\s","_",title),".svg"), 
         p, width = 40, height = 20,  units = "cm", device = "svg")
  
  if(show) return(p) else  return("Is Done!")
}


# ----------------------------------------------
#
#                        Recourse Plot
#
# ----------------------------------------------

recourse_plot <- function(
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
    show = F
    ){
  
  title <- sprintf("SCM:%s  label:%s  w:%s  b:%s h:%s l:%s delta:%s",
                   scm_type, tag_type, w_type, as.character(b),
                   classifier_type, learn_type, delta)
  
  geo_polygon = polyggon_to_df(concave_hull, continuous, immutable, label)
  

  fa  = instance
  tw = twin
  x = continuous[1]
  y = continuous[2]
  id_x = stringr::str_extract(x, "\\d")
  id_y = stringr::str_extract(y, "\\d")
  
  hull_ball <- acp_ball %>%
    slice(chull(get(x),get(y)))
  
  twin_hull_ball <- twin_acp_ball %>%
    slice(chull(get(x),get(y)))
  
  pos_hull_ball = hull_ball 
  pos_hull_ball[[x]] = pos_hull_ball[[x]] + robust_opt_act$point[x]
  pos_hull_ball[[y]] = pos_hull_ball[[y]] + robust_opt_act$point[y]
  
  pos_twin_hull_ball = twin_hull_ball 
  pos_twin_hull_ball[[x]] = pos_twin_hull_ball[[x]] + twin_robust_opt_act$point[x]
  pos_twin_hull_ball[[y]] = pos_twin_hull_ball[[y]] + twin_robust_opt_act$point[y]
  
  if(scm_type != "SYN"){
    p <- ggplot()+
      geom_sf(data = subset(concave_hull, get(immutable) == 1),
              aes(geometry = geometry, fill = label),
              alpha = 0.3, color = "transparent", lwd = 1
      )
  } else{
    p <- ggplot()+
      geom_polygon(data = subset(geo_polygon, get(immutable) == 1),
                   aes_string(x, y, group = "id", fill = label),
                   alpha = 0.3, color = "transparent")
    
  }
  
  p = p +
    geom_point(aes(fa[x], fa[y]), color = "#BA3537", size = 1) +
    geom_point(aes(fa[x] + opt_act$point[x], fa[y] + opt_act$point[y]),
               color = "#0077a9", size = 1) +
    geom_point(aes(tw[x], tw[y]), color = "#BA3537", size = 1) +
    geom_point(aes(tw[x] + twin_opt_act$point[x], tw[y] + twin_opt_act$point[y]),
               color = "#0077a9", size = 1) +
    geom_polygon(data = hull_ball, aes_string(x,y), fill = "transparent", 
                 color = "black", linetype = "dotted")+
    geom_point(aes(fa[x] + robust_opt_act$point[x], fa[y] + robust_opt_act$point[y]),
               color = "#0077a9", size = 1) +
    geom_polygon(data = pos_hull_ball, aes_string(x,y), fill = "transparent", 
                 color = "black", linetype = "dotted")+
    geom_polygon(data = twin_hull_ball, aes_string(x,y), fill = "transparent",
                 color = "black", linetype = "dotted")+
    geom_point(aes(tw[x] + twin_robust_opt_act$point[x], tw[y] + twin_robust_opt_act$point[y]), 
               color = "#0077a9", size = 1) +
    geom_polygon(data = pos_twin_hull_ball, aes_string(x,y), fill = "transparent",
                 color = "black", linetype = "dotted")+
    labs(x = TeX(sprintf("$X_%s$",id_x)), y = TeX(sprintf("$X_%s$",id_y))) + 
    theme_Publication() +
    theme(legend.position = "none") +
      scale_fill_manual(values = c("#E5948E", "#8EDFE5"))
  
  ggsave(paste0("plots/counterfactual_balls/", k, ": ", gsub("\\s","_",title),".pdf"), 
         p, width = 20, height = 20,  units = "cm",device=cairo_pdf)
  
  ggsave(paste0("plots/counterfactual_balls/", k, ": ", gsub("\\s","_",title),".svg"), 
         p, width = 20, height = 20,  units = "cm",device = "svg")
  
  save(instance, 
       twin, 
       acp_ball, 
       twin_acp_ball,
       concave_hull,
       opt_act,
       twin_opt_act,
       robust_opt_act,
       twin_robust_opt_act, file = paste0("simulations/classifier_boundary/", k, ": ", gsub("\\s","_",title),".RData"))
  
  if(show) return(p) else  return("Is Done!")
}

