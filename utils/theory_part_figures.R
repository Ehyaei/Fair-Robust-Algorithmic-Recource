setwd("~/Dropbox/My Papers/Fair Robust Recourse/paper_draft/figs")
source("theme.R")

# ----------------------------------------------
#
#                        Example I
#
# ----------------------------------------------
# https://math.stackexchange.com/questions/280937/finding-the-angle-of-rotation-of-an-ellipse-from-its-general-equation-and-the-ot
# Convert Quadaric Form to Elliptic Formula
# Ax^2 + Bxy + Cy^2 + Dx + Ey + F = 0
# If 4AC - B^2 > 0

quadratic2Elliptic  = function(A , B , C, D, E, F){
  theta = atan(B/(A-C))/2
  # Interior VAriables
  .a = A*cos(theta)^2+B*cos(theta)*sin(theta)+C*sin(theta)^2
  .b = 0
  .c = A*sin(theta)^2-B*cos(theta)*sin(theta)+C*cos(theta)^2
  .d = D*cos(theta) + E*sin(theta)
  .e = -D*sin(theta) + E*cos(theta)
  .f = F
  .x0 = -.d/(2*.a)
  .y0 = -.e/(2*.c)
  # Center of ellipse
  x0 = .x0*cos(theta)-.y0*sin(theta)
  y0 = .x0*sin(theta)+.y0*cos(theta)
  a  = sqrt((-4*.f*.a*.c+.c*.d^2 + .a*.e^2)/(4*.a^2*.c))
  b  = sqrt((-4*.f*.a*.c+.c*.d^2 + .a*.e^2)/(4*.a*.c^2))
  return(c(x0,y0, a, b, theta))
}

# ----------------------------------------------
#
#                        Example I
#
# ----------------------------------------------

negative <- data.frame(x=c(0,7,0), y = c(0,0,7))
positive <- data.frame(x=c(7,7,0), y = c(0,7,7))

instances = data.frame(x = c(1,3), 
                       y = c(2,1), 
                       label = c("a","b"),
                       x2 = c(3,4.5),
                       y2 = c(4,2.5),
                       a = c(0.5,0.5),
                       b = c(1,1),
                       angle = c(45,45)
                       )

e1 = quadratic2Elliptic(2,2,1,0,0,-1/4)
e2 = quadratic2Elliptic(2,2,1,-6,-2,4.75)

# ----------------------------------------------
#
#                        Base Plot
#
# ----------------------------------------------

p = ggplot()+
  geom_polygon(data = negative, aes(x = x, y = y), 
               alpha = 0.3, color = "transparent", fill = "#E5948E")+
  geom_polygon(data = positive, aes(x = x, y = y), 
               alpha = 0.3, color = "transparent", fill = "#8EDFE5")+
  scale_x_continuous(expand = c(0,0),limits = c(0,7), breaks = 1:7)+
  scale_y_continuous(expand = c(0,0),limits = c(0,7), breaks = 1:7)+
  xlab(TeX("$X_1$"))+
  ylab(TeX("$X_2$"))+
  annotate(geom="text", x=1, y=6.5, label="L", color="black", size = 8)+
  annotate(geom="text", x=6.75, y =0.5, label="+", color="black", size = 8)+
  annotate(geom="text", x=6.5, y = 0.45, label="_", color="black", size = 8)+
  geom_abline(intercept = 7, slope = -1)+
  theme_Publication(base_size=20)+ 
  coord_fixed()

p

# ----------------------------------------------
#
#                         Plot 1
#
# ----------------------------------------------

p + 
  geom_point(data = instances, aes(x = x,y = y), size = 4, color = "#ee6c4d")+
  geom_point(data = instances, aes(x = x2,y = y2), size = 4, color = "#219ebc")+
  geom_segment(data = instances, aes(x = x,y = y, xend = x2, yend = y2), 
               colour = "black",linetype = "dotted", linewidth = 1)+
  geom_segment(aes(x = 1, y = 2, xend = 3, yend = 1),
                linewidth = 0.3, color ="#005b96",
               lineend = "round", linejoin = "bevel", 
               arrow = arrow(length = unit(2, "mm"), angle = 30,
                             type = "closed"))+
  geom_segment(aes(x = 3.5, y = 3.5, xend = 4.5, yend = 4.5),
               linewidth = 0.5, color ="black",
               lineend = "round", linejoin = "bevel", 
               arrow = arrow(length = unit(2, "mm"), angle = 30,
                             type = "closed"))
  
