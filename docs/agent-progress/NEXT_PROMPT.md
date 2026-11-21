> State 2026-11-21 night (records through the 0177f rows of `TEST_LOG.md`; branch `gpu`, local HEAD after `7f4d760`, not pushed this session).
> - **Kernel now:** CI kernel 0165+0167+0168+0169 (`~/Developer/ios-sweet-work/kernel-0169/xnu-kernel`). Images: `shim/out/shim-boot-0175e.img` (best config, 750x1624, 1.5x filter) and `shim-boot-0177f.img` (= 0175e + `sweetmetal_fc_undef=1`).
> - **Upscale step CLOSED (0175eU):** user: "not exactly sharp, I guess it's better... very smooth! but lags when an animation starts, only the first time". Copy 3.53 ms median.
> - **Phone root:** `work1.raw` + metal 0017-0022 payload (flashed 0177f). Rollbacks: `~/Developer/ios-sweet-work/root/rollback-0016`. After reading files off `work1.raw`, DETACH it (`hdiutil detach`), or the next flash fails with "Recurso ocupado".
> - **metaltest 18/21 on 0177f:** 18/19 draw NOTHING (clear colour 404040ff everywhere); 06 "library from source" timed out once (passed before; recheck); 17 GPU times 0.
> - Tools: `PATH=$HOME/Developer/ios-sweet-work/bin:$PATH`. Metal: `bash tools/metal-build.sh {ios,driver,test,payload}` (NOT `host` unless needed: it wipes the host tree, including the `AIR_EVAL_ZERO`/`AIR_EVAL_PRINT` diagnostic in host `air2nir.c`). Flash+boot: `SWEET_SERIAL=f492cad9 nohup tools/metal-flash-test.sh ~/Developer/ios-sweet-work/root/work1.raw IMAGE TAG 720 & disown` (~30 min; userdata flash needs the user's typed yes each session). If `sweet-boot-test.sh` says "recovery adb did not come up", re-run `fastboot reboot recovery` + `tools/sweet-log-pull.sh` by hand (0175eU).
> - CPU model of a QuartzCore shader: `air2nir --ll` -> scratchpad harness (`cpuref/`, session scratchpad, may be gone; method in `RESEARCH_LEDGER.md` 2026-11-21 last row). LLVM 23 at `/usr/local/opt/llvm/bin`. `tools/air/cpuref.py` does NOT exist.

# Next phase: metaltest 18/19 draw nothing (user asked: "make it pass all of the metal tests")

Known (2026-11-21):
- Metal 0022: our runtime used to report EVERY function constant defined as 0; Metal reports unset ones undefined. Boot-arg `sweetmetal_fc_undef=1` (default off) fixes that. CPU model: with it, `fixed_frag_lph_cph` outputs the vertex colour; without it (0,0,0,0). On the device it changed nothing visible (UI or tests) because nothing is drawn.
- User decision: keep the boot-arg for now; make it the default once app constants are plumbed (below) and that goes well.

1. **Why the CA quad draws nothing.** 18/19 are the only tests with `drawIndexedPrimitives` (index buffer = the same pool buffer at `IOFF`) and a vertex buffer at a non-zero offset (`VOFF=96`), `metaltest.m:905,912`. One build/boot that splits it: keep the CA pipeline, draw non-indexed at offset 0 in one sub-case, and test 08's simple pipeline indexed with offsets in another (or add a new test so 18/19 stay unchanged). Read `redwoodmetal.m` `indexBufferOffset` (lines ~1184, 5976, 7092, 7269-7301) and the vertex-buffer offset path before building.
2. Recheck test 06 on that boot (one timeout so far).
3. **App function constants never reach the compiler** (`redwoodmetal.m` has no path; `newFunctionWithName:constantValues:` returns a function on the device, fc=empty). CA's real pipelines therefore run without their constants: a strong lead for the UI faults (no wallpaper, widgets, lines, rdar bar?). Needs REA on Metal.framework: where `_MTLFunction` (or its specialized subclass) keeps the `MTLFunctionConstantValues`. Hopper demo mode was on 2026-11-21; ask the user before REA. Then plumb them into `air_constant_value` (defined = set by the app), and make `sweetmetal_fc_undef` the default if the UI holds.
4. Test 17 GPU times (optional), then the old list: rdar status bar, 828x1792, first-animation stall, freezes.

Rules: one change per build/boot; state the rung; a `TEST_LOG.md` row per boot; stop at the phase end and rewrite this file.
