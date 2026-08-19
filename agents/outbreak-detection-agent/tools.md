# Tools

The Outbreak Detection Agent inherits the four skill-level tools (Data Query,
Guideline Retrieval, Analytics, Reporting) and adds four investigation-specific
tools. Every entry gives purpose, inputs, outputs, and the constraint that keeps
it inside `safety_rules.md`.

---

## Inherited: Data Query Tool

Same contract as in the Infection Surveillance Agent, with a wider scope:

- Longer lookback windows (investigation window, not the 24h sweep)
- Facility feeds: work orders, water management records, air handling logs,
  reprocessing logs, equipment tracking
- Staffing assignment data, restricted to exposure linkage

Constraints:

- Read-only, minimum necessary, PHI hashed at the boundary.
- Staffing data is retrieved as assignment intervals only. Never performance
  records, never disciplinary history, never health information about staff.

---

## Inherited: Guideline Retrieval Tool

Adds outbreak-specific sources: organism-specific CDC containment guidance, the
hospital outbreak response policy, the state reportable-conditions list, and the
EPA registered disinfectant lists.

Constraint: returns a citation with a document version, or returns
`guideline_unavailable`. Never a remembered paraphrase.

---

## Inherited: Analytics Tool

Adds the outbreak calculations: attack rates by exposure group, relative risk,
odds ratio with confidence intervals, and control-chart baselines.

Constraints: numerator and denominator always shown; small cells suppressed; an
inferential statistic is withheld below the minimum case count and replaced with
a descriptive summary.

---

## Inherited: Reporting Tool

Renders the investigation packet and closure summary. Drafts only, no external
transmission, de-identified keys in every distributed artifact.

---

## Line List Tool

Purpose:
Build and maintain the authoritative case list for one investigation.

Inputs: `investigation_id`, `case_definition_version`, `search_window`,
`search_scope` (unit / facility / network).

Outputs: the line list in the field set defined in `workflow.md` Step 4, plus a
diff against the previous version showing added, reclassified, and removed cases.

Constraints:

- De-identified case ids only. The identified crosswalk stays inside the covered
  system and is never included in an export.
- Case classification changes are appended with a reason, never overwritten.
- Every count carries its case definition version.

---

## Epidemic Curve Tool

Purpose:
Render and interpret the time distribution of cases.

Inputs: `investigation_id`, `date_field` (onset preferred, collection as
fallback), `bin_width`, `incubation_period`.

Outputs: the curve, the bin width used, the count of cases using a fallback date,
and a ranked list of compatible patterns (point source, propagated, continuous
common source, mixed) with the evidence for each.

Constraints:

- The pattern is always labeled a hypothesis.
- If more than a stated share of cases use fallback dates, the tool returns the
  curve with a shape-unreliable warning rather than a pattern interpretation.
- Never smooths or reshapes the curve to fit a preferred hypothesis.

---

## Exposure Linkage Tool

Purpose:
Find what the cases share - place, procedure, device, equipment, product lot, or
personnel assignment.

Inputs: `investigation_id`, `dimensions[]`, `exposure_window`.

Outputs: shared-exposure matrix, each candidate link with the number of cases it
covers, the number it fails to explain, and the size of the unaffected exposed
group.

Constraints:

- Always reports how many cases a link does NOT explain. A link covering 3 of 7
  cases is reported as 3 of 7.
- Personnel links are reported as an anonymized assignment pattern (`staff_key_4`)
  and routed to the IP and Occupational Health. No staff name appears in any
  packet, dashboard, or export. The agent draws no conclusion about an individual.
- Coincidence is expected in small populations; every link is reported with the
  base rate of that exposure among non-cases.

---

## Typing Liaison Tool

Purpose:
Track molecular typing requests and file the results into the investigation.

Inputs: `investigation_id`, `isolate_ids[]`, `requested_by` (human), `lab`.

Outputs: request status, turnaround estimate, and, when returned, the laboratory
relatedness interpretation verbatim with its source.

Constraints:

- The agent does not order typing. It prepares the request for the IP to submit
  and tracks it once submitted.
- Relatedness is reported as the laboratory stated it. The agent never derives,
  adjusts, or infers a threshold.
- A result contradicting the working hypothesis is surfaced with the same
  prominence as a confirming one.

---

## Tools deliberately absent

There is no notification tool, no order-entry tool, no bed-management tool, and
no external-transmission tool. Declaring an outbreak, notifying public health,
restricting staff, and closing beds are human actions, and the agent has no
mechanism to perform them.
