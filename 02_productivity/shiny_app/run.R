# -----------------------------------------------------------------------------
# Run FDAi - AI-Powered FDA Device Recalls Dashboard
# Simple launcher script - checks dependencies and runs the app
# -----------------------------------------------------------------------------

# Add user library to path (for packages installed in user directory)
.libPaths(c("~/Library/R/arm64/4.4/library", .libPaths()))

# Check and install required packages
required_packages <- c("shiny", "bslib", "httr", "jsonlite", "DT", "plotly", "dplyr", "markdown")

missing_packages <- required_packages[!sapply(required_packages, requireNamespace, quietly = TRUE)]

if (length(missing_packages) > 0) {
  message("Installing missing packages: ", paste(missing_packages, collapse = ", "))
  install.packages(missing_packages, repos = "https://cloud.r-project.org")
}

# Get the directory where this script is located
# Works when sourced via source() from any working directory
this_file <- function() {
  # Look through call stack to find the sourced file path
  for (i in sys.nframe():1) {
    if (!is.null(sys.frame(i)$ofile)) {
      return(normalizePath(sys.frame(i)$ofile))
    }
  }
  # Fallback: assume current directory
  return(NULL)
}

script_path <- this_file()
app_dir <- if (!is.null(script_path)) dirname(script_path) else getwd()

# Run the app from the correct directory
shiny::runApp(app_dir)
