# Workflow Detail

Execution contract for the Antibiotic Stewardship Agent. The unit of work is the
daily worklist; the unit of value is an accepted intervention.

---

## Run modes

| Mode | Trigger | Output |
|---|---|---|
| Daily PAF worklist | scheduled, before stewardship rounds | ranked worklist (Template 9) |
| Event-driven flag | new culture result or rapid diagnostic returns | single flag (Template 4) |
| Weekly summary | scheduled | acceptance rate, DOT trend, open flags |
| Quarterly AU/AR | scheduled | utilization and resistance package (Template 10) |
| Annual antibiogram | scheduled | CLSI-conformant antibiogram draft |

---

## Step 1 - Assemble the denominator

Pull every patient with an active antimicrobial order. This is the population;
everything else is filtering.

For each patient, assemble the review bundle:

- Antimicrobial: agent, dose, route, start datetime, days of therapy to date
- Administration record - count administered doses, not ordered doses
- Indication as documented at order entry
- All cultures in the current admission, with panels and collection times
- Rapid diagnostic results and their timestamps
- Renal function trend, allergy list with reaction descriptions
- Clinical stability inputs and oral intake status

Fail closed. If the MAR, the susceptibility panel, or the documented indication
is unavailable, the patient still appears on the worklist but the flag is labeled
`data_incomplete: <feed>` and confidence is capped at 60 percent. A missing feed
is never treated as a negative finding.

---

## Step 2 - Apply flag rules

Rules are declarative, versioned, and hospital-configurable. Every threshold in
the table below is configuration, not a clinical assertion - each hospital sets
its values from its own pathways and its chosen guideline source.

| Rule id | Flag | Logic sketch | Configurable |
|---|---|---|---|
| S-MISMATCH-01 | bug-drug mismatch | organism non-susceptible to an active agent on the panel | none |
| S-DEESC-01 | de-escalation | broad agent active > N hours after a narrowing susceptibility result | N |
| S-REDUN-01 | redundant coverage | two active agents in an overlapping spectrum class pair | class pair list |
| S-TIMEOUT-01 | time-out due | therapy at hour N with no reassessment documented | N |
| S-IVPO-01 | IV-to-PO candidate | high-bioavailability agent + stability criteria + oral intake | criteria set, agent list |
| S-DUR-01 | duration outlier | DOT > pathway reference for the documented indication | per-indication table |
| S-ASB-01 | asymptomatic bacteriuria | positive urine culture + therapy started + no documented urinary symptom | symptom field set |
| S-INDIC-01 | missing indication | active order, indication field empty at hour N | N |
| S-CXNEG-01 | culture-negative continuation | empiric therapy > N hours, all cultures negative and final | N |
| S-RAPID-01 | rapid result unactioned | rapid diagnostic resulted > N hours, no therapy change | N |
| S-ALLERGY-01 | delabeling candidate | penicillin label + low-risk reaction text + alternative agent active | reaction risk map |
| S-RESTRICT-01 | restricted without approval | restricted agent active, no approval record | formulary list |
| S-PROPHY-01 | prophylaxis extended | surgical prophylaxis beyond procedure-specific window | per-procedure window |
| S-COMBO-01 | high-risk combination | configured combination active, surfaced for monitoring | combination list |

Two rules deserve a note, because they are where an automated stewardship tool
most easily does harm:

**S-ASB-01.** Not treating asymptomatic bacteriuria is a standard stewardship
target, but the agent cannot see symptoms that were never charted. The flag is
phrased as "no urinary symptom documented", not "no symptoms present", and it
never suggests stopping therapy. It asks the pharmacist to look.

**S-IVPO-01.** Stability criteria are a hospital-defined checklist. The agent
reports which criteria are met and which are unverifiable from structured data.
It never concludes that a patient is stable.

---

## Step 3 - Rank the worklist

A stewardship pharmacist has roughly one hour. An unranked list of forty flags is
the same as no list. Rank by:

1. **Patient consequence** - bug-drug mismatch first, always. A patient on
   ineffective therapy outranks every efficiency opportunity on the list.
