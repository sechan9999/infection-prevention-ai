# Workflow Detail

Execution contract for the FDE Deployment Agent. The unit of work is a site; the
unit of value is an agent running in production with a named owner and a
demonstrated effect on the site's own baseline.

---

## Step 1 - Discovery

Structured interview plus system inspection. Output is the site profile
(Template 12), covering systems, integration surface, data availability, people,
workflow, governance, and baseline.

Discovery rules:

- **Ask what is documented, then verify what is real.** A stated interface that
  has never carried a message is not an interface. A policy that exists but is
  not followed is a compliance finding, not a capability.
- **Free text is not a feed.** If the documented indication for an antibiotic
  lives in a progress note, the indication field is absent for capability
  purposes. Extraction from notes may be a later project; it is never assumed at
  discovery.
- **Record data quality defects as facts, not complaints.** "Onset date is
  populated in 40 percent of records" is a design input.
- **Name a person for every feed.** A feed with no owner will not be fixed when
  it breaks.

Discovery does not end until every dimension has an answer, including "unknown" -
an explicit unknown is a valid discovery output and drives a follow-up. A blank
is not.

---

## Step 2 - Capability manifest

For each rule in each of the four agents, intersect its declared feed
requirements with the site data matrix. Every rule lands in exactly one state:

| State | Meaning |
|---|---|
| `enabled` | all required feeds present at adequate quality |
| `degraded-explicit` | runs on a reduced input set, with the limitation printed on every output it produces |
| `disabled-missing-feed` | required feed absent; lists exactly what would enable it |
| `disabled-quality` | feed present but below the quality floor; lists the defect |
| `deferred` | enabled later in the rollout by choice, not by constraint |

`degraded-explicit` is used sparingly and only where a reduced rule is still
honest - for example, a surveillance rule running on collection date because
onset date is unavailable, with every output labeled accordingly. If a reduction
would change what the output means rather than how precise it is, the rule is
disabled instead.

The manifest is presented to the IP as a plain list of what the hospital is
getting and what it is not. This conversation happens at week one, not at
go-live. A capability discovered to be missing at go-live is a failure of this
step.

---

## Step 3 - Site configuration

Build the site config from the profile. It is data, reviewed and approved by the
IP, never code:

```
site_id, tier, timezone, units[], services[], bed_counts
feeds[]:            name, source, transport, latency, quality_notes, owner
rule_config[]:      rule_id, state, thresholds{}, rationale, approved_by
pathways[]:         indication -> duration/agent reference, source doc + version
formulary[]:        restricted agents, approval requirement
requirement_register_seed[]: compliance requirements with citations
routing[]:          finding type -> role, channel, target response time
escalation[]:       condition -> role, hours, after-hours path
suppression[]:      minimum group size, small cell threshold
retention[]:        audit retention period, PHI boundary
capacity[]:         daily worklist cap, alert budget per role per day
```

Configuration rules:

- **Never import another hospital's thresholds.** A peer site's configuration is
  a starting hypothesis to review line by line, never a default to inherit. The
  most common deployment failure is a threshold tuned for a 600-bed academic
  centre firing continuously in a 90-bed community hospital.
- **Every threshold carries a rationale and an approver.** A threshold nobody can
  explain will not be defended when it produces an unwelcome finding.
- **Routing names roles, never individuals**, and every role must have a real
  after-hours path. A route to a role that is unstaffed at 2am is not a route.
- **The alert budget is set before the rules are enabled.** Decide how many items
  per day a 0.5 FTE IP can actually adjudicate, then enable rules up to that
  budget by value. Enabling everything and pruning later trains the team to
  ignore the tool during the exact window when they are forming their opinion of it.

---

## Step 4 - Baseline capture

Before any output is shown to anyone, record:

- Detection latency: first case onset to IP awareness, on retrospective cases
- IP hours per week on case finding and chart review
- Current HAI counts and rates by type and unit
- Antibiotic utilization by agent and unit
- Compliance rates by domain, with observation counts
- Number and type of findings the current manual process produces

This is the only comparison that matters later. Value is always reported against
this hospital's own before, never against a benchmark or another site.

If baseline capture is skipped for schedule reasons, record that it was skipped.
A deployment with no baseline can still be useful, but it can never be shown to
be, and the site should know that going in.

