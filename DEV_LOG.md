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

