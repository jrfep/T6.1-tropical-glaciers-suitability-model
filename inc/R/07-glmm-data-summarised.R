library(units)
library(dplyr)
library(stringr)
library(readr)
library(doParallel)

here::i_am("inc/R/07-glmm-data-summarised.R")
source(here::here("inc","R","RS-functions.R"))

source(here::here("env","project-env.R"))
target.dir <- sprintf("%s/%s/", gis.out, projectname)

rds.file <- sprintf("%s/massbalance-totalmass-all-groups.rds", target.dir)
totalmass_year_data <- readRDS(rds.file)

rds.file <- sprintf("%s/massbalance-model-data-all-groups.rds", target.dir)
massbalance_results <- readRDS(rds.file)


results_file <- sprintf("%s/relative-severity-degradation-suitability-all-tropical-glaciers.csv", target.dir)
RS_results <- read_csv(results_file, show_col_types = FALSE) %>%
  mutate(unit_name=str_replace_all(unit,"-"," "))

exclude <- c("Temperate Glacier Ecosystems", "Famatina", "Norte de Argentina", "Zona Volcanica Central")

dat1 <- RS_results %>% 
  mutate(time=case_when(
    timeframe %in% "2011-2040"~0,
    timeframe %in% "2041-2070"~1,
    timeframe %in% "2071-2100"~2
    ),
    scenario=str_replace(pathway,"[ssp]+([0-9])([0-9])([0-9])","SSP\\1-\\2.\\3"),) %>%
  group_by(unit,scenario,method=threshold,timeframe,time,modelname) %>%
  summarise(n=n(),RS=mean(RS_cor),RSmed=median(RS_cor), .groups="keep") %>%
  ungroup %>%
  transmute(unit, scenario, method, time, RS)


dat2 <- totalmass_year_data %>% 
  filter(
    year %in% c(2000,2040,2070,2100),
    ssp %in% c("SSP1-2.6", "SSP3-7.0", "SSP5-8.5")
    ) %>% 
  group_by(unit_name, model_nr, ssp) %>% 
  group_modify(~RSts(.x$year,.x$total_mass,
                     formula = "conditional")) %>%
  ungroup %>% 
    transmute(
      unit=unit_name,
      scenario = ssp,
      method = "ice",
      time = (year-2040)/30,
      RS)

## average RS
model_data <- dat1 %>% 
  bind_rows(dat2) %>% 
  mutate(method=factor(method,levels=c("ice","acc","ess","ppv"))) %>%
  filter(!unit %in% exclude)

rds.file <- sprintf("%s/totalmass-suitability-glmm-data.rds", target.dir)
saveRDS(file=rds.file, model_data)


## cED

# create a grid of arguments to avoid for loops within the `ex` code
jjs <- massbalance_results %>% pull(unit_name) %>% unique()
scs <-  c("SSP1-2.6", "SSP3-7.0", "SSP5-8.5")

argrid <- expand.grid(jjs,scs)

cl <- makeCluster(round(detectCores()*.8))
registerDoParallel(cl)

cED_ice <- 
  foreach (
    jj = argrid$Var1,
    scn = argrid$Var2
    .packages=c( "dplyr", "tidyr"),
    .combine=bind_rows
  ) %dopar% {
    mbdata <- massbalance_results %>% 
      filter(
        unit_name == jj,
        ssp == scn
        )
    wgs <- mbdata %>% 
        filter(year == 2000) %>% 
        group_by( RGIId, model_nr) %>% 
        summarise(initial_mass=sum(mass), .groups="keep") 

    dat3 <- mbdata %>% 
        filter(
          year %in% c(2000,2040,2070,2100)
        ) %>% 
      group_by(RGIId, model_nr) %>% 
      group_modify(~RSts(.x$year,.x$mass,
                        formula = "conditional")) %>%
      ungroup %>% 
      left_join(wgs, by = c("RGIId", "model_nr"))
      
    res <- dat3 %>%
      group_by(year, model_nr) %>% 
      #group_map(~cED_w(.x$RS,.x$initial_mass))
      group_modify(~summary_cED_w(.x$RS,.x$initial_mass)) %>%
      ungroup %>%
        transmute(
          unit=jj,
          scenario = scn,
          method = "ice",
          time = (year-2040)/30,
          cED_30,
          cED_50,
          cED_80, 
          AUC_cED)

    return(res)
  }


## Stop cluster: garbage collection ----

stopCluster(cl)
gc()

## Output: save data to Rdata file ----

rds.file <- sprintf("%s/totalmass-suitability-cED-data.rds", target.dir)
saveRDS(file=rds.file, cED_ice)
