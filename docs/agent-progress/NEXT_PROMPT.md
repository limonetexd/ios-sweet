> State 2026-11-21 (records through the 0174s row of `TEST_LOG.md`; branch `gpu`, pushed).
> - **Smooth config (user-confirmed, one boot):** 0174s = kernel 0165 (`~/Developer/ios-sweet-work/kernel-0165/xnu-kernel`, SMP) + `SWEET_SCALE=2` (750x1624) + metal 0017 `sweetmetal_async=1` + `gpu_slack=1`: "extremely smooth, with some freezes and hangs", best second 61, GPU 1.8 ms a submission. Faults: pixelated (nearest-neighbour 1.5x CPU upscale), rdar status bar, freezes/hangs.
> - Native 1125x2436 with the same stack: ~27 swaps/s (0171a/0173d), GPU 7.1 ms a submission x 3.4 a frame.
> - Pacing model (fits every boot): CoreAnimation starts a frame at a vsync only when the previous one completed; commit-to-completion is 36-40 ms at native, so frames take 2-3 vsyncs. CPU-side changes (async, AMP, coalescing, DontCare) barely move it. The lever is GPU time per frame.
> - Closed: forced GMEM (0170g worse), xnu 0166 AMP+no coalescing (0174a: no gain, user "worse"; kernel kept in `kernel-0166` but not used), metal 0020 DontCare discard (correct, neutral, kept), CPUMAX (small).
> - Phone root = `work1.raw` + metal 0017-0020 binaries (diagnostic 0018/0019 `sweetmetal_prof=2/3` are off unless asked). Rollbacks: `~/Developer/ios-sweet-work/root/rollback-0016`.
> - Tools: `bash tools/...`, `PATH=$HOME/Developer/ios-sweet-work/bin:$PATH`; flashes/boots run detached (`nohup ... & disown`, log in `logs/`) because a dying session killed a flash once; `SWEET_SERIAL=f492cad9`. Userdata flash = `tools/metal-flash-test.sh work1.raw IMAGE TAG 420` (~20 min). CI kernel: `gh workflow run xnu.yml -R limonetexd/ios-sweet-gpu --ref gpu`.
> - Read first: `SMOOTH_PORTS-2026-11-21.md`, `UPSTREAM_SURVEY-2026-11-19.md`, last five sections of `TEST_LOG.md`.

# Next phase (lead: Opus/Fable): keep 750x1624's smoothness, at a better picture

User question: "is it possible to achieve this smoothness on higher resolution?" Answer so far: yes in steps. Do them in this order, one change per boot, user looks at each:

1. **Better upscale at 750x1624** (fixes "pixelated" now): bilinear instead of nearest in the kernel's panel copy (HakiOS: nearest while moving, bilinear when still; their `fb_filter=1` cost late shares), or an A6xx 2D-engine scaled blit (mesa `fd6_blitter.cc`, DC28088's plan) that also frees the CPU copy. Find the copy in `SweetFramebuffer.cpp` (`present()`, copy helper threads).
2. **rdar status bar at 750x1624:** HakiOS `inject_sb.c` makes SpringBoard's fallback status bar the iPhone X's; DC28088 found a MobileGestalt cache must match the canvas.
3. **Intermediate size 828x1792 @2x** (iPhone XR class, `fbsubtype=1792`; HakiOS 118 fps scroll, no rdar bar): 1.53x the pixels of 750x1624, still 1.85x fewer than native.
4. **Native:** cut GPU work per frame below ~12 ms: per-pass GPU timing (extend xnu 0165 timestamps per submission with the pass's size/draws), then the heavy passes (blur, wallpaper: HakiOS `wallpaper_freeze`).
5. **Freezes/hangs** at 750x1624: catch one in a log (SWEET FPS `longest`, `not done after`, SpringBoard main thread with `sweetmetal_prof=3`).

Rules: RAM boots only unless userdata must change; state the rung; record a `TEST_LOG.md` row per boot; stop at the phase end and rewrite this file.
