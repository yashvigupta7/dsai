# Homework 1: AI-Powered Reporter Software

**Name:** Yashvi Gupta
**Course:** SYSEN 5381 — Data Science and AI for Systems Engineering

---

## 1. Writing Component

> **⚠️ IMPORTANT: Rewrite this section entirely in your own words before submitting. The homework requires this to NOT be AI-generated.**

My AI-powered reporter software is built around the FDA Open Data API for medical device recalls. The tool lets users explore recall data through three integrated components: an R script that queries the FDA API, a Shiny web dashboard for interactive exploration, and a Python script that uses OpenAI to generate plain-language summary reports. I chose the FDA device recall dataset because it is publicly available, returns structured tabular data, and is relevant to systems engineering — understanding why medical devices fail and get recalled connects directly to quality control and risk management.

The three components work together as a pipeline. First, the API query layer (`my_good_query.R` and the `helpers.R` module) handles authentication, constructs date-range searches against the FDA endpoint, and parses the JSON response into a data frame. The Shiny app (`app.R`) wraps this query logic in an interactive web interface where users can select start/end dates and record limits, then view results in a sortable, filterable table powered by the DT package. The AI reporter (`my_ai_reporter.py`) takes a different path — it pulls a full year of recall data, aggregates it into monthly counts, top root causes, and top product codes, then sends that structured summary to OpenAI's GPT-4o-mini model with a carefully designed prompt requesting an executive summary, trend analysis, root-cause breakdown, and actionable recommendations.

One design challenge was deciding what data to send to the AI. Sending all 1,000 raw records would be wasteful and exceed token limits, so I pre-aggregated the data into summary statistics before passing it to the model. This kept costs low and helped the AI focus on patterns rather than individual records. Another challenge was error handling — the Shiny app needed to gracefully handle bad date ranges, network timeouts, and empty API responses, so I built a tryCatch-based flow in the helper functions that returns structured success/error objects instead of crashing the app.

---

## 2. Git Repository Links

