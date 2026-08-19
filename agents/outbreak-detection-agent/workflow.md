# Workflow Detail

Execution contract for the Outbreak Detection Agent. Steps map 1:1 to `AGENT.md`.
An investigation is a persistent object with a state, not a single run.

---

## Investigation states

| State | Meaning | Agent behavior |
|---|---|---|
| `open-suspected` | trigger fired, not yet verified | steps 1-5, refresh on every new result |
| `open-confirmed` | IP confirms an outbreak exists | full loop, daily packet refresh |
| `monitoring` | control measures applied, no new cases yet | enhanced surveillance only |
| `closed` | closure criteria met and IP signed off | closure summary written, record frozen |
| `rejected` | IP determines no outbreak | reason code recorded, fed to step 12 |

State changes are human decisions. The agent proposes a state change; it never
applies one.

---

## Step 1 - Verify diagnosis and laboratory result

Before counting anything:

- Confirm organism identification is final, not preliminary
- Check for a laboratory error pattern: same analyzer, same run, same batch,
  same collection team, contamination-prone specimen source
- Check for a pseudo-outbreak pattern: a change in test method, assay
  sensitivity, specimen collection practice, or surveillance intensity that
  raises detected cases without raising real cases

A pseudo-outbreak is a finding in its own right. Report it with the same
structure as a real one.

---

## Step 2 - Confirm the outbreak exists

Compare observed cases against expected, using:

- The trailing 12-month baseline for that unit, organism, and event type
- The same calendar period in prior years, where seasonality applies
- The facility-wide rate for the same organism

Report observed, expected, the comparison window, and the denominator. Never
report an increase without the denominator - a rise in cases during a census
drop is a larger rise than it appears; during a census surge, smaller.

Threshold guidance: for organisms normally absent from the unit (C. auris, CRE,
Legionella), expected is effectively zero and a single case clears this step.

---

## Step 3 - Construct the case definition

Four components, all required:

| Component | Example |
|---|---|
| Person | inpatients and patients seen in the outpatient dialysis unit |
| Place | 3W and the 3rd-floor procedure suite |
| Time | admitted or seen between 2026-06-01 and present |
| Clinical/lab criteria | K. pneumoniae isolate, carbapenem-resistant on panel |

Stratified into:

- Confirmed: meets lab criteria plus person/place/time
- Probable: meets clinical criteria plus a strong epidemiologic link, lab pending
- Suspect: meets person/place/time with compatible findings only

Start the definition broad for case finding, then narrow it for hypothesis
testing. Record every revision with a timestamp; recomputed counts always state
which definition version produced them. Never restate a prior count under a new
definition without labeling it.

---

## Step 4 - Case finding and line list

Search beyond the index unit: patients transferred off the unit, discharged
patients readmitted within the lookback, patients sharing the procedure room or
equipment, and prior admissions of the same patients.

Minimum line list fields:

```
case_id (de-identified) | classification (confirmed/probable/suspect)
admission_date | onset_date | culture_collection_date | organism | susceptibility_pattern
unit_history (unit/room/bed by date) | procedures (type, date, room, equipment_id)
devices (type, insert/remove dates) | prior_facility_exposure
outcome | isolation_status | typing_result (when available)
```

Onset date drives all time analysis. Where onset is undocumented, use collection
date and flag the substitution - it shifts the epidemic curve right and can turn
a point source into an apparent propagated pattern.

---

## Step 5 - Descriptive epidemiology

Person: age band, unit, immune status, device exposure, procedure exposure.

Place: a room-and-bed map with case positions and dates, plus shared equipment,
shared procedure rooms, and shared water or air systems.

Time: the epidemic curve, binned by onset date at a bin width of roughly one
quarter to one third of the organism incubation period.

Curve interpretation - offered as a hypothesis, never a conclusion:

| Shape | Suggests | Typical hospital analogue |
|---|---|---|
| Single sharp peak spanning about one incubation period | point source | one contaminated procedure, solution, or product lot |
| Successive peaks about one incubation period apart | propagated | person-to-person transmission |
| Plateau or irregular, sustained | continuous common source | colonized environmental reservoir, water system, shared device |
| Point source with a later tail | point source plus secondary spread | index exposure, then person-to-person |

Attack rate = cases / population at risk, computed per exposure group.

---

## Step 6 - Generate hypotheses

Enumerate candidate transmission routes and score each on plausibility:

