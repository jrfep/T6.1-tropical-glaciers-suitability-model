
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


RS_extent_combs <- tibble(
  RS_min=c(80,50,30,80,50,80)/100,
  RS_max=c(100,80,50,100,80,100)/100,
  extent_min=c(80,80,80,50,50,30)/100,
  extent_max=c(100,100,100,80,80,50)/100,
  category=c("CR","EN","VU","EN","VU","VU"),
  extent=rep(c("widespread","intermediate","localised"),c(3,2,1)),
  degradation=c("very high","high","moderate")[c(1,2,3,1,2,1)],
  state=c(
    "very wide", "high wide", "mod wide",
    "very inter", "high inter",
    "very local"
  )
  )
