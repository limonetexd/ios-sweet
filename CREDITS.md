# Credits and lineage

Branch `gpu-dana` merges two independent lines of the same port with full git history, so every
commit keeps its original author. Counts are from `git log` on 2026-11-23.

| Line | Repository | Work | Commit authors (as recorded) |
| --- | --- | --- | --- |
| Base port | [dipa-studio/ios-sweet](https://github.com/dipa-studio/ios-sweet) | XNU + iOS 16.7.16 to SpringBoard on `sweet`, CPU drawing; shared kernel patches 0001-0080 | dipa-studio, damjankakak3 |
| Hardware + native GPU | [DC28088/ios-sweet](https://github.com/DC28088/ios-sweet) | Native Adreno kernel driver (GMU, SQE/CP, SMMU, rings, fences), SweetNativeMetal, Wi-Fi, Bluetooth, speaker audio, haptics, battery, calls, sensors, sleep, page-flip and GPU present copy, USB SSH; iOS 26 research (`xnu/patches-12377`) | damjankakak3, Dan Cheriyan, DC28088, and the AI agents recorded as OpenCode and Codex |
| Fork of the above | [DanaTheScripterAlt/ios-sweet](https://github.com/DanaTheScripterAlt/ios-sweet) | Kernel 0143-0146 sampler dumps (`sweetsampledump=1`), 0249 per-process jetsam limits boot-arg | DanaTheScripter |
| Redwood Metal + measurement | [limonetexd/ios-sweet](https://github.com/limonetexd/ios-sweet), branch `gpu` | RedwoodMetal path, `metaltest` (24 on-device Metal tests), frame-rate research, render-scale + bilinear upscale, GPU timestamps, agent rules and ledgers | limonetexd, with DeepSeek, Big Pickle and Claude |

Shared donors: HakiOS userland (MIT, `userspace/native-metal/HAKIOS-LICENSE.txt`) is the AIR -> NIR -> freedreno
runtime behind both Metal paths; Mesa keeps its own licenses.

## What this branch takes from each line

- From `dana/main` at `fa8c53a` (= DC28088/main up to `af7e8ab` + Dana's 9 commits): the whole kernel series
  (`xnu/patches`, `xnu/patches-12377`), `shim/`, `userspace/`, workflows, tools, `NOTES.md`, `README.md` body.
  These are byte-identical to `dana/main`.
- From `gpu` at `084dad8` (tag `gpu-known-good-2026-11-23`): `userspace/metaltest/` (was `userland/metaltest/`),
  `CLAUDE.md`, `.claude/`, `docs/agent-progress/`, boot/flash helpers in `tools/`, and the branch record
  `docs/branches/gpu-redwood/` (its `NOTES.md` and `README.md`).
- Not in this tree, still built from branch `gpu`: redwood kernel patches 0081-0169, `userland/metal` patches 0001-0024,
  the redwood shim additions (`gpuprobe`, `plog`). Read them with `git show gpu-known-good-2026-11-23:<path>`.
- Not merged yet: DC28088/main after `af7e8ab` (26 commits, iOS 26 cellular/Wi-Fi work, xnu 2012-2015, wland 0009).

## License status

`dipa-studio/ios-sweet` is MIT (`LICENSE`, added 2026-10-22). DC28088/ios-sweet and its fork carry no license file
in any commit; their own additions are therefore not explicitly licensed. The repository owner has contacted the
authors about collaborating (2026-11-23); no explicit license has been given yet. Until then this branch credits them
here and in git history, and the gap is recorded in `docs/agent-progress/RESEARCH_LEDGER.md`. If an author objects,
their work comes out of this branch.
