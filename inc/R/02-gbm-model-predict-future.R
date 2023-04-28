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
require(sf)
require(magrittr)
require(tibble)
require(terra)
require(stringr)
require(tidyr)
library(caret)
require(dismo)
require(readr)

## Programing environment variables
env_file_path <- "proyectos/Tropical-Glaciers/T6.1-tropical-glaciers-suitability-model/"
source(
    sprintf(
        "%s/%s/env/project-env.R",
        Sys.getenv("HOME"),
        env_file_path
    )
)
input.dir <- sprintf("%s%s/OUTPUT",gis.out,"T6.1-tropical-glaciers-data")
output.dir <- sprintf("%s%s/OUTPUT",gis.out,projectname)

## Read command line arguments
args = commandArgs(trailingOnly=TRUE)
pick <- as.numeric(args[1])

## Input: Load data in R session ----

## Load spatial data for the group polygons and glacier points
grp_table <- read_sf(sprintf("%s/gisdata/trop-glacier-groups-labelled.gpkg",input.dir)) %>%
   st_drop_geometry %>% transmute(id=factor(id),unit_name=group_name)
trop_glaciers_classified <- readRDS(file=sprintf("%s/Rdata/Inner-outer-wet-dry-glacier-classification.rds",
   input.dir))
all_units <- unique(grp_table$unit_name)
slc_unit <- all_units[ifelse(is.na(pick),12,pick)]

exclude <- c("Temperate Glacier Ecosystems", "Famatina", "Norte de Argentina", "Zona Volcanica Central")

if (slc_unit %in% exclude) {
  stop("Skipping temperate and transitional glacier ecosystems")
}

# Read the data extracted from the raster files for each polygon, and save into a Rdata file.

rda.results <- sprintf('%s/%s/gbm-model-current.rda',output.dir,str_replace_all(slc_unit," ","-"))

load(file=rda.results)

## Step 5: predictions for different timeframes models and pathways  -------

ids <- grp_table %>% filter(unit_name %in% slc_unit) %>% pull(id) %>% as.numeric()

for (timeframe in c("2011-2040","2041-2070","2071-2100")) {
   for (modelname in c("ukesm1-0-ll","mri-esm2-0","ipsl-cm6a-lr","gfdl-esm4","mpi-esm1-2-hr")) {
      for (pathway in c("ssp126","ssp370","ssp585")) {
         cat(sprintf("prediction for %s_%s_%s :: ",timeframe,modelname,pathway))
         newdata <- data.frame()
         for (Group in ids) {
            archs <- list.files(sprintf('%s/Group-%02d/modvars',input.dir,Group),
                                pattern=sprintf("%s_%s_%s",timeframe,modelname,pathway),
                                full.names=T)
            if (length(archs)>0) {
               r0 <- rast(archs)
               names(r0) <- sprintf("bio_%02d",as.numeric(str_extract(str_extract(basename(archs),"bio[0-9]+"),"[0-9]+")))
               vals <- values(r0)
               cellnr <- 1:ncell(r0)
               ss <- rowSums(is.na(vals))==0
               newdata %<>% bind_rows({data.frame(vals,id=as.character(Group),cellnr) %>% filter(ss)})
            }
         }
         if (nrow(newdata)>0) {
            newdata <- newdata %>% 
               left_join(testing %>% 
               transmute(id=as.character(id),cellnr,glacier),by=c("id","cellnr")) %>% 
               filter(glacier == "G")
            newdata$FV <- predict(model, newdata,type="prob")[,"G"]

            rds.results.future <- sprintf('%s/%s/gbm-prediction-%s-%s-%s.rds',
               output.dir,
               str_replace_all(slc_unit," ","-"),
               timeframe,
               modelname,
               pathway)

            saveRDS(file=rds.results.future, newdata)
            cat("done\n ")
         } else {
            cat("data not found, skipping\n ")
         }
      }
   }
}


## That's it  -----

cat("Done for today!\n")
