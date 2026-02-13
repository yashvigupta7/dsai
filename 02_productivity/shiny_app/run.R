#' @name run.R
#' @title Launch the FDA Device Recall Explorer
#' @description
#' Quick launcher for the Shiny app. Run this from RStudio or the R console.
#' Make sure your working directory is set to the shiny_app/ folder first.

# Install any missing packages before launching
required_pkgs = c("shiny", "bslib", "httr", "jsonlite", "DT", "dplyr", "lubridate")
missing = required_pkgs[!sapply(required_pkgs, requireNamespace, quietly = TRUE)]
if (length(missing) > 0) {
  message("Installing missing packages: ", paste(missing, collapse = ", "))
  install.packages(missing, repos = "https://cloud.r-project.org")
}

# Resolve the app directory (folder where this script lives)
app_dir = "/Users/yashvi711/Desktop/Cornell/Classes/Spring 2026/SYSEN 5381/dsai/02_productivity/shiny_app"

# Launch the app — opens in your default browser
shiny::runApp(appDir = app_dir, launch.browser = TRUE)
