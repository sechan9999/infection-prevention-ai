---
name: clabsi-retrospective-validation
description: Run a retrospective validation of a deterministic CLABSI (or other HAI) rule engine against Infection Preventionist adjudications. Use when validating a surveillance rule engine before go-live, measuring capture rate / false positives / false negatives against confirmed cases, testing LIS field mapping completeness, or building the synthetic boundary-case fixture set. Enforces pre-registered gates, a separate indeterminate bucket, alert-volume and detection-latency measurement, and the concordance-not-ground-truth caveat. Triggers on "retrospective", "회고 검증", "rule engine 검증", "capture rate", "CLABSI 룰", "shadow validation".
---

# CLABSI Retrospective Validation

Validate a deterministic HAI rule engine against what the Infection Preventionist
actually decided. Two halves, run in this order:

1. **Fixture replay** - synthetic boundary cases with expected verdicts. Runs
   today, needs no PHI, catches rule regressions.
2. **Retrospective** - real adjudicated cases. Needs data access and an IP.

Never skip half 1 to get to half 2. A rule engine that fails its own synthetic
boundary cases will not produce interpretable retrospective numbers.

---

## Rule 0 - Register the gates before you look

Write the pass/fail thresholds, with a timestamp and an approver, **before** the
first case is run. Refuse to evaluate against gates written after results exist,
and say so out loud if asked to.

Minimum gate set:

| Measure | Gate shape |
|---|---|
| Unexplained false negatives | 0 - every FN classified as mapping / rule / definition |
| Capture rate vs IP adjudication | >= agreed floor |
| Candidate volume | <= the IP's stated daily adjudication budget |
| Detection latency | earlier than or equal to the manual process |
| Indeterminate rate | <= agreed ceiling |

"Grade distribution looks reasonable" is not a gate. Either state the expected
band in advance or drop the item.

---

## Rule 1 - It is concordance, not truth

The reference standard is the IP's determination, which has its own inter-rater
variability. Every report must say so. Before trusting a capture rate, double
adjudicate a subset (20-30 cases) with two IPs and report their agreement - that
figure is the engine's ceiling, and a capture rate above it is measuring noise.

---

## Rule 2 - Three buckets, not two

`confirmed` / `rejected` / **`indeterminate`**. Cases the engine could not judge
because a required feed was missing go in the third bucket and are reported as
their own rate. Folding them into FP or FN corrupts both.

---

## The archetype set (fixture half)

A case set of "typical" cases proves nothing. These are where HAI rule engines
actually fail - every one of them must exist as a fixture with an expected
verdict before a retrospective is worth running:

| # | Archetype | Trap it tests |
|---|---|---|
| 1 | Recognized pathogen, line in place, other source excluded | happy path |
| 2 | Common commensal, 2 sets on separate occasions, symptom present | must NOT auto-reject as contamination |
| 3 | Not line-associated + clear alternate source | must be non-candidate |
| 4 | Line dates unavailable | must go indeterminate, not default either way |
| 5 | Single commensal set, asymptomatic | non-candidate; the easy true negative |
| 6 | **Secondary BSI** - same organism from a primary site within the attribution period | the largest real-world FP source |
| 7 | **Repeat within the Repeat Infection Timeframe** | double-counting; usually absent from v1 engines |
| 8 | **MBI-LCBI** - neutropenic, viridans strep / enteric organism | separate NHSN category, not a CLABSI |
| 9 | **Neonate / infant** - commensal + hypothermia, apnea, or bradycardia | fever-only symptom logic misses these entirely |
| 10 | **Device-day boundary** - line in place exactly 2 calendar days | calendar-day rule, not a 48-hour clock |
| 11 | **Two bottles, one draw** counted as 2 sets | "separate occasions" vs `set_count >= 2` |

Cases 6-11 are the ones that separate a working engine from a demo.

---

## Definition traps to check in the mapping, every time

- **Device day counting** is consecutive *calendar days*, day of insertion = day 1,
  with the line present on the date of event or the day before - not a 48-hour clock
- **Common commensal** criteria require draws on *separate occasions*, not two
  bottles from one stick
- **Symptom criteria differ by age**; infants use hypothermia / apnea / bradycardia
- **Secondary BSI** needs the primary-site attribution period and organism match,
  not a single "other source excluded" boolean
- **RIT** suppresses a new event within the repeat window

These definitions are revised annually. Retrieve the current NHSN Patient Safety
Component Manual (https://www.cdc.gov/nhsn/) and the hospital's own policy, and
cite the version used. Where a national program (e.g. KONIS in Korea) also
applies, declare which is authoritative for which purpose and version-lock both -
they are not interchangeable.

---

## Metrics

See `references/metrics.md` for definitions and formulas, including the two most
teams omit: **candidate volume per day** and **detection latency delta**. A
capture rate of 95% at 40 candidates a day is a tool nobody will open in week two.

Report every rate with its numerator and denominator, and a confidence interval.
With 10-20 confirmed cases a year, state the interval width plainly rather than
presenting a point estimate as a finding.

---

## Explanation-layer scoring

If an LLM generates the human-readable explanation, score it separately from the
engine, with the rubric in `references/explanation_rubric.md`: prohibited-phrase
classes, two independent reviewers, a stated sample size. "Did it sound right"
is not a measurement.

Hard failures in explanation review: reversing or softening the rule verdict,
asserting an alternate infection source as fact, or omitting the citation.

---

## Output

Use `references/report_template.md`. It carries the pre-registered gates, the
three buckets, the classified FN list, the volume and latency figures, the
concordance caveat, and the mapping-completeness table that drives the next
data-acquisition priority.

---

## Boundaries

- Produces candidates and measurements. Never confirms a reportable event.
- Never rejects a common commensal automatically; that call is the IP's and the
  physician's.
- Never asserts an alternate infection source as excluded.
- Fixtures are synthetic with relative day offsets and no identifiers. Real
  retrospective data stays inside the covered environment; only aggregate
  measurements leave it, with small-cell suppression - ward + date + organism is
  re-identifying in a small hospital.
