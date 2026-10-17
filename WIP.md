# WORK IN PROGRESS

**Last touched:** 2026-10-15
**Active task:** P0-1 PIN bypass + biometrics (code done, awaiting phone verify)
**Driver:** Rocky (design) / David (PC)
**Branch:** main
**HEAD:** 3699973 (brace fix for _showPinSetup)

## Status: IN PROGRESS

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