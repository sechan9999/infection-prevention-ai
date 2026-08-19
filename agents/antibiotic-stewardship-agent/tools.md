# Tools

Inherits the four skill-level tools (Data Query, Guideline Retrieval, Analytics,
Reporting) and adds four stewardship-specific tools.

---

## Inherited: Data Query Tool

Same read-only, minimum-necessary, PHI-hashed contract, with pharmacy scope
added: active orders, the administration record, formulary and restriction
status, and approval records.

Constraint specific to this agent: the MAR is the source of truth for what a
patient received. An order is an intention. Any flag computed from orders alone
is labeled as such.

---

## Inherited: Guideline Retrieval Tool

Sources: hospital treatment pathways first, then IDSA and other society
guidelines, then the local antibiogram.

Constraints:

- Hospital pathway outranks external guidance when they conflict; the conflict is
  surfaced to the stewardship team, never silently resolved
- Returns a citation with a document version, or returns `guideline_unavailable`
- A duration, an interval, or a spectrum recommendation is never produced from
  memory. If the pathway is unavailable, the flag says so and the agent does not
  substitute its own number

---

## Inherited: Analytics Tool

Adds DOT, LOT, DOT-to-LOT ratio, days present denominators, SAAR context, and
resistance trending.

Constraints: numerator and denominator always shown; small cells suppressed; a
SAAR is reported with its predicted value and never as a quality score.

---

## Inherited: Reporting Tool

Renders the worklist, the weekly summary, the quarterly AU/AR package, and the
antibiogram draft. Drafts only, no external transmission, no prescriber names.

---

## Worklist Tool

Purpose:
Build, rank, and hold the daily prospective audit and feedback list.

Inputs: `date`, `scope` (facility / unit / service), `capacity` (max flags),
`rule_set_version`.

Outputs: ranked worklist with each flag's evidence bundle, plus a held-flag count
with reasons, plus a diff against yesterday (new, resolved, still open).

Constraints:

- A bug-drug mismatch is never held below the capacity cap.
- Held flags are visible as a count and reason, never silently dropped.
- Ranking inputs are shown, so the pharmacist can see why an item is at the top.
- De-identified patient keys only in any exported view.

---

## Bug-Drug Matching Tool

Purpose:
Compare active therapy against the organism's susceptibility panel.

Inputs: `patient_key`, `isolate_id`, `active_agents[]`.

Outputs: per-agent status - susceptible, intermediate, resistant, or
not-tested-on-panel - with the panel date and the specimen source.

Constraints:

- `not-tested-on-panel` is reported as its own category and never collapsed into
  susceptible or resistant. Absence of a result is not a result.
- The tool matches drug to panel. It does not judge whether the isolate
  represents infection or colonization, and it does not weigh specimen source
  against clinical picture - both are the pharmacist's call.
- Intrinsic-resistance and spectrum-overlap tables are hospital-maintained
  reference data, versioned and citable, not model knowledge.

---

## Utilization Tracking Tool

Purpose:
Compute and trend antimicrobial use.

Inputs: `metric` (DOT / LOT / DOT:LOT / SAAR), `grouping` (agent / class / unit /
service), `period`, `baseline_period`.

Outputs: metric with numerator and denominator, trend against baseline, control
limits, and, for SAAR, the observed and predicted values with the NHSN
methodology version.

Constraints:

- Days present is the denominator for AU metrics; patient days and days present
  are not interchangeable, and the tool states which it used.
- A SAAR is never reported as good or bad. It is reported as a value with its
  predicted basis and a note that it prompts investigation, not a conclusion.
- Comparisons across hospitals are not produced. Case mix is not adjustable from
  the data this agent holds.

---

## Antibiogram Tool

Purpose:
Prepare the cumulative susceptibility report.

Inputs: `period` (typically annual), `scope` (facility / unit / specimen source),
`minimum_isolates`.

Outputs: susceptibility percentages by organism and agent, isolate counts shown
alongside every percentage, and a suppressed-organism list.

Constraints:

- First isolate per patient per period, following the CLSI M39 approach; repeat
  isolates from the same patient are excluded and the exclusion count is shown.
- Organisms below the minimum isolate count are suppressed, not reported with a
  percentage. Twelve isolates do not make a percentage worth printing.
- Every percentage is printed with its denominator.
- Output is a draft for the microbiology laboratory and stewardship team to
  review and approve before it is circulated or used to guide empiric therapy.

---

## Tools deliberately absent

There is no order-entry tool, no prescriber-messaging tool, no dose-calculation
tool, no therapeutic-drug-monitoring tool, and no external-submission tool.
Changing therapy, contacting a prescriber, calculating a dose, and submitting to
NHSN are human actions, and the agent has no mechanism to perform them.
