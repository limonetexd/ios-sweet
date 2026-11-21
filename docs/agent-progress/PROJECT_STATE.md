# Project state — 2026-11-20 (records through `0e06cf4`)

**Revision:** branch `gpu`, pushed to `origin` (`limonetexd/ios-sweet-gpu`) for CI builds; `origin/gpu` may trail local HEAD. Agent files (`CLAUDE.md`, `.claude/`, this directory) are tracked.

**Phase:** 0, 1, 1b done. Metal is the primary path (user, 2026-11-08). Metal draws the UI on the phone with `metal_profile=1` and patches 0003-0007 (0160vA: UI renders recognisably); on-device self-test 15 of 19 pass (0160vA). Details and work list: `METAL_FINDINGS.md`. `fix-in-place` still governs GL, which stays the default. No kernel or device changes.

## What works, at what evidence level

Nothing is `verified-working`. Full table: `FEATURE_MATRIX.md`.

- `partially-working` (real device, `NOTES.md` only): boot to SpringBoard, UFS/HFSX root, CPU-copy display, touch, CoreAnimation on the A618 via Mesa GL, 512 MiB GPU VA.
- `partially-working` (real device, two boots, `TEST_LOG` 0160s2, 0160w1): GL home screen (SpringBoard, lock screen, Control Centre, Settings, touch; laggy); second boot about 2 min.
- `partially-working` (real device, one boot, 0160vA): Metal UI renders recognisably (Settings, home, App Library, Control Centre). Faults: respring on app exit, blur dotted pattern, missing glyphs, low frame rate. Self-test 15 of 19 (0160vA).
- `experimental`: Wi-Fi (rungs 1–2 passed; rung 3 result unrecorded), battery.
- `not-working`: sustained 60 fps (best no-idle run 36 swaps/s; swipe runs are bursts with no per-frame data), 120 Hz, automated screenshots, blur-dismiss stability.
- Host: `check-patch.py` 151/151 (2026-11-21); `validate-repo.py` fails on known numbering.

## Environment gaps

- `logs/` recovered 2026-11-08 (gitignored); `reports/` absent. Metal work tree, IPSW and shaders are outside the repository.
- Present: `aarch64-linux-gnu-gcc`, `mkbootimg` (in `~/Developer/ios-sweet-work/bin`, put it on `PATH`), `ipsw` (`/usr/local/bin`). Missing: `qemu-system-aarch64`, `img2simg`. Kernel patch tree: `~/Developer/ios-sweet-work/cxnu` (not `~/cxnu`; `tools/xnu-tree.sh` defaults to `~/cxnu`, see the warning below).

## Top three next tasks

Re-planned 2026-11-11 (full list: `METAL_FINDINGS.md` section 10; routing: `SUBAGENTS.md`).

1. GPU fault then compositor crash (0160d9, `METAL_FINDINGS.md` 10 item 1b). Respring on app exit is `partially-working` with patches 0008+0009 (one boot, attribution unknown).
2. (withdrawn) Blue tint of whites: camera artefact, not on the screen (user, 2026-11-11).
3. Visual faults: patch 0010 (scissor rectangle) is on the phone, `partially-working` (0161sA/0161sB, one boot each, 2026-11-12): green fault and app-close fault gone with it, back without it; self-test 16 of 20. Left: status-bar battery icon, dotted blur, Control Centre glyphs, widgets.
4. Frame rate (user priority 1), 2026-11-14: RAM boots only. 750x1624 boots drew only a strip at the top of the screen (user photos): their numbers are invalid. Valid: 1125x2436 + sysmem + 60 Hz (0168s60), 26.1 ms a frame, best second 29, 0 faults. 60 not reached. 1125x2436 is capped at 30 (26 ms a frame). The 60 Hz fault is a GMEM over-fetch, avoided by `sweetmetal_fddebug=sysmem`. Since then: 0162 booted (0169pf, 0169sf; `sweet_surfclear_ms=0` -1.66 ms, one boot); 0163 fixes the 750x1624 strip (`144ba95`); Metal 0016 (commit before the GPU wait) closed as neutral; xnu 0164 `gpu_slack=1` (default off) lets GMEM run at native with 0 faults: GPU 21.95 -> 18.87 ms a submission, 21.4 swaps/s (0165b, one boot). Only 32 % of batches are tiled. 2026-11-19/20: forced GMEM loses (0170g); metal 0017 async completion (`sweetmetal_async=1`, default off) 27.4 swaps/s, best 51 (0171a, picture not user-confirmed); xnu 0165 `gpu_ts=1`: ~21 ms GPU execution a frame, GPU busy 37-63 % (0171t). 2026-11-21: 750x1624 with async completion is the first config the user calls smooth (0174s, best second 61; pixelated, rdar bar, some freezes); AMP (0166) and DontCare (0020) neutral. Upstream: `UPSTREAM_SURVEY-2026-11-19.md`, `SMOOTH_PORTS-2026-11-21.md`. Detail: `TEST_LOG.md` (last sections); next: `NEXT_PROMPT.md`.

Video (decoder, YUV compositing) needs its own audit and is `not-tested`.

## Handoff

- Current phase and next step: `NEXT_PROMPT.md` (2026-11-21: keep 750x1624's smoothness at a better picture).
- **Risk (still true):** donor license unresolved (`ios-topaz` none detected, `hackios` NOASSERTION; `hakios-metal/` is MIT). `tools/xnu-tree.sh:44-45` runs `git reset --hard` and `clean -fdx` in its `XNU_TREE` target (default `~/cxnu`), so never point it at this repository.
