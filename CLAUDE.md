[paste CLAUDE.md content here]
# CLAUDE'S DEVELOPMENT RULES — HAVEN OS — NOOB MODE
Last Updated: 2026-09-06 — reorganized for clean AI handoff, no content changes to Laws 1-17
Branch: feature/haven-central-fixes — HEAD: 60170b5 — update this line on every push, no exceptions

## CURRENT STATE
See DEV_LOG.md's CURRENT STATE block for the live status — that file is the source of truth for what's done vs. in progress. This file is for stable rules and architecture, not changing status.

## RULES
Rule 1: Never tell David to manually find/edit — give complete file replacements
Rule 2: Always the complete file, never a snippet
Rule 3: Always give the exact file path
Rule 4: One file at a time — test, confirm, then move on
Rule 5: Inspect first — read the real file (Get-Content / view), never assume its content
Rule 6: Explain what is wrong before proposing a fix
Rule 7: Give the complete replacement
Rule 8: Stop after each file, wait for the test result
Rule 9: David tests with flutter analyze + flutter run (and a functional smoke test for anything analyze can't catch, like runtime-only bugs)
Rule 10: Only move to the next file after the current one is confirmed
Rule 11: If an error occurs, STOP and diagnose before continuing
Rule 12: Never invent constructors/fields/APIs — preserve the original schema, additive changes only
Rule 13: Preserve working functionality
Rule 14: Do not change multiple architectural layers at once — Phase 1 Models, Phase 2 AppState, Phase 3 Firestore/UI
Rule 15: Do not casually delete working code — verify usage (grep in build(), event handlers, etc.) before removing anything another AI calls "unused"
Rule 16 (LOG LAW): Every AI must keep DEV_LOG.md's CURRENT STATE block up to date — no push without updating it
Rule 17 (READ BEFORE ASSIST): Every AI must read DEV_LOG.md + CLAUDE.md before assisting

## ARCHITECTURE
- app_state.dart (ChangeNotifier) + SharedPreferences is the real state layer — NOT a repository/provider pattern
- householdId fallback = userId (additive migration in progress toward household-scoped Firestore sync)
- Transaction amounts are always stored non-negative (.abs()); use !isIncome to distinguish spend vs. income, never amount < 0
- gigIncomeId (nullable, on Transaction) -> GigIncome.id links a transaction to its gig-income detail record

## PEOPLE / CONTEXT
- David Berry Sr. — sole maintainer, NOOB MODE (directs product/architecture, AI writes the code)
- Location context: Olivia, NC / NMB hotspot — connection can be flaky, --verbose helps diagnose push issues

All AIs assisting on this project must follow Rules 1-17 above and read DEV_LOG.md first.