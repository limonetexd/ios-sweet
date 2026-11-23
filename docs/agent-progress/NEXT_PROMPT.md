# Next phase: first boot of `gpu-dana` on our phone (branch `gpu-dana`, repo `limonetexd/ios-sweet`)

State 2026-11-23: `gpu-dana` = Dana's tree + `gpu` history (`CREDITS.md`, `UPSTREAM_MERGE-2026-11-23.md`).
Kernel 0250 (`sweetgpu_reboot=N`, back to fastboot) written and reviewed; CI results in `TEST_LOG.md` (last rows).
Their native Metal bundles and `metaltest` built on the Mac: `~/Developer/ios-sweet-work/gpu-dana/userspace-5ff04f3/`.
Phone: in fastboot, root = 0181s (redwood); rollback `~/Developer/ios-sweet-work/root/rollback-0016`.

1. Ask the user (one question): did DC28088/Dana send their `scripts/package-*.py` or the full cmdline of image
   2482? If not, rebuild it: our base args (`git show gpu:tools/sweet-gpu-image.sh`, line `B=`) + the args their
   kernel reads (108 `sweet*` boot-args; defaults in `bsd/dev/sweet_*.c`, `iokit/Kernel/arm/Sweet*.cpp`) +
   2482's additions (`sweetpanelvci=0 sweetmotion=0xbf sweetfbflip=1 sweetfbgpu=1`). Write it to a file, cite each arg.
2. Image: their `tools/mkadt.py --highmem` + `tools/adt-*.py` + `tools/sweet-adreno-firmware.py` (GPU fw in
   `research/gpu-sweet/fw/`) + `tools/mkpayload.py` + `shim/build.sh`; add `sweetgpu_reboot=420`; check it is in the
   payload (`tools/payload-cmdline.py`).
3. Rung 1 (reversible, RAM only, root untouched if possible): boot their kernel on our root; expect a console and an
   automatic return to fastboot (validates 0250 on hardware). `tools/sweet-boot-test.sh IMAGE TAG 720`.
4. Rung 2 (snapshot-first, standing yes for `work1.raw` roots): copy of `work1.raw` + their bundles (install path:
   their `tools/sweet-install-metal2.sh`, `/System/Library/Extensions/SweetMetal2.bundle`) + `metaltest`; flash
   with `tools/metal-flash-test.sh`; then `metaltest --runs 20`.
5. Then the low-res trick: `sweetfb_mode=3` + `kern.sweet_fb_gpucopy=2` (configuration only; see section 5 of
   `UPSTREAM_MERGE-2026-11-23.md`).

Rules: one change per boot; state the rung; a `TEST_LOG.md` row per boot; stop at the phase end and rewrite this file.
