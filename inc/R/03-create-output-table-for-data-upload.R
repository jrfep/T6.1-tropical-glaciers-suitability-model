library(dplyr)
library(ROCR)
library(stringr)
require(doParallel)

env_file_path <- "proyectos/Tropical-Glaciers/T6.1-tropical-glaciers-suitability-model/"
source(
  sprintf(
    "%s/%s/env/project-env.R",
    Sys.getenv("HOME"),
    env_file_path
  )
)

source(
  sprintf(
    "%s/%s/inc/R/RS-functions.R",
    Sys.getenv("HOME"),
    env_file_path
  )
)

input.dir <- sprintf("%s%s/OUTPUT/",gis.out,projectname)

RS_results <- tibble()
groups <- dir(sprintf("%s/",input.dir))


cl <- makeCluster(round(detectCores()*.8))
registerDoParallel(cl)

all_RS_results <- 
  foreach (
    grp = grep("rda$", groups, invert=TRUE, value=TRUE),
    .packages=c("ROCR", "dplyr", "stringr"),
    .combine=bind_rows
  ) %dopar% {

  load(sprintf("%s/%s/gbm-model-current.rda",input.dir,grp))
  all_results <- tibble()
  for (arch in list.files(sprintf("%s/%s",input.dir,grp),pattern="rds")) {
    comps <- str_replace(arch,"gbm-prediction-","") %>% str_replace(".rds","") %>% str_split_1("-")
    timeframe <- str_c(comps[1:2],collapse="-")
    pathway <- comps[length(comps)]
    modelname <- str_c(comps[3:(length(comps)-1)],collapse="-")
    future_prediction <- readRDS(
      sprintf("%s/%s/%s",
              input.dir,
              grp,
              arch))
    
    rslts <- testing %>% 
      inner_join(future_prediction, by=c("id", "cellnr", "glacier")) %>% 
      dplyr::select(id, cellnr, glacier, IV, FV) %>% 
      mutate(unit=grp, timeframe, modelname, pathway)
    all_results <- all_results %>% bind_rows(rslts)
    
  
  CT <- calcCT(testing$IV, testing$glacier)
  

    for (threshold in names(CT)) {
      CV <- unname(CT[threshold])
      RS_results <- 
        RS_results %>% bind_rows(
          all_results %>% 
            mutate(
              threshold=threshold,
              CV=CV,
              OD=IV-FV,
              MD=IV-CV,
              RS=OD/MD,
              RS_cor = case_when(
                FV<CV ~ 1,
                FV>IV ~ 0,
                TRUE ~ RS
              ),
              IUCN_cat = case_when(
                RS_cor < 0.3 ~ "LC",
                RS_cor > 0.999 ~ "CO",
                RS_cor < 0.5 ~ "VU",
                RS_cor < 0.8 ~ "EN",
                TRUE ~ "CR"
              )
            )
        )
    }
  }
  return(RS_results)
}

## Stop cluster: garbage collection ----

stopCluster(cl)
gc()


glimpse(all_RS_results)

## Output: save data to csv or rds file ----

## csv file is too big!
##write.csv(all_RS_results %>% select(unit, id, cellnr, glacier, IV,FV, timeframe, modelname, pathway, threshold, CV, OD, MD, RS, RS_cor, IUCN_cat),
##          file=sprintf("%s%s/relative-severity-degradation-suitability-all-tropical-glaciers.csv",
##                       gis.out,projectname),
##          row.names = FALSE)

saveRDS(all_RS_results %>% select(unit, id, cellnr, glacier, IV,FV, timeframe, modelname, pathway, threshold, CV, OD, MD, RS, RS_cor, IUCN_cat),
          file=sprintf("%s%s/relative-severity-degradation-suitability-all-tropical-glaciers.rds",
                       gis.out,projectname),
          row.names = FALSE)

