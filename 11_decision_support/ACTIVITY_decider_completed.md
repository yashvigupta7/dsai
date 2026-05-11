# ACTIVITY: AI Decider — Completed

## Stage 1: Comparison Table & Shortlist

### Prompt Used

**System prompt:**

> You are a structured data extractor and decision analyst.
> Your job is to extract key attributes from unstructured venue descriptions,
> build a comparison table, and recommend the top 3 venues based on the client's priorities.
>
> Always return:
> 1. A markdown table with columns: Venue, Capacity, Approx. Price/Night, Catering, Outdoor, Parking, Vibe (1 word)
> 2. A ranked shortlist of top 3 venues with 1-sentence justification each
> 3. One sentence noting any venues you had to exclude due to missing information
>
> Be concise. Do not invent data that is not in the descriptions.

**User prompt:**

> Here are the couple's priorities:
> - Budget: under $8,000 for venue rental
> - Guest count: ~120 people
> - Vibe: romantic, not too corporate
> - Must have outdoor ceremony option
> - Catering must be in-house or on an approved vendor list
>
> Here are descriptions of 16 venues. Please analyze and recommend.
>
> [Full venue data from ACTIVITY_decider.md pasted below the prompt]

**Model:** `gpt-oss:20b-cloud` via Ollama Cloud

---

### Comparison Table

| Venue | Capacity | Approx. Price/Night | Catering | Outdoor | Parking | Vibe |
|---|---|---|---|---|---|---|
| Rosewood Estate | 175 | $17,500 | Approved vendor list | Yes | ~80 cars | Elegant |
| Grand Metropolitan Hotel | 300 | $12,000 | In-house | No | Valet | Professional |
| Lakeview Pavilion | 90 / 110 | $2,500 | BYOB | Yes | N/A | Casual |
| Thornfield Manor | 150 | $18,000 | In-house | Yes | N/A | Classic |
| Foundry at Millworks | 250 | $5,000 | Bring-your-own | No | N/A | Trendy |
| Sunrise Farm & Vineyard | 130 | $9,800 | In-house / 2 approved | Yes | Ample | Picturesque |
| Atrium Club | 300+ | $9k–$14k | Flexible | No | N/A | Corporate |
| Cedar Hollow Retreat | 60 | $3,200 | Outside allowed | Yes | Field | Cozy |
| Belvedere | 180 | $28,000 | In-house | Yes | Valet | Elegant |
| Harborside Event Center | 220 | N/A | Flexible | Yes | Large | Modern |
| Ivy House | 100 | $4,500 | BYOB | Yes | Street | Intimate |
| Maple Ridge Country Club | 160 | $28,500 | In-house | No | Ample | Classic |
| Glasshouse Conservatory | 140 | $18,000 | Open | Yes | On-site | Elegant |
| Millbrook Inn | 120 | $10,500 | Outside allowed | Yes | N/A | Charming |
| Warehouse Loft | 200 | $8,800 | None | No | N/A | Industrial |
| Cloverfield Farms | 135 | $6,000 | Approved vendor list | Yes | Lots | Warm |

### Top 3 Shortlist

1. **Cloverfield Farms** — Fits every client priority: under $8k, 135-guest capacity, outdoor barn terrace, approved catering, and a warm, romantic setting.
2. **Lakeview Pavilion** — Meets budget, capacity for a tight 90–120 crowd, and an outdoor lakeside setting, though catering must be sourced independently.
3. **Ivy House** — Budget-friendly, 100-guest capacity, outdoor ceremony in a garden, but also requires BYOB catering.

### Excluded Venues

Harborside Event Center was excluded because pricing is still TBD.

---

## Stage 2: Shifted Priorities

### New Priorities

> - Budget: flexible, up to $15,000
> - Guest count: ~200 people
> - Vibe: elegant, grand
> - Outdoor is a nice-to-have but not required
> - No catering constraint

### Top 3 Shortlist (Shifted)

| Rank | Venue | Justification |
|---|---|---|
| 1 | **Grand Metropolitan Hotel** | Meets the budget ($12k), supports about 300 guests, and offers a grand, upscale setting. |
| 2 | **Warehouse Loft** | Fits the budget ($8.8k), exact 200-person capacity, and its large industrial-style space can be dressed for an elegant feel. |
| 3 | **Foundry at Millworks** | Under budget ($5k), 250-person capacity, and its trendy, spacious loft can be tailored to a more graceful aesthetic. |

### What Changed and Why

- **Cloverfield Farms** dropped from #1 to the bottom. It previously ranked high because of its price and outdoor charm; the new priorities favor grander venues with larger capacity and more upscale vibes.
- **Grand Metropolitan Hotel** and **Warehouse Loft** were not on the original top 3 because the earlier priority was budget-first, but they now rank highest due to the relaxed budget and larger capacity requirements.
- **Foundry at Millworks** moved up because its 250-person capacity aligns with the new ~200-guest target.

---

## Stage 3: Reflection

The AI consistently parsed each venue's key attributes — capacity, cost, catering, outdoor options, parking, and vibe — into a clear, sortable table, which made direct comparisons straightforward. Its biggest challenge was dealing with incomplete data (e.g., Harborside's TBD price) and distinguishing options that were "nice-to-have" versus mandatory, which forced it to guess at relative placement. It also defaulted to the only numerical data provided (e.g., capacity ranges) without cross-checking for hidden constraints, so it may have mis-ranked venues where the description implied capacity limits. Before relying on this output, a human should double-check unlisted details (exact pricing, parking capacity, and whether "vibe" labels reflect actual client sentiment) and confirm that the venues' indoor/outdoor arrangements truly match the couple's updated priorities.

---
