#!/usr/bin/env bash
# rexcode  ·  Brendan Punsky (dotbmp@github), original author

# =============================================================================
# N64 RSP verification harness — assembles via `armips`, compares bytes
# =============================================================================
#
# Strategy: the dumper emits an armips .asm file with one canonical
# instruction per ENCODING_TABLE entry. We assemble it, then walk the
# resulting binary 4 bytes at a time and compare to our expected hex.
#
# Caveats (built into the dumper, not bugs):
#   - LWV (vector wide-load) is commented out — armips 0.11 doesn't recognise it.
#   - VMOV/VRCP/VRCPL/VRCPH/VRSQ/VRSQL/VRSQH require `[N]` element brackets
#     in armips; `[0]` maps to encoded value 8, so the expected bytes for
#     those entries include the (8<<21)|(8<<11) offset.
#
# Install:  pacman -S armips    |    yay -S armips
#
# Usage:    bash tools/verify_against_armips.sh /tmp/rexcode_rsp.hex

set -euo pipefail

HEX_FILE="${1:-/tmp/rexcode_rsp.hex}"
ASM_FILE="${HEX_FILE%.hex}.asm"
META_FILE="${HEX_FILE%.hex}_meta.txt"
BIN_FILE="${HEX_FILE%.hex}.bin"

# Prefer the locally-patched armips with LWV restored
# (upstream removed LWV — see tools/armips_lwv_patch.sh to rebuild).
if [ -x "$HOME/.local/bin/armips-lwv" ]; then
	ARMIPS_BIN="$HOME/.local/bin/armips-lwv"
elif command -v armips >/dev/null 2>&1; then
	ARMIPS_BIN="armips"
else
	echo "armips not found — install with: yay -S armips"
	exit 0
fi
echo "Using: $ARMIPS_BIN"
for f in "$HEX_FILE" "$ASM_FILE" "$META_FILE"; do
	if [ ! -f "$f" ]; then
		echo "Manifest missing: $f"
		echo "Run first: cd isa/rsp && odin run tools/dump_verify_input.odin -file"
		exit 1
	fi
done

rm -f "$BIN_FILE"

# armips reads paths relative to its CWD; switch to the .asm file's dir
ASM_DIR=$(dirname "$ASM_FILE")
ASM_BASE=$(basename "$ASM_FILE")
echo "Assembling $ASM_FILE with $ARMIPS_BIN..."
(cd "$ASM_DIR" && "$ARMIPS_BIN" "$ASM_BASE") 2>&1 | tail -20

if [ ! -f "$BIN_FILE" ]; then
	echo "armips did not produce $BIN_FILE — see errors above"
	exit 1
fi

# Convert expected hex (one entry per line) → "NN NN NN NN" rows.
awk -F',' '{
	out = ""
	for (i = 1; i <= NF; i++) {
		v = $i
		sub(/^0x/, "", v)
		out = (i==1) ? toupper(v) : out " " toupper(v)
	}
	print out
}' "$HEX_FILE" > "$HEX_FILE.expected"

# Convert binary → 4-byte rows in the same hex format.
xxd -c 4 -p "$BIN_FILE" | awk '
	{ up = toupper($0)
	  printf "%s %s %s %s\n", substr(up,1,2), substr(up,3,2),
							  substr(up,5,2), substr(up,7,2) }
' > "$HEX_FILE.got"

n_exp=$(wc -l < "$HEX_FILE.expected")
n_got=$(wc -l < "$HEX_FILE.got")

# Identify skipped entries: those whose asm lines start with "; " (commented).
# Their meta-file rows are still present, but they consume zero output bytes.
# Build a list of which meta rows are "skipped" via the asm file.
awk 'BEGIN { in_body=0 }
	/^\.org/ { in_body=1; next }
	!in_body { next }
	/^[[:space:]]*$/ { next }
	/^\./ { next }              # other directives
	{ line_count++
	  if (substr($0,1,2) == "; ") print line_count
	}' "$ASM_FILE" > "$HEX_FILE.skipped"

n_skipped=$(wc -l < "$HEX_FILE.skipped")

# Compare row-by-row, accounting for skipped entries (which shift the
# expected→got alignment). Walk both files and skip the "; " entries.
python3 - "$HEX_FILE.expected" "$HEX_FILE.got" "$HEX_FILE.skipped" "$META_FILE" << 'PYEOF'
import sys
exp_path, got_path, skip_path, meta_path = sys.argv[1:]
with open(exp_path) as f: exp = f.read().splitlines()
with open(got_path) as f: got = f.read().splitlines()
with open(skip_path) as f: skipped_set = set(int(l) for l in f.read().splitlines() if l)
with open(meta_path) as f: meta = f.read().splitlines()

total = len(exp)
got_idx = 0
ok = 0; mis = 0; skipped = 0
mismatches = []
for i in range(total):
	one_based = i + 1
	mn = meta[i].split('\t')[0]
	if one_based in skipped_set:
		skipped += 1
		continue
	if got_idx >= len(got):
		mis += 1
		mismatches.append((mn, exp[i], "<missing>"))
		continue
	e = exp[i]; g = got[got_idx]
	got_idx += 1
	if e == g:
		ok += 1
	else:
		mis += 1
		mismatches.append((mn, e, g))

print("="*68)
print(f"  TOTAL entries:  {total}")
print(f"  OK matches:     {ok}")
print(f"  MISMATCHES:     {mis}")
print(f"  SKIPPED:        {skipped}  (armips can't represent)")
print("="*68)

if mismatches:
	print("First mismatches:")
	for mn, e, g in mismatches[:20]:
		print(f"  {mn:8s}  expected={e}   got={g}")
PYEOF
