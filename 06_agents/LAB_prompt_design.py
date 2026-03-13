# LAB_prompt_design.py
# Multi-Agent Drug Shortage Impact Assessment Pipeline
# Pairs with LAB_prompt_design.md
# Yashvi

# This script implements a 3-agent workflow for analyzing FDA drug shortages.
# Agent 1 (Data Analyst) analyzes raw data, Agent 2 (Healthcare Advisor)
# writes clinical recommendations, and Agent 3 (Patient Communicator)
# translates those into patient-friendly language.
#
# The script demonstrates prompt iteration: first with simple prompts (v1),
# then with refined prompts incorporating YAML rules (v2).

# 0. SETUP ###################################

## 0.1 Load Packages #################################

import pandas as pd  # for data manipulation
import requests      # for HTTP requests
import yaml          # for reading YAML rules

# If you haven't already, install these packages...
# pip install pandas requests tabulate pyyaml

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

# Convert the DataFrame to text so our agents can read it
raw_text = df_as_text(stat)

# ============================================================
# 3. ITERATION 1 — Simple Prompts (v1)
# ============================================================
# Start with basic role descriptions to see what the model produces.
# These prompts are intentionally minimal to establish a baseline.

print("*" * 60)
print("ITERATION 1 — Simple Prompts (v1)")
print("*" * 60)

# Agent 1 - Data Analyst (v1: simple)
role_analyst_v1 = "You are a data analyst. Summarize the drug shortage data."

# Agent 2 - Healthcare Advisor (v1: simple)
role_advisor_v1 = "You are a healthcare advisor. Write recommendations based on the analysis."

# Agent 3 - Patient Communicator (v1: simple)
role_patient_v1 = "You are a patient communicator. Rewrite the recommendations for patients."

# Run the v1 workflow
result_analyst_v1 = agent_run(role=role_analyst_v1, task=raw_text, model=MODEL, output="text")
result_advisor_v1 = agent_run(role=role_advisor_v1, task=result_analyst_v1, model=MODEL, output="text")
result_patient_v1 = agent_run(role=role_patient_v1, task=result_advisor_v1, model=MODEL, output="text")

print("\n--- Agent 1 (Data Analyst) ---")
print(result_analyst_v1)
print("\n--- Agent 2 (Healthcare Advisor) ---")
print(result_advisor_v1)
print("\n--- Agent 3 (Patient Communicator) ---")
print(result_patient_v1)

# v1 Issues observed:
# - Agent 1 output is unstructured; hard for Agent 2 to parse.
# - Agent 2 recommendations are vague without specific drug names.
# - Agent 3 still uses medical jargon because it has no constraints.
# - No word limits, so responses vary wildly in length.

# ============================================================
# 4. ITERATION 2 — Refined Prompts with YAML Rules (v2)
# ============================================================
# Address v1 issues by adding:
# - Specific output formats so each agent's output feeds cleanly to the next
# - Word limits to keep responses focused
# - YAML rules for detailed behavioral constraints

print("\n" + "*" * 60)
print("ITERATION 2 — Refined Prompts with Rules (v2)")
print("*" * 60)

## 4.1 Load Rules from YAML #################################

# Rules provide structured guidance that makes agent behavior
# more precise and consistent across runs.
# See LAB_prompt_design_rules.yaml for the full rule definitions.
with open("LAB_prompt_design_rules.yaml", "r") as f:
    rules = yaml.safe_load(f)

# Extract each agent's rules
rules_analyst = rules["rules"]["data_analyst"][0]
rules_advisor = rules["rules"]["healthcare_advisor"][0]
rules_patient = rules["rules"]["patient_communicator"][0]

## 4.2 Helper: Format Rules for Prompt #################################

def format_rules(ruleset):
    """Format a YAML ruleset into a string to append to the agent's role."""
    return f"{ruleset['name']}\n{ruleset['description']}\n\n{ruleset['guidance']}"

## 4.3 Build Refined Prompts #################################

