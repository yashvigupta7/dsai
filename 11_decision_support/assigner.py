# assigner.py
# AI Assigner for Staff-Client Assignment
# Pairs with ACTIVITY_assigner.md
# Yashvi Gupta
#
# This script sends the staff-client matching problem to Ollama Cloud
# and runs all 3 stages: assignment, stress-test, and reflection prompt.

# If you haven't already, install these packages...
# pip install requests python-dotenv

# 0. SETUP ###################################

## 0.1 Load Packages #################################

import requests
import json
import os
from dotenv import load_dotenv

## 0.2 Load Environment #################################

load_dotenv()

OLLAMA_API_KEY = os.getenv("OLLAMA_API_KEY")
OLLAMA_HOST = os.getenv("OLLAMA_HOST", "https://ollama.com")
OLLAMA_MODEL = os.getenv("OLLAMA_MODEL", "gpt-oss:20b-cloud")

if not OLLAMA_API_KEY:
    raise ValueError("OLLAMA_API_KEY not found in .env file. Set it up first.")

url = f"{OLLAMA_HOST}/api/chat"
headers = {
    "Authorization": f"Bearer {OLLAMA_API_KEY}",
    "Content-Type": "application/json"
}

print(f"\n{'='*60}")
print(f"  AI ASSIGNER — Staff-Client Matching")
print(f"  Model: {OLLAMA_MODEL}")
print(f"  Host:  {OLLAMA_HOST}")
print(f"{'='*60}\n")

## 0.3 Define Data #################################

staff_and_client_data = """
--- STAFF ---

Alex Chen
Senior consultant, 9 years experience. Background in financial services and
regulatory compliance. Known for being methodical and detail-oriented.
Prefers clients who are organized and have clear deliverables.
Not great with ambiguous or fast-moving projects.

Brianna Okafor
Mid-level consultant, 4 years experience. Specialist in nonprofit and public
sector work. Very strong communicator — clients love her. Comfortable with
messy, evolving scopes. Has done a lot of stakeholder engagement work.

Carla Mendez
Senior consultant, 7 years experience. Deep expertise in healthcare and life
sciences. Data-heavy work is her strength — she's built several dashboards and
automated reporting tools. Tends to be blunt and efficient; not the warmest
bedside manner but clients respect her results.

Dana Park
Junior consultant, 2 years experience. Background is in marketing and consumer
research. Eager and creative. Better on smaller, well-defined tasks.
Still building confidence with senior client stakeholders.

Elliot Vasquez
Partner-level, 15 years experience. Generalist with a strong track record in
strategy and organizational change. Good relationship manager. Prefers high-stakes,
high-visibility engagements. Gets bored on smaller tactical work.

Fiona Marsh
Mid-level consultant, 5 years experience. Former journalist turned researcher.
Excellent writer and communicator. Often assigned to deliverable-heavy projects
(reports, white papers, presentations). Works well independently.
Prefers clients who give her creative latitude.

--- CLIENTS ---

Client A — Riverdale Community Health Clinic
Small nonprofit health clinic undergoing a strategic planning process.
Moderate budget. Stakeholders include the board, medical staff, and community
advocates. Very collaborative, but decisions are slow due to committee structure.
Main need: facilitation support and a written strategic plan.

Client B — Atlas Financial Group
Large regional bank. Highly regulated environment. Project involves auditing
their compliance documentation and recommending process improvements.
Very organized client — they have a detailed project plan. Expects formal
deliverables and regular status reports.

Client C — BrightPath Schools (Charter Network)
Fast-growing charter school network. Expanding from 3 to 8 schools.
Needs help with org design and HR policy. Client is enthusiastic but somewhat
disorganized. Decision-maker is the founder/CEO — she's visionary but hard to pin
down for meetings.

Client D — Nexagen Pharmaceuticals
Mid-size pharma company. Project is a data audit and KPI dashboard buildout
for their clinical operations team. Technical stakeholders who want results,
not hand-holding. Timeline is tight.

Client E — Greenway Transit Authority
Regional transit agency. Unionized workforce. Project involves a service
redesign study with significant community engagement components.
Political sensitivities — several board members have conflicting opinions.
Long timeline, phased project.

Client F — Solstice Consumer Goods
Consumer packaged goods brand. Needs a market research summary and brand
positioning analysis ahead of a product launch. Fun client, collaborative,
lots of back and forth. Not a huge budget. Creative work valued.

Client G — Meridian Capital Partners
Private equity firm. Fast-moving, high-expectations. Needs an org assessment
of a portfolio company. Very low patience for process — they want findings fast.
Elliot has a pre-existing relationship with the managing partner.

Client H — Harbor City Government (Parks Dept.)
Municipal parks department doing a 10-year capital planning study.
Lots of stakeholders — parks staff, city council, community groups.
Needs public engagement support and a formal report for the city council.

Client I — ClearView Diagnostics
Healthcare tech startup. Building a clinical decision support tool.
Needs help structuring their regulatory strategy and drafting FDA submission
materials. Technical and regulatory complexity is high. Startup culture —
informal, fast, sometimes chaotic.

Client J — The Holloway Foundation
Private philanthropy. Wants a landscape scan and strategic options memo on
workforce development funding. Small team, thoughtful, low-maintenance.
Primarily needs a polished, well-written deliverable.

Client K — Summit Retail Group
Multi-location retail chain. Undergoing a cost reduction initiative.
Wants operational benchmarking and process recommendations.
Client stakeholders are skeptical of consultants — they've had bad experiences
before. Need someone who can build trust quickly.

Client L — Vance Biomedical Research Institute
Academic research institute. Needs help redesigning their grant reporting
process and building a data tracking system. Methodical, detail-oriented
stakeholders. Comfortable with technical complexity.
"""

