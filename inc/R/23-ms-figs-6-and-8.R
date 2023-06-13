library(dplyr)
library(ggplot2)
library(readr)
library(units)
library(ggforce)
#library(purrr)
#library(ggpubr)
#library(tidyr)
library(stringr)
here::i_am("inc/R/23-ms-figs-6-and-8.R")
# sessionInfo()
# Suppress summarise info
options(dplyr.summarise.inform = FALSE)
source(here::here("inc","R","RS-functions.R"))
source(here::here("inc","R","RS-shared.R"))

target_dir <- "sandbox"
rds_file <- here::here(target_dir,"totalmass-suitability-glmm-data.rds")
model_data <- readRDS(rds_file)


pats <- c("Cordilleras" = "Cord", 
          "Cordillera" = "Cord", 
          "Sierra Nevada" = "SN",
          " de "=" ",
          "Volcanos" = "V",
          "Norte" = "N",
          "Orientales" = "O")
valid_methods <- c("ice","ess","acc")
model_data <- model_data %>%
  filter(method %in% valid_methods) %>%
  mutate(
    method=droplevels(method)
  )

clrs <- c(acc=okabe[1],ess=okabe[3],ice=okabe[5])

model_data <- model_data %>%
  mutate(unit = factor(
    str_replace_all(unit,pattern=pats), 
    rev(str_replace_all(unit_order,pattern=pats))
  ),
  method=factor(method,names(clrs)),
  time=factor(time,labels=c("2011-2040","2041-2070","2071-2100")),
  andes=factor(grepl("Merida|Colombia|Peru|Ecuador",unit),
               labels=c("extra Andean","Andean")))


ggplot(model_data) +
  geom_boxplot(
    aes(x=RS, y=unit, colour=method, group=interaction(unit,method))
  ) +
  scale_colour_manual(values=clrs, name="Method") +
  facet_grid(andes ~ time, scales = "free", space = "free") +
  ylab("") +
  xlab(expression(paste("Relative severity [", bar(RS), "]"))) +
  theme(legend.position="top",
        axis.text.x = element_text(angle = 47, vjust = 1, hjust = 1))

ggsave(here::here("sandbox","Figure-8-compare-RS-methods.png"), width = 7, height = 5)
