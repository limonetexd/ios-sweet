# Next phase: port Dana's iOS 16 present path (page flip / GPU copy) to `gpu`, behind a flag

Decision 2026-11-28 (`DECISIONS.md`): stay on iOS 16.7.16, `gpu` line. Upstream iOS 26 work: `UPSTREAM_STATUS-2026-11-28.md`.
Phone: fastboot; root = 0181s + Dana `SweetMetal2.bundle` (additive, harmless: 0183r 20/20 of 24/24 on 0177f).
`gpu-dana` (`a7ebe65`, worktree `~/Developer/ios-sweet-work/gpu-dana/tree`) is a parts bin only; d02/d03 in its TEST_LOG.

1. Put the metaltest job back to one pass: mount `work1.raw`, `tools/sweet-metaltest-job.py MOUNT --apply`, detach,
   flash with `tools/metal-flash-test.sh` (standing yes; state the rung). Confirm with one boot.
2. Port (opus-impl, from a written spec): Dana's iOS 16 present patches — `sweetfbflip`/`sweetfbgpu`
   (their 0244-0246: flip, flush guard, GPU present copy; find them in `gpu-dana:xnu/patches`) — onto our kernel
   (`~/Developer/ios-sweet-work/cxnu`, CI `xnu` workflow on `gpu`), default off. Reviewer before CI.
   Record source/commit/license in `RESEARCH_LEDGER.md`. Their FB scheduler showed `target=10 Hz` in d03: check what sets it.
3. A/B on the device at 750x1624 + async (0175e config): flag off vs on; cold, warm, stress; `tools/sweet-fps-summary.py`.
4. Do not port `sweetmotion` ALS (bit 0x04): it hangs backboardd on our root (d02).

Rules: one change per build/boot; state the rung; a `TEST_LOG.md` row per boot; stop at the phase end and rewrite this file.
