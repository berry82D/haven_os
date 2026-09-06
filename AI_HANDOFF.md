# UNIVERSAL AI HANDOFF — Haven OS — Grok, Claude, Meta AI, DeepSeek, Gemini — ONE FILE

**Branch:** feature/haven-central-fixes
**Current HEAD:** 85d852d (origin synced, analyze No issues at 76900b6)
**Last 3:** 85d852d docs handoff, e6d63ba copy, 76900b6 feat GigIncome storage Phase 2 complete
**Repo:** berry82D/haven_os

## LAWS (from CLAUDE.md)
Law 2: ONE complete file replacement only. Law 3: analyze + add + commit + push each file. Law 5: No issues before push. Law 12: householdId filtering .where((x)=>x.householdId==_currentUser?.householdId). Law 17: Read DEV_LOG + CLAUDE before coding.

## DONE — Phase 2 @76900b6
- lib/models/gig_income.dart: id,userId,householdId,date,platform(GigPlatform enum doordash,uberEats,spark,instacart,lyft,uber,other),basePay,tips,bonus,mileage,miles,totalAmount,notes,transactionId, getters totalPay, payPerMile, tipPercent, formattedDate, platformName, formattedTotal, toJson/fromJson
- lib/core/storage/storage_service.dart: saveAll/loadAll includes List<GigIncome> gigIncomes + import
- lib/services/app_state.dart: List<GigIncome> _gigIncomes, myGigIncomes filtered, gigIncomes getter, addGigIncome, deleteGigIncome, updateGigIncome, wired in initialize/_saveData/_seedData, pin logic intact (isPinEnabled, pinVerified, needsPinReentry, _refreshPinStatus) DO NOT BREAK
- Analyze: No issues found! at 76900b6

## NEXT — Phase 3 — File to create: lib/screens/gig_income/gig_income_screen.dart
Requirements: Scaffold AppBar "Gig Income", Consumer<AppState> myGigIncomes sorted date desc, ListTile title platformName + formattedTotal, subtitle formattedDate + miles + payPerMile + tipPercent, trailing edit/delete, Summary card total month/miles/avg, FAB dialog with platform dropdown, date picker, basePay,tips,bonus,miles,mileage,notes, auto totalAmount=basePay+tips+bonus, save via addGigIncome/updateGigIncome with userId/currentUser.id householdId/currentUser.householdId

## START COMMANDS
git checkout feature/haven-central-fixes
git pull origin feature/haven-central-fixes
git log --oneline -3
flutter analyze

## UNIVERSAL PROMPT FOR ANY AI (Copy/Paste to Grok/Claude/Meta/DeepSeek/Gemini)
Read AI_HANDOFF.md at root of berry82D/haven_os branch feature/haven-central-fixes HEAD 85d852d. Read CLAUDE.md Laws 1-17 and DEV_LOG.md. Run git log + flutter analyze. Then create ONE complete file lib/screens/gig_income/gig_income_screen.dart per Phase 3 in AI_HANDOFF.md. Law 2 full file, Law 5 analyze clean, Law 3 commit+push. No questions — all context in AI_HANDOFF.md and lib/models/gig_income.dart. Branch 85d852d is clean.

## PASS-OFF CHECK
Good AI output: shows 85d852d, analyze No issues, plan for gig_income_screen.dart, does NOT ask for GigIncome fields. Bad: asks 100 questions = did NOT read AI_HANDOFF.md.