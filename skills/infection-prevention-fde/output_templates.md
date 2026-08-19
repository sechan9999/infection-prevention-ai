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

## Template 7: Outbreak Investigation Packet

```
Investigation ID: OBK-<YYYY>-<nnn>
State: open-suspected | open-confirmed | monitoring | closed | rejected
Opened: <date>   Last updated: <datetime>   Detection latency: <n> days

1. CASE DEFINITION (version <n>, set <date>)
   Person: <...>
   Place: <...>
   Time: <...>
   Lab/clinical criteria: <...>
   Counts under this version: confirmed <n> | probable <n> | suspect <n>

2. OUTBREAK EXISTENCE
   Observed: <n> in <window>
   Expected: <n> (basis: <trailing baseline / prior year / facility rate>)
   Denominator: <patient days / procedures / census>

3. LINE LIST
   <table, de-identified case ids, per workflow.md Step 4>
   Changes since last packet: +<n> new, <n> reclassified

4. DESCRIPTIVE EPIDEMIOLOGY
   Person: <...>
   Place: <room/bed map summary, shared equipment and rooms>
   Time: <epidemic curve; bin width; cases using fallback dates: <n>>
   Compatible pattern (hypothesis): <point source | propagated | continuous
   common source | mixed>

5. HYPOTHESES (ranked)
   H1: <transmission route>
       Supports: <evidence>
       Contradicts: <evidence>
       Cases explained: <n> of <n>
       Status: unverified | log-verified | tested
   H2: ...

6. HYPOTHESIS TESTING
   Design: <cohort | case-control | descriptive only>
   Exposures declared in advance: <list>
   Results: <all exposures, with point estimate and CI>
   Power: <statement; underpowered if applicable>

7. LABORATORY AND ENVIRONMENTAL
   Typing: <status | laboratory interpretation verbatim | source>
   Facility logs reviewed: <water / air / reprocessing / construction>
   Contradicting findings: <stated explicitly, or "none">

8. CONTROL MEASURE OPTIONS
   | Option | Tier | Evidence | Operational cost | Reversible |
   <one row per option; no single recommended course for unit closure,
    admission holds, procedure cancellation, or staff restriction>

9. OPEN QUESTIONS / MISSING DATA
   - <field or feed, and what it would resolve>

Risk Level: Low | Medium | High
Confidence: <0-100>% (<basis>)

Human Approval Required:
Yes - Infection Preventionist (and Infection Control Committee for any state
change or control measure)

Proposed state change: <none | to <state>>

Audit Record:
Generated - <audit_id>
```

---

## Template 8: Outbreak Closure Summary

```
Investigation ID: OBK-<YYYY>-<nnn>
Period: <first onset> to <last onset>
Final counts: confirmed <n> | probable <n> | suspect <n>
Organism: <species, susceptibility / typing summary>
Units involved: <...>

WHAT HAPPENED
<3-5 sentences, plain language, no jargon>

MOST SUPPORTED HYPOTHESIS
<hypothesis>
Supporting evidence: <...>
Evidence never resolved: <...>
Alternative hypotheses not excluded: <...>

CONTROL MEASURES APPLIED
| Measure | Applied date | Verified date | Verified by |

CLOSURE CRITERIA
- No new confirmed case since <date> (<n> incubation periods: yes/no)
- Control measures verified: yes/no
- Contact screening complete: yes/no
- Corrective actions closed: yes/no

DETECTION PERFORMANCE
Trigger that surfaced the event: <rule id | human report>
First onset to investigation open: <n> days
Rule outcome: true positive | missed (rule change proposed: <id>)
Pseudo-outbreak: yes/no (<cause>)

LESSONS AND PROPOSED CHANGES
- <change, owner, proposed to IP on <date>>

Closed by: <name, role>   Date: <date>
Audit Record: Generated - <audit_id>
```

---

## Template 9: Stewardship Daily Worklist

