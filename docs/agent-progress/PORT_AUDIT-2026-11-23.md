# Port audit: `gpu` kernel patches not in `gpu-dana` — 2026-11-23

Base of `gpu-dana` = their kernel. This lists each of our 73 kernel patches that are not in their series and
says whether their tree already covers it (checked by grep in a local tree with 0001-0250 applied; host only).

## GPU and display (58 patches): superseded, not ported

0082-0083, 0086-0101, 0103, 0109-0142, 0145-0146, 0158, 0160-0169: RedwoodGPU driver, shim GPU hand-off, GPU pool,
CPU framebuffer copy, presenter, render scale, bilinear scaler, fps monitor, pass/diag probes. Their NativeAdreno
driver + SweetFramebuffer (page flip 0181/0244/0245, GPU copy 0246, 800 MHz 0143) replace all of it.
Ideas worth carrying, as new patches or configuration:

| ours | what | on gpu-dana |
| --- | --- | --- |
| 0129, 0158, 0163, 0167-0169 | render below panel size + bilinear upscale (the config the user calls smooth) | configuration: `sweetfb_mode=3` + `kern.sweet_fb_gpucopy=2` (`UPSTREAM_MERGE` section 5) |
| 0165 | GPU start/end timestamps per submission (`gpu_ts=1`) | port candidate: their profiling times the CPU side only |
| 0082 (`sg_reboot_fastboot`) | auto return to fastboot | done: 0250 |

## Other subsystems (15 patches)

| ours | what | their tree | action |
| --- | --- | --- | --- |
| 0084 | AMFI policy answers dyld | `sweet_amfi.c` `.mpc_name = "AMFI"`, `sweet_gles_dyld_policy` | covered |
| 0106 | battery default real | their battery stack (0156-0162, 0227) | covered |
| 0144, 0156, 0159 | wall clock: RTC calendar, host epoch boot-arg | 0166 calendar from PMIC RTC (`SweetBattery.cpp`) | covered |
| 0147, 0154, 0155 | Wi-Fi pmem, RPMh command sender, BCM/ARC via /dev/pmem | 0138, 0141, 0149-0152 (`sweet_rpmh.c`, `PMEM_RPMH` in `sweet_pmem.c`) | covered |
| 0081 | USB network link-state events | none found; their USB CDC-ECM + SSH work without it | not needed unless a link problem shows |
| 0085 | iig headers for Xcode 16 | none; their CI builds with Xcode 16 | the CI run on `gpu-dana` answers it |
| 0107 | sandbox op 4: app extensions (`.appex`) get the mobile container path | **missing**: their op 4 returns ENOENT for every process (`sweet_amfi.c` ~300); our boot 0109b crash-looped speech-synthesizer extensions without it | **port** (their notes list extension crashes) |
| 0157 | AMFI boot-arg state 0x86 so ExtensionKit registers extension points | **missing**; their 0121 adds the AMFI IOService stand-in, not this answer | **port**, check together with 0107 |
| 0108 | `security.mac.amfi.developer_mode_status` sysctl + AMFI service | **missing** (no `developer_mode_status`) | port candidate, after 0107/0157 |
| 0143 | read-only thermal log (CPU/GPU/DDR TSENS every 5 s) | **missing** | port: needed to judge sustained 800 MHz runs |
| 0102 | `sweetfix=1` deletes the accessibility prefs once (rescue from a respring loop) | **missing** | port: small rescue tool |

Order when the device rung exists: 0143 (read-only), then 0107 + 0157 (one boot each), then 0108, 0102, 0165.
Each is kernel code: `opus-impl` from a spec, reviewed, one per build.
