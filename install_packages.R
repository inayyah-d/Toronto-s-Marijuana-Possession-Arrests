# Install the R packages needed to knit toronto_arrests_logistic_regression.Rmd.
# Usage: Rscript install_packages.R

packages <- c(
  # loaded by the analysis
  "dplyr", "ggplot2", "MASS", "tibble", "Epi", "lattice", "DAAG", "knitr", "caret",
  # needed to knit the .Rmd
  "rmarkdown",
  # only used to export the Arrests dataset to data/Arrests.csv
  "carData"
)

missing <- packages[!vapply(packages, requireNamespace, logical(1), quietly = TRUE)]

if (length(missing) > 0) {
  install.packages(missing, repos = "https://cloud.r-project.org")
} else {
  message("All required packages are already installed.")
}
