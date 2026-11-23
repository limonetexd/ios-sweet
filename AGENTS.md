# Working on ios-sweet

- Read `CLAUDE.md` first, then `docs/agent-progress/PROJECT_STATE.md` and
  `docs/agent-progress/NEXT_PROMPT.md` (the next concrete action). `NOTES.md` is the
  detailed running log: project goal, hardware facts, artifact locations.
- The user switches agents frequently. After each milestone and before stopping,
  add the dated entry at the top of `NOTES.md` and update `PROJECT_STATE.md` and
  `NEXT_PROMPT.md` to match. Record commits, CI run IDs, exact
  build/boot results and unfinished work. Distinguish observations from guesses.
- Commit completed changes. Use `gh` for GitHub Actions kernel builds and logs.
  Local single-file cross-compiles are useful before spending a CI run.
- Device bring-up uses temporary `fastboot boot` images. Preserve the Android
  installation and partition backups. The user approved (2026-10-15) using
  internal UFS for iOS and said Android may be deleted: the iOS root goes
  into the existing `userdata` partition (no GPT changes). Keep bootloaders,
  recovery, modem, persist and the backups intact, and confirm each
  destructive step with the user before running it.
- Keep device dumps, serial numbers and downloaded Apple artifacts out of git.

- Follow `PRIVACY.md`: never publish device/SIM IDs, phone/call/SMS records,
  carrier/cell-location details, personal network identifiers or raw device logs.
- Public history was privacy-rewritten on 2026-11-03. Never merge/push pre-cleanup
  history; start from the cleaned remote and transplant reviewed code changes.
