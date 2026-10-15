\# Haven OS — Full Math Audit (branch `main`, Oct 15, 2026)



Files checked: `haven\_central\_screen.dart` (2,795 lines), `app\_state.dart`, `gig\_income\_screen.dart`, `gig\_income.dart`, `transaction.dart`, `gig\_job.dart`, `finance\_service.dart` (×2), `loan\_service.dart`, `health\_score\_service.dart`, `briefing\_service.dart`, `query\_service.dart`, `farm\_service.dart`, `loan.dart` (models), `haven\_screen.dart` (amortization engine), `haven\_assistant.dart`, `cfo\_screen.dart`, `spending\_pie\_chart.dart`, `teen\_dashboard.dart`, plus a repo-wide sweep for arithmetic.



\---



\## 🔴 WRONG MATH — LIVE (affects what David sees now)



\### 1. Budgets tab: `spent` sums ALL-TIME, not this month

\*\*File:\*\* `lib/features/haven\_central/haven\_central\_screen.dart`, \~line 1390

\*\*Formula:\*\* `spent = all Transactions where !isIncome \&\& category == budget.category` — no date filter, while the budget itself is for one month (`budget.month == monthKey`).

\*\*Verdict:\*\* WRONG.

\*\*Fix:\*\* Filter to the budget's month, like `\_homeMonthlyLeft` does: `!t.date.isBefore(monthStart) \&\& t.date.isBefore(monthEnd)`.

\*\*Example:\*\* Groceries budget $500 for Oct 2026. All-time Groceries = $8,000 → tab shows "$8,000 spent, −$7,500 left, 1600% used" even if October groceries are only $200. Every budget with history looks massively overspent. Budgets are effectively unusable.



\### 2. Budgets tab: "Income this month" is ALL-TIME income

\*\*File:\*\* `haven\_central\_screen.dart`, \~line 1354

\*\*Formula:\*\* `incomes = all Transactions where isIncome` — no date filter, but labeled "Income this month: $X" and used for "Suggested budget: Spend < 80% of income."

\*\*Verdict:\*\* WRONG.

\*\*Fix:\*\* Same month filter as #1.

\*\*Example:\*\* All-time income $50,000, October income $1,810 → screen says "Income this month: $50,000" and "Suggested budget: $40,000." The suggestion is 22× too high.



\### 3. Monthly buckets double-count the previous month's last day

\*\*File:\*\* `haven\_central\_screen.dart`, \~line 829 (monthlyData filter)

\*\*Formula:\*\* `t.date.isAfter(monthStart.subtract(Duration(days: 1))) \&\& t.date.isBefore(monthEnd)`

\*\*Verdict:\*\* WRONG (off-by-one).

\*\*Fix:\*\* Use `!t.date.isBefore(monthStart)` like everywhere else in the file.

\*\*Example:\*\* A $500 expense on Sep 30 at noon: `isAfter(Sep 30 00:00)` → true, `isBefore(Nov 1)` → true → counted in \*\*October\*\*. It is also counted in September's bucket. So it appears in \*\*both\*\* months. This corrupts `monthlyData` → the monthly chart, `avgSavings`, and `projectedNet`. The `subtract(1 day)` hack was presumably meant to include Oct 1 00:00:00.000 exactly, but it overcorrects by a full day.



\### 4. Insights projection: month-to-date net × 12, no day-extrapolation

\*\*File:\*\* `haven\_central\_screen.dart`, \~line 503

\*\*Formula:\*\* `yearly = net \* 12` where `net` = month-to-date net (Oct 1 → today).

\*\*Verdict:\*\* WRONG.

\*\*Fix:\*\* `monthly = net / now.day \* daysInMonth; yearly = monthly \* 12` — exactly what the what-if code below it already does (line \~544).

\*\*Example:\*\* Oct 15, MTD net $100 → displays "At this pace you save $1,200 this year." True annualized pace: $100 ÷ 15 × 31 × 12 = \*\*$2,480\*\*. Displayed value understates by 52%. The error is worst early in the month (on day 15, \~50% low; on day 3, \~90% low).



\### 5. Insights overspend warning unreachable when income is $0

\*\*File:\*\* `haven\_central\_screen.dart`, \~line 496

