# Upstream survey, 2026-11-19 (GPU / frame rate)

Sources read through the GitHub API on 2026-11-19. Every number below is the other project's own claim, on its own
hardware, unverified here. Label: `not-tested` on sweet.

## Our baseline (sweet, A618 @ 650 MHz, 1125x2436, Metal over Gallium freedreno)

0165b: 21.4 swaps/s, cpu/cb 7.37 ms (96 draws/cb, ~77 us a draw), client fence wait 15.9 ms, 3.2 submissions/cb,
panel copy 3.2 ms. 0170g (2026-11-19): forced GMEM is worse (19.7 swaps/s); keep the autotuner.

## Same phone, same donor: `DC28088/ios-sweet` (README + NOTES.md, pushed 2026-11-19; no repo license, native-metal MIT from HakiOS)

- Same architecture as ours: HakiOS userland `a79ff07` AIR -> NIR -> Gallium freedreno/ir3, own kernel ABI ("NativeAdreno ABI1").
- Claim: ~45 fps in interaction windows at 1125x2436 (NOTES 2026-11-11: 441-467 presents/10 s, present 10.6-11.6 ms =
  GPU-fence gate 7.8-8.8 ms + copy 2.4-2.6 ms); README: "about 37 fps during animations (GPU wait ~7 ms + display copy 4-8 ms)".
  Peak 1199 presents/10 s with no GPU wait: their present path can do 120 Hz.
- Their GPU fence wait is ~8 ms a frame against our 15.9 ms on the same GPU. Their listed changes: reused render surfaces
  and bindings, kernel-owned GPU buffers, scoped imported-buffer cache ownership, cached aligned constant uploads,
  UBO bounds proven from the shader (no constant-buffer copies), one wait per command buffer at commit, framebuffer kept
  across consecutive draws to the same attachments (lets freedreno batch), AMP spill thresholds lowered.
- Profile (NOTES 2026-11-11 20:40): render thread 42 % in commit, `fd_draw_vbo` 26 %, `flush_deferred_submits` 22 %,
  `drmCommandWriteRead` 21 % (transport wait 257, `submitResources` 160 samples).
- Planned there, not done: A6xx 2D-engine scaled blit for the panel copy (mesa `fd6_blitter.cc`), direct scanout + VIG0 QSEED scaler.

## HakiOS main tree: `oosexgang/hakios-xnu-kernel` (pushed 2026-11-10; `hakios-metal/` MIT; kernel part APSL-derived)

POCO X5 Pro, Adreno 642L @ 550 MHz (a bigger GPU than the A618), 1125x2436 rendered:
- `hakios-metal` = a **direct Metal -> PM4 engine** (no Gallium): shaders AIR -> NIR -> ir3, its own command streams.
  Refuses any chip ID but its own (2.3.3). Swipe 100-104 fps, scroll ~90, home ~90; GPU ~10 ms a frame at home.
  At 750x1624 (`fbscale=2`): scroll 118-120, swipe 107-118.
- What moved their numbers (`docs/reference/metal-measurements.md`, CHANGELOG):
  - `metal_defer=1`: command buffers recorded on a thread of the engine's own; a draw costs the render thread ~5 us, not ~40.
  - vcvkk merge (2026-11-01): hardware binning (RM6_BIN_END_OF_DRAWS per tile), uber shaders specialised with 128-wide
    fragment waves, resident programs, flat register shadow, repeated state skipped, UBWC textures.
  - `luma_boost` left out where QuartzCore's library has its own: it was 83 % of the GPU's timed passes (their plug-in only).
  - `wallpaper_freeze=1` (wallpaper as one picture): home button 50 -> 92. `wallpaper_cache=1`: swipes 85-91 -> 97-103.
  - `fb_threads=6` (copy threads 3 -> 6): scroll 75 -> 84. `fb_beam=1`: write rows behind the scan line, no tearing.
  - Run-time CA pipelines get the nearest variant of the same kind (fixed red wallpaper head, white status-bar band,
    Weather widget materials) -- possibly relevant to our missing glyphs / widgets.
  - Shader stages cached across boots (`/var/db/hakios-metal-cache`), seeded into the image.
- Metal-on-Vulkan (metal2vulkan + Turnip) on the same phone: 50-57 fps, GPU 14-21 ms a frame: slower than the direct path.

## Others

- `MakrSas/ios-topaz` 0949: ten 12 MB contiguous buffers for 1125x2436 surfaces, shared with the GPU instead of read back
  (removed 30-160 ms hitches in blurred animations). 0948 (timing elements) we already have (xnu 0095/0116).
- `joranv1/ios-sailfish` 0182: present (GPU scale + flip) on a kernel thread; flush only pages the CPU wrote since the last
  submit (pmap modified bit; was ~1/4 of backboardd's CPU); 30 -> 37 fps.
- `UniXNU/UniXNU-sheng` (A740): direct scanout through the display SMMU, fence waiters woken by the GPU interrupt,
  submissions no longer clean 8.5 MB of context buffers each, GPU DCVS with wake boost. `UniXNU/AdrenoMetal` is MIT.
- Mesa 26.x freedreno: nothing found that targets this (release notes only show small a6xx register/drm-shim changes).

## What this says for us

1. Our GPU fence wait (15.9 ms) is twice DC28088's (~8 ms) on identical hardware and the same donor: the gap is in our
   path, not the GPU. Their kernel/transport differences (kernel-owned buffers, cache ownership, no per-submission
   context cleans) and the userland ones above are the first places to look. xnu 0165 `gpu_ts=1` will say how much of
   our 15.9 ms is GPU execution and how much is submission/cache work and queueing.
2. CPU per draw (~77 us) is 2x HakiOS's pre-defer cost (~40 us) and 15x its deferred cost (~5 us).
3. A direct PM4 engine (hakios-metal) is the fastest known path but A642L-only; porting it to the A618 is a GPU_DECISION
   R2/R3 question that needs our own timestamps first. Do not start it on these claims alone.
