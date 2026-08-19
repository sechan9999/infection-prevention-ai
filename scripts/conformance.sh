#!/usr/bin/env bash
# Structural conformance checks for the infection-prevention-ai repository.
#
# This repo is a specification, not a program: there is nothing to unit test.
# What can be tested is that every agent still obeys the architecture - it
# inherits the one skill, binds the safety rules, declares an explicit refusal
# surface, and produces only templates the skill actually defines.
#
# C6 exists because Template 6 sat orphaned for four commits before a manual
# check caught it. Every check below is here because something drifted, or
# could.
#
# Usage:  ./scripts/conformance.sh          from the repository root
# Exit:   0 all checks pass, 1 any check fails

set -uo pipefail
cd "$(dirname "$0")/.." || exit 1

SKILL_DIR="skills/infection-prevention-fde"
TEMPLATES="$SKILL_DIR/output_templates.md"
SKILL_MD="$SKILL_DIR/SKILL.md"
AGENT_DIRS=(agents/*/)
AGENT_COUNT=${#AGENT_DIRS[@]}

pass=0; fail=0

if [ -t 1 ] && [ -z "${NO_COLOR:-}" ]; then
  G=$'\033[32m'; R=$'\033[31m'; Y=$'\033[33m'; D=$'\033[2m'; N=$'\033[0m'
else
  G=""; R=""; Y=""; D=""; N=""
fi

ok()   { pass=$((pass+1)); printf "  %sPASS%s  %-4s %-52s %s\n" "$G" "$N" "$1" "$2" "$3"; }
bad()  { fail=$((fail+1)); printf "  %sFAIL%s  %-4s %-52s %s\n" "$R" "$N" "$1" "$2" "$3"; }
info() {              printf "  %sINFO%s  %-4s %-52s %s\n" "$Y" "$N" "$1" "$2" "$3"; }
note() {              printf "        %s%s%s\n" "$D" "$1" "$N"; }

# assert <id> <label> <actual> <expected>
assert() {
  if [ "$3" = "$4" ]; then ok "$1" "$2" "$3/$4"; else bad "$1" "$2" "$3/$4"; fi
}

echo
echo "Structural conformance - infection-prevention-ai"
echo "Agents found: $AGENT_COUNT"
echo

# --- C1: every agent directory has the AGENT/workflow/tools triple -----------
n=0
for d in "${AGENT_DIRS[@]}"; do
  [ -f "$d/AGENT.md" ] && [ -f "$d/workflow.md" ] && [ -f "$d/tools.md" ] && n=$((n+1)) \
    || note "missing a triple file: $d"
done
assert C1 "agent has AGENT/workflow/tools triple" "$n" "$AGENT_COUNT"

# --- C2: AGENT.md frontmatter carries all four keys --------------------------
n=0; expected=$((AGENT_COUNT * 4))
for d in "${AGENT_DIRS[@]}"; do
  for k in "name:" "description:" "skill:" "version:"; do
    if head -12 "$d/AGENT.md" | grep -q "^$k"; then n=$((n+1));
    else note "frontmatter missing '$k' in $d/AGENT.md"; fi
  done
done
assert C2 "AGENT.md frontmatter keys present" "$n" "$expected"

# --- C3: every agent inherits the one skill ----------------------------------
n=$(grep -h "^skill: infection-prevention-fde" agents/*/AGENT.md 2>/dev/null | wc -l | tr -d ' ')
assert C3 "declares skill: infection-prevention-fde" "$n" "$AGENT_COUNT"

# --- C4: every agent binds the safety rules ----------------------------------
n=0
for d in "${AGENT_DIRS[@]}"; do
  grep -q "safety_rules" "$d/AGENT.md" && n=$((n+1)) || note "no safety_rules binding: $d/AGENT.md"
done
assert C4 "AGENT.md binds safety_rules.md" "$n" "$AGENT_COUNT"

