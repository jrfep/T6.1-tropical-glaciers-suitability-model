#!/usr/bin/R --vanilla
####
## Fit a Gradient Boosting Machine model to the Tropical Glacier Ecosystem distribution
####

## Outline
## - Set up
## - Input: Load data prepared for each group using a parallel cluster
## - Run GBM for each group using data from other groups
## - Output: save file to output Rdata file

## Set up / Libraries -------

library(dplyr)
library(raster)
library(dismo)

## Programing environment variables
env_file_path <- "proyectos/Tropical-Glaciers/T6.1-tropical-glaciers-suitability-model/"
source(
    sprintf(
        "%s/%s/env/project-env.R",
        Sys.getenv("HOME"),
        env_file_path
    )
)
input.dir <- sprintf("%s%s/OUTPUT/",gis.out,projectname)

dir(sprintf("%s/Mexico/",input.dir))

load(sprintf("%s/Mexico/gbm-model-current.rda",input.dir))

all_results <- tibble()
for (timeframe in c("2011-2040", "2041-2070", "2071-2100")) {
    for (pathway in c("ssp126")) {
        for (modelname in "mri-esm2-0") {
            future_prediction <- readRDS(
                sprintf("%s/Mexico/gbm-prediction-%s-%s-%s.rds",
                    input.dir,
                    timeframe,
                    modelname,
                    pathway))

            rslts <- testing %>% 
                inner_join(future_prediction, by=c("id", "cellnr", "glacier")) %>% 
                dplyr::select(id, cellnr, glacier, IV, FV) %>% 
                mutate(timeframe, modelname, pathway)
            all_results <- all_results %>% bind_rows(rslts)

        }
    }
}

CT <- threshold(e1)[c("prevalence","spec_sens","equal_sens_spec")]

RS_results <- all_results %>% 
    mutate(
        OD=IV-FV,
        MD_p=IV-CT[[1]],
        MD_ss=IV-CT[[2]],
        MD_ess=IV-CT[[3]],
        RS_p=OD/MD_p,
        RS_ss=OD/MD_ss,
        RS_ess=OD/MD_ess,
        )
