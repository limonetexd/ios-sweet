# SPEC 0017: completed handlers delivered by a completion thread (`sweetmetal_async=1`, default off)

## Why (found by reading the code, 2026-11-19)

The native frame is serial because of our driver, not CoreAnimation. At the end of `-[RedwoodMetalCommandBuffer commit]`
(`userland/src/redwoodmetal.m` ~5517) `-redwoodDeliverHandlers` finds CoreAnimation's completed handler and calls
`-waitUntilCompleted` on CA's render thread, so every commit blocks for the GPU (0164c/0165b: `waits` = `cbs`, ~16 ms).
The 0164c reading "CA calls -waitUntilCompleted itself" was a misattribution: the wait is our handler delivery.
`DC28088/ios-sweet` (same phone, same donor) measured `wait_until_completed=0` after moving completion to a thread
(their NOTES 2026-11-01, "async command completion"). 0016 only moved the wait to the next commit, and then into the
handler delivery of the same commit, so it could not help.

## Change (only `userland/src/redwoodmetal.m` in `~/Developer/ios-sweet-work/metal-build/donor`)

1. Boot-arg `sweetmetal_async=1` read the way the other `sweetmetal_*` keys are read (see `RW_COMMITWAIT_KEY`).
   Off: behaviour byte-for-byte as today. On: requires 0016's pipelined mode (`pipelined` true); otherwise ignored, said once.
2. One process-wide completion thread (pthread, QoS user-interactive), started lazily on the first async commit. A FIFO
   (mutex + condvar) of retained command buffers in commit order.
3. In `-commit`, when async is on and the buffer was submitted with a fence (`_fenceDue`):
   - Do NOT take/pay the previous buffer (`redwoodTakePending` / `redwoodPayFenceLocked`) and do NOT call
     `redwoodSetPending`. Deliver SCHEDULED handlers as today; enqueue `self` (retained) on the FIFO instead of delivering
     completed handlers. Return the slot (`redwoodReturnSlot`) exactly as today.
   - Buffers with no fence (empty, error, clear-only without submission) keep today's path.
4. The completion thread, per buffer in FIFO order: poll the fence with a zero timeout **under `rw_lib_lock()`** (hold
   the lock only for the poll), sleep 200 us between polls, give up after 2 s with the same "THE GPU DID NOT FINISH"
   failure path as today. Needs a library entry `rwa_fence_done(device, fence)` = `fence_finish(screen, NULL, fence, 0)`
   without releasing the fence (add it in `tools/mesa/air/air_metal.c` next to `rwa_wait_fence`, declare in
   `air_metal.h`, dlsym it like `rwa_wait_fence`; if missing, async is off and said once). When done: under the lock,
   `redwoodPayFenceLocked` (now returns at once, releases the fence and `_work`), unlock, then deliver completed handlers
   (`redwoodDeliver`: completion queue if set, else on this thread), mark the buffer completed, broadcast a per-buffer
   condition, release the buffer.
5. `-waitUntilCompleted` from any thread on an async-enqueued buffer: wait on that buffer's completion condition (do not
   pay the fence itself; never two payers of one fence). `-addCompletedHandler:` after commit on an enqueued, not yet
   completed buffer: append to the list the thread will deliver (under the FIFO mutex), not wait.
6. Bound: at most 3 enqueued buffers; a 4th `-commit` waits on the FIFO condvar (outside `rw_lib_lock`) before replaying.
7. Counters, printed with the existing passlog/stat line cadence when async is on: buffers completed, mean us from commit
   return to completion, mean polls per buffer, times commit waited for the bound.
8. Queue teardown / `-dealloc`: drain the queue's enqueued buffers (wait for completion) before freeing.

Lock order: `rw_lib_lock` before any FIFO mutex is never taken; the FIFO mutex is never held while taking `rw_lib_lock`
or delivering handlers.

## Done when

`tools/metal-build.sh all` builds; the host test `air_metal_test --draw-deferred dw.metallib` still passes. Deliver the
diff and a note of any spec item that did not fit the code. No device, no commit.