---

## Step 5 - Shadow validation

The agent runs on real data. Its outputs are stored and shown to nobody. The IP
works exactly as before.

Two validation passes:

**Retrospective.** Run against a historical window the IP has already
adjudicated. Compare agent candidates to the IP's determinations:

- Sensitivity against known events - what did it miss, and why
- Positive predictive value - of what it raised, what the IP would have accepted
- Detection latency delta - how much earlier would it have surfaced each case

**Prospective shadow.** Run live for an agreed period, outputs sealed. At the end,
compare against what the IP found independently in the same window.

Every miss is reviewed individually with the IP and classified: missing feed,
threshold too tight, rule gap, or data quality defect. The classification drives
the fix. A miss with no explanation blocks the gate.

Go-live thresholds are agreed **before** validation starts, by the IP, in
writing. Setting them after seeing the results is how a tool talks its way into
production. Typical gate shape - each site sets its own numbers:

| Measure | Gate |
|---|---|
| Missed events the IP found | zero unexplained; each explained miss has an accepted remediation |
| PPV on raised candidates | at or above the agreed floor for the enabled rule set |
| Daily volume | within the alert budget set in Step 3 |
| Latency | demonstrably earlier than baseline, or no worse |

A failed gate is a normal outcome. It means retune and revalidate, not proceed
with caveats.

---

## Step 6 - Staged rollout

Surveillance first, then the others in the order the site's pain justifies -
usually stewardship next where a pharmacist exists, compliance where a survey is
approaching, outbreak last because it depends on surveillance output being
trusted.

At each stage:

- Entry gate passed and recorded, with who passed it
- One agent, one unit or one service first where the site allows it
- A named owner for that agent, not a committee
- A documented rollback: how to turn it off, who can, and what the team reverts
  to. The kill switch is tested during shadow, not discovered during an incident.

**Nothing goes live without a named human owner.** An agent owned by "the
hospital" is owned by nobody, and its findings will age untouched until the
program quietly stops looking at them.

---

## Step 7 - Handover

Deliverables, all reviewed with the receiving team:

- Runbook: what each agent does, what it will never do, how to read every output
- Escalation map: which finding reaches which role, on what clock, after hours too
- Config documentation: every threshold with its rationale and approver
- Failure modes: what a stale feed looks like, what a broken interface looks like,
  what to do when output stops arriving or arrives wrong
- Kill switch: how to disable one rule, one agent, or everything, and who may
- Tuning cadence: who reviews rule precision, how often, with what authority
- Known gaps: the disabled rules and what each would require, carried forward
  from the capability manifest rather than quietly dropped at the end

Handover is complete when the receiving team can explain the tool's limitations
without the deployment team in the room. That is the test - not whether they can
use it, but whether they know what it cannot do.

---

## Step 8 - Post-deployment review

At 30, 90, and 180 days, against the Step 4 baseline:

- Detection latency change
- IP hours reclaimed, and what they were redirected to
- Alert precision and acceptance rate per rule
- Rules retired for low precision, and rules newly enabled
- Feeds that broke and how long that took to notice - if a broken feed went
  unnoticed for a week, the monitoring is the finding
- Whether the disabled-rule list has moved

Report honestly, including no-change and negative results. A deployment that
reclaimed no hours is information the next site needs. Fabricating or softening a
result to protect a rollout is the one failure this agent's own audit trail is
designed to make visible.

---

## Common failure modes

Encoded here because each one has killed a real clinical AI deployment:

| Failure | Prevention in this workflow |
|---|---|
| All four agents at once | Step 6, one at a time, one gate each |
| Go-live without shadow | Step 5, gates agreed in writing beforehand |
| Peer site's thresholds copied in | Step 3, line-by-line review, rationale per threshold |
| Alert fatigue in week one | Step 3, alert budget set before rules are enabled |
| No baseline, no provable value | Step 4, captured before anything is shown |
| No named owner | Step 6, gate condition |
| Silent capability gaps | Step 2, disabled rules listed and carried to handover |
| Feed breaks unnoticed | Step 7 failure modes, Step 8 review |
| Tool blamed for a data problem | Step 1, data quality defects recorded as facts at discovery |
