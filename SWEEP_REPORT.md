# Sweep report — 2026-11-19

Report only. I edited, moved and deleted nothing. Repo HEAD `72f84fa` (branch `gpu`, `origin/gpu` = `df915ab`).
An independent read-only checker (sonnet) checked each claim from a neutral list. I also checked rows marked ✔ myself.

## 1. Outdated

### Whole file: archive candidate

| File | Claim | Evidence it is false | Evidence the reason is gone | Checker | Proposed action |
| --- | --- | --- | --- | --- | --- |
| `SUBAGENTS.md` (repo root, **untracked**) | It is the current subagent set ("Three bounded, read-only helpers"; `reviewer` on sonnet) | It has no `opus-impl` and no routing table. `reviewer` is `model: opus` in `.claude/agents/reviewer.md:5` and in `docs/agent-progress/SUBAGENTS.md` ✔ | It is replaced by the tracked `docs/agent-progress/SUBAGENTS.md` (2026-11-10), which is a superset and is the file `CLAUDE.md` points to ✔ | FALSE, stale | Archive the whole file. The file is untracked, so the archive would hold its only copy. That is a move, not a delete, but approve it explicitly. |

### Stale sections inside live files (edit by hand; do not archive)

| File | Stale claim | Now | Checker |
| --- | --- | --- | --- |
| `docs/agent-progress/PROJECT_STATE.md` (Revision line) | "Local only, nothing pushed." | `origin/gpu` exists at `df915ab`. Pushing for CI is approved (memory `build-on-mac-not-github`) ✔ | FALSE |
| same (Revision line) | "Untracked and left alone: `.claude/`, `CLAUDE.md`, `SUBAGENTS.md`, kickoff/protocol/subagent files" | All are tracked since `00ba8e7`, except the root `SUBAGENTS.md` ✔ | FALSE |
| same (Environment gaps) | "Missing here: `aarch64-linux-gnu-gcc`, `mkbootimg`, … `ipsw`" | The first two are in `~/Developer/ios-sweet-work/bin`. `ipsw` is at `/usr/local/bin`. Still missing: `qemu-system-aarch64`, `img2simg`, `~/cxnu` ✔ | FALSE (partly) |
| same (Environment gaps) | "HEAD CI run 42508457273 was still in progress" | `completed / success` ✔ | FALSE |
| same (task 4) | "Kernel 0162 … pushed, not booted" | Booted as `0169pf` and `0169sf` (NEXT_PROMPT Results) | FALSE |
| `docs/agent-progress/PROJECT_STATE.md` + `NEXT_PROMPT.md` as a whole | They describe the latest work | Both last changed in `d4cb205` (2026-11-14 12:51). About 12 commits followed: 0163 strip fix, Metal 0016 v1/v2, xnu 0164 `gpu_slack`, boots 0165a/b ✔ | TRUE that they are stale |
| `docs/agent-progress/NEXT_PROMPT.md` Phase A | Two RAM boots of 0162 are the next work | Done. The Results section is filled in (0169pf, 0169sf) ✔ | FALSE |
| same, Phase B item 2 | "Find why 750x1624 shows only a strip" | `144ba95`: "the 750x1624 strip is a destination bug", patch 0163 | FALSE (resolved) |
| same, Phase B item 3 | "Commit returns before the GPU wait": still to do | Done in `537498d`, `615876f` and `411469d`. Closed as neutral (NOTES.md:5-8) | FALSE |
| same, Phase B item 4 | "Over-fetch fix in the kernel": still to do | `xnu/patches/0164-sweet-gpu-slack.patch` is a workaround. 0165b ran GMEM with 0 faults in one boot | PARTLY |
| same, header | "Best result: 0168z60 = 750x1624 …" | The file's own CORRECTION line just above it says that the 750x1624 numbers are invalid ✔ | (self-contradiction) |
| `NOTES.md:3` heading | "xnu 0164 built, waiting on CI" | CI 43622291051 succeeded. The 0165a/b rows are in `TEST_LOG.md:538-539` ✔ | FALSE |
| memory `MEMORY.md` | The index lists every memory | `agent-may-boot-the-phone.md` is missing from the index ✔ | FALSE |

Suggested fix: rewrite `PROJECT_STATE.md` and `NEXT_PROMPT.md` from the NOTES.md top section and TEST_LOG 0165a/b, and add the missing line to `MEMORY.md`.

## 2. Conflicts (you decide which side is right)

