#!/usr/bin/R --vanilla
####
## Fit a Gradient Boosting Machine model to the Tropical Glacier Ecosystem distribution
####

## Input: 
## Steps: a) 
## Output: 

## Set up  -------
## Libraries

require(dplyr)
require(sf)
require(magrittr)
require(tibble)
require(raster)
require(stringr)
require(tidyr)
library(caret)
require(dismo)
require(readr)

## Programing environment variables
source(sprintf("%s/proyectos/Tropical-Glaciers/T6.1-tropical-glaciers-suitability-model/env/project-env.R",Sys.getenv("HOME")))
input.dir <- sprintf("%s/%s/INPUT",gis.out,projectname)
output.dir <- sprintf("%s/%s/OUTPUT",gis.out,projectname)

## Read command line arguments
args = commandArgs(trailingOnly=TRUE)
pick <- as.numeric(args[1])

## Utility functions
## relative severity
meanRS <- function(IV,FV,CT) {
   pres <- IV>CT
   MD=(CT-IV)[pres]
   #OD=ifelse(FV>IV,0,ifelse(FV<CT,CT-IV,FV-IV))[pres]
   OD=ifelse(FV>IV,0,FV-IV)[pres]
   RS <- ifelse(abs(OD)>abs(MD),MD,OD)/MD
   return(mean(RS))
}


## Input: Load data in R session ----

## Load spatial data for the group polygons and glacier points
grp_table <- read_sf(sprintf("%s/gisdata/trop-glacier-groups-labelled.gpkg",output.dir)) %>%
   st_drop_geometry %>% transmute(id=factor(id),unit_name=group_name)
trop_glaciers_classified <- readRDS(file=sprintf("%s/Rdata/Inner-outer-wet-dry-glacier-classification.rds",output.dir))
all_units <- unique(grp_table$unit_name)
slc_unit <- all_units[ifelse(is.na(pick),12,pick)]

rda.results <- sprintf('%s/Rdata/gbm-model-%s.rda',output.dir,str_replace_all(slc_unit," ","-"))

# Read the data extracted from the raster files for each polygon, and save into a Rdata file.

rda.file <- sprintf("%s/Rdata/bioclim-model-data-groups.rda",output.dir)
if (file.exists(rda.file)) {
   load(rda.file)
} else {
   require(doParallel)
   if (!exists("rawdata")) {
      jjs <- unique(trop_glaciers_classified$grp)
      jjs <- jjs[jjs %in% 3:36]
      cl <- makeCluster(round(detectCores()*.8))
      registerDoParallel(cl)

      rawdata <- foreach (j=jjs,.packages=c("raster","sf","dplyr","magrittr","stringr"),.combine=bind_rows) %dopar% {
         mapfiles <- dir(sprintf("%s/Group-%02d/modvars",output.dir,j),"1981-2010",full.names=T)
         maps<- stack(mapfiles)
         names(maps) <- sprintf("bio10_%02d",as.numeric(str_extract(str_extract(mapfiles,"bio[0-9]+"),"[0-9]+")))
         e0 <- raster(sprintf('%s/Group-%02d/GMTED/elevation_1KMmd_GMTEDmd.tif',output.dir,j))
         e1 <- resample(e0,maps)

         vals <- values(maps)
         eles <- values(e1)

         glaz_points <- trop_glaciers_classified %>% filter(grp %in% j) %>% dplyr::select(X1,X2)
         cellnr <- 1:ncell(maps)
         glaz_qry <- raster::cellFromXY(maps,data.frame(glaz_points ))

         ss <- rowSums(is.na(vals))==0
         xys <- xyFromCell(maps,(1:ncell(maps))[ss])
         if (any(ss)) {
            data.frame(id=j,vals[ss,],lon=xys[,1],lat=xys[,2],elevation_1KMmd=eles[ss],cellnr=cellnr[ss],glacier={cellnr[ss] %in% glaz_qry})
         } else {
            data.frame(id=j)
         }
      }

      stopCluster(cl)
      gc()
      save(file=rda.file,rawdata)
   }
}

## Step 1: prepare data for training and testing  -------

# Exclude low elevations
# table(rawdata$glacier,rawdata$elevation_1KMmd>3500)
data <- rawdata %>% tibble %>% mutate(id=factor(id)) %>% left_join(grp_table,by="id") %>%
   filter(!unit_name %in% slc_unit,unit_name %in% all_units,elevation_1KMmd>3500) 

