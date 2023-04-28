require(dplyr)
require(tidyr)
library(ncdf4)
require(doParallel)
library(sf)

here::i_am("inc/R/06-massbalance-model-results.R")

#And load computing environment variables:
source(here::here("env","project-env.R"))
input.dir <- sprintf("%s/%s/INPUT", gis.out, "T6.1-tropical-glaciers-data")
output.dir <- sprintf("%s/%s/OUTPUT", gis.out, "T6.1-tropical-glaciers-data")
target.dir <- sprintf("%s/%s/OUTPUT", gis.out, projectname)

dir(sprintf("%s/PyGEM-OGGM/", input.dir))

trop_glaz_pols <- read_sf(sprintf("%s/gisdata/trop-glacier-groups-labelled.gpkg", output.dir)) 

grp_table <- trop_glaz_pols  %>%
  st_drop_geometry %>% 
  transmute(id=factor(id),unit_name=group_name)
trop_glaciers_classified <- readRDS(
  file=sprintf("%s/Rdata/Inner-outer-wet-dry-glacier-classification.rds",
               output.dir)
)


exclude <- c("Temperate Glacier Ecosystems", "Famatina", "Norte de Argentina", "Zona Volcanica Central")

# create a grid of arguments to avoid for loops within the `ex` code
jjs <- grp_table %>% filter(!unit_name %in% exclude) %>% pull(id) %>% as.numeric()
scs <-  c("ssp126","ssp370","ssp585")
rgs <- c("R16", "R17") # low latitudes and southern andes, just in case

argrid <- expand.grid(jjs,scs,rgs)

cl <- makeCluster(round(detectCores()*.8))
registerDoParallel(cl)

all_massbalance_results <- 
  foreach (
    jj = argrid$jjs,
    scn = argrid$scs,
    rgn = argrid$rgs,
    .packages=c("ncdf4", "dplyr", "tidyr"),
    .combine=bind_rows
  ) %dopar% {
    slc <- trop_glaciers_classified %>% filter(grp %in% jj, !is.na(RGIId)) %>% pull(RGIId)
    mass_nc_file <- sprintf("%s/PyGEM-OGGM/%s_glac_mass_annual_50sets_2000_2100-%s.nc", input.dir,rgn,scn)
    mad_nc_file <- sprintf("%s/PyGEM-OGGM/%s_glac_mass_annual_mad_50sets_2000_2100-%s.nc", input.dir,rgn,scn)
    massbalance_results <- tibble()
    
    if(length(slc)>0) {        
        model_results <- nc_open(mass_nc_file)
        RGIIds  <- ncvar_get(model_results, "RGIId")
        if (sum(RGIIds %in% slc)>0) {
          slc_fixed <- RGIIds[RGIIds %in% slc]
          mad_results <- nc_open(mad_nc_file)
          mass  <- ncvar_get(model_results, "glac_mass_annual")
          mass_mad  <- ncvar_get(mad_results, "glac_mass_annual_mad")
          
          yy  <- ncvar_get(model_results, "year")
          dts <- data.frame(mass[,RGIIds %in% slc_fixed,])
          mts <- data.frame(mass_mad[,RGIIds %in% slc_fixed,])
          colnames(dts) <- expand.grid(slc_fixed,01:12) %>% apply(1,FUN=paste,collapse="_")
          colnames(mts) <- expand.grid(slc_fixed,01:12) %>% apply(1,FUN=paste,collapse="_")
          dts$year=yy
          mts$year=yy
          dts$scn <- scn
          
          this_result <- dts %>%
            pivot_longer(cols=starts_with("RG"),names_sep="_",names_to=c("RGIId","model_nr")) %>%
            inner_join(
              {mts %>%
                  pivot_longer(cols=starts_with("RG"),names_sep="_",names_to=c("RGIId","model_nr"))
              }, by=c("RGIId","model_nr","year")) %>%
            rename(c(mass="value.x",mad="value.y")) %>% 
            mutate(grp=jj, unit_name={grp_table %>% filter(id==jj) %>% pull(unit_name)})
          
          massbalance_results <- massbalance_results %>%
            bind_rows(this_result)
        }
      }
    } 
    return(massbalance_results)
}


## Stop cluster: garbage collection ----

stopCluster(cl)
gc()



## Output: save data to Rdata file ----

rds.file <- sprintf("%s/massbalance-model-data-all-groups.rds",target.dir)

saveRDS(file=rds.file, all_massbalance_results)
