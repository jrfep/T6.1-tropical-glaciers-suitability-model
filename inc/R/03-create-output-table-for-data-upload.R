library(dplyr)
library(ROCR)

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

for (grp in grep("rda$", groups, invert=TRUE, value=TRUE)) {

  (load(sprintf("%s/%s/gbm-model-current.rda",input.dir,grp)))
  
  
  all_results <- tibble()
  for (timeframe in c("2011-2040", "2041-2070", "2071-2100")) {
    for (pathway in c("ssp126")) {
      for (modelname in "mri-esm2-0") {
        future_prediction <- readRDS(
          sprintf("%s/%s/gbm-prediction-%s-%s-%s.rds",
                  input.dir,
                  grp,
                  timeframe,
                  modelname,
                  pathway))
        
        rslts <- testing %>% 
          inner_join(future_prediction, by=c("id", "cellnr", "glacier")) %>% 
          dplyr::select(id, cellnr, glacier, IV, FV) %>% 
          mutate(unit=grp, timeframe, modelname, pathway)
        all_results <- all_results %>% bind_rows(rslts)
        
      }
    }
  }
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

write.csv(RS_results %>% select(unit, id, cellnr, glacier, IV,FV, timeframe, modelname, pathway, threshold, CV, OD, MD, RS, RS_cor, IUCN_cat),
  file=sprintf("%s%s/relative-severity-degradation-suitability-all-tropical-glaciers.csv",
               gis.out,projectname),
  row.names = FALSE)

