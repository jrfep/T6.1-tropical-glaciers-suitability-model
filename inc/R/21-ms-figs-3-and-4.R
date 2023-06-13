library(dplyr)
library(ggplot2)
library(units)
library(stringr)
library(ggrepel)
library(purrr)
library(readr)
library(tidyr)
library(forcats)

here::i_am("inc/R/21-ms-figs-3-and-4.R")
source(here::here("inc","R","RS-functions.R"))
source(here::here("inc","R","RS-shared.R"))

target_dir <- "sandbox"
rds_file <- here::here(target_dir,"massbalance-totalmass-all-groups.rds")
totalmass_year_data <- readRDS(rds_file)
#results_file <- here::here(target_dir, "relative-severity-degradation-suitability-all-tropical-glaciers.csv")

#RS_results <- read_csv(results_file, show_col_types = FALSE) %>%
#  mutate(unit_name=str_replace_all(unit," ","-"))

pats <- c("Cordilleras" = "Cord", 
          "Cordillera" = "Cord", 
          "Sierra Nevada" = "SN",
          " de "=" ",
          "Volcanos" = "V",
          "Norte" = "N",
          "Orientales" = "O")
RStotal <- totalmass_year_data %>%
  filter(
    ssp %in% c("SSP2-4.5")
  ) %>%
  group_by(unit_name, model_nr) %>%
  group_modify(~RSts(
    .x$year,
    .x$total_mass,
    vmin=.x$min_mass,
    vmax=.x$max_mass,
    formula = "original"
    )
    ) 
RStotal <- RStotal %>%
 pivot_longer(
  cols = starts_with("RS"),
    names_to = "type",
    values_to = "RS"
 )  %>%
 group_by(unit_name,year) %>%
 summarise(
  RSmin = min(RS),
  RSmax = max(RS),
  RSmean = mean(RS),
  .groups = "keep"
  ) %>%
 mutate(
  unit_name = factor(
    unit_name, unit_order
    #str_replace_all(unit_name,pattern=pats), 
    #str_replace_all(unit_order,pattern=pats)
    ),
  collapsed = RSmin>0.99
  ) 

ggplot(RStotal) +
  geom_ribbon(aes(x = year, ymin = RSmin, ymax = RSmax), alpha=.55, fill = okabe[2]) +
  geom_line(aes(x = year, y = RSmean, colour = collapsed), alpha=.85, linewidth=1.2) +
  facet_wrap(~ unit_name, labeller=labeller(unit_name=label_wrap_gen())) +
  scale_colour_discrete(type=okabe[c(5,6)]) +
  theme(legend.position="none") +
  ylab(expression(bar(RS))) +
  xlab("Year") +
  theme(#panel.spacing.x = unit(4, "mm"),
        axis.text.x = element_text(angle = 47, vjust = 1, hjust = 1))
  #scale_x_continuous(guide = guide_axis(rotate = 45))

ggsave(here::here("sandbox","Figure-3-TS-ice.png"), width = 7, height = 5)


RStotal <- totalmass_year_data %>%
  filter(
    ssp %in% c("SSP2-4.5")
  ) %>%
  group_by(unit_name, model_nr) %>%
  group_modify(~RSts(
    .x$year,
    .x$total_mass,
    vmin=.x$min_mass,
    vmax=.x$max_mass,
    formula = "original"
  )) 
RSyears <- RStotal %>%
  mutate(
    unit_name = factor(unit_name, unit_order),
    non_collapsed=if_else(RS<0.99,year,2000),
    max_non_collapsed=if_else(RS_min<0.99,year,2000),
    min_non_collapsed=if_else(RS_max<0.99,year,2000),
    non_severe=if_else(RS<0.80,year,2000),
    max_non_severe=if_else(RS_min<0.80,year,2000),
    min_non_severe=if_else(RS_max<0.80,year,2000)
  ) %>%
  group_by(unit_name,model_nr) %>%
  summarise(
    med_collapse_year=max(non_collapsed,na.rm=T)+1,
    max_collapse_year=max(max_non_collapsed,na.rm=T)+1,
    min_collapse_year=max(min_non_collapsed,na.rm=T)+1,
    med_severe_year=max(non_severe,na.rm=T)+1,
    max_severe_year=max(max_non_severe,na.rm=T)+1,
    min_severe_year=max(min_non_severe,na.rm=T)+1,
    .groups = "keep")

severity_years <- RSyears %>% pivot_longer(ends_with("year"), values_to = "year",names_to=c("bound","variable"), names_pattern="(.*)_(.*)_year") %>% filter(year<2101)

clrs <- c("severe"=okabe[4],"collapse"=okabe[1])

ggplot(severity_years) +
  geom_histogram(aes(x=year,fill=variable, weight=50/3),binwidth=5) +
  facet_wrap(~ unit_name, labeller=labeller(unit_name=label_wrap_gen())) +
  scale_fill_manual(name="",
                      values=clrs,
                    labels=c(expression(bar(RS)>0.99),
                             expression(bar(RS)>=0.80))) +
  theme(legend.position="top") +
  xlab("Year") + 
  ylab("Nr. of replicates") +
  theme(axis.text.x = element_text(angle = 47, vjust = 1, hjust = 1))

ggsave(here::here("sandbox","Figure-4-year-degradation.png"), width = 7, height = 5)