\*\*Formula:\*\* The "spending is $X above income" branch sits inside `if (curInc > 0)`.

\*\*Verdict:\*\* WRONG (guard too narrow).

\*\*Fix:\*\* Compute `net` outside the `curInc > 0` gate; show the overspend warning whenever `net < 0`, even if `curInc == 0`.

\*\*Example:\*\* Day 5, $500 spent, $0 income yet → no warning shown, even though spending is $500 above income.



\### 6. "Left" double-counts paid bills

\*\*File:\*\* `haven\_central\_screen.dart`, \~line 792–801

\*\*Formula:\*\* `leftThisPeriod = incomes − expenses − billsDue − 100`, where `billsDue` sums \*\*all\*\* bills due in range with no `isPaid` check.

\*\*Verdict:\*\* WRONG (double-count in two ways).

\*\*Fix:\*\* Exclude paid bills: `if (b.isPaid) continue;` — and ideally, if a bill's payment is already a Transaction, don't count it in billsDue at all.

\*\*Example:\*\* Rent bill $800 due Oct 1, paid Oct 1 (logged as an $800 expense Transaction). Left subtracts $800 in `expenses` AND $800 in `billsDue` → Left understated by \*\*$800\*\*. Even without the Transaction, a bill marked paid still subtracts from Left.



\### 7. What-if yearly: 7/30 × 52 chain overstates by 1.1%

\*\*File:\*\* `haven\_central\_screen.dart`, \~line 547

\*\*Formula:\*\* `weeklyCut = cutMonthly \* 7 / 30; yearlySave = weeklyCut \* 52` → `yearlySave = cutMonthly × 12.13`.

\*\*Verdict:\*\* Slightly WRONG (approximation error).

\*\*Fix:\*\* `yearlySave = cutMonthly \* 12`; `weeklyCut = cutMonthly \* 12 / 52`.

\*\*Example:\*\* 10% monthly cut = $100/mo → displays "$1,213/year back." True: \*\*$1,200\*\*. Overstates by $13 (1.1%). Small but systematic — 52 weeks ≠ 12 × 30-day months.



\### 8. DST: `startOfToday.add(Duration(days: 1))` shifts by 24h, not 1 calendar day

\*\*File:\*\* `haven\_central\_screen.dart`, line 170 (`\_spendWindow`) and line \~769 (week `rangeEnd`).

\*\*Verdict:\*\* WRONG on DST days (known deferred patch 11, still present).

\*\*Fix:\*\* `DateTime(y, m, d + 1)`.

\*\*Example:\*\* Spring-forward day (Mar 8, 2026, 23-hour day): midnight Mar 8 + 24h = 1 AM Mar 9. A transaction at Mar 9 00:30 passes `isBefore(curEnd)` → wrongly counted in Mar 8. Affects 2 days/year, only the 12am–1am window. Low severity.



\### 9. Transaction category-keyword override can flip expenses to income

\*\*File:\*\* `lib/models/transaction.dart`, constructor

\*\*Formula:\*\* If category contains 'paycheck', 'salary', 'income', 'deposit', 'wage', 'pay', 'bonus', 'rental', or 'livestock' (substring match) → `isIncome = true`, \*\*overriding the explicit `isIncome` passed in\*\*.

\*\*Verdict:\*\* WRONG (logic).

\*\*Fix:\*\* Only apply the keyword rule when `isIncome` was not explicitly provided (or remove it — the category lists already separate income/expense).

\*\*Example:\*\* An expense with category "Payroll Tax" or "Deposit Fee" contains 'pay'/'deposit' → silently reclassified as income. With current built-in category lists this doesn't trigger, but any custom category containing those substrings will misclassify. Explicit user choice should win.



\---



\## 🔴 WRONG MATH — DEAD CODE (wrong, but not shown; fix before wiring in)



\### 10. FinanceService (BOTH copies): classifies by amount sign, but amounts are always ≥ 0

\*\*Files:\*\* `lib/domain/services/finance\_service.dart` and `lib/services/finance\_service.dart`

\*\*Formula:\*\* `income = transactions where amount > 0`; `expenses = transactions where amount < 0`.

\*\*Verdict:\*\* WRONG. `Transaction` constructor forces `amount = amount.abs()`, so \*\*no\*\* amount is ever negative.

