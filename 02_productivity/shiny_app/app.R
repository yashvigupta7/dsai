#' @name app.R
#' @title FDA Device Recall Explorer — Shiny App
#' @description
#' Topic: Shiny + API Integration
#'
#' A Shiny dashboard that queries the FDA Device Recall API and displays
#' results in an interactive table. Users pick a year range and record limit,
#' then click "Query" to fetch data. Built with bslib for a modern UI.

# 0. SETUP ###################################

## 0.1 Load Packages #################################

library(shiny)      # web app framework
library(bslib)      # modern Bootstrap themes and layouts
library(DT)         # interactive data tables
library(dplyr)      # data wrangling with pipelines

## 0.2 Load Helpers ##################################

# Source our API helper functions (fetch_fda_recalls, clean_recalls)
source("helpers.R")

# 1. UI ###################################

# We use page_sidebar() from bslib for a clean dashboard layout.
# The sidebar holds query controls; the main area shows status + results.

ui = page_sidebar(
  title = "FDA Device Recall Explorer",
  theme = bs_theme(
    bootswatch = "flatly",        # clean, modern theme
    primary    = "#2c3e50",       # dark blue-grey accent
    "navbar-bg" = "#2c3e50"
  ),

  # ---- Sidebar: query controls ----
  sidebar = sidebar(
    title = "Query Parameters",
    width = 320,

    # Brief instructions for the user
    p("Select a start and end month/year, then click",
      strong("Query FDA Recalls"), "to fetch data.",
      class = "text-muted"),

    hr(),

    # Month names for the dropdown
    # Start date controls
    tags$label("Start date", class = "form-label fw-bold"),
    layout_columns(
      col_widths = c(7, 5),
      selectInput(
        inputId  = "month_start",
        label    = NULL,
        choices  = setNames(1:12, month.name),
        selected = 1
      ),
      numericInput(
        inputId = "year_start",
        label   = NULL,
        value   = 2024,
        min     = 2000,
        max     = 2030,
        step    = 1
      )
    ),

    # End date controls
    tags$label("End date", class = "form-label fw-bold"),
    layout_columns(
      col_widths = c(7, 5),
      selectInput(
        inputId  = "month_end",
        label    = NULL,
        choices  = setNames(1:12, month.name),
        selected = 12
      ),
      numericInput(
        inputId = "year_end",
        label   = NULL,
        value   = 2024,
        min     = 2000,
        max     = 2030,
        step    = 1
      )
    ),

    # Max records selector (FDA allows up to 1000)
    selectInput(
      inputId  = "limit",
      label    = "Max records",
      choices  = c(10, 25, 50, 100, 500, 1000),
      selected = 100
    ),

    hr(),

    # Action button to fire the query
    actionButton(
      inputId = "query_btn",
      label   = "Query FDA Recalls",
      class   = "btn-primary btn-lg w-100",
      icon    = icon("magnifying-glass")
    ),

    hr(),

    # Link to FDA docs
    tags$small(
      class = "text-muted",
      "Data from ",
      tags$a(
        href = "https://open.fda.gov/apis/device/recall/",
        target = "_blank",
        "FDA Open Data"
      ),
      "."
    )
  ),

  # ---- Main panel ----

  # Status card — shows success / error messages
  card(
    card_header(
      class = "bg-light",
      "Status"
    ),
    uiOutput("status_ui")
  ),

  # Results card — interactive data table
  card(
    card_header(
      class = "bg-light",
      "Results"
    ),
    full_screen = TRUE,
    card_body(
      p("Click ", strong("Query FDA Recalls"),
        " in the sidebar to load data. Use the search box and column",
        " filters to explore results.",
        class = "text-muted mb-3"),
      DT::dataTableOutput("recall_table")
    )
  )
)

# 2. SERVER ###################################

server = function(input, output, session) {

  # Reactive value to store the latest query result
  query_result = reactiveVal(NULL)

  ## 2.1 Handle query button click #################################

  observeEvent(input$query_btn, {

    # Show a "loading" message immediately
    output$status_ui = renderUI({
      div(
        class = "d-flex align-items-center gap-2 p-2",
        div(class = "spinner-border spinner-border-sm text-primary"),
        span("Querying FDA API...")
      )
    })

    # Validate inputs
    yr_start = as.integer(input$year_start)
    mo_start = as.integer(input$month_start)
    yr_end   = as.integer(input$year_end)
    mo_end   = as.integer(input$month_end)

    if (is.na(yr_start) || is.na(yr_end) || is.na(mo_start) || is.na(mo_end)) {
      output$status_ui = renderUI({
        div(class = "alert alert-danger m-2", "Please enter valid start and end dates.")
      })
      query_result(NULL)
      return()
    }

    # Build Date objects so we can compare start vs end properly
    start_date = as.Date(sprintf("%d-%02d-01", yr_start, mo_start))
    end_date   = as.Date(sprintf("%d-%02d-01", yr_end, mo_end))

    if (start_date > end_date) {
      output$status_ui = renderUI({
        div(class = "alert alert-danger m-2", "Start date must be on or before end date.")
      })
      query_result(NULL)
      return()
    }

    # Call the API using our helper function (now with month granularity)
    result = fetch_fda_recalls(
      year_start  = yr_start,
      month_start = mo_start,
      year_end    = yr_end,
      month_end   = mo_end,
      limit       = as.integer(input$limit)
    )

    # Store the result
    query_result(result)

    # Pretty date labels for the status message
    date_label = paste0(month.name[mo_start], " ", yr_start, " to ", month.name[mo_end], " ", yr_end)

    # Update the status card
    if (result$success && !is.null(result$data)) {
      output$status_ui = renderUI({
        div(
          class = "alert alert-success m-2",
          icon("circle-check"),
          strong(" Success! "),
          result$message,
          tags$br(),
          tags$small(class = "text-muted", date_label)
        )
      })
    } else if (result$success && is.null(result$data)) {
      output$status_ui = renderUI({
        div(
          class = "alert alert-warning m-2",
          icon("triangle-exclamation"),
          strong(" No data: "),
          result$message
        )
      })
    } else {
      output$status_ui = renderUI({
        div(
          class = "alert alert-danger m-2",
          icon("circle-xmark"),
          strong(" Error: "),
          result$message
        )
      })
    }
  })

  ## 2.2 Render the results table #################################

  output$recall_table = DT::renderDataTable({
    res = query_result()

    # Show nothing until the user runs a query
    if (is.null(res) || is.null(res$data) || nrow(res$data) == 0) return(NULL)

    # Clean and select key columns via our helper
    df = clean_recalls(res$data)

    # Friendly column names (replace underscores with spaces, title case)
    names(df) = gsub("_", " ", names(df)) %>% tools::toTitleCase()

    DT::datatable(
      df,
      filter   = "top",
      rownames = FALSE,
      options  = list(
        pageLength = 15,
        scrollX    = TRUE,
        autoWidth  = TRUE,
        language   = list(
          emptyTable = "No recalls loaded yet. Use the sidebar to run a query."
        )
      )
    )
  })
}

# 3. RUN APP ###################################

shinyApp(ui, server)
