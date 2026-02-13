# my_ai_reporter.py
# AI-Powered FDA Device Recall Reporter
# Tim Fraser
#
# This script queries the FDA Open Data API for medical device recalls,
# processes the data into a structured summary, and uses OpenAI to
# generate an insightful report with trends and recommendations.

# 0. Setup #################################

## 0.1 Load Packages ############################

# pip install requests python-dotenv pandas

import os               # for environment variables
import requests         # for HTTP requests
import pandas as pd     # for data manipulation
import json             # for formatting data as JSON
from dotenv import load_dotenv  # for loading .env file

## 0.2 Load Environment Variables ################

# Load environment variables from the .env file in the project root
if os.path.exists(".env"): load_dotenv(".env")
else: print("⚠️ .env file not found. Make sure it exists in the project root.")

# Get API keys from environment
API_KEY = os.getenv("API_KEY")
OPENAI_API_KEY = os.getenv("OPENAI_API_KEY")

# Check that OpenAI key is available (required for AI reporting)
if not OPENAI_API_KEY:
    raise ValueError("OPENAI_API_KEY not found in .env file. Please set it up first.")

# 1. Query FDA Device Recall API #################################

print("\n📡 Querying FDA API for 2024 Device Recalls...\n")

# FDA Open Data API endpoint for device recalls
base_url = "https://api.fda.gov/device/recall.json"

# Build query parameters
# We search for recalls initiated in 2024, up to 1000 records
params = {
    "search": "event_date_initiated:[2024-01-01 TO 2024-12-31]",
    "limit": 1000
}

# Include API key if available (enables higher rate limits)
if API_KEY: params["api_key"] = API_KEY

# Send GET request to the FDA API
response = requests.get(base_url, params=params)
response.raise_for_status()

# Parse the JSON response
data = response.json()
recalls_raw = data["results"]

print(f"✅ Retrieved {len(recalls_raw)} recall records from FDA API.\n")

# 2. Process and Clean Data #################################

# Convert raw JSON records to a pandas DataFrame
df = pd.DataFrame(recalls_raw)

# Select the key columns we care about for reporting
# These fields tell us: what was recalled, when, why, and how serious
key_cols = [
    "recall_number",
    "event_date_initiated",
    "product_code",
    "root_cause_description",
    "res_event_number"
]

# Keep only columns that exist in the data
available_cols = [c for c in key_cols if c in df.columns]
df_clean = df[available_cols].copy()

# Parse dates so we can analyze trends over time
df_clean["event_date_initiated"] = pd.to_datetime(df_clean["event_date_initiated"], errors="coerce")

# Extract month for trend analysis
df_clean["month"] = df_clean["event_date_initiated"].dt.month
df_clean["month_name"] = df_clean["event_date_initiated"].dt.strftime("%B")

# 2.1 Aggregate Summary Statistics ############################

# Count recalls per month
monthly_counts = (df_clean
    .groupby(["month", "month_name"])
    .size()
    .reset_index(name="recall_count")
    .sort_values("month"))

# Top root causes
top_causes = (df_clean
    .groupby("root_cause_description")
    .size()
    .reset_index(name="count")
    .sort_values("count", ascending=False)
    .head(10))

# Top product codes
top_products = (df_clean
    .groupby("product_code")
    .size()
    .reset_index(name="count")
    .sort_values("count", ascending=False)
    .head(10))

# Build a concise data summary to send to the AI
# This reduces token usage and focuses the AI on what matters
data_summary = {
    "total_recalls": len(df_clean),
    "date_range": "January 2024 - December 2024",
    "recalls_by_month": monthly_counts[["month_name", "recall_count"]].to_dict(orient="records"),
    "top_root_causes": top_causes.to_dict(orient="records"),
    "top_product_codes": top_products.to_dict(orient="records")
}

print("📊 Data processed. Summary statistics ready for AI.\n")

# 3. Query OpenAI for AI-Generated Report #################################

print("🤖 Sending data to OpenAI for analysis...\n")

# Design a clear, specific prompt
# We tell the AI exactly what format and content we want
prompt = f"""You are a data analyst reporting on FDA medical device recalls in 2024.

Below is a structured summary of recall data. Analyze it and produce a brief report.

DATA SUMMARY:
{json.dumps(data_summary, indent=2, default=str)}

INSTRUCTIONS:
1. Write a 2-3 sentence executive summary of the overall recall landscape in 2024.
2. Identify the top 3 monthly trends (e.g., which months had the most recalls and why that might matter).
3. List the top 5 root causes as bullet points with their counts.
4. Provide 2-3 actionable recommendations for device manufacturers based on patterns in the data.

FORMAT:
- Use markdown headers (##) for each section.
- Keep the total report under 300 words.
- Be specific with numbers from the data."""

# OpenAI API endpoint (Responses API)
openai_url = "https://api.openai.com/v1/responses"

# Construct the request body
body = {
    "model": "gpt-4o-mini",
    "input": prompt
}

# Set headers with API key
headers = {
    "Authorization": f"Bearer {OPENAI_API_KEY}",
    "Content-Type": "application/json"
}

# Send POST request to OpenAI
ai_response = requests.post(openai_url, headers=headers, json=body)
ai_response.raise_for_status()

# Parse the AI response
result = ai_response.json()

# Extract the model's text reply
report = result["output"][0]["content"][0]["text"]

# 4. Save and Display the AI-Generated Report #################################

# Save the report as a markdown file
# This makes it easy to view on GitHub or in any markdown reader
report_path = "03_query_ai/LAB_ai_reporter_report.md"
with open(report_path, "w", encoding="utf-8") as f:
    f.write(report)

print(f"✅ Saved report to {report_path}\n")

# Also print the report to the console
print("=" * 60)
print("📝 AI-GENERATED FDA DEVICE RECALL REPORT")
print("=" * 60)
print()
print(report)
print()
print("=" * 60)
print("✅ AI Reporter complete.\n")
