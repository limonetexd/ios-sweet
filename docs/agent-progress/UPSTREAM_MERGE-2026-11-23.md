# Upstream merge: DC28088 / Dana vs `gpu` — 2026-11-23

Refs read: `dana/main` `fa8c53a` (2026-11-21), `dc28088/main` `2b54629` (2026-11-22), `gpu` `084dad8`.
Every DC/Dana number below is **their** record from **their** phone (`NOTES.md` line numbers on `dana/main`
unless marked). Nothing here is measured on our phone. Labels follow `CLAUDE.md`.

## 1. Lineage

- Common history ends at `b05c848` (2026-10-15). Kernel patches 0001-0080 are identical in both lines
  (0020 differs only by a BearSSL mirror fallback, theirs kept). From 0081 the two series are unrelated.
- DC28088/main = 935 commits not in `gpu`. Dana = DC28088 up to `af7e8ab` + 9 commits (0143-0146 sampler
  dumps, 0249 jetsam limits). DC28088 after `af7e8ab`: 26 commits, all iOS 26 (xnu-12377 2012-2015, wland 0009).
- Both Metal paths come from the same donor: HakiOS userland (MIT), AIR -> NIR -> Mesa freedreno/ir3.
  The difference is everything around it: kernel GPU driver, clocks, present path, residency, profiling.

## 2. Subsystem verdict

| Subsystem | `gpu` (ours) | DC/Dana | Better | Why |
| --- | --- | --- | --- | --- |
| Kernel GPU driver | redwood: shim brings GPU up (`gpuprobe.c`), 0082 handoff, 0083 RedwoodGPU | NativeAdreno in XNU: GMU/HFI, zap, SQE/CP, SMMU, rings, fences (0081-0111), scoped submit, BO pools | theirs | owned by the kernel, not the shim; fences and residency are real objects |
| GPU clock | 430 MHz requested (SVS_L1); running clock never measured (`GPU_DECISION.md:35`) | 800 MHz TURBO default, OPP table from the phone's own KGSL, RPMh GFX ARC votes (0083, 0086, 0127, 0143) | theirs | 21 ms x 430/800 ~ 11 ms: the clock alone may explain most of the GPU-time gap (inference) |
| GPU time per frame | ~21 ms execution at 1125x2436 (0171t, `gpu_ts`) | GPU fence gate 7.3-8.8 ms (`NOTES.md` 735-736, 843) | theirs | same UI, same resolution |
| Present path | CPU copy, bilinear 1.5x scaler (0167-0169), render scale (0129-0163) | beam-raced CPU copy, page flip (0181, 0244, 0245), GPU 2D-blit copy 2.3-2.9 ms with nearest/bilinear (0246, `sweetfbflip=1 sweetfbgpu=1`) | theirs | copy on the GPU and flips instead of CPU copies |
| Frame rate | best second 61 at 750x1624 (0174s, user: "smooth", pixelated); 27.4 swaps/s average at native | ~45 fps in interaction windows at 1125x2436 (image 2482, 441-467 presents/10 s); sustained 60 not reached | theirs at native res; ours only at reduced res | neither has measured sustained 60 |
| Low-res trick | 750x1624 @2x + 1.5x bilinear upscale: the config the user calls smooth | 0222 HD/XR modes (750x1624, 828x1792) with CPU nearest upscale ~20 ms a copy (`NOTES.md` 1444, 1499-1512) | combine | their GPU bilinear copy + our low-res canvas has never been tried |
| Metal correctness test | `metaltest` 24/24, cold + warm + stress on one commit (0181s, 0182c) | `qualification false`; correctness judged by eye | ours | device-independent public Metal API: runs on their stack unchanged |
| Profiling | GPU timestamps (0165), fps monitor, pass log | present breakdown (0139), spindump profiles, per-tap latency (0179), sampler (Dana 0143-0146) | both | ours times the GPU, theirs the CPU side |
| Wi-Fi, BT, audio, haptics, battery, calls, sensors, sleep, USB SSH | Wi-Fi and battery `experimental` (ported from DC earlier) | all reported working on iOS 16 (README table) | theirs | we have nothing comparable |
| Process | ladder, ledgers, one change per boot, auto return to fastboot (`sweetgpu_reboot`, inside 0082) | NOTES log; they flashed iOS 26 over userdata with no backup (`dc28088/main:NOTES.md` 958-984) | ours | keep our rules on this branch |

## 3. Decision taken (`DECISIONS.md` row 2026-11-23)

- Branch `gpu-dana` = their tree unchanged + `metaltest` + our rules/ledgers. Merge commit `4e8b5cf`, full history.
- `gpu` stays the known-good redwood line (tag `gpu-known-good-2026-11-23` = `084dad8`); nothing on it changed.
- This is a parallel line, not a cutover. GPU rule: R1-R3 are not shown for redwood; the 800 MHz clock is a
  bounded in-place candidate for `gpu`. `gpu-dana` becomes the main line only after `metaltest` 24/24 and
  cold + warm + stress pass on our phone, recorded in `TEST_LOG.md`.
- iOS 26: not merged (user: "quizás eso aún no"). It is on remote `dc28088` for later.

## 4. What blocks a device test of `gpu-dana`

1. **Return to fastboot.** Their iOS 16 kernel has no `sweetgpu_reboot`; ours lives inside redwood 0082. Port
   only `sg_reboot_fastboot` (PMIC PON soft-reboot reason + IMEM restart reason + PSCI reset, already proven on
   our phone) as a standalone boot-arg patch 0250. Kernel code: `opus-impl` + `reviewer`.
2. **Root.** Their userspace (native-legacy SweetMetal2.bundle + libSweetNativeBackend, wland, audio, BT, SSH)
   must be built by their workflows (`native-metal.yml`, `wifi-0239.yml`, `audio.yml`, `bt.yml`, `ssh.yml`) and
   installed into a copy of `work1.raw`; the iOS 16 root is the same 16.7.16 (20H392).
3. **ADT + firmware.** Their `tools/mkadt.py` embeds Adreno/WLAN/ADSP firmware pulled read-only from the phone
   (`tools/pull-sweet-firmware.py`); git-ignored, never committed.
4. **Kernel build.** `xnu.yml` (dispatch on `gpu-dana`). Host rung only until steps 1-3 exist.

## 5. First experiments once it boots (one change per boot)

1. Their best iOS 16 config as is (image 2482 cmdline: `sweetfbflip=1 sweetfbgpu=1 ...`): baseline on our phone.
2. `metaltest --runs 20` on their stack: correctness evidence they do not have.
3. The user's low-res trick on their present path: `sweetfb_mode=3` (750x1624) + `kern.sweet_fb_gpucopy=2`
   (bilinear GPU copy). Boot-args only, no code, if 0246 scales from that canvas (to check in 0246 first).
