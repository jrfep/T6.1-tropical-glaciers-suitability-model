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
require(raster)
require(stringr)
require(tidyr)
library(caret)
# require(dismo)
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
input.dir <- sprintf("%s/%s/OUTPUT",gis.out,"T6.1-tropical-glaciers-data")
output.dir <- sprintf("%s/%s/OUTPUT",gis.out,projectname)

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

system(sprintf('mkdir -p %s/%s',output.dir,str_replace_all(slc_unit," ","-")))

# Read the data extracted from the raster files for each polygon, and save into a Rdata file.

rda.file <- sprintf("%s/current-bioclim-data-all-groups.rda",output.dir)
if (file.exists(rda.file)) {
   load(rda.file)
} else {
   stop("input_raster_data is missing")
}

## Step 1: prepare data for training and testing  -------

# Exclude low elevations
# table(input_raster_data$glacier,input_raster_data$elevation_1KMmd>3500)
data <- input_raster_data %>%
   tibble %>%
   mutate(id = factor(id)) %>%
   left_join(grp_table, by = "id") %>%
   filter(
      !unit_name %in% slc_unit,
      unit_name %in% all_units,
      elevation_1KMmd > 3500
      )

tt <- table(data$id)

training <- data %>% 
   mutate(prob=if_else(glacier,5,.5)*(sum(tt)/tt[id])) %>% 
   slice_sample(n=10000,weight_by = prob) %>%
   dplyr::select(glacier,bio_01:bio_19) %>%
   mutate(glacier=factor(if_else(glacier,"G","N")))

testing <- input_raster_data %>% 
   tibble %>%
   mutate(id = factor(id)) %>% 
   left_join(grp_table, by = "id") %>%
   filter(unit_name %in% slc_unit,elevation_1KMmd>3500) %>%
   mutate(glacier = factor(if_else(glacier,"G","N")))


## Step 2: tune model parameters  -------

ctrl <- trainControl(
   method = "cv",
   number = 10
)
tuneGrid <- expand.grid(
   n.trees = c(50, 75, 100, 125, 150, 200),
   interaction.depth = (1:5),
   shrinkage = c(0.05, 0.1, 0.5),
   n.minobsinnode = c(5, 7, 10, 12)
)

model <- caret::train(
   glacier ~ .,
   data = training,
   method = 'gbm',
   distribution="bernoulli",
   preProcess = c("center", "scale"),
   trControl = ctrl,
   tuneGrid = tuneGrid,
   verbose = TRUE
)

#model
# plot(model)

## Step 3: save model, training and testing subsets  -------

test.features = testing %>% dplyr::select(bio_01:bio_19)
test.target = testing %>% pull(glacier)

rda.results <- sprintf(
   '%s/%s/gbm-model-current.rda',
   output.dir,
   str_replace_all(slc_unit," ","-")
   )

## Step 4: save model predictions at test location  -------

predictions = predict(model, newdata = test.features, type='prob')

# we will use another approach using the caret library
#e1 <- evaluate(predictions$G[test.target=="G"],predictions$G[test.target=="N"])

testing$IV <- predictions[,"G"]

save(file=rda.results,model,training,testing,slc_unit )

## That's it  -----

cat("Done for today!\n")
