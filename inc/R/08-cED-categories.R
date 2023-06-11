library(units)
library(dplyr)
library(stringr)
library(readr)
library(doParallel)

here::i_am("inc/R/07-glmm-data-summarised.R")

source(here::here("inc", "R", "RS-functions.R"))
source(here::here("env", "project-env.R"))

if (exists("gis.out")) {
    target_dir <- sprintf("%s/%s/", gis.out, projectname)
    rds_file <- sprintf("%s/massbalance-model-data-all-groups.rds", target_dir)
    out_file <- sprintf("%s/collapse-trajectory-data.rds", target_dir)

} else {
    target_dir <- "sandbox"
    rds_file <- here::here(target_dir, "massbalance-model-data-all-groups.rds")
    out_file <- here::here(target_dir, "collapse-trajectory-data.rds")
}
massbalance_results <- readRDS(rds_file)

jj <- "Cordillera de Merida"
ss <- "SSP5-8.5"


cl <- makeCluster(round(detectCores() * 0.8))
registerDoParallel(cl)

# create a grid of arguments to avoid for loops within the `ex` code
jjs <- c("Puncak Jaya", "Kilimanjaro", "Mount Kenia",
  "Ruwenzori", "Mexico", "Sierra Nevada de Santa Marta",
  "Cordillera de Merida")
scs <-  c("SSP1-2.6", "SSP2-4.5", "SSP3-7.0", "SSP5-8.5")

argrid <- expand.grid(jjs, scs)

collapse_trajectories <- foreach(
    jj = argrid$Var1,
    ss = argrid$Var2,
    .packages = c("dplyr", "tidyr"),
    .combine = bind_rows,
    .multicombine = TRUE,
    .export = c("RSts", "summary_cED_w", "cED_w")
  ) %dopar% {
    mbdata <- massbalance_results %>%
    filter(
        unit_name %in% jj,
        ssp %in% ss
        )

    RSa_data <- mbdata %>%
        group_by(model_nr, year) %>%
        summarise(total_mass = sum(mass), .groups = "keep") %>%
        ungroup %>%
        group_by(model_nr) %>%
        group_modify(
            ~RSts(
                .x$year,
                .x$total_mass,
                formula = "conditional"))

    wgs <- mbdata %>%
        filter(year == 2000) %>%
        group_by(RGIId, model_nr) %>%
        summarise(initial_mass = sum(mass), .groups = "keep")

    RSi_data <- mbdata %>%
    group_by(RGIId, model_nr) %>%
    group_modify(~RSts(.x$year, .x$mass,
                        formula = "conditional")) %>%
    ungroup %>%
    left_join(wgs, by = c("RGIId", "model_nr"))

    cED_data <- RSi_data %>%
        group_by(model_nr, year) %>%
        #group_map(~cED_w(.x$RS, .x$initial_mass))
        group_modify(~summary_cED_w(.x$RS, .x$initial_mass)) %>%
        ungroup

    collapse_year <- RSa_data %>%
        filter(RS == 1) %>%
        summarise(collapse_year = min(year))

    all_data <-
    RSa_data %>%
    inner_join(cED_data, by = c("model_nr", "year")) %>%
    left_join(collapse_year, by = "model_nr") %>%
    mutate(
        unit_name = jj,
        scenario = ss,
        state = case_when(
            RS == 1 ~ "collapsed",
            cED_80 >= 0.80 ~ "very wide",
            cED_80 >= 0.50 ~ "very inter",
            cED_50 >= 0.80 ~ "high wide",
            cED_80 >= 0.30 ~ "very local",
            cED_50 >= 0.50 ~ "high inter",
            cED_30 >= 0.80 ~ "mod wide",
            TRUE ~ "low"
        ),
        countdown = if_else(is.na(collapse_year),
            2100 - year,
            collapse_year - year)
    ) %>%
        select(
            unit_name,
            scenario,
            year,
            countdown,
            model_nr,
            RS:AUC_cED,
            state)

    return(all_data)
  }


## Stop cluster: garbage collection ----

stopCluster(cl)
gc()

## Output: save data to Rdata file ----

saveRDS(file = out_file, collapse_trajectories)