# ----------------------------------------------
#
#                        Plot II
#
# ----------------------------------------------

p + 
  geom_point(data = instances, aes(x = x,y = y), size = 1.5, color = "#ee6c4d")+
  geom_ellipse(aes(x0 = 1, y0 = 2, a = e1[3], b = e1[4], angle = e1[5]),
                 fill = "black", alpha = 0.2,color = "transparent")+
  geom_ellipse(aes(x0 = 3, y0 = 1, a = e2[3], b = e2[4], angle = e2[5]),
               fill = "black", alpha = 0.2,color = "transparent")+
  geom_segment(aes(x = 3.45, y = 0.05, xend = 2.5, yend = 1), 
               colour = "black",linetype = "dashed", linewidth = 0.5)+
  geom_segment(aes(x = 1.45, y = 1.05, xend = .5, yend = 2), 
               colour = "black",linetype = "dashed", linewidth = 0.5)+
  geom_segment(aes(x = 3, y = 0.5, xend = 4.75, yend = 2.25), 
             colour = "black",linetype = "dashed", linewidth = 0.5)+
  geom_segment(aes(x = 1, y = 1.5, xend = 3.25, yend = 3.75), 
               colour = "black",linetype = "dashed", linewidth = 0.5)+
  geom_ellipse(aes(x0 = 3.25, y0 = 4.25, a = e1[3], b = e1[4], angle = e1[5]),
               fill = "black", alpha = 0.2,color = "transparent")+
  geom_ellipse(aes(x0 = 4.75, y0 = 2.75, a = e2[3], b = e2[4], angle = e2[5]),
               fill = "black", alpha = 0.2,color = "transparent")+
  geom_point(aes(x = 3.25,y = 4.25), size = 2, color = "#219ebc")+
  geom_point(aes(x = 4.75 ,y = 2.75), size = 2, color = "#219ebc")+
  geom_segment(aes(x = 1, y = 2, xend = 3.25, yend = 4.25), 
               colour = "black",linetype = "dotted", linewidth = 0.5)+
  geom_segment(aes(x = 3, y = 1, xend = 4.75, yend = 2.75), 
               colour = "black",linetype = "dotted", linewidth = 0.5)


# ----------------------------------------------
#
#                        Plot III
#
# ----------------------------------------------
e = 0.1
d = 0.03
p + 
  geom_point(data = instances, aes(x = x,y = y), size = 1.5, color = "#ee6c4d")+
  geom_ellipse(aes(x0 = 1, y0 = 2, a = e1[3], b = e1[4], angle = e1[5]),
               fill = "black", alpha = 0.2,color = "transparent")+
  geom_point(aes(x = 3.25,y = 4.25), size = 2, color = "#219ebc")+
  geom_point(aes(x = 5.25 ,y = 3.25), size = 2, color = "#219ebc")+
  geom_segment(aes(x = 1.5, y = 1, xend = 3.75, yend = 3.25),
               colour = "black",linetype = "dashed", linewidth = 0.5)+
  geom_ellipse(aes(x0 = 3, y0 = 1, a = e2[3], b = e2[4], angle = e2[5]),
               fill = "black", alpha = 0.2,color = "transparent")+
  geom_ellipse(aes(x0 = 3.25, y0 = 4.25, a = e1[3], b = e1[4], angle = e1[5]),
               fill = "black", alpha = 0.2,color = "transparent")+
  geom_ellipse(aes(x0 = 5.25, y0 = 3.25, a = e2[3], b = e2[4], angle = e2[5]),
               fill = "black", alpha = 0.2,color = "transparent")+
  geom_segment(aes(x = 0.05, y = 2.45, xend = 2.45, yend = 0.05), 
               colour = "black",linetype = "dashed", linewidth = 0.5)+
  # geom_segment(aes(x = 1, y = 2, xend = 3.25, yend = 4.25),
  #              colour = "black",linetype = "dotted", linewidth = 0.5)+
  geom_segment(aes(x = 3, y = 1, xend = 5.25, yend = 3.25),
               colour = "black",linetype = "dotted", linewidth = 0.5)+
  geom_segment(aes(x = 3+e-d, y = 1-d-e, xend =4.5-d +e, yend =2.5-d -e),
               colour = "black", linewidth = 0.2)+
  geom_segment(aes(x = 4.5 +e +d, y =2.5+d -e , xend = 5+e-d, yend = 3-e-d),
               colour = "black", linewidth = 0.2)+
  geom_segment(aes(x = 5+e+d, y = 3-e +d, xend = 5.25+e+d, yend = 3.25-e+d),
               colour = "black", linewidth = 0.2)

  


