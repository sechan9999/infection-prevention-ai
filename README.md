# infection-prevention-ai

A Skill + Agent architecture for hospital infection prevention.

The premise: a community hospital runs infection prevention on 0.5 to 2.0 FTE and
manual chart review. The bottleneck is not clinical judgment, it is the hours
spent finding the cases that deserve judgment. This repo packages that first pass
as an AI skill and the agents built on top of it.

**The AI does not replace infection prevention professionals.** Every output is a
candidate finding routed to a named human for approval, with its evidence and an
audit record attached.

---

## Structure

```
infection-prevention-ai/
│
├── skills/
│   └── infection-prevention-fde/
│       ├── SKILL.md            # principles, reasoning workflow, output contract
│       ├── knowledge.md        # surveillance definitions, epi logic, regulatory context
│       ├── safety_rules.md     # hard constraints (override everything else)
│       └── output_templates.md # fixed output shapes + audit record schema
│
└── agents/
    ├── infection-surveillance-agent/
    │   ├── AGENT.md            # role, mission, data sources, boundaries
    │   ├── workflow.md         # run modes, rule set, routing, feedback loop
    │   └── tools.md            # tool contracts and their constraints
    │
    ├── outbreak-detection-agent/
    │   ├── AGENT.md            # triggers, agent chain position, boundaries
    │   ├── workflow.md         # 12-step investigation, states, closure criteria
    │   └── tools.md            # inherited + line list, epi curve, linkage, typing
    │
    ├── antibiotic-stewardship-agent/
    │   ├── AGENT.md            # 14 flag types, program context, the hard line
    │   ├── workflow.md         # worklist assembly, ranking, AU/AR tracking
    │   └── tools.md            # inherited + worklist, bug-drug, utilization, antibiogram
    │
    ├── policy-compliance-agent/
    │   ├── AGENT.md            # 14 domains, the non-punitive constraint
    │   ├── workflow.md         # requirement register, gap classes, CA tracking
    │   └── tools.md            # inherited + register, verification, CA tracker, deadlines
    │
    └── fde-deployment-agent/
        ├── AGENT.md            # site profile dimensions, tiers, rollout stages
        ├── workflow.md         # discovery, manifest, baseline, shadow, handover
        └── tools.md            # profiler, manifest, config builder, harness, tracker
```

The first four agents run the hospital's infection prevention work. The fifth
configures them for a specific hospital and proves they work there before anyone
depends on them.

## The agent chain

```
                FDE Deployment Agent
   profiles the site · computes the capability manifest
   validates in shadow · stages the rollout to a named owner
                         |
                    configures
                         v
                     Infection Prevention FDE Skill
      evidence first · human in the loop · auditability · safety rules
                                 |
     +-------------+-------------+-------------+-------------+
     |             |                           |             |
 Surveillance      Outbreak              Stewardship     Policy Compliance
 "is something     "what is it, how      "is this        "does practice
  here?"            is it spreading,      therapy still   match policy and
     |              has it stopped?"      the right one   regulation?"
     |                   |                to ask about?"        |
     |  cluster          |                      |               |
     +----candidate----->|                      |               |
     |                   |                      |               |
     v                   v                      v               v
 Infection          IP / Infection         Stewardship      IP / Quality /
 Preventionist      Control Committee      Pharmacist +     Infection Control
 adjudicates        declare · monitor      Physician Lead   Committee
 the line list      close · reject         accept · decline reach the conclusion
```

Surveillance runs continuously and cheaply. Investigation opens only on an
accepted candidate or a human report. Stewardship runs daily against every
patient on an antimicrobial. Compliance runs against the requirement register.
None of the four decides anything - each one terminates at a named human role.

The skill is the reusable layer. Agents are thin: they declare a mission, a data
scope, and a routing table, and inherit reasoning and safety from the skill.

---

## Core guarantees

