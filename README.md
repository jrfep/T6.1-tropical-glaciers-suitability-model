# T6.1-tropical-glaciers - Environmental suitability model

Tropical Glacier Ecosystems are facing extreme pressure due to climate change and face imminent collapse in this century.

We explore here future projections of one direct and one indirect indicator of key ecosystem properties and use these to explore the probable trajectories toward collapse of the ecosystem. We evaluate the usefulness of relative severity and extent of degradation to anticipate collapse.

We discuss here details of the suggested formula for calculation of relative severity $RS$ and different approaches to summarise and visualise data across the extent of the ecosystem assessment unit.

We use the tropical glacier ecosystems as a model because:

- risk of ecosystem collapse is very high and well documented
- future probabilities of collapse can be projected from mechanistic models,
- the different assessment units differ in extent: from the isolated glaciers in Indonesia and Venezuela to the highly connected of the Sierra Blanca in Peru.

We use projected degradation of climatic suitability because:

- it is conceptually linked to models used to calculate probability of collapse
- it uses the same underlying variables models and scenarios
- we can explore different time frames (temporal scale of degradation)
- we can explore uncertainty due to different models, scenarios and collapse thresholds

This repository includes all steps for fitting a environmental suitability model for tropical glacier ecosystems and compare the results with simulation results from a hybrid model of glacier ice mass balance and dynamics.

The repository has the following structure:

## _env_ folder
The workflow was developed using different computers (named *terra*, *humboldt*, *roraima*), but most of the spatial analysis has been done in Katana @ UNSW ResTech:
> Katana. Published online 2010. doi:10.26190/669X-A286

This folder contains scripts for defining the programming environment variables for working in Linux/MacOS.

## _notes_ folder
Notes about the configuration and use of some features and repositories: OSF project management with R, using the quarto book project, running pbs jobs in katana, fitting GLMM with the `glmmTMB` package.

## _inc_ folder
Scripts used for specific tasks: R scripts for functions, tables and figures, quarto documents for publication appendices and PBS scripts for scheduling jobs in the HPC nodes in Katana.

## _docs-src_ folder
This contains the (quarto-) markdown documents explaining the steps of the workflow from the raw data to the end products. 
