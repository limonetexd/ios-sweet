# SPEC 0250 — `sweetgpu_reboot=SECONDS` on the gpu-dana kernel (back to fastboot after a test boot)

Branch `gpu-dana`, series `xnu/patches` 0001-0249 (DC28088/Dana). Patch file: `xnu/patches/0250-sweet-reboot-fastboot-timer.patch`.

## Why

Our test tools (`tools/sweet-boot-test.sh`, `tools/metal-flash-test.sh`) RAM-boot an image and wait for the phone to
come back to fastboot by itself. On branch `gpu` that is `sg_reboot_fastboot()` inside redwood patch 0082
(`git show gpu-known-good-2026-11-23:xnu/patches/0082-sweet-gpu-handoff.patch`, lines ~155-227), proven on our phone
on every boot since 0143r. The gpu-dana iOS 16 kernel has no equivalent. Their iOS 26 series has the same mechanism
in `sweet_reboot.c` (`dc28088/main:xnu/patches-12377/2001-sweet-ios16-drivers.patch`, around line 15981):
PM6150 PON spare 0x88f + IMEM restart reason + PSCI SYSTEM_RESET, no PS_HOLD.

## Behaviour

- Boot-arg `sweetgpu_reboot=N` (same name as on `gpu`; `tools/sweet-boot-test.sh` greps for it). Absent or N <= 20:
  nothing is created or written (default off, no behaviour change).
- N > 20: one kernel thread sleeps N seconds after it starts, prints `SWEET REBOOT: back to fastboot in N s` at start,
  then:
  1. PMIC sid 0, register 0x088f (PON_SOFT_RB_SPARE) <- `0x02 << 1` (fastboot reason; same value as 0082).
  2. IMEM restart reason: `ml_io_map(0x146aa65c & ~0xfff, 0x1000)`, write 32-bit `0x77665500` at offset `0x65c`.
  3. Print `SWEET REBOOT: rebooting to fastboot (pon rc X)`, sleep 12 s so the persistent console ring is flushed
     (shared patch 0069 flushes every 10 s), then PSCI SYSTEM_RESET (`smc #0`, x0 = 0x84000009), then `wfe` forever.
  If the PON write fails, still do steps 2-3 (log the rc): the IMEM reason alone may suffice; never retry in a loop.

## Ownership (use their layer, do not copy ours)

- PMIC write goes through their `sweet_spmi_write()` (`bsd/dev/sweet_spmi.c`). It has an allow-list of charger
  registers; add exactly `0x088f` with a comment naming 0250 and the reason. Do not widen it otherwise, do not
  remove the EE-owner or poisoned-APID checks. Make sure SPMI is initialised when the thread fires (read
  `sweet_spmi_init()`; call it if that is safe and idempotent, otherwise explain what you did).
- New file `bsd/dev/sweet_reboot_timer.c` (+ `bsd/conf/files` entry like the other `bsd/dev/sweet_*.c`). Start it from
  the same place the other sweet threads start (`bsd/dev/sweet_ufs.c` near line 670, e.g. next to
  `sweet_sample_start()`), guarded by `ARM64_BOARD_CONFIG_SWEET` like its neighbours.

## Constraints

- No other register, address or command. No GPU code. Nothing on by default.
- Kernel style of the neighbouring sweet files (tabs, printf prefix `SWEET REBOOT:`).

## Proof

- `tools/xnu-tree.sh check` (with `XNU_TREE` = the scratch tree) on the patch: applies cleanly after 0249.
- Compile is CI's job (`xnu.yml`, dispatch on `gpu-dana`). Device: RAM boot with `sweetgpu_reboot=420` returns to
  fastboot by itself (rung: reversible, RAM only).
