# Tools

Inherits the four skill-level tools (Data Query, Guideline Retrieval, Analytics,
Reporting) and adds four compliance-specific tools.

---

## Inherited: Data Query Tool

Same read-only, minimum-necessary, PHI-hashed contract, with compliance scope
added: audit records, EVS and sterile processing logs, facilities work orders,
training and immunization records, and the policy library.

Constraints specific to this agent:

- Patient records are retrieved de-identified, minimum-necessary, with PHI hashed
  at the boundary - the same contract as the other four agents. Clinical fields
  are pulled only to verify a requirement, never for clinical analysis.
- Staff-linked records (training, fit test, immunization) are retrieved as
  aggregate counts by role and unit. Individual records are never returned to the
  agent's reasoning context - only completion rates and expiry counts.
- Where a compliance question can only be answered with individual-level data,
  the tool returns `requires_human_review` and the question goes to the IP.

---

## Inherited: Guideline Retrieval Tool

The most heavily used tool in this agent. Sources: hospital policy library first,
then accreditor standards, CMS conditions of participation, OSHA standards, CDC
guidelines, EPA registered disinfectant lists, and manufacturer IFUs.

Constraints:

- Returns requirement text with document, version, and section, or returns
  `guideline_unavailable`. A requirement is never paraphrased from memory into
  the register.
- Standard numbering and regulatory citations are reported as retrieved, with
  their effective date, because they are revised on their own schedules.
- Where hospital policy and external standard conflict, both are returned and the
  conflict is surfaced. The agent does not resolve it.

---

## Inherited: Analytics Tool

Adds compliance rates with observation counts, trend against target, recurrence
detection, and corrective action aging.

Constraints: numerator and denominator always shown; groupings below the minimum
group size suppressed and rolled up - which protects patients as well as staff;
observed rates always labeled with observer type and coverage.

---

## Inherited: Reporting Tool

Renders rounds packs, domain reviews, deadline status, and the readiness
snapshot. Drafts only, no external transmission, no staff names, de-identified
patient keys throughout, no compliance score.

---

## Requirement Register Tool

Purpose:
Maintain the authoritative list of what the hospital is required to do, and where
the evidence for each requirement lives.

Inputs: `domain`, `source_filter`, `owner_role`, `status`.

Outputs: register rows in the Step 1 field set, plus a coverage summary showing
requirements with no owner, no monitoring method, or no evidence location.

Constraints:

- Every row carries a citation with a document version. Rows the agent cannot
  cite are marked `source_unverified` and cannot be used to raise a finding until
  the IP confirms them.
- The agent proposes rows; the IP approves them. An unapproved row is visible but
  inert.
- Stricter hospital policy overrides the external standard as the operative
  requirement; policy weaker than the standard raises a `requirement-gap`.

---

## Practice Verification Tool

Purpose:
Compare a required practice against operational data, and classify what kind of
gap any difference represents.

Inputs: `requirement_id`, `period`, `scope` (unit / shift / service / process).

Outputs: evidence summary, computed rate with its denominator, gap class
(`practice` / `documentation` / `evidence` / `requirement` / `timeliness`), and,
where the class is ambiguous, the specific data point that would resolve it.

Constraints:

- Never guesses between a practice gap and a documentation gap. Ambiguity is
  reported as ambiguity, with the resolving data point named.
- Never infers compliance from the absence of a bad outcome. No CLABSI last month
  is not evidence that line insertion practice met the bundle.
- Results are aggregate. The tool has no individual-level output mode.

---

## Corrective Action Tracker

Purpose:
Follow a finding from raised to verified closed, and detect when a fix did not
hold.

Inputs: `finding_id`, `action_id`, `state`, `owner_role`, `due_date`.

Outputs: action register with age in state, overdue flags, verification evidence
attached to each closure, and a recurrence list showing findings that returned
after a verified closure.

Constraints:

- Only a human moves an action's state. The agent records, ages, and re-measures.
- `verified-closed` requires attached post-fix evidence. The tool refuses to
  accept a closure with no verification evidence and records the refusal.
- Recurrence after verified closure raises a new finding about the corrective
  action process itself, routed to Quality.

---

## Deadline Watch Tool

Purpose:
Track every clock the infection prevention program is running against.

Inputs: `deadline_type` (reportable condition / NHSN submission / policy review /
competency / fit test / water management task), `lookahead_window`.

Outputs: each item with its deadline, the source that sets it, days remaining,
current status, and the owner role.

Constraints:

- Prepares packages; never submits, notifies, attests, or signs.
- A missed deadline is reported on the day it is missed, plainly, to the IP.
  There is no roll-forward, no soft language, and no suppression path.
- Deadline values are retrieved with their source, never assumed - state
  reporting windows and NHSN deadlines differ and change.

---

## Tools deliberately absent

There is no record-generation tool, no attestation tool, no external-submission
tool, no surveyor-facing document builder, and no individual performance report.
Creating a compliance record, attesting to compliance, submitting to a regulator,
and addressing an individual's practice are human acts, and the agent has no
mechanism to perform any of them.
