#! R --no-save --no-restore
script_dir <-
  "proyectos/Tropical-Glaciers/T6.1-tropical-glaciers-suitability-model/"
source(
  sprintf("%s/%s/env/project-env.R",
  Sys.getenv("HOME"),
  script_dir
  )
)

library(dplyr)
library(osfr)

here::i_am("inc/R/11-download-files-from-OSF.R")
target_dir <- "sandbox"
if (!file.exists(here::here(target_dir)))
  dir.create(here::here(target_dir))

## read value for conflicts argument
args <- commandArgs(trailingOnly = TRUE)
if (args[1] %in% c("skip", "overwrite")) {
  conflict_answer <- args[1]
} else {
  conflict_answer <- "skip"
}

osfcode <- Sys.getenv("OSF_PROJECT")
osf_project <- osf_retrieve_node(sprintf("https://osf.io/%s", osfcode))
my_project_components <- osf_ls_nodes(osf_project)

## navigate to each subcomponent...
compname <-
  "Data for the global RLE assessment of Tropical Glacier Ecosystems"
idx <- my_project_components %>%
  filter(name %in% compname) %>%
  pull(id)

global_data_comp <- osf_retrieve_node(sprintf("https://osf.io/%s", idx))

compname <- "Environmental suitability model for Tropical Glacier Ecosystems"
idx <- my_project_components %>%
  filter(name %in% compname) %>%
  pull(id)
env_suitability_comp <- osf_retrieve_node(sprintf("https://osf.io/%s", idx))

## Download/update our target directory

osf_data_all_files <- osf_ls_files(global_data_comp)

osf_download(
  osf_data_all_files,
  path = here::here(target_dir),
  conflicts = conflict_answer)

project_files <- osf_ls_files(env_suitability_comp)
osf_download(
  project_files,
  path = here::here(target_dir),
  conflicts = conflict_answer)