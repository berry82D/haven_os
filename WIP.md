# WORK IN PROGRESS

**Last touched:** 2026-10-11 12:51
**Branch:** main
**HEAD:** 5981256
**Driver:** DeepSeek (via David's PC)

## Status: PAUSED - awaiting build 5981256 + phone verification

## Just shipped (uncommitted? no - pushed, awaiting phone check)
- [x] Search + windowed Recent Activity (commit 5981256)
- [x] Pie + 12-Month Projection collapsed into ExpansionTiles (commit aa619e0)
- [x] Step D money format - commas + sign-before-$ (commit 82aa213)
- [x] Week stepper replaces chip grid (commit 1177e1a)

## Awaiting phone verification (blocking WIP close)
- [ ] Build 5981256 green in GitHub Actions
- [ ] Install APK on R3GL40HW72K (and Candice's R5CY2180YTH when awake)
- [ ] Verify search: type "circle k" -> only matches show; clear -> full list
- [ ] Verify window: fixed-height box scrolls; page stays short
- [ ] Verify collapse: pie + 12-Month Projection start collapsed, tap to expand
- [ ] Verify stepper: chevrons step, first/last disabled, label opens picker, bar tap swaps month
- [ ] Verify settings footer shows Haven OS v1.0.1+NN

## Queued for next session (do in this order)
1. [ ] Home bridge card: money card on Home showing "Left this month $X" + "+ Add expense" button + tap-through to Finances; remove placeholder "Reports coming soon" / "Edit Widgets coming next update"
2. [ ] Finances display bugs (3): pie title overlapped by pie; Transport+Groceries both cyan; "Other" legend pink but slice gray
3. [ ] Projection math: allTimeNet + avgSavings*12 = straight multiple of net worth, not real forecast. Add label or better formula.

## RESOLVED
- [x] Net worth swing +$246 -> -$56: wife deleted a duplicate $301 wage entry. Not a bug.

## Rule (Law 18)
WIP.md deleted ONLY after install + real-phone verification on ALL active chunks.

## If Another AI Reads This
Resume at the first unchecked [ ] in "Awaiting phone verification". Do NOT redo completed steps.