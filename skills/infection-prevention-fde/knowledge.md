# Knowledge Base

Working reference for the Infection Prevention FDE skill.

IMPORTANT: This file is a reasoning scaffold, not a substitute for the official
definitions. Surveillance definitions change annually. Before any event is
counted, reported, or submitted, the current NHSN Patient Safety Component
Manual and the hospital's own policy are the authority.

Primary sources:

- CDC NHSN: https://www.cdc.gov/nhsn/
- CDC NHSN Patient Safety Component: https://www.cdc.gov/nhsn/psc/index.html
- CMS quality programs: https://www.cms.gov/
- WHO IPC: https://www.who.int/teams/integrated-health-services/infection-prevention-control
- IDSA guidelines: https://www.idsociety.org/practice-guideline/practice-guidelines/

---

# 1. Surveillance Definitions (Working Summary)

Each entry lists the device/procedure window the agent uses to raise a *candidate*
signal. The IP confirms or rejects.

## CLABSI - Central Line-Associated Bloodstream Infection

- Population: patient with an eligible central line.
- Device day rule: central line in place more than 2 consecutive calendar days,
  day of insertion counted as day 1, and the line present on the date of event
  or the day before.
- Signal inputs: positive blood culture, central line presence from ADT/device
  flowsheet, organism identity, collection date.
- Common exclusion the agent must flag rather than decide: secondary bloodstream
  infection attributable to another site.

## CAUTI - Catheter-Associated Urinary Tract Infection

- Population: patient with an indwelling urinary catheter.
- Device day rule: catheter in place more than 2 consecutive calendar days, and
  present on the date of event or the day before.
- Signal inputs: positive urine culture with qualifying colony count, catheter
  presence, symptoms documented (fever, suprapubic tenderness, CVA tenderness).
- Note: asymptomatic bacteriuria is not a CAUTI. The agent flags; it never
  concludes.

## SSI - Surgical Site Infection

- Population: patient with an NHSN operative procedure.
- Window: 30 days post-procedure for most procedures; 90 days for a defined
  subset (largely implant-related). Verify the procedure-specific window in the
  current manual.
- Depth classes: superficial incisional, deep incisional, organ/space.
- Signal inputs: procedure code and date, wound culture, readmission with
  infection diagnosis, antibiotic start post-discharge.

## MDRO - Multidrug-Resistant Organism

- Common tracked organisms: MRSA, VRE, ESBL-producing Enterobacterales, CRE,
  multidrug-resistant Pseudomonas and Acinetobacter.
- LabID event logic: first isolate per patient per defined period; onset
  classified by specimen collection day relative to admission.
- Signal inputs: susceptibility panel, specimen source, collection date,
  admission date, unit history.

## C. difficile Infection (CDI)

- LabID event logic: positive laboratory assay on an unformed stool specimen.
- Onset classification: healthcare facility-onset when the specimen is collected
  on hospital day 4 or later; community-onset otherwise, with a separate
  community-onset healthcare facility-associated category for recent discharges.
- Signal inputs: assay type (NAAT vs toxin EIA), collection day, prior admission
  within the lookback window, laxative administration within 24h (flag, do not
  auto-exclude).

## Key derived metrics

- Device utilization ratio = device days / patient days.
- Infection rate = events / device days x 1000.
- SIR (Standardized Infection Ratio) = observed events / predicted events. An SIR
  is only interpretable when predicted events are at or above the threshold the
  current NHSN methodology requires; below it, report the raw counts instead.

---

# 2. Epidemiology and Outbreak Logic

## Cluster signal (candidate, not conclusion)

Raise a candidate cluster when, within a defined window:

- 2 or more patients,
- same organism (species, and where available matching susceptibility pattern),
- shared exposure: unit, room, procedure, provider, device, or equipment,
- with temporal proximity consistent with the organism's incubation period.

## Analysis dimensions

- Person: age, immune status, device exposure, procedure exposure.
- Place: unit, room, bed, OR suite, dialysis station, equipment ID.
- Time: epidemic curve by onset date, not by result date.

## Escalation

Any candidate cluster involving a high-consequence organism (CRE, Candida auris,
Legionella, TB, measles, or any organism the hospital lists as immediately
reportable) escalates the same day, before analysis is complete.

## Contact tracing scope

Line-list exposure by shared unit and shift, shared procedure room, and shared
reusable equipment. Personnel exposure tracking is Occupational Health's record,
not the surveillance record; hand off rather than duplicate.

---

# 3. Antibiotic Stewardship Support

The agent supports stewardship analytics only. It does not select therapy.

Supported outputs:

- Antibiotic utilization by unit and by agent, expressed as days of therapy per
  1000 patient days.
- Bug-drug mismatch flags: organism resistant on the panel while the matching
  agent remains active on the MAR.
- De-escalation opportunity flags: broad-spectrum agent continuing more than 72
  hours after a narrowing culture result.
- Duplicate therapy flags: overlapping anaerobic or gram-negative coverage.
- Duration outliers versus hospital pathway or IDSA guideline reference.

Every stewardship flag routes to the stewardship pharmacist or physician lead. It
is a discussion prompt, never an order.

---

# 4. Regulatory Compliance

## What the hospital reports

- HAI data flows to CDC NHSN and is used by CMS quality programs (Hospital
  Inpatient Quality Reporting, the Hospital-Acquired Condition Reduction Program,
  and Value-Based Purchasing). Confirm current program inclusion at cms.gov,
  since measure sets are revised by rulemaking each year.
- State health departments carry separate, often stricter, reportable-disease
  requirements with their own timelines. The hospital's reportable-condition list
  is the operative document.

## Accreditation

Joint Commission (or the hospital's chosen accreditor) requires a documented IPC
program, risk assessment, and evidence of corrective action. The agent's audit
records are designed to be usable as that evidence.

## Agent obligations

- Never submit anything to an external registry autonomously.
- Flag suspected reportable conditions to the IP within the same shift.
- Keep a retrievable trail of every alert, its evidence, and its disposition.

---

# 5. Healthcare Operations Context

## Community hospital reality

Assume the deployment target is a 50 to 300 bed community hospital with 0.5 to
2.0 FTE dedicated to infection prevention, no data science staff, a single
vendor EHR, and manual chart review as the current surveillance method.

Design consequence: an alert that costs the IP more than a few minutes to
adjudicate will be ignored. Precision matters more than recall for routine
signals; recall matters more for outbreak signals.

## Where the agent fits in the day

- Morning: overnight micro results reviewed, candidate events line-listed.
- Midday: IP adjudicates the line list; agent records dispositions.
- Weekly: trend and stewardship summary for the quality committee.
- Monthly: NHSN reconciliation packet prepared for IP submission.

## Improvement loop

Every rejected alert is training data for the rule set. Track alert precision by
rule and retire rules that fall below the agreed threshold.
