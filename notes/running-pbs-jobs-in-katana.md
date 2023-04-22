# Workflow on Katana @ UNSW

Please check [Katana User’s documentation](https://unsw-restech.github.io/index.html).

Here some useful tips:

## Log-in / authentication

To apply for an account in Katana you can send an email to the [UNSW IT Service Centre](mailto:ITServiceCentre@unsw.edu.au) giving your zID, your role within UNSW and the name of your supervisor or head of your research group.

In Linux and MacOSX I set up my bash terminal to recognize my zID (as env variable `$zID`) and set up [SSH Public key authentication](https://www.ssh.com/ssh/public-key-authentication).

## Copying files

From Linux/MacOSX I use `ssh` and `scp` to copy some datasources using the *katana data mover* (kdm) node:

```sh
export OUTPUTDIR=...
ssh $zID@kdm.restech.unsw.edu.au mkdir -p /srv/scratch/cesdata/$OUTPUTDIR

scp -r $WORKDIR/... $zID@kdm.restech.unsw.edu.au:/srv/scratch/cesdata/$OUTPUTDIR
```

## Version control with `git`

Log into the katana node with `ssh` and use `git` to clone and update repositories:

```sh
ssh $zID@katana.restech.unsw.edu.au
## SSH Public key authentication for github
eval $(ssh-agent)
ssh-add

git clone ...

## load bash environment variables
source $HOME/proyectos/.../env/project.env
cd $SCRIPTDIR
git status
```

## Running interactive jobs with `pbs`

It is always useful to run interactive `pbs` jobs:

```sh
ssh $zID@katana.restech.unsw.edu.au
source $HOME/proyectos/.../env/project.env
cd $WORKDIR

qsub -I -l select=1:ncpus=1:mem=120gb,walltime=12:00:00
#" if we need a graphical session "
##qsub -I -X -l select=1:ncpus=1:mem=32gb,walltime=4:00:00

```


Some recomendations from Duncan:

* Use skylake-avx512 by making your interactive job request become something like: `qsub -I -l select=1:ncpus=1:cpuflags=skylake-avx512:mem=120gb -l walltime=12:00:00`. This will take a little longer to start but will mean running on newer hardware.
* Walltime should be 12:00:00 unless you need more. i.e. nothing shorter.
* When requesting memory you the point at which you have less options is 124gb, 180gb, 248gb, 370gb, 750gb and 1000gb. i.e. requesting 126gb is not a great idea.

These are the cpuflags:
```sh
cputype       : "sandybridge", "ivybridge", "broadwell", "haswell", "skylake-avx512"
cpuflags      : "avx", "avx2", "avx512bw", "avx512cd", "avx512dq", "avx512f", "avx512vl", "avx512vnni", "avx512_vnni"
```

## Running batch jobs with `pbs`

Now run the batch scripts for Growing degree days (GDD) based on NARCLiM data for all models and scenarios:

```sh
ssh $zID@katana.restech.unsw.edu.au
source $HOME/proyectos/.../env/project-env.sh
source $HOME/proyectos/.../env/katana-env.sh

cd $WORKDIR

qsub -l select=1:ncpus=1:mem=32gb,walltime=4:00:00 -J 1-2 $SCRIPTDIR/bin/pbs/....pbs

qsub -l select=1:ncpus=2:mem=16gb,walltime=4:00:00 -J 3-4 $SCRIPTDIR/bin/pbs/....pbs

qsub -J 5-36 $SCRIPTDIR/bin/pbs/....pbs
qstat -tu $(whoami)
# or 
qstat -tu $USER

```

Check what resources (I/O, CPU, memory and scratch) a job is currently using?
> `qstat -f <jobid>`

For this repository, I would do something like:

```{bash}
source $HOME/proyectos/Tropical-Glaciers/T6.1-tropical-glaciers-suitability-model/env/project-env.sh
cd $WORKDIR
qsub -J 10-28 $SCRIPTDIR/inc/pbs/crop-variables-per-TG-unit.pbs
qsub -J 29-37 $SCRIPTDIR/inc/pbs/crop-variables-per-TG-unit.pbs
```


```{bash}
source $HOME/proyectos/Tropical-Glaciers/T6.1-tropical-glaciers-suitability-model/env/project-env.sh
cd $WORKDIR
qsub -J 1-3 $SCRIPTDIR/inc/pbs/run-gbm-model-per-TG-unit.pbs
qsub -J 4-19 $SCRIPTDIR/inc/pbs/run-gbm-model-per-TG-unit.pbs

qstat -tu $USER
```


## Katana On Demand

### Install required R packages 

We had some issues when trying to use some packages in R (in batch jobs in Katana) and Rstudio (in Katana On Demand).

Basically, what I did in a normal katana session was to first load the modules:


```sh
module load r proj/8.2.1 sqlite/3.39.4 perl/5.36.0 udunits/2.2.28 \
geos/3.9.1 python/3.10.8 gdal/3.5.3-szip netcdf-c/4.9.0
```
Then start an R session and install packages:

```R
#install.packages(c('sf','ncdf4'))
#install.packages("rnaturalearthhires", repos = "http://packages.ropensci.org", type = "source")
```
But these do not work with RStudio!

For RStudio, I needed to call the module functions within R, which requires some additional steps.

Before the Katana update in Feb. 2023 I used to do:

```{r}
# source('/apps/modules/module/4.6.0/init/r.R')
#module('load', 'udunits/2.2.26', 'python/3.9.9', 'perl/5.28.0',
#'gdal/3.4.1',
#      'proj4/5.1.0', 'spatialite/5.0.1', 'geos/3.10.2', 'sqlite/3.31.1')
```

But the module names changed in Feb. 2023. Now I would run

```{r}
source("/usr/share/Modules/init/r.R")
module("load", "proj/8.2.1", "sqlite/3.39.4", "perl/5.36.0",
	       "udunits/2.2.28", "geos/3.9.1", "python/3.10.8",
	       "gdal/3.5.3-szip", "netcdf-c/4.9.0")
```

Then we also need some extra steps at the moment of the installation, here one example with one library:

```{r}
library(withr)
with_makevars(
  list(LDFLAGS=paste('-Wl,-rpath=', Sys.getenv("UDUNITS_ROOT"), '/lib ',sep=''), 
    MAKEFLAGS='-j'),
  (function() {
  install.packages('units')
  })()
)
```

And more general when there are many libraries involved:

```{r}
names(s <- Sys.getenv()) 

moduleLibs <- sprintf("-rpath=%s/lib",s[grep("ROOT",names(s))])
moduleLibs <- c(moduleLibs,sprintf("-rpath=%s/lib64",s[grep("GDAL_ROOT",names(s))]))

with_makevars(
  list(LDFLAGS=paste('-Wl,', paste(moduleLibs, collapse=","),sep=''), 
    MAKEFLAGS='-j'),
  (function() {
  install.packages(c('sf','ncdf4'))
  })()
)

with_makevars(
  list(LDFLAGS=paste('-Wl,', paste(moduleLibs, collapse=","),sep=''), 
    MAKEFLAGS='-j'),
  (function() {
  install.packages(c('raster','dismo'))
  })()
)
```

Other libraries might or might not work:

```{r}
install.packages(c('mapview'))
# install.packages("rnaturalearthhires", repos = "http://packages.ropensci.org", type = "source")
```



