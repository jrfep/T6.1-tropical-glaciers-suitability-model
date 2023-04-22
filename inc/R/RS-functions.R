## Utility functions
## relative severity


IUCN_cat_colours <- c("LC"="darkgreen","VU"="yellow","EN"="orange","CR"="red")


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