- Person-to-person via hands or shared care
- Common device or reusable equipment (reprocessing failure)
- Environmental reservoir (sink drains, ice machines, shower heads, mattresses)
- Water system (Legionella, Pseudomonas, non-tuberculous mycobacteria)
- Air (construction, pressure differential failure, filtration failure)
- Common product or solution (single lot, compounded medication, flush syringe)
- Colonized or infected personnel
- Importation from a referring facility

Reprocessing, water, air, and construction hypotheses require pulling the
corresponding facility logs for the exposure window before the hypothesis is
scored. A hypothesis scored without its log evidence is labeled `unverified`.

---

## Step 7 - Test hypotheses

Design selection:

| Condition | Design | Measure |
|---|---|---|
| Population at risk is enumerable (unit census, procedure log) | retrospective cohort | attack rate ratio / relative risk |
| Population at risk is not enumerable | case-control | odds ratio |
| Fewer than about 5 cases | descriptive only | no inferential statistic |

With small numbers - the normal hospital situation - report the point estimate
with its confidence interval and state plainly that the study is underpowered.
Do not run a battery of comparisons and report the significant one; declare the
tested exposures in advance and report all of them, significant or not.

Every association is reported with the reminder that it is an association.

---

## Step 8 - Reconcile with laboratory and environmental findings

Molecular typing: requested through the IP, from the hospital reference or state
public health laboratory. Relatedness thresholds are organism-specific and set by
that laboratory - the agent reports the laboratory interpretation and never
invents a SNP cutoff. Indistinguishable isolates support a common source;
distinct isolates argue against one and must be shown as contradicting evidence.

Environmental sampling: hypothesis-driven only. Routine or random environmental
culturing is not recommended and produces uninterpretable results (CDC,
Guidelines for Environmental Infection Control in Health-Care Facilities). The
agent may state which surface, device, or water outlet a hypothesis implicates;
the decision to sample belongs to the IP.

Typing that contradicts the epidemiologic hypothesis outranks the hypothesis.
Say so explicitly in the packet.

---

## Step 9 - Control measure options

Present options in the standard hierarchy, each with its evidence, its
operational cost, and its reversibility:

1. Eliminate the source - remove the implicated device, lot, or water outlet
2. Engineering and environmental - terminal cleaning with the correct agent,
   drain remediation, water management corrective action, air or pressure repair,
   construction barrier
3. Administrative - cohorting patients and staff, admission or transfer hold,
   enhanced precautions, contact screening, procedure pause, education, observed
   hand hygiene audit
4. PPE - precaution level appropriate to the transmission route

Disinfectant selection is organism-specific: sporicidal agents for C. difficile,
and the specific EPA-registered lists for C. auris and norovirus. The agent names
the required product class and points to the current EPA registered disinfectant
lists rather than naming a product from memory:
https://www.epa.gov/pesticide-registration/selected-epa-registered-disinfectants

Interventions that stop admissions, close a unit, cancel procedures, or restrict
a staff member are presented as options with their trade-offs. They are never
recommended as a single course of action, and never applied by the agent.

---

## Step 10 - Enhanced surveillance while open

While an investigation is `open-confirmed`:

- Lower the detection threshold for the implicated organism facility-wide
- Add the implicated organism to the daily line list regardless of unit
- Track contacts of each case for the full incubation window of the organism
- Re-run the epidemic curve daily; a new case after control measures is itself a
  finding about the control measures

---

## Step 11 - Closure criteria

Propose closure when all hold:

- No new confirmed cases for two full incubation periods of the organism, or the
  interval hospital policy specifies, whichever is longer
- Control measures are implemented and verified, not merely ordered
- Contact screening, where indicated, is complete
- Environmental or reprocessing corrective actions are verified closed

Closure is proposed, then signed by the IP or the Infection Control Committee.
The agent records who signed and when.

---

## Step 12 - Document and feed back

Write the closure summary (Template 8). Then:

- Record which trigger surfaced the event, and how many days elapsed between the
  first case onset and the investigation opening - this detection latency is the
  number the program is trying to shrink
- If the event was missed by the rule set, propose the rule change to the IP
- If a rule fired correctly, record it as a true positive for that rule precision
  statistic
- If the event was a pseudo-outbreak, record the cause so the same test or
  practice change is recognized next time

Rule changes are proposed to the IP. The agent never edits its own rule set.
