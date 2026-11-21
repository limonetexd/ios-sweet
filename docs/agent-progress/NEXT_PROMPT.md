> State 2026-11-21 late night (records through the host fc-probe rows of `TEST_LOG.md` / `RESEARCH_LEDGER.md`; branch `gpu`, not pushed this session).
> - **Kernel now:** CI kernel 0165+0167+0168+0169 (`~/Developer/ios-sweet-work/kernel-0169/xnu-kernel`). Images: `shim/out/shim-boot-0175e.img` (best config, 750x1624, 1.5x filter) and `shim-boot-0177f.img` (= 0175e + `sweetmetal_fc_undef=1`).
> - **Phone root:** `work1.raw` + metal 0017-0022 payload (flashed 0177f). Rollbacks: `~/Developer/ios-sweet-work/root/rollback-0016`. After reading files off `work1.raw`, DETACH it (`hdiutil detach`), or the next flash fails with "Recurso ocupado". (Detached at the end of this session.)
> - **metaltest 18/21 on 0177f:** 18/19 draw NOTHING (clear colour 404040ff everywhere); 06 "library from source" timed out once; 17 GPU times 0.
> - Tools: `PATH=$HOME/Developer/ios-sweet-work/bin:$PATH`. Metal build tree is `~/Developer/ios-sweet-work/metal-build` (NOT `ios-sweet-work/metal`, an old copy). `bash tools/metal-build.sh {ios,driver,test,payload}` (NOT `host` unless needed: it wipes the host tree). Flash+boot: `SWEET_SERIAL=f492cad9 nohup tools/metal-flash-test.sh ~/Developer/ios-sweet-work/root/work1.raw IMAGE TAG 720 & disown` (~30 min; userdata flash needs the user's typed yes each session).
> - Apple binaries: `ipsw dyld extract <work1.raw mount>/System/Library/Caches/com.apple.dyld/dyld_shared_cache_arm64 Metal` (read-only `hdiutil attach -readonly -nobrowse -imagekey diskimage-class=CRawDiskImage`); `nm`/`otool -tV` answer most questions. REA/Ghidra on the whole 3.5 MB Metal dylib timed out on the first decompile: carve one function to a raw arm64 image instead (method: ledger row for QuartzCore `create_fragment_shader`).

# Next phase: metaltest 18/19 draw nothing (user asked: "make it pass all of the metal tests")

Settled 2026-11-21 (ledger rows "Metal function constants" and "Apple's function specialization folds"):
- Function constants are NOT the missing piece. Apple's specializer (MTLCompilerService, launched on the phone before 18/19) returns a new function whose `bitcodeData` has the constants folded in; unset ones take the shader's default branch. Host-verified (`tools/metal-host/fc-specialize-probe.m`); phone by log hint only. So on the device 18/19's fragment is most likely just "return the vertex colour", and a grey clear means NO fragments were produced at all: look at vertices, indices, offsets, rasterization, not the fragment shader.
- `sweetmetal_fc_undef` only affects modules that still declare constants (unspecialized ones). Making it the default is a small, separate decision; ask the user.

1. **Why the CA quad draws nothing.** 18/19 are the only tests with `drawIndexedPrimitives` (index buffer = the same pool buffer at `IOFF`) and a vertex buffer at a non-zero offset (`VOFF=96`), `metaltest.m:905,912`. One build/boot that splits it: keep the CA pipeline and draw non-indexed at offset 0 in one sub-case, and test 08's simple pipeline indexed with offsets in another (or add a new test so 18/19 stay unchanged). Read `redwoodmetal.m` (in `metal-build/donor/userland/src/`) `indexBufferOffset` and the vertex-buffer offset path before building.
2. Recheck test 06 on that boot (one timeout so far).
3. Optional device confirmation of the fold (one log line, its own build): in `air_metal.c` `pipeline_function_constants`, log once per module how many constants it declares (expected 0 for every CA pipeline in backboardd). Do it only if item 1 points back at shaders.
4. Test 17 GPU times (optional), then the old list: rdar status bar, 828x1792, first-animation stall, freezes.

Rules: one change per build/boot; state the rung; a `TEST_LOG.md` row per boot; stop at the phase end and rewrite this file.
