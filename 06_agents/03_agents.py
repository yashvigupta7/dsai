# 03_agents.py
# Multi-Agent Workflow
# Pairs with 03_agents.R
# Tim Fraser

# This script demonstrates a 2-agent workflow where each agent's output
# becomes the next agent's input. Students will learn multi-agent orchestration.

# 0. SETUP ###################################

## 0.1 Load Packages #################################

import pandas as pd  # for data manipulation
import requests      # for HTTP requests

# If you haven't already, install these packages...
# pip install pandas requests

## 0.2 Load Functions #################################

# Load helper functions for agent orchestration
from functions import agent_run, get_shortages, df_as_text

# 1. CONFIGURATION ###################################

# Select model of interest
MODEL = "smollm2:135m"

# We will use the FDA Drug Shortages API to get data on drug shortages.
# https://open.fda.gov/apis/drug/drugshortages/

# 2. DATA FETCHING ###################################

# Pick a category of medication to search
input_category = "Psychiatry"

# Get data on drug shortages for this category
data = get_shortages(category=input_category, limit=500)

# Process the data: keep only the most recent update per drug,
# then filter for items that are currently unavailable
stat = (data
        .groupby("generic_name")
        .apply(lambda x: x.loc[x["update_date"].idxmax()])
        .reset_index(drop=True)
        .query("availability == 'Unavailable'"))

# Convert the DataFrame to a text string so our agents can read it
raw_text = df_as_text(stat)

# 3. TWO-AGENT WORKFLOW ###################################

# Agent 1 - Summary Agent -------------------------
# Takes raw data and produces a concise bullet-point summary
role1 = "You summarize medicine shortage data. Given a markdown table of drug shortages, return a concise bullet-point summary listing each drug name and its current status."
result1 = agent_run(role=role1, task=raw_text, model=MODEL, output="text")

# Agent 2 - Press Release Agent -------------------------
# Takes the summary from Agent 1 and writes a formatted press release
role2 = "You write a short press release about drug shortages. Given a bullet-point summary, produce a 1-paragraph press release suitable for a news outlet."
result2 = agent_run(role=role2, task=result1, model=MODEL, output="text")

# 4. VIEW RESULTS ###################################

# Show output from Agent 1 (summary)
print("=" * 60)
print("AGENT 1 — Summary")
print("=" * 60)
print(result1)

# Show output from Agent 2 (press release)
print("\n" + "=" * 60)
print("AGENT 2 — Press Release")
print("=" * 60)
print(result2)
