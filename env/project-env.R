#!R --vanilla
projectname <- "T6.1-tropical-glaciers-suitability-model"
projectdir <- "proyectos/Tropical-Glaciers"

if (Sys.getenv("GISDATA") != "") {
   gis.data <- Sys.getenv("GISDATA")
   gis.out <- Sys.getenv("GISOUT")
   work.dir <- Sys.getenv("WORKDIR")
   script.dir <- Sys.getenv("SCRIPTDIR")
} else {
   out <- Sys.info()
   username <- out[["user"]]
   hostname <- out[["nodename"]]
   sysname <- out[["sysname"]]
   script.dir <- sprintf("%s/%s/%s",Sys.getenv("HOME"), projectdir, projectname)

   switch(hostname,
      terra={
         gis.data <- sprintf("/opt/gisdata/")
         work.dir <- sprintf("%s/tmp/%s",Sys.getenv("HOME"),projectname)
      },
      roraima={
        gis.data <- sprintf("%s/gisdata/",Sys.getenv("HOME"))
        work.dir <- sprintf("%s/tmp/%s",Sys.getenv("HOME"),projectname)
      },
      roraima.local={
        gis.data <- sprintf("%s/gisdata/",Sys.getenv("HOME"))
        work.dir <- sprintf("%s/tmp/%s",Sys.getenv("HOME"),projectname)
      },
      {
         if (file.exists("/srv/scratch/cesdata")) {
            gis.data <- sprintf("/srv/scratch/cesdata/gisdata/")
            gis.out <- sprintf("/srv/scratch/%s/output/",username)
            work.dir <- sprintf("/srv/scratch/%s/tmp/%s/",username,projectname)
            ## modules script for loading modules in R
            source("/usr/share/Modules/init/r.R")
            module("load", "proj/8.2.1", "sqlite/3.39.4", "perl/5.36.0",
                   "udunits/2.2.28", "geos/3.9.1", "python/3.10.8",
                   "gdal/3.5.3-szip", "netcdf-c/4.9.0")
            
         } else if(sysname == "Darwin" & username == "jferrer") {
           gis.data <- sprintf("%s/gisdata/",Sys.getenv("HOME"))
           work.dir <- sprintf("%s/tmp/%s",Sys.getenv("HOME"),projectname)
         } else {
            stop("Can't figure out where I am, please customize `project-env.R` script\n")
         }
      })
}


if (file.exists("~/.database.ini")) {
   tmp <-     system("grep -A4 psqlaws $HOME/.database.ini",intern=TRUE)[-1]
   get.db <- gsub("[a-z]+=","",tmp)
   names(get.db) <- gsub("([a-z]+)=.*","\\1",tmp)
   tmp <-     system("grep -A4 IUCNdb $HOME/.database.ini",intern=TRUE)[-1]
   rle.db <- gsub("[a-z]+=","",tmp)
   names(rle.db) <- gsub("([a-z]+)=.*","\\1",tmp)
   rm(tmp)
}
# we can put this in .Renviron
#if (file.exists("~/.secrets/osf")) {
#  osf.token <- readLines("~/.secrets/osf")
#}
Sys.setenv("OSF_PROJECT"="hp8bs")
