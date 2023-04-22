# Estimated and predicted bioclimatic suitability for Tropical Glacier Ecosystems using a Gradient Boosting Machine model
---

We used a Gradient Boosting Machine (GBM) model to analyse the current climatic conditions in areas occupied by Tropical Glacier Ecosystems in all the tropics. Here we assume that the recent and current distribution of tropical glaciers represent suitable conditions for the tropical glacier ecosystem and that climate change will reduce the suitability in areas currently occupied. Occurrence records were selected using stratified random sampling from all the glacier outlines in tropical areas and 25 km distance buffers around glacier outlines. We applied a first partition of the data by withholding the occurrence records of the target assessment unit for the final model evaluation of the prediction performance of the model (target partition) and the rest of the occurrence records were used for model fitting (modeling partition). Random subsets of the modeling partition were divided into calibration (80%) and test partitions (20%) for tuning of model parameters (number of trees, interaction depth, shrinkage, and minimum number of observations per node) using cross-validation. We used 19 bioclimatic variables from the CHELSA dataset representing climatological mean values for present conditions (1981-2010) as predictor variables. Eight variables were excluded from the model due to high correlation to other variables. Variables were centered and scaled to zero mean and unit variance. We fitted the GBM model for classification (two classes: glacier or not-glacier) using a bernoulli error distribution, and evaluated the predictive performance of the final model on the target partition.


## Description of the data and file structure


The data is presented in tabular form using a comma separated value (csv) format.

The data has 16 columns and 42,984 rows.

| column | name | type | description |
|---|---|---|---|
| 1 | unit | character | name of glacier unit (one or more clusters) |
| 2 | id | integer | ID of spatial glacier cluster |
| 3 | cellnr | integer | cell number within glacier cluster |
| 4 | glacier | binomial | "G"lacier or "N"on-glacier | 
| 5 | IV | numeric | initial value (1980-2010) of suitability (0-1) |
| 6 | FV | numeric | final value of suitability (0-1) |
| 7 | timeframe | character | time frame of final value |
| 8 | modelname | character | name of global circulation model used for prediction of final value |
| 9 | pathway | character | shared socioeconomic pathway used for prediction of final value |
| 10 | threshold | character | rule for collapse threshold selection |
| 11 | CV | numeric | collapse threshold or collapse value  |
| 12 | OD | numeric | Observed decline (IV-FV) |
| 13 | MD | numeric | Maximum decline (IV-CV) |
| 14 | RS | numeric | Relative severity, original formula (-Inf,Inf) |
| 15 | RS_cor | numeric | Relative severity, corrected/bounded formula (0-1) |
| 16 | IUCN_cat | character | corresponding IUCN category of threat |

Glacier units and spatial cluster (columns 1, 2) were defined based on glacier outlines from different global and national glacier inventories.

Cell number (column 3) refers to the cells of the raster grids (CHELSA dataset) used as input explanatory variables in the model. The binomial _glacier_ variable (column 4) identifies cell intersecting the glacier outlines as "G" and those not intersecting the outlines as "N", this was the response variable used in the GBM model. [Note: all observation in this dataset are classified as "G", because the relative severity value is only meningful for these cells].

Initial and final values (columns 5 and 6) refer to the output probabilities of the GBM model, interpreted here as bioclimatic suitability. Initial values were calculated from the CHELSA bioclimatic variables for the reference timeframe of 1980 to 2010. Final values were calculated for different timeframes, global circulation models and shared socioeconomic pathways (columns 7-9).

We used three different methods to estimate the collapse threshold (columns 10 and 11) based on the confusion matrix built using `IV` as predicted value and `glacier` as observed value (from the larger testing dataset including "G" and "N" values).

We used the formula from the IUCN Red List of Ecosystems Guidelines (Bland et al. 2017) to calculate observed and maximum decline and relative severity (columns 12-14): $\mathrm{RS} = \mathrm{OD}/\mathrm{MD}$, where $\mathrm{OD} = \mathrm{IV}-\mathrm{FV}$ and $\mathrm{MD} = \mathrm{IV}-\mathrm{CV}$. We used a bounded formula to get corrected value of Relative severity (column 15). We categorise RS values into five categories of threat (column 16): 

- LC: Least Concern ($RS < 0.3$)
- VU: Vulnerable ($0.3 < RS < 0.5$)
- EN: Endangered ($0.5 < RS < 0.8$)
- CR: Critically Endangered ($0.8 < RS < 0.99$)
- CO: Collapsed ($RS > 0.99$)

    Bland, L. M., Keith, D. A., Miller, R. M., Murray, N. J., & Ródriguez, J. P. (Eds.). (2017). Guidelines for the application of IUCN red list of ecosystems categories and criteria. Version 1.1. IUCN International Union for Conservation of Nature.

## Sharing/Access information

Links to other publicly accessible locations of the data:

  * OSF project component: https://osf.io/hp8bs/
  * OSF project: https://osf.io/792qb/
  * GitHub repository: https://github.com/jrfep/T6.1-tropical-glaciers-suitability-model/


Data was derived from the following sources:

  * CHELSA

    Karger, D.N., Conrad, O., Böhner, J., Kawohl, T., Kreft, H., Soria-Auza, R.W., Zimmermann, N.E., Linder, H.P. & Kessler, M. (2017) Climatologies at high resolution for the earth’s land surface areas. Scientific Data 4, 170122.
  * Glacier polygons from
    * Global sources:

        GLIMS and NSIDC (2005, updated 2018): Global Land Ice Measurements from Space glacier database. Compiled and made available by the international GLIMS community and the National Snow and Ice Data Center, Boulder CO, U.S.A. DOI:10.7265/N5V98602

        RGI Consortium (2017). Randolph Glacier Inventory – A Dataset of Global Glacier Outlines: Version 6.0: Technical Report, Global Land Ice Measurements from Space, Colorado, USA. Digital Media. DOI: https://doi.org/10.7265/N5-RGI-60

        WGMS, and National Snow and Ice Data Center (comps.). 1999, updated 2012. World Glacier Inventory, Version 1. [Indicate subset used]. Boulder, Colorado USA. NSIDC: National Snow and Ice Data Center. doi: https://doi.org/10.7265/N5/NSIDC-WGI-2012-02. [Date Accessed].

    * National sources:

        Dirección General de Aguas (DGA), 2022. METODOLOGÍA DEL INVENTARIO PÚBLICO DE GLACIARES, SDT N°447, 2022. Ministerio de Obras Públicas, Dirección General de Aguas Unidad de Glaciología y Nieves. Realizado por: Casassa, G., Espinoza, A., Segovia, A., Huenante, J.

        Zalazar, L., Ferri, L., Castro, M., Gargantini, H., Gimenez, M., Pitte, P., . . . Villalba, R. (2020). Spatial distribution and characteristics of Andean ice masses in Argentina: Results from the first National Glacier Inventory. Journal of Glaciology, 66(260), 938-949. doi:10.1017/jog.2020.55
> 

## Code/Software

The dataset was prepared using gdal and ogr tools (GDAL 3.5.3, released 2022/10/21), R and RStudio: 

    R version 4.2.2 (2022-10-31)
    Platform: x86_64-pc-linux-gnu (64-bit)
    Running under: Rocky Linux 8.7 (Green Obsidian)

With R packages: `ROCR_1.0-11`, `caret_6.0-94`, `sf_1.0-12`, and `raster_3.6-20`.

Code for all steps of data preparation are available https://github.com/jrfep/T6.1-tropical-glaciers-suitability-model/

The code was run in Katana High Performance Computer at UNSW Restech:

> Katana. Published online 2010. doi:10.26190/669X-A286

