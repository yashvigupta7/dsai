# 02_ai_quality_control.R
# AI-Assisted Text Quality Control — Medical Device Recall App
# Modified from Tim Fraser's lab template
#
# RESEARCH QUESTION:
#   Can AI quality control feedback improve report generation prompts,
#   and can we prevent gaming by anchoring evaluation to a mechanical
#   number-matching check (accurate) rather than relying solely on
#   AI Likert scores (faithfulness)?
#
# DESIGN:
#   - Condition A: Generate report with original prompt → QC score it
#   - Condition B: AI rewrites prompt using QC feedback → regenerate → re-score
#   - Anti-gaming: mechanical number check runs independently of AI grader
#   - Held-out test recall used to verify improvement generalizes

# 0. SETUP ###################################

library(dplyr)
library(stringr)
library(readr)
library(httr2)
library(jsonlite)

if (file.exists(".env")) { readRenviron(".env") } else { warning(".env not found.") }
OPENAI_API_KEY <- Sys.getenv("OPENAI_API_KEY")
OPENAI_MODEL   <- "gpt-4o-mini"
if (OPENAI_API_KEY == "") stop("OPENAI_API_KEY not found in .env file.")

# 1. DATA ###################################
# Two separate recalls: one for optimization, one held-out for testing.
# This prevents the optimizer from gaming — improvement must generalize
# to data it never saw during the rewrite process.

## 1.1 Training recall (used to generate + optimize the prompt) ----
source_data_train <- "
FDA DEVICE RECALL DATA SUMMARY — TRAINING SET
======================================
Total Recalls: 847

TOP 5 ROOT CAUSES:
  Labeling: 312
  Design: 198
  Sterility: 127
  Software: 94
  Manufacturing: 116

MONTHLY RECALL COUNTS:
  2024-01: 61
  2024-02: 68
  2024-03: 89
  2024-04: 95
  2024-05: 74
  2024-06: 71
  2024-07: 66
  2024-08: 70
  2024-09: 63
  2024-10: 58
  2024-11: 65
  2024-12: 67

TOP 5 RECALLING FIRMS:
  Medtronic: 42
  Abbott: 38
  Boston Scientific: 31
  Becton Dickinson: 27
  Stryker: 22
"

## 1.2 Held-out recall (never shown to the prompt optimizer) ----
# If the optimized prompt scores better here too, the improvement is real.
source_data_test <- "
FDA DEVICE RECALL DATA SUMMARY — HELD-OUT TEST SET
======================================
Total Recalls: 634

TOP 5 ROOT CAUSES:
  Software: 241
  Labeling: 189
  Sterility: 98
  Design: 71
  Manufacturing: 35

MONTHLY RECALL COUNTS:
  2023-01: 44
  2023-02: 51
  2023-03: 60
  2023-04: 58
  2023-05: 55
  2023-06: 62
  2023-07: 49
  2023-08: 53
  2023-09: 48
  2023-10: 57
  2023-11: 50
  2023-12: 47

TOP 5 RECALLING FIRMS:
  Abbott: 51
  Medtronic: 44
  Zimmer Biomet: 29
  Philips: 24
  Smith & Nephew: 18
"

# 2. HELPER FUNCTIONS ###################################

## 2.1 OpenAI call (general purpose) ----
call_openai <- function(system_msg, user_msg, temperature = 0, json_mode = FALSE) {
  body <- list(
    model    = OPENAI_MODEL,
    messages = list(
      list(role = "system", content = system_msg),
      list(role = "user",   content = user_msg)
    ),
    temperature = temperature
  )
  if (json_mode) body$response_format <- list(type = "json_object")

  res <- request("https://api.openai.com/v1/chat/completions") %>%
    req_headers(
      "Authorization" = paste0("Bearer ", OPENAI_API_KEY),
      "Content-Type"  = "application/json"
    ) %>%
    req_body_json(body) %>%
    req_method("POST") %>%
    req_perform()

  resp_body_json(res)$choices[[1]]$message$content
}

## 2.2 Generate recall report from a given prompt template ----
generate_report <- function(report_prompt, source_data) {
  call_openai(
    system_msg  = "You are a data analyst writing executive reports on FDA device recalls. Be specific and cite numbers from the data.",
    user_msg    = paste0(report_prompt, "\n\nDATA:\n", source_data),
    temperature = 0.3
  )
}

