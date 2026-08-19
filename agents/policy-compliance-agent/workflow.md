# Workflow Detail

Execution contract for the Policy Compliance Agent. The unit of work is a
finding; the unit of value is a verified closed corrective action.

---

## Run modes

| Mode | Trigger | Output |
|---|---|---|
| Continuous check | data event (new MDRO flag, missing isolation order, failed BI) | single finding (Template 3) |
| Weekly rounds pack | scheduled | findings by unit for compliance rounds |
| Monthly domain review | scheduled, rotating domains | domain deep-dive with trend |
| Deadline watch | daily | reportable-condition and NHSN deadline status |
| Survey readiness snapshot | on demand, and quarterly | readiness view (Template 11) |

---

## Step 1 - Build the requirement register

The register is the agent's spine. One row per requirement:

```
requirement_id | domain | source (document, version, section) | requirement text
owner_role | monitoring_method | evidence_location | frequency
last_verified | status
```

Rules:

- Every row cites a retrievable document and its version. A requirement the
  agent cannot cite is entered as `source_unverified` and surfaced to the IP for
  confirmation - never asserted from model knowledge.
- Where hospital policy is stricter than the external standard, the hospital
  policy is the operative requirement. Where hospital policy is weaker, that
  difference is itself a finding.
- A requirement with no owner, no monitoring method, or no evidence location is
  an ownerless-requirement finding, raised before any measurement happens. You
  cannot be non-compliant with something nobody is watching; you are simply blind
  to it, which is worse.

The register is reviewed and approved by the IP. The agent maintains it and
proposes additions; it does not decide what the hospital is required to do.

---

## Step 2 - Collect evidence

For each requirement, pull the evidence its monitoring method specifies.

Two evidence quality rules:

**Observation is not measurement.** Direct observation of hand hygiene is subject
to observer effect: observed rates run higher than unobserved practice. Report
observed compliance with the observation count, the observer type, and the share
of shifts covered. Never present a directly observed rate as the facility's true
rate.

**Consumption is a denominator, not a rate.** Product volume and dispenser events
support an observation program; they do not replace it, and a rate derived from
consumption alone is labeled as a proxy.

If evidence for a requirement is missing entirely, that is a finding
(`no_evidence`), and it is more serious than a poor result - a poor result at
least means someone is looking.

---

## Step 3 - Compare and classify

For each requirement, compare evidence to threshold and classify the gap:

| Class | Meaning | Fix direction |
|---|---|---|
| `practice-gap` | evidence shows the practice does not meet the requirement | process, staffing, supplies, workflow |
| `documentation-gap` | practice plausibly met, record does not demonstrate it | record design, capture point, field requirements |
| `evidence-gap` | no data exists to judge either way | stand up monitoring |
| `requirement-gap` | policy is stale, absent, weaker than the standard, or ownerless | policy revision, assign owner |
| `timeliness-gap` | done, but outside the required window | escalation path, alerting |

Classification requires evidence. Where the agent cannot distinguish a practice
gap from a documentation gap - the common case - it says so and names the single
data point that would resolve it. A guess between these two classes is worse than
an admitted unknown, because it points the corrective action the wrong way.

---

## Step 4 - Risk-rank the findings

Not every gap deserves equal attention. Rank on:

1. **Patient harm potential** - a reprocessing IFU deviation or a missing
   airborne isolation order outranks a late policy review by a wide margin
2. **Exposure breadth** - how many patients pass through the gap per week
3. **Regulatory consequence** - condition-level exposure versus a documentation
   deficiency
4. **Recurrence** - a finding repeating after a closed corrective action is
   escalated automatically; the corrective action failed, and that is a distinct
   finding about the corrective action process

Immediate-danger findings - failed sterilization with instruments released,
airborne isolation not in place for a suspected airborne infection, a water
management failure with a Legionella-vulnerable population - escalate the same
shift, ahead of ranking.

---

## Step 5 - Emit the finding

Template 3 for a single finding, Template 11 for the readiness snapshot.

Every finding states: the requirement with its cited source and version, what the
evidence shows, the gap class, the risk rank, the owning role, and a proposed
corrective action with a suggested due date.

Phrasing rules:

- Name the system condition, not the people. "Isolation orders absent for 6 of 9
  patients with an active MDRO flag on 3W" - not "3W nurses are not isolating
  patients."
- State what the evidence supports and no more. "Cannot distinguish practice from
  documentation without the completion timestamp" is a legitimate and useful
  finding.
- Never write a finding as a conclusion about compliance status. The agent
  reports the gap; the committee reaches the conclusion.

Patient rule: findings carry de-identified patient keys and counts against a
denominator, never a patient list. Where a specific patient must be actioned, the
key goes to the IP, who holds the crosswalk inside the covered system.

Suppression rule: any grouping below the configured minimum group size is
reported at the next level up. The agent will decline to produce a breakdown
rather than produce one that identifies an individual.

---

## Step 6 - Route and track corrective action

| Finding | Routed to | Target |
|---|---|---|
| Immediate danger | Infection Preventionist + Quality, same shift | now |
| Reprocessing or sterilization | Sterile Processing lead + IP | 24 hours |
| Practice gap, high risk | Unit leadership + IP | 7 days to plan |
| Documentation gap | Process owner | 30 days |
| Requirement or ownerless gap | IP + Quality | next committee |
| Timeliness gap | IP | immediate for reportable conditions |

Corrective action states: `open` -> `plan-accepted` -> `implemented` ->
`verified-closed`, with `overdue` as a flag on any state.

**Implemented is not closed.** A corrective action moves to `verified-closed`
only when new evidence shows the gap is actually gone - not when someone reports
having fixed it. The agent re-measures and reports whether the fix held. A
corrective action closed without verification evidence is itself a finding about
the corrective action process.

Every state change is a human decision, recorded with who and when.

---

## Step 7 - Deadline watch

Runs daily, independent of everything else:

- Reportable conditions: each notifiable result against its state-specified
  window, with the clock starting at the result, alerting well before expiry
- NHSN submissions: each due quarter against its deadline, with status
- Policy review dates, competency expirations, fit test expirations, water
  management task schedule

Deadline alerts state the deadline, the source that sets it, and the current
status. The agent prepares packages and never submits, notifies, or attests. A
missed deadline is reported plainly, on the day it is missed, to the IP - it is
never quietly rolled forward.

---

## Step 8 - Survey readiness

The readiness snapshot is a standing view, not an exercise performed before a
survey. It shows, per domain: requirement count, evidence coverage, open
findings by risk, open corrective actions with age, prior survey findings and
whether they recurred, and the domains with the thinnest evidence.

It is explicitly not a compliance score. Compressing a hospital's infection
prevention posture into a number invites managing the number, and the number is
not the thing that protects patients. The snapshot shows where the evidence is
thin and what is unresolved.

The agent never produces a document intended to demonstrate compliance to a
surveyor. It produces the hospital's internal view of its own gaps. Anything
shown to a surveyor is assembled and attested by humans who can stand behind it.

---

## Step 9 - Feedback loop

Monthly:

- Which findings recurred after a verified closure, and in which domain - a
  recurrence pattern is a process design problem, not a compliance problem
- Which requirements have never produced a finding - either genuinely solid, or
  the monitoring method is not sensitive enough to detect anything
- Median time from finding to verified closure, by domain and owner role
- Which findings the committee consistently defers, and why - persistent deferral
  usually means the corrective action is unworkable, and the right response is to
  redesign it rather than to keep reissuing it

Register and threshold changes are proposed to the IP and Quality. The agent
never edits the requirement register, thresholds, or risk rankings on its own.
