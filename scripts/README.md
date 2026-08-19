# scripts

## conformance.sh

Structural conformance checks for the repository. This is a specification, not a
program - there is nothing to unit test. What can be tested is that every agent
still obeys the architecture.

```bash
bash scripts/conformance.sh
```

Exit code 0 if every check passes, 1 if any fails. Runs in CI on every push and
pull request (`.github/workflows/conformance.yml`).

| ID | Check | Fails when |
|----|-------|-----------|
| C1 | Agent has the AGENT/workflow/tools triple | An agent ships incomplete |
| C2 | AGENT.md frontmatter has name, description, skill, version | An agent will not load |
| C3 | Every agent declares `skill: infection-prevention-fde` | An agent drifts off the shared skill |
| C4 | Every AGENT.md binds `safety_rules.md` | An agent's safety contract is unbound |
| C5 | Every agent declares a boundary / refusal section | An agent has no stated refusal surface |
| C6 | Every defined template has a producing agent | A template is orphaned |
| C7 | Rules carry versioned ids | A rule cannot be tracked or tuned |
| C8 | SKILL.md roster lists every built agent, split from planned | The roster overstates what exists |
| C9 | Agents reference `knowledge.md` (informational) | Never - reported only |
| C10 | Every tools.md enforces cite-or-withhold | An agent may state a guideline from memory |
| C11 | Every agent states patient de-identification | A PHI clause is missing |
| C12 | Template-level prohibitions present | The no-diagnosis or no-staff-name rule is deleted |

C9 is informational and never fails the build: the FDE Deployment Agent performs
no clinical reasoning, so it has no reason to load surveillance definitions.

**Adding a check.** Every check here exists because something drifted, or could.
C6 exists because Template 6 sat orphaned for four commits before a manual review
caught it. When a review finds a class of mistake, add the check rather than
fixing only the instance.
