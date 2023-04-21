# T6.1-tropical-glaciers - Data for a global IUCN RLE assessment (Level 4/5 units)

This repository includes all steps for data import and preparation for an ongoing IUCN Red List of Ecosystem Assessment of global ecoregional types for the ecosystem functional group _T6.1 Ice sheets, glaciers and perennial snowfields_ in the tropical regions.

The repository has the following structure:

## _env_ folder
The workflow was developed using different computers (named *terra*, *humboldt*, *roraima*), but most of the spatial analysis has been done in Katana @ UNSW ResTech:
> Katana. Published online 2010. doi:10.26190/669X-A286

This folder contains scripts for defining the programming environment variables for working in Linux/MacOS.

## _notes_ folder
Notes about the configuration and use of some features and repositories.

## _inc_ folder
Scripts used for specific tasks. Mostly R and (bash) shell scrips, includes the PBS scripts for scheduling jobs in the HPC nodes.

## _docs_ folder
This contains the markdown documents explaining the steps of the workflow from the raw data to the end products. 
