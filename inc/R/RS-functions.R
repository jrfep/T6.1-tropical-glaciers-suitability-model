## Utility functions
## relative severity
meanRS <- function(IV,FV,CT) {
   pres <- IV>CT
   MD=(CT-IV)[pres]
   #OD=ifelse(FV>IV,0,ifelse(FV<CT,CT-IV,FV-IV))[pres]
   OD=ifelse(FV>IV,0,FV-IV)[pres]
   RS <- ifelse(abs(OD)>abs(MD),MD,OD)/MD
   return(mean(RS))
}