2. **Reversibility window** - flags that expire (a de-escalation opportunity on
   day 3 is worth more than on day 6)
3. **Historical acceptance rate of that rule** - rules the team acts on rise
4. **Effort to adjudicate** - a flag resolvable from structured data outranks one
   needing a full chart read, at equal value

Cap the worklist at the configured daily capacity. Flags below the cap are held,
not dropped, and are shown as a held count with the reason. A held bug-drug
mismatch is never permitted - if one exists, it displaces something else.

---

## Step 4 - Emit flags

Single flag: Template 4. Daily worklist: Template 9.

Every flag carries: patient de-identified key, the agent and its day of therapy,
the specific evidence (culture, timestamp, guideline reference), what the
stewardship team may want to consider, and the confidence with its basis.

Phrasing rule, enforced on every flag:

- Correct: "Day 5 of piperacillin-tazobactam; blood culture from day 2 grew
  E. coli susceptible to ceftriaxone. De-escalation opportunity per pathway
  ABX-04. For stewardship review."
- Prohibited: "Switch to ceftriaxone." / "Broad-spectrum therapy is no longer
  indicated." / "Stop antibiotics."

The difference is not politeness. The first states facts and names a pathway; the
second issues a clinical instruction the agent has no standing to issue.

Deduplicate against open flags on the same patient, agent, and rule. A flag the
team already declined does not reappear for that admission unless the underlying
data changes materially - and then it reappears labeled as a change, with what
changed.

---

## Step 5 - Route for human review

| Flag | Routed to | Target |
|---|---|---|
| Bug-drug mismatch | Stewardship pharmacist, paged | immediate |
| Restricted agent without approval | Stewardship pharmacist | same day |
| All other flags | Daily worklist | stewardship rounds |
| Pattern across prescribers or units | Stewardship physician lead | weekly, aggregated and anonymized |
| Antibiotic-associated CDI signal | Stewardship + Infection Prevention | same day, both |

Flag states: `open` -> `accepted` | `declined` | `modified` | `not-applicable`.

A declined flag is data, not a failure. The decline reason is the single most
valuable input the program produces, because it is what tunes the rule set.

The agent takes no action on any state. It records the state and moves on.

---

## Step 6 - Track and report

Utilization metrics:

- Days of therapy (DOT) per 1000 days present, by agent, class, unit, and service
- Length of therapy (LOT), and the DOT-to-LOT ratio as a combination-therapy proxy
- SAAR (Standardized Antimicrobial Administration Ratio) from the NHSN AUR Module,
  reported as observed over predicted, with the reminder that a SAAR is a
  comparison signal and not a quality judgment

Resistance metrics:

- Cumulative susceptibility, prepared per the CLSI M39 approach: first isolate per
  patient per period, and an organism suppressed below the minimum isolate count
  rather than reported with a misleading percentage
- Resistance trend by unit for the organisms on the hospital watch list

Program metrics - the ones that say whether any of this works:

- Flag acceptance rate, overall and per rule
- Time from flag to intervention
- DOT trend for targeted agents against the pre-program baseline
- IV-to-PO conversion rate
- Facility CDI rate alongside high-risk agent utilization

Reporting constraints: numerator and denominator always shown; small cells
suppressed; drafts only; nothing transmitted externally. The agent prepares the
NHSN AUR package for a human to submit, and never submits.

---

## Step 7 - Feedback loop

Weekly, recompute acceptance rate per rule.

- Rule above the acceptance floor: keep, and record its true positives
- Rule below the floor: propose retuning the threshold, with the decline reason
  distribution attached, or propose retirement
- Recurring decline reason across rules: propose a data or documentation fix
  rather than a threshold change - a rule that keeps firing because the
  indication field is empty is a documentation problem, not a rule problem

Alert fatigue is the failure mode that kills stewardship tools. A rule with a low
acceptance rate is not neutral; it is actively costing the program the attention
it needs for the flags that matter.

All rule changes are proposed to the stewardship pharmacist and physician lead.
The agent never edits its own rule set, thresholds, or pathway references.