## 2.3 QC prompt builder ----
# MODIFICATION from lab template: faithfulness criterion is strengthened
# for recall-specific failure modes (severity softening, unsupported causal
# claims, device identifier generalization). These are safety-critical risks
# not covered by the generic rubric.
create_quality_control_prompt <- function(report_text, source_data) {
  paste0(
    "You are a quality control validator for AI-generated FDA medical device recall reports. ",
    "Evaluate ONLY the report text below against these criteria. ",
    "Be strict about numeric fidelity against Source Data. ",
    "Return valid JSON only. Likert fields must be integers 1-5.\n\n",
    "Source Data:\n", source_data, "\n\n",
    "Report Text to Validate:\n", report_text, "\n\n",
    "Quality Control Criteria:

1. accurate (boolean): TRUE only if every number in the report exists in Source Data
   (one-decimal rounding allowed). FALSE for any clear numeric contradiction.

2. accuracy (1-5): 1 = many numeric errors vs 5 = no misinterpretation of data.

3. formality (1-5): 1 = casual vs 5 = regulatory/government report style.

4. faithfulness (1-5): MOST IMPORTANT for medical device recalls.
   Score 1 if the report softens severity language, generalizes device identifiers,
   makes causal claims not in the source data, or introduces numbers not present
   in the source. Score 5 if every claim traces directly to the source data
   with no embellishment or unsupported inference.

5. clarity (1-5): 1 = confusing vs 5 = clear and precise.

6. succinctness (1-5): 1 = unnecessarily wordy vs 5 = succinct.

7. relevance (1-5): 1 = irrelevant commentary vs 5 = directly relevant to data.

Return ONLY this JSON:
{
  \"accurate\": true/false,
  \"accuracy\": 1-5,
  \"formality\": 1-5,
  \"faithfulness\": 1-5,
  \"clarity\": 1-5,
  \"succinctness\": 1-5,
  \"relevance\": 1-5,
  \"details\": \"0-50 word explanation\"
}"
  )
}

## 2.4 Parse QC JSON response ----
extract_json_from_text <- function(text) {
  m <- regexpr("\\{[\\s\\S]*\\}", text, perl = TRUE)
  if (m[1] == -1) return(text)
  regmatches(text, m)[1]
}

parse_qc_results <- function(json_response) {
  q <- fromJSON(extract_json_from_text(json_response))
  tibble(
    accurate     = q$accurate,
    accuracy     = as.numeric(q$accuracy),
    formality    = as.numeric(q$formality),
    faithfulness = as.numeric(q$faithfulness),
    clarity      = as.numeric(q$clarity),
    succinctness = as.numeric(q$succinctness),
    relevance    = as.numeric(q$relevance),
    details      = as.character(q$details)
  )
}

## 2.5 Mechanical number-matching check (ANTI-GAMING) ----
# This runs in pure R — no AI involved, so it cannot be gamed
# by prompt rewording. Every number in the report must exist
# in the source data. This is our ground-truth verification layer.
mechanical_accuracy_check <- function(report_text, source_data) {

  # Extract all numbers from the generated report
  report_numbers <- str_extract_all(report_text, "\\d+\\.?\\d*")[[1]] %>%
    as.numeric() %>%
    unique()

  # Extract all numbers from the source data
  source_numbers <- str_extract_all(source_data, "\\d+\\.?\\d*")[[1]] %>%
    as.numeric() %>%
    unique()

  # Check which report numbers cannot be found in source
  # Allow 1% tolerance for rounding (e.g. 36.8% reported as ~37%)
  verify_number <- function(n) {
    any(abs(source_numbers - n) / pmax(source_numbers, 1) <= 0.01)
  }

  verified    <- sapply(report_numbers, verify_number)
  unverified  <- report_numbers[!verified]

  list(
    report_numbers   = report_numbers,
    all_verified     = all(verified),
    n_unverified     = sum(!verified),
    unverified_nums  = unverified,
    pct_verified     = round(100 * mean(verified), 1)
  )
}

