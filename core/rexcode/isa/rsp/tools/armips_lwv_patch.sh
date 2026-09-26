#!/usr/bin/env bash
# rexcode  ·  Brendan Punsky (dotbmp@github), original author

# =============================================================================
# Build a patched armips with LWV restored
# =============================================================================
#
# Upstream armips (https://github.com/Kingcom/armips) removed the LWV
# vector load opcode because it's a known broken RSP instruction
# (op2=0x0A in LWC2 layout). Our rexcode ENCODING_TABLE includes LWV for
# completeness, so we need an assembler that can verify its bit pattern.
#
# This script clones armips, restores the LWV opcode entries (matching
# upstream pre-removal source), builds, and installs to ~/.local/bin/armips-lwv.
#
# Re-run only when armips needs rebuilding (e.g. compiler upgrade).
#
# Output:  ~/.local/bin/armips-lwv

set -euo pipefail

WORK=${WORK:-/tmp/armips-build}
rm -rf "$WORK"

echo "Cloning armips..."
git clone --depth 1 https://github.com/Kingcom/armips "$WORK"
cd "$WORK"
git submodule update --init --recursive

echo "Patching MipsOpcodes.cpp to restore LWV..."
sed -i '/{"lfv",.*"RtRo,(s)"/a\	{"lwv",		"RtRo,i7(s)",	MIPS_RSP_LWC2(0x0a),		MA_RSP,		MO_RSP_QWOFFSET },\n	{"lwv",		"RtRo,(s)",		MIPS_RSP_LWC2(0x0a),		MA_RSP,		MO_RSP_QWOFFSET },' Archs/MIPS/MipsOpcodes.cpp

echo "Building..."
mkdir -p build && cd build
cmake -DCMAKE_BUILD_TYPE=Release -DCMAKE_POLICY_VERSION_MINIMUM=3.5 .. >/dev/null
make -j"$(nproc)"

echo "Installing to ~/.local/bin/armips-lwv..."
mkdir -p "$HOME/.local/bin"
install -m755 armips "$HOME/.local/bin/armips-lwv"

echo "Done. Verify:"
"$HOME/.local/bin/armips-lwv" 2>&1 | head -1
