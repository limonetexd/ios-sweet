> State 2026-11-22 (records through the 2026-11-22 rows of `TEST_LOG.md` / `RESEARCH_LEDGER.md`; branch `gpu`, not pushed this session).
> - **Kernel now:** CI kernel 0165+0167+0168+0169 (`~/Developer/ios-sweet-work/kernel-0169/xnu-kernel`). Images: `shim/out/shim-boot-0175e.img` (best config, 750x1624, 1.5x filter) and `shim-boot-0177f.img` (= 0175e + `sweetmetal_fc_undef=1`).
> - **Phone root:** flashed 0179s: `libredwoodair` `6bbda66d...`, `metaltest` `105052c4...` (24/24). Rollbacks: `~/Developer/ios-sweet-work/root/rollback-0016`. After reading files off `work1.raw`, DETACH it (`hdiutil detach`), or the next flash fails with "Recurso ocupado".
> - Tools: `PATH=$HOME/Developer/ios-sweet-work/bin:$PATH`. Metal build tree `~/Developer/ios-sweet-work/metal-build`. `bash tools/metal-build.sh {ios,driver,test,payload}` (NOT `host`: it wipes the host tree). The host tree now has 0022 synced in and 0024 (air2nir diagnostics) applied, and so does `donor/`. Rebuild: `ninja -C host/build src/compiler/air/air2nir src/gallium/drivers/freedreno/ir3_compiler`. Flash+boot: `SWEET_SERIAL=f492cad9 tools/metal-flash-test.sh ~/Developer/ios-sweet-work/root/work1.raw IMAGE TAG 720` in the background (~11 min; userdata flash needs the user's typed yes each session).
> - Specialize a function on the Mac: `tools/metal-host/fc-specialize-lib.m` (writes Apple bitcode: scratchpad only). QuartzCore `default.metallib`: `~/Developer/ios-sweet-work/metal/corpus/System/Library/Frameworks/QuartzCore.framework/`.

# Next phase: pick with the user (metaltest 24/24 on 0179s, one boot)

Done 2026-11-22: 18/19 pass with `fc_dest_index = 0` (0179s, `TEST_LOG.md`); the phone root now has `metaltest` `105052c4...`. "Passes all the metal tests" holds for one boot only; the definition of done wants a cold boot, a warm run and a stress run.

1. Ask the user which is next (one question): (a) repeat metaltest cold + warm + stress to close "24/24", or (b) the frame-rate / picture list.
2. `sweetmetal_fc_undef` default: a small separate decision for the user; it only matters for a base function with constants, which the phone did not hand out (0178s, 0179s: `fc=empty`/`fc=set`).
3. Test 17 passes but reports GPU times 0. Then the old list: rdar status bar, 828x1792, first-animation stall, freezes.
4. Side fact: an UNspecialized uber shader reaches ir3 with `nir_load_point_coord` (ir3: "Unhandled intrinsic") and keeps its constants in 216 B scratch. Only matters if a base function with constants is ever compiled.

Rules: one change per build/boot; state the rung; a `TEST_LOG.md` row per boot; stop at the phase end and rewrite this file.
