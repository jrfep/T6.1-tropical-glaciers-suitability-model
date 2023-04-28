## Utility functions
## relative severity


IUCN_cat_colours <- c("LC"="darkgreen","VU"="yellow","EN"="orange","CR"="red")


RS_extent_combs <- tibble(
  RS_min=c(80,50,30,80,50,80),
  RS_max=c(100,80,50,100,80,100),
  extent_min=c(80,80,80,50,50,30),
  extent_max=c(100,100,100,80,80,50),
  category=c("CR","EN","VU","EN","VU","VU"))

meanRS <- function(IV,FV,CT) {
   pres <- IV>CT
   MD=(CT-IV)[pres]
   #OD=ifelse(FV>IV,0,ifelse(FV<CT,CT-IV,FV-IV))[pres]
   OD=ifelse(FV>IV,0,FV-IV)[pres]
   RS <- ifelse(abs(OD)>abs(MD),MD,OD)/MD
   return(mean(RS))
}

calcCT <- function(pred_values,obs_values) {
  require(ROCR)
  pred <- prediction( pred_values, obs_values)
  Accu.mdl <- performance(pred,  measure="acc", x.measure="cutoff")
  Sens.mdl <- performance(pred,  measure="sens", x.measure="cutoff")
  Spec.mdl <- performance(pred,  measure="spec", x.measure="cutoff")
  PPV.mdl <- performance(pred,  measure="ppv", x.measure="cutoff")
  
  perf <- tibble(cutoff=Accu.mdl@x.values[[1]],
                 accuracy=Accu.mdl@y.values[[1]],
                 sensitivity=Sens.mdl@y.values[[1]],
                 specificity=Spec.mdl@y.values[[1]],
                 ppv=PPV.mdl@y.values[[1]]) %>%
    filter(is.finite(cutoff))
  
  CT <- c(
    "acc"={perf %>% slice(which.max(accuracy)) %>% pull(cutoff)},
    "ppv"={perf %>% slice(which.max(ppv)) %>% pull(cutoff)},
    "ess"={perf %>% slice(which.min(abs(sensitivity-specificity))) %>% pull(cutoff)}
  )
  return(CT)
}

RS_ecdf <- function(RSvals) {
  f <- ecdf((1-RSvals)*100)
  return(f)
}
RSvExt <- function(RSvals) {
  f <- RS_ecdf(RSvals)
  x <- seq(0,100,length=100)
  y <- f(x)
  z <-tibble(RS=100-x,Extent=y*100)
  return(z)
}

RSts <- function(
  years, 
  values, 
  init_year = 2000, 
  collapse_threshold=0,
  vmin,
  vmax, 
  formula=c("original","conditional")
  ) {
  IV <- values[years==init_year]
  FV <- values[years>init_year]
  CT <- collapse_threshold
  OD <- IV -FV
  MD <- IV - CT
  RS <- OD/MD

  if (formula[1] == "conditional") {
    RS <- case_when(
                FV<CT ~ 1,
                FV>IV ~ 0,
                TRUE ~ RS
              )
  } 
    
  res <- tibble(year=years[years>init_year],IV,FV,CT,OD,MD,RS)
  if (!missing(vmin)) {
    IV <- vmin[years==init_year]
    FV <- vmin[years>init_year]
    OD <- IV -FV
    MD <- IV - CT
    RS <- OD/MD
    if (formula[1] == "conditional") {
    RS <- case_when(
                FV<CT ~ 1,
                FV>IV ~ 0,
                TRUE ~ RS
              )
  } 
    res <- res %>% bind_cols(tibble(IV_min=IV,FV_min=FV,OD_min=OD,MD_min=MD,RS_min=RS))
  }
  if (!missing(vmax)) {
    IV <- vmax[years==init_year]
    FV <- vmax[years>init_year]
    OD <- IV -FV
    MD <- IV - CT
    RS <- OD/MD
    if (formula[1] == "conditional") {
    RS <- case_when(
                FV<CT ~ 1,
                FV>IV ~ 0,
                TRUE ~ RS
              )
    } 
    res <- res %>% bind_cols(tibble(IV_max=IV,FV_max=FV,OD_max=OD,MD_max=MD,RS_max=RS))
  }
  return(res)
}