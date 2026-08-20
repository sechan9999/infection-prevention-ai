# Workflow Detail

Execution contract for the Infection Report Agent. The unit of work is a report;
the unit of value is a committee that can act on a number without first arguing
about where it came from.

---

## Run modes

| Mode | Trigger | Output |
|---|---|---|
| Monthly close | scheduled, after the adjudication cutoff | committee packet, unit scorecards |
| Quarterly close | scheduled | quality/board report, AU/AR package, readiness snapshot |
| Submission prep | deadline watch from the compliance agent | NHSN package, for a human to submit |
| Event summary | outbreak closure | outbreak summary for the next ICC |
| Annual | scheduled | program evaluation assembly |
| Restatement | a prior-period case is reclassified | restatement notice to every affected audience |

---

## Step 1 - Freeze the snapshot

A report is built from a frozen snapshot, never from live data.

- Record the snapshot timestamp and the adjudication cutoff
- Include only records whose IP disposition is final as of the cutoff
- Records still `pending` at cutoff are counted as pending, in their own line,
  and are not distributed across the confirmed and rejected buckets
- Store the snapshot id in the report header and in the audit record

Two people running the same report a week apart must get the same numbers. Live
queries make that impossible, which is how three documents end up disagreeing.

---

## Step 2 - Pull from the audit trail, not the source systems

For each measure, collect the adjudicated records from the producing agent:

| Measure | Source agent | Record state required |
|---|---|---|
| HAI events by type | surveillance | `accepted` by the IP |
| Clusters and outbreaks | outbreak | `closed` or `open-confirmed` |
| Antimicrobial use, resistance | stewardship | period aggregates |
| Compliance findings, corrective actions | compliance | any state, state shown |

If a measure has no adjudicated source, it is not reported. The agent does not
fall back to querying raw data to fill a gap - a gap is a finding about the
pipeline, and it is reported as one.

---

## Step 3 - Reconcile

Where the same measure can be derived from more than one place - the audit trail,
an existing manual log, a prior report, the source system - compute all of them
and compare.

| Result | Action |
|---|---|
| All agree | report the number, note the sources agreed |
| They disagree | report the discrepancy, both values, and the likely cause |

**Never silently pick one, and never average them.** A discrepancy is the single
most useful thing this agent finds: it usually means a case was adjudicated after
a prior report went out, or a denominator was pulled from a different system.

Discrepancies over the configured tolerance block distribution until the IP
resolves them. The resolution is recorded, and if it changes a prior period, Step
6 applies.

---

## Step 4 - Compute with the denominator attached

For every rate:

- Name the denominator explicitly - device days, patient days, days present,
  procedures - and state which one was used
- Show numerator and denominator beside the rate, always
- Attach a confidence interval, and where the interval spans the comparison
  point, say so in words rather than leaving the reader to notice
- Withhold a trend statement below the configured minimum event count; report
  counts instead and state that the period cannot support a trend
- Report SIR and SAAR only above the predicted-events threshold; otherwise raw
  counts and the reason
- Apply small-cell suppression before rendering, not after; suppressed cells are
  shown as suppressed with the count of what was withheld

---

## Step 5 - Compose per audience

Same numbers, different depth:

| Audience | Depth | Framing |
|---|---|---|
| Infection Control Committee | full detail, all measures | technical, with definitions cited |
| Quality / board | headline measures, fewer of them | plain language, no jargon, uncertainty stated |
| Unit leadership | that unit only, plus facility comparison | actionable, what the unit controls |
| NHSN submission prep | exactly the required fields | mechanical, mapped to the submission schema |

A measure may be omitted from a shorter report. It may never be restated as a
different value, rounded differently, or given a more favorable framing for a
particular audience. Where a board version simplifies, it carries a pointer to
the committee packet's fuller treatment.

---

## Step 6 - Restatement check

Before publishing, compare the current period's view of prior periods against
what was actually distributed.

If a prior number has changed - a case reclassified after adjudication, a
late-arriving culture, a corrected denominator - the agent:

1. Issues a restatement notice (Template 15), not a silent correction
2. States the prior figure, the revised figure, the cause, and the affected reports
3. Routes it to every audience that received the original
4. Preserves the original report; a distributed report is never edited in place

Restatements are normal in surveillance and are not a failure. Quietly changing
history is a failure, and it is the one that destroys a committee's trust in the
numbers.

---

## Step 7 - Human review and distribution

| Report | Approver | Then |
|---|---|---|
| Committee packet | Infection Preventionist | IP presents to ICC |
| Board / quality report | IP and Quality | Quality distributes |
| Unit scorecard | IP | unit leadership receives |
| NHSN submission package | IP | **the IP submits; the agent never does** |
| Restatement notice | IP | IP distributes to affected audiences |

The agent produces drafts with a DRAFT marker that only a human approval action
removes. Nothing leaves the workspace on the agent's initiative.

If a reader asks for a number to be changed, the agent's answer is that a number
changes when its adjudication changes. The request is recorded and routed to the
IP. It is not actioned in the report.

---

## Step 8 - Archive

Store, immutably, per report:

- The frozen snapshot id and its timestamp
- Every `audit_id` that contributed to every figure
- The rendered report as distributed, and its approver
- Any discrepancies found and how they were resolved
- Any restatement issued against it

Retention follows the hospital's policy, minimum six years unless local policy is
longer. This archive is what makes a figure defensible a year later when a
surveyor asks where it came from.

---

## Step 9 - Feedback loop

Quarterly:

- Discrepancy rate by measure and source - a measure that disagrees every month
  has a pipeline problem, not a reporting problem
- Restatement rate, and how long after distribution each was issued - a long lag
  means the adjudication cutoff is too early
- Measures that could not be reported for lack of an adjudicated source
- Which figures the committee actually asks questions about, and which are never
  discussed - a report nobody reads should shrink

Cadence, thresholds, and report composition changes are proposed to the IP and
Quality. The agent does not change what it reports on its own.
