# fixtures

Synthetic boundary cases for HAI rule-engine regression testing. No real
patients, no PHI, relative day offsets only (day 0 = culture collection day).

## clabsi_cases.json

Eleven cases. Five are the typical archetypes any engine handles; six are the
boundaries where CLABSI engines actually fail.

| Case | Archetype | What it catches |
|---|---|---|
| C-001 | pathogen_typical | happy path |
| C-002 | commensal_two_sets_symptomatic | auto-rejecting a common commensal as contamination |
| C-003 | not_line_associated | line removed before the event |
| C-004 | line_dates_missing | defaulting instead of going indeterminate |
| C-005 | commensal_single_set_asymptomatic | the easy true negative |
| **C-006** | secondary_bsi | the largest real-world false-positive source |
| **C-007** | repeat_within_rit | silent double-counting |
| **C-008** | mbi_lcbi | a separate NHSN category counted as CLABSI |
| **C-009** | neonate_non_fever_symptoms | fever-only symptom logic missing infants |
| **C-010** | device_day_boundary | a 48-hour clock instead of the calendar-day rule |
| **C-011** | two_bottles_one_draw | `set_count >= 2` instead of separate occasions |

An engine that passes C-001 to C-005 and fails C-006 to C-011 is the normal
first result. That is what the fixture set is for: those six are invisible
without them, and each one is a wrong number in an annual report.

## Running

```bash
python scripts/rule_replay.py                     # lint the fixtures (CI default)
RULE_ENGINE_CMD="python my_engine.py" python scripts/rule_replay.py   # replay
```

The engine command reads one case `input` object as JSON on stdin and writes
`{"verdict","grade","flags","reason"}` as JSON on stdout. `verdict` is one of
`candidate` / `non_candidate` / `indeterminate`.

Lint mode runs with no engine and no data, so the fixture set stays valid
even before an engine exists.

## Definitions

Expected verdicts follow NHSN CLABSI/LCBI surveillance logic as of this file's
authorship, recorded in `definition_sources` inside the JSON. **These definitions
are revised annually.** Before treating a fixture failure as an engine defect,
re-verify the case against the current NHSN Patient Safety Component Manual and
the hospital's own policy. Where a national program also applies (KONIS in
Korea, for example), declare which is authoritative for which purpose and
version-lock both - they are not interchangeable.

When a definition changes, the fixture is what gets updated first, and the
engine follows.
