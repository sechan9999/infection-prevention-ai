# Metrics

Every rate is reported as numerator / denominator with a confidence interval.
Never a bare percentage.

## Agreement with the IP

```
capture rate      = (candidate TRUE  AND IP confirmed) / (all IP-confirmed cases)
false positive    = (candidate TRUE  AND IP rejected)  / (all candidates raised)
false negative    = count(candidate FALSE AND IP confirmed)
indeterminate     = (engine could not judge) / (all cases evaluated)
```

Indeterminate cases are excluded from the capture-rate and FP denominators and
reported on their own line. Folding them in makes both numbers meaningless.

Every false negative carries a classification, and an unclassified FN blocks the
gate:

| Class | Meaning | Fix direction |
|---|---|---|
| `mapping` | field existed, was not mapped or was mapped wrong | field_mapping / code_mapping |
| `feed` | data does not exist in any system | data acquisition project |
| `rule` | mapping fine, rule condition too tight | threshold or condition |
| `definition` | rule encoded the surveillance definition incorrectly | rule logic, cite the manual section |

## Workload - the metric that decides adoption

```
candidate volume  = candidates raised / week, and projected / day
adjudication cost = median minutes per candidate (time the IP, do not estimate)
daily load        = volume x cost, compared against the IP's stated budget
```

An engine that clears every accuracy gate and exceeds the budget has failed.
Report it as a failure, not as a footnote.

## Timeliness - the actual value claim

```
latency delta = (date IP became aware, manual process)
              - (date the engine would have raised the candidate)
```

Report the median and the distribution. A negative median means the engine is
slower than the humans, which is a finding worth surfacing immediately.

## Mapping completeness

Per field required by any rule condition:

| Field | Present | Mapped | Populated % | Blocks which rules |
|---|---|---|---|---|

This table is the deliverable that survives the retrospective. It becomes the
data-acquisition priority list, ranked by how many rules each missing field
blocks.

## Grade distribution

Report the distribution only if an expected band was registered in advance. If
none was, report the raw counts and say no expectation was set. Do not
rationalize a distribution after seeing it.

## Sample size

State N and the interval width. With 10-20 confirmed events a year, a 12-month
window gives intervals too wide to separate an 80% capture rate from a 95% one -
either extend the window, or state that the retrospective can detect gross
failure only. Both are legitimate; pretending otherwise is not.

For workload estimates use a larger denominator - all positive blood cultures in
the window - since that population drives volume regardless of how few become
confirmed events.
