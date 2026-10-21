# WORK IN PROGRESS

**Last touched:** 2026-10-21
**Active task:** ROADMAP/WIP catch-up (this docs push); next: Candice installs b121 + enters real debts, then path-to-debt-free calculator or loan insight
**Driver:** Rocky (design) / David (PC)
**Branch:** main
**HEAD:** 4a08be7 (delete confirmations b121, phone-verified Oct 21)

## Status: IN PROGRESS

### Oct 21 - verified on phone (David)
- Zero-Debt (b118): test data cleared, tracker empty, ready for real debts
- Top-layer form errors + gig edit button (b119)
- Gig edit amount validation (b120)
- Delete confirmations - gig job / farm item / task (b121)
- Both phones sync confirmed

### Oct 21 - verified on phone (David)
- Zero-Debt (b118): test data cleared, tracker empty, ready for real debts
- Top-layer form errors + gig edit button (b119)
- Gig edit amount validation (b120)
- Delete confirmations - gig job / farm item / task (b121)
- Both phones sync confirmed

### Done (awaiting phone verify)
- [x] Budgets month filter (e3206da) — spent + income filtered to current month
- [x] Chart off-by-one (fb7fc93) — inclusive month start
- [x] DEV_LOG entry for both fixes (5f72071)
- [x] Audit files on GitHub (bdb5504)

### P0-1 PIN bypass + biometrics
- [x] WIP updated
- [x] pubspec.yaml: local_auth added
- [x] AndroidManifest: USE_BIOMETRIC permission added
- [x] app_state.dart: signIn stops auto-verifying PIN; verifyPinAndUnlock + unlockWithBiometrics added
- [x] pin_entry_screen.dart: real PIN field + biometric button, demo button removed, /home route fixed
- [x] sign_in_screen.dart: route through PIN screen when PIN enabled
- [x] PIN setup UI in Settings (e70abe4) + brace fix (3699973, build #91 failed on top-level method)
- [x] DEV_LOG entries (f105d05, e70abe4, f586870 trace)
- [ ] Delete unlockApp() dead-code bypass (script given, not yet run)
- [ ] Cloud build green (#93)
- [ ] Phone verify:
  - [ ] No PIN: sign in -> straight Home
  - [ ] Settings -> PIN Lock -> set 4+ digit PIN -> confirm
  - [ ] Sign out -> sign in -> PIN screen (not Home)
  - [ ] Wrong PIN -> error, stays locked
  - [ ] Correct PIN -> Home
  - [ ] Fingerprint/face (if enrolled) -> Home
  - [ ] Remove PIN -> sign in -> Home with no PIN screen
  - [ ] Budgets tab shows October only
  - [ ] Sep 30 transaction in September only

### Queued next (from audits)
- [ ] Insights #4 projection extrapolation (two formulas: Insights MTD x12 + Finances complete-months avg)
- [ ] #6 Left / bills double-count (skip paid bills)
- [ ] P0-8 / P0-9 / P0-15 (load guards, budget doc IDs, amount validation)
- [ ] Dead-path sign bugs (#10-14)
- [ ] needsPinReentry session gate (5-min re-lock after Home — currently unenforced)

## Rule (Law 18)
WIP.md deleted ONLY after install + real-phone verification.
## Tomorrow (2026-10-19)
- [ ] Candice's phone: Allow USB debugging → adb -s R5CY2180YTH install -r 'C:\Users\corch\haven_os_zip_b111\haven_os-1.0.1-b111-1ee5321.apk'
- [ ] Phone-verify Impact: Gig Income → X% of income (should NOT be 100%, RHB included)
- [ ] WIP.md: update driver, mark gig Phase 2+3 done
- [ ] ROADMAP.md: gig upgrade → DONE, pick next (zero-debt goal?)
- [ ] Next build: zero-debt goal or David's pick
