\# Haven OS — Full System Audit: Fix Plan



\*\*Repo:\*\* `berry82D/haven\_os`, branch `main`, HEAD `2e2f1bb`. Audit only, no code changed. \*\*Math formulas covered by a separate audit (still running when this plan was written).\*\* Sync findings inferred from code, not live-tested on two phones.



\*\*Architectural fact behind most findings:\*\* Finances/Home/Records/Schedule/Budgets render from \*\*Firestore streams\*\*, while Gig Income, bills, and CFO/assistant screens read \*\*AppState local SharedPreferences\*\*. The two stores are written independently and almost never reconciled.



\---



\## P0 — Wrong data / security / crash (fix first)



\### Security



\*\*P0-1 — PIN "Unlock (demo)" button bypasses PIN entirely.\*\*

`lib/features/auth/presentation/pin\_entry\_screen.dart:30-38` — button calls `unlockApp()` with no PIN entry. Plus: `PinEntryScreen` is never navigated to (zero references); `needsPinReentry()` has zero callers; `signIn()`/`unlockApp()` set `pinVerified=true` unconditionally; PIN \*\*is\*\* the account password (`create\_account\_screen.dart:79`); `logout()` wipes all secure-storage keys including everyone's PIN hash. Settings tile says "Password Lock / Enabled" hardcoded even with no PIN set.

\*\*Fix:\*\* Delete demo-unlock button; route through `PinEntryScreen` with real `PinLock.verifyPin()`; gate every entry point on `needsPinReentry()`; make PIN a separate secret from password; scope `logout()` to auth keys only; make Settings tile reflect `hasPin`.



\*\*P0-2 — No Firestore rules in repo; server-side authorization unverifiable.\*\*

Full repo tree has no `firestore.rules` / `firebase.json`. If console rules are permissive (`allow read, write: if request.auth != null`), any authenticated user can read/write any household.

\*\*Fix:\*\* Commit `firestore.rules` to repo, deploy from it; rules must check `request.auth.uid in resource.data.memberIds` on every collection.



\*\*P0-3 — Client trusts stored `household\_id` with no membership check; join needs only the invite code.\*\*

`firestore\_service.dart:119-175` — `\_dataRoot()` reads `household\_id` from secure storage, returns `households/{hid}` for any non-empty value, and `\_mergeIntoHousehold()` copies personal docs into that household with no `memberIds` check. `household\_cloud\_service.dart` — `joinByInviteCode()` adds caller to `memberIds` with no owner approval, expiry, or role. Invite codes are 4 chars from a 32-char alphabet (\~1M combos, enumerable). Household IDs are predictable (`hh\_<uid>`).

\*\*Fix:\*\* In `\_resolveRoot()`, fetch `households/{hid}` and return it only if `memberIds` contains the Firebase UID; require owner approval for cloud joins; add code expiry + rate-limiting; use unguessable household IDs.



\*\*P0-4 — New account on a shared phone is NOT clean.\*\*

`AppState.initialize()` (`app\_state.dart:257-315`) loads one device-wide `SharedPreferences` key `haven\_os\_data`. `logout()` clears only `\_joinRequests`/`\_households` — transactions/bills/etc. stay in memory. Logout → sign-in as different user without restart keeps previous user's data; next `\_saveData()` persists the mixed state back to the shared file. This violates the locked sharing-model spec (new accounts start clean).

\*\*Fix:\*\* Scope local storage per Firebase UID (`haven\_os\_data\_<uid>`); make `logout()`/`setCurrentUser()` clear all in-memory lists.



\*\*P0-5 — Invite levels (viewer/helper/admin) don't exist in code.\*\*

Zero occurrences of `viewer`/`helper`/`InviteService` in any `.dart` file. `PermissionService.can()` has zero callers; `Capability` has zero uses outside its own file; `UserAccount.accessExpiresAt`/`grantedByUid`/`hasActiveAccess` never read/written outside JSON. No UI to pick/change a level. Only real gates are `isParent` checks.

\*\*Fix:\*\* Implement specced levels as `Capability` sets, call `PermissionService.can()` in every mutating `AppState` method, enforce `accessExpiresAt` on sign-in — or delete the dead code and mark levels unimplemented.



\*\*P0-6 — User folder keyed by display username, not UID.\*\*

`firestore\_service.dart:93-100` — `\_getUserId()` returns `auth\_username` (display name). Two users can pick the same username; a username change orphans/cross-links the folder.

\*\*Fix:\*\* Key `users/{…}` and `\_dataRoot()` by Firebase UID; migrate username-keyed docs.



\*\*P0-7 — Logout incomplete; navigates to undefined routes.\*\*

`haven\_central\_screen.dart:2755-2765` — drawer Logout only deletes `auth\_username`, doesn't call `FirebaseAuthService.logout()`/`AppState.logout()`, leaves `household\_id`, `auth\_email`, PIN-verified state. `main.dart` defines no `routes:` table, yet code navigates to `'/auth'` and `'/home'` — undefined routes throw at runtime.

\*\*Fix:\*\* One `logout()` that signs out of Firebase, clears all auth keys + in-memory state, navigates to a real route; add the `routes` table to `MaterialApp`.



