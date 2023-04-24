#! R --no-save --no-restore

source(sprintf("%s/proyectos/Tropical-Glaciers/T6.1-tropical-glaciers-suitability-model/env/project-env.R", Sys.getenv("HOME")))
output.dir <- sprintf("%s/%s/",gis.out,projectname)

library(dplyr)
library(osfr)

here::i_am("inc/R/05-upload-files-to-OSF.R")
#target.dir <- tempdir()
target.dir <- "sandbox"
if (!file.exists(here::here(target.dir)))
  dir.create(here::here(target.dir))

## read value for conflicts argument
args = commandArgs(trailingOnly=TRUE)
if (args[1] %in% c("skip","overwrite")) {
  conflict_answer <- args[1]
} else {
  conflict_answer <- "skip"
}

osfcode <- Sys.getenv("OSF_PROJECT")
osf_project <- osf_retrieve_node(sprintf("https://osf.io/%s", osfcode))
my_project_components <- osf_ls_nodes(osf_project)

## navigate to each subcomponent...
idx <- my_project_components %>% filter(name %in% "Data for the global RLE assessment of Tropical Glacier Ecosystems") %>%
  pull(id) 
global_data_comp <- osf_retrieve_node(sprintf("https://osf.io/%s", idx))

idx <- my_project_components %>% filter(name %in% "Environmental suitability model for Tropical Glacier Ecosystems") %>%
  pull(id) 
env_suitability_comp <- osf_retrieve_node(sprintf("https://osf.io/%s", idx))


## First upload to data component

file_to_upload <- sprintf("%s/OUTPUT/current-bioclim-data-all-groups.rda", output.dir)

data_file  <- osf_upload(global_data_comp, 
                         path = file_to_upload,
                         conflicts = conflict_answer
)


## Now upload the result table in env model component

file_to_upload <- sprintf("%s/relative-severity-degradation-suitability-all-tropical-glaciers.rds", output.dir)

data_file  <- osf_upload(env_suitability_comp, 
                         path = file_to_upload,
                         conflicts = conflict_answer
)

file_to_upload <- sprintf("%s/relative-severity-degradation-suitability-all-tropical-glaciers.csv", output.dir)

data_file  <- osf_upload(env_suitability_comp, 
                         path = file_to_upload,
                         conflicts = conflict_answer
)

## Download/update our target directory

osf_data_all_files <- osf_ls_files(global_data_comp)
osf_download(osf_data_all_files, path=here::here(target.dir), conflicts=conflict_answer)

project_files <- osf_ls_files(env_suitability_comp)
osf_download(project_files, path=here::here(target.dir), conflicts=conflict_answer)

