# Tools

Inherits the four skill-level tools and adds five education-specific ones.

---

## Inherited: Data Query Tool (pattern mode)

Reads finding patterns and aggregate workforce data, not patients.

Constraints specific to this agent:

- Findings arrive already de-identified from the producing agent. This agent has
  no patient-level access and no reason for any.
- Training, competency, and completion records are retrieved as **aggregate rates
  by role and unit only**. Individual records are never returned to this agent's
  reasoning context, and a request that could only be answered with them returns
  `requires_human_review`.
- Groups below the minimum size are rolled up before the data reaches the agent,
  not after.

---

## Inherited: Guideline Retrieval Tool

The tool this agent leans on hardest, because every clinical statement in a brief
must be traceable.

Constraints:

- Returns requirement text with document, version, and section, or returns
  `guideline_unavailable`.
- A teaching point whose source cannot be retrieved is **dropped from the brief**,
  not written from memory. Wrong education propagates further than a wrong alert:
  staff carry it to other units and other employers.
- Where hospital policy and external guidance conflict, both are returned and the
  conflict is surfaced to the IP. Teaching material never resolves a conflict.

---

## Inherited: Analytics Tool

Finding-rate comparisons before and after delivery, reach by role and shift, and
recurrence detection. Numerator and denominator always shown; small cells
suppressed; no unit ranking or league table is produced.

---

## Inherited: Reporting Tool

Renders briefs, bulletins, and effectiveness reviews. Drafts only, review gate
enforced, no delivery path, no staff names.

---

## Cause Triage Tool

Purpose:
Decide whether a finding pattern is a knowledge gap before any content exists.

Inputs: `finding_pattern`, `prior_education[]`, `corrective_action_history`,
`supply_and_equipment_evidence`, `workflow_timing_evidence`.

Outputs: cause classification (`knowledge` / `system` / `workflow` /
`documentation` / `mixed`), the evidence for it, confidence with its basis, and -
where uncertain - the single observation that would resolve it.

Constraints:

- **Refuses to emit an education brief for a `system` or `workflow` cause.** It
  emits a refusal brief naming the actual cause and the agent it routes back to.
- Never defaults to `knowledge`. Uncertainty is reported as uncertainty.
- A topic previously taught with no movement in the finding rate cannot be
  classified `knowledge` again without new evidence; the tool flags the prior
  attempt and requires the triage to be re-argued.

---

## Audience Segmentation Tool

Purpose:
Determine who performs the behavior and how to reach them.

Inputs: `finding_pattern`, `roles[]`, `units[]`, `shifts[]`, `minimum_group_size`.

Outputs: target segments with the count in each, reach path per segment (huddle,
job aid, onboarding), and coverage gaps - the segments no existing delivery
channel reaches.

Constraints:

- Role, unit, and shift only. **No individual-level output mode exists.**
- Segments below the minimum size roll up.
- Night, weekend, agency, and contracted staff are enumerated explicitly, because
  they are the routine coverage gap.
- Targets the role that performs the action, which is frequently not the role the
  finding was written against.

---

## Content Drafting Tool

Purpose:
Draft a brief in the fixed five-part structure.

Inputs: `behavior`, `cause_evidence`, `audience_segment`, `format`,
`reading_level`, `languages[]`.

Outputs: the brief, its content version, every citation with document version,
and a list of any points dropped for lack of a retrievable source.

Constraints:

- One behavior per brief. A request covering several returns several briefs.
- Every clinical statement carries a citation, or it is dropped and listed as
  dropped.
- No blame framing, no unit-shaming statistics, no recognizable case.
- Output is marked DRAFT and cannot lose that marker without a recorded human
  review.

---

## Delivery Planning Tool

Purpose:
Produce an executable plan, sized to the time that exists.

Inputs: `segments[]`, `format`, `available_education_time`, `shift_patterns`,
`teachable_moment`.

Outputs: delivery plan per segment, the named role who delivers, total staff time
consumed, timing rationale, and any reinforcement schedule.

Constraints:

- **No delivery path.** The tool plans; people schedule and teach.
- Refuses to emit a plan whose total staff time exceeds the stated available
  time, and shows what would have to be cut to fit.
- Defaults to the shortest format that carries the message.

---

## Effectiveness Tool

Purpose:
Measure whether the behavior changed.

Inputs: `content_version`, `delivery_dates`, `target_behavior`,
`measurement_window`, `baseline_period`.

Outputs: finding rate before and after with denominators, recurrence count,
reach by segment, completion rate, and a co-occurring-changes list for the same
period.

Constraints:

- **Completion rate is never reported alone.** It always appears beside the
  finding-rate change, because a completed module with an unchanged finding rate
  is a failed intervention.
- Reports co-occurring changes - supply, staffing, construction, policy - so a
  rate movement is not silently attributed to the teaching.
- No-change and negative results are reported plainly, and route back to the
  Cause Triage Tool for re-argument rather than to a second round of the same
  content.

---

## Tools deliberately absent

There is no delivery, scheduling, assignment, or notification tool; no competency
attestation tool; no individual training-gap report; and no patient education
tool. Teaching, scheduling, attesting competency, addressing an individual, and
educating patients are human acts or out of scope entirely, and the agent has no
mechanism for any of them.
