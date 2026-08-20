# Retrospective Validation Report

```
CLABSI RULE ENGINE - RETROSPECTIVE VALIDATION
Site: <site>   Window: <dates>   Run: <date>
Rule engine version: <id>   Contaminant list version: <id>
Definition sources: <NHSN PSC Manual version> | <national program + version> | <hospital policy version>
Explanation prompt version: <id>   Status: DRAFT - not a compliance record

--- PRE-REGISTERED GATES ---
Recorded: <datetime>   By: <role, name>       (gates written after results are void)
| Measure | Gate | Result | Pass? |
| Unexplained false negatives | 0 | | |
| Capture rate | >= <x>% | | |
| Candidate volume | <= <n>/day | | |
| Latency delta | >= 0 days earlier | | |
| Indeterminate rate | <= <x>% | | |
| Explanation hard failures | 0 | | |

--- REFERENCE STANDARD ---
IP adjudication. This measures CONCORDANCE WITH THE IP, not ground truth.
Inter-rater subset: <n> cases, 2 IPs, agreement <x>%   <- the engine's ceiling

--- FIXTURE REPLAY (run first) ---
Archetypes 1-11: <n> pass / <n> fail
Failing archetype(s): <id + what the engine returned vs expected>
A failing fixture invalidates the retrospective below it.

--- COUNTS ---
Cases evaluated: <n>   (positive blood cultures in window: <n>)
Confirmed by IP: <n>   Rejected: <n>   Indeterminate: <n>

--- AGREEMENT ---
| Measure | Value | Numerator/Denominator | 95% CI |
| Capture rate | | | |
| False positive rate | | | |
| False negatives | | | |
| Indeterminate rate | | | |

--- FALSE NEGATIVES (each must be classified) ---
| Case | Organism | Why the engine missed it | Class (mapping/feed/rule/definition) | Remediation | Accepted by |

--- FALSE POSITIVES ---
| Case | Engine verdict | IP reason for rejection | Class | Rule to tune |

--- WORKLOAD ---
Candidates/week: <n>   Projected/day: <n>   IP budget: <n>/day
Median adjudication time: <n> min (timed, not estimated)
Daily load: <n> min   Within budget: yes/no

--- TIMELINESS ---
Median latency delta: <n> days earlier   Distribution: <...>

--- MAPPING COMPLETENESS ---
| Field | Present | Mapped | Populated % | Rules blocked |
Top data-acquisition priority: <field>, unblocks <n> rules

--- EXPLANATION REVIEW ---
Sampled: <n>   Reviewers: 2   Hard failures: <n> (<codes>)   Pass rate: <x>%
Soft findings: <counts by code>

--- GRADE DISTRIBUTION ---
GRADE_A <n> / GRADE_B <n> / GRADE_C <n>
Expected band registered in advance: yes/no   (if no, report counts only)

--- ACTIONS FOR NEXT ITERATION ---
| Action | Type (rule/mapping/prompt/policy/data) | Owner | Re-test on |

Human approval required: Infection Preventionist. This report proposes; it does
not certify an engine as fit for go-live.
```