# --- C5: every agent states an explicit refusal surface ----------------------
n=0
for d in "${AGENT_DIRS[@]}"; do
  if grep -hqE '^(# Boundaries|## Tools deliberately absent|# The line this agent does not cross|# The non-punitive constraint)$' "$d"*.md
  then n=$((n+1)); else note "no boundary/refusal section: $d"; fi
done
assert C5 "declares a boundary / refusal section" "$n" "$AGENT_COUNT"

# --- C6: every template the skill defines is produced by some agent ----------
defined=$(grep -c '^## Template [0-9]' "$TEMPLATES")
orphans=""
matched=0
for i in $(grep -o '^## Template [0-9]\+' "$TEMPLATES" | grep -o '[0-9]\+'); do
  if grep -hqE "Templates? ([0-9]+, )*([0-9]+ and )?$i\b|Templates? $i\b|Templates ([0-9]+, )*$i," agents/*/*.md
  then matched=$((matched+1)); else orphans="$orphans $i"; fi
done
[ -n "$orphans" ] && note "orphaned templates (defined, produced by no agent):$orphans"
assert C6 "every defined template has a producing agent" "$matched" "$defined"

# --- C7: rules carry versioned ids -------------------------------------------
rules=$(grep -hoE '^\| [RS]-[A-Z]+-[0-9]+' agents/*/workflow.md 2>/dev/null | wc -l | tr -d ' ')
if [ "$rules" -gt 0 ]; then ok C7 "rules carry versioned ids" "$rules found";
else bad C7 "rules carry versioned ids" "0 found"; fi

# --- C8: SKILL.md roster separates built from planned, and built is accurate --
if grep -q "^Built and in this repository:" "$SKILL_MD" && grep -q "^Planned, not yet built:" "$SKILL_MD"; then
  n=0
  for d in "${AGENT_DIRS[@]}"; do
    name=$(basename "$d")
    grep -q "agents/$name/" "$SKILL_MD" && n=$((n+1)) || note "built agent absent from SKILL.md roster: $name"
  done
  assert C8 "SKILL.md roster lists every built agent" "$n" "$AGENT_COUNT"
else
  bad C8 "SKILL.md roster splits built from planned" "missing heading"
fi

# --- C9: agents reference knowledge.md for clinical definitions --------------
# Informational: the deployment agent performs no clinical reasoning and has no
# reason to load surveillance definitions. Reported, never failed.
n=0
for d in "${AGENT_DIRS[@]}"; do grep -q "knowledge.md" "$d/AGENT.md" && n=$((n+1)); done
info C9 "references knowledge.md (clinical agents only)" "$n/$AGENT_COUNT"

# --- C10: every tools.md enforces cite-or-withhold ----------------------------
n=0
for d in "${AGENT_DIRS[@]}"; do
  grep -q "guideline_unavailable" "$d/tools.md" && n=$((n+1)) || note "no cite-or-withhold contract: $d/tools.md"
done
assert C10 "tools.md enforces cite-or-withhold" "$n" "$AGENT_COUNT"

# --- C11: every agent states patient de-identification ------------------------
n=0
for d in "${AGENT_DIRS[@]}"; do
  grep -qi "de-identif" "$d"*.md && n=$((n+1)) || note "no de-identification statement: $d"
done
assert C11 "states patient de-identification" "$n" "$AGENT_COUNT"

# --- C12: no output contract may carry a diagnosis, order, or staff name ------
# The two template-level prohibitions the whole architecture rests on.
n=0
grep -q "No template ever contains a diagnosis, an order, or a therapy recommendation." "$TEMPLATES" && n=$((n+1)) \
  || note "missing template rule: no diagnosis/order/therapy"
grep -q "No template ever contains a staff name or an individual performance finding." "$TEMPLATES" && n=$((n+1)) \
  || note "missing template rule: no staff name"
assert C12 "template-level prohibitions present" "$n" "2"

echo
if [ "$fail" -eq 0 ]; then
  printf "%s%d checks passed, 0 failed%s\n\n" "$G" "$pass" "$N"
  exit 0
else
  printf "%s%d checks passed, %d failed%s\n\n" "$R" "$pass" "$fail" "$N"
  exit 1
fi
