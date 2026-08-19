# Output Templates

Every agent powered by this skill emits one of these. Section names are fixed so
downstream tooling can parse them. Never drop a section; if a section has no
content, write "None identified."

---

## Template 1: Standard Finding (default)

```
Finding:
- <one sentence, candidate signal phrased as a possibility>

Evidence:
- Source: <system / table / feed>
- Data: <de-identified records, dates, organisms>
- Guideline: <NHSN / CDC / hospital policy reference>

Risk Level:
Low | Medium | High

Confidence:
<0-100>%  (<basis for the number>)

Recommended Action:
- <specific, assignable, doable today>

Human Approval Required:
Yes - <role>

Audit Record:
Generated - <audit_id>
```

---

## Template 2: Cluster / Outbreak Alert

```
Finding:
Possible infection cluster detected.

Evidence:
- Patients: <A, B, C - de-identified keys>
- Organism: <species + susceptibility pattern>
- Shared exposure: <unit / room / procedure / equipment>
- Time window: <onset dates>
- Guideline: <reference>

Risk Level:
High

Confidence:
<0-100>%

Recommended Action:
1. Notify Infection Preventionist and Quality Department now.
2. Line-list additional exposed patients on <unit>.
3. Verify isolation and precaution status for each case.
4. Consider environmental and equipment review.

Human Approval Required:
Yes - Infection Preventionist (immediate)

Escalation:
Triggered per safety_rules.md

Audit Record:
Generated - <audit_id>
```

---

## Template 3: Compliance Finding

```
Finding:
- <gap between observed practice and required standard>

Evidence:
- Observed: <what the data shows>
- Required: <policy / regulation text reference>
- Gap: <difference>

Risk Level:
Low | Medium | High

Confidence:
<0-100>%

Recommended Action:
- <corrective action, owner, suggested due date>

Human Approval Required:
Yes - Quality Department

Audit Record:
Generated - <audit_id>
```

---

## Template 4: Stewardship Flag

```
Finding:
- <bug-drug mismatch | de-escalation opportunity | duplicate therapy | duration outlier>

Evidence:
- Patient: <de-identified key>
- Culture: <organism, susceptibility, result date>
- Therapy: <agent, start date, day of therapy>
- Reference: <hospital pathway / IDSA guideline>

Risk Level:
Low | Medium | High

Confidence:
<0-100>%

Recommended Action:
- Route to stewardship pharmacist for review. No order change proposed by AI.

Human Approval Required:
Yes - Antimicrobial Stewardship Pharmacist

Audit Record:
Generated - <audit_id>
```

---

## Template 5: Audit Record (machine-readable)

```json
{
  "audit_id": "IPC-2026-0001",
  "timestamp_utc": "2026-01-01T12:00:00Z",
  "agent": "infection-surveillance-agent",
  "skill_version": "0.1.0",
  "trigger": "new_positive_culture",
  "inputs": {
    "sources": ["LIS", "ADT"],
    "record_keys": ["pt_hash_1", "pt_hash_2"],
    "query_window": "2026-01-01/2026-01-07"
  },
  "reasoning_summary": "Two isolates, same species and antibiogram, same unit, 4 days apart.",
  "evidence_refs": ["NHSN PSC Ch.4", "Policy IPC-012"],
  "finding": "Possible infection cluster detected.",
  "risk_level": "High",
  "confidence": 0.85,
  "recommendation": "Notify IP and Quality; line-list unit 3W.",
  "human_review": {
    "required": true,
    "assigned_role": "Infection Preventionist",
    "status": "pending",
    "reviewer": null,
    "decision": null,
    "decision_timestamp_utc": null,
    "reviewer_note": null
  },
  "phi_handling": "de-identified keys only"
}
```

---

## Template 6: Daily Dashboard Summary

```
Date: <YYYY-MM-DD>

New candidate events:      <n>   (CLABSI <n> / CAUTI <n> / SSI <n> / MDRO <n> / CDI <n>)
Open clusters:             <n>
Pending IP adjudication:   <n>
Escalated today:           <n>
Alert precision (30d):     <x>%

Top item for review:
- <single most important thing the IP should look at first>
```

---

## Rules for all templates

- Confidence is a stated number with a stated basis. "High" is not a confidence.
- Findings are phrased as candidates ("possible", "consistent with"), never as
  confirmed NHSN events.
- Patient identifiers are de-identified keys in every template.
- No template ever contains a diagnosis, an order, or a therapy recommendation.
