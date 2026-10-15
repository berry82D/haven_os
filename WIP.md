# WORK IN PROGRESS

**Last touched:** 2026-10-15
**Active task:** P0-1 PIN bypass + biometrics
**Driver:** Rocky (design) / David (PC)
**Branch:** main
**HEAD:** bdb5504 (audits on GitHub)

## Status: IN PROGRESS

### Done (awaiting phone verify)
- [x] Budgets month filter (e3206da) — spent + income filtered to current month
- [x] Chart off-by-one (fb7fc93) — inclusive month start
- [x] DEV_LOG entry for both fixes (5f72071)
- [x] Audit files on GitHub (bdb5504)

### P0-1 PIN bypass + biometrics
- [x] WIP updated (this file)
- [ ] pubspec.yaml: add local_auth
- [ ] AndroidManifest: add USE_BIOMETRIC permission
- [ ] app_state.dart: signIn stops auto-verifying PIN; add unlockWithBiometrics()
- [ ] pin_entry_screen.dart: real PIN field + biometric button, remove demo button, fix /home route
- [ ] sign_in_screen.dart: route through PIN screen when PIN enabled
- [ ] Cloud build green
- [ ] Phone verify:
  - [ ] Login with PIN set -> PIN screen appears (not straight to Home)
  - [ ] Correct PIN -> Home
  - [ ] Wrong PIN -> error, stays locked
  - [ ] Fingerprint -> Home (if enrolled)
  - [ ] No PIN set -> straight to Home (no PIN screen)

### Queued next (from audits)
- [ ] Insights #4 projection extrapolation
- [ ] #6 Left / bills double-count
- [ ] P0-8 / P0-9 / P0-15 (load guards, budget doc IDs, amount validation)
- [ ] Dead-path sign bugs (#10-14)

## Rule (Law 18)
WIP.md deleted ONLY after install + real-phone verification.