```
Date: <YYYY-MM-DD>   Scope: <facility | unit | service>
Patients on antimicrobials: <n>   Flags raised: <n>   Shown: <n>   Held: <n>
Rule set version: <v>

--- PRIORITY ---
1. [S-MISMATCH-01] <patient_key> | <agent>, day <n>
   Evidence: <organism> from <source>, collected <date>; panel shows
             non-susceptible to <agent>
   For stewardship review. Routed: pharmacist, paged.
   Confidence: <n>% (<basis>)

--- WORKLIST ---
2. [S-DEESC-01] <patient_key> | <agent>, day <n>
   Evidence: <organism> susceptible to <narrower agent>, result <datetime>
   Pathway reference: <id, version>
   Criteria met: <list>   Unverifiable from structured data: <list>
   Confidence: <n>% (<basis>)

3. [S-IVPO-01] ...

--- HELD (<n>) ---
<rule id> x <n> - reason: <daily capacity | already declined this admission>

--- CHANGES SINCE YESTERDAY ---
New: <n>   Resolved: <n>   Still open: <n>

Human Approval Required:
Yes - Stewardship Pharmacist. No flag proposes a therapy change.

Audit Record:
Generated - <audit_id>
```

---

## Template 10: AU / AR Quarterly Package

```
Period: <Qn YYYY>   Prepared: <date>   Status: DRAFT - not submitted

1. UTILIZATION
   | Agent / class | DOT | Days present | DOT per 1000 days present | vs baseline |
   Denominator used: days present (not patient days)

   SAAR: <observed> / <predicted> = <value>
   NHSN methodology version: <v>
   Note: a SAAR prompts investigation. It is not a quality score and is not
   comparable across facilities from this data.

2. RESISTANCE
   | Organism | Isolates | % susceptible by agent |
   First isolate per patient per period. Repeat isolates excluded: <n>
   Organisms suppressed below minimum isolate count (<n>): <list>

3. PROGRAM PERFORMANCE
   Flags raised: <n>   Accepted: <n> (<x>%)   Declined: <n>   Modified: <n>
   Acceptance rate by rule: <table>
   Median time from flag to intervention: <n> hours
   IV-to-PO conversion rate: <x>%
   Targeted-agent DOT trend vs pre-program baseline: <x>%
   Facility CDI rate alongside high-risk agent DOT: <both series>

4. RULE SET CHANGES PROPOSED
   | Rule | Acceptance | Top decline reason | Proposal |

5. LIMITATIONS
   - <feeds with gaps in this period, and what they bias>

Human Approval Required:
Yes - Stewardship Pharmacist and Physician Lead before circulation.
NHSN AUR submission is performed by a human. This package is preparation only.

Audit Record:
Generated - <audit_id>
```

---

## Template 11: Survey Readiness Snapshot

```
Prepared: <date>   Scope: <facility | division>
This is an internal gap view. It is not a compliance score, not an attestation,
and not a surveyor-facing document.

--- BY DOMAIN ---
| Domain | Requirements | Evidence coverage | Open findings (H/M/L) | Open CAs | Oldest CA |
| Hand hygiene            | <n> | <n>/<n> | 1/3/2 | 4 | 62d |
| Isolation precautions   | ... |
| Reprocessing            | ... |
| Water management        | ... |
| Staff immunization      | ... |
| Policy currency         | ... |

--- THINNEST EVIDENCE ---
Requirements with no monitoring method or no evidence location:
- <requirement_id> | <domain> | owner: <role | NONE>

--- OPEN FINDINGS BY RISK ---
High:
- <finding_id> | <requirement, cited source + version> | <gap class> | owner <role>
  Evidence: <what the data shows>
  Corrective action: <state>, age <n>d, due <date>

--- RECURRENCE ---
Findings that returned after a verified closure:
- <finding_id> | closed <date> | recurred <date> | prior action: <what was done>

--- PRIOR SURVEY FINDINGS ---
| Finding | Cycle | Corrective action | Recurred? |

--- DEADLINES IN WINDOW ---
| Item | Source | Due | Days left | Status | Owner role |

--- SUPPRESSED ---
<n> breakdowns withheld: group size below minimum (<n>)

Human Approval Required:
Yes - Infection Preventionist and Quality. Compliance conclusions are reached by
the Infection Control Committee, not by this snapshot.

Audit Record:
Generated - <audit_id>
```

---

## Template 12: Site Profile and Capability Manifest

