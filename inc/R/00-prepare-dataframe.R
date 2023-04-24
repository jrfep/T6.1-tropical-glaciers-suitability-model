#!/usr/bin/R --vanilla
####
## Prepare data to fit a Gradient Boosting Machine model to the Tropical Glacier Ecosystem distribution
####

## Outline
## - Set up
## - Input: Load data prepared for each group using a parallel cluster
## - Stop cluster and clean up
## - Output: save file to output Rdata file

## Set up / Libraries -------

require(dplyr)
require(sf)
require(tibble)
require(terra)
require(doParallel)

## Set up / Programing environment variables  -------
env_file_path <- "proyectos/Tropical-Glaciers/T6.1-tropical-glaciers-suitability-model/"
source(
    sprintf(
        "%s/%s/env/project-env.R",
        Sys.getenv("HOME"),
        env_file_path
    )
)
input.dir <- sprintf("%s/%s/OUTPUT", gis.out, "T6.1-tropical-glaciers-data")
output.dir <- sprintf("%s/%s/OUTPUT", gis.out, projectname)

## Input: Load data in R session ----

## Load spatial data for the group polygons and glacier points
trop_glaz_pols <- read_sf(sprintf("%s/gisdata/trop-glacier-groups-labelled.gpkg", input.dir)) 

grp_table <- trop_glaz_pols  %>%
   st_drop_geometry %>% 
   transmute(id=factor(id),unit_name=group_name)
trop_glaciers_classified <- readRDS(
    file=sprintf("%s/Rdata/Inner-outer-wet-dry-glacier-classification.rds",
    input.dir)
    )
all_units <- unique(grp_table$unit_name)

# Read the data extracted from the raster files for each polygon, and save into a Rdata file.

## take the ids directly from the table
jjs <- grp_table %>% filter(!unit_name %in% "Temperate Glacier Ecosystems") %>% pull(id) %>% as.numeric()

## jjs <- unique(trop_glaciers_classified$grp)
## jjs <- jjs[jjs %in% 3:36]

cl <- makeCluster(round(detectCores()*.8))
registerDoParallel(cl)

input_raster_data <- 
    foreach (
        j = jjs,
        .packages=c("terra", "sf", "dplyr", "magrittr", "stringr"),
        .combine=bind_rows
    ) %dopar% {
        mapfiles <- dir(sprintf("%s/Group-%02d/modvars", input.dir, j), "1981-2010", full.names=T)
        maps<- terra::rast(mapfiles)
        names(maps) <- sprintf(
            "bio_%02d",
            as.numeric(str_extract(str_extract(mapfiles, "bio[0-9]+"), "[0-9]+"))
            )
        e0 <- terra::rast(
            sprintf(
                '%s/Group-%02d/GMTED/elevation_1KMmd_GMTEDmd.tif',
                input.dir, 
                j
            )
        )

        e1 <- resample(e0,maps)

        vals <- values(maps)
        eles <- values(e1)

        glaz_points <- trop_glaciers_classified %>% 
            filter(grp %in% j) %>% 
            dplyr::select(X1,X2)
        cellnr <- 1:ncell(maps)
        glaz_qry <- terra::cellFromXY(maps, data.frame(glaz_points ))

        ss <- rowSums(is.na(vals))==0
        xys <- xyFromCell(maps, (1:ncell(maps))[ss])
        if (any(ss)) {
            data.frame(
                id=j,
                vals[ss,],
                lon=xys[,1],
                lat=xys[,2],
                elevation_1KMmd=eles[ss],
                cellnr=cellnr[ss],
                glacier={cellnr[ss] %in% glaz_qry})
        } else {
            data.frame(id = j)
        }
    }

## Stop cluster: garbage collection ----

stopCluster(cl)
gc()



## Output: save data to Rdata file ----

rda.file <- sprintf("%s/current-bioclim-data-all-groups.rda",output.dir)

save(file=rda.file, input_raster_data)
