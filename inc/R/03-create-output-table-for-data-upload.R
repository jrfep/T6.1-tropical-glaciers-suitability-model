library(dplyr)
library(ROCR)
library(stringr)
require(doParallel)

here::i_am("inc/R/03-create-output-table-for-data-upload.R")

source(here::here("env","project-env.R"))
source(here::here("inc","R","RS-functions.R"))

input.dir <- sprintf("%s%s/GBMmodel/",gis.out,projectname)

groups <- dir(sprintf("%s/",input.dir))

cl <- makeCluster(round(detectCores()*.8))
registerDoParallel(cl)

eg <- expand.grid(file_name = grep("rda$", groups, invert=TRUE, value=TRUE),
            eval_set = c("testing", "training"))

all_RS_results <- 
  foreach (
    grp = eg$file_name,
    eval_set = eg$eval_set,
    .packages=c("ROCR", "dplyr", "stringr"),
    .combine=bind_rows,
    .export="calcCT"
  ) %dopar% {

  load(sprintf("%s/%s/gbm-model-current.rda",input.dir,grp))
  
  RS_results <- tibble()
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
    
    all_results <- testing %>%
      inner_join(future_prediction, by=c("id", "cellnr", "glacier")) %>%
      dplyr::select(id, cellnr, glacier, IV, FV) %>%
      mutate(unit=grp, timeframe, modelname, pathway)
    
  if (eval_set %in% "training") {
    CT <- calcCT(training$IV, training$glacier)
  } else {
    CT <- calcCT(testing$IV, testing$glacier)
  }
  

    for (threshold in names(CT)) {
      CV <- unname(CT[threshold])
      RS_results <- 
        RS_results %>% bind_rows(
          all_results %>%
            mutate(
              eval_set=eval_set,
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


# glimpse(all_RS_results)

## Output: save data to csv or rds file ----

## csv file is very big!

training_RS_results <- all_RS_results %>%
  filter(eval_set %in% "training") %>%
  select(unit, id, cellnr, glacier, IV,FV, timeframe, modelname, pathway, threshold, CV, OD, MD, RS, RS_cor, IUCN_cat)

testing_RS_results <- all_RS_results %>%
  filter(eval_set %in% "testing") %>%
  select(unit, id, cellnr, glacier, IV,FV, timeframe, modelname, pathway, threshold, CV, OD, MD, RS, RS_cor, IUCN_cat)

write.csv(testing_RS_results,
          file=sprintf("%s%s/relative-severity-degradation-suitability-all-tropical-glaciers.csv",
                       gis.out,projectname),
          row.names = FALSE)

saveRDS(testing_RS_results,
        file=sprintf("%s%s/relative-severity-degradation-suitability-all-tropical-glaciers.rds",
                     gis.out,projectname))

saveRDS(training_RS_results,
        file=sprintf("%s%s/relative-severity-degradation-suitability-all-tropical-glaciers-training-thresholds.rds",
                     gis.out,projectname))

