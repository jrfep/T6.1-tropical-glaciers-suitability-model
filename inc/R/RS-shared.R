
## from far to near, Andes from north to south
unit_order <- c(
  "Puncak Jaya",
  "Kilimanjaro",
  "Mount Kenia",
  "Ruwenzori",
  "Mexico",
  "Sierra Nevada de Santa Marta",
  "Cordillera de Merida",
  "Cordilleras de Colombia",
  "Ecuador",
  "Cordilleras Norte de Peru",
  "Cordilleras Orientales de Peru y Bolivia",
  "Volcanos de Peru y Chile"
)

okabe <- c("#E69F00", "#56B4E9", "#009E73", "#F0E442", "#0072B2", "#D55E00", "#CC79A7")
IUCN_cat_colours <- c("LC"="darkgreen", "VU"="yellow", "EN"="orange", "CR"="red", "CO"="black")
IUCN_cat_okabe <- c("LC"=okabe[3], "VU"=okabe[4], "EN"=okabe[1], "CR"=okabe[6], "CO"=okabe[7])

state_cat_okabe <- c(
  "low"=okabe[5], 
  "mod wide"=okabe[2], 
  "high inter"=okabe[3],
  "very local"=okabe[4], 
  "high wide"=okabe[1],
  "very inter"=okabe[6],
  "very wide"=okabe[7], 
  "collapsed"="black")

state_order <- names(state_cat_okabe)

#| ggplot theme
old <- theme_set(theme_linedraw())
theme_update(panel.grid.minor = element_line(colour = "pink"),
panel.grid.major = element_line(colour = "rosybrown3"))