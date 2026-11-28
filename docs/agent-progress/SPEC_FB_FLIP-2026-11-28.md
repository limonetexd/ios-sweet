# Spec: xnu 0170 `sweet-fb-page-flip` (port of Dana 0181 + 0244 modes 0/1 + 0245), default off

Date 2026-11-28. Source: `DanaTheScripterAlt/ios-sweet` via local branch `gpu-dana` (`a7ebe65`), files
`~/Developer/ios-sweet-work/gpu-dana/tree/xnu/patches/{0181-sweet-page-flip-present,0244-sweet-fb-flip-live-modes,0245-sweet-fb-flip-flush-line-guard}.patch`. License MIT (dipa-studio lineage). Their tree ran it on this phone (d02/d03, `sweetfbflip=1`, 0 GPU faults, one boot).

## Why
Our present (`AppleCLCD::present`/`copy`, `iokit/Kernel/arm/SweetFramebuffer.cpp`) copies (scaled, 0167-0169) straight
into ABL's single continuous-splash buffer that the display controller is scanning, then races the beam (0144/0145).
A second buffer + flip removes the race and tearing: draw into the buffer not being scanned, then point pipe VIG0 at it.

## Not in scope
- Dana 0246 GPU present copy: needs their kernel Adreno submit API (`sweet_native_adreno_submit_async`, `SweetNativeAdreno*.cpp`), absent here. Deferred.
- 0244 modes 2 and 3 (diagnostics). `sweetmotion` / ALS. Any change to the default path.

## Behaviour
1. Boot-arg `sweetfbflip=1` enables it; absent or 0 = today's code path, byte-for-byte the same behaviour.
2. `flipSetup()` once at start: find a second panel-sized buffer (1080x2400x4, ABL pitch) in the rest of ABL's
   cont_splash region exactly as Dana 0181 does; verify the region is large enough and the MDP register block maps.
   Any check fails -> log `SWEET FLIP: off (<why>)`, stay single-buffer. Never write MDP registers before all checks pass.
3. Per present with flip on: copy (existing scaled/bilinear copy, existing copy helper split) into the back buffer;
   wait for the previous flip to latch (`flipWait`, bounded, Dana's timeout); write VIG0 SRC0 = back buffer phys and
   CTL0 flush with mask `sweet_fb_flip_mask` (default 0x20041), honouring the 0245 line guard (default 64 lines, <= 1 ms
   wait). Skip the beam-race wait (0144/0145) for flipped frames only.
4. Partial/dirty-rect presents: the back buffer is a frame old, so either copy the whole frame or copy the union of
   the last two damage rects. Use whatever Dana 0181 does; state which in a comment.
5. Flip timeout or any error -> `flipAbandon(why)`: point VIG0 back at buffer 0, single-buffer from then on, log once.
6. Kernel console / panic text draws into buffer 0 only: on panic/console paths keep or restore scan = buffer 0 as Dana does.
7. Live sysctls as Dana 0244/0245: `kern.sweet_fb_flip` (0/1), `kern.sweet_fb_flip_mask`, `kern.sweet_fb_flip_guard`;
   change applied at the next present.
8. 10 s stats line `SWEET FLIP: flips= wait_avg_us= wait_max_us= timeouts= scan= on= underrun1= underrun2= guard_waits=`
   inside the existing `statsReport`.

## Hardware-write rule
Only the registers and values Dana's tested patches write (VIG0 SRC0 address, CTL0 flush bits, INTR_STATUS read/clear
for underrun). Copy offsets from their code; cite the Dana line in a comment. No new registers, no guessed values.

## Deliverable
- Edit `~/Developer/ios-sweet-work/cxnu/iokit/Kernel/arm/SweetFramebuffer.cpp` only (working tree; do not commit).
- Patch header comment in the code: `0170` and credit "ported from DanaTheScripterAlt/ios-sweet 0181/0244/0245 (MIT)".
- It must build on host: whatever compile check the tree offers (or `clang -fsyntax-only` with the tree's flags if available); report what ran.

## Test plan (lead, later)
CI `xnu` on `gpu`; RAM boot A/B at 750x1624 + async (0175e config): flag off vs `sweetfbflip=1`; cold, warm, stress;
`tools/sweet-fps-summary.py`; `TEST_LOG` row per boot.

## Addendum (lead, 2026-11-28, after opus-impl blocker report)
- MDP block: `SWEET_MDP_PA 0x0ae00000ULL`, `SWEET_MDP_LEN 0x86000` (Dana 0180 lines 83-84). Cross-check: our
  `SWEET_INTF1_PA 0x0ae6b800` = MDP + 0x6b800, the same INTF_1 offset Dana addresses. Map read/write only inside flipSetup, after checks.
- Active lines for the 0245 guard: read-only, as Dana 0145 lines 91-111: per enabled INTF (1 then 2) read
  `INTF_HSYNC_CTL 0x008`, `INTF_VSYNC_PERIOD_F0 0x00c`, `INTF_DISPLAY_V_START_F0 0x01c`, `INTF_DISPLAY_V_END_F0 0x024`
  (Dana 0145 lines 17-24; our tree already defines 0x000/0x0a8/0x0ac/0x0b0 identically); hp = hsync_ctl >> 16;
  total = period/hp, first = vstart/hp, last = (vend+1)/hp; accept only if last > first, last <= total, last-first == fHeight.
  Store in new fields `fFlipFirst`/`fFlipLast`/`fFlipTotal` (do not alter `beamMeasure` or `fBeamLines`). Not found -> guard off, log it, flip still allowed.
- `fPixels`/screenshot: do not repoint `fPixels` or `fSurface`. Screenshot (`shotLoop`) and kernel console keep reading buffer 0;
  while flip is on, make buffer 0 hold the latest frame only if that is cheap (else document that shots show buffer 0 and may be one frame stale/old).
- Present hook placement in our `present()`/`copy()` is by hand; keep the `bool` return contract.
