# Tools

This agent inherits Guideline Retrieval and Reporting from the skill, uses Data
Query in a restricted discovery mode, and adds five deployment tools.

---

## Inherited: Data Query Tool (discovery mode)

Purpose here is to characterize feeds, not to analyze patients.

Constraints specific to this agent:

- Discovery queries return **shape, not content**: row counts, field population
  rates, value distributions, latency measurements, date ranges.
- Where a sample record is genuinely needed to verify a field's meaning, it is
  pulled de-identified, in the minimum quantity, with the reason recorded.
- This agent has no clinical analysis path. It never produces a finding about a
  patient. If discovery surfaces something clinically urgent, it is handed to the
  IP immediately and is not analyzed here.

---

## Inherited: Guideline Retrieval Tool

Used to seed the compliance requirement register and the pathway references in
the site config, always with document version and citation. Returns
`guideline_unavailable` rather than a remembered requirement.

---

## Inherited: Reporting Tool

Renders the site profile, capability manifest, deployment plan, validation
report, and handover pack. Drafts for human review; nothing transmitted
externally.

---

## Site Profiler

Purpose:
Conduct discovery and produce the site profile.

Inputs: `site_id`, `dimension` (systems / integration / data / people / workflow /
governance / baseline), interview responses, system inspection results.

Outputs: profile rows per dimension, each with a value, a source (stated by whom,
or verified how), a confidence, and an owner. Plus an explicit `unknown` list.

Constraints:

- Distinguishes **stated** from **verified** on every row and never promotes one
  to the other without evidence.
- Cannot mark discovery complete while any dimension is blank; `unknown` is a
  valid value, blank is not.
- Records data quality defects as neutral facts with measurements.
- Governance rows are recorded, not judged. BAA status, PHI boundary, and hosting
  posture are documented for the hospital's privacy officer, counsel, and
  security team to rule on. The agent never states that an arrangement is
  compliant.

---

## Capability Manifest Tool

Purpose:
Compute which rules can honestly run at this site.

Inputs: `site_profile`, `rule_registry` (every rule from all four agents with its
declared feed requirements and quality floors).

Outputs: one row per rule with its state (`enabled`, `degraded-explicit`,
`disabled-missing-feed`, `disabled-quality`, `deferred`), the feeds it needs, the
feeds it has, and - for every disabled rule - exactly what would enable it.

Constraints:

- **A rule is never enabled on inferred, substituted, or defaulted data.** If a
  required feed is absent, the rule is disabled. There is no partial-credit path.
- `degraded-explicit` requires the limitation to be printed on every output the
  rule produces, and is refused where the reduction would change what the output
  means rather than how precise it is.
- The disabled list is a permanent deliverable. It appears in the manifest, the
  deployment plan, and the handover pack, and is reviewed at every post-deployment
  checkpoint. It is never dropped for looking bad.

---

## Config Builder

Purpose:
Assemble and version the site configuration.

Inputs: `site_profile`, `capability_manifest`, IP-approved thresholds, pathways,
formulary, routing and escalation tables, suppression and retention settings,
alert budget.

Outputs: versioned site config in the Step 3 field set, a diff against the
previous version, and a validation report listing every unapproved or
unexplained value.

Constraints:

- **Refuses to emit a config containing a threshold with no rationale and no
  approver.**
- Refuses to emit a config whose enabled rule set exceeds the site's stated alert
  budget, and shows which rules would need to be deferred to fit.
- Refuses any value that would loosen `safety_rules.md`. A site may make a
  constraint stricter; nothing makes one looser.
- Peer-site configurations may be loaded as a review baseline only, and every
  inherited value arrives marked `unreviewed` until a site approver clears it.
- Config is data under version control with an approver recorded per change.

---

## Shadow Validation Harness

Purpose:
Measure the configured stack against the IP's own adjudication before anyone
relies on it.

Inputs: `site_config`, `validation_window`, `adjudicated_truth_set`,
`agreed_gates` (recorded with timestamp and approver before the run).

Outputs: sensitivity against known events, PPV of raised candidates, daily
volume against the alert budget, detection latency delta, and a classified miss
list (missing feed / threshold / rule gap / data quality).

Constraints:

- Gates must be recorded **before** the run. The harness refuses to evaluate
  against gates entered after results exist, and the refusal is logged.
- Shadow outputs are sealed from the IP during the prospective run, so the
  comparison is not contaminated by the tool it is testing.
- Every miss carries a classification. Unexplained misses block the gate and
  cannot be waived by this agent.
- Reports the result as measured. There is no path to present a failed gate as a
  conditional pass.

---

## Rollout Tracker

Purpose:
Manage stage progression, gates, ownership, and rollback.

Inputs: `site_id`, `agent`, `stage`, `gate_evidence`, `owner_role`,
`rollback_plan`.

Outputs: stage status per agent, gate evidence with who passed it and when,
named owner per live agent, rollback readiness, and post-deployment metrics
against the captured baseline.

Constraints:

- Stage advancement is a human decision, recorded with a name and a timestamp.
  The tracker records and blocks; it never advances.
- Blocks stage 4 without a named individual owner and a tested kill switch.
- Blocks any stage that would put a second agent live while the previous one is
  still inside its first review window.
- Post-deployment metrics are reported against the site's own baseline, including
  no-change and negative results. There is no path to suppress an unfavorable
  measurement.

---

## Tools deliberately absent

There is no infrastructure provisioning tool, no credential or network
configuration tool, no data migration tool, no contract or BAA tool, and no
compliance attestation tool. Standing up environments, opening network paths,
moving PHI, signing agreements, and certifying compliance are human acts
performed by the hospital's own IT, security, privacy, and legal functions.
