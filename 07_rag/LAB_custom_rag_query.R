# LAB_custom_rag_query.R
# RAG workflow for FDA Device Recall data
# Searches a CSV of FDA device recalls and uses an LLM to generate insights.
# Tim Fraser

# 0. SETUP ###################################

## 0.1 Load Packages ############################

# install.packages(c("dplyr", "readr", "httr2", "jsonlite", "ollamar"), repos = c(CRAN = "https://packagemanager.posit.co/cran/latest"))
library(dplyr)      # for data wrangling
library(readr)      # for reading CSV files
library(httr2)      # for HTTP requests
library(jsonlite)   # for JSON operations
library(ollamar)    # for interacting with the LLM
source("07_rag/functions.R")

## 0.2 Configuration ############################

MODEL = "smollm2:135m"
PORT = 11434
OLLAMA_HOST = paste0("http://localhost:", PORT)
DOCUMENT = "07_rag/data/fda_recalls.csv"

# 1. SEARCH FUNCTION ###################################

# Search FDA recall records by matching a query string
# across multiple columns: firm name, root cause, and product description
search = function(query, document) {
  read_csv(document, show_col_types = FALSE) %>%
    filter(
      stringr::str_detect(recalling_firm, stringr::regex(query, ignore_case = TRUE)) |
      stringr::str_detect(root_cause_description, stringr::regex(query, ignore_case = TRUE)) |
      stringr::str_detect(product_description, stringr::regex(query, ignore_case = TRUE))
    ) %>%
    as.list() %>%
    jsonlite::toJSON(auto_unbox = TRUE)
}

# 2. TEST SEARCH ###################################

# Test: search for recalls related to "Software Design"
search("Software Design", DOCUMENT)

# Test: search for recalls by a specific firm
search("Medtronic", DOCUMENT)

# Test: search for recalls mentioning a device type
search("pump", DOCUMENT)

# 3. RAG QUERY WORKFLOW ###################################

# Suppose a user wants to know about software-related recalls
input = list(query = "Software Design")

## 3.1 Data Retrieval - search the CSV for matching recalls
result1 = search(input$query, DOCUMENT)

## 3.2 System Prompt - instruct the LLM on how to analyze the data
role = "You are an FDA medical device safety analyst. The user will provide JSON data containing FDA device recall records. Analyze the recall data and provide: (1) a brief summary of how many recalls were found and what they have in common, (2) the key safety risks identified across these recalls, and (3) a recommendation for manufacturers to prevent similar issues. Keep your response under 250 words and use clear, professional language."

## 3.3 Generation - pass the retrieved data to the LLM
result2 = agent_run(role = role, task = result1, model = MODEL, output = "text")

# View the result
cat(result2)

# 4. ADDITIONAL QUERIES ###################################

# Query 2: Search by firm name
input2 = list(query = "Medtronic")
result3 = search(input2$query, DOCUMENT)
result4 = agent_run(role = role, task = result3, model = MODEL, output = "text")
cat("\n\n--- Medtronic Recalls Analysis ---\n")
cat(result4)

# Query 3: Search by device type
input3 = list(query = "pump")
result5 = search(input3$query, DOCUMENT)
result6 = agent_run(role = role, task = result5, model = MODEL, output = "text")
cat("\n\n--- Pump Recalls Analysis ---\n")
cat(result6)
