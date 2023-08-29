library(dplyr)
library(ggplot2)
library(readr)
library(units)
library(ggforce)
#library(purrr)
#library(ggpubr)
#library(tidyr)
library(stringr)
here::i_am("inc/R/22-ms-figs-5-and-6.R")
# sessionInfo()
# Suppress summarise info
options(dplyr.summarise.inform = FALSE)
source(here::here("inc","R","RS-functions.R"))
source(here::here("inc","R","RS-shared.R"))

target_dir <- "sandbox"
results_file <- here::here(target_dir, "relative-severity-degradation-suitability-all-tropical-glaciers.csv")
RS_results <- read_csv(results_file, show_col_types = FALSE) %>%
  mutate(unit_name=str_replace_all(unit,"-"," ")) %>%
  mutate(unit_name = factor(unit_name, unit_order) )
results_file <- here::here(target_dir, "massbalance-model-data-all-groups.rds")
massbalance_results <- readRDS(results_file)

rds_file <- here::here(target_dir,"totalmass-suitability-cED-data.rds")
cED_model_data <- readRDS(rds_file)

jj <- "Cordilleras Norte de Peru"
ss <- "SSP2-4.5"
mm <- " 9"
mbdata <- massbalance_results %>%
    filter(
        unit_name %in% jj,
        ssp %in% ss,
        model_nr %in% mm,
        year %in% c(2000,2050)
        ) 

    wgs <- mbdata %>%
        filter(year == 2000) %>%
        group_by( RGIId) %>%
        summarise(initial_mass = sum(mass), .groups = "keep") 

    RSi_data <- mbdata %>%
    group_by(RGIId) %>%
    group_modify(~RSts(.x$year, .x$mass,
                        formula = "conditional")) %>%
    ungroup %>%
      mutate(
        IV=set_units(IV,'kg') %>% set_units("Mt"),
        FV=set_units(FV,'kg') %>% set_units("Mt"),
        RS=set_units(RS,'1')
      ) %>%
    left_join(wgs, by = c("RGIId"))

ggplot(RSi_data %>% drop_units) + 
  geom_point(aes(x=IV,y=RS,size=FV)) + 
  scale_x_continuous(
    trans="log",
    breaks=c(0,10,100,300,1000),
    ) +
  scale_size_continuous(
    name="Final ice mass [Mt]",
    breaks=c(0,10,100,300,500)
    ) +
  #scale_colour_continuous(trans="reverse") + 
  theme(legend.position = "top") +
  xlab("Initial ice mass [Mt]") +
  ylab(
    expression(paste("Relative severity of ice loss [",RS[i],"]"))
  )


ggsave(here::here("sandbox","Figure-5-ice-mass-Peru.png"), width = 7, height = 5)

for (slc_ssp in c("ssp126", "ssp370", "ssp585")) {
  for (slc_thr in c("acc", "ess")) {
    for (slc_mdl in unique(RS_results$modelname)) {
        dat1 <- RS_results %>%
    filter(
      threshold == slc_thr,
      pathway == slc_ssp,
      modelname == slc_mdl) %>%
      mutate(timeframe=str_replace(timeframe,"-","\n"))
  dat2 <- dat1 %>%
    group_by(timeframe,unit_name) %>%
    summarise(mean_RS=mean(RS_cor))
  
  dat3 <- dat1 %>%
    group_by(unit_name,timeframe) %>%
    group_modify(~summary_cED_w(.x$RS_cor)) %>%
    inner_join(dat2, by=c("unit_name","timeframe")) %>%
    mutate(state = case_when(
              mean_RS == 1 ~ "collapsed",
              cED_80 >= 0.80 ~ "very wide",
              cED_80 >= 0.50 ~ "very inter",
              cED_50 >= 0.80 ~ "high wide",
              cED_80 >= 0.30 ~ "very local",
              cED_50 >= 0.50 ~ "high inter",
              cED_30 >= 0.80 ~ "mod wide",
              TRUE ~ "low")
    )
  
  
  sts <- dat3 %>% select(unit_name,timeframe,state)
  dat1 <- dat1 %>%
    left_join(sts, by=c("unit_name","timeframe"))
  
    ggplot(dat1 ) +
    geom_boxplot(aes(y = RS_cor, x = timeframe),colour="grey77") +
  # mucho carnaval:  
  ## geom_boxplot(aes(y = RS_cor, x = timeframe, colour=state))+#,colour="grey77") +
  ##   scale_colour_manual(values=state_cat_okabe) 
    geom_point(data=dat2, aes(y = mean_RS, x = timeframe),pch=1,cex=3,colour="grey22") +
    facet_wrap(~unit_name, labeller=labeller(unit_name=label_wrap_gen())) +
    theme(legend.position = "none") +
    ylab(expression(paste("Decline in suitability [", RS[i] * phantom(n) * textstyle(or) * phantom(n) * bar(RS),"]"))) +
    xlab("Future period") 
    
  ggsave(here::here("sandbox",
                    sprintf("Figure-7-RS-suitability-per-unit-%s-%s-%s.png",
                            slc_ssp, slc_mdl, slc_thr)), width = 7, height = 5)
    }
  }
}
