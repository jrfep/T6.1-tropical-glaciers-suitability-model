---
author: "José R. Ferrer-Paris"
title: "Environmental suitability model for T6.1 tropical glaciers"
subtitle: "Analysis of future environmental degradation"
editor_options:
  chunk_output_type: console
---

# General description of workflow

## Steps

### Consolidate input data

```sh
source $HOME/proyectos/Tropical-Glaciers/T6.1-tropical-glaciers-suitability-model/env/project-env.sh
cd $WORKDIR
## load modules for gdal functions
#module purge
module load gdal/3.5.3-szip  r/4.2.2

Rscript --vanilla $SCRIPTDIR/inc/R/00-prepare-dataframe.R
```

### Run models for each unit

```sh
source $HOME/proyectos/Tropical-Glaciers/T6.1-tropical-glaciers-suitability-model/env/project-env.sh
cd $WORKDIR
qsub -J 2-16 $SCRIPTDIR/inc/pbs/02-run-gbm-model-per-TG-unit.pbs
```


```sh
tree $GISOUT/$PROJECTNAME
```

### Calculate Relative Severity

### Visualise results

