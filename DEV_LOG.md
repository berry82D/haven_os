# Haven OS — DEV LOG
Live log — LAW 16 + LAW 17 ENFORCED
LAW 16: Every AI must keep log up-to-date. No push without log.
LAW 17: Every AI must READ DEV_LOG.md + CLAUDE.md BEFORE assisting.

---

## 2026-09-06 — 949d358 — feature/haven-central-fixes
**Status:** PUSHED --verbose needed
**analyze:** No issues (91.1s)
**Push:** b124790..949d358
**Fix:** Transaction late-field bug, budget 0% ->!isIncome, householdId all models, edit/delete UI, settings preserved

---

## 2026-09-06 — 7dda27d — Transaction Fix + Law 16
**Status:** PUSHED
**Files:** lib/models/transaction.dart, DEV_LOG.md
**Change:** Removed rhbarringer hack, added String? gigIncomeId additive link
**Why:** rhbarringer fragile employer hack, need link for gig income
**analyze:** No issues (46.8s) then (32.6s)
**Push:** 949d358..7dda27d
**Commit:** fix: remove rhbarringer hack, add gigIncomeId link, add Law 16 log enforcement
**Law 16:** Every AI must keep DEV_LOG.md up-to-date, no push without log

---

## 2026-09-06 — PENDING — 7dda27d+ — gig_income.dart + CLAUDE.md + Law 17

**Status:** CREATING FILES — awaiting analyze + push
**Files:**
- lib/models/gig_income.dart — NEW MODEL — basePay, tips, bonus, mileage, miles, totalAmount, platform enum (doordash, uberEats, spark, instacart, lyft, uber, other), payPerMile, tipPercent, householdId groundwork
- CLAUDE.md — Updated with Laws 1-17 — Law 17 = Read Before Assist
- DEV_LOG.md — This file — updated with Law 17

**Why gig_income.dart:** Currently only "$50 from DoorDash" — can't separate base/tip/bonus/mileage for tax insights. Need richer entry UI.

**Why Law 17:** David: each ai helper need to read the dev log before they assist — prevents AIs repeating fixes, overwriting working code, breaking household migration. Must read DEV_LOG.md + CLAUDE.md first.

**Architecture:**
- Transaction.gigIncomeId nullable -> GigIncome.id
- GigIncome.transactionId links back
- householdId fallback = userId
- totalAmount auto = base + tips + bonus if 0

**analyze:** Pending
**run:** Pending
**Push command:** git add lib/models/gig_income.dart CLAUDE.md DEV_LOG.md && git commit -m "feat: add gig_income model richer entry, add CLAUDE.md Laws 1-17 incl Read Before Assist Law 17, update DEV_LOG.md" && git push origin feature/haven-central-fixes --verbose

**Next after push:** AppState Phase 2 — add List<GigIncome> storage, JSON blob persistence, household filtering

### Law 16 + 17 Enforcement
- Before file replacement: read DEV_LOG.md + CLAUDE.md (Law 17)
- After replacement: update DEV_LOG.md (Law 16)
- Before push: ensure log updated (Law 16)
- Complete file replacement per Rule 2
- Terminal push via Set-Content @' '@

### Checklist
- [x] transaction.dart fix pushed 7dda27d
- [x] DEV_LOG.md created via terminal
- [x] gig_income.dart created via terminal (previous step)
- [ ] CLAUDE.md with Laws 1-17 via terminal (this step)
- [ ] DEV_LOG.md updated with Law 17 via terminal (this step)
- [ ] flutter analyze
- [ ] git status -> should show 3 files
- [ ] git add + commit + push --verbose (all 3 together per Law 16)

---

## TEMPLATE
## YYYY-MM-DD — HASH — Branch
**Status:** **File:** **Change:** **Why:** **analyze:** **run:** **Push:** **Next:** **Laws:**

## NOTES
- Hotspot: --verbose
- David Berry Sr. NOOB MODE — AI brains, David idea
- Olivia NC / NMB hotspot
- Branch: feature/haven-central-fixes
- Last push 7dda27d
- Queued: AppState Phase 2, UI richer entry, Forgot-password
- Laws 1-17 enforced — Read Before Assist mandatory
