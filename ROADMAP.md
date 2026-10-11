# Haven OS - Roadmap

**Updated:** 2026-10-10 evening. **HEAD:** c290f26. Read with `AI_HANDOFF.md`, `WIP.md` (if present), `DEV_LOG.md`.

## DONE
- Cloud build + signing (Flutter 3.44.8, fingerprint-verified, `install -r` only)
- Auth: username resolution from Firestore profile, `auth_username` on every sign-in
- Finances Chunk #1: Week/Month toggle + "Left this period" hero
- Settings gear -> Household Management link (invite code + join UI)
- Household cloud join: sign-in publishes household + invite index, Firestore rules for `households/{id}` + `household_invites/{code}`
- Data sync: household data root + one-time non-destructive merge - both phones synced
- Finances Chunk #2: chart tap -> month anchor -> week chips (Monday-anchored, clipped, no bleed), overshoot fix - code shipped, awaiting phone test
- Laws 18 (WIP.md) + 19 (HANDOFF block) + 20 (ROADMAP LAW)

## NOW
1. Phone-test Chunk #2 (5 tests in `WIP.md`: chips appear, chip tap recalcs, bar tap swaps month, no overshoot, no errors)
2. Live sync test: add transaction on one phone -> appears on the other
3. Delete `WIP.md` after both pass

## NEXT
4. Finances Chunks #3-6 (per `finances-redesign-mockup` artifact: formula drawer, coaching, period control polish)
5. Move bills / animals / gig income from per-phone local to household sync; retire the `pending_join` workaround
6. Monarch/Jarvis visual pass on dense screens ("fancy when it's complicated", dark theme stays, app teaches)

## LATER
7. Kitchen Aid: real Recipes / Pantry / Shopping behind the placeholder tab
8. Show an error (not endless loading) on Firestore PERMISSION_DENIED
9. Forgotten-username hint on sign-in
10. Clean up duplicate Firebase Auth accounts (2 each for David and Candice - review in console first)
11. Package rename (`com.example.haven_os`) before any Play Store release
12. D:\ flash-drive update once a stable build is confirmed (contents TBD - David provides `dir` listing)

## RULES FOR THIS FILE
- Keep it short. One line per item.
- Move items DONE -> NOW -> NEXT as work lands. Delete, don't accumulate.
- If you're an AI picking up work, start at NOW #1. If NOW is empty, take the top of NEXT.