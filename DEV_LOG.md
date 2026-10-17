## 2026-10-17 -- PENDING -- fix(gig-import): dedup against Firestore, deterministic id, proper-case description
**Steps:** _importGigJobs now reads existing Firestore transactions and skips any job whose gigIncomeId already exists. New rows use id 'gig_<jobId>' so re-runs overwrite instead of duplicating. Description is '<Platform> Gig Job' (no leading space). Early return on no jobs; mounted check before context use. Repaired two mangled userId/householdId lines.
**Files:** lib/features/haven_central/haven_central_screen.dart (one function), WIP.md, DEV_LOG.md, ROADMAP.md
**Why:** Old import deduped against the local list only, so a second phone could re-import the same jobs as duplicates.
**Not touched:** Existing duplicate rows in Firestore (report first, delete only with approval). Gig form still writes locally only (patch 14).
**Next:** Green build, phone verify, then patch 14 (gig form writes to Firestore).
## 2026-10-16 -- PLAN -- Single entry point for all transactions (1 entry point)
**Status:** PLANNED, not yet built. Log first, build after (Law 16).
**Problem:** 4 entry paths create the same kind of income in different shapes, and neither the Gig tab nor Finances sees the full picture. Proof: Gig tab shows only $25.92 (Oct 14, Gig form); Finances search "spark" shows only Trip #9308 $50.22 (Oct 5, Scan Receipt). Same income type, two silos.
**Entry paths today:**
1. Gig form -> GigIncome (+ linked Transaction via bridge)
2. Finances Add Transaction -> Transaction only
3. Scan Receipt (Gallery/Camera) -> Transaction only
4. Import (gig_jobs) -> Transaction only
**Plan -- 1 entry point:**
- One "+" opens the Add Transaction sheet. That sheet is the ONLY user entry point.
- Gig tab "+" routes to the same sheet, pre-set to Gig (platform + miles fields appear).
- Scan Receipt fills the same sheet (user reviews, then saves). It never saves directly.
- Import stays background sync (not a user entry point). It creates both Transaction + GigIncome.
- One save path: Income + gig -> creates Transaction + GigIncome together. Everything else -> just Transaction.
- Gig tab reads GigIncome + gig Transactions, deduped by link, grouped by platform. Finances counts Transactions.
- Scan rule: one Transaction per TRIP (not per stop/order). Amount = Estimated Total (Base + Tips + Boost). Trip # is the dedup key. Tips are estimated (adjustable 24h) -- use final amount when possible.
**Source data:** 6 Spark trips (Aug 23 - Oct 5): #6162 $18.16, #4970 $14.00, #9914 $18.07, #5553 $36.42, #3797 $30.86, #9308 $50.22. Total $167.73. (Backlog vs already-in-Haven TBD.)
**Not touched:** Biometric diagnostic (#96), Insights #4, budget doc IDs, Firestore rules versioning.
**Next:** Build after David approves this plan.
## 2026-10-15 -- PROJECTION + PIN RE-ENTRY -- fix(projection): current-month pace; fix(auth): PIN only on re-entry after 5-min background
**Steps:** Projection uses MTD pace (day >= 15) else last complete month. PIN gate moved from after-login to app-resume-after-5-min-background. signIn marks session verified. PinEntryScreen pops back to Home. Home observes lifecycle, pushes PIN screen on resume when needsPinReentry. PopScope back-button block attempted then reverted (broke parse).
**Files:** haven_central_screen.dart (projection + lifecycle observer), app_state.dart (background tracking, needsPinReentry rewrite, unlockApp deleted, _sessionStartTime removed), sign_in_screen.dart (straight to Home), pin_entry_screen.dart (pop on success).
**Why:** Projection was $30k fantasy (Aug outlier + partial Oct in average). PIN-after-login was an extra step; PIN's real job is locking on return. Password proves identity at login; PIN locks when you walk away.
**Not touched:** PIN setup UI, biometric unlock, Insights projection.
**Next:** Phone verify PIN re-entry + projection. Then next audit item.
## 2026-10-15 -- PROJECTION + PIN RE-ENTRY -- fix(projection): current-month pace; fix(auth): PIN only on re-entry after 5-min background
**Steps:** Projection uses MTD pace (day >= 15) else last complete month. PIN gate moved from after-login to app-resume-after-5-min-background. signIn marks session verified. PinEntryScreen pops back to Home, back button blocked. Home observes lifecycle, pushes PIN screen on resume when needsPinReentry.
**Files:** haven_central_screen.dart (projection + lifecycle observer), app_state.dart (background tracking, needsPinReentry rewrite, unlockApp deleted), sign_in_screen.dart (straight to Home), pin_entry_screen.dart (pop + PopScope).
**Why:** Projection was $30k fantasy (Aug outlier + partial Oct in average). PIN-after-login was an extra step; PIN's real job is locking on return. Password proves identity at login; PIN locks when you walk away.
**Not touched:** PIN setup UI, biometric unlock, Insights projection.
**Next:** Phone verify PIN re-entry + projection. Then next audit item.
## 2026-10-15 -- P0-1c -- verify: PIN paths traced, unlockApp bypass still present

**Status:** Verified on origin; unlockApp deletion pending
**Steps:** Traced all PIN paths against origin/main after e70abe4: (1) login -> hasPin check -> PIN screen or Home - PASS (2) correct PIN -> Home - PASS (3) biometrics -> Home - PASS (4) forgot PIN -> Sign In - PASS (5) signIn no longer auto-verifies - PASS (6) no demo button, no /home route - PASS. Found: unlockApp() still exists (app_state.dart:115), dead code that still sets pinVerified=true with no check. PIN setup UI (e70abe4) landed on origin AFTER the trace - trace "local only" note is stale.
**Files:** none (verification only)
**Why:** Verify P0-1 end-to-end before phone test. unlockApp() is a loaded gun - if future code calls it, the bypass returns. Delete it.
**Not touched:** code (deletion script given, not yet run)
**Next:** Delete unlockApp() -> push -> build green -> phone verify PIN gate + setup.

---## 2026-10-15 -- P0-1b -- fix(auth): PIN setup UI in Settings (was missing)

**Status:** Pushed, awaiting build + phone verification
**Steps:** Added PIN Lock tile to live Settings dialog (_showSettings) + _showPinSetup dialog (new PIN + confirm, min 4 digits, Remove PIN when set). P0-1 built the gate but no UI existed to set a PIN — Settings had no PIN option at all.
**Files:**
- lib/features/haven_central/haven_central_screen.dart -- PIN tile + _showPinSetup
- DEV_LOG.md -- this entry

**Why:** b90 installed, David reported "no pin / not in settings" — the gate works but users had no way to create a PIN. Now: Settings -> PIN Lock -> set PIN -> sign out/in -> PIN screen appears.
**Not touched:** Insights #4, #6 Left, P0-2..P0-25 — queued.
**Next:** Build green -> install -> Settings -> PIN Lock -> set PIN -> sign out/in -> verify PIN gate + fingerprint.

---## 2026-10-15 -- P0-1 -- fix(auth): real PIN gate + biometric unlock

**Status:** Pushed, awaiting build + phone verification
**Steps:** (1) app_state.dart: signIn no longer auto-verifies PIN; added verifyPinAndUnlock() + unlockWithBiometrics() (local_auth). (2) pin_entry_screen.dart: full rewrite - real PIN field, biometric button, forgot-PIN back to sign-in; demo button deleted; /home route fixed to MaterialPageRoute. (3) sign_in_screen.dart: after login, routes to PIN screen when PIN is set, else straight to Home. (4) pubspec.yaml: local_auth ^2.3.0. (5) AndroidManifest: USE_BIOMETRIC permission. (6) WIP.md: P0-1 as active ticket.
**Files:**
- lib/services/app_state.dart -- PIN/biometric unlock methods, signIn fix
- lib/features/auth/presentation/pin_entry_screen.dart -- full rewrite
- lib/features/auth/presentation/sign_in_screen.dart -- PIN routing
- pubspec.yaml -- local_auth
- android/app/src/main/AndroidManifest.xml -- USE_BIOMETRIC
- WIP.md + DEV_LOG.md -- this entry

**Why:** P0-1 - PIN "Unlock (demo)" button bypassed PIN entirely; signIn() set pinVerified=true; login went straight to Home with no PIN gate. PIN is a shortcut password (4-6 digits) for quick unlock; biometrics (fingerprint/face) is an alternate unlock. Forgot-PIN path goes back to sign-in so no lockout.
**Not touched:** P0-2..P0-25, Insights #4, #6 Left - queued. Audit reports on GitHub (bdb5504).
**Next:** Build green -> install -> phone verify per WIP checklist (correct PIN, wrong PIN, fingerprint, no-PIN straight to Home).

---## 2026-10-15 -- e3206da + fb7fc93 -- fix(math audit): Budgets month filter + chart off-by-one

**Status:** Pushed, awaiting build + phone verification
**Steps:** (1) e3206da: Budgets tab filtered `incomes` + `spent` to current month (added monthStart/monthEnd). (2) fb7fc93: monthly chart buckets use `!isBefore(monthStart)` instead of `isAfter(monthStart - 1 day)` — last day of prev month no longer counted twice.
**Files:**
- lib/features/haven_central/haven_central_screen.dart -- both fixes
- DEV_LOG.md -- this entry

**Why:** Full math audit (Oct 15) found Budgets tab compared ALL-TIME spend/income vs this month's budget (Groceries $500 budget showed $8,000 spent). Chart off-by-one counted Sep 30 expense in BOTH Sep and Oct, corrupting chart + projection.
**Not touched:** Insights projection (#4), Left bills double-count (#6), PIN bypass (P0-1) — queued next. Audit reports prepared for Claude review before audit DEV_LOG entry.
**Next:** Build green -> install -> verify Budgets tab shows October-only numbers; verify Sep 30 transaction appears in September only.

---## 2026-10-15 -- a85fb09 -- phone verify: Add Transaction form working

**Status:** VERIFIED on phone (David, Oct 15)
**Steps:** Category picker: 1 open, 1 close (PASS — earlier "double-layer" read was a misread; same sheet, keyboard open vs closed). Income/Expense toggle: Expense stays selected when Description tapped (PASS). Keyboard: active field visible above keyboard (PASS).
**Files:**
- lib/features/haven_central/haven_central_screen.dart -- autofocus false on category search
- DEV_LOG.md -- this entry
**Why:** Category picker autofocus opened keyboard on sheet open, expanding it to full-screen. Removing autofocus keeps the sheet compact.
**Not touched:** General default category (still open, minor); gig doubles (Candice review pending)
**Next:** Loan insight (NEXT #1) — Records -> Loans form, live affordability what-if

---## 2026-10-15 -- VERIFIED -- b84 (a85fb09) installed on R3GL40HW72K

**Status:** VERIFIED on phone
**Build:** b84, commit a85fb09, 93.9 MB APK
**Steps:** Extracted b84 zip, `adb -s R3GL40HW72K install -r` succeeded. First attempt with b81 (be2d216) failed VERSION_DOWNGRADE (phone had 82, APK was 81) - no uninstall performed, switched to b84.
**Files:** none (verification only)
**Why:** Close out the category-picker + keyboard WIP and record the install path.
**Verified on phone:**
- Category picker: no autofocus on open, single back-out (a85fb09) - PASS
**Still to verify (pending David):**
- Home comparative line day-aligned
- AI Insights dedup (comparative line not repeated in sheet)
- Budget line shows real percent when overspent
- Keyboard never covers active field
- Gig income reaches Finances (bridge suspected broken - see next)
**Not touched:** code
**Next:** smoke test remaining items; if gig income missing from Finances, write patch 13 (Firestore bridge)

---## 2026-10-14 -- 804e4eb -- fix(gig): bridge + import gig income to Finances

**Status:** Build #82 pending (pushed, awaiting green)
**Steps:** (1) 4bc212a: addGigIncome/updateGigIncome/deleteGigIncome now create/update/remove a linked income Transaction (category "Gig Income") so Finances counts gig money. (2) d76db68: corrupt duplicate run, reverted. (3) f71ec34/d966cb8/be2d216: fixed dropped quotes on description string, added dedup guard (skip if Transaction with same gigIncomeId exists). (4) 804e4eb: _importGigJobs runs on startup, pulls gig_jobs from Firebase, creates Transactions for jobs with net > 0 that lack one (dedup by gigIncomeId).
**Files:**
- lib/services/app_state.dart -- gig bridge + dedup guard
- lib/features/haven_central/haven_central_screen.dart -- _importGigJobs + initState call
- DEV_LOG.md -- this entry

**Why:** GigIncome saved only to local gig list, never created a Transaction, so Finances never counted it. Firebase gig_jobs (July, 17+ entries incl. $218.21 DoorDash) sat unused because nothing subscribed to the stream. Import pulls them into Transactions.
**Not touched:** GigJob model; FirestoreService gig_jobs methods (already existed); DST fix (still deferred)
**Next:** #82 green -> install -> verify July gig earnings appear in Finances income; verify new gig entry adds to income without duplicate
**Caveat:** Gig entries saved before the bridge have no Transactions until re-saved or imported.

---## 2026-10-14 -- PENDING -- fix(insights): remove duplicate what-if block from patch 9

**Status:** PENDING push
**Steps:** Patch 9's brace counter stopped at the `};` of the fixedCats set (a set literal inside a comment-anchored block), replacing only 5 lines. The old unguarded block remained below, leaving two `final varEntries` declarations in one scope. Build b72 red with `'varEntries' is already defined`. Patch 10 deletes the duplicate block.
**Files:**
- lib/features/haven_central/haven_central_screen.dart -- removed 14-line duplicate
- WIP.md -- stamp
- DEV_LOG.md -- this entry
**Why:** Brace counting from a comment that contains a set literal stops at the set's close brace, not the block's.
**Not touched:** the guarded what-if block (kept); rangedSavingsRate clamp; DST add-Duration
**Next:** push -> b73 -> install -> verify on day < 10 the what-if line is absent

---## 2026-10-14 -- 371e7bb -- b72 -- fix(insights): accuracy pass - partial months, tone, what-if, clamp

**Status:** PENDING push
**Steps:** 8 patches. Added _spendWindow (day-aligned windows) + _comparativeSentenceFromTotals (shared formatter). Home card and engine comparative now call the same helper, so L287 dedup matches by construction. Engine seed loop day-aligned. Projection gated on now.day >= 15. Tone softened. What-if skips fixed categories; cut = ~10% of extrapolated month. Budget percent unclamped for text and >80 color, clamped only for the bar (engine + budgets screen).
**Files:**
- lib/features/haven_central/haven_central_screen.dart -- helpers added; 6 blocks rewritten
- WIP.md -- checkboxes
- ROADMAP.md -- #4 to DONE
- DEV_LOG.md -- this entry

**Why:** Partial month vs full prev month distorted the comparative. Hardcoded $5/week what-if fired on fixed categories like Housing. Clamped percent showed "100% used" on 150% overspend. Tone was blunt.
**Not touched:** _homeMonthlyLeft 100.0 buffer, rangedSavingsRate (L747), top-category bars
**Next:** push -> cloud build -> install -> phone verify: partial-month comparison, no Housing what-if, >100% shown honestly, tone

---## 2026-10-14 -- PENDING -- feat(transaction-form): compact searchable category picker

**Status:** PENDING push
**Steps:** added _showCategoryPicker helper (bottom sheet, search bar on top, frequency-sorted list, constrained to 320px height) -> Add Transaction dropdown replaced with GestureDetector that opens the picker
**Files:**
- lib/features/haven_central/haven_central_screen.dart -- category selection now uses a compact searchable sheet instead of a full-page dropdown
- WIP.md -- checkboxes
- DEV_LOG.md -- this entry

**Why:** Full-page category list was too tall and required scrolling to find categories. Compact sheet with search matches user's mental model ("type 'tra' -> Transport").
**Not touched:** budget dropdown (still uses old DropdownButtonFormField for now), toggle, form fields
**Next:** push -> cloud build -> install -> verify search + compact + frequency sort

---
## 2026-10-13 -- PENDING -- fix(transaction-form): keyboard no longer covers fields

**Status:** PENDING push
**Steps:** DraggableScrollableSheet config: maxChildSize 0.95 -> 1.0; expand false -> true. Now the sheet expands to fill the reduced viewport when keyboard is up. viewInsets.bottom padding on the Container already handles the keyboard offset.
**Files:**
- lib/features/haven_central/haven_central_screen.dart -- one-line config change in Add Transaction sheet wrapper
- WIP.md -- checkboxes
- DEV_LOG.md -- this entry
**Why:** With maxChildSize 0.95 and expand false, sheet couldn't grow past 95% of full screen. When keyboard took ~40%, active field fell below visible area.
**Not touched:** form fields, toggle, dropdowns, submit
**Next:** push -> build -> install -> tap each field top-to-bottom; keyboard should never cover active field

---
## 2026-10-13 -- 3f066c5 -- VERIFIED: toggle instant + category split

**Status:** VERIFIED on R3GL40HW72K
**Confirmed:**
- Add Transaction toggle turns red/green instantly (StatefulBuilder fix)
- Income selected -> Category shows income list only (Salary, Gig Income, Crop Sales, etc.)
- Expense selected -> Category shows expense list only (Gas, Power, Rent, Groceries, etc.)
- Budget tab -> Add Budget dialog shows expense categories only
- Sync still working between phones

**WIP closed.** Next: ROADMAP NEXT items.

---
## 2026-10-13 -- PENDING -- feat(transaction-form): toggle rebuild + income/expense category split

**Status:** PENDING push
**Steps:** added incomeCategories + expenseCategories const lists -> _sortedCategoriesByUse now takes base List<String> -> wrapped Add Transaction sheet in StatefulBuilder with local setState alias -> toggle resets selectedCategory to Salary/Gas -> Add Transaction dropdown uses isIncome ? incomeCategories : expenseCategories -> Budget dropdown uses expenseCategories
**Files:**
- lib/features/haven_central/haven_central_screen.dart -- toggle now redraws sheet; category list cleanly splits income vs expense
- WIP.md -- checkboxes
- DEV_LOG.md -- this entry

**Why:** Toggle taps only updated a variable but not the sheet's context, so UI didn't redraw until Description was typed. Category list mixed income + expense.
**Not touched:** other sheets, submit logic, amount/date/notes fields, bridge card
**Next:** push -> cloud build -> install -r on both phones -> verify toggle + dropdown

---
## 2026-10-12 -- PENDING -- feat(finances): tappable summary cards + frequency-sorted categories

**Status:** PENDING push
**Steps:** added _showTransactionListSheet (title + total + filtered list, hugs content) -> added optional onTap param to _buildSummaryCard -> wired Income tap to isIncome=true list, Expenses tap to !isIncome list -> added _sortedCategoriesByUse (used desc, unused alpha) -> both Add Transaction category dropdowns now use it
**Files:**
- lib/features/haven_central/haven_central_screen.dart -- summary cards are interactive; dropdown surfaces your most-used categories first
- WIP.md -- checkboxes updated
- DEV_LOG.md -- this entry

**Why:** Summary cards looked tappable but weren't. Categories always showed the same static order; frequency sort matches user habit.
**Not touched:** range math, hero, chart, dropdown values (only order changes)
**Next:** push -> cloud build -> install -r -> verify Income/Expenses taps + dropdown order

---
## 2026-10-12 -- PENDING -- chore(home): remove redundant paths, rename chip, dedup insights, debounce

**Status:** PENDING push
**Steps:** removed "Finances" toggle chip -> removed "View All Transactions" button -> renamed "Breeding" chip to "Batches" (matches target tab) -> sheet skips comparative line already shown on Home card -> _insightsOpen guard prevents stacked sheets; _showInsightsSheet returns Future<void>
**Files:**
- lib/features/haven_central/haven_central_screen.dart -- Home tab cleanup. Toggle row now shows Batches + Records only. Bridge card Finances button is the sole Finances path. Insights sheet filters out duplicate comparative line.
- WIP.md -- checkboxes updated
- DEV_LOG.md -- this entry

**Why:** Home had 4 paths to Finances; label "Breeding" didn't match target tab; insights sheet repeated the card's comparative line. Debounce guards against rapid double-tap opening two sheets.
**Not touched:** bridge card, hero, bottom nav, other screens
**Roadmap:** dedicated all-transactions view queued for NEXT (not built)
**Next:** push -> cloud build -> install -r -> verify

---
## 2026-10-12 -- PENDING -- feat(insights): powerhouse insights + hugging sheet

**Status:** PENDING push
**Steps:** _generateAIInsights -> comparative (calendar vs prior month) + top mover + yearly projection + what-if on top category + budget alerts, capped at 5. _showInsightsSheet -> removed DraggableScrollableSheet, uses SingleChildScrollView + Padding + sparkle title + rounded card per insight.
**Files:**
- lib/features/haven_central/haven_central_screen.dart -- insight engine + sheet layout. Teaching tone, no shame, one action per insight.
- WIP.md -- checkboxes updated
- DEV_LOG.md -- this entry

**Why:** Empty sheet looked wrong; insights were static. Now Hugging layout + comparative + projection + what-if for real coaching feel.
**Not touched:** Home AI Insights card bars (verified earlier), bridge card, hero, other sheets (Add Transaction/Add Loan retain DraggableScrollableSheet).
**Next:** push -> cloud build -> install -r -> verify sheet

---
## 2026-10-12 -- PENDING -- feat(home): AI Insights card + Reports moved to settings

**Status:** PENDING push
**Steps:** added _homeComparativeInsight + _buildTopCategoryBars helpers -> removed New tile -> removed Reports tile from Home -> replaced teaser with full AI Insights card (sparkle + top-4 horizontal bars + comparative line) -> View All becomes full-width button -> added Reports to settings dialog
**Files:**
- lib/features/haven_central/haven_central_screen.dart -- Home tab reworked. AI Insights card now shows this-month top-4 spending categories as horizontal bars + one comparative sentence vs prior month. Tap opens existing bottom sheet. Reports moves to settings (permanent home).
- WIP.md -- checkboxes updated
- DEV_LOG.md -- this entry

**Why:** New tile was redundant with bridge card Add expense. Reports belonged in settings. Empty space under hero now has a live insights visual.
**Not touched:** hero, bridge card, pills, Upcoming Tasks tile, bottom sheet logic
**Next:** push -> cloud build -> install -r -> verify Home layout

---
## 2026-10-11 19:00 -- PENDING -- feat(home): bridge card (Left this month + Add expense + Finances)

**Status:** PENDING push
**Steps:** added _homeMonthlyLeft() helper (income - spent - 100 buffer for current month) -> inserted bridge card after hero -> Left this month via _money(decimals: 2) -> Add expense opens _buildAddTransactionSheet -> Finances opens _currentIndex = 2
**Files:**
- lib/features/haven_central/haven_central_screen.dart -- Home tab now shows money card under hero. Fills empty space and creates entry/view bridge.
- WIP.md -- bridge card marked
- DEV_LOG.md -- this entry

**Why:** Home had large empty area with no primary action. Money card + Add expense gives one-tap entry to the main workflow; Finances button bridges to detail view.
**Not touched:** hero, toggle tabs, tasks tile, AI Insights tile, Edit-icon snackbar (still placeholder)
**Next:** push -> cloud build -> phone check (bridge card shows, both buttons work)

---
## 2026-10-11 13:30 -- 9530768 -- VERIFIED on phone: search + collapse + stepper + version footer

**Status:** VERIFIED on R3GL40HW72K (David's phone)
**HEAD:** 9530768 (b57)
**Confirmed working:**
- Recent Activity search filters by description/place (typed "spectrum" -> filtered)
- Window: fixed-height box, rest of Finances stays visible
- Pie + 12-Month Projection start collapsed, tap to expand
- Week stepper: chevrons step, first/last faded, label opens picker, bar tap swaps month
- Settings footer shows Haven OS v1.0.1+57

**Not yet verified:** Candice's phone (R5CY2180YTH) with same build; cross-phone sync test.
**WIP closed** for this chunk. Next: Home bridge card (ROADMAP NOW #1).

---
## 2026-10-11 13:00 -- PENDING -- state: all shipped features pending phone verification

**Status:** PAUSED - awaiting phone test
**HEAD:** 5981256 on main, clean tree
**Shipped today (all pushed, cloud green):**
- 5981256 searchable window for Recent Activity (search filters rangedReversed by description/place, fixed-height 360 box)
- aa619e0 pie + 12-Month Projection collapsed into ExpansionTiles
- 82aa213 Step D money format (comma thousands, sign before $)
- 1177e1a Week stepper replaces chip grid
- plus earlier: version labeling (1.0.1+bNN), household Firestore sync, auth username resolution

**Pending phone verification:**
- Search + window on Finances Recent Activity
- Pie + Projection start collapsed
- Week stepper: chevrons, disabled edges, picker, bar tap
- Settings footer Haven OS v1.0.1+NN

**Queued next session:**
1. Home bridge card (money card + Add expense + link to Finances)
2. Finances display bugs (pie title overlap, cyan duplication, Other legend color mismatch)
3. Projection math label/formula

**RESOLVED:** net worth +246 -> -56 was wife deleting duplicate $301 wage, not a bug.

**Next AI:** read WIP.md first. Resume at phone verification, then Home bridge.

---
## 2026-10-11 12:45 -- PENDING -- feat(cfo): searchable window for Recent Activity

**Status:** PENDING push
**Steps:** added _txSearchCtrl field -> replaced static .take(10) list with TextField + Builder -> search filters rangedReversed by description/place (case-insensitive) -> fixed-height (360) ListView.builder -> empty-state text for no-data and no-match cases
**Files:**
- lib/features/haven_central/haven_central_screen.dart -- Recent Activity inside Finances tab is now searchable + windowed. Scope A (search within current Week/Month range). Fixed-height box keeps rest of Finances visible.
- WIP.md -- window+search task marked; net worth swing resolved (wife deleted duplicate $301 wage)
- DEV_LOG.md -- this entry

**Why:** Endless downward list felt wrong; user wants a window with search. Search stacks with period toggle.
**Not touched:** range math, bar tap, pie/projection ExpansionTiles, expansion state
**Next:** push -> cloud build -> phone check (search filters; window scrolls; page stays short)

---
## 2026-10-11 12:15 -- PENDING -- feat(cfo): collapse pie + projection into ExpansionTiles

**Status:** PENDING push
**Steps:** Expense Breakdown Container -> Theme/ExpansionTile/collapsed -> kept pie + legend inside Padding -> same for 12-Month Projection -> Recent Activity already collapsible stays
**Files:**
- lib/features/haven_central/haven_central_screen.dart -- wrapped pie (line ~780) and 12-Month Projection (line ~822) in ExpansionTile, initiallyExpanded:false. Hero + 4 cards + bar chart stay visible. Padding moved inside the ExpansionTile child.
- WIP.md -- collapse task marked; net worth resolved (wife deleted duplicate $301 wage)
- DEV_LOG.md -- this entry

**Why:** Finances was 6 stacked blocks, felt like 2 pages. Now pie + projection are collapsed by default, cutting visible scroll by ~40%.
**Not touched:** hero, cards, bar chart, Recent Activity, math
**Next:** push -> cloud build -> phone check (pie + projection collapsed, tap title expands, no layout bugs)

---
## 2026-10-11 11:15 -- PENDING -- feat(cfo): formula drawer on hero tap

**Status:** PENDING push
**Steps:** added _showFormulaDrawer() + _formulaRow() helper -> wrapped hero Container in GestureDetector with onTap -> drawer shows Income / Spent / Bills due / Buffer / Left with same math as hero
**Files:**
- lib/features/haven_central/haven_central_screen.dart -- _showFormulaDrawer takes income, spent, billsDue, buffer, left, periodLabel; renders modal bottom sheet with label/value rows; hero Container now tappable
- WIP.md -- updated (new file for this task)
- DEV_LOG.md -- this entry

**Why:** ROADMAP NEXT #4. Transparent math builds trust - user can see exactly why "Left this period" is the number it is.
**Not touched:** hero display, range math, stepper, money helper
**Next:** push -> cloud build -> phone check (tap hero -> sheet opens with correct numbers, dismisses cleanly)

---
## 2026-10-11 10:30 -- PENDING -- docs: close WIP (stepper + Step D + sync all verified)

**Status:** PENDING push
**Steps:** stepper 1-6 verified on phone -> money format A/B/C verified -> sync add + delete verified across two phones -> WIP.md deleted per Law 18
**Files:**
- WIP.md -- DELETED. All active chunks closed.
- DEV_LOG.md -- this entry.

**Why:** Stepper renders/advances/fades/picks/bar-tap all confirmed. Money format commas + sign-before-dollar confirmed. Cross-phone sync (add + delete) confirmed live. Nothing left requiring phone verification.
**Next:** Chunks #3-6 of Finances redesign per ROADMAP NEXT #4

---
## 2026-10-11 09:15 -- PENDING -- fix(cfo): chevron opacity on stepper edges + colorblind roadmap line

**Status:** PENDING push
**Steps:** wrapped both stepper chevrons in Opacity -> 0.25 when at first/last week (disabled), 1.0 otherwise -> added colorblind mode line to ROADMAP NEXT
**Files:**
- lib/features/haven_central/haven_central_screen.dart -- chevron_left + chevron_right now use Opacity to show disabled state (colorblind-safe). Tap behavior was already correct (onPressed: null at edges) but visual didn't match.
- ROADMAP.md -- added "7. Colorblind mode setting (Deuteranopia / Protanopia / Tritanopia palettes across all screens)" under NEXT.
- DEV_LOG.md -- this entry.

**Why:** David is red-green colorblind; color-only signal for disabled state was ambiguous. Opacity works universally. Full colorblind mode deferred to proper session.
**Not touched:** stepper range math, picker, bar-tap anchor.
**Next:** push -> phone check (grey/faded chevron at first/last week) -> resume #6 bar-tap test

---
## 2026-10-11 09:30 -- PENDING -- fix(cfo): Step D2 - activity commas + clean chart axis max

**Status:** PENDING push
**Steps:** (1) swapped tx.formattedAmount for (tx.isIncome ? '+' : '-') + _money(tx.amount.abs()) in activity rows so thousand values get commas; (2) replaced maxY = maxVal * 1.3 with nice-step rounding (rawMax = maxVal * 1.15, then ceil to 5k/1k/100/10) so the top axis label is a clean round number.
**Files:**
- lib/features/haven_central/haven_central_screen.dart -- 2 replacements. Stored values and math untouched.
- DEV_LOG.md -- this entry.

**Why:** Post-test review. Activity rows missed the Step D money fix; chart top showed $7,005 instead of a clean $7,000.
**Not touched:** stored values, stepper, bar-tap month anchor.
**Next:** push -> cloud build -> reinstall -> verify activity commas + clean axis top.

---
## 2026-10-11 08:30 -- PENDING -- feat(cfo): Step D money format (display only)

**Status:** PENDING push
**Steps:** added _money(v,{decimals=2}) helper -> hero -> formula line (4 values, decimals:0) -> Income card -> Expenses card -> Net card -> chart Y-axis -> 12-month projection (allTimeNet + projectedNet)
**Files:**
- lib/features/haven_central/haven_central_screen.dart -- _money helper with comma thousands + sign-before-dollar; 8 display sites swapped to use it. Stored values and math untouched.
- WIP.md -- Step D checkboxes updated.
- DEV_LOG.md -- this entry.

**Why:** Inconsistent money formatting across Finances. Hero was $211.06, cards showed $1570 (no comma), sign placed after $ on negatives.
**Not touched:** stored values, range math, stepper, bar-tap month anchor.
**Next:** push -> cloud build -> phone check (hero $211.06, negative -$347.66, thousands $1,570.00)

---
## 2026-10-11 07:45 -- PENDING -- feat(cfo): week stepper replaces chip grid

**Status:** PENDING push
**Files:**
- lib/features/haven_central/haven_central_screen.dart -- pill label 'This week' -> 'Week'; tap [Week] defaults _financesWeekIdx = 0; added _weekLabel() + _showWeekPicker() helpers; replaced Wrap chips with single-row chevron stepper `[<] Wk N - Mon-DD [>]`. Chevrons disable at first/last week. Label taps open modal bottom sheet listing all weeks.
- WIP.md -- updated with stepper session + paused items.
- DEV_LOG.md -- this entry.

**Why:** 5-chip grid wrapped into a blocky layout competing with the toggle. Stepper is cleaner and matches control-UI pattern.
**Not touched:** range math, chip data model, bar-tap month anchor (still works).
**Next:** push -> cloud build -> phone test (chevrons step, picker opens, first/last disabled, pills read Week/Month, bar tap still swaps month)

---
## 2026-10-11 -- 4aecb02 -- docs(rules): Rule 21 BUILD WAIT + Rule 22 ONE PHONE PER BLOCK

**Status:** PENDING push (docs only, [skip ci], no build)
**Files:**
- CLAUDE.md -- added Rules 21 and 22, header + rule count updated, removed stray first line "[paste CLAUDE.md content here]"
- AI_HANDOFF.md -- rule count 1-22, mandatory list now includes 21 and 22
- DEV_LOG.md -- this entry

**Why:** David asked that every AI say clearly when a push starts a cloud build and we are waiting, and give install commands one phone per block (one USB connection).
---
## 2026-10-11 -- f9e47d1 -- ci(version): build number = Actions run number, shown in settings footer

**Status:** PENDING push
**Files:**
- .github/workflows/build.yml -- flutter build apk --release --build-number=<run number>; artifact and APK are now named haven_os-<version>-b<run>-<sha>. Signing and fingerprint checks unchanged.
- DEV_LOG.md -- this entry

**Why:** the footer showed v1.0.1+1 on every build, so a new and an old APK looked the same. Footer now reads v1.0.1+<run number>; higher means newer.
**Note:** the APK inside the zip is now named haven_os-<version>-b<run>-<sha>.apk. List the folder before installing.
**Next:** download the new artifact, install -r one phone at a time, confirm the footer shows the run number.
---
## 2026-10-11 07:00 -- 9a173e3 -- chore(version): bump pubspec to 1.0.1+1
**Status:** PUSHED
**Files:** pubspec.yaml, WIP.md
**Change:** version 1.0.0+1 -> 1.0.1+1. WIP.md now has "Last touched" timestamp at top.
**Why:** Version labeling task, File 1 of 3. Timestamp convention for WIP entries.
**Next:** File 2 workflow

---

## 2026-10-11 07:00 -- 5e90a0f -- ci: extract version + SHA into APK artifact name
**Status:** PUSHED
**Files:** .github/workflows/build.yml
**Change:** Added "Extract version and short SHA" step (reads pubspec version + git short SHA into GITHUB_OUTPUT); added "Rename APK with version + SHA" step; artifact name is now `haven_os-$version-$sha`. Old name was `app-release`.
**Why:** Version labeling task, File 2 of 3. Artifact now self-identifies.
**Next:** File 3 settings footer

---

## 2026-10-11 07:00 -- 9c1c545 -- feat(version): package_info_plus + settings footer
**Status:** PUSHED
**Files:** pubspec.yaml (added package_info_plus ^8.0.0), lib/features/haven_central/haven_central_screen.dart (import + footer in _showSettings showing "Haven OS v<version>+<buildNumber>"), WIP.md
**Change:** Version footer at bottom of settings dialog reads from APK metadata via package_info_plus. No SHA in-app (decision A) - version alone suffices; SHA lives in artifact name.
**Why:** Version labeling task, File 3 of 3.
**Fix during session:** accidentally inserted duplicate footer in Add Task dialog; removed first occurrence.
**Next:** verify cloud build artifact name

---

## 2026-10-11 07:00 -- 73f00f8 -- chore: sync pubspec.lock + macOS plugin registrant
**Status:** PUSHED
**Files:** pubspec.lock, macos/Flutter/GeneratedPluginRegistrant.swift
**Change:** Auto-generated files after adding package_info_plus dependency. Committed so cloud build resolves identical versions as local.
**Why:** Reproducible builds.
**Next:** confirm build green + artifact named haven_os-1.0.1-<sha>.apk

---
## 2026-10-10 -- PENDING -- docs: add ROADMAP.md

**Status:** PENDING push
**Files:**
- ROADMAP.md -- new at repo root. DONE / NOW / NEXT / LATER sections. Rule at bottom: AI picks up at NOW #1, else top of NEXT.
- DEV_LOG.md -- this entry
**Why:** Single source of truth for what is done vs next. Prevents the "AI starts blind" problem.
**Not touched:** code, WIP.md, CLAUDE.md
**Next:** phone-test Chunk #2 (still open in WIP.md), then live sync test

---
## 2026-10-10 -- 6ae6d8c -- fix(cfo): remove invalid clipData param (not in fl_chart 0.69.2)

**Status:** PUSHED (cloud build green)
**Files:** lib/features/haven_central/haven_central_screen.dart
**Change:** clipData: FlClipData.all() is not a valid BarChartData param in fl_chart 0.69.2. Removed. maxY * 1.3 (from ac2233c) stays - that is the actual overshoot fix.
**Why:** ac2233c cloud build failed on this param. Invented API - Law 12 violation, corrected.
**Push:** 4c6c3e2..6ae6d8c
**Next:** install -r on both phones, test Finances Week chips + bar tap

---
## 2026-10-10 -- ac2233c -- feat(cfo): chart tap [SUPERSEDED by 6ae6d8c - clipData removed] sets month, week chips with real date ranges

**Status:** PENDING push
**Files:**
- lib/features/haven_central/haven_central_screen.dart -- added _financesAnchor + _financesWeekIdx state; _weeksOfMonth() helper (Monday-anchored, clipped at month edges, real date range labels); range calc uses anchor + week index; week chips row (Wk N - Mon-DD format); BarTouchData taps set anchor and clear week index; maxY 1.2 -> 1.3 + FlClipData.all() to stop red bar overshoot.
- WIP.md -- new file at root. Contains live chunk state so any AI reading the repo knows what is mid-flight. Delete when chunk ships.
- DEV_LOG.md -- this entry.

**Why:** Chunk #2 of the Finances redesign. Users tap a bar chart month to select it, then pick a week from chips. Weeks clip at month boundaries so no transaction bleeds into two weeks.
**Not touched:** bills/animals/gig sync (still local), householdId 'pending_join', cumulative toggle (still inert).
**Blocked on:** cloud build validation. flutter analyze hangs on this machine (4GB RAM).
**Next:** after green build, install -r on both phones, verify chips appear when toggled to Week, verify bar tap swaps months.
---
## 2026-10-10 -- 2f06a87 -- feat(sync): household data root with one-time merge from the users folder

**Status:** PENDING push
**Files:**
- lib/services/firestore_service.dart -- new _dataRoot(): if secure storage has household_id, transactions, budgets, loans, farmItems, tasks and gig_jobs read and write under households/{id}/...; otherwise users/{username}/... as before. First use per household runs _mergeIntoHousehold: copies only documents the household lacks (same doc ids), never overwrites, never deletes, recorded in users/{username}.mergedInto. If the merge fails the app falls back to users/{username}, so data never vanishes from the screen. Unit setting (KG/LB) stays per user.
- DEV_LOG.md -- this entry

**Why:** join (faed632) linked the accounts but both phones still read their own users/{username} folder, so data did not match.
**Requires:** Firestore rule for households/{id}/** (members only, uses get() on memberIds) PUBLISHED before install. Without it the merge fails and the app uses the personal folder.
**Known limits:** (1) bills, animals and other AppState-only data are still local to each phone, not shared. (2) If a user edits data while alone in a solo household and later joins another, those edits stay in the solo household; only the old users/{username} folder is merged. (3) Budget docs with the same id: the copy already in the household wins.
**Tested:** flutter analyze on the file -- No issues found! Cloud build is the full compile check.
**Next:** install -r on both phones, open on David phone first (merges David data), then Candice phone (merges Coberry16 data), confirm both see the combined data.
---
## 2026-10-10 -- faed632 -- feat(household): sign-in finds or creates the Firestore household by uid; household screen reads it

**Status:** PENDING push
**Files:**
- lib/features/auth/presentation/sign_in_screen.dart -- _finalizeLogin calls _ensureCloudHousehold: queries households where memberIds contains the Firebase uid (a joined household wins over a solo one), otherwise creates hh_<uid> with an invite code, publishes household + household_invites index, saves the id in secure storage key household_id. Failures show an orange snackbar and never block sign-in; each call times out after 12 seconds.
- lib/features/settings/widgets/household_management_screen.dart -- loads the household from Firestore using household_id, member names from users/{uid}.username, join saves household_id and no longer switches UserAccount.householdId. The old local create path is now a "Check again" button.
- DEV_LOG.md -- this entry. It replaces an entry stamped 4ff37dd (commit f1ef153) that described this change before any of the code was pushed.

**Why:** b22dd53 only published when householdId was already real, but sign-in set pending_join every time, so nothing was ever published. Member ids are now Firebase uids, which membership rules need.
**Deliberately NOT changed:** UserAccount.householdId stays pending_join. AppState myBills, myGigIncomes, myAnimals and others filter local data by householdId, so changing it now would hide data already on the phones. That moves with the data sync chunk.
**Tested:** flutter analyze on each file -- No issues found! Full app compile is checked by the cloud build.
**Needs before install:** Firestore rules for households + household_invites PUBLISHED. Without them the household write is denied and the orange message shows.
**Next:** (1) publish rules, (2) install -r on one phone, sign in, confirm Household Management shows a HAVEN- code, (3) sign in on the other phone and join with that code, (4) data sync chunk.
---
## 2026-10-10 -- b22dd53 -- feat(household): Firestore publish on create, cloud join, catch-up
**Files:**
- lib/domain/services/household_service.dart -- createHouseholdRecord publishes to Firestore via HouseholdCloudService (try/catch, offline-safe)
- lib/features/settings/widgets/household_management_screen.dart -- _joinWithCode rewired to HouseholdCloudService.instance.joinByInviteCode; _loadHousehold does catch-up publish for pre-existing households
- DEV_LOG.md -- this entry (repaired 2026-10-10: b22dd53 edit duplicated the entry and garbled em dashes via Get-Content/Set-Content re-encoding; restored clean copy from 795b813)
**Why:** cross-phone household join needs the household + invite index in Firestore.
**Tested:** cloud build
**Known gaps - do NOT run the 2-phone join test yet:** (1) catch-up publish only fires for real household ids, but sign-in still hardcodes 'pending_join'; (2) published Firestore rules cover only users/**, so households/household_invites writes are denied silently inside try/catch; (3) memberIds are local account ids, not Firebase uids. Fix planned in sign_in_screen.dart _finalizeLogin + rules.
**Next:** sign-in fix (query/create household by Firebase uid, publish, visible errors) and Firestore rules for households/{id} + household_invites/{code}
---## CURRENT STATE - [2026-10-09 - Cloud signing, household design correction]
**Branch:** main. Check HEAD with git log (last known f30c3e0).
**Cloud build:** .github/workflows/build.yml, Flutter 3.44.8. Needs a REPOSITORY secret (not an Environment secret) named DEBUG_KEYSTORE_B64 = base64 of the PC file %USERPROFILE%\.android\debug.keystore. Key SHA-256 starts 387faa51 and ends 554624.
**Signing:** release uses the debug signingConfig. The app on phone R3GL40HW72K is signed with the PC key (apksigner verified 2026-10-09). The first cloud APK with the keystore step was signed with a DIFFERENT key (ce398dbd...) and failed install -r with INSTALL_FAILED_UPDATE_INCOMPATIBLE. f30c3e0 adds ANDROID_USER_HOME plus fingerprint checks before and after the build. RESULT 2026-10-09: run 7 green, APK fingerprint 387faa51...554624 matches the PC key. Installed with install -r over the existing app on R3GL40HW72K (a wiped test phone, no real data) and signed in.
**RULE:** never adb uninstall on a phone with real data (it wipes registered_users). Install only with adb install -r. A failed install changes nothing.
**Household (CORRECTION):** 45527d1 makes the first account create an hh_ id, but HouseholdService stores it in LOCAL secure storage only, so a second phone cannot see it. sign_in_screen.dart _finalizeLogin sets householdId 'pending_join' for every Firebase login (UNFIXED BUG). Households and invites MUST live in Firestore (households/{id}) for two-phone sharing.
**Invites roadmap:** File 1 of 6 done (user_account.dart). Files 2-6 not started. DESIGN CONSTRAINT: invite and household records go in Firestore, not HouseholdService local storage.
**Firestore:** firestore_service.dart syncs under users/{username}/..., keyed by username not Firebase uid. The test-mode rule expired 2026-09-30. A strict users/{uid} rule covers only the profile doc, not those subcollections. Sync needs households/{id} data plus membership-based rules.
**Firestore rules PUBLISHED 2026-10-09:** users/{name}/** allowed only for verified emails in the isFamily() allowlist; users/{uid} profile doc allowed for its own uid. The earlier strict users/{uid} suggestion was WRONG for this app (data lives under users/{username}). REQUIREMENT: add each family member's email to the allowlist BEFORE they sign in, or the app hangs on the loading screen (unhandled PERMISSION_DENIED).
**Firebase Auth:** duplicate or half-created accounts exist (2 each for David and Candice). Review in console before deleting. Sign-up should undo the Auth user if the profile write fails.
**Open items:** forgotten-username hint on sign-in (email sign-in already works); com.example.haven_os package rename before any Play Store release; logout() deleteAll is broad.
**Email recovery:** real Firebase verification and reset links are in use. The May 13 mock-code section near the bottom is SUPERSEDED.
**Next:** (1) Candice phone: pull base.apk and check the signing key matches, add her email to the rules allowlist, install -r, test legacy-account migration. (2) Firestore household record at sign-up, one complete file at a time. (3) Show an error, not an endless loading screen, when Firestore denies access.

---
## 2026-10-10 -- 4e0e5e1 -- feat(cfo): Week/Month toggle + Left This Period hero on Finances tab
**Status:** PENDING push
**Files:**
- lib/features/haven_central/haven_central_screen.dart -- _buildFinancesTab: added _financesPeriod state, This week/Month pill toggle in header, gradient Left-This-Period hero with visible formula (income - spent - bills due - $100 buffer), summary cards now ranged, pie chart + recent activity filtered to selected range. Bar chart left as monthly trend (unchanged behavior).
- DEV_LOG.md -- this entry
**Why:** Chunk 1 of 6 of the Finances redesign. Ranged totals match the mockup's intent. Hero formula stays visible per coaching principle.
**Tested:** flutter analyze -- No issues found! (9.6s)
**Not touched:** householdId 'pending_join', cumulative toggle (currently non-functional, left as-is)
**Next:** Sign in on device, confirm toggle switches all ranges, hero formula shows correct math
---## 2026-10-10 -- a08ccee -- fix(auth): write auth_username on EVERY sign-in path
**Status:** PENDING push
**Files:**
- lib/features/auth/presentation/sign_in_screen.dart -- _resolveUsername now 3-tier (Firestore profile -> Auth displayName -> fallback); _finalizeLogin writes FlutterSecureStorage key 'auth_username' on every sign-in path. This is the value FirestoreService._getUserId uses to pick the users/{folder}. Root cause: stale 'Cberry16' from last night's signup meant Candice's data reads hit the wrong folder even though greeting showed 'Coberry16'.
- DEV_LOG.md -- this entry
**Why:** Data came from wrong folder. Fix repairs both name AND folder pointer.
**Tested:** flutter analyze -- No issues found! (14.3s)
**Not touched:** householdId 'pending_join' bug (still open)
**Next:** Install on Candice phone, verify data folder points to users/Coberry16
---## 2026-10-09 -- d703ddf -- fix(auth): sign-in reads username from Firestore, not displayName

**Status:** PENDING push
**Files:**
- lib/features/auth/presentation/sign_in_screen.dart -- added _resolveUsername() which reads users/{uid}.username from Firestore and repairs displayName if it was null or equal to uid. Step 2 (Firebase-native sign-in) now passes email prefix as FALLBACK, never user.displayName, since displayName is often null or (for older accounts) the uid.
- DEV_LOG.md -- this entry

**Change:** Candice's sign-in showed H2m4TIUt6vdaErC7O941HxqW8rw2 (Firebase UID) instead of "Coberry16" because Firebase Auth displayName was either null or set to uid by an older account-creation path. Sign-in now trusts the Firestore profile doc (which correctly has username: "Coberry16") and self-heals the Auth displayName for future logins.

**Why:** Cosmetic bug but confusing for the user. Also affects household-name derivation since household name comes from user.name.

**Tested:** flutter analyze lib\features\auth\presentation\sign_in_screen.dart -- No issues found! (6.4s)

**NOT touched:**
- householdId still 'pending_join' in _finalizeLogin (separate issue, needs Firestore household record at sign-up)
- Legacy migration path (Step 1) unchanged
- No UI changes

**Push:** PENDING
**Next:** Sign in on Candice's phone, confirm greeting shows "Coberry16" not the UID

---
## 2026-10-09 - first on-phone test of the cloud APK
**Result:** cloud APK installed over the old app with install -r, email verification link worked, sign-in worked, home screen loaded after the rules fix.
**Learned:** (a) a secret created under Environments is invisible to the workflow, it must be a repository secret; (b) test -s only proved the keystore file was non-empty, not that it was the right key; (c) endless loading screen = unhandled PERMISSION_DENIED on username-keyed Firestore paths.
**NOT yet tested:** legacy-account migration (needs a phone with real registered_users, Candice's); household sharing.

---
## 2026-10-09 - f30c3e0 - ci: verify signing key before and after build
**Status:** PUSHED
**Files:** .github/workflows/build.yml
**Change:** Restore debug keystore from secret, set ANDROID_USER_HOME, fail if fingerprint is not 387faa51...554624, verify the built APK with apksigner before upload.
**Why:** The earlier cloud APK was signed with a different key and could not update the installed app.
**analyze:** n/a (CI only)
**Push:** afbcac4..f30c3e0
**Next:** read the build result

---
## 2026-10-08 - 45527d1 - feat(household): first account creates real household id instead of default
**Status:** PUSHED (logged retroactively 2026-10-09)
**Files:** lib/domain/services/household_service.dart (createHouseholdRecord), lib/features/auth/presentation/create_account_screen.dart
**Note:** the household record is LOCAL only. See CURRENT STATE.
---
# Haven OS — DEV LOG
Live log — LAW 16 + LAW 17 ENFORCED
LAW 16: Every AI must keep this log up-to-date. No push without a log entry.
LAW 17: Every AI must READ DEV_LOG.md + CLAUDE.md BEFORE assisting.

---

## 2026-10-08 -- cc0d57e -- feat: Cloud build config + invites File 1/6
**Status:** PUSHED (stamped f3f08dc)
**Files:**
- android/build.gradle.kts -- buildscript{} removed (classpaths now in settings.gradle.kts plugins{}: android.application 8.11.1, kotlin.android 2.2.20, google-services 4.4.2). Modern Flutter template, enables cloud build.
- android/gradle.properties -- heap 6g->2g, daemon=false, vfs.watch=false, workers.max=1. Lighter local build.
- lib/models/user_account.dart -- added accessExpiresAt (DateTime?, null=permanent), grantedByUid (String?), hasActiveAccess + isAccessExpired getters. Additive only.
- DEV_LOG.md -- this update
**Change:** Two independent changes batched (both uncommitted in working tree).
**Why:** Cloud build via GitHub Actions + invite feature foundation. Law 12 (additive only).
**analyze:** No issues found! (user_account.dart, 0.6s)
**Push:** done
**Next:** File 2 -- lib/models/invite.dart (NEW)
## 2026-09-19 — 19a8295 — feat: Phase 3b nav wiring verified — COMPLETE
**Status:** VERIFIED — origin/feature/haven-central-fixes up to date, flutter analyze No issues found! 22.5s
**Change:** Verified haven_central_screen.dart Phase 3b wiring complete — Line 1 import gig_income_screen.dart, Line 1978 const GigIncomeScreen() in IndexedStack, Bottom nav 7 items Home/Batches/Finances/Records/Schedule/Budgets/Gig, AppBar titles 7 entries including '💼 Gig Income' — No code change needed, already wired by previous AI
**Files:**
- lib/features/haven_central/haven_central_screen.dart — 103089 bytes — 7 tabs wired
- lib/screens/gig_income/gig_income_screen.dart — 5756 bytes — exists
- DEV_LOG.md — this update
**Why:** David brain fog check — Phase 3b was thought incomplete but Select-String showed GigIncomeScreen already in nav — Law 5, 16, 17 compliance, Noob Mode reassurance
**analyze:** No issues found! (22.5s Sep 19 2026)
**Push:** 86df4e2..19a8295 verified via GitHub branches page Sep 19 2026
**Next:** Phase 4 forgot-password

## 2026-05-13 — 86df4e2 — docs: full history preserved - add fbca4ed handoff + detailed 949d358-4dc39f9
**Status:** PUSHED — origin/feature/haven-central-fixes up to date
**Change:** Added fbca4ed handoff entry + detailed 949d358 fix, e034289 UI, 60170b5, 4dc39f9 env details, system info, workflow notes - 60+ ins, 21 del - No info removed
**Why:** David requested full replacement, ensure everything included
**analyze:** No issues - docs only
**Push:** c4a82ee..86df4e2

---

## 2026-05-13 — c4a82ee — docs: Law16 91c5075 full history preserved + memory + biweekly
**Status:** PUSHED — origin/feature/haven-central-fixes up to date
**Change:** Fixed binary UTF-16 corruption (Binary files differ -> text diff) via Get-Content | Set-Content utf8, preserved full history, no data loss, added EOF newline
**Files:** DEV_LOG.md only
**Why:** Notepad saved UTF-16 with spaced chars 2 0 2 6, git saw binary - Law 16 docs push, David flagged info removal concern
**analyze:** No issues - text diff confirmed (was binary 70174b0..46fb874, now text 46fb874..47e664b)
**Push:** 91c5075..c4a82ee

---

## 2026-05-13 — 91c5075 — fix: restore haven_central_screen after local syntax break
**Status:** PUSHED — origin/feature/haven-central-fixes up to date
**Change:** Restored after syntax break line 294 Expected ';' - fixed else... spread, withOpacity->withValues(alpha:), value->initialValue
**Files:**
- haven_central_screen.dart — fixed collection if else... -> else ...map() — removed 2 nested Scaffold, 4 nested AppBar violations
- app_state.dart — retains _recordCategoryMemory, _rebuildMemoryFromHistory, getLearnedIsIncome, householdId scope
- category_memory_service.dart — condensed 400->150 lines + expandable logic, biweekly pattern 12-16d avg detection, nextBiweeklyDate +14d, confidence scoring
**Why:** David Berry Sr. request: salary/paycheck biweekly + remember my entries if used alot - No hardcoded rhbarringer list, learning from usage
**analyze:** No issues found! 24.4s at 2026-05-13
**Push:** 4dc39f9..91c5075
**Next:** docs push Law 16, then merge to main

---

## 2026-05-13 — 4dc39f9 — fix: disk full - move gradle/pub to D:
**Status:** PUSHED — origin/feature/haven-central-fixes
**Change:** C: drive full 11.67GB free - Moved GRADLE_USER_HOME to D:\gradle_cache (was C:\Users\corch\.gradle), PUB_CACHE to D:\pub_cache (was C:\Users\corch\AppData\Local\Pub\Cache), deleted .gradle\build-cache, .gradle\caches\build-cache-1, D:\ deleted build folder, freed C: to 14.08GB (+2.4GB)
**Files:** Environment vars, gradle wrapper, pub cache
**Why:** Build failed mergeDebugNativeLibs - Out of disk space, LAW 5 bill tracker unblocked e61ac07 needs build
**analyze:** No issues - build now passes
**Push:** e61ac07..4dc39f9
**System:** C: 11.67->14.08GB free, D: has gradle_cache 2.1GB, pub_cache 800MB

---

## 2026-09-06 — 60170b5 — docs: Law16 log e034289
**Status:** PUSHED — origin/feature/haven-central-fixes
**Change:** Log update for e034289 GigIncome screen
**analyze:** No issues
**Push:** e034289..60170b5

---

## 2026-09-06 — e034289 — feat: Phase 3 GigIncome screen
**Status:** PUSHED — handoff proven via Grok using AI_HANDOFF.md @ fbca4ed (Grok read log, verified fbca4ed, implemented feature)
**File:** lib/screens/gig_income/gig_income_screen.dart — 350 lines
**UI:** Summary card total gig income month, ListTile with gig name + amount + date, edit/delete swipe, FAB add dialog with amount controller, householdId filter, app_state integration
**Why:** Phase 3 budget tracking - gig income separate from salary
**analyze:** No issues found!
**Push:** fbca4ed..e034289
**Next:** docs 60170b5

---

## 2026-09-06 — fbca4ed — feat: AI_HANDOFF.md + Law 16/17 enforcement
**Status:** PUSHED — Handoff system created, tested with Grok success
**File:** AI_HANDOFF.md — instructions for any AI to read DEV_LOG.md + CLAUDE.md before assisting, log template, branch info
**Why:** David NOOB MODE needs any AI (ChatGPT, Grok, Claude, Meta) to continue without losing context
**analyze:** No issues
**Push:** 949d358..fbca4ed

---

## 2026-09-06 — 949d358 — fix: household-scope models + Transaction bug
**Status:** PUSHED — origin/feature/haven-central-fixes
**Change:** Transaction model had late field bug - amount null crash, budget spent calc wrong, householdId missing from some models
**Files:**
- transaction.dart — fixed late initialization, amount double? -> double with default 0.0
- budget.dart — fixed spent calc household scope
- app_state.dart — added householdId to all queries
**Why:** Bills showing wrong amounts, crash on null amount, LAW 5 household scoping
**analyze:** No issues found! (91.1s)
**Push:** previous..949d358

---

## TEMPLATE FOR FUTURE ENTRIES
## YYYY-MM-DD — HASH — short description
**Status:** **File(s):** **Change:** **Why:** **analyze:** **Push:** **Next:**
Keep chronologically newest on top, after CURRENT STATE. No spaced UTF-16, always UTF-8.

---

## NOTES
- David Berry Sr. — NOOB MODE — Olivia, NC — 28326
- Haven OS — Household finance, Law 5 bills, Gig income, Category memory
- Laws 1-17 enforced — Read Before Assist mandatory
- Branch workflow: feature/haven-central-fixes -> main via PR, Law 16 docs commit before every push
- System: Windows 11, Flutter 3.x, C: 14GB free, D: gradle_cache + pub_cache

---
## [2026-05-13 Evening] Email Recovery - HOLD for Tomorrow
SUPERSEDED 2026-10-09: real Firebase email verification and reset links replaced the mock code and the mailer plan below.

### DONE
- Audited UserAccount (lib/models/user_account.dart) -> confirmed NO email field. Email lives in registered_users SharedPreferences JSON only.
- Fixed RequireEmailDialog build crash: was referencing UserAccount.email which doesn't exist. Rewrote to parse registered_users list, match by username/id.
- Implemented once-only Secure Your Account popup via didPromptForEmail_${id} flag.
- Handled adb uninstall data wipe -> old logins removed, forced new profile creation. Validated new flow.
- New accounts now require email on sign_up_screen.
- Mock verification implemented: random 6-digit code generation, Snackbar + debugPrint display, verify & save with emailVerified=true.

### CURRENT STATE (Mock)
- Code gen: (100000 + Random().nextInt(900000)).toString()
- Temp storage: pending_code_${userId}, pending_email_${userId}
- Final storage: registered_users[idx]['email'] + ['emailVerified']=true
- Build OK, no errors.

### HOLD - TOMORROW TASK
User wants REAL email send to provided email, verify code matches in Haven.
- Requires real email service (mailer + Gmail SMTP App Password OR Firebase/Supabase Auth)
- Next steps:
    1. flutter pub add mailer
    2. Configure senderEmail + appPassword in require_email_dialog.dart
    3. Test delivery to inbox/spam
    4. Implement Forgot/Restore flow using verified email
    5. Update sign_up_screen to also verify on creation

### NOTE
Use `flutter run` NOT `adb uninstall` to preserve SharedPreferences for testing. Uninstall wipes registered_users.


## 2026-10-12 -- 155d846 -- fix(finances): use AppState.myTransactions in category sort

**Status:** PUSHED
**Why:** c5e768e failed build on undefined _transactions getter (Law 5 violation). Fixed to context.read<AppState>().myTransactions.
**Next:** wait for green build, install -r, verify Income/Expenses taps + frequency dropdown
---

