#' @name helpers.R
#' @title FDA Device Recall API Helper Functions
#' @description
#' Topic: API Query Helpers
#'
#' Contains reusable functions for querying the FDA Device Recall endpoint
#' and transforming the results into a tidy data frame. Used by app.R.

# 0. SETUP ###################################

library(httr)       # for HTTP requests (GET, status_code, etc.)
library(jsonlite)   # for parsing JSON responses
library(dplyr)      # for data wrangling with pipelines
library(lubridate)  # for month arithmetic (%m+%)

# 1. CONSTANTS ###################################

# FDA Open Data endpoint for device recalls
FDA_RECALL_URL = "https://api.fda.gov/device/recall.json"

# Your FDA API key (from https://open.fda.gov/apis/authentication/)
FDA_API_KEY = "nKrzrh8skxScAG9VdGwXImssp7LI9ONsusO6lQef"

# 2. HELPER FUNCTIONS ###################################

## 2.1 fetch_fda_recalls #################################

# Query the FDA Device Recall API for a given date range (month + year).
# Returns a named list: success (logical), data (data frame or NULL), message (string).
# This mirrors the logic from my_good_query.R but is wrapped for reuse.
fetch_fda_recalls = function(year_start, month_start, year_end, month_end, limit = 100) {

  # Figure out the last day of the end month
  # We go to the 1st of the NEXT month and subtract 1 day
  last_day = as.integer(format(
    as.Date(sprintf("%d-%02d-01", year_end, month_end)) %m+% months(1) - 1,
    "%d"
  ))

  # Build the search string with full YYYY-MM-DD dates
  search_str = sprintf(
    "event_date_initiated:[%d-%02d-01 TO %d-%02d-%02d]",
    year_start, month_start,
    year_end, month_end, last_day
  )

  # Assemble query parameters — same structure as my_good_query.R
  query_params = list(
    api_key = FDA_API_KEY,
    search  = search_str,
    limit   = as.integer(limit)
  )

  # Make the GET request with a 30-second timeout
  response = tryCatch(
    GET(FDA_RECALL_URL, query = query_params, timeout(30)),
    error = function(e) {
      return(list(
        success = FALSE, data = NULL,
        message = paste0("Network error: ", conditionMessage(e))
      ))
    }
  )

  # If tryCatch already returned our error list, pass it through
  if (is.list(response) && !is.null(response$success)) return(response)

  # Check HTTP status
  status = status_code(response)
  if (status != 200) {
    body = rawToChar(response$content)
    return(list(
      success = FALSE, data = NULL,
      message = paste0("FDA API returned status ", status, ": ", substr(body, 1, 300))
    ))
  }

  # Parse the JSON response
  raw_text = rawToChar(response$content)
  parsed = tryCatch(
    fromJSON(raw_text, flatten = TRUE),
    error = function(e) {
      return(list(
        success = FALSE, data = NULL,
        message = paste0("JSON parse error: ", conditionMessage(e))
      ))
    }
  )

  # If parse failed, pass the error list through

  if (is.list(parsed) && !is.null(parsed$success)) return(parsed)

  # Extract the results data frame

  recalls = parsed$results

  if (is.null(recalls) || (is.data.frame(recalls) && nrow(recalls) == 0)) {
    return(list(
      success = TRUE, data = NULL,
      message = "No recalls found for this date range."
    ))
  }

  # Return success with the data
  list(
    success = TRUE,
    data    = as.data.frame(recalls),
    message = paste0("Retrieved ", nrow(recalls), " recall(s).")
  )
}

## 2.2 clean_recalls #################################

# Select and rename key columns from the raw recalls data frame.
# Makes the table easier to read in the UI.
clean_recalls = function(df) {
  # Columns we want (matching my_good_query.R output)
  cols_wanted = c(
    "recall_number",
    "event_date_initiated",
    "product_code",
    "root_cause_description",
    "recalling_firm",
    "product_description",
    "k_numbers"
  )

  # Keep only columns that actually exist in the data
  existing = intersect(names(df), cols_wanted)

  # If none of our preferred columns exist, fall back to first 5 columns
  if (length(existing) == 0) existing = names(df)[seq_len(min(5, ncol(df)))]

  df %>%
    select(all_of(existing))
}
