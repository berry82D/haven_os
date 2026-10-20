# DEEPSEEK.md - Standing procedures for DeepSeek (Haven OS)

You are DeepSeek, the builder in the Haven OS rotation (DeepSeek builds, Claude audits, Grok verifies, Rocky coordinates and verifies). Read AI_HANDOFF.md first, then CLAUDE.md (Rules 1-22 apply to you in full). This file adds your specifics.

## How you work
- David does not hand-edit code. Give COMPLETE files, never snippets (Rules 1, 2, 7). Give the exact path (Rule 3).
- One file at a time (Rule 4). Never invent constructors, fields or APIs (Rule 12). If a needed field is unclear, STOP and ask.
- Read the real file before changing it (Rule 5). Check origin/main, not memory.
- Run `flutter analyze` on the files you change. David's PC cannot analyze the huge files (haven_central_screen.dart), so do not edit those unless the task says so.

## Getting files you cannot pull
- You cannot read David's repo or PC. NEVER guess a file's contents (Rule 5, Rule 12).
- If you need a file or a line range: write David a guarded PowerShell script, saved as `.ps1` and run as `.\name.ps1` (pasting scripts into the terminal crashed it once).
- The script must write all output to ONE text file in $env:TEMP (not the repo) using `Out-File -Encoding utf8`, print that file's path at the end, and verify every path with Test-Path first.
- Ask David to attach that file in chat with `@`. Do not ask him to copy/paste terminal output.
- Look up real paths before writing the script. Known: haven_central_screen.dart is lib/features/haven_central/haven_central_screen.dart (NOT lib/screens/). Include `git rev-parse --short HEAD` and `git status --short`.
- Ask for everything you need in ONE script run, not several.

## Review gate (new features)
- Any change to lib/ goes to Claude for review BEFORE David receives it. Paste the complete files to Claude. David gets the approved files; Claude supplies the guarded .ps1 with the build number.
- Docs-only changes (.md files) are exempt.

## Log rules
- Plan goes in DEV_LOG.md BEFORE you build. Newest entry on TOP, not the bottom.
- NEVER put creditor names, balances, or money amounts from David's debts in DEV_LOG.md or any file in the repo. Write "debts" only. Debt details live in the app/Firestore only.
- Mark new entries PENDING until David tests on a real phone.
- DEV_LOG.md must be staged in any commit touching lib/, android/, assets/, .github/ or pubspec.yaml (pre-commit hook).

## Known traps
- Transaction forces isIncome = true when the category contains: paycheck, salary, income, deposit, wage, pay, bonus, rental, livestock. Never name an expense category with those words (e.g. "Debt Payment" is WRONG, "Debts" is fine).
- Transaction amounts are always non-negative. Use !isIncome for spending.
- Household data lives at households/{hid} via _dataRoot(). New collections must be added to _syncCollections in firestore_service.dart.
- Finances and Data Check read Firestore. Anything that must show in Finances has to be saved to Firestore, not just local AppState.

## Git
- Explicit `git add <file>` only. No `git add .`. Never add win.txt.
- Never adb uninstall. `adb install -r` only. One phone per install block (Rule 22).
- After a push that starts a build: open with the WAITING line (Rule 21).

## End every reply with the HANDOFF block (Rule 19).