\*\*Fix:\*\* Use `t.isIncome` / `!t.isIncome`.

\*\*Example:\*\* Income $1,810, Expenses $1,705 → FinanceService returns income \*\*$3,515\*\*, expenses \*\*$0\*\*, balance \*\*$3,515\*\* (true balance: $105). Overstates by the full expense total.



\### 11. BriefingService `safeToSpend` built on broken FinanceService

\*\*File:\*\* `lib/domain/services/briefing\_service.dart`, \~line 15

\*\*Formula:\*\* `safeToSpend = (FinanceService income − FinanceService expenses) − upcoming bills`.

\*\*Verdict:\*\* WRONG (inherits #10).

\*\*Example:\*\* Same numbers as #10 with $200 upcoming bills → reports safe-to-spend \*\*$3,315\*\*. True: $105 − $200 = \*\*−$95\*\*. Overstates by $3,410. \*\*Currently dead code\*\* — `appState.briefing` is never called from the UI — but it will produce dangerously wrong numbers the moment it is wired in.



\### 12. QueryService: same sign bug

\*\*File:\*\* `lib/domain/services/query\_service.dart`, \~lines 366–380

\*\*Formula:\*\* `\_calculateTotalIncome` uses `amount > 0`; `\_calculateTotalExpenses` uses `amount < 0`.

\*\*Verdict:\*\* WRONG (same root cause as #10). Currently dead code (`appState.query` never called from UI).



\### 13. HavenAssistant "Total Balance" = sum of ALL amounts

\*\*File:\*\* `lib/features/home/widgets/haven\_assistant.dart`, line 25

\*\*Formula:\*\* `totalBalance = fold(sum + t.amount)` over all transactions, no income/expense split.

\*\*Verdict:\*\* WRONG. Income $1,810 + Expenses $1,705 → "Total Balance" \*\*$3,515\*\* (true: $105). Currently dead code (widget never referenced from any live screen).



\### 14. SpendingPieChart: `amount < 0` filter → always empty

\*\*File:\*\* `lib/features/cfo/widgets/spending\_pie\_chart.dart`, \~line 22

\*\*Formula:\*\* Groups `transactions.where((t) => t.amount < 0)` — never true since amounts are non-negative.

\*\*Verdict:\*\* WRONG. The pie always shows "No spending data to show." Dead code (CFO screen unwired). Fix: filter `!t.isIncome`.



\---



\## 🟡 MISLEADING LABELS / INCONSISTENT FORMULAS — LIVE



\### 15. "Current Net Worth" = lifetime cash flow, not net worth

\*\*File:\*\* `haven\_central\_screen.dart`, \~line 804 + display line \~1095

\*\*Formula:\*\* `allTimeNet = all-time income − all-time expenses`, labeled "Current Net Worth."

\*\*Verdict:\*\* MISLEADING LABEL (verified — same as prior finding).

\*\*Fix:\*\* Either relabel to "Lifetime net cash flow" or compute real net worth: `starting balance + all income − all expenses − total loan balances`.

\*\*Impact:\*\* No starting balance (starts at $0 when tracking began). Loan principals in Records are not subtracted. Gig duplicate Transactions inflate it (the +$20.30 / +$418.13 doubles add $438.43+ until Candice deletes them). Explains the Oct 11 swing (+$246 → −$56): any large transaction moves it directly.



\### 16. Two different "Left" formulas

\*\*File:\*\* `haven\_central\_screen.dart`

\- Home bridge card (line \~157): `Left = month income − month expenses − 100` (no bills).

\- Finances (line 801): `Left = incomes − expenses − billsDue − 100` (with bills).

\*\*Verdict:\*\* INCONSISTENT. Same label, different numbers.

\*\*Example:\*\* Bills due $500 → Home shows Left \*\*$505.38\*\*, Finances shows \*\*$5.38\*\*. Pick one definition (Finances' is more complete) and use it in both places.



\### 17. Savings Rate clamped to 0–100 hides negative savings

\*\*File:\*\* `haven\_central\_screen.dart`, line 788

\*\*Formula:\*\* `rangedSavingsRate = (net / incomes × 100).clamp(0, 100)`.

\*\*Verdict:\*\* MISLEADING (verified — known issue).

\*\*Fix:\*\* Allow negative (e.g., `.clamp(-100, 100)` or no lower clamp).

\*\*Example:\*\* Income $1,000, Expenses $1,150 → true rate \*\*−15%\*\*, displayed \*\*0%\*\*. The user can't tell break-even from overspending.



\### 18. $100 buffer hardcoded in Left

\*\*File:\*\* `haven\_central\_screen.dart`, line \~800 (`const rangeBuffer = 100.0`) and line \~165 (`− 100.0` in `\_homeMonthlyLeft`).

\*\*Verdict:\*\* MISLEADING / hardcoded (verified — known issue). Not user-set, no settings field. Fix: make it a setting.



\### 19. Comparative label "vs last month" is actually "vs same days last month"

\*\*File:\*\* `haven\_central\_screen.dart`, \~line 191–196

\*\*Verdict:\*\* Minor label issue. The comparison itself is correctly day-aligned (verified). The label should say "vs same days last month" or similar. The top-mover line has the same label issue.



\### 20. Gig import silently drops gig losses

\*\*File:\*\* `haven\_central\_screen.dart`, `\_importGigJobs`

\*\*Formula:\*\* Skips jobs with `net <= 0` (net = earnings − expenses).

\*\*Verdict:\*\* INCOMPLETE, not arithmetic error. A gig job that lost money (e.g., $50 earnings, $100 gas) never appears anywhere — the $100 expense vanishes from Finances. Design decision, but the user should know gig expenses are invisible.



\---



\## 🟡 MISLEADING / WRONG — DEAD CODE (loan insight, unwired)



\### 21. `models/loan.dart`: `payoffDate = startDate + termMonths × 30 days`

\*\*File:\*\* `lib/models/loan.dart`

\*\*Verdict:\*\* APPROXIMATE / WRONG. Months are not 30 days.

\*\*Fix:\*\* `DateTime(startDate.year, startDate.month + termMonths, startDate.day)`.

\*\*Example:\*\* 36-month loan starting Jan 15, 2026 → true payoff Jan 15, 2029. Code gives Jan 15 + 1,080 days = \*\*Dec 31, 2028\*\* — 15 days early. Error grows with term (60 mo → \~26 days early). Note: the live Records UI uses the \*other\* Loan model (in `firestore\_service.dart`), so this model's payoffDate is currently unused.



\### 22. HavenScreen: "999 months" sentinel leaks into display

\*\*File:\*\* `lib/features/haven/widgets/haven\_screen.dart` (amortization engine + display)

\*\*Verdict:\*\* MISLEADING. When payment can't cover interest, engine sets `monthsPaid = 999` (never-payoff signal), but the display prints "Payoff Time: 999 months" literally, and the extra-payment savings compute `999 − 60 = 939 months earlier` — nonsense. Fix: display "Never pays off at this payment" when `monthsPaid == 999`, and skip the savings lines.

\*\*Note:\*\* The screen itself is \*\*unwired\*\* (zero references in the repo) — this is the "lost" loan insight. The core amortization engine math is CORRECT (iterative, handles r=0, overpay adjustment, never-payoff guard). Only the display/validation around it has issues.



\### 23. HavenScreen rejects 0% APR loans

\*\*File:\*\* `haven\_screen.dart`, `\_calculateImpact` validation

\*\*Formula:\*\* Rejects if `rate <= 0`.

\*\*Verdict:\*\* WRONG. A 0% APR loan is valid and the engine handles it (interest = 0). Fix: reject only `rate < 0`.



\### 24. HavenScreen: early-break at 2× term displays partial totals without warning

\*\*File:\*\* `haven\_screen.dart`, `\_runAmortization`

\*\*Verdict:\*\* MISLEADING. If the loan doesn't pay off within `maxMonths × 2`, the loop breaks and partial `totalPaid`/`totalInterest` are displayed as if complete. The returned `finalBalance` is never shown. Fix: display remaining balance or a "does not pay off" note when the loop breaks early.



\### 25. CFO "debt" = loan-category transactions (actually payments, not debt owed)

\*\*File:\*\* `lib/features/cfo/widgets/cfo\_screen.dart` (dead code)

\*\*Verdict:\*\* MISLEADING LABEL. Summing transactions categorized 'loan' gives loan \*payments\*, not debt owed. Real debt = loan principals − paid.



\---



\## 🟢 EDGE CASES — LIVE (small, fix opportunistically)



\### 26. Budget "remaining %" = NaN when limit is $0 and spent is $0

\*\*File:\*\* `haven\_central\_screen.dart`, \~line 1438

\*\*Formula:\*\* `left >= 0 ? (left / budget.limit × 100)` — when `limit == 0` and `spent == 0`, `left == 0` → `0 / 0` = NaN → displays "NaN% remaining."

\*\*Fix:\*\* Guard `budget.limit > 0` for the remaining-% branch.



\### 27. `getCategorySpent` excludes midnight-on-the-1st transactions

\*\*File:\*\* `lib/services/app\_state.dart`, \~line 528

\*\*Formula:\*\* Uses `t.date.isAfter(startOfMonth)` (exclusive) while the rest of the codebase uses `!t.date.isBefore(start)` (inclusive).

\*\*Verdict:\*\* Minor off-by-one + inconsistency. A transaction at exactly Oct 1 00:00:00.000 is excluded. Nearly impossible in practice (transactions carry `DateTime.now()` timestamps), but the pattern should match the rest of the file.



\### 28. `addGigIncome` dedup guard re-adds a duplicate GigIncome entry

\*\*File:\*\* `lib/services/app\_state.dart`, \~line 565

\*\*Formula:\*\* On same-`gigIncomeId` re-add, the guard adds the GigIncome to the list anyway (just skips the duplicate Transaction).

\*\*Verdict:\*\* Partial dedup. Finances counts it once, but the Gig tab would show the gig twice. Fix: return early without adding.



\### 29. GigIncome `totalAmount` (stored) vs `totalPay` (recomputed) can diverge

\*\*File:\*\* `lib/models/gig\_income.dart`

\*\*Verdict:\*\* Minor inconsistency. The form always passes `tot = base + tips + bonus`, so they agree in practice. But `formattedTotal` uses stored `totalAmount` while `payPerMile` uses recomputed `totalPay` — if a stored record ever diverges, the two disagree. The Transaction bridge uses stored `totalAmount`; `updateGigIncome` copies stored `totalAmount` to the Transaction. Consistent within the app's own flows; only stale loaded data could diverge.



\### 30. `\_money` shows "-$0" for tiny negatives

\*\*File:\*\* `haven\_central\_screen.dart`, `\_money`

\*\*Verdict:\*\* Display quirk. E.g., −$0.001 with `decimals: 0` → "-$0". Cosmetic.



\### 31. OCR receipt amount regex misparses thousands

\*\*File:\*\* `haven\_central\_screen.dart`, `\_parseReceiptTextForForm`, \~line 1692

\*\*Formula:\*\* Regex `\\$?(\\d+\\.\\d{2})`, takes the LAST match.

\*\*Verdict:\*\* WRONG for comma amounts + fragile. `$1,234.56` → matches "234.56" (the `\\d+` after the comma) → parses \*\*$234.56\*\* instead of \*\*$1,234.56\*\* (understates by $1,000). Also requires exactly 2 decimals (misses "$5", "$5.50"), and last-match may be change/tax, not the total. Fix: strip commas first, prefer a line containing TOTAL.



\### 32. Insights `take(5)` can truncate budget alerts

\*\*File:\*\* `haven\_central\_screen.dart`, line \~557

\*\*Verdict:\*\* Minor. Budget alerts come before what-if (patch 12), but with 3+ budgets at 80%+ plus comparative + top mover, the list hits 5 and later budget alerts are dropped. Consider `take(5)` after prioritizing, or raising the cap when budgets are present.



\### 33. FarmService `countHealth` is case-sensitive exact match

\*\*File:\*\* `lib/domain/services/farm\_service.dart`

\*\*Verdict:\*\* Minor robustness. Counts `health == 'Good'/'Fair'/'Poor'` exactly; any other casing or value ('good', 'Healthy') counts as none. Used only by dead BriefingService code path.



\### 34. HealthScoreService returns hardcoded 85

\*\*File:\*\* `lib/domain/services/health\_score\_service.dart`

\*\*Verdict:\*\* Placeholder stub (known). Not wrong math — no math at all. Returns 85 always.



\---



\## ✅ VERIFIED CORRECT (checked, no change needed)



\- \*\*Category frequency sort\*\* (`\_sortedCategoriesByUse`): counts from live transactions, used-first by count descending, unused alphabetical. Correct as claimed. (Alphabetical display in screenshots is because most transactions are "General," so real categories have zero counts — the sort is fine, the "General" default was the problem, now fixed.)

\- \*\*$0.38 gap\*\*: still display rounding. Income/Expenses/Net cards use `\_money(decimals: 0)`; Left uses `\_money()` (decimals: 2). 1810.42 → $1,810; 1705.04 → $1,705; Left 5.38 → $5.38. The 38¢ is rounding, not error.

\- \*\*Insights dedup\*\*: shared `\_comparativeSentenceFromTotals` helper → Home card and engine produce byte-identical strings → `i != home` filter works by construction. Empty-filtered fallback ("Nothing new yet…") present.

\- \*\*Insights day-alignment\*\* (`\_spendWindow`): current window = 1st → tomorrow; previous = 1st of last month → same day count (capped at prev month's days). Correct, except the DST issue in #8.

\- \*\*Insights what-if\*\* (10% cut, fixed-category skip, day ≥ 10 gate, $1/week minimum): correct except the 1.1% yearly chain in #7.

\- \*\*Budget % unclamped\*\* (engine + Budgets tab): `rawPercent` shown in text, clamped only for the progress bar. Correct per post-#73 fix.

\- \*\*GigIncome\*\* `payPerMile` (miles > 0 guard), `tipPercent` (totalPay > 0 guard), constructor total recompute: correct.

\- \*\*GigJob\*\* `net`, `perHour` (minutes > 0 guard), `perMile` (miles > 0 guard): correct.

\- \*\*Gig tab\*\* month total / miles / avg-per-mile (miles > 0 guard): correct \*for GigIncome entries\* — but it misses imported gig\_jobs (see #20's companion note: the Gig tab undercounts because the import creates Transactions only).

\- \*\*`\_money` comma formatting\*\*: verified loop logic — "1,234,567" correct.

\- \*\*`\_weeksOfMonth`\*\*: Mon–Sun split, clamps to month end, correct.

\- \*\*Pie %\*\* (`\_buildCategoryLegend`): `total > 0` guard, correct. Pie sections guarded by construction.

\- \*\*`models/loan.dart`\*\*: `totalPaid = payment × term`, `totalInterest = totalPaid − principal`, `progressPercent` (principal == 0 guard), `currentBalance` fallback: correct.

\- \*\*Amortization engine\*\* (`haven\_screen.dart`): iterative interest/principal split, overpay adjustment, never-payoff guard, missed-payment capitalization: correct core math (display issues in #22–#24 only).

\- \*\*FarmService\*\* `calculateFeedCost` / `calculateRevenue` / `calculateProfit`: correct sums.

\- \*\*Budget dialog\*\*: rejects null / ≤ 0 limits. Correct.

\- \*\*CFO screen\*\* (dead): income/expense via `type` enum, monthly buckets by year+month: correct.

\- \*\*Teen dashboard\*\* (dead): balance = income − expenses via `type`: correct.



\---



\## Top fixes by impact (recommended order)

1\. \*\*Budgets tab month filter\*\* (#1, #2) — budgets are unusable without it.

2\. \*\*Monthly bucket off-by-one\*\* (#3) — silently corrupts projection + chart.

3\. \*\*Insights projection extrapolation\*\* (#4) — yearly figure understated by up to \~50%.

4\. \*\*Left bills double-count\*\* (#6) — Left understated by paid-bill amounts.

5\. \*\*"Net Worth" label\*\* (#15) — relabel or compute properly.

6\. \*\*FinanceService / QueryService sign bug\*\* (#10, #12) — fix before anything wires them in.

7\. \*\*Transaction keyword override\*\* (#9) — stop overriding explicit `isIncome`.

8\. \*\*Home vs Finances Left inconsistency\*\* (#16) — one definition.

9\. \*\*Savings Rate clamp\*\* (#17) — show negative rates.

10\. \*\*OCR regex commas\*\* (#31) — $1,234.56 → $234.56.



