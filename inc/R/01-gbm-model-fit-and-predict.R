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
library(doParallel)
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
output.dir <- sprintf("%s/%s/GBMmodel",gis.out,projectname)

## Read command line arguments
args = commandArgs(trailingOnly=TRUE)
pick <- as.numeric(args[1])

## Input: Load data in R session ----

## Load spatial data for the group polygons and glacier points
grp_table <- 
  read_sf(sprintf("%s/gisdata/trop-glacier-groups-labelled.gpkg",input.dir)) %>%
  st_drop_geometry %>% 
  transmute(id = factor(id), unit_name = group_name)
trop_glaciers_classified <- 
  readRDS(file=sprintf("%s/Rdata/Inner-outer-wet-dry-glacier-classification.rds",
  input.dir))
all_units <- unique(grp_table$unit_name)
slc_unit <- all_units[ifelse(is.na(pick), 6, pick)]

exclude <- c("Temperate Glacier Ecosystems", "Famatina", "Norte de Argentina", "Zona Volcanica Central")

if (slc_unit %in% exclude) {
  stop("Skipping temperate and transitional glacier ecosystems")
}

system(sprintf('mkdir -p %s/%s', output.dir, str_replace_all(slc_unit, " ", "-")))

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
input_data <- input_raster_data %>%
   tibble %>%
   mutate(id = factor(id)) %>%
   left_join(grp_table, by = "id") %>%
   filter(
      !unit_name %in% slc_unit,
      unit_name %in% all_units,
      elevation_1KMmd > 3500
      ) %>% 
  mutate(andes = grepl("Peru|Colombia|Ecuador",unit_name))

tt <- table(input_data$id)

sample_size <- case_when(
  slc_unit %in% "Kilimanjaro" ~ 5000L,
  TRUE ~ 10000L
)
if (!grepl("Peru|Colombia|Ecuador",slc_unit)) {
  prob <- if_else(input_data$glacier,5,.5)*if_else(input_data$andes,1,3)*(sum(tt)/tt[input_data$id])
} else {
  prob <- if_else(input_data$glacier,5,.5)*(sum(tt)/tt[input_data$id])
}

training <- input_data %>% 
   slice_sample(n=sample_size, weight_by = prob) %>%
   dplyr::select(glacier,starts_with("bio_")) %>%
   mutate(glacier=factor(if_else(glacier,"G","N")))

testing <- input_raster_data %>% 
   tibble %>%
   mutate(id = factor(id)) %>% 
   left_join(grp_table, by = "id") %>%
   filter(unit_name %in% slc_unit, elevation_1KMmd>3500) %>%
   mutate(glacier = factor(if_else(glacier,"G","N")))


## Step 2: tune model parameters  -------

ctrl <- trainControl(
   method = "cv",
   number = 10
)
# suggestion from https://topepo.github.io/caret/model-training-and-tuning.html#metrics
fitControl <- trainControl(method = "repeatedcv",
                           number = 10,
                           repeats = 10,
                           ## Estimate class probabilities
                           classProbs = TRUE,
                           ## Evaluate performance using 
                           ## the following function
                           summaryFunction = twoClassSummary)

tuneGrid <- expand.grid(
   n.trees = c(50, 75, 100, 125, 150, 200),
   interaction.depth = (1:5),
   shrinkage = c(0.05, 0.1, 0.5),
   n.minobsinnode = c(5, 7, 10, 12)
)

## Register cluster for Parallel # see topepo.github.io/caret/parallel-processing.html

cl <- makeCluster(detectCores()-1)
registerDoParallel(cl)

model <- caret::train(
   glacier ~ .,
   data = training,
   method = 'gbm',
   distribution="bernoulli",
   preProcess = c("center", "scale"),
   trControl = fitControl,
   tuneGrid = tuneGrid,
   ## Specify which metric to optimize
   metric = "ROC",
   verbose = TRUE
)

## stop parallel cluster
stopCluster(cl)
#model
# plot(model)

## Step 3: save model, training and testing subsets  -------

test.features = testing %>% dplyr::select(starts_with("bio_"))
test.target = testing %>% pull(glacier)

rda.results <- sprintf(
   '%s/%s/gbm-model-current.rda',
   output.dir,
   str_replace_all(slc_unit," ","-")
   )

## Step 4: save model predictions at test location  -------


# we will use another approach using the caret library
#e1 <- evaluate(predictions$G[test.target=="G"],predictions$G[test.target=="N"])

predictions = predict(model, newdata = test.features, type='prob')
testing$IV <- predictions[,"G"]

predictions = predict(model,  type='prob')
training$IV <- predictions[,"G"]

save(file=rda.results,model,training,testing,slc_unit )

## That's it  -----

cat("Done for today!\n")
