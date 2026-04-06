# LAB_multi_agent_with_tools.py
# Multi-Agent System with Tools: FDA Device Recall Analysis
# Pairs with LAB_multi_agent_with_tools.md
# Yashvi

# This script builds a multi-agent workflow where Agent 1 uses a custom tool
# to fetch and summarize FDA medical device recall data from the openFDA API,
# and Agent 2 takes those summary statistics and writes an executive report
# with trends and regulatory recommendations.

# 0. SETUP ###################################

## 0.1 Load Packages #################################

import requests  # for HTTP requests
import json      # for working with JSON
import pandas as pd  # for data manipulation
import numpy as np   # for numerical calculations

## 0.2 Load Functions #################################

# Load helper functions for agent orchestration
import functions
from functions import agent_run, df_as_text

## 0.3 Configuration #################################

MODEL = "smollm2:1.7b"

# openFDA API base URL for device recalls
FDA_BASE_URL = "https://api.fda.gov/device/recall.json"

# 1. DEFINE CUSTOM TOOL FUNCTION ###################################

# This tool queries the openFDA Device Recall API for a given year,
# then computes summary statistics: total recalls, top root causes,
# top recalling firms, and monthly recall counts.
def fetch_fda_recall_stats(year, limit=1000):
    """
    Fetch FDA device recall data for a given year and return summary statistics.

    Parameters:
    -----------
    year : int or str
        The calendar year to query (e.g. 2023)
    limit : int
        Maximum number of records to retrieve (default: 1000, max: 1000)

    Returns:
    --------
    str
        A markdown-formatted summary of recall statistics for the year
    """

    year = int(year)
    start_date = f"{year}-01-01"
    end_date = f"{year}-12-31"

    # Build the search query for the date range
    search_query = f"event_date_initiated:[{start_date} TO {end_date}]"
    params = {"search": search_query, "limit": min(int(limit), 1000)}

    # Query the openFDA API
    response = requests.get(FDA_BASE_URL, params=params)
    response.raise_for_status()
    data = response.json()

    results = data.get("results", [])
    total_available = data.get("meta", {}).get("results", {}).get("total", 0)

    if len(results) == 0:
        return f"No recalls found for {year}."

    df = pd.DataFrame(results)

    # --- Total recalls ---
    n_loaded = len(df)

    # --- Top root causes ---
    root_cause_summary = "No root cause data available."
    if "root_cause_description" in df.columns:
        rc = (df["root_cause_description"]
              .dropna()
              .loc[lambda s: s != ""]
              .value_counts()
              .head(5))
        if len(rc) > 0:
            rc_df = pd.DataFrame({"Root Cause": rc.index, "Count": rc.values})
            root_cause_summary = rc_df.to_markdown(index=False)

    # --- Top recalling firms ---
    firm_summary = "No firm data available."
    if "recalling_firm" in df.columns:
        firms = (df["recalling_firm"]
                 .dropna()
                 .loc[lambda s: s != ""]
                 .value_counts()
                 .head(5))
        if len(firms) > 0:
            firm_df = pd.DataFrame({"Firm": firms.index, "Recalls": firms.values})
            firm_summary = firm_df.to_markdown(index=False)

    # --- Monthly trend ---
    monthly_summary = "No date data available."
    if "event_date_initiated" in df.columns:
        df["month"] = df["event_date_initiated"].str[:7]
        monthly = (df.groupby("month")
                   .size()
                   .reset_index(name="Count")
                   .sort_values("month"))
        monthly.columns = ["Month", "Count"]
        monthly_summary = monthly.to_markdown(index=False)

    # Build the full summary text
    summary = (
        f"# FDA Device Recall Summary for {year}\n\n"
        f"**Records loaded:** {n_loaded} of {total_available} total recalls\n\n"
        f"## Top 5 Root Causes\n{root_cause_summary}\n\n"
        f"## Top 5 Recalling Firms\n{firm_summary}\n\n"
        f"## Monthly Recall Counts\n{monthly_summary}"
    )

    return summary


# Register the function in the functions module so agent() can find it via globals()
functions.fetch_fda_recall_stats = fetch_fda_recall_stats

# 2. DEFINE TOOL METADATA ###################################

# Tool metadata tells the LLM what the function does and what parameters it accepts
tool_fetch_fda_recall_stats = {
    "type": "function",
    "function": {
        "name": "fetch_fda_recall_stats",
        "description": (
            "Fetch FDA medical device recall data from the openFDA API for a "
            "given year and return summary statistics including total recalls, "
            "top root causes, top recalling firms, and monthly trend."
        ),
        "parameters": {
            "type": "object",
            "required": ["year"],
            "properties": {
                "year": {
                    "type": "number",
                    "description": "The calendar year to query, e.g. 2023 or 2024"
                },
                "limit": {
                    "type": "number",
                    "description": "Maximum number of records to retrieve. Default is 1000."
                }
            }
        }
    }
}

# 3. MULTI-AGENT WORKFLOW ###################################

# Agent 1: FDA Data Analyst (uses the custom tool)
# This agent receives a user request and calls fetch_fda_recall_stats
# to pull recall data from the openFDA API for 2024.
print("=" * 60)
print("AGENT 1: FDA Data Analyst")
print("=" * 60)

role1 = (
    "You are an FDA data analyst. Use the fetch_fda_recall_stats tool "
    "to retrieve medical device recall statistics for the requested year."
)
task1 = "Fetch the FDA device recall summary statistics for the year 2024."

result1 = agent_run(
    role=role1,
    task=task1,
    model=MODEL,
    output="text",
    tools=[tool_fetch_fda_recall_stats]
)

print("Agent 1 Output (FDA Recall Statistics):")
print(result1)
print()

# 4. AGENT 2: REPORT WRITER ###################################

# Agent 2: Regulatory Report Writer (no tools)
# Takes the recall statistics from Agent 1 and generates an executive
# report summarizing trends, top concerns, and recommendations.
print("=" * 60)
print("AGENT 2: Regulatory Report Writer")
print("=" * 60)

role2 = (
    "You are a regulatory affairs analyst writing a brief executive report "
    "on FDA medical device recalls. Given recall summary statistics, write "
    "a 2-paragraph report that explains: (1) the key trends in root causes "
    "and recalling firms, and (2) what regulatory or quality-improvement "
    "actions are recommended based on the data."
)
task2 = f"Analyze these FDA device recall statistics and write an executive report:\n\n{result1}"

result2 = agent_run(
    role=role2,
    task=task2,
    model=MODEL,
    output="text",
    tools=None
)

print("Agent 2 Output (Executive Report):")
print(result2)
print()

# 5. SUMMARY ###################################

print("=" * 60)
print("WORKFLOW COMPLETE")
print("=" * 60)
print("Agent 1 used the fetch_fda_recall_stats tool to query the openFDA API and compute recall statistics.")
print("Agent 2 analyzed those statistics and wrote an executive report with trends and recommendations.")
