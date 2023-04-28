library(units)
library(dplyr)
library(stringr)
library(readr)
here::i_am("inc/R/07-massbalance-summarised.R")
source(here::here("inc","R","RS-functions.R"))

target.dir <- "sandbox"
results_file <- here::here(target.dir, "massbalance-model-data-all-groups.rds")
massbalance_results <- readRDS(results_file)


year_of_collapse_data <- massbalance_results %>% 
    mutate(
      ssp=str_replace(scn,"[ssp]+([0-9])([0-9])([0-9])","SSP\\1-\\2.\\3"),
      non_collapsed=if_else(mass>0,year,2000),
           max_non_collapsed=if_else(mass+mad>0,year,2000),
           min_non_collapsed=if_else(mass-mad>0,year,2000)) %>% 
    group_by(unit_name,ssp,model_nr) %>% 
    summarise(collapse_year=max(non_collapsed,na.rm=T)+1,
              max_collapse_year=max(max_non_collapsed,na.rm=T)+1,
              min_collapse_year=max(min_non_collapsed,na.rm=T)+1,
              .groups="keep")
rds.file <- here::here(target.dir,"massbalance-year-collapse-all-groups.rds")
saveRDS(file=rds.file, year_of_collapse_data)

totalmass_year_data <- {
  massbalance_results %>% 
    mutate(scn=str_replace(scn,"[ssp]+([0-9])([0-9])([0-9])","SSP\\1-\\2.\\3"),
           mass=set_units(mass,'kg') %>% 
             set_units("Mt"),
           mad=set_units(mad,'kg') %>% 
             set_units("Mt")) %>% 
    drop_units() %>% 
    group_by(unit_name,year,scn,model_nr) %>% 
    summarise(total_mass=sum(mass,na.rm=T),
              max_mass=sum(mass+mad,na.rm=T),
              min_mass=sum(mass-mad,na.rm=T),
              .groups="keep")
  }
rds.file <- here::here(target.dir,"massbalance-totalmass-all-groups.rds")
saveRDS(file=rds.file, totalmass_year_data)


results_file <- here::here(target.dir, "relative-severity-degradation-suitability-all-tropical-glaciers.csv")
RS_results <- read_csv(results_file, show_col_types = FALSE) %>%
  mutate(unit_name=str_replace_all(unit," ","-"))


#slc_unit <- c("Cordillera de Merida", "Kilimanjaro", "Ruwenzori", "Ecuador", "Cordilleras Norte de Peru")
dat1 <- RS_results %>% 
  # filter(unit_name %in% slc_unit) %>%
  filter(threshold %in% c("acc","ess")) %>% 
  mutate(time=case_when(
    timeframe %in% "2011-2040"~0,
    timeframe %in% "2041-2070"~1,
    timeframe %in% "2071-2100"~2
    ),
    scenario=str_replace(pathway,"[ssp]+([0-9])([0-9])([0-9])","SSP\\1-\\2.\\3"),) %>%
  group_by(unit,scenario,method=threshold,timeframe,time,modelname) %>%
  summarise(n=n(),RS=mean(RS_cor),RSmed=median(RS_cor), .groups="keep") %>%
  ungroup %>%
  transmute(unit=str_replace_all(unit,"-"," "), 
            scenario, method, time, RS)

dat2 <- totalmass_year_data %>% 
  filter(year %in% c(2000,2040,2070,2100)) %>% 
  # filter(unit_name %in% slc_unit) %>%
  group_by(unit_name,model_nr,scn) %>% 
  group_modify(~RSts(.x$year,.x$total_mass,
                     formula = "conditional")) %>%
  ungroup %>% 
    transmute(unit=unit_name,
    scenario=scn,
    method="ice",
    time=(year-2040)/30,
    RS)


model_data <- dat1 %>% 
  bind_rows(dat2) %>% 
  mutate(method=factor(method,levels=c("ice","acc","ess")))

rds.file <- here::here(target.dir,"totalmass-suitability-glmm-data.rds")
saveRDS(file=rds.file, model_data)
