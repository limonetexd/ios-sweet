# Project state — 2026-11-23, branch `gpu-dana`

**Revision:** branch `gpu-dana`, merge `4e8b5cf` = `dana/main` `fa8c53a` (first parent) + `gpu` `084dad8`.
Repository `limonetexd/ios-sweet` (renamed from `ios-sweet-gpu` on 2026-11-23). The redwood line is branch `gpu`;
its state file is `git show gpu:docs/agent-progress/PROJECT_STATE.md` (last record: 0182c, metaltest 24/24 cold +
warm + stress on `5cf3dec`).

**Phase:** upstream merge done (research + branch). Nothing of this branch has run on our phone.

## What this branch is

- Kernel (`xnu/patches` 0001-0249, `xnu/patches-12377`), `shim/`, `userspace/`, workflows: DC28088/Dana's,
  byte-identical to `dana/main`. Who did what and license status: `CREDITS.md`.
- From `gpu`: `userspace/metaltest/` (+ `build.sh`), `CLAUDE.md`, `.claude/`, these ledgers, boot/flash helpers
  in `tools/`, the branch record `docs/branches/gpu-redwood/`.
- Comparison and the reasons: `UPSTREAM_MERGE-2026-11-23.md`.

## What works, at what evidence level

- `not-tested` on our phone: everything. Their own log (their phone) reports Metal UI at ~45 fps in interaction
  windows, Wi-Fi, BT, speaker audio, haptics, battery, calls, sensors, sleep, page flip, GPU present copy.
- Host: `userspace/metaltest/build.sh` builds a binary byte-identical to the 24/24 one (`4f901701...`).

## Blockers for a device test (detail: `UPSTREAM_MERGE-2026-11-23.md` section 4)

1. No auto return to fastboot in their iOS 16 kernel (ours is inside redwood 0082): port as patch 0250.
2. Their userspace bundles must be built by their workflows and installed into a copy of `work1.raw`.
3. ADT with firmware pulled read-only from the phone (git-ignored).

## Risks

- License: DC28088 and Dana have no license file; the owner contacted them, nothing granted yet (`CREDITS.md`).
- Their notes describe flashing userdata without a backup (iOS 26). Our Safety rules apply on this branch.
- `tools/xnu-tree.sh` runs `git reset --hard` / `clean -fdx` in `XNU_TREE` (default `~/cxnu`): never this repo.
- Phone: left in fastboot after 0182c, root = 0181s (redwood); rollback `~/Developer/ios-sweet-work/root/rollback-0016`.

## Top three next tasks

1. Patch 0250: `sg_reboot_fastboot` as a standalone boot-arg on their kernel (opus-impl + reviewer), CI build.
2. Build their iOS 16 userspace on CI (`native-metal.yml`, `wifi-0239.yml`, `audio.yml`, `bt.yml`, `ssh.yml`).
3. Root + ADT + image for their best config (2482), RAM boot, then `metaltest --runs 20` on their stack.
