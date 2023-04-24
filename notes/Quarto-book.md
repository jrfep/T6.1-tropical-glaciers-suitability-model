
## Quarto 

To render and preview the book

```{sh}
conda deactivate ## make sure to use the global R installation
quarto preview docs

```


## Citation and bibliography

Look for - https://github.com/citation-style-language/styles
```sh
cd docs/bibtex
wget https://github.com/citation-style-language/styles/blob/master/dependent/ecological-indicators.csl
```


# Populate a sandbox folder with data

All data files shared via OSF cloud storage

To use OSF functions in R, need to install package `osfr` and add a personal access token to the `.Renviron` file in home directory.

See `inc/R/05-upload-files-to-OSF.R` file for upload/download instructions.
