source(sprintf("%s/proyectos/IUCN-GET-L4/T6.1-tropical-glaciers/env/project-env.R", Sys.getenv("HOME")))
input.dir <- sprintf("%s/%s/INPUT",gis.out,projectname)
output.dir <- sprintf("%s/%s/OUTPUT",gis.out,projectname)

library(dplyr)
library(osfr)

osfcode <- Sys.getenv("OSF_PROJECT")
osf_project <- osf_retrieve_node(sprintf("https://osf.io/%s", osfcode))
my_project_components <- osf_ls_nodes(osf_project)

source(sprintf("%s/inc/osf-functions.R", script.dir))

global_data_comp <- osf_find_or_create_component(
  my_project_components,
  comp_name = "Data for the global RLE assessment of Tropical Glacier Ecosystems",
  comp_desc = "Data for the global Red List of Ecosystems assessment of all Tropical Glacier Ecosystems. This component contains data files to be used by other components of the project.",
  comp_cat = "data"
)

data_file  <- osf_upload(global_data_comp, 
                         path = sprintf("%s/Rdata/bioclim-model-data-groups.rda",output.dir)
)

osf_all_files <- osf_ls_files(global_data_comp)

#target.dir <- tempdir()
#osf_download(osf_all_files,path=target.dir)
#dir(target.dir)
