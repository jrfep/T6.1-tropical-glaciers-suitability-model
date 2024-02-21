library(dplyr)
library(sf)

here::i_am("inc/R/24-ms-map.R")
target_dir <- "sandbox"
gpkg_file <- here::here(target_dir,"trop-glacier-groups-labelled.gpkg")
kml_file <- here::here(target_dir,"Study_area_tropical_glaciers.kml")
glaz_groups <- read_sf(gpkg_file)

grps <- c("Kilimanjaro", "Ruwenzori", "Ecuador", "Sierra Nevada de Santa Marta",
          "Cordillera de Merida",
          "Cordilleras de Colombia",
          "Puncak Jaya")

extra_andean <- c("Puncak Jaya", "Mount Kenia", "Ruwenzori", "Kilimanjaro", "Mexico", "Sierra Nevada de Santa Marta")
extra_andean_desc <- c("Extra andean tropical glaciers located in a single mountain top in Indonesia. The Randolph Glacier Inventory includes four glacier outlines within ca. 22 squared kilometers. The modelled initial ice mass for year the 2000  is less than 80 Megatonnes.",
                       "Extra andean tropical glaciers located in Kenya. The Randolph Glacier Inventory includes three glacier outlines within 3 squared kilometers. The modelled initial ice mass for year the 2000  is less than 3 Megatonnes.",
                       "Extra andean tropical glaciers located between the Democratic Republic of the Congo and Uganda. The Randolph Glacier Inventory includes 11 glacier outlines within ca. 11 squared kilometers. The modelled initial ice mass for year the 2000  is less than 26 Megatonnes.",
                       "Extra andean tropical glaciers located between Kenya and Tanzania. The Randolph Glacier Inventory includes ten glacier outlines within ca. 11 squared kilometers. The modelled initial ice mass for year the 2000  is less than 95 Megatonnes.",
                       "Extra andean tropical glaciers located in two regions of Mexico. The Randolph Glacier Inventory includes six glacier outlines within ca. six squared kilometers. The modelled initial ice mass for year the 2000  is less than 38 Megatonnes.",
                       "Extra andean tropical glaciers located in Northern Colombia. The Randolph Glacier Inventory includes 30 glacier outlines within ca. 31 squared kilometers. The modelled initial ice mass for year the 2000  is the largest outside of the tropical Andes with more than 360 Megatonnes.")

andean_units <- c("Cordillera de Merida", "Cordilleras de Colombia", "Ecuador", "Cordilleras Norte de Peru", "Cordilleras Orientales de Peru y Bolivia", "Volcanos de Peru y Chile")

andean_units_desc <- c("Tropical glaciers of the Cordillera de Merida in the northern tropical Andes. The Randolph Glacier Inventory includes four glacier outlines within less than 3 squared kilometers. The modelled initial ice mass for year the 2000 is the lowest for any unit in the tropical Andes with less than 20 Megatonnes.",
                       "Tropical glaciers of three regions of Colombia belonging to the tropical Andes. The Randolph Glacier Inventory includes 39 glacier outlines within ca. 44 squared kilometers. The modelled initial ice mass for year the 2000 is ca. 2250 Megatonnes.",
                       "Tropical glaciers of three regions of Ecuador belonging to the tropical Andes. The Randolph Glacier Inventory includes almost 60 glacier outlines within ca. 66 squared kilometers. The modelled initial ice mass for year the 2000 is ca. 4300 Megatonnes.",
                       "Tropical glaciers of Northern Peru belonging to the tropical Andes. The Randolph Glacier Inventory includes more than 900 glacier outlines within more than 1300 squared kilometers. The modelled initial ice mass for year the 2000 is ca. 25000 Megatonnes.",
                       "Tropical glaciers of five regions between eastern Peru and Bolivia belonging to the tropical Andes. The Randolph Glacier Inventory includes more than 1000 glacier outlines within more than 1200 squared kilometers. The modelled initial ice mass for year the 2000 is ca. 51000 Megatonnes.", 
                       "Tropical glaciers of six volcanic regions between Peru and Chile in the southern tropical Andes. The Randolph Glacier Inventory includes more than 300 glacier outlines within ca. 870 squared kilometers. The modelled initial ice mass for year the 2000 is ca. 5000 Megatonnes.")


glaz_groups %>% 
  filter(group_name %in% c(extra_andean,andean_units)) %>%
  group_by(group_name) %>%
  summarise(number_of_polygons=n(), RGI=sum(RGI_records,na.rm = TRUE)) %>%
  mutate(description = coalesce(
    andean_units_desc[match(group_name,andean_units)],
    extra_andean_desc[match(group_name,extra_andean)]
  )) %>%
  select(group_name, description, RGI) %>% 
  write_sf(dsn = kml_file )
