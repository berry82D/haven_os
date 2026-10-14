# WORK IN PROGRESS

**Last touched:** 2026-10-14
**Active task:** Insights accuracy fix (5 bugs, 8 patches)
**Driver:** DeepSeek (via David's PC)
**Branch:** main
**HEAD:** 49edb36 (push pending)

## Status: IN PROGRESS

### Prior tasks (still awaiting phone verify)
- [x] Compact searchable category picker (b71 green)
- [x] Keyboard fix (b70/b71 green)

### Insights accuracy fix
- [x] Patch 1: _spendWindow + _comparativeSentenceFromTotals helpers
- [x] Patch 2: _homeComparativeInsight uses helpers
- [x] Patch 3: Engine seed loop day-aligned
- [x] Patch 4: Engine comparative uses shared helper (fixes dedup)
- [x] Patch 5: Projection gate (day >= 15) + tone fix
- [x] Patch 6: What-if - fixed-cat skip + 10% extrapolated
- [x] Patch 7: Engine budget text unclamped
- [x] Patch 8: Budgets screen - text/color unclamped, bar clamped
- [ ] Commit + push
- [ ] Cloud build green
- [ ] Install on phone, tap-test:
  - [ ] Compact picker: type "tra" -> Transport
  - [ ] Keyboard never covers active field
  - [ ] Comparative uses same-days window (not all of last month)
  - [ ] What-if does NOT fire on Housing/Utilities
  - [ ] 150% budget shows 150%, not 100%
  - [ ] Tone: "So far this month: spending is $X above income"

## Rule (Law 18)
WIP.md deleted ONLY after install + real-phone verification.