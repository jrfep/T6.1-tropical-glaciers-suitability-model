## Utility functions
## relative severity

meanRS <- function(IV,FV,CT) {
   pres <- IV>CT
   MD <- (CT-IV)[pres]
   OD <- ifelse(FV>IV, 0, FV-IV)[pres]
   RS <- ifelse(abs(OD)>abs(MD), MD, OD) / MD
   return(mean(RS))
}


RSi <- function(IV,FV,CT) {
  MD <- (CT-IV)
  OD <- ifelse(FV>IV, 0, FV-IV)
  RS <- ifelse(abs(OD)>abs(MD), MD, OD) / MD
  return(RS)
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

## methods(Ecdf)
## getAnywhere(Ecdf.default)
#ED_w <- function(RS,w) {
#  o <- order(RS)
#  ED <- 1-cumsum(w[o])
#  x <- RS[o]
#  res <- tibble(
#    x = c(0,x[-1]),
#    ED = c(1,ED[-length(ED)]))
#  return(res)
#}


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


## Create our own?

cED_w <- function (RS, weights=NULL, x=seq(0, 1, length=100)) 
{
  n <- length(RS)
  if (is.null(weights)) {
    w <- rep(1/n,n)
  } else {
    w <- weights/sum(weights)
  }

  y <- sapply(x, FUN=function(z) sum(w[RS >= z]))
  rval <- approxfun(x, y, 
        method = "constant", yleft = 0, yright = 1, f = 0, ties = "ordered")
  class(rval) <- c("cED","ecdf", "stepfun", class(rval))
  assign("nobs", n, envir = environment(rval))
  attr(rval, "call") <- sys.call()
    rval
}

## this could be a function with one method for raw RS vvalues and another for cED function
AUC_cED <- function(x) {
  res <- integrate(x,0,1)
  return(res)
}

summary_cED_w <- function(RS, ...) {
  f <- cED_w(RS, ...)
  auc <- integrate(f,0,1,rel.tol=.Machine$double.eps^.05)
  res <- tibble(cED_30=f(0.3), cED_50=f(0.5), cED_80=f(0.8), AUC_cED=auc$value)
  return(res)
}