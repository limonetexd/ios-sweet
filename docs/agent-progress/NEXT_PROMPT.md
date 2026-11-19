> State 2026-11-20 (records through the 0171t row of `TEST_LOG.md`).
> - Best at native 1125x2436: 0171a/0171t = kernel 0164/0165 + `gpu_slack=1` + metal 0017 `sweetmetal_async=1`: 27.4-27.7 swaps/s, best second 51-52, 0 faults (one boot each, `experimental`, picture NOT yet confirmed by the user). Phone root = `work1.raw` + 0017 binaries (rollback `~/Developer/ios-sweet-work/root/rollback-0016`).
> - True GPU time (xnu 0165 `gpu_ts=1`): ~21 ms of execution a frame (3.4 submissions x 7.2 ms), GPU busy only 37-63 %. Forced GMEM (0170g) loses: keep the autotuner.
> - Kernel 0165 in `~/Developer/ios-sweet-work/kernel-0165/xnu-kernel`. CI `xnu` runs on `gpu` only by `gh workflow run xnu.yml --ref gpu`.
> - Read first: `UPSTREAM_SURVEY-2026-11-19.md`, the last three sections of `TEST_LOG.md`.
> - Traps: image builds need `PATH=$HOME/Developer/ios-sweet-work/bin:$PATH` and `bash tools/...`; check sha256 and `rg -a -o NAME=` in the image. `SWEET_SERIAL=f492cad9` for boot tests.

# Next phase (lead: Fable or Opus): GPU work per frame at native, and the idle 40 %

0. Ask the user to look at one 0171a-style boot and confirm the picture (no tearing, no stale frames, apps open/close). Until then 0017 stays default off.
1. Where the 21 ms goes: per-pass GPU time. Extend the passlog (metal 0013) or the 0165 timestamps to tag each submission with its pass (attachment size, draws, gmem/sysmem) and log the top passes per 5 s. Compare with HakiOS (`metal-measurements.md`: full-screen home pass 6-13 ms; luma_boost was 83 % of their GPU passes; wallpaper_freeze home 50 -> 92).
2. The idle 40 %: what the GPU waits for between submissions (kernel flush 1.3 ms a submission, take 2.2 ms, present 3.4 ms; 3.4 submissions a frame = three flush points). Candidates from DC28088 (same phone): no per-submission cache cleans of imported surfaces (their 0174: ioctl 2400 -> 605 us), page-flip/GPU present copy.
3. One change, one boot, record, stop.

Still open: defaults for `gpu_slack=1`, `sweet_surfclear_ms=0`, `sweetmetal_async=1` (need more than one boot and the user's eye); thermal cap before `SWEET_CPUMAX=1`.
