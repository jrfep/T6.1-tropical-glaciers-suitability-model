source(sprintf("%s/proyectos/Tropical-Glaciers/T6.1-tropical-glaciers-suitability-model/env/project-env.R", Sys.getenv("HOME")))
output.dir <- sprintf("%s/%s/",gis.out,projectname)

library(dplyr)
library(osfr)

here::i_am("inc/R/05-upload-files-to-OSF.R")
#target.dir <- tempdir()
target.dir <- "sandbox"
if (!file.exists(here::here(target.dir)))
  dir.create(here::here(target.dir))


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

osf_data_all_files <- osf_ls_files(global_data_comp)
osf_download(osf_data_all_files, path=here::here(target.dir), conflicts="skip")

file_to_upload <- sprintf("%s/relative-severity-degradation-suitability-all-tropical-glaciers.csv", output.dir)

data_file  <- osf_upload(env_suitability_comp, 
                         path = file_to_upload,
                         conflicts = "skip"
)

project_files <- osf_ls_files(env_suitability_comp)
osf_download(project_files, path=here::here(target.dir))