## 2.6 Prompt optimizer ----
# Takes QC feedback (details + scores) and rewrites the report generation
# prompt. Uses a separate system message so the optimizer "thinks" differently
# from the writer — partial defense against the optimizer gaming the grader.
optimize_prompt <- function(original_prompt, qc_results) {
  feedback_summary <- paste0(
    "The report generated by this prompt received these QC scores:\n",
    "  - Accurate (boolean): ", qc_results$accurate, "\n",
    "  - Faithfulness: ", qc_results$faithfulness, " / 5\n",
    "  - Accuracy: ", qc_results$accuracy, " / 5\n",
    "  - Overall: ", round(mean(as.numeric(qc_results[, c("accuracy","formality","faithfulness","clarity","succinctness","relevance")])), 2), " / 5\n",
    "  - Critic details: ", qc_results$details, "\n\n",
    "Common failure modes in medical device recall reports:\n",
    "  - Softening severity language\n",
    "  - Introducing numbers not present in source data\n",
    "  - Making causal claims not supported by the data\n",
    "  - Being vague to avoid contradiction (raises faithfulness artificially)\n\n",
    "Rewrite the report generation prompt below to fix these issues. ",
    "The new prompt must still ask for: Overview, Key Trends, Top Concerns, Recommendations. ",
    "Return ONLY the new prompt text, nothing else.\n\n",
    "Original prompt:\n", original_prompt
  )

  call_openai(
    system_msg  = "You are an expert prompt engineer specializing in regulatory reporting. Your goal is to make report prompts more faithful to source data, not just more cautious or vague.",
    user_msg    = feedback_summary,
    temperature = 0.5
  )
}

## 2.7 Full QC pipeline (generate + AI-grade + mechanical-check) ----
run_full_qc <- function(label, report_prompt, source_data) {
  cat("\n", strrep("=", 60), "\n")
  cat("▶", label, "\n")
  cat(strrep("=", 60), "\n")

  # Generate report
  cat("  Generating report...\n")
  report <- generate_report(report_prompt, source_data)
  cat("  Report preview (first 300 chars):\n  ",
      substr(report, 1, 300), "...\n\n")

  # AI quality control
  cat("  Running AI quality control...\n")
  qc_prompt <- create_quality_control_prompt(report, source_data)
  raw_qc    <- call_openai(
    system_msg  = "You are a strict quality control validator. Return valid JSON only.",
    user_msg    = qc_prompt,
    temperature = 0,
    json_mode   = TRUE
  )
  qc <- parse_qc_results(raw_qc)

  likert_cols   <- c("accuracy","formality","faithfulness","clarity","succinctness","relevance")
  overall_score <- round(mean(as.numeric(qc[, likert_cols])), 2)

  # Mechanical number check (ungameable ground truth)
  cat("  Running mechanical number check...\n")
  mech <- mechanical_accuracy_check(report, source_data)

  # Print results
  cat("\n  📊 AI QC SCORES:\n")
  cat("    Accurate (AI):      ", qc$accurate, "\n")
  cat("    Faithfulness:       ", qc$faithfulness, "/ 5\n")
  cat("    Accuracy:           ", qc$accuracy, "/ 5\n")
  cat("    Formality:          ", qc$formality, "/ 5\n")
  cat("    Clarity:            ", qc$clarity, "/ 5\n")
  cat("    Succinctness:       ", qc$succinctness, "/ 5\n")
  cat("    Relevance:          ", qc$relevance, "/ 5\n")
  cat("    Overall (mean):     ", overall_score, "/ 5\n")
  cat("    Details:            ", qc$details, "\n\n")

  cat("  🔧 MECHANICAL NUMBER CHECK (anti-gaming ground truth):\n")
  cat("    Numbers in report:  ", length(mech$report_numbers), "\n")
  cat("    Verified in source: ", mech$pct_verified, "%\n")
  cat("    Unverified numbers: ",
      ifelse(mech$n_unverified == 0, "none ✅",
             paste(mech$unverified_nums, collapse = ", ")), "\n")
  cat("    Mechanical pass:    ", ifelse(mech$all_verified, "✅ PASS", "❌ FAIL"), "\n")

  list(
    label         = label,
    report        = report,
    qc            = qc,
    overall_score = overall_score,
    mechanical    = mech
  )
}

# 3. DEFINE PROMPTS ###################################

## Original report generation prompt (from app.R build_ai_prompt) ----
original_prompt <- "You are a data analyst generating a brief executive report on FDA device recalls.

Generate a concise report with these sections:
1. **Overview**: A 2-3 sentence summary of the overall recall landscape.
2. **Key Trends**: 3-5 bullet points identifying the most notable trends.
3. **Top Concerns**: 2-3 bullet points highlighting significant root causes.
4. **Recommendations**: 2-3 bullet points for manufacturers or regulators.

Keep the total report under 300 words. Use clear, professional language."