| Component | Link |
|-----------|------|
| **API Query Script** | [01_query_api/my_good_query.R](https://github.com/yashvigupta7/dsai/blob/main/01_query_api/my_good_query.R) |
| **Shiny App (main)** | [02_productivity/shiny_app/app.R](https://github.com/yashvigupta7/dsai/blob/main/02_productivity/shiny_app/app.R) |
| **Shiny App Helpers** | [02_productivity/shiny_app/helpers.R](https://github.com/yashvigupta7/dsai/blob/main/02_productivity/shiny_app/helpers.R) |
| **Shiny App Launcher** | [02_productivity/shiny_app/run.R](https://github.com/yashvigupta7/dsai/blob/main/02_productivity/shiny_app/run.R) |
| **Shiny App README** | [02_productivity/shiny_app/README.md](https://github.com/yashvigupta7/dsai/blob/main/02_productivity/shiny_app/README.md) |
| **AI Reporter Script** | [03_query_ai/my_ai_reporter.py](https://github.com/yashvigupta7/dsai/blob/main/03_query_ai/my_ai_reporter.py) |
| **AI-Generated Report** | [03_query_ai/LAB_ai_reporter_report.md](https://github.com/yashvigupta7/dsai/blob/main/03_query_ai/LAB_ai_reporter_report.md) |
| **Project Design Doc** | [02_productivity/my_project_design.md](https://github.com/yashvigupta7/dsai/blob/main/02_productivity/my_project_design.md) |

---

## 3. Screenshots and Outputs

> **⚠️ TODO: Add your own screenshots before submitting.** Take the following screenshots and paste them into the .docx file:
>
> 1. **Shiny App — Initial Interface**: The app loaded in a browser, showing the sidebar with query controls and empty results table.
> 2. **Shiny App — Successful Query**: The app after clicking "Query FDA Recalls", showing the green success alert and the data table populated with recall records.
> 3. **Shiny App — Error Handling**: The app displaying a red error alert when given an invalid date range (e.g., start date after end date).
> 4. **AI Reporter — Console Output**: Terminal showing the `my_ai_reporter.py` script running, with the "Querying FDA API..." and "AI-GENERATED FDA DEVICE RECALL REPORT" output visible.

### Sample AI-Generated Report Output

Below is the full AI-generated report produced by `my_ai_reporter.py` (saved to `LAB_ai_reporter_report.md`):

---

#### Executive Summary

In 2024, the FDA reported a total of 1,000 medical device recalls, with significant activity concentrated in the latter half of the year. The dramatic increase in recalls, particularly during September and October, highlights critical issues in device manufacturing and compliance.

#### Monthly Trends

1. **September Surge**: September recorded the highest number of recalls at 271, suggesting potential systemic issues or heightened scrutiny in manufacturing practices during this month.
2. **August Increase**: August saw a notable rise with 75 recalls, indicating a possible prelude to the fall trend or reactions to earlier quality control failures.
3. **Consistent Decline**: After peaking in September, recalls gradually declined, with December reporting 149 recalls, reflecting possible improvements in practices or seasonal production lags.

#### Top 5 Root Causes

- Under Investigation by firm: **270**
- Process control: **188**
- Nonconforming Material/Component: **111**
- Device Design: **97**
- Process change control: **66**

#### Recommendations

1. **Enhance Quality Control**: Improve process control measures to reduce recalls related to nonconforming materials and device design issues, particularly those identified as high-frequency root causes.
2. **Increased Transparency**: Establish systems for greater transparency during investigations to address recalls promptly, especially those classified as "Under Investigation."
3. **Invest in Staff Training**: Implement comprehensive training programs focusing on device design and process change control to minimize errors and improve overall product compliance.

---

## 4. Documentation

### Data Summary

The FDA Device Recall API returns records with the following key columns used in this project:

| Column Name | Data Type | Description |
|-------------|-----------|-------------|
| `recall_number` | text | Unique identifier for each recall event (e.g., "Z-1234-2024") |
| `event_date_initiated` | date (YYYY-MM-DD) | Date the recall was initiated by the firm |
| `product_code` | text | FDA product classification code identifying the device type |
| `root_cause_description` | text | Reason for the recall (e.g., "Process control", "Device Design") |
| `recalling_firm` | text | Name of the company issuing the recall |
| `product_description` | text | Description of the recalled device |
| `k_numbers` | text | 510(k) premarket notification numbers associated with the device |
| `res_event_number` | text | FDA recall event tracking number |

### Technical Details

| Item | Detail |
|------|--------|
| **API** | [FDA Open Data — Device Recall](https://open.fda.gov/apis/device/recall/) |
| **API Key** | Register at [open.fda.gov](https://open.fda.gov/apis/authentication/). Store as `TEST_API_KEY` (R) or `API_KEY` (Python) in a `.env` file. |
| **OpenAI Model** | `gpt-4o-mini` via the Responses API (`/v1/responses`) |
| **OpenAI Key** | Store as `OPENAI_API_KEY` in the `.env` file |
| **Languages** | R (API query + Shiny app), Python (AI reporter) |
| **R Packages** | `shiny`, `bslib`, `httr`, `jsonlite`, `DT`, `dplyr`, `lubridate` |
| **Python Packages** | `requests`, `pandas`, `python-dotenv` |

### File Structure

```
dsai/
├── .env                              # API keys (not committed to git)
├── 01_query_api/
│   └── my_good_query.R               # Standalone FDA API query script
├── 02_productivity/
│   ├── my_project_design.md           # Project design document
│   └── shiny_app/
│       ├── app.R                      # Shiny UI + server
│       ├── helpers.R                  # API query & data-cleaning functions
│       ├── run.R                      # Launcher (auto-installs packages)
│       ├── DESCRIPTION                # R dependency manifest
│       └── README.md                  # App documentation
└── 03_query_ai/
    ├── my_ai_reporter.py              # AI-powered reporter script
    └── LAB_ai_reporter_report.md      # Output report generated by AI
```

### Usage Instructions

#### Running the Shiny App

```bash
# 1. Clone the repository
git clone https://github.com/yashvigupta7/dsai.git
cd dsai

# 2. Create a .env file in the project root with your API keys
#    TEST_API_KEY=your_fda_api_key_here
#    OPENAI_API_KEY=your_openai_key_here

# 3. Open R or RStudio and run the Shiny app
```

```r
setwd("02_productivity/shiny_app")
source("run.R")
```

The app opens in your browser. Select a date range, choose a record limit, and click **Query FDA Recalls** to fetch and explore data.

#### Running the AI Reporter

```bash
# 1. Install Python dependencies
pip install requests pandas python-dotenv

# 2. Make sure your .env file contains OPENAI_API_KEY and (optionally) API_KEY

# 3. Run the reporter from the project root
python 03_query_ai/my_ai_reporter.py
```

The script queries the FDA API, processes the data, sends a summary to OpenAI, and saves the generated report to `03_query_ai/LAB_ai_reporter_report.md`.
