#!/usr/bin/env python3
"""Replay the synthetic CLABSI fixture set against a rule engine.

Two modes:

  lint   (default)  Validate the fixture set itself: schema, archetype coverage,
                    no absolute dates, no identifier-shaped fields. Runs in CI
                    today, needs no engine and no PHI.

  replay            Feed each case to a rule engine and compare its verdict to
                    the expected one. Enabled by setting RULE_ENGINE_CMD to a
                    command that reads one case input as JSON on stdin and
                    writes {"verdict","grade","flags","reason"} as JSON on
                    stdout.

      RULE_ENGINE_CMD="python my_engine.py" python scripts/rule_replay.py

Exit 0 if everything checked passes, 1 otherwise.
"""

import json
import os
import subprocess
import sys

FIXTURES = os.path.join(os.path.dirname(__file__), "..", "fixtures", "clabsi_cases.json")

VERDICTS = {"candidate", "non_candidate", "indeterminate"}
IDENTIFIER_KEYS = {"mrn", "patient_name", "name", "ssn", "chart_no", "admission_date",
                   "birth_date", "dob", "phone", "address"}

GREEN, RED, YELLOW, DIM, OFF = "\033[32m", "\033[31m", "\033[33m", "\033[2m", "\033[0m"
if not sys.stdout.isatty() or os.environ.get("NO_COLOR"):
    GREEN = RED = YELLOW = DIM = OFF = ""


class Results:
    def __init__(self):
        self.passed = 0
        self.failed = 0

    def ok(self, label, detail=""):
        self.passed += 1
        print(f"  {GREEN}PASS{OFF}  {label:<52} {detail}")

    def bad(self, label, detail=""):
        self.failed += 1
        print(f"  {RED}FAIL{OFF}  {label:<52} {detail}")

    def info(self, label, detail=""):
        print(f"  {YELLOW}INFO{OFF}  {label:<52} {detail}")

    def note(self, text):
        print(f"        {DIM}{text}{OFF}")


def lint(doc, r):
    cases = doc.get("cases", [])
    r.ok("fixture file parses", f"{len(cases)} cases")

    # every case carries the full contract
    bad = [c.get("case_id", "?") for c in cases
           if not all(k in c for k in ("case_id", "archetype", "tests", "input", "expected"))]
    if bad:
        r.bad("every case has the required keys", ",".join(bad))
    else:
        r.ok("every case has the required keys", f"{len(cases)}/{len(cases)}")

    # expected verdicts are from the closed set, and grades pair with candidates
    problems = []
    for c in cases:
        exp = c.get("expected", {})
        if exp.get("verdict") not in VERDICTS:
            problems.append(f"{c['case_id']}: verdict {exp.get('verdict')!r}")
        if exp.get("verdict") == "candidate" and not exp.get("grade"):
            problems.append(f"{c['case_id']}: candidate without a grade")
        if exp.get("verdict") != "candidate" and exp.get("grade"):
            problems.append(f"{c['case_id']}: non-candidate carries a grade")
    if problems:
        for p in problems:
            r.note(p)
        r.bad("expected verdicts well formed", f"{len(problems)} problems")
    else:
        r.ok("expected verdicts well formed", f"{len(cases)}/{len(cases)}")

    # the archetypes that matter are all present
    required = set(doc.get("required_archetypes", []))
    present = {c["archetype"] for c in cases}
    missing = required - present
    if missing:
        for m in sorted(missing):
            r.note(f"missing archetype: {m}")
        r.bad("required archetypes covered", f"{len(present & required)}/{len(required)}")
    else:
        r.ok("required archetypes covered", f"{len(required)}/{len(required)}")

    # the six boundary archetypes are the reason this file exists
    boundary = {"secondary_bsi", "repeat_within_rit", "mbi_lcbi",
                "neonate_non_fever_symptoms", "device_day_boundary", "two_bottles_one_draw"}
    have = boundary & present
    if have == boundary:
        r.ok("boundary archetypes present", f"{len(have)}/{len(boundary)}")
    else:
        for m in sorted(boundary - have):
            r.note(f"boundary archetype absent: {m}")
        r.bad("boundary archetypes present", f"{len(have)}/{len(boundary)}")

    # no PHI shapes: relative day offsets only, no identifier-ish keys
    leaks = []
    for c in cases:
        for k, v in c["input"].items():
            if k.lower() in IDENTIFIER_KEYS:
                leaks.append(f"{c['case_id']}: identifier-shaped key {k!r}")
            if k.endswith("_day") and isinstance(v, str):
                leaks.append(f"{c['case_id']}: {k} should be a relative int, got {v!r}")
            if isinstance(v, str) and len(v) == 10 and v[4] == "-" and v[7] == "-":
                leaks.append(f"{c['case_id']}: absolute-looking date in {k!r}")
    if leaks:
        for l in leaks:
            r.note(l)
        r.bad("synthetic-only (no PHI shapes)", f"{len(leaks)} issues")
    else:
        r.ok("synthetic-only (no PHI shapes)", "relative offsets only")

    # case ids unique
    ids = [c["case_id"] for c in cases]
    if len(ids) == len(set(ids)):
        r.ok("case ids unique", f"{len(ids)}")
    else:
        r.bad("case ids unique", "duplicates present")


