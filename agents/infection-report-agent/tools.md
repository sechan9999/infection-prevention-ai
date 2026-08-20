# Tools

Inherits the four skill-level tools and adds five reporting-specific ones. This
agent's Data Query access is deliberately the narrowest in the repo: it reads the
audit trail, not the hospital.

---

## Inherited: Data Query Tool (audit-trail mode)

Purpose here is to read adjudicated records, not patient data.

Constraints specific to this agent:

- Primary source is the audit store, not the EHR, LIS, pharmacy, or ADT.
- Source-system access is limited to **denominators** - patient days, device
  days, days present, procedure counts - and is used for nothing else.
- No patient-level clinical fields are retrieved. This agent has no reason to see
  an organism attached to a patient; it sees counts attached to an `audit_id`.
- De-identified keys only, and they never appear in a rendered report.

---

## Inherited: Guideline Retrieval Tool

Used for the definitions a report must cite - surveillance definitions behind
each measure, the methodology version behind a SIR or SAAR, and the submission
schema for a package. Returns a citation with a version, or
`guideline_unavailable`. A measure whose definition cannot be cited is reported
with that gap stated.

---

## Inherited: Analytics Tool

Rates, intervals, trends, and comparisons. Constraints: numerator and denominator
always shown; small cells suppressed before rendering; trend statements withheld
below the minimum event count; SIR and SAAR withheld below the predicted-events
threshold.

---

## Inherited: Reporting Tool

Renders every artifact in this agent's catalogue. Drafts only, DRAFT marker
removable only by a human approval action, no external transmission.

---

## Snapshot Tool

Purpose:
Freeze the data a report is built from, so the same report run twice gives the
same numbers.

Inputs: `period`, `adjudication_cutoff`, `scope`.

Outputs: snapshot id, timestamp, record counts by disposition (confirmed /
rejected / pending), and the list of contributing `audit_id`s.

Constraints:

- A report cannot be rendered from live data. The tool refuses to serve a report
  build without a frozen snapshot id.
- Records still pending at the cutoff are reported as pending on their own line
  and never distributed into confirmed or rejected.
- Snapshots are immutable. A correction produces a new snapshot and a
  restatement, never an edit to an existing one.

---

## Reconciliation Tool

Purpose:
Compute the same measure from every available source and compare.

Inputs: `measure`, `period`, `sources[]` (audit trail, manual log, prior report,
source system), `tolerance`.

Outputs: each source's value, agreement or disagreement, the delta, and a likely
cause where one is inferable (late adjudication, different denominator system,
different period boundary).

Constraints:

- **Never selects a winner and never averages.** Disagreement is reported as
  disagreement.
- A discrepancy above tolerance blocks distribution until the IP resolves it, and
  the block is recorded.
- The resolution is recorded with who made it and on what basis. If it changes a
  prior period, it triggers the Restatement Tracker.

---

## Denominator Service

Purpose:
Supply and label the denominator for every rate.

Inputs: `denominator_type` (device days / patient days / days present /
procedures), `period`, `scope`.

Outputs: the value, its source system, its collection method, and known
completeness caveats.

Constraints:

- A rate request without a denominator type is refused.
- Patient days and days present are not interchangeable; the tool states which it
  returned, and a mismatch between the measure's definition and the denominator
  supplied is an error, not a rounding difference.
- Denominator changes between periods (a unit reclassified, a census method
  changed) are flagged, because they move rates without any change in infections.

---

## Restatement Tracker

Purpose:
Detect and document changes to already-distributed numbers.

Inputs: `current_snapshot`, `prior_distributed_reports[]`.

Outputs: per changed figure - the prior value, the revised value, the cause, the
reports affected, and the audiences that received them.

Constraints:

- A distributed report is never edited in place. Corrections are new documents.
- Every restatement names the cause. "Revised" without a reason is not a
  restatement, and the tool will not emit one.
- Routes to every audience that received the original, not only the current one.
- Cannot be suppressed by any reader request. A suppression request is recorded
  and routed to the IP.

---

## Submission Package Builder

Purpose:
Prepare a submission package against the receiving system's schema.

Inputs: `submission_type`, `period`, `schema_version`.

Outputs: the mapped package, a field-by-field completeness check, a list of
records excluded and why, and the human steps required to submit.

Constraints:

- **Prepares only. There is no transmission path, to NHSN, CMS, a state agency,
  an accreditor, or anyone else.** Submission is performed by the IP.
- Refuses to emit a package with unresolved discrepancies or unexplained
  exclusions.
- Never attests. Attestation language, where a submission requires it, is left
  blank for the human who can stand behind it.

---

## Tools deliberately absent

There is no transmission tool, no attestation tool, no distribution or email
tool, no ranking or scorecard-league tool, and no figure-adjustment tool.
Submitting, attesting, distributing, ranking units against each other, and
changing a number are either human acts or things this architecture does not do
at all.
