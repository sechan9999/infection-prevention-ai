# Workflow Detail

Execution contract for the Infection Surveillance Agent. Steps map 1:1 to
`AGENT.md`. Every run produces exactly one run record plus zero or more alerts.

---

## Run modes

| Mode | Trigger | Window | Typical output |
|---|---|---|---|
| Daily sweep | scheduled, once per morning | last 24h + open cases | line list for IP adjudication |
| Continuous | new micro result event | single record + lookback | single candidate finding |
| Cluster check | on demand, or when daily sweep raises 2+ matching isolates | 14 days | cluster alert |
| Weekly summary | scheduled | 7 days | trend + stewardship summary |

---

## Step 1 - Collect

Pull, for the run window:

- Micro results: organism, specimen source, collection datetime, susceptibility panel
- ADT: admission datetime, unit/room/bed history, discharge datetime
- Device flowsheet: central line and urinary catheter presence by day
- Procedures: NHSN operative procedure code and datetime
- Pharmacy: antibiotic orders, start/stop, route

Fail closed. If any feed is stale beyond its expected latency, the run continues
but every affected finding is labeled `data_incomplete: <feed>` and confidence is
capped at 60 percent.

De-identify on ingest. Downstream steps see hashed patient keys only.

---

## Step 2 - Apply surveillance rules

Rules are declarative and versioned. Each rule declares: id, target event type,
inputs, logic, precision-to-date.

Baseline rule set:

| Rule id | Event | Logic sketch |
|---|---|---|
| R-CLABSI-01 | CLABSI candidate | positive blood culture AND central line day > 2 AND line present on event date or day prior |
| R-CAUTI-01 | CAUTI candidate | qualifying urine culture AND catheter day > 2 AND documented symptom |
| R-SSI-01 | SSI candidate | wound culture or infection dx within procedure-specific window of an NHSN procedure |
| R-MDRO-01 | MDRO LabID | first qualifying isolate per patient per period, onset classified by collection day |
| R-CDI-01 | CDI LabID | positive assay on unformed stool, onset classified by hospital day |
| R-CLUSTER-01 | cluster | 2+ patients, same species and antibiogram, shared unit/room/procedure/equipment, within 14 days |
| R-TREND-01 | trend | unit rate exceeds its trailing 6-month mean by the configured control limit |

Rules produce candidates. Rules never produce conclusions.

---

## Step 3 - Risk analysis

Score each candidate on four axes, then map to Low / Medium / High:

- Organism consequence: routine / resistant / high-consequence (CRE, C. auris, Legionella, TB, measles)
- Transmission plausibility: shared room > shared unit-shift > shared equipment > shared provider only
- Temporal fit: consistent with incubation period or not
- Population vulnerability: ICU, transplant, oncology, neonatal, dialysis

Confidence is computed from data completeness, rule precision-to-date, and
strength of exposure linkage, and is always reported with its basis.

---

## Step 4 - Generate alert

Use the matching template from `output_templates.md`:

- single candidate event -> Template 1
- cluster -> Template 2
- practice/policy gap -> Template 3
- antibiotic issue -> Template 4

Deduplicate against open alerts on the same patient + organism + event type.
Suppression is never silent: a suppressed duplicate is logged and linked to the
open parent alert.

---

## Step 5 - Human review

Routing:

| Finding | Assigned to | Target response |
|---|---|---|
| High risk / any cluster | Infection Preventionist | same shift |
| High-consequence organism | Infection Preventionist + Quality | immediate, before analysis completes |
| Medium risk | Infection Preventionist | next business day |
| Low risk | daily line list | routine adjudication |
| Stewardship flag | Stewardship pharmacist | next business day |

Alert states: `pending` -> `accepted` | `rejected` | `needs_more_data`.
The agent takes no downstream action while an alert is `pending`.

If no human has acted on a High alert within its target response time, the agent
re-surfaces it and records the delay. It does not escalate outside the IPC and
Quality routing table on its own.

---

## Step 6 - Audit record

Write one record per alert and one per run, in the Template 5 JSON shape, to
append-only storage. Records are immutable; a reviewer decision is a linked
update, not an overwrite.

Retain per hospital policy, minimum 6 years for HIPAA-adjacent documentation
unless local policy is longer.

---

## Step 7 - Feedback loop

Each rejected alert is recorded with a reason code. Weekly, recompute precision
per rule. Any rule below the agreed precision floor is flagged for retuning and
reported to the IP, who decides whether to keep, tune, or retire it. The agent
never edits its own rule set without that approval.
