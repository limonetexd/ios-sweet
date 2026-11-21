> State 2026-11-21 late night (records through the host `--draw-ca` rows of `TEST_LOG.md` / `RESEARCH_LEDGER.md`; branch `gpu`, not pushed this session).
> - **Kernel now:** CI kernel 0165+0167+0168+0169 (`~/Developer/ios-sweet-work/kernel-0169/xnu-kernel`). Images: `shim/out/shim-boot-0175e.img` (best config, 750x1624, 1.5x filter) and `shim-boot-0177f.img` (= 0175e + `sweetmetal_fc_undef=1`).
> - **Phone root:** `work1.raw` + metal 0017-0022 payload (flashed 0177f). Rollbacks: `~/Developer/ios-sweet-work/root/rollback-0016`. After reading files off `work1.raw`, DETACH it (`hdiutil detach`), or the next flash fails with "Recurso ocupado". (Detached at the end of this session.)
> - **metaltest 18/21 on 0177f:** 18/19 draw NOTHING (clear colour 404040ff everywhere); 06 "library from source" timed out once; 17 GPU times 0.
> - Tools: `PATH=$HOME/Developer/ios-sweet-work/bin:$PATH`. Metal build tree is `~/Developer/ios-sweet-work/metal-build` (NOT `ios-sweet-work/metal`). `bash tools/metal-build.sh {ios,driver,test,payload}` (NOT `host`: it wipes the host tree; rebuild the host test with `ninja -C host/build src/gallium/drivers/freedreno/air_metal_test`, run with `RWA_SOFTWARE=1 DYLD_LIBRARY_PATH=host/build/src/gallium/drivers/freedreno`). Flash+boot: `SWEET_SERIAL=f492cad9 nohup tools/metal-flash-test.sh ~/Developer/ios-sweet-work/root/work1.raw IMAGE TAG 720 & disown` (~30 min; userdata flash needs the user's typed yes each session).
> - Patch 0023 (`air_metal_test --draw-ca`, host test only) is applied to `metal-build/donor` and the host tree. The host tree still lacks 0022 (every function constant defined 0).
> - QuartzCore `default.metallib`: copy it from a read-only attach of `work1.raw` (`hdiutil attach -readonly -nobrowse -imagekey diskimage-class=CRawDiskImage`), then detach. Never into the repo.

# Next phase: metaltest 18/19 draw nothing (user asked: "make it pass all of the metal tests")

Settled 2026-11-21 (ledger rows "function constants", "specialization folds", "indexed draw ... covers the target on softpipe"):
- Function constants are not the missing piece (Apple's specializer folds them).
- **Host, softpipe:** the library's indexed draw from one pool buffer at CA's offsets (96/288) and CA's 48-byte layout covers 4096/4096 in all four `--draw-ca` cases with `std_vert0_lpf` + `fs_color`. The index/offset arithmetic is not the fault, at least at coverage level on the host.
- Softpipe cannot run QuartzCore's `fixed_vert_*_spc` or `fixed_frag_lph_cph` (`f2f16`; 8-bit scratch). Static: all three carry scratch (`air_to_nir`'s `path_conditional` bools: VS 96 bytes, FS 216), `fixed_vert_lph_spc` also an f16 colour varying; no discard. The passing metaltest pipelines carry no scratch.

1. **Device split, one build/boot (test binary only, 18/19 unchanged; userdata flash = typed yes).** New metaltest tests, each the 18/19 data and indexed draw, fragment `fs_color` with buffer 0 = opaque magenta: 22 `std_vert0_lpf` (no scratch; the device twin of host case a), 23 `fixed_vert_lph_spc` (scratch + f16 varying), 24 `fixed_vert_lpf_spc` (scratch, float varying). Read: 22 grey = the device index/offset path after all; 22 draws and 23/24 grey = CA vertex shader on ir3 (scratch if both, f16 varying if only 23). All three draw = the fragment side (`fixed_frag_lph_cph`, 216 bytes scratch) is next. If the device refuses `fs_color`'s `stage_in` against the CA vertex outputs, add a fragment with no `stage_in` (and keep `kShaderSource` in step, test 06).
2. Recheck test 06 on that boot (one timeout so far).
3. If scratch is implicated: read how ir3 private memory is set up on our path (freedreno fd6 pvtmem, redwood-drm BO) before changing anything; and whether `air_to_nir` should keep those bools in SSA (`nir_lower_vars_to_ssa` / `nir_lower_reg_intrinsics_to_ssa`) instead of scratch.
4. `sweetmetal_fc_undef` default: a small, separate decision; ask the user. Then test 17 GPU times, then the old list: rdar status bar, 828x1792, first-animation stall, freezes.

Rules: one change per build/boot; state the rung; a `TEST_LOG.md` row per boot; stop at the phase end and rewrite this file.