# ----------------------------------------------
#
#                        Plot IV
#
# ----------------------------------------------

library(ggpattern)
p+
  geom_polygon_pattern(
    aes(x = c(0,0,7,6), y = c(6,7,0,0)),
    pattern       = 'magick',
    pattern_type = "vertical2" ,
    pattern_scale = 6,
    pattern_angle = 45,
    pattern_fill  = 'gray60',
    pattern_alpha = 0.7,
    fill          = 'transparent', 
    size          = 0.2,
    color = "transparent"
  )+
  geom_polygon_pattern(
    aes(x = c(0,1,7,7), y = c(7,7,1,0)),
    pattern       = 'magick',
    pattern_type = "horizontal2" ,
    pattern_scale = 6,
    pattern_angle = 45,
    pattern_fill  = 'gray60',
    pattern_alpha = 0.7,
    fill          = 'transparent', 
    size          = 0.2,
    color = "transparent"
  ) +
  annotate(geom="text", x=1, y=6.5, label="L", color="black", size = 8)+
  annotate(geom="text", x=6.75, y =0.5, label="+", color="black", size = 8)+
  annotate(geom="text", x=6.5, y = 0.45, label="_", color="black", size = 8)




# ----------------------------------------------
#
#                        Plot V
#
# ----------------------------------------------

d = sqrt(seq(0.7,.03,length.out = 4))

p + 
  geom_point(data = instances, aes(x = x,y = y), size = 1.5, color = "#ee6c4d")+
  geom_segment(aes(x = 1.75, y = 1.25, xend = 3.75, yend = 3.25),
               colour = "black",linetype = "dotted", linewidth = 0.75)+
  geom_segment(aes(x = 0.05, y = 2.95, xend = 2.95, yend = 0.05), 
               colour = "black",linetype = "dotted", linewidth = 0.75)+ 
  geom_ellipse(aes(x0 = 1, y0 = 2, a = e1[3], b = e1[4], angle = e1[5]),
               color = "black", fill = "transparent", linewidth = 0.2)+
  geom_ellipse(aes(x0 = 3, y0 = 1, a = e2[3], b = e2[4], angle = e2[5]),
                 color = "black", fill = "transparent", linewidth = 0.2)+
  geom_ellipse(aes(x0 = 1, y0 = 2, a = e1[3]*d[1], b = e1[4]*d[1], angle = e1[5]),
               color = "black", fill = "transparent", linewidth = 0.2)+
  geom_ellipse(aes(x0 = 3, y0 = 1, a = e2[3]*d[1], b = e2[4]*d[1], angle = e2[5]),
             color = "black", fill = "transparent", linewidth = 0.2)+
  geom_ellipse(aes(x0 = 1, y0 = 2, a = e1[3]*d[2], b = e1[4]*d[2], angle = e1[5]),
               color = "black", fill = "transparent", linewidth = 0.2)+
  geom_ellipse(aes(x0 = 3, y0 = 1, a = e2[3]*d[2], b = e2[4]*d[2], angle = e2[5]),
               color = "black", fill = "transparent", linewidth = 0.2)+
  geom_ellipse(aes(x0 = 1, y0 = 2, a = e1[3]*d[3], b = e1[4]*d[3], angle = e1[5]),
               color = "black", fill = "transparent", linewidth = 0.2)+
  geom_ellipse(aes(x0 = 3, y0 = 1, a = e2[3]*d[3], b = e2[4]*d[3], angle = e2[5]),
               color = "black", fill = "transparent", linewidth = 0.2)+
  geom_ellipse(aes(x0 = 1, y0 = 2, a = e1[3]*d[4], b = e1[4]*d[4], angle = e1[5]),
               color = "black", fill = "transparent", linewidth = 0.2)+
  geom_ellipse(aes(x0 = 3, y0 = 1, a = e2[3]*d[4], b = e2[4]*d[4], angle = e2[5]),
               color = "black", fill = "transparent", linewidth = 0.2)