\### Data loss / corruption



\*\*P0-8 — One corrupt record poisons an entire load.\*\*

`AppState.initialize()` maps `fromJson` with no per-record try/catch. `Bill.fromJson` does `DateTime.parse(json\['dueDate'])` (throws on null); `Loan.fromJson` does `(json\['principal'] as num)` (throws on null); `Transaction.fromJson` throws on missing `date`. One bad record aborts the whole load, `\_isLoading` never clears, all local data disappears. Same on Firestore side: `streamLoans`/`streamTasks` map `fromJson` with no guard — one corrupt doc throws inside the stream and the whole screen errors.

\*\*Fix:\*\* Wrap each `fromJson` in try/catch, skip + log the bad record, load the rest. Same for Firestore stream maps.



\*\*P0-9 — Budget doc-ID collision = silent cross-month data loss.\*\*

`FirestoreService.saveBudget` uses doc ID = `budget.category` ONLY (`firestore\_service.dart:211-217`) while `streamBudgets` filters by `month`. Setting next month's budget for the same category \*\*overwrites this month's doc\*\* — old month's budget silently disappears. `deleteBudget(category)` deletes whichever month's doc exists.

\*\*Fix:\*\* Doc ID = `"<month>\_<category>"`; update `deleteBudget` to take the month.



\*\*P0-10 — `restoreFromBackup` is a no-op that discards the backup.\*\*

`app\_state.dart:669-672` ignores its `data` argument, calls `\_saveData()` — re-saving \*current\* state. "Restoring" a backup silently keeps current data. Related: `BackupService` (`backup\_service.dart`) has `buildBackupData`/`exportBackup`/`importBackup` but \*\*zero callers\*\* anywhere.

\*\*Fix:\*\* Actually parse `data` into the lists and persist, with confirmation prompt. Wire Settings Export/Import/Reset to `BackupService` + `restoreFromBackup()`, or delete the service.



\*\*P0-11 — Two stores, two write paths, never reconciled.\*\*

Add Transaction sheet saves \*\*Firestore-only\*\* (`haven\_central\_screen.dart:2033-2035`, never `AppState.addTransaction`); Teen/Preview save \*\*AppState-only\*\* (`teen\_dashboard.dart:422,493`; `preview\_screen.dart:276`, never Firestore). Sheet transactions invisible to AppState readers (assistant, CFO); teen/preview transactions invisible to Finances and to the other phone.

\*\*Fix:\*\* Single write path that writes Firestore + local (or migrate all screens to Firestore streams).



\*\*P0-12 — Pre-bridge gig entries still invisible to Finances; gig delete/edit diverge by store.\*\*

`addGigIncome` writes local-only, never Firestore. `\_importGigJobs` only imports the `gig\_jobs` collection, never local `GigIncome` rows. `updateGigIncome` (`app\_state.dart:604-620`) only updates a linked Transaction \*if one is found\* — creates none when missing. A pre-bridge entry has `transactionId == ''` and no Transaction; no code backfills it. `deleteGigIncome` deletes local-only — Firestore Transaction stays, Finances keeps showing deleted gig income. Conversely `\_confirmDeleteTransaction` deletes Firestore-only — local `GigIncome` remains, Gig tab still counts it. `updateGigIncome` never writes to Firestore, so Finances never sees gig edits.

\*\*Fix:\*\* One-time backfill — for every `GigIncome` with no linked Transaction, create one (both stores); make `updateGigIncome` create the link when missing; make every gig add/update/delete write through to both stores.



\*\*P0-13 — Bills and animals are local-only, never synced; live app cannot add a bill at all.\*\*

`AppState.initialize()` loads bills/animals from SharedPreferences only. `FirestoreService` has zero bill/animal methods; `\_syncCollections` lists transactions/budgets/loans/farmItems/tasks/gig\_jobs — no bills, no animals. Candice can't see David's bills/animals and vice versa. Worse: the only bill-add UI (`BillsTab`) lives in `LedgerScreen`, which nothing navigates to (sign-in goes only to `HavenCentralScreen`) — yet Finances subtracts local `myBills` as "bills due."

\*\*Fix:\*\* Add bills (and animals) to Firestore sync collections and expose a reachable bill-add UI, or stop subtracting bills Finances cannot see.



\*\*P0-14 — `Transaction` constructor silently rewrites user input.\*\*

`lib/models/transaction.dart:66-76` — "category decides income" rule forces `isIncome = true` whenever the category contains substrings like `'pay'`, `'deposit'`, `'rental'` — an expense explicitly marked as expense flips to income if its category contains e.g. "pay" ("Repayment", "PayPal fee"). `amount.abs()` silently flips negative amounts. Stored data ≠ entered data.

