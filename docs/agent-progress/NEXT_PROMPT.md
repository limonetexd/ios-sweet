> State 2026-11-22 (records through the 0181s row of `TEST_LOG.md`; branch `gpu`, not pushed this session).
> - **Kernel now:** CI kernel 0165+0167+0168+0169 (`~/Developer/ios-sweet-work/kernel-0169/xnu-kernel`). Images: `shim/out/shim-boot-0175e.img` (best config, 750x1624, 1.5x filter) and `shim-boot-0177f.img` (= 0175e + `sweetmetal_fc_undef=1`).
> - **Phone root:** flashed 0181s: `libredwoodair` `6bbda66d...`, `metaltest` `4f901701...` (`5cf3dec`), metaltest job `--delay --runs 20` (20 passes each boot; `sweet-metaltest-job.py MOUNT --apply` puts it back to one pass). Rollback: `~/Developer/ios-sweet-work/root/rollback-0016`. After reading files off `work1.raw`, DETACH it (`hdiutil detach`), or the next flash fails with "Recurso ocupado".
> - Tools: `PATH=$HOME/Developer/ios-sweet-work/bin:$PATH`. Metal build tree `~/Developer/ios-sweet-work/metal-build`. `bash tools/metal-build.sh {ios,driver,test,payload}` (NOT `host`: it wipes the host tree). Flash+boot: `SWEET_SERIAL=f492cad9 tools/metal-flash-test.sh ~/Developer/ios-sweet-work/root/work1.raw IMAGE TAG 720` in the background (~18 min; standing yes for `work1.raw` test roots, `CLAUDE.md` Safety). RAM boot only: `SWEET_SERIAL=f492cad9 bash tools/sweet-boot-test.sh IMAGE TAG 720` (~11 min).
> - Specialize a function on the Mac: `tools/metal-host/fc-specialize-lib.m` (writes Apple bitcode: scratchpad only). QuartzCore `default.metallib`: `~/Developer/ios-sweet-work/metal/corpus/System/Library/Frameworks/QuartzCore.framework/`. Host tree (and `donor/`) has 0022 synced and 0024 applied; rebuild: `ninja -C host/build src/compiler/air/air2nir src/gallium/drivers/freedreno/ir3_compiler`.

# Next phase: pick with the user (metaltest 24/24 closed on one GPU stack)

Done 2026-11-22: 0180c (fresh RAM boot, no flash) 24/24; 0181s (`--runs 20`) 20/20 passes clean. 0180s: 06 "library from source" timed out at 10 s in all 20 passes; limit now 30 s; why it was slow there (and ~10 s in 0179s) is unknown. Open caveats: the harness binary differs between the cold and the stress boot, and no power-off cold start (needs the user's hands).

1. Ask the user which is next (one question): (a) the frame-rate / picture list, or (b) a RAM boot of the current root to put cold + stress on one exact commit.
2. Picture list (user, 0180c): the About page is broken (new since earlier boots); lines, missing icons/symbols/widgets, rdar status bar text, no wallpaper unchanged; the first run of each animation lags, then it is smooth.
3. Test 17 passes but reports GPU times 0. `sweetmetal_fc_undef` default: a small separate decision for the user.
4. Side fact: an unspecialized uber shader reaches ir3 with `nir_load_point_coord` (ir3: "Unhandled intrinsic"); matters only if a base function with constants is ever compiled.

Rules: one change per build/boot; state the rung; a `TEST_LOG.md` row per boot; stop at the phase end and rewrite this file.
