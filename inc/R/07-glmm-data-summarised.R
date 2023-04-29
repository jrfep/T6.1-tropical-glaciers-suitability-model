library(units)
library(dplyr)
library(stringr)
library(readr)
here::i_am("inc/R/07-glmm-data-summarised.R")
source(here::here("inc","R","RS-functions.R"))

source(here::here("env","project-env.R"))
target.dir <- sprintf("%s/%s/", gis.out, projectname)

rds.file <- sprintf("%s/massbalance-totalmass-all-groups.rds", target.dir)
totalmass_year_data <- readRDS(rds.file)


results_file <- sprintf("%s/relative-severity-degradation-suitability-all-tropical-glaciers.csv", target.dir)
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

rds.file <- sprintf("%s/totalmass-suitability-glmm-data.rds", target.dir)
saveRDS(file=rds.file, model_data)