\*\*Fix:\*\* Only apply the category rule when `isIncome` was not explicitly supplied; reject (don't silently flip) negative amounts.



\*\*P0-15 — Add Transaction has NO max/sanity validation; `TransactionValidator` is dead code.\*\*

`haven\_central\_screen.dart:2008-2035` — save requires only `desc.isNotEmpty \&\& amount != null`. `amount == 0` saves a $0 transaction; negative input silently flips positive via `amount.abs()`; any huge value (`10795348507`, `$40,000` instead of `$400.00`) saves with no warning. Amount `TextField` has no input formatter. `core/validators/transaction\_validator.dart` has `validateAmount` (>0), `validateDate` (rejects future), `validateDescription` — \*\*zero callers\*\* anywhere.

\*\*Fix:\*\* Reject `amount <= 0`; add currency input formatter; add sanity confirm ("Amount over $X — is this right?") before save; call `TransactionValidator` in the Add Transaction save path and every other entry point.



\*\*P0-16 — Budget tab compares ALL-TIME spend/income against this month's budget.\*\*

`haven\_central\_screen.dart:1353-1354` — "Income this month" sums \*all\* transactions, no date filter. Lines 1388-1389 — "spent" per budget category is all-time spend vs \*this month's\* budget limit. Insights budget check (line \~518) correctly uses current-month spend — the two surfaces disagree, and the Budget tab overstates spent/income for anyone with history.

\*\*Fix:\*\* Filter both `incomes` and `spent` to the current calendar month (`!isBefore(monthStart) \&\& isBefore(monthEnd)`).



\*\*P0-17 — Monthly chart off-by-one: last day of previous month counts in BOTH months.\*\*

`haven\_central\_screen.dart:826-832` — `monthTxs` uses `t.date.isAfter(monthStart.subtract(Duration(days: 1)))` instead of `!isBefore(monthStart)`. Any transaction on the last day of the previous month after 00:00 is counted in both months' bars.

\*\*Fix:\*\* Replace with `!t.date.isBefore(monthStart) \&\& t.date.isBefore(monthEnd)`.



\*\*P0-18 — `\_spendWindow` previous window is one day shorter than current.\*\*

`haven\_central\_screen.dart:167-180` — `curEnd = startOfToday + 1 day` (includes all of today) but `prevEnd = prevStart + prevDay days` = midnight at the \*start\* of the same day-of-month last month (excludes all of that day). On Oct 15 the comparison is 15 days vs 14 days. Related: `startOfToday.add(Duration(days: 1))` is 23h/25h across DST.

\*\*Fix:\*\* `prevEnd = prevStart.add(Duration(days: prevDay + 1))` capped at 1st of current month; use calendar-day arithmetic, not 24h durations.



\*\*P0-19 — Combined stream can wedge UI on infinite spinner; rebuilt every build (leak).\*\*

`\_getAllStreams()` (`haven\_central\_screen.dart:2557-2605`) attaches six listeners with no `onError`; `checkAndEmit` only fires when all six slots are non-null. One stream error (e.g. malformed doc, see P0-8) → `latestData` never completes → `CircularProgressIndicator` forever. `build()` calls `\_getAllStreams()` (`:2628`), creating a new `StreamController` + 6 listeners each time, never closed.

\*\*Fix:\*\* Add `onError` to each listener (emit last-known/empty + surface error); hoist combined stream to a field created in `initState`, closed in `dispose`.



\*\*P0-20 — Duplicates: no content dedup, no submit guard, import races, merge id-only.\*\*

\- `addTransaction` has zero dedup (`app\_state.dart:366-371`) — plain `\_transactions.add(tx)`.

\- `addGigIncome` "dedup" branch still executes `\_gigIncomes.add(income)` before returning (`app\_state.dart:564-572`) — double-tap Save = 2 `GigIncome` rows, 1 Transaction; Gig tab month total double-counts. It also checks local `\_transactions` only, but Finances renders the Firestore stream and `addGigIncome` never calls `saveTransaction` — guard can't see other-phone/sheet transactions.

\- `\_importGigJobs` (`haven\_central\_screen.dart:109-138`) dedups only by `gigIncomeId` against the \*local\* list, creates Transactions with fresh `millisecondsSinceEpoch` ids each run. On fresh install / second phone / reinstall / if it runs before `initialize()` finishes (called from `initState` despite "one-time" comment; `main.dart:13` launches `initialize()` unawaited), local list is empty → import re-creates duplicate Firestore Transactions with new ids. Imported Transactions are orphans: hardcoded description `' Gig Job'` (leading space), platform dropped, `net <= 0` jobs silently skipped.

\- No content-based dedup anywhere — Candice's double-entry (two distinct ids, same job) passes both guards by design.

\- No submit/in-flight guard on any form (transaction sheet, loan, task, bill, farm, gig) — rapid double-tap = two rows with different ids. (Budget is the exception: doc id = category, re-save overwrites.)

\- Household merge dedups by doc id only, runs once — same logical transaction under different ids on two phones pre-merge is copied twice; later personal-folder docs never merged; failed merge silently falls back to personal folder while user keeps writing there.

\*\*Fix:\*\* (a) In `addGigIncome` dedup branch, `return` before adding to `\_gigIncomes`; write linked Transaction to Firestore; dedup against Firestore set. (b) Import: dedup against Firestore transaction set before inserting; deterministic id from `job.id`; await `initialize()` before importing; gate with persisted "imported" flag; create matching `GigIncome` per imported job; preserve platform; import `net <= 0` jobs. (c) Content-similarity flag per David's rule — same platform/date/amount (gig) or description/date/amount/category (transactions) — flag, never silently delete. (d) Disable Save button while async save is in flight on every form. (e) Merge on content key as well as id; re-run merge for docs created after first merge; record `mergedAt` and copy personal docs newer than it.



\*\*P0-21 — Finances INCLUDES future dates within the current month; future tx poisons chart + projection.\*\*

`haven\_central\_screen.dart:783-784` — `ranged` = whole anchor month, so a transaction dated 5 days from now counts in Income/Expenses/Net/Savings Rate/Left and Recent Activity today. `:806-834` — `monthRange` built from earliest→latest transaction, so one future-dated tx extends the chart into future months, renders as actuals, and enters `validMonths` → `avgSavings` → `projectedNet`.

\*\*Fix:\*\* Cap `rangeEnd` / `latest` at current month for "so far" totals; exclude future months from `validMonths`; validate `selectedDate <= today` on save (use `TransactionValidator.validateDate`).



\*\*P0-22 — Edit = full-doc save-overwrite, no merge, no conflict detection.\*\*

Every `save\*` in `FirestoreService` uses `.set(doc)` with no `SetOptions(merge: true)` (only `saveUnit` and `HouseholdCloudService` merge). Two phones editing the same doc → last writer wins the entire document; stale phone can silently clobber the other's fields.

\*\*Fix:\*\* Use `set(…, SetOptions(merge: true))` for edits, or field-level `update()` + `FieldValue` ops.



\*\*P0-23 — Two different `Loan` and `Task` classes, never reconciled.\*\*

`FirestoreService` defines its own `Loan` (`principal/annualRate/months/extraPayment/missedPaymentPenalty/startDate`) and `Task` (`dueDate/isDone`), while `models/loan.dart` (`lender/interestRate/monthlyPayment/termMonths/remainingBalance`) and `models/task.dart` (`isCompleted/priority`, no `dueDate`) define different ones. `HavenCentralScreen` uses Firestore ones; `AppState` uses models ones; nothing converts. AppState loans/tasks and Firestore loans/tasks are disjoint universes.

\*\*Fix:\*\* One canonical `Loan`/`Task` model shared by both.



\*\*P0-24 — Post-merge personal writes can strand.\*\*

`\_mergeIntoHousehold` copies only docs the household doesn't already have, records `mergedInto: \[hid]`, early-returns if already present. If `household\_id` is cleared/changed and restored, merge early-returns → documents written to the personal folder in the interim are never copied and never read again. Same-ID conflict: household version wins, personal version never merged, never read again. Merge-failure fallback caches the personal root for the session.

\*\*Fix:\*\* Record `mergedAt`, re-run missing-doc copy every launch; on ID conflict keep newer doc by `updatedAt`; retry merge on next save instead of caching fallback indefinitely.



\*\*P0-25 — All save/delete calls have no error handling; user can't tell a save failed.\*\*

Every save/delete in `HavenCentralScreen` is awaited with no `try/catch` and no user feedback (transaction, loan, task, budget, farm saves; all deletes). On thrown error (permission-denied, malformed doc) the sheet/dialog stays open with no error message. Only `\_importGigJobs` has try/catch.

\*\*Fix:\*\* Wrap every Firestore call in `try/catch` + `SnackBar` on failure (and success confirmation on save).



\---



\## P1 — User-visible bugs / misleading displays



\*\*P1-1 — `\_money` precision split across the same screen (generalized $0.38 gap).\*\*

`\_money` defaults to 2 decimals. But: big "Left" uses 2 decimals; breakdown line uses `decimals: 0`; summary cards Income/Expenses/Net use `decimals: 0`; formula drawer uses 2; Income/Expense sheet total uses 2; activity tile uses 2. Rounded components don't sum to Left. Same value shows as `$1,810` on card and `$1,810.49` in its sheet.

\*\*Fix:\*\* Pick one precision for money on Finances (recommend cents everywhere, or whole dollars everywhere including Left) and use it at every call site.



\*\*P1-2 — `getCategorySpent` excludes 1st-of-month transactions.\*\*

`app\_state.dart:527-537` uses strict `isAfter(startOfMonth)` — a transaction stamped exactly at the 1st 00:00 is excluded. Date-picker transactions are stamped at exactly midnight, so 1st-of-month entries are systematically dropped from category spent.

\*\*Fix:\*\* Use `!isBefore(startOfMonth)`.



\*\*P1-3 — Week label disagrees with week range.\*\*

When `\_financesWeekIdx` is null while period is `'week'` (e.g. after tapping a chart bar, which resets idx to null), range falls back to whole month but `\_weekLabel` clamps null → 0 and displays "Wk 1." Label says Wk 1, data is whole month. Tapping Week pill always jumps to Wk 1, never current week.

\*\*Fix:\*\* Default `\_financesWeekIdx` to current week's index; make `\_weekLabel` show "all weeks" when idx is null.



\*\*P1-4 — Bill "due soon" defined three different ways.\*\*

Finances bills-due uses range window. `haven\_assistant.dart:33-34` uses `isAfter(now) \&\& isBefore(now + 7d)` — overdue bills vanish entirely, bills due exactly now / +7d excluded. `query\_service.dart:144` / `briefing\_service.dart:27` use `difference().inDays <= 7`, which \*includes\* overdue bills. Same bill is "due soon" in one surface, invisible in another.

\*\*Fix:\*\* One shared `dueSoon(bill)` helper used by all three surfaces, explicitly including overdue bills.



\*\*P1-5 — Recent Activity shows oldest first.\*\*

`rangedReversed = ranged.reversed.toList()` reverses the Firestore desc-ordered list, so under a "Recent Activity" heading the oldest transaction in the range is on top. Income/Expense sheets use unreversed `ranged` (newest first) — inconsistent ordering.

\*\*Fix:\*\* Drop the `.reversed` for Recent Activity.



\*\*P1-6 — Finances bills-due errors silently swallowed.\*\*

`haven\_central\_screen.dart:789-801` — bills loop wrapped in `try { } catch (\_) {}` — any error makes `rangedBillsDue` silently 0 and "Left" overstated, no error shown.

\*\*Fix:\*\* Remove blanket catch; let errors surface, or log and show a warning.



\*\*P1-7 — Savings Rate card clamps negative to 0%.\*\*

`haven\_central\_screen.dart:788` — `.clamp(0, 100)` — a month where spending exceeds income displays "0%" instead of the true negative rate.

\*\*Fix:\*\* Clamp only the progress-bar rendering, not the displayed number.



\*\*P1-8 — Pie percentages round to whole percent (can sum to 99%/101%).\*\*

`haven\_central\_screen.dart:1058,1065` — `toStringAsFixed(0)`.

\*\*Fix:\*\* Show one decimal, or adjust largest slice so they sum to 100%.



\*\*P1-9 — Homestead feed cost truncates to whole dollars.\*\*

`homestead\_screen.dart:83,179` — `toStringAsFixed(0)` while money elsewhere shows cents.

\*\*Fix:\*\* Use the same money formatter.



\*\*P1-10 — Recent Activity search doesn't match category/notes.\*\*

Search filters range-scoped list, case-insensitive `contains` on `description` and `place` only. Matches its hint text, so correct-per-hint, but category/notes unsearchable.

\*\*Fix:\*\* Extend match to `category` and `notes` (and update hint), or leave as-is deliberately.



\*\*P1-11 — Empty category groups under `''`.\*\*

`Transaction` constructor defaults category only when null (`?? 'General'`) — empty-string category passes through, groups under `''` in pie/bars, never matches a budget category.

\*\*Fix:\*\* Normalize `category.trim().isEmpty → 'General'` in constructor.



\*\*P1-12 — Records (Loans) and Batches (Farm) have no empty-state message.\*\*

`\_buildRecordsTab` renders only `...loans.map(...)` — zero loans = header + button, no message. `\_buildBatchesTab` renders only `...farmItems.map(...)` with no empty message, and `Text(item\['name'])` will throw if a doc lacks `name`.

\*\*Fix:\*\* Add empty-state messages matching Schedule tab pattern; use `item\['name']?.toString() ?? 'Unnamed item'`.



\*\*P1-13 — Unguarded divisions (low severity, fix while nearby).\*\*

\- Budget "remaining %" divides by `budget.limit` with no guard (`haven\_central\_screen.dart:1438`) — malformed doc with `limit == 0` renders `Infinity%`/`NaN%`. Fix: guard with `budget.limit > 0` or reuse `rawPercent`.

\- Loan-simulator Daily Drain divides by `monthsPaid` which can be 0 (`haven\_screen.dart:191-193`) — amount like `$0.005` yields `Infinity`. Fix: `monthsPaid == 0 ? 0.0 : …`.

\- Kitchen serving-scale divides by `originalServings` which can be 0 (`kitchen\_screen.dart:303-305,343`) — API value `"0"` parses to 0 → `NaN`. Fix: `if (originalServings <= 0) originalServings = 4;`.

\- Legacy `SpendingPieChart` divides by caller-supplied `totalSpent` (dead widget, no caller) — guard belongs in widget anyway.



\*\*P1-14 — Loan APR = 0: simulator rejects it, Records form accepts garbage.\*\*

Simulator validation rejects all `rate <= 0`, so legitimate 0% APR loan can't be simulated. Records loan form only null-checks: negative principal, negative rate, `months == 0` or negative all accepted and saved to Firestore.

\*\*Fix:\*\* Simulator: allow `rate == 0` (reject only `< 0`). Records form: require `principal > 0`, `rate >= 0`, `months > 0`.



\*\*P1-15 — Gig Income dialog has no validation; Batches accepts negative qty/weight.\*\*

Gig dialog: every field `double.tryParse(…) ?? 0` — negative base/tips/bonus/miles, negative totals, absurd amounts all save silently. Batches add: only `name.isEmpty` checked; `qty`/`weight` fall back to 0 on parse failure, negatives pass through.

\*\*Fix:\*\* Validate all money/miles fields `>= 0` + sanity max, reject empty/negative totals; require `qty >= 0 \&\& weight >= 0`.



\*\*P1-16 — Future-date handling inconsistent across surfaces.\*\*

\- Insights `\_spendWindow` excludes future dates; Finances includes them (see P0-21). Fix: pick one rule (recommend exclude future from both "so far" totals), share via `\_spendWindow`.

\- Main Add Transaction date picker caps at today, but save never validates — editing an already-future transaction keeps the future date and picker can't fix it. Fix: validate on save.

\- Gig Income date picker allows +365 days; future dates inside current month inflate "Month" totals. Fix: cap picker at today (or label "Upcoming" and exclude from Month totals).



\*\*P1-17 — `myTasks` / `myTimelineEvents` NOT filtered by household, unlike every other getter.\*\*

`app\_state.dart:149-150` — raw `\_tasks` / `\_timelineEvents`, while `myTransactions`/`myAnimals`/`myBills`/`myFeedDeliveries`/`myLoans`/`myBudgets`/`myGigIncomes` all filter by `householdId`. Raw unfiltered getters also exist.

\*\*Fix:\*\* Filter `myTasks`/`myTimelineEvents` by `householdId` like the others; audit raw getters, remove or restrict them.



\*\*P1-18 — Version-string drift.\*\*

Settings shows "Haven\_OS v1.0.0" (`settings\_screen.dart:369` + About dialog) and `BackupService.version = '1.0.0'`, while `pubspec.yaml` says `1.0.1+1`.

\*\*Fix:\*\* Read version from `package\_info\_plus` everywhere (as `haven\_central\_screen.dart:2767` already does).



\*\*P1-19 — All local data is plaintext on device.\*\*

Entire dataset is one JSON string in `SharedPreferences` (`haven\_os\_data`), unencrypted. Legacy `registered\_users` (salted password hashes) also in SharedPreferences. `flutter\_secure\_storage` used only for accounts/PINs/auth keys, not main dataset.

\*\*Fix:\*\* Encrypt the local dataset (encrypt JSON blob with key in `FlutterSecureStorage`) or move to encrypted store.



\*\*P1-20 — Firebase config + signing fingerprint committed to repo.\*\*

`android/app/google-services.json` contains Firebase `api\_key`, project ID, package name. `.github/workflows/build.yml:30-36` hardcodes debug keystore SHA-256 fingerprint.

\*\*Fix:\*\* Restrict API key in Google Cloud Console (Android-app + API restrictions); move fingerprint to secret/variable.



\---



\## P2 — Placeholders / missing features



\*\*P2-1 — Settings Export/Import/Reset are empty stubs; `BackupService` uncalled; `resetAllData` incomplete.\*\*

`settings\_screen.dart:346-359` — `\_exportData`, `\_importData`, `\_confirmReset` are empty bodies; buttons do nothing. `resetAllData()` (`app\_state.dart:661-666`) clears only `haven\_os\_data` + account keys; PIN hashes, `registered\_users`, `household\_id`, kitchen prefs, Firestore data survive "Reset All Data."

\*\*Finished =\*\* Export downloads a real backup file; Import restores it; Reset clears all local + auth state with confirm.



\*\*P2-2 — Farm service is a placeholder (two `FarmService` classes).\*\*

`lib/services/farm\_service.dart:3-10` — "Placeholder farm service – all methods return empty data"; `getTotalAnimals() => 0`, `getTotalFeed() => 0.0`. Note: the \*domain\* `FarmService` in `lib/domain/services/farm\_service.dart` is real. `lib/services/` also has orphan duplicate `FinanceService` and `StorageService` with \*\*zero imports\*\* (the orphan `storage\_service.dart` even diverges — its `saveAll()` lacks `gigIncomes`).

\*\*Finished =\*\* Delete the three `lib/services/` duplicates; wire the real domain `FarmService` so Batches tab shows real data.



\*\*P2-3 — Placeholder screens (entire screens are stubs).\*\*

\- Tasks: `tasks\_screen.dart:19` — "Tasks screen (coming soon)"

\- Routines: `routines\_screen.dart:19` — "Routines screen (coming soon)"

\- Timeline screen: `timeline\_screen.dart:9` — "Timeline coming soon..."

\- Timeline widget: `timeline\_widget.dart:9` — "Timeline widget coming soon..."

\- CFO Transactions tab: `transactions\_tab.dart:9` — "Transactions tab coming soon..." (used by `ledger\_screen.dart`)

\- CFO entry dialog: `transaction\_entry\_dialog.dart:10` — "Transaction entry coming soon..."; Save/Cancel `onPressed: null`

\- Homestead duplicate: `homestead/tabs/widgets/homestead\_screen.dart:9` — "Homestead Screen – coming soon" (real `HomesteadScreen` exists at `homestead/widgets/homestead\_screen.dart`, 223 lines)

\- Reports: `haven\_central\_screen.dart:2746` — "Reports coming soon" snackbar stub

\- Home nav: `home\_screen.dart:304` — `SnackBar('Navigating to tab $index (coming soon)')` dead-end navigation

\- Health score: `health\_score\_service.dart:6-13` — "Placeholder – returns a default health score"; `calculateHealthScore()` always returns 85. Instance held in `app\_state.dart:210`, never invoked.

\*\*Finished =\*\* Each screen shows real data with working add/edit/delete, persists across restart; Health score computes from real data; Reports generates/downloads a real report.



\*\*P2-4 — Sync the unsynced collections.\*\*

`GigIncome`, `Bills`, `Animals`, `FeedDeliveries`, `TimelineEvents` have no Firestore methods — local-only. `GigJobs` has full Firestore methods but \*\*zero writers\*\* (`saveGigJob` has zero callers) and one one-shot reader (`\_importGigJobs` takes `.first` on launch). `saveUnit`/`streamUnit` read/write `users/{uid}`, not household root — household members can have different units.

\*\*Finished =\*\* `GigIncome` (and Bills/Animals if household-visible) get Firestore collections + streams mirroring the existing six-collection pattern; `saveGigJob` wired to GigIncome write path + `streamGigJobs` subscribed live, or dead collection deleted; unit documented as per-user or moved to household doc.



\*\*P2-5 — Dead code / duplicates / empty files.\*\*

\- Entirely uncalled: `AppInitializer`, `HavenCentralViewModel` (never instantiated), `CommandParser.parse()`, `ScanService`, `EventBus`, `ErrorBoundary`, `PermissionService.can()`, `HealthScoreService.calculateHealthScore()`, `promoteToParent()` (also no permission check).

\- Empty lifecycle stubs: `\_migrateLegacyData()` (empty body); `migrateIfNeeded()` no-op in both `StorageService`s and `migration.dart`.

\- 15 zero-byte `.dart` files (placeholders with no code): `date\_utils`, `number\_utils`, `app\_data`, `forecast\_service`, `haven\_context`, CFO tabs, Haven widgets, Homestead tabs, Settings tabs, `old\_bills\_tab`.

\- Stale `.bak` files committed despite `.gitignore` (`sign\_in\_screen.dart.bak`, `require\_email\_dialog.dart.bak`).

\- `Animal` store is write-only dead code: `addAnimal` has zero callers; live Batches tab uses Firestore `farmItems` maps, not `Animal`.

\- Dead/legacy screens with no navigation caller: `CfoScreen`, `SpendingPieChart`, `CashFlowChart`, `LedgerScreen`, `BillsTab`, `TransactionEntryDialog`, legacy `HomeScreen`.

\- Dead-code "Loan" filter (`cfo\_screen.dart:339`) filters on `category == 'loan'` but no category list contains "Loan" — always empty.

\*\*Finished =\*\* Delete uncalled classes, empty files, `.bak` files, dead screens (or wire them up); delete one of each duplicate service/model pair; adopt `TODO:` markers so stubs are greppable (currently zero literal TODO/FIXME/HACK in any `.dart` file).



\*\*P2-6 — `haven\_central\_screen.dart` is 2,795 lines / 132,620 bytes (\~17.6% of all Dart), one `State` class with \~25 builder/show methods.\*\*

\*\*Finished =\*\* Do NOT split in this pass. Later: extract one tab at a time behind phone tests, starting with Finances.



\---



\## P3 — Housekeeping / polish



\*\*P3-1 — Release builds signed with DEBUG keystore.\*\*

`android/app/build.gradle.kts` — release block uses `signingConfigs.getByName("debug")`; `isMinifyEnabled = false`, `isShrinkResources = false`. Workflow restores debug keystore from `DEBUG\_KEYSTORE\_B64`.

\*\*Fix:\*\* Before any Play Store submission, generate a real upload/release key, add a `release` signing config fed by secrets. Debug signing is fine for sideloaded family testing (current distribution).



\*\*P3-2 — Package name is still the Flutter template default.\*\*

`android/app/build.gradle.kts` — `namespace`/`applicationId = "com.example.haven\_os"`; `google-services.json` — `package\_name: "com.example.haven\_os"`; `MainActivity.kt` under `com/example/haven\_os/`.

\*\*Fix:\*\* Rename to a real ID (e.g. `com.berry82.havenos` — confirm with David) before Play Store: move Kotlin package dir, update `build.gradle.kts`, regenerate `google-services.json`, re-register app in Firebase. Cannot change after first store upload — do the rename now.



\*\*P3-3 — CI has no quality gates; pins older Flutter; lints off; no tests.\*\*

`.github/workflows/build.yml` — Flutter pinned to `3.44.8`; no `flutter analyze` or `flutter test` step. `analysis\_options.yaml:10` — `include: package:flutter\_lints/flutter.yaml` commented out, no rules enabled. Only `test/widget\_test.dart` (741 bytes) exists; no unit tests for `PinLock`, `PermissionService`, `FirestoreService`, backup/restore.

\*\*Fix:\*\* Uncomment lint include; add `flutter analyze` + `flutter test` steps before build; add unit tests for at least `PinLock` and `PermissionService.can()`; align pinned Flutter with dev machines.



\*\*P3-4 — Version: `1.0.2` bump NOT due for build numbering.\*\*

`pubspec.yaml:5` — `version: 1.0.1+1`. Workflow passes `--build-number=${{ github.run\_number }}`, overriding `+1`, and names artifacts `haven\_os-1.0.1-b<run>-<sha>`. Devices get versionName `1.0.1`, buildNumber = run number (\~85). The `+1` never reaches a CI-built device.

\*\*Fix:\*\* Decide explicitly: bump `pubspec.yaml` to `1.0.2+1` when the user-visible version should move, or leave `1.0.1` and let run number carry build identity. Do not bump just to match run number.



\*\*P3-5 — Committed junk inflates repo and leaks local state.\*\*

`.vs/` (\~3.5 MB VS binaries), `nuget.exe` (8.4 MB), `error.txt` (16.8 KB analyze dump), `flutter\_01.png` (414 KB) + `flutter\_02.png` (144 KB) screenshots, `lib/services/app\_service.dat` (8.9 KB unknown binary), a file literally named `t n===== PROVIDER REFERENCES =====` (17 KB). `.gitignore` covers none of `.vs/`, `\*.exe`, or these files.

\*\*Fix:\*\* `git rm --cached` all of the above; add `.vs/`, `\*.exe`, `\*.bak`, `error.txt`, `\*.dat` to `.gitignore`; keep screenshots out of repo.



\*\*P3-6 — Release APK not minified/obfuscated.\*\*

`isMinifyEnabled = false`, `isShrinkResources = false`.

\*\*Fix:\*\* Enable R8 minification + resource shrinking once a release key exists (P3-1); verify with phone test.



\*\*P3-7 — Over-broad Android permissions.\*\*

`AndroidManifest.xml` requests `CAMERA`, `READ\_EXTERNAL\_STORAGE`, `RECORD\_AUDIO`, `INTERNET`. No audio-recording feature evident in codebase.

\*\*Fix:\*\* Remove `RECORD\_AUDIO` (and `READ\_EXTERNAL\_STORAGE` on modern targets) unless a feature needs them; justify each remaining permission in a comment.



\*\*P3-8 — Logging via raw `print()` with no redaction.\*\*

`logger\_service.dart`, `event\_bus.dart`, `error\_boundary.dart` use raw `print()`.

\*\*Fix:\*\* Route through a logger that strips PII/secrets.



\*\*P3-9 — Timezone: all dates are local wall-clock, no UTC.\*\*

`Transaction.toJson` writes `toIso8601String()` with no offset; another device/timezone re-parses the same wall time as its own local time.

\*\*Fix:\*\* Store UTC (`toUtc().toIso8601String()`), convert to local only for display. Low priority for single-timezone household.



\*\*P3-10 — Legacy-account migration bypasses email verification.\*\*

Sign-in legacy path: after proving old local password, creates Firebase account that stays signed in without email verification, while normal `login()` signs out unverified users. `rawSignIn()` has no verification check.

\*\*Fix:\*\* Send/require verification on migrated path too, or document as accepted one-time exception.



\*\*P3-11 — Artifact retention is fine.\*\* `retention-days: 30` on APK artifact. No action.



\---



\## Suggested fix order (highest leverage first)



1\. \*\*P0-1\*\* PIN demo bypass + enforce PIN entry.

2\. \*\*P0-2 + P0-3\*\* Commit Firestore rules with membership checks; stop trusting client-side `household\_id`; require owner approval for joins.

3\. \*\*P0-4\*\* Scope local storage per user; clear state on logout (new account starts clean).

4\. \*\*P0-8\*\* Per-record `fromJson` guards (stops one bad record wiping all data).

5\. \*\*P0-9\*\* Budget doc ID → `"<month>\_<category>"` (active data loss).

6\. \*\*P0-11 + P0-12\*\* Single write path (Firestore + local); gig backfill + both-store gig add/update/delete.

7\. \*\*P0-15\*\* Amount validation + sanity confirm + call `TransactionValidator`.

8\. \*\*P0-16\*\* Budget tab: filter spend + income to current month.

9\. \*\*P0-20\*\* Content-similarity duplicate flagging; submit guards; import dedup vs Firestore + deterministic ids + await initialize; merge re-run.

10\. \*\*P0-19 + P0-25\*\* `onError` on combined streams + hoist/close; `try/catch` + user feedback on all save/delete calls.

11\. \*\*P0-5 + P0-6 + P0-7\*\* Invite levels enforcement; UID-keyed folders; logout + routes fix.

12\. \*\*P0-13 + P0-14 + P0-17 + P0-18 + P0-21 + P0-22 + P0-23 + P0-24\*\* Bills/animals sync; constructor rewrite fix; chart off-by-one; spend-window fix; future-date rules; merge-sets for edits; unify Loan/Task models; merge re-run for post-merge writes.

13\. \*\*P1 items\*\* in order listed.

14\. \*\*P2 items\*\* (Export/Import/Reset wiring, Farm duplicates, placeholder screens, unsynced collections, dead code).

15\. \*\*P3 items\*\* (release key + package rename before any Play Store attempt; CI gates + lints + tests; version decision; repo cleanup; permissions; logging; timezone; migration verification).



\## Caveats

\- Sync propagation (delete/edit appearing on phone B) is inferred from stream architecture, not live-verified — no two-phone test was run.

\- Offline behavior of the Firestore SDK cache is inferred, not established from code (no persistence config in repo either way).

\- All line numbers verified against HEAD `2e2f1bb`; gig-income screen is minified into 10 long lines, so its findings cite line 7/9 rather than precise columns.

\- Math formulas excluded — covered by a separate audit (still running at plan time).



