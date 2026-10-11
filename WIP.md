# WORK IN PROGRESS

**Last touched:** 2026-10-11 10:59
**Active task:** Formula Drawer - tap hero -> slide up "why this number"
**Driver:** DeepSeek (via David's PC)
**Branch:** main
**ROADMAP:** NEXT #4

## Status: IN PROGRESS - inspection phase

### Goal
Tapping the "Left this period" hero card opens a bottom sheet showing the math:
income - spent - bills due - $100 buffer = left. Same number as hero, broken down.

### Steps
- [x] 1. Inspect current hero card + tap handlers
- [x] 2. Add _showFormulaDrawer() helper
- [x] 3. Wrap hero in tap gesture
- [ ] 4. Commit + push
- [ ] 5. Cloud build green
- [ ] 6. Phone check: tap hero -> sheet opens, math correct, dismisses cleanly
- [ ] 7. Close WIP (delete)

### Home tab polish (new)

- [ ] Condense Home layout so it fits one screen (hero smaller, pills tighter, cards tighter)
- [ ] Fix AI Insights money text: strip `**`, add `\$`, add commas, use _money if applicable
- [ ] 12-Month Projection on Finances: switch from decimals:0 to decimals:2 (brief spec)
### Finances long-page fix (chosen: A - collapse sections)
- [ ] Wrap Expense Breakdown (pie) in ExpansionTile, collapsed by default
- [ ] Wrap 12-Month Projection in ExpansionTile, collapsed by default
- [ ] Keep Recent Activity as-is (already ExpansionTile)
- [ ] Hero + 4 cards + bar chart stay visible

### Finances display bugs (queued)
- [ ] Pie title "Expense Breakdown (X)" overlapped by pie - move label above or add padding
- [ ] Transport + Groceries both cyan - assign distinct colors
- [ ] "Other" legend pink but slice gray - align legend to slice

### Home bridge card (queued)
- [ ] Home: money card "Left this month X" + "+ Add expense" + tap-through to Finances
- [ ] Remove placeholder "Reports coming soon" / "Edit Widgets coming next update"

### RESOLVED - net worth swing
- [x] +246 -> -56 caused by wife deleting a duplicate 301 wage entry. Not a bug. Data integrity fine.

### Backlog
- [ ] Projection math: allTimeNet + avgSavings*12 = straight multiple of net worth, not real forecast. Label or better formula.
## Rule (Law 18)
WIP.md deleted ONLY after install + real-phone verification.

## If Another AI Reads This
Resume at first unchecked [ ] item.