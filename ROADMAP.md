# Haven OS - Roadmap

**Updated:** 2026-10-21. **HEAD:** 4a08be7 (b121). Read with `AI_HANDOFF.md`, `WIP.md` (if present), `DEV_LOG.md`.

## DONE
- Cloud build + signing (Flutter 3.44.8, fingerprint-verified, `install -r` only)
- Version labeling: pubspec `1.0.2`, workflow extracts version + SHA into artifact name
- Auth: username resolution from Firestore profile, `auth_username` on every sign-in
- Settings gear -> Household Management link (invite code + join UI)
- Household cloud join: sign-in publishes household + invite index, Firestore rules for `households/{id}` + `household_invites/{code}`
- Data sync: household data root + one-time non-destructive merge - both phones synced - VERIFIED (re-confirmed Oct 21)
- Finances Chunk #1: Week/Month toggle + "Left this period" hero
- Finances Chunk #2: chart tap -> month anchor -> week stepper (chevrons + picker, faded edges), overshoot fix - VERIFIED on phone
- Money format: comma thousands + sign-before-dollar across Finances - VERIFIED on phone
- Finances: pie + 12-Month Projection collapsed into ExpansionTiles (shorter scroll) - VERIFIED on phone
- Finances: searchable window for Recent Activity (fixed-height + search field) - VERIFIED on phone
- Laws 18 (WIP.md) + 19 (HANDOFF block) + 20 (ROADMAP LAW)
- Home rework: AI Insights dashboard card (top-4 horizontal bars + comparative line), removed New/Reports tiles, View All full-width - VERIFIED on phone
- Home redundancy cleanup: killed Finances chip, removed View All Transactions, Breeding->Batches, insights dedup, sheet debounce - VERIFIED on phone
- Insights powerhouse: comparative + projection + what-if + budget alerts, hugging sheet - VERIFIED on phone
- Tappable Income/Expense summary cards (strict isIncome filter) - VERIFIED on phone
- Frequency-sorted category dropdown (most-used first) - VERIFIED on phone
- StatefulBuilder toggle fix: Income/Expense toggle responds instantly - VERIFIED on phone
- Income/expense category split (separate lists) - VERIFIED on phone
- Keyboard fix: sheet expands, keyboard never covers active field - b70 green, phone verification pending
- Compact searchable category picker (partial-match search) - b71 green, phone verification pending
- Home bridge card: "Left this month" + Add expense + Finances button - VERIFIED on phone
- Insights accuracy fix: day-aligned comparisons, honest budget %, warmer tone, category-aware what-if - b72, phone verify pending
- Gig import: idempotent dedup (deterministic ids, Firestore write on save/delete) + Data Check screen + Remove Duplicates - b100/b101 - VERIFIED in the Oct 17-18 cleanup
- Zero-Debt Goal: household debts in Records, unknown-balance support, verified dates, payment creates a 'Debts' expense - b118 - VERIFIED on phone Oct 21
- Gig tab upgrade: unified list, year/month picker, Trends/Impact, platform case merge - b103-b115 - VERIFIED on phone
- Top-layer form errors: validation shows on the open sheet/dialog, never buried - b119 - VERIFIED on phone Oct 21
- Gig edit button for Transaction-only rows - b119 - VERIFIED on phone Oct 21
- Gig edit amount validation (a bad amount is no longer silently dropped) - b120 - VERIFIED on phone Oct 21
- Delete confirmations: gig job, farm item and task deletes ask first and name the item - b121 - VERIFIED on phone Oct 21

## NOW
1. Candice: install b121, then enter the real debts in Zero-Debt
2. Phone verify: keyboard fix (b70/b71) - keyboard never covers active field
3. Phone verify: compact searchable category picker (type "tra" -> Transport)
4. Phone verify: PIN/biometric checklist in WIP.md (capture the fingerprint error text)