# Agent 1 - Data Analyst (v2: specific role + format + rules)
role_analyst_v2 = (
    "You are a pharmaceutical data analyst. "
    "Given a markdown table of drug shortages, analyze the data and produce "
    "a numbered list of findings. For each drug, include: "
    "(1) the drug name, (2) its availability status, and (3) an impact rating "
    "(High, Medium, or Low) based on how commonly the drug is prescribed. "
    "End with a one-sentence overall assessment of the shortage situation. "
    "Keep your response under 200 words."
    f"\n\n{format_rules(rules_analyst)}"
)

# Agent 2 - Healthcare Advisor (v2: specific role + format + rules)
role_advisor_v2 = (
    "You are a healthcare advisor writing for physicians and pharmacists. "
    "Given a numbered analysis of drug shortages with impact ratings, "
    "write 3-5 actionable recommendations as bullet points. "
    "Each recommendation should: start with a bold action verb, "
    "reference specific drugs from the analysis, and suggest a concrete "
    "alternative or monitoring step. End with a brief note on when to "
    "re-evaluate. Keep your response under 200 words."
    f"\n\n{format_rules(rules_advisor)}"
)

# Agent 3 - Patient Communicator (v2: specific role + format + rules)
role_patient_v2 = (
    "You are a patient communication specialist. "
    "Given a set of healthcare provider recommendations about drug shortages, "
    "rewrite them as a short, friendly patient advisory notice. "
    "Use simple language (no medical jargon). Structure it as: "
    "(1) a brief intro explaining the situation, "
    "(2) 3-4 simple action items patients can take, and "
    "(3) a reassuring closing sentence. "
    "Keep your response under 150 words."
    f"\n\n{format_rules(rules_patient)}"
)

## 4.4 Run Refined Workflow #################################

# Agent 1 - Data Analyst -------------------------
# Takes raw shortage data and produces a structured severity analysis
result_analyst_v2 = agent_run(role=role_analyst_v2, task=raw_text, model=MODEL, output="text")

# Agent 2 - Healthcare Advisor -------------------------
# Takes the analyst's findings and writes clinical recommendations
result_advisor_v2 = agent_run(role=role_advisor_v2, task=result_analyst_v2, model=MODEL, output="text")

# Agent 3 - Patient Communicator -------------------------
# Takes the advisor's recommendations and creates a patient-friendly notice
result_patient_v2 = agent_run(role=role_patient_v2, task=result_advisor_v2, model=MODEL, output="text")

# 5. VIEW FINAL RESULTS ###################################

print("\n" + "=" * 60)
print("AGENT 1 — Data Analyst (v2)")
print("=" * 60)
print(result_analyst_v2)

print("\n" + "=" * 60)
print("AGENT 2 — Healthcare Advisor (v2)")
print("=" * 60)
print(result_advisor_v2)

print("\n" + "=" * 60)
print("AGENT 3 — Patient Communicator (v2)")
print("=" * 60)
print(result_patient_v2)

# 6. PROMPT DESIGN NOTES ###################################
#
# Workflow Design:
#   Data Analyst --> Healthcare Advisor --> Patient Communicator
#   Each agent transforms content for a progressively wider audience.
#
# Iteration 1 (v1) issues:
#   - Simple prompts produced unstructured, inconsistent output.
#   - No format spec meant Agent 2 couldn't reliably parse Agent 1's output.
#   - Agent 3 still used jargon because nothing told it not to.
#
# Iteration 2 (v2) improvements:
#   - Added explicit output format (numbered list, bullets, 3-part advisory).
#   - Added word limits (200/200/150) to control response length.
#   - Loaded YAML rules (LAB_prompt_design_rules.yaml) for detailed constraints
#     like impact ratings, bold action verbs, and no-jargon requirements.
#   - Each agent's format is designed so its output matches the next agent's
#     expected input, making the chain more reliable.
#
# What worked well:
#   - Specifying exact output structure made outputs more consistent.
#   - YAML rules kept prompts organized and easy to tweak independently.
#   - The audience progression (analyst → provider → patient) gives each
#     agent a clear, distinct purpose in the chain.