tt <- table(data$id)

training <- data %>% mutate(prob=if_else(glacier,5,.5)*(sum(tt)/tt[id])) %>% slice_sample(n=10000,weight_by = prob) %>%
   dplyr::select(glacier,bio10_01:bio10_19) %>%
   mutate(glacier=factor(if_else(glacier,"G","N")))

testing <- rawdata %>% tibble %>% mutate(id=factor(id)) %>% left_join(grp_table,by="id") %>%
   filter(unit_name %in% slc_unit,elevation_1KMmd>3500) %>%
   mutate(glacier=factor(if_else(glacier,"G","N")))


## Step 2: tune model parameters  -------

ctrl <- trainControl(
   method = "cv",
   number = 10
)
tuneGrid <- expand.grid(
   n.trees = c(50, 75, 100, 125, 150, 200),
   interaction.depth = (1:5),
   shrinkage = c(0.05,0.1,0.5),
   n.minobsinnode = c(5,7,10,12)
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

test.features = testing %>% dplyr::select(bio10_01:bio10_19)
test.target = testing %>% pull(glacier)

save(file=rda.results,model,training,testing,slc_unit)

## Step 4: save model predictions at test location  -------

predictions = predict(model, newdata = test.features, type='prob')

save(file=rda.results,model,training,testing,predictions,slc_unit )

## Step 5: Predicted cells for different thresholds  -------

e1 <- evaluate(predictions$G[test.target=="G"],predictions$G[test.target=="N"])

IV <- predictions$G[test.target=="G"]
CT <- threshold(e1)
rslts <- tibble(timeframe="1981-2010",
                modelname="observed",
                pathway=c("ssp126","ssp370","ssp585"),
                predCells=sum(test.target=="G"))

for (ctopt in c("prevalence","spec_sens","equal_sens_spec")) {
   vals <- sum(IV>CT[[ctopt]])
   rslts %<>%    bind_rows(tibble(timeframe="1981-2010",
                                  modelname="current",
                                  CT=ctopt,
                                  pathway=c("ssp126","ssp370","ssp585"),
                                  predCells=vals))
}
save(file=rda.results,model,training,testing,predictions,rslts,slc_unit )

## Step 6: Relative severity for different thresholds  -------

ids <- grp_table %>% filter(unit_name %in% slc_unit) %>% pull(id) %>% as.numeric()

for (timeframe in c("2011-2040","2041-2070","2071-2100")) {
   for (modelname in c("ukesm1-0-ll","mri-esm2-0","ipsl-cm6a-lr","gfdl-esm4","mpi-esm1-2-hr")) {
      for (pathway in c("ssp126","ssp370","ssp585")) {
         cat(sprintf("prediction for %s_%s_%s \n ",timeframe,modelname,pathway))
         newdata <- data.frame()
         for (Group in ids) {
            archs <- list.files(sprintf('%s/Group-%02d/modvars',output.dir,Group),
                                pattern=sprintf("%s_%s_%s",timeframe,modelname,pathway),
                                full.names=T)
            r0 <- stack(archs)
            names(r0) <- sprintf("bio10_%02d",as.numeric(str_extract(str_extract(basename(archs),"bio[0-9]+"),"[0-9]+")))
            vals <- values(r0)
            cellnr <- 1:ncell(r0)
            ss <- rowSums(is.na(vals))==0
            newdata %<>% bind_rows({data.frame(vals,id=as.character(Group),cellnr) %>% filter(ss)})
         }
         newdata %<>% left_join(testing %>% transmute(id=as.character(id),cellnr,glacier),by=c("id","cellnr")) %>% filter(glacier == "G")
         predictions = predict(model, newdata,type="prob")[,"G"]

         for (ctopt in c("prevalence","spec_sens","equal_sens_spec")) {
            vals <- sum(predictions>CT[[ctopt]])
            RSval <- meanRS(IV,FV=predictions,CT[[ctopt]])
            rslts %<>%    bind_rows(tibble(timeframe,
                                           modelname,
                                           CT=ctopt,
                                           pathway,
                                           predCells=vals,
                                           meanRS=RSval))
         }
      save(file=rda.results,model,training,testing,predictions,rslts,slc_unit )
      }
   }
}


## Output: Save final results  -----
save(file=rda.results,model,training,testing,rslts,slc_unit)

cat("Done for today!\n")
