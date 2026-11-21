#!/bin/bash
# rea-decompile.sh BINARY ADDRESS-OR-SYMBOL [OUT]
# Ghidra decompile through the rea CLI, outside MCP. The MCP route stops each call at
# ~60 s, and Ghidra's first analysis of a big dylib (Metal, 3.5 MB: 97 s) takes longer.
# A cancelled call discards the analysis, so retrying never finishes; snapshots do not
# keep Ghidra's database. Static only; see docs/agent-progress/REA_SAFE_PROTOCOL.md.
# Run in the background for big binaries. Pseudocode goes to OUT (default BINARY.ADDR.txt).
set -euo pipefail
[ $# -ge 2 ] || { sed -n 2,7p "$0"; exit 2; }
export GHIDRA_INSTALL_DIR=${GHIDRA_INSTALL_DIR:-$HOME/Applications/ghidra_12.1.4_PUBLIC}
export JAVA_HOME=${JAVA_HOME:-/Library/Java/JavaVirtualMachines/temurin-21.jdk/Contents/Home}
out=${3:-$1.$2.txt}
rea decompile "$1" "$2" --provider ghidra > "$out.raw" 2>&1
python3 -I - "$out.raw" "$out" <<'PY'
import re, sys, json
t = open(sys.argv[1]).read()
m = re.search(r'^normalized_result: (".*")$', t, re.M)
open(sys.argv[2], "w").write(json.loads(m.group(1)) if m else t)
PY
rm -f "$out.raw"
echo "$out"