def replay(doc, cmd, r):
    print()
    print(f"  Replaying against: {cmd}")
    for c in doc["cases"]:
        exp = c["expected"]
        try:
            proc = subprocess.run(cmd, shell=True, input=json.dumps(c["input"]),
                                  capture_output=True, text=True, timeout=30)
        except subprocess.TimeoutExpired:
            r.bad(f"{c['case_id']} {c['archetype']}", "engine timed out")
            continue
        if proc.returncode != 0:
            r.bad(f"{c['case_id']} {c['archetype']}", f"engine exit {proc.returncode}")
            r.note((proc.stderr or "").strip()[:200])
            continue
        try:
            got = json.loads(proc.stdout)
        except json.JSONDecodeError:
            r.bad(f"{c['case_id']} {c['archetype']}", "engine output was not JSON")
            r.note((proc.stdout or "").strip()[:200])
            continue

        diffs = []
        if got.get("verdict") != exp["verdict"]:
            diffs.append(f"verdict {got.get('verdict')!r} != {exp['verdict']!r}")
        if exp.get("grade") and got.get("grade") != exp["grade"]:
            diffs.append(f"grade {got.get('grade')!r} != {exp['grade']!r}")
        missing_flags = [f for f in exp.get("flags", []) if f not in (got.get("flags") or [])]
        if missing_flags:
            diffs.append("missing flags: " + ",".join(missing_flags))

        if diffs:
            r.bad(f"{c['case_id']} {c['archetype']}", diffs[0])
            for d in diffs[1:]:
                r.note(d)
            r.note(f"tests: {c['tests']}")
        else:
            r.ok(f"{c['case_id']} {c['archetype']}", exp["verdict"])


def main():
    with open(os.path.abspath(FIXTURES), encoding="utf-8") as fh:
        doc = json.load(fh)

    r = Results()
    print()
    print("CLABSI fixture replay")
    print()
    lint(doc, r)

    cmd = os.environ.get("RULE_ENGINE_CMD")
    if cmd:
        replay(doc, cmd, r)
    else:
        print()
        r.info("replay", "skipped - set RULE_ENGINE_CMD to enable")
        r.note("lint-only mode. The fixtures are validated; no engine was exercised.")

    print()
    colour = GREEN if r.failed == 0 else RED
    print(f"{colour}{r.passed} checks passed, {r.failed} failed{OFF}")
    print()
    return 1 if r.failed else 0


if __name__ == "__main__":
    sys.exit(main())
