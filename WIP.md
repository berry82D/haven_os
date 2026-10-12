# WORK IN PROGRESS

**Last touched:** 2026-10-11 19:54
**Active task:** Home bridge card
**Driver:** DeepSeek (via David's PC)
**Branch:** main
**HEAD:** 0dc4160

## Status: AWAITING PHONE TEST (installed as b60)

### Home bridge card
- [x] Inspect _buildHomeTab in haven_central_screen.dart
- [x] Add money card: Left this month (reuse finances range calc)
- [x] Add "Add expense" button -> opens _buildAddTransactionSheet
- [x] Tap-through to Finances tab (_currentIndex = 2)
- [ ] Remove "Reports coming soon" placeholder tile
- [ ] Remove "Edit Widgets coming next update" placeholder
- [ ] Commit + push + phone test

## Rule (Law 18)
WIP.md deleted ONLY after install + real-phone verification.

## If Another AI Reads This
Resume at first unchecked [ ] item above.
### Installed but not verified
- [ ] Home shows money card under hero: "Left this month" + teal amount
- [ ] Add expense button opens form
- [ ] Finances button jumps to Finances tab
- [ ] After verification: close WIP, log in DEV_LOG, update ROADMAP
## NEW TASK — Home dashboard rework (AI Insights card)

### Remove
- [x] Removed "New" tile
- [x] Moved "Reports" to settings dialog

### Add
- [x] AI Insights card: title + sparkle + horizontal bars + comparative line
- [x] Tap card -> _showInsightsSheet
- [x] View All Transactions button full-width
- [ ] Don't touch: hero, Add expense/Finances buttons, pills, bottom sheet logic

### Also pending (yesterday)
- [ ] Verify bridge card on Home — money card + Add expense + Finances button
### AI Insights - layout + powerhouse content (this session)
- [x] _generateAIInsights rewritten: comparative + top mover + projection + what-if + budget alerts, capped at 5
- [x] _showInsightsSheet: hugs content (no DraggableScrollableSheet), sparkle title, each insight in rounded card
- [ ] Commit + push
- [ ] Phone verify: sheet opens hugging content, 4-5 insight cards visible