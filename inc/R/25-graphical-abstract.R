library(dplyr)
library(ggplot2)
library(readr)
library(ggforce)
library(purrr)
#library(ggpubr)
library(stringr)
here::i_am("inc/R/25-graphical-abstract.R")

target_dir <- "sandbox"
results_file <- here::here(target_dir, "relative-severity-degradation-suitability-all-tropical-glaciers.csv")
RS_results <- read_csv(results_file, show_col_types = FALSE) %>%
  mutate(unit_name=str_replace_all(unit,"-"," "))
results_file <- here::here(target_dir, "massbalance-model-data-all-groups.rds")
massbalance_results <- readRDS(results_file)
source(here::here("inc","R","RS-functions.R"))
source(here::here("inc","R","RS-shared.R"))

slc_unit <- "Santa Marta"
slc_scenario <- "ssp126"
slc_scenario <- "ssp370"
## Mass balance results
mass_su <- massbalance_results %>%
  filter(
    grepl(slc_unit,unit_name),
    model_nr %in% c(" 9"),
    scn %in% slc_scenario
  ) %>%
  mutate(min_mass = mass-mad, max_mass = mass+mad) 

wgs <- mass_su %>%
    filter(year==2000) %>%
    transmute(RGIId,initial_mass=mass) 
 wgs <- wgs   %>%
    mutate(w=initial_mass/sum(wgs$initial_mass))

RSvals <- mass_su %>%
  select(RGIId,year,mass,min_mass,max_mass) %>%
  group_by( RGIId) %>%
  group_modify( ~ RSts(
    .x$year,
    .x$mass,
    vmin = .x$min_mass,
    vmax = .x$max_mass,
    formula = "conditional"
    )
    ) %>%
    left_join(wgs, by = c( "RGIId")) 

dat2 <- RSvals %>%
  filter(year %in% c(2010,2030,2050,2070, 2090)) %>%
  mutate(initial_mass = initial_mass/1e6)


fs <- dat2 %>%
  group_by(year) %>%
  group_map(~cED_w(.x$RS, .x$w)) 

xs <- seq(0,1,length=100)

cEDdata2 <- bind_rows(
  tibble(timeframe=2010,xs,cED=fs[[1]](xs)),
  tibble(timeframe=2030,xs,cED=fs[[2]](xs)),
  tibble(timeframe=2050,xs,cED=fs[[3]](xs)),
  tibble(timeframe=2070,xs,cED=fs[[4]](xs)),
  tibble(timeframe=2090,xs,cED=fs[[5]](xs))
)

time_labels <- tibble(tfm= c(2010,2030,2050,2070, 2090), RS=c(0.2, 0.5, 0.75, 0.87, 0.92), ED = c(0.3, 0.4, 0.5, 0.6, 0.82))

plot_direct_indicator <- ggplot(  ) +
  geom_rect(data=RS_extent_combs, 
            aes(colour = state, 
                xmin = RS_min, xmax = RS_max,
                ymin = extent_min, ymax = extent_max), fill=NA, lty =2) +
  geom_rect(data=RS_extent_combs %>% filter(state %in% c("mod wide", "high wide", "very wide")), 
            aes(fill = state, 
                xmin = RS_min, xmax = RS_max,
                ymin = extent_min, ymax = extent_max),
            alpha=0.84) +
  scale_fill_manual(values=state_cat_okabe) +
  scale_colour_manual(values=state_cat_okabe) +
  geom_smooth(data = cEDdata2,
              aes(x=xs,y=cED,group=timeframe), 
              colour = "black",
              method = 'loess', formula = 'y ~ x', se = FALSE) +
  ylab("Extent of decline") +
  xlab("Relative Severity") +
  scale_x_continuous(breaks = c(0,1), minor_breaks = c(0.3,0.5,0.8), limits =c(0,1)) +
  scale_y_continuous(breaks = c(0,1), minor_breaks = c(0.3,0.5,0.8), limits =c(0,1)) +
  geom_label(data=time_labels, 
             aes(y=ED, x=RS, 
                 label=tfm),
             col = "black",
             cex=3) +
  theme_linedraw() +
  theme(legend.position = "none") 

plot_direct_indicator

## Suitability results
dat1 <- RS_results %>%
  filter(threshold=="ess", 
         grepl(slc_unit,unit_name), 
         modelname == "mri-esm2-0",
         pathway == slc_scenario)


tfm <- dat1 %>% distinct(timeframe) %>% pull

fs <- dat1 %>%
  group_by(timeframe) %>%
  group_map(~cED_w(.x$RS)) 

xs <- seq(0,1,length=100)

cEDdata <- bind_rows(
  tibble(timeframe=tfm[1],xs,cED=fs[[1]](xs)),
  tibble(timeframe=tfm[2],xs,cED=fs[[2]](xs)),
  tibble(timeframe=tfm[3],xs,cED=fs[[3]](xs))
)

rss_thr <- c(.80,.50,.30) # IUCN RLE thresholds

time_labels <- tibble(tfm, RS=c(0.5, 0.6,0.85), ED = c(0.15, 0.42, 0.8))

#

plot_indirect_indicator <- ggplot(  ) +
  geom_rect(data=RS_extent_combs, 
            aes(colour = state, 
                xmin = RS_min, xmax = RS_max,
                ymin = extent_min, ymax = extent_max), fill=NA, lty =2) +
  geom_rect(data=RS_extent_combs %>% filter(state %in% c("very local", "very wide")), 
            aes(fill = state, 
                xmin = RS_min, xmax = RS_max,
                ymin = extent_min, ymax = extent_max),
            alpha=0.84) +
  scale_fill_manual(values=state_cat_okabe) +
  scale_colour_manual(values=state_cat_okabe) +
  geom_smooth(data = cEDdata,
              aes(x=xs,y=cED,group=timeframe), 
              colour = "black",
              method = 'loess', formula = 'y ~ x', se = FALSE) +
    ylab("Extent of decline") +
    xlab("Relative Severity") +
  scale_x_continuous(breaks = c(0,1), minor_breaks = c(0.3,0.5,0.8)) +
  scale_y_continuous(breaks = c(0,1), minor_breaks = c(0.3,0.5,0.8), limits =c(0,1)) +
  geom_label(data=time_labels, 
             aes(y=ED, x=RS, 
                 label=tfm),
             col = "black",
             cex=3) +
  theme_linedraw() +
  theme(legend.position = "none") 

plot_indirect_indicator


ggsave(plot_indirect_indicator,
       filename = here::here("sandbox","Graphical-abstract-indirect.png"), width = 4, height = 3)
ggsave(plot_direct_indicator,
       filename = here::here("sandbox","Graphical-abstract-direct.png"), width = 4, height = 3)
