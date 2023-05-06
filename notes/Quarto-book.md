
## Quarto 

To render and preview the book

```{sh}
conda deactivate ## make sure to use the global R installation
quarto render docs ## or:
quarto preview docs
```


## Citation and bibliography

Look for - https://github.com/citation-style-language/styles
```sh
cd docs/bibtex
wget https://raw.githubusercontent.com/citation-style-language/styles/master/dependent/ecological-indicators.csl
```


## Populate a sandbox folder with data

All data files shared via OSF cloud storage

To use OSF functions in R, need to install package `osfr` and add a personal access token to the `.Renviron` file in home directory.

See `inc/R/*-upload-files-to-OSF.R` and `inc/R/*-doenload-files-from-OSF.R` files for upload/download instructions.

## Publish...

Instruction for github pages: 

https://quarto.org/docs/publishing/github-pages.html

And follow the instructions for using the `quarto publish` command to publish content rendered locally.