# 1. STAGE 1: ASSIGNMENT PROMPT ###################################

print("📋 STAGE 1: Running Assignment Prompt...")
print("-" * 60)

system_prompt = """You are a managing partner at a consulting firm making staffing assignments.
Your job is to read unstructured descriptions of staff members and clients,
then assign each staff member to exactly 2 clients based on fit.

Return:
1. An assignment table with columns: Staff Member | Client 1 | Client 2 | Rationale (1 sentence)
2. A brief paragraph (3–5 sentences) summarizing your overall assignment logic

Rules:
- Each staff member gets exactly 2 clients
- Each client is assigned to exactly 1 staff member
- No client may be left unassigned
- Base assignments on demonstrated fit — skills, experience, communication style
- Flag any assignments where fit is weak and explain why"""

user_prompt = f"""Below are descriptions of our 6 staff members and 12 clients.
Please make the best possible assignments.

{staff_and_client_data}"""

# Track conversation history for multi-turn
messages = [
    {"role": "system", "content": system_prompt},
    {"role": "user", "content": user_prompt}
]

body = {
    "model": OLLAMA_MODEL,
    "messages": messages,
    "stream": False
}

response = requests.post(url, headers=headers, json=body, timeout=180)
response.raise_for_status()
result = response.json()

stage1_output = result["message"]["content"]
print(stage1_output)
print()

# Append assistant reply to conversation history
messages.append({"role": "assistant", "content": stage1_output})

# 2. STAGE 2: STRESS-TEST ###################################

print(f"\n{'='*60}")
print("🔍 STAGE 2: Stress-Testing an Assignment...")
print("-" * 60)

stress_test_prompt = """I'm not sure about the assignment of Fiona Marsh to Summit Retail Group (Client K).
Can you reconsider this pairing and either defend it or suggest an alternative?"""

messages.append({"role": "user", "content": stress_test_prompt})

body = {
    "model": OLLAMA_MODEL,
    "messages": messages,
    "stream": False
}

response = requests.post(url, headers=headers, json=body, timeout=180)
response.raise_for_status()
result = response.json()

stage2_output = result["message"]["content"]
print(stage2_output)
print()

messages.append({"role": "assistant", "content": stage2_output})

# 3. STAGE 3: REFLECTION PROMPT ###################################

print(f"\n{'='*60}")
print("💭 STAGE 3: Generating Reflection...")
print("-" * 60)

reflection_prompt = """Now step back and reflect on the assignment process.
Write 3–4 sentences addressing:
- What factors did you weight most heavily?
- What did you miss or get wrong?
- Would you trust this output as a starting point? Why or why not?"""

messages.append({"role": "user", "content": reflection_prompt})

body = {
    "model": OLLAMA_MODEL,
    "messages": messages,
    "stream": False
}

response = requests.post(url, headers=headers, json=body, timeout=180)
response.raise_for_status()
result = response.json()

stage3_output = result["message"]["content"]
print(stage3_output)
print()

# 4. SUMMARY ###################################

print(f"\n{'='*60}")
print("✅ All 3 stages complete.")
print(f"{'='*60}\n")
