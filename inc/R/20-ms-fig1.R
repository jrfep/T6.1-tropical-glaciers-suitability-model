library(dplyr)
library(magrittr)
library(ggplot2)
library(tidyr)

here::i_am("inc/R/20-ms-fig1.R")
source(here::here("inc","R","RS-functions.R"))
source(here::here("inc","R","RS-shared.R"))

ABC <- tibble(
  IV=rnorm(100,0.6,0.1)
)
ABC %<>%  mutate(FVA=IV-runif(100,0,0.1))
ABC %<>%  mutate(FVB=FVA-runif(100,0,0.3))
ABC %<>%  mutate(FVC=FVB-runif(100,0,0.2))
ABC %<>% mutate(
  RSA = RSi(IV,FVA,CT=0.2),
  RSB = RSi(IV,FVB,CT=0.2),
  RSC = RSi(IV,FVC,CT=0.2)
)
fA <- cED_w(ABC$RSA)
fB <- cED_w(ABC$RSB)
fC <- cED_w(ABC$RSC)

xys <- tibble(RS=seq(0,1,length=50)) %>% 
  mutate(cEDA=fA(RS), cEDB=fB(RS), cEDC=fC(RS)) %>% 
  pivot_longer(cols=cEDA:cEDC)

plot_c <- ggplot( xys ) +
  geom_step(aes(x=RS,y=value,group=name),linewidth=0.8, colour="black") +
  ylab(expression(cED[RS[i]>=x])) +
  xlab("x") +
  theme_linedraw()
plot_c +
  geom_rect(data=RS_extent_combs, 
            aes(#fill = state, 
                xmin = RS_min, xmax = RS_max,
                ymin = extent_min, ymax = extent_max),
            alpha=0.54, lty=2, fill=NA,colour="grey47") +
  annotate("label",x=0.30,y=0.25,label="A") +
  annotate("label",x=0.75,y=0.35,label="B") +
  annotate("label",x=0.85,y=0.60,label="C") +
  annotate("text",x=0.40,y=1.05,label="Moderate") +
  annotate("text",x=0.65,y=1.05,label="High") +
  annotate("text",x=0.90,y=1.05,label="Very high") +
  annotate("text",x=1.05,y=0.40,label="Localised",angle=270) +
  annotate("text",x=1.05,y=0.65,label="Intermediate",angle=270) +
  annotate("text",x=1.05,y=0.90,label="Widespread",angle=270) +
  #  scale_fill_manual(values=state_cat_okabe) +
  theme(legend.position = "none", 
        panel.grid.minor = element_blank() , 
        panel.grid.major = element_blank() ) 

ggsave(here::here("sandbox","Figure-1-cED-RSi-plot.png"), width = 5, height = 5)