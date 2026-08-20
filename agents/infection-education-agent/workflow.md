# Workflow Detail

Execution contract for the Infection Education Agent. The unit of work is an
education brief; the unit of value is a finding rate that drops and stays down.

---

## Run modes

| Mode | Trigger | Output |
|---|---|---|
| Pattern review | monthly, over accumulated findings | triage results, briefs for confirmed knowledge gaps |
| Event-driven | outbreak closure, or a recurring finding after a verified corrective action | targeted brief |
| Guideline change | a policy or guideline takes effect | bulletin, timed to the effective date |
| Onboarding | new-hire cadence | role-scoped onboarding content |
| Effectiveness review | 30 and 90 days after a delivery | Template 17 |

---

## Step 1 - Assemble the pattern

Education responds to a pattern, not a single finding. Collect, per candidate
topic:

- The findings involved, their units, shifts, roles, and dates
- Whether the pattern recurred after a verified corrective action
- What was already taught on this topic, when, to whom, and in what version
- Aggregate competency completion for the relevant role and unit

A single finding is not a pattern. A single finding that recurs after a verified
fix is.

If this topic was taught within the last cycle and the finding rate did not move,
that is the finding: repeating the same content is the least likely thing to
work, and Step 2 must re-run rather than reissue.

---

## Step 2 - Triage the cause

Before any content is drafted, classify the cause. This is the gate the rest of
the workflow depends on.

Evidence to weigh:

| Signal | Points toward |
|---|---|
| Staff can state the requirement when asked, but the practice differs | system or workflow |
| The correct action requires materials that are absent or badly placed | system |
| The correct action takes materially longer than the incorrect one | workflow |
| The practice occurred but the record lacks a field for it | documentation |
| The requirement changed recently and the change was not communicated | knowledge |
| New staff, agency staff, or a role that never received the content | knowledge |
| The reason behind the rule is not known, so it is skipped under pressure | knowledge |

Rules:

- Uncertain triage is reported as uncertain, with the one observation that would
  resolve it. It is never defaulted to `knowledge` because education is the
  easiest thing to produce.
- A `system` or `workflow` cause produces a refusal brief naming the actual cause
  and routing it back. The agent does not soften this into "education plus
  process review" when the knowledge component is absent.
- A `mixed` cause produces education for the knowledge portion only, and states
  plainly that the education will not close the finding on its own.

---

## Step 3 - Segment the audience

Segment by **role, unit, and shift**. Never by individual.

- Teach the role that performs the action, not the role that gets blamed for it.
  Environmental services, sterile processing, transport, and agency staff are
  routinely the right audience and routinely the last to be asked.
- Night and weekend shifts receive their own delivery plan. Content that only
  exists at a Tuesday day-shift huddle has not reached half the workforce.
- Groups below the minimum size roll up to the next level.
- Where a pattern is concentrated in one unit, teach that unit first, and say
  explicitly whether facility-wide delivery is warranted or would be noise.

---

## Step 4 - Draft the content

Structure of every brief, in this order:

1. **The behavior** - one specific action, stated in the words of the person doing it
2. **The reason** - the mechanism, not the rule number. People retain why
3. **What good looks like** - the concrete, observable version
4. **The common failure** - the actual pattern from the findings, de-identified
5. **The citation** - guideline or policy, with version and section

Constraints:

- One behavior per brief.
- Every clinical statement carries a citation. If the source cannot be retrieved,
  the statement is dropped - never written from memory.
- Where hospital policy and external guidance differ, the conflict goes to the IP.
  Teaching material never resolves it.
- Plain language, at the reading level of the workforce, in the languages the
  workforce uses.
- No blame framing, no statistics that identify a unit as the worst performer, no
  before-and-after that names anyone.

---

## Step 5 - Plan delivery

Produce a plan the hospital can actually execute:

- Format matched to the time that exists (see AGENT.md), defaulting to shortest
- The teachable moment: at onboarding, immediately after an outbreak closure,
  before a policy takes effect, or at the point of care - not the annual cycle
- Who delivers it: named role, not "education"
- Total staff time consumed, stated up front, so the IP can weigh it
- How reinforcement happens, if the behavior needs more than one exposure

The agent produces the plan. It does not schedule, assign, publish, or deliver
anything.

---

## Step 6 - Human review gate

Every brief is reviewed before delivery by the Infection Preventionist or a
clinical educator, who checks:

- Clinical accuracy against the cited source
- Consistency with current hospital policy
- Tone: addresses the practice, not the practitioner
- Nothing identifying: no unit shaming, no individual, no case recognizable to
  the people in the room

The reviewer's corrections are recorded against the content version. Unreviewed
content is never delivered, and the agent has no path to deliver it.

---

## Step 7 - Measure the effect

**Completion rate is not effectiveness.** A 100% completion rate with an
unchanged finding rate means the education did not work, and reporting the former
without the latter is how programs convince themselves otherwise.

Measure, at 30 and 90 days:

| Measure | Source |
|---|---|
| Finding rate for the specific behavior, before vs after | compliance agent |
| Recurrence after the verified corrective action | compliance agent |
| Related event rate, where the behavior plausibly connects | surveillance agent |
| Reach: proportion of the target role and shift actually exposed | delivery records |
| Completion rate | training records - reported, but never alone |

Attribution honesty: infection rates move for many reasons, and an education
brief is rarely the largest. Report the change alongside what else happened in
the period - a supply change, a staffing change, a construction project - and
resist claiming credit the data cannot support. If the finding rate did not move,
say so plainly and return to Step 2; the original triage may have been wrong.

---

## Step 8 - Feedback loop

Quarterly:

- Proportion of findings triaged as `knowledge` versus `system` or `workflow` -
  a program where almost everything is a knowledge gap is triaging badly
- Topics taught repeatedly without the finding rate moving - these are almost
  always misclassified system problems
- Reach gaps by shift and role, especially agency and night staff
- Content versions superseded by guideline changes and needing reissue
- Refusal briefs that were overridden, and what happened afterward

Content, cadence, and format changes are proposed to the IP and the educator. The
agent does not change the curriculum on its own.
