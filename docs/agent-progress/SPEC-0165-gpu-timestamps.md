# SPEC 0165: true GPU execution time from GPU timestamps (`gpu_ts=1`, default off)

## Why

`RedwoodGPU: the GPU worked N us` is ring-write to first-poll-that-sees-the-fence: it includes
queueing behind earlier submissions and poll delay (outliers of 105 ms in 0165b). It cannot say
whether the GPU is saturated or what one submission costs on the GPU. Every GPU-side decision
(tiling, flush points, blended draws, R3) needs that number.

## Packets (all from mesa 25.0.7 / Linux msm, verified in `src/freedreno/registers/adreno/*.xml`)

- `CP_REG_TO_MEM` = opcode 0x3e, 3 payload dwords: `0x980 | (2 << 18) | (1u << 30)` (REG =
  `CP_ALWAYS_ON_COUNTER` 0x980, CNT 2, 64B), dest lo, dest hi. This is Linux a6xx `get_stats_counter`.
- `CP_EVENT_WRITE` = 0x46, 4 payload dwords: `22 | (1u << 30)` (RB_DONE_TS = 22, TIMESTAMP bit 30),
  dest lo, dest hi, 0. This is mesa `fd6_record_ts` on A6XX: writes the 64-bit always-on counter at
  end of pipe.
- Counter: 19.2 MHz (mesa `ticks_to_ns`); the patch must also measure it, see below.

## Change (files: `iokit/Kernel/arm/SweetAdreno.cpp`, `iokit/Kernel/arm/RedwoodGPU.cpp` in `~/Developer/ios-sweet-work/cxnu`)

1. `TUNABLE(uint32_t, gGPUTs, "gpu_ts", 0)` in SweetAdreno.cpp. With 0, the emitted ring words and
   `need` must be byte-identical to today.
2. Timestamp slots live in the fence page: `SHARED_FENCE + 0x100`, 64 slots (`TIMED`) of 16 bytes
   (start u64, end u64); GPU address `GVA_FENCE + 0x100 + 16 * (fence % TIMED)` (+8 for end). Zero
   them where `*fence_word() = 0` is done at init.
3. `redwood_gpu_submit`: compute the fence number (seqno increment) before the IB loop instead of
   after; with `gGPUTs`, emit CP_REG_TO_MEM (start) before the IBs and CP_EVENT_WRITE RB_DONE_TS
   (end) after the IBs and before the existing CACHE_FLUSH_TS; `need` grows by 4 + 5. Before
   emitting, write 0 to both slot words (CPU) so a stale value is detectable.
4. `note_done`: for each newly done fence f (only when `gGPUTs`), read start/end (two volatile 32-bit
   reads each, or a 64-bit volatile read). Skip a slot if start == 0, end == 0, end < start, or if
   more than `TIMED - 8` fences completed since the last call (slots may be reused). Accumulate:
   - `ts_exec` += end - start (CP reached the submission to end of pipe),
   - `ts_busy` += end - max(start, prev_end) (GPU busy, excluding queueing behind the previous one),
   - `ts_n`++, `ts_first` = first start in the window, `ts_last` = last end, `prev_end` = end.
5. New `void redwood_gpu_ts(uint64_t *busy_ticks, uint64_t *exec_ticks, uint64_t *span_ticks,
   uint32_t *n)` returns and resets the window (span = ts_last - ts_first; keep prev_end).
   Also `uint64_t redwood_gpu_now_ticks(void)`: CPU read of 0x980 (lo) and 0x981 (hi), hi-lo-hi
   retry, via `gpu_rd`. Declare both where `redwood_gpu_worked` is declared in RedwoodGPU.cpp.
6. RedwoodGPU.cpp, next to the `the GPU worked` IOLog, only when `gpu_ts` is on (read the same boot-arg
   with PE_parse_boot_argn or export the tunable): one line
   `RedwoodGPU: GPU timestamps (0165): busy %llu us of %llu us (%u %%), exec %llu us mean over %u submissions, counter %llu ticks in %llu us`
   where the last pair is `redwood_gpu_now_ticks()` delta and mach time delta since the previous line
   (gives the real counter rate; convert ticks to us with 19.2 MHz for the first three numbers).
   Once at the first submission with `gpu_ts` on: `RedwoodGPU: GPU timestamps on (0165)`.
7. No other behaviour change. No new allocations, no new mappings.

## Done when

The tree compiles in CI (`xnu` workflow). Deliver: the diff, and a one-paragraph note of anything in
the spec that did not match the code. Do not commit, do not touch the device.
