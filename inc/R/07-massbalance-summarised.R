library(units)
library(dplyr)
library(stringr)
here::i_am("inc/R/07-massbalance-summarised.R")
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
    summarise(mean_mass=sum(mass,na.rm=T),
              max_mass=sum(mass+mad,na.rm=T),
              min_mass=sum(mass-mad,na.rm=T),
              .groups="keep")
  }
rds.file <- here::here(target.dir,"massbalance-totalmass-all-groups.rds")
saveRDS(file=rds.file, totalmass_year_data)
