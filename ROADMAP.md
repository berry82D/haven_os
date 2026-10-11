# Haven OS - Roadmap

**Updated:** 2026-10-11 13:15. **HEAD:** 9530768. Read with `AI_HANDOFF.md`, `WIP.md` (if present), `DEV_LOG.md`.

## DONE
- Cloud build + signing (Flutter 3.44.8, fingerprint-verified, `install -r` only)
- Version labeling: pubspec `1.0.1+1`, workflow extracts version + SHA into artifact name
- Auth: username resolution from Firestore profile, `auth_username` on every sign-in
- Settings gear -> Household Management link (invite code + join UI)
- Household cloud join: sign-in publishes household + invite index, Firestore rules for `households/{id}` + `household_invites/{code}`
- Data sync: household data root + one-time non-destructive merge - both phones synced - VERIFIED
- Finances Chunk #1: Week/Month toggle + "Left this period" hero
- Finances Chunk #2: chart tap -> month anchor -> week stepper (chevrons + picker, faded edges), overshoot fix - VERIFIED on phone
- Money format: comma thousands + sign-before-dollar across Finances - VERIFIED on phone
- Finances: pie + 12-Month Projection collapsed into ExpansionTiles (shorter scroll) - VERIFIED on phone
- Finances: searchable window for Recent Activity (fixed-height + search field) - VERIFIED on phone
- Laws 18 (WIP.md) + 19 (HANDOFF block) + 20 (ROADMAP LAW)

## NOW
1. Phone verify: search filters Recent Activity, window scrolls, page stays short
2. Phone verify: pie + 12-Month Projection start collapsed, tap to expand
3. Phone verify: settings footer shows Haven OS v1.0.1+NN
4. Close WIP.md (delete) once all above pass

## NEXT
5. Home bridge card - money card on Home: "Left this month $X" + "+ Add expense" button + tap-through to Finances; remove placeholder "Reports coming soon" / "Edit Widgets coming next update"
6. Finances display bugs: pie title overlapped by pie; Transport + Groceries both cyan; "Other" legend pink but slice gray
7. Projection math: allTimeNet + avgSavings*12 = straight multiple of net worth, not real forecast. Add label or better formula.
8. Finances - Formula Drawer (tap hero -> slide up "why this number" breakdown)
9. Finances - Coaching Card (one plain-words insight per screen, no shame)
10. Finances - Period Control Polish (tighten toggle + stepper UX per mockup)
11. Move bills / animals / gig income from per-phone local to household sync; retire the `pending_join` workaround
12. Monarch/Jarvis visual pass on dense screens ("fancy when it's complicated", dark theme stays, app teaches)
13. Colorblind mode setting (Deuteranopia / Protanopia / Tritanopia palettes across all screens)

## LATER
14. Kitchen Aid: real Recipes / Pantry / Shopping behind the placeholder tab
15. Show an error (not endless loading) on Firestore PERMISSION_DENIED
16. Forgotten-username hint on sign-in
17. Clean up duplicate Firebase Auth accounts (2 each for David and Candice - review in console first)
18. Package rename (`com.example.haven_os`) before any Play Store release
19. D:\ flash-drive update once a stable build is confirmed (contents TBD - David provides `dir` listing)

## RULES FOR THIS FILE
- Keep it short. One line per item.
- Move items DONE -> NOW -> NEXT as work lands. Delete, don't accumulate.
- If you're an AI picking up work, start at NOW #1. If NOW is empty, take the top of NEXT.