| Note | Other side | Detail |
| --- | --- | --- |
| `CLAUDE.md:7`: "public upstream `DC28088/ios-sweet`, itself a fork of `dipa-studio/ios-sweet`" | `git remote -v` → `limonetexd/ios-sweet-gpu`. `README.md:7` says the repo is a fork of `dipa-studio/ios-sweet` and does not mention DC28088 | `PROJECT_STATE.md` also says "`CLAUDE.md` names the wrong upstream". The DC28088 branch does exist as a Wi-Fi source (`notes/agents/INDEX.md`). |
| memory `agent-owns-fastboot-return`: "each `fastboot boot` still needs the go-ahead" | memory `agent-may-boot-the-phone` (2026-11-13, later): the agent runs RAM-only boots itself | The later memory looks like it supersedes the earlier one for RAM boots. Flashing still needs a typed yes in both. |
| `AGENTS.md`: read `NOTES.md` first and keep the handoff there | `CLAUDE.md`: state files in `docs/agent-progress/`, handoff in `NEXT_PROMPT.md` | Both are kept up to date in practice. NOTES.md is currently the fresher of the two, so there are two handoff systems that drift apart. |
| `notes/deepseek/ROADMAP-STATUS.md`: agents use `opencode/deepseek-*` free models | `CLAUDE.md` Subagents: haiku/sonnet/opus routing | The first applies to the DeepSeek/opencode agent. `AGENTS.md` says the user switches agents, so it is not shown to be dead. |
| `NEXT_PROMPT.md`: "Always boot with `sweetmetal_fddebug=sysmem`" | 0165b booted without it, using `gpu_slack=1` (default off), with 0 faults in one boot | The warning still stands for default builds. Revisit after more `gpu_slack` boots. |

## 3. Kept / unverifiable

- `notes/agents/INDEX.md` "Blocker is `launchd`": false today (the home screen was reached 2026-11-11), but this is a dated 2026-11-03 forensic snapshot and live ledgers still cite the notes it indexes. Keep. An optional "historical" banner could be added by hand.
- `notes/agents/*.md`, `notes/deepseek/*`: dated historical work notes and roadmaps, still referenced by `NOTES.md`, `RESEARCH_LEDGER.md` and `FPS_INVESTIGATION.md`. Keep.
- `PROJECT_STATE.md` warning on `tools/xnu-tree.sh:44-45` (`reset --hard`, `clean -fdx`): the code is still there. Keep.
- memory `first-boot-needs-30-min`: the `sweetsample` patch is `xnu/patches/0054-sweet-process-sampler.patch` and the migrate step is at `tools/sweet-root-fixes.py:118`. Keep.
- memory `build-on-mac-not-github`: the origin and workflow are correct. "No kernel built on this Mac" is unverifiable. The slug says the opposite of the content; renaming it is optional.
- `CLAUDE.md`, `~/.claude/CLAUDE.md`, `.claude/agents/*`, `docs/agent-progress/{DECISIONS,GPU_DECISION,FEATURE_MATRIX,RESEARCH_LEDGER,TEST_LOG,REA_SAFE_PROTOCOL,SUBAGENTS}.md`: no claim found false. Keep.
- `docs/QEMU_TESTING.md`: `qemu-system-aarch64` is not installed here, but the doc is not shown to be wrong. Unverifiable.
- `docs/agent-progress/FRAME_RATE_RESEARCH.md`, `METAL_FINDINGS.md`, `HAKIOS_SEARCH_DEEPSEEK.md`, `SPEC-0016-commit-no-wait.md`, `00_KICKOFF.md`: research and specs, not checked claim by claim. Keep.

## Outcome (2026-11-19, approved by the user)

- Archived the root `SUBAGENTS.md` (the manifest is in the archive folder). Guard hook in `.claude/settings.json`; a test read returned exit 2.
- Fixed the stale lines in `PROJECT_STATE.md` and the `NOTES.md:3` heading, and rewrote `NEXT_PROMPT.md`.
- Settled the conflicts: `CLAUDE.md:7` lineage (`origin` = `limonetexd/ios-sweet-gpu`; `DC28088/ios-sweet` is a fork of `dipa-studio/ios-sweet`, checked on GitHub). `AGENTS.md` now points to the state files and keeps `NOTES.md` as the log. The boot memories are reconciled and the memory index is complete.
- Every file in `notes/deepseek/` and `notes/agents/INDEX.md` now starts with a historical banner that points to the current state files. The opencode model budget is kept.
