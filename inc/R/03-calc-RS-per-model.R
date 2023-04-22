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

require(dplyr)
require(raster)

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

dir(sprintf("%s/Ecuador/",input.dir))

(load(sprintf("%s/Ecuador/gbm-model-current.rda",input.dir)))
IV <- predictions[,"G"]
(load(sprintf("%s/Ecuador/gbm-prediction-2011-2040-mri-esm2-0-ssp126.rda",input.dir)))
FV <- predictions