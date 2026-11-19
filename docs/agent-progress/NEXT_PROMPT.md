> State 2026-11-19 (records through `72f84fa`, 2026-11-14). Previous prompt (Phase A, kernel 0162) is done; its results are in `TEST_LOG.md` (0169pf, 0169sf).
> - Valid baseline at native 1125x2436: 0165b = kernel 0164 + `gpu_slack=1`, no `sweetmetal_fddebug`: GPU 18.87 ms a submission, 21.4 swaps/s, 0 faults (one boot, `experimental`). Control 0165a (`sweetmetal_fddebug=sysmem`): 21.95 ms, 20.8 swaps/s.
> - Sustained 60 is NOT reached. Native frame is serial: replay + GPU + panel copy + walk/take.
> - The GMEM over-fetch fault is avoided either by `sweetmetal_fddebug=sysmem` (tiling off) or by `gpu_slack=1` (kernel 0164, default off). Never boot native without one of the two.
> - Closed: 0016 commit-before-GPU-wait (neutral, kept). 750x1624 strip: destination bug fixed by 0163 (`144ba95`); no user-confirmed picture at that size yet, so 750x1624 numbers stay unconfirmed until the user sees the screen.
> - Kernel 0164 is in `~/Developer/ios-sweet-work/kernel-0164`. Phone was last recorded in fastboot (check with `fastboot devices`), root `work1.raw`; nothing flashed.
> - Read first: `NOTES.md` top section, then the last section of `TEST_LOG.md`.
> - Trap: image builds need `PATH=$HOME/Developer/ios-sweet-work/bin:$PATH`; without it the script silently copies the old image. Check the printed sha256 is new and `rg -a -o 'NAME=[^ ]*' IMAGE` shows every boot-arg you added.
> - Trap: with a second adb device attached, set `SWEET_SERIAL` for `tools/sweet-boot-test.sh` (`4e57214`).
> - Summary of a log: `tools/sweet-boot-summary.sh TAG`.

# Next phase (lead: Fable or Opus): the tiling ceiling at native

Question: how much of the GPU time goes away if every batch is tiled? Only 32 % of batches are tiled in 0165b; the freedreno autotuner (`fd_autotune_use_bypass()`, mesa 25.0.7 `freedreno_gmem.c:725`) bypasses the rest. `sweetmetal_fddebug=gmem` forces tiling with no code change.

1. One RAM boot, tag `0170g`: same flags as 0165b plus `sweetmetal_fddebug=gmem`, kernel 0164, `gpu_slack=1`, same image environment as 0165b, with `sweetgpu_reboot` in the payload (rung: reversible, RAM only).
2. Compromise check first: screen draws (the user confirms the picture), no `SMMU`, no `FAR`, no `THE GPU DID NOT`. Then GPU ms a submission, swaps/s, batches gmem vs sysmem, waits.
3. Compare with 0165b. If forced GMEM wins: plan how to make the choice without the debug flag. If not: the next levers are the 3.2 submissions per command buffer (three flush points a frame) and the ~100 blended draws.
4. Record a row in `TEST_LOG.md`, update `NOTES.md` top and this file, stop.

Still open from earlier lists: whether `gpu_slack=1` and `sweet_surfclear_ms=0` become defaults in `tools/sweet-gpu-image.sh` (needs more than one boot each), and a thermal cap before `SWEET_CPUMAX=1` is used outside a test.

Not in this phase: widgets, glyphs, masks, Control Centre.
