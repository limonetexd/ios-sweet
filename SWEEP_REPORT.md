# Sweep report, 2026-11-21

Scope: agent-facing notes changed or contradicted since the 2026-11-19 sweep (`7495563`). Report only, nothing
edited. Checker: an independent read-only agent given neutral claims; its evidence was spot-checked (ids 1, 2, 4).

## 1. Outdated

**No whole file is outdated.** Every file below is live; only sections are stale. Proposed action for all: edit
the section by hand (or let the next session do it), archive nothing.

| # | File:line | Claim | Evidence it is false now | Reason gone | Checker |
| --- | --- | --- | --- | --- | --- |
| 1 | `docs/agent-progress/PROJECT_STATE.md:16` | "`check-patch.py` 144/144" | 151 patches in `xnu/patches/`, `check-patch.py` exits 0 on all | snapshot count from 2026-11-08 | FALSE |
| 2 | `docs/agent-progress/PROJECT_STATE.md:21` | "Missing: ... `~/cxnu`" | literally true, but the kernel patch tree is `~/Developer/ios-sweet-work/cxnu` (HEAD `0166-...`) | tree moved, not missing | partly FALSE |
| 3 | `docs/agent-progress/PROJECT_STATE.md:33-43` (Handoff) | "Next: user starts M1"; Phase 0/1 handoff | `NEXT_PROMPT.md` has no M1; it is the 750x1624 phase | Phase 0/1 closed | FALSE |
| 4 | `docs/agent-progress/FEATURE_MATRIX.md:13` | "144/144 `.patch` files" | 151, all pass | count snapshot | FALSE |
| 5 | `docs/agent-progress/FEATURE_MATRIX.md:15` | "Local builds on this Mac: blocked; gcc, mkbootimg, ipsw missing" | `aarch64-linux-gnu-gcc`, `mkbootimg` in `ios-sweet-work/bin`, `ipsw` in `/usr/local/bin`; shim images and Metal build locally every boot this week | tools installed | mostly FALSE (QEMU, `img2simg` still missing) |
| 6 | `docs/agent-progress/GPU_DECISION.md:6-7` ("Current path") | "There is no Metal anywhere in this tree" | Metal path in `userland/metal/0001-0020`, `tools/metal-build.sh`; primary since 2026-11-08 | memo dated 2026-11-08 (`c5d9aca`) | FALSE |
| 7 | `docs/agent-progress/GPU_DECISION.md` Evidence table | "GPU execution per frame: no valid number" | xnu 0165 `gpu_ts=1`: 7.17 ms a submission, busy 37-63 % (`TEST_LOG.md` 0171t), 1.81 ms at 750x1624 (0174s) | measured 2026-11-20 | FALSE |
| 8 | `NOTES.md:3` (top heading) | "the GPU is the wall at native" | GPU busy 37-63 % at native (0171t, 0173d); the pacing model in `NEXT_PROMPT.md` replaces it; NOTES top has no entry for 2026-11-19..21 although `AGENTS.md` asks for one per milestone | superseded by measurement | PARTLY TRUE |

## 2. Conflicts (decide which side is right)

- **Memory `first-boot-needs-30-min`** ("After any userdata flash the first boot needs 30+ min; short test boots cannot
  reach it") vs this week's boots: after `tools/metal-flash-test.sh work1.raw ...` flashes, 300-420 s boots reached
  thousands of swaps (0171a 27.4/s, 0172p, 0172m, 0173d). Likely both true: `work1.raw` is an already-seeded root, the
  memory's cause (lsd seeding an unseeded root) applies to a fresh root. Suggested wording for you to choose: "after
  flashing a *fresh, unseeded* root". No deletion proposed.

## 3. Kept / unverifiable

- `PROJECT_STATE.md:42` warning "`tools/xnu-tree.sh:44-45` runs `git reset --hard` / `clean -fdx` in `XNU_TREE`
  (default `~/cxnu`)": TRUE (`xnu-tree.sh:19,44-45`); guard still needed. Keep.
- Memory `agent-may-boot-the-phone` (flashing needs a typed confirmation per session): TRUE, `CLAUDE.md` Safety. Keep.
- Memory `build-on-mac-not-github` (`gh workflow run xnu.yml --ref gpu`): TRUE, `xnu.yml` pushes trigger on `main`
  only. "No kernel ever built on this Mac": unverifiable, kept.
- Memory `agent-owns-fastboot-return`: consistent with every boot this week. Keep.
- `CLAUDE.md` subagent list / `SUBAGENTS.md` / `.claude/agents/`: TRUE. Keep.
- `notes/deepseek/*`, `notes/agents/*`: carry the historical banner from the 2026-11-19 sweep; not re-checked. Keep.
- `SPEC-0016`, `SPEC-0017`, `SPEC-0165`, `UPSTREAM_SURVEY`, `SMOOTH_PORTS`: dated records of this week; true as records. Keep.

Archive candidates: none. Items 1-8 are hand edits in live files.