# 4. RUN EXPERIMENT ###################################
cat("\n🧪 EXPERIMENT: Prompt Optimization with Anti-Gaming Verification\n")
cat("================================================================\n")
cat("Training set: 2024 recalls (used for optimization)\n")
cat("Test set: 2023 recalls (held out — never seen by optimizer)\n\n")

## Step 1: Baseline — original prompt on training data ----
result_baseline <- run_full_qc(
  label         = "BASELINE: Original Prompt (Training Data)",
  report_prompt = original_prompt,
  source_data   = source_data_train
)

## Step 2: Optimize the prompt using QC feedback ----
cat("\n", strrep("=", 60), "\n")
cat("▶ OPTIMIZING PROMPT using QC feedback...\n")
cat(strrep("=", 60), "\n")
optimized_prompt <- optimize_prompt(original_prompt, result_baseline$qc)
cat("  Optimized prompt preview (first 400 chars):\n  ",
    substr(optimized_prompt, 1, 400), "...\n")

## Step 3: Optimized prompt on training data (same data as baseline) ----
result_optimized_train <- run_full_qc(
  label         = "OPTIMIZED PROMPT (Training Data — same as baseline)",
  report_prompt = optimized_prompt,
  source_data   = source_data_train
)

## Step 4: Optimized prompt on held-out test data (anti-gaming verification) ----
# If scores improve here too, the improvement is real, not gaming.
result_optimized_test <- run_full_qc(
  label         = "OPTIMIZED PROMPT (Held-Out Test Data — 2023 recalls)",
  report_prompt = optimized_prompt,
  source_data   = source_data_test
)

# 5. FINAL SUMMARY ###################################
cat("\n", strrep("=", 60), "\n")
cat("📋 FINAL COMPARISON SUMMARY\n")
cat(strrep("=", 60), "\n\n")

summary_table <- tibble(
  Condition = c(
    "Baseline (train)",
    "Optimized (train)",
    "Optimized (test — held out)"
  ),
  Accurate_AI = c(
    result_baseline$qc$accurate,
    result_optimized_train$qc$accurate,
    result_optimized_test$qc$accurate
  ),
  Faithfulness = c(
    result_baseline$qc$faithfulness,
    result_optimized_train$qc$faithfulness,
    result_optimized_test$qc$faithfulness
  ),
  Overall_Score = c(
    result_baseline$overall_score,
    result_optimized_train$overall_score,
    result_optimized_test$overall_score
  ),
  Mechanical_Pass = c(
    result_baseline$mechanical$all_verified,
    result_optimized_train$mechanical$all_verified,
    result_optimized_test$mechanical$all_verified
  ),
  Pct_Numbers_Verified = c(
    result_baseline$mechanical$pct_verified,
    result_optimized_train$mechanical$pct_verified,
    result_optimized_test$mechanical$pct_verified
  )
)

print(summary_table)

cat("\n🎯 KEY FINDINGS:\n")
faith_gain_train <- result_optimized_train$qc$faithfulness - result_baseline$qc$faithfulness
faith_gain_test  <- result_optimized_test$qc$faithfulness  - result_baseline$qc$faithfulness

cat("  Faithfulness change (train): ", faith_gain_train,
    ifelse(faith_gain_train > 0, "⬆ improved", ifelse(faith_gain_train < 0, "⬇ worsened", "→ no change")), "\n")
cat("  Faithfulness change (test):  ", faith_gain_test,
    ifelse(faith_gain_test > 0, "⬆ improved — generalized! ✅",
    ifelse(faith_gain_test < 0, "⬇ worsened on new data ⚠️",
                                "→ no change")), "\n")

mech_improved <- result_optimized_test$mechanical$pct_verified > result_baseline$mechanical$pct_verified
cat("  Mechanical check on test:    ",
    ifelse(mech_improved, "✅ More numbers verified — real improvement",
                          "⚠️  No mechanical improvement — possible gaming"), "\n")

cat("\n💡 INTERPRETATION:\n")
cat("  If faithfulness improved on the held-out test set AND mechanical\n")
cat("  verification improved, the prompt optimization produced genuine\n")
cat("  gains — not just gaming of the AI grader.\n")
cat("  If only the training scores improved, the optimizer learned to\n")
cat("  satisfy the grader without actually becoming more faithful.\n\n")

cat("✅ Lab complete! Take a screenshot of this output for submission.\n")
cat("📁 Submit this script + screenshot + your 3-4 sentence writeup.\n")
