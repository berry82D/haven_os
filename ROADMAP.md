# Haven OS - Roadmap

**Updated:** 2026-10-14. **HEAD:** 16b26da (b71). Read with `AI_HANDOFF.md`, `WIP.md` (if present), `DEV_LOG.md`.

## DONE
- Cloud build + signing (Flutter 3.44.8, fingerprint-verified, `install -r` only)
- Version labeling: pubspec `1.0.1+1`, workflow extracts version + SHA into artifact name
- Auth: username resolution from Firestore profile, `auth_username` on every sign-in
- Settings gear -> Household Management link (invite code + join UI)
- Household cloud join: sign-in publishes household + invite index, Firestore rules for `households/{id}` + `household_invites/{code}`
- Data sync: household data root + one-time non-destructive merge - both phones synced - VERIFIED
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

## NOW
- Gig import dedup against Firestore (patch 13) - pushed 2026-10-17, awaiting build + phone verify. Next: patch 14 (gig form to Firestore).
1. Phone verify: keyboard fix (b70/b71) — keyboard never covers active field
2. Phone verify: compact searchable category picker (type "tra" -> Transport)
3. Close WIP.md (delete) once all above pass

## NEXT
5. Sharing permission model: clean new accounts (no inherited data), explicit linking, leveled invites (viewer/add/edit/admin, adjustable anytime), permanent (changeable/revocable) or temp (1 day min, 1 month max), 6-month check-ins
6. Household sync: move bills / animals / gig income from per-phone local to household sync; retire the `pending_join` workaround
7. Wire Settings Export/Import/Reset (buttons exist, methods are empty stubs; backup_service.exportBackup exists but uncalled)
8. Budget dropdown -> tap-to-open field (deferred from category picker work, still old style)
9. Finances - Formula Drawer (tap hero -> slide up "why this number" breakdown)
10. Finances - Coaching Card (one plain-words insight per screen, no shame)
11. Finances - Period Control Polish (tighten toggle + stepper UX per mockup)
12. Placeholder screens: Farm service (returns empty data), Tasks, Routines, Homestead, Timeline (widget + screen), CFO Transactions tab + entry dialog, Health score (returns default)
13. File split: haven_central_screen.dart is 2,592 lines (~1/6 of app) — split into Home / Finances / sheets before visual pass
14. Monarch/Jarvis visual pass on dense screens ("fancy when it's complicated", dark theme stays, app teaches)
15. Colorblind mode setting (Deuteranopia / Protanopia / Tritanopia palettes across all screens)
16. Savings Rate: computed (Net/Income*100) - VERIFIED. $100 buffer is hardcoded (const rangeBuffer) - make user-adjustable if desired
17. Dedicated all-transactions view (View All was removed as 4th Finances path; a real list view is still wanted)

## LATER
18. Kitchen Aid: real Recipes / Pantry / Shopping behind the placeholder tab
19. Show an error (not endless loading) on Firestore PERMISSION_DENIED
20. Forgotten-username hint on sign-in
21. Clean up duplicate Firebase Auth accounts (2 each for David and Candice - review in console first)
22. Package rename (`com.example.haven_os`) before any Play Store release
23. D:\ flash-drive update once a stable build is confirmed (contents TBD - David provides `dir` listing)

## RULES FOR THIS FILE
- Keep it short. One line per item.
- Move items DONE -> NOW -> NEXT as work lands. Delete, don't accumulate.
- If you're an AI picking up work, start at NOW #1. If NOW is empty, take the top of NEXT.
