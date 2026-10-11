# WORK IN PROGRESS

**Last touched:** 2026-10-11 08:31
**Active task:** Step D - money format (display only)
**Driver:** DeepSeek (via David's PC)
**Branch:** main

## Status: IN PROGRESS

### Step D - money format edits
- [x] Step D2: activity commas + clean axis max (pushed 2ebecda)
Add _money(v, [decimals=2]) helper. Comma-separated thousands, sign before $, 2 decimals default.
- [x] Helper added
- [x] Hero amount -> _money(leftThisPeriod)
- [x] Formula line: 4 values -> _money(x, decimals: 0)
- [x] Cards Income/Expenses/Net -> _money(x, decimals: 0)
- [x] Chart Y-axis -> _money(x, decimals: 0)
- [x] 12-month projection: allTimeNet, projectedNet -> _money(x, decimals: 0)
- [ ] Commit + push
- [ ] Phone check: hero $211.06, negative -$347.66, thousands $1,570.00

### Still open from earlier - stepper + chunk #2 phone test
- [ ] Phone taps: 2 (chevron advance), 3 (first/last disabled), 4 (label opens picker), 6 (bar tap swaps month), 8 (settings footer v1.0.1+1)
- [ ] Sync test: wife adds $1 -> appears on yours
- [ ] Confirm remaining -> close WIP

## Rule (Law 18)
WIP.md deleted ONLY after install + real-phone verification on ALL active chunks.

## If Another AI Reads This
Resume at first unchecked [ ] item above.