## NEXT
5. Path-to-debt-free calculator (snowball/avalanche, months to free, total interest - data only)
6. Loan insight: affordability verdict in the loan form and on loan cards (restore lost feature)
7. Single entry point: one Add Transaction sheet for everything; Gig tab + routes into it; Scan Receipt fills the sheet for review, never saves directly
8. Sharing permission model: clean new accounts (no inherited data), explicit linking, leveled invites (viewer/add/edit/admin, adjustable anytime), permanent (changeable/revocable) or temp (1 day min, 1 month max), 6-month check-ins
9. Household sync: move bills / animals / gig income from per-phone local to household sync; retire the `pending_join` workaround
10. Wire Settings Export/Import/Reset (buttons exist, methods are stubs; backup_service.exportBackup exists but uncalled)
11. 'Debts' into the expense category picker (debt payments use the category but it cannot be picked)
12. Budget dropdown -> tap-to-open field (deferred from category picker work, still old style)
13. Finances - Formula Drawer (tap hero -> slide up "why this number" breakdown)
14. Finances - Coaching Card (one plain-words insight per screen, no shame)
15. Finances - Period Control Polish (tighten toggle + stepper UX per mockup)
16. Placeholder screens: Routines, Homestead, Timeline (widget + screen), CFO Transactions tab + entry dialog, Health score (returns default)
17. File split: haven_central_screen.dart is ~3,000 lines (~1/6 of app) - split into Home / Finances / sheets before visual pass
18. Monarch/Jarvis visual pass on dense screens ("fancy when it's complicated", dark theme stays, app teaches)
19. Colorblind mode setting (Deuteranopia / Protanopia / Tritanopia palettes across all screens)
20. Savings Rate: computed (Net/Income*100) - VERIFIED. $100 buffer is hardcoded (const rangeBuffer) - make user-adjustable if desired
21. Dedicated all-transactions view (View All was removed as 4th Finances path; a real list view is still wanted)
22. Gig form: one end-of-day Total Earnings entry for Candice (Spark, all-day gig work)

## LATER
23. Kitchen Aid: real Recipes / Pantry / Shopping behind the placeholder tab (lost module)
24. Insights projection fix (audit #4: monthly projection understated ~50%)
25. Keyword income-override guard (audit #9: a category like 'Debt Payment' must not flip an expense to income)
26. Budget doc ID -> month_category + migration (audit P0-9)
27. Firestore rules file into the repo (today they live only in the Firebase console)
28. Data cleanup with Candice: Aug 9 DoorDash duplicate, Trip #6162/#9308 recategorize Salary -> Gig Income, $25.92 Spark entry missing its Finances link
29. Show an error (not endless loading) on Firestore PERMISSION_DENIED
30. Forgotten-username hint on sign-in
31. Clean up duplicate Firebase Auth accounts (2 each for David and Candice - review in console first)
32. Package rename (`com.example.haven_os`) before any Play Store release
33. INSTALL.md vs folding into README.md - decide
34. Firebase App Distribution (parked Oct 14: David group gets every build, Candice group gets verified builds only)
35. D:\ flash-drive update once a stable build is confirmed (contents TBD - David provides `dir` listing)
36. AI Insights futuristic redesign: full-screen intelligence view instead of the bottom sheet - teal aurora glow, ranked insight cards (headline + proving number + impact tag), hero top insight; presentation only, insight math unchanged (David, Oct 21)
37. Gig Trends fix: monthly bars + By platform ignore the month picker (year-scoped) - scope Trends to the selected period (month pick shows weekly bars); Impact already correct (David, Oct 21)
38. Suggested Budgets setup: suggestion cards from real spending (per category, last 3 months) with Tight / Typical / Roomy options and one-tap Add budget via the existing save path; expenses only, needs spend in 2 of the last 3 months (David, Oct 21)
39. Remove the Schedule tab: move the full task list + Add Task into Home at the Upcoming Tasks card, bottom bar 7 tabs to 6, drop the card tap-to-tab jump (David, Oct 21)

## RULES FOR THIS FILE
- Keep it short. One line per item.
- Move items DONE -> NOW -> NEXT as work lands. Delete, don't accumulate.
- If you're an AI picking up work, start at NOW #1. If NOW is empty, take the top of NEXT.