| Principle | What it means in the output |
|---|---|
| Evidence first | Every finding names its data source, guideline, and confidence number |
| Human in the loop | Every finding names the role that must approve it before anything happens |
| Auditability | Every finding writes an immutable JSON audit record |
| Hospital customization | Rules and thresholds are configuration, not code |

Capability is derived from data, never assumed. A rule whose required feeds are
unavailable at a site is disabled and shown as disabled - never silently degraded
into a version that runs on partial data. A hospital that can support 9 of 34
rules gets 9 rules and an honest list of the 25 it does not have.

Hard limits, enforced in `safety_rules.md`: no diagnosis, no prescribing, no
treatment changes, no clinician override, no hidden uncertainty, no PHI leaving
the covered environment, no autonomous submission to any registry.

---

## Usage with Claude Code

Both files are plain Markdown with YAML frontmatter, so they load directly:

```bash
mkdir -p ~/.claude/skills ~/.claude/agents
cp -r skills/infection-prevention-fde ~/.claude/skills/
cp agents/infection-surveillance-agent/AGENT.md ~/.claude/agents/infection-surveillance-agent.md
cp agents/outbreak-detection-agent/AGENT.md ~/.claude/agents/outbreak-detection-agent.md
cp agents/antibiotic-stewardship-agent/AGENT.md ~/.claude/agents/antibiotic-stewardship-agent.md
cp agents/policy-compliance-agent/AGENT.md ~/.claude/agents/policy-compliance-agent.md
cp agents/fde-deployment-agent/AGENT.md ~/.claude/agents/fde-deployment-agent.md
```

Then invoke the skill by name, or ask a surveillance question and let the
description trigger it.

For any other agent framework, `SKILL.md` is the system prompt, `safety_rules.md`
is the non-negotiable prefix, and `output_templates.md` is the response schema.

---

## Conformance

This repo is a specification, so there is nothing to unit test. What is tested is
that every agent still obeys the architecture - inherits the one skill, binds the
safety rules, declares a refusal surface, and produces only templates the skill
defines.

```bash
bash scripts/conformance.sh
```

Twelve checks, run in CI on every push and pull request. See
[scripts/README.md](scripts/README.md) for what each one catches and why it
exists.

Rule engines get a second suite: `fixtures/clabsi_cases.json` holds eleven
synthetic CLABSI cases with expected verdicts - five typical, six boundary
(secondary BSI, repeat-within-RIT, MBI-LCBI, infant symptom criteria, device-day
boundary, two-bottles-one-draw).

```bash
python scripts/rule_replay.py                                        # lint fixtures
RULE_ENGINE_CMD="python my_engine.py" python scripts/rule_replay.py  # replay
```

No PHI and no engine required to run it, so rule regressions are catchable before
a hospital deployment exists. See [fixtures/README.md](fixtures/README.md).

---

## Roadmap

**Phase 1 - done**
- Infection Prevention FDE Skill
- Infection Surveillance Agent

**Phase 2 - done**
- Outbreak Detection Agent
- Antibiotic Stewardship Agent
- Policy Compliance Agent

**Phase 3 - done**
- FDE Deployment Agent: profiles a hospital's EHR, workflow, and staffing, then
  configures the stack for that environment, validates it in shadow mode against
  the IP's own adjudication, and stages the rollout to a named owner

---

## Scope and disclaimer

This is a decision-support scaffold, not a medical device and not a certified
NHSN reporting system. Surveillance definitions summarized in `knowledge.md`
change annually; the current CDC NHSN Patient Safety Component Manual and the
hospital's own policy are the authority for any event that is counted, reported,
or submitted.

References: [CDC NHSN](https://www.cdc.gov/nhsn/) ·
[CMS](https://www.cms.gov/) ·
[WHO IPC](https://www.who.int/teams/integrated-health-services/infection-prevention-control) ·
[IDSA guidelines](https://www.idsociety.org/practice-guideline/practice-guidelines/)