```
Site: <site_id>   Beds: <n>   Assessed: <date>   Tier: T0 | T1 | T2 | T3

--- SYSTEMS ---
| System | Vendor / version | Owner | Stated or Verified |

--- INTEGRATION SURFACE ---
Available: <HL7 v2 message types | FHIR version + resources | flat file | API>
Interface engine owner: <role>   Change lead time: <n> weeks
Test environment: <yes/no>   Historical data depth: <n> months

--- DATA AVAILABILITY MATRIX ---
| Feed | Present | Latency | Completeness | Structured? | Known defects | Owner |
| Micro results        | yes | 2h   | 98% | yes | ... | Lab IT |
| Device flowsheet     | no  | -    | -   | -   | not captured discretely | - |
| Documented indication| partial | - | 31% | free text | in progress notes | - |

--- PEOPLE ---
IP FTE: <n> (coverage <hours>)   Stewardship pharmacist FTE: <n>
ICC cadence: <...>   After-hours path: <...>

--- WORKFLOW ---
Current surveillance method: <...>   IP hours/week on case finding: <n>
How alerts reach the IP today: <...>

--- GOVERNANCE (recorded, not adjudicated) ---
BAA status: <...>   PHI boundary: <...>   Hosting: <on-prem | private cloud>
Audit retention required: <n> years   Security review: <process, owner>
For the hospital privacy officer, counsel, and security team to rule on.

--- BASELINE (captured <date>, before any output shown) ---
Detection latency: <n> days   HAI counts by type: <...>
Antibiotic DOT/1000 days present: <n>   Compliance rates: <...>
IP hours/week on case finding: <n>

--- CAPABILITY MANIFEST ---
Enabled (<n>):
| Rule | Agent | Feeds used |
Degraded-explicit (<n>):
| Rule | Reduction | Label printed on every output |
Disabled - missing feed (<n>):
| Rule | Missing feed | What would enable it |
Disabled - quality (<n>):
| Rule | Feed | Defect | Quality floor |
Deferred by choice (<n>):
| Rule | Enable at stage |

Honest summary: this site can run <n> of <n> rules today.

--- UNKNOWNS ---
| Dimension | Question | Owner | Due |

Human Approval Required:
Yes - Infection Preventionist confirms profile accuracy before configuration.

Audit Record:
Generated - <audit_id>
```

---

## Template 13: Deployment Plan and Go-Live Gate

```
Site: <site_id>   Agent: <which of the four>   Stage: 0-5   Plan version: <v>

--- CONFIG SUMMARY ---
Config version: <v>   Approved by: <role, name, date>
Alert budget: <n>/day for <role>   Enabled rules within budget: yes/no
Thresholds without rationale: <n>  (must be 0 to proceed)
Values inherited from a peer site still marked unreviewed: <n>  (must be 0)

--- GATES AGREED BEFORE VALIDATION ---
Recorded: <datetime>   By: <role, name>
| Measure | Gate | Result | Pass? |
| Unexplained missed events | 0 | <n> | |
| PPV on raised candidates | >= <x>% | <x>% | |
| Daily volume | <= budget | <n> | |
| Detection latency vs baseline | earlier or equal | <n> days | |

--- VALIDATION RESULT ---
Retrospective window: <dates>   Adjudicated truth set: <n> events
Sensitivity: <x>%   PPV: <x>%   Latency delta: <n> days earlier
Miss list:
| Event | Classification (feed / threshold / rule gap / data quality) | Remediation | Accepted by |

Prospective shadow: <dates>, outputs sealed
Agent found: <n>   IP found independently: <n>   Overlap: <n>

--- ROLLOUT ---
| Stage | Entry gate | Passed by | Date |
Scope at go-live: <unit / service / facility>
Named owner: <individual, role>            (required for stage 4)
Kill switch: <how, who may, tested on <date>>   (required for stage 4)
Fallback process: <what the team reverts to>

--- KNOWN GAPS CARRIED FORWARD ---
Disabled rules: <n>   (from Template 12; reviewed at every checkpoint)

--- POST-DEPLOYMENT CHECKPOINTS ---
| Day | Detection latency | IP hours reclaimed | Precision | Rules retired | Rules enabled |
| 30  | | | | | |
| 90  | | | | | |
| 180 | | | | | |
Reported against this site's baseline. No-change and negative results included.

Human Approval Required:
Yes - stage advancement is a human decision. This agent prepares gates; it does
not pass them.

Audit Record:
Generated - <audit_id>
```
---

## Rules for all templates

- Confidence is a stated number with a stated basis. "High" is not a confidence.
- Findings are phrased as candidates ("possible", "consistent with"), never as
  confirmed NHSN events.
- Patient identifiers are de-identified keys in every template.
- No template ever contains a diagnosis, an order, or a therapy recommendation.
- No template ever contains a staff name or an individual performance finding.
