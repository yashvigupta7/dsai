# ACTIVITY: AI Assigner — Completed

## Stage 1: Assignment Table

### Prompt Used

**System prompt:**

> You are a managing partner at a consulting firm making staffing assignments.
> Your job is to read unstructured descriptions of staff members and clients,
> then assign each staff member to exactly 2 clients based on fit.
>
> Return:
> 1. An assignment table with columns: Staff Member | Client 1 | Client 2 | Rationale (1 sentence)
> 2. A brief paragraph (3–5 sentences) summarizing your overall assignment logic
>
> Rules:
> - Each staff member gets exactly 2 clients
> - Each client is assigned to exactly 1 staff member
> - No client may be left unassigned
> - Base assignments on demonstrated fit — skills, experience, communication style
> - Flag any assignments where fit is weak and explain why

**User prompt:**

> Below are descriptions of our 6 staff members and 12 clients.
> Please make the best possible assignments.
>
> [Full staff and client data from ACTIVITY_assigner.md pasted below the prompt]

**Model:** `gpt-oss:20b-cloud` via Ollama Cloud

---

### Assignment Table

| Staff Member | Client 1 | Client 2 | Rationale (1 sentence) |
|---|---|---|---|
| **Alex Chen** | **B — Atlas Financial Group** | **L — Vance Biomedical Research Institute** | Alex's methodical, compliance-focused style makes him ideal for highly-regulated, deliverable-heavy projects. |
| **Brianna Okafor** | **A — Riverdale Community Health Clinic** | **E — Greenway Transit Authority** | Brianna excels in nonprofit/public-sector stakeholder facilitation and handling evolving scopes, matching both clients' needs. |
| **Carla Mendez** | **D — Nexagen Pharmaceuticals** | **K — Summit Retail Group** | Carla's data-heavy, dashboard-building expertise fits pharma analytics, while her process-oriented mindset suits retail benchmarking. |
| **Dana Park** | **F — Solstice Consumer Goods** | **J — The Holloway Foundation** | Dana's creative market-research chops and independent work style suit the research brief and polished memo. |
| **Elliot Vasquez** | **G — Meridian Capital Partners** | **C — BrightPath Schools** | Elliot's high-stakes strategy and change-management track record matches fast-moving PE assessment and charter-school org design. |
| **Fiona Marsh** | **H — Harbor City Government (Parks Dept.)** | **I — ClearView Diagnostics** | Fiona's research-based writing and independent style create strong public-engagement reports and regulatory drafting. |

### Flagged Weak Fits

- **Dana → J (Holloway Foundation):** Dana's junior status may make a polished, high-level strategic memo more challenging than expected.
- **Fiona → I (ClearView Diagnostics):** Fiona is a strong writer but lacks deep regulatory expertise needed for FDA submissions.

### Summary of Assignment Logic

The AI first mapped each client to the staff profile that best matched their dominant needs — regulatory compliance, nonprofit facilitation, data-driven analytics, creative research, high-stakes strategy, or research-based writing. Each staff member was then paired with two clients, ensuring all 12 clients were assigned. The pairings balanced seniority, communication style, and project scope. The weakest fits were Dana Park → The Holloway Foundation (a strategic memo may be a stretch for a junior) and Fiona Marsh → ClearView Diagnostics (regulatory drafting needs domain expertise beyond writing skill).

---

## Stage 2: Stress-Test

### Follow-Up Prompt

> I'm not sure about the assignment of Fiona Marsh to Summit Retail Group (Client K).
> Can you reconsider this pairing and either defend it or suggest an alternative?

**Note:** In this model's original assignment, Fiona was actually assigned to H and I (not K). The model assigned Carla Mendez to K. When questioned about a hypothetical Fiona → K pairing, the model defended keeping Carla on K instead.

### AI Response

The model explained why Fiona was mapped to H and I rather than K:

1. **Fiona's primary strength** is research-based writing — polished, standalone documents (reports, white papers, presentations).
2. **Client H (Parks Dept.)** needs a publicly-oriented, formal report. Fiona's writing edge and independent work style produce a crisp, well-structured final product.
3. **Client I (ClearView Diagnostics)** demands regulatory drafting and pre-FDA documentation. Fiona's incisive prose and research rigor translate well into detail-heavy submissions.
4. **Client K (Summit Retail)** requires rapidly earned trust with skeptical stakeholders — a relationship-building, face-to-face endeavor that leans toward a consultant with a proven track record in change-management and stakeholder engagement.

**Why Carla is the better fit for Client K:**

- **Operational benchmarking** — Carla's data-heavy, dashboard-focused mindset aligns directly with Summit Retail's demand for process benchmarks and quantitative recommendations.
- **Trust economy** — Carla is blunt and efficient, traits that resonate with a skeptical, cost-conscious retail chain. Her straightforwardness can halt conversations at the "gap-analysis" stage, a useful trait for a client that "wants someone who can build trust quickly."

**Verdict:** Fiona stays on H and I; Carla stays on D and K. The configuration preserves skill-to-client alignment without weak-fit pairings.

---

## Stage 3: Reflection

The AI weighted the clients' dominant skill requirements — compliance rigor, data-driven analytics, stakeholder facilitation, or research-based writing — against each staff member's most pronounced proficiencies. It also considered each engagement's scale and pace to match seniority and relationship-management strength. In hindsight it underestimated the trust-building aspect of the Summit Retail Group; Carla's blunt, systematic style fits better than Fiona's purely written-deliverable focus. Overall, this allocation works as a solid first draft, but high-stakes, politics-heavy assignments should be double-checked and confidence levels validated before finalizing.

---
