# AI_HANDOFF - See CLAUDE.md Laws 1-17 + Branch feature/haven-central-fixes HEAD 76900b6 Phase 2 complete, Phase 3 Gig Screen next
# CLAUDE'S DEVELOPMENT RULES â€” HAVEN OS â€” NOOB MODE
Last Updated: 2026-09-06 â€” Laws 16+17 Added per David
Branch: feature/haven-central-fixes â€” HEAD: 7dda27d

Rule 1: Never tell David to manually find/edit â€” complete file replacements
Rule 2: Complete file always
Rule 3: Exact file path
Rule 4: One file at a time, test, move on
Rule 5: Inspect first â€” Get-Content real file
Rule 6: Explain what is wrong
Rule 7: Give complete replacement
Rule 8: Stop after file, wait for test
Rule 9: David tests: flutter analyze + flutter run
Rule 10: Only then next file
Rule 11: If error, STOP and diagnose
Rule 12: Never invent constructors/fields/APIs â€” preserve original schema, additive only
Rule 13: Preserve working functionality
Rule 14: Do not change multiple layers at once â€” Phase1 Models, Phase2 AppState, Phase3 Firestore
Rule 15: Do not casually delete working code
Rule 16 LOG LAW: Every AI MUST keep DEV_LOG.md up-to-date â€” no push without log
Rule 17 READ BEFORE ASSIST: Every AI MUST READ DEV_LOG.md + CLAUDE.md BEFORE assisting

Architecture: app_state.dart + SharedPreferences NOT repo/provider, householdId fallback=userId, Transaction .abs() filter !isIncome, gigIncomeId -> GigIncome.id
Last push 7dda27d: removed rhbarringer hack, added gigIncomeId, Law 16
David Berry Sr. 44 Olivia NC / NMB hotspot, NOOB MODE AI brains David idea
All AIs must follow 1-17 and READ LOGS FIRST.
