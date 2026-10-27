#!/usr/bin/env bash
# rexcode  ·  Brendan Punsky (dotbmp@github), original author

# =============================================================================
# W65C816 verification harness — assembles via ca65, compares bytes
# =============================================================================
#
# Strategy: the dumper emits a ca65 .s file with one canonical asm line per
# ENCODING_TABLE entry. We assemble it with --listing, then for every entry
# parse the listing's per-line bytes and compare to the table's hex bytes.
#
# This catches every wrong encoding: bad opcode, swapped operand bytes,
# wrong length, mistakenly applied/missing .a8/.a16/.i8/.i16 width.
#
# Install:  pacman -S cc65   |   apt install cc65   |   brew install cc65
#
# Usage:    bash tools/verify_against_ca65.sh /tmp/rexcode_mos65816.hex

set -euo pipefail

HEX_FILE="${1:-/tmp/rexcode_mos65816.hex}"
ASM_FILE="${HEX_FILE%.hex}.s"
META_FILE="${HEX_FILE%.hex}_meta.txt"
LST_FILE="${HEX_FILE%.hex}.lst"
OBJ_FILE="${HEX_FILE%.hex}.o"

if ! command -v ca65 >/dev/null 2>&1; then
	echo "ca65 (cc65) not found — install with: pacman -S cc65"
	exit 0
fi
for f in "$HEX_FILE" "$ASM_FILE" "$META_FILE"; do
	if [ ! -f "$f" ]; then
		echo "Manifest missing: $f"
		echo "Run first: cd isa/mos65816 && odin run tools/dump_verify_input.odin -file"
		exit 1
	fi
done

echo "Assembling $ASM_FILE with ca65..."
if ! ca65 --listing "$LST_FILE" "$ASM_FILE" -o "$OBJ_FILE" 2>&1; then
	echo "ca65 failed — see errors above"
	exit 1
fi

# Extract per-instruction bytes from the listing.
# Listing line format for *resolved* (post-.org) instructions:
#   <6 hex offset>  <seg>  <bytes>  <asm>
# Lines we want to keep:
#   - Have NO trailing 'r' on the offset (post-.org address)
#   - Have at least one byte in the bytes column
#   - Are NOT pure directive lines (no bytes column populated)
awk '
	# Strip ca65 listing header (everything before the first .org line)
	/\.org/ { reached_org = 1; next }
	!reached_org { next }
	# Match listing rows: offset(6) seg bytes asm
	# Two flavors of byte block: 1-4 hex bytes separated by spaces
	{
		# Looking for lines like: "000000  1  61 42        adc ($42,x)"
		if (match($0, /^[0-9A-F]{6}  [0-9]+  ([0-9A-F]{2}( [0-9A-F]{2}){0,3})/, arr)) {
			print arr[1]
		}
	}
' "$LST_FILE" > "${LST_FILE}.bytes"

# Now compare line-by-line against $HEX_FILE.
# Convert each $HEX_FILE entry from "0xNN,0xMM" → "NN MM" for direct compare.
awk -F',' '{
	out = ""
	for (i = 1; i <= NF; i++) {
		v = $i
		sub(/^0x/, "", v)
		out = (i==1) ? toupper(v) : out " " toupper(v)
	}
	print out
}' "$HEX_FILE" > "${HEX_FILE}.expected"

total=0; ok=0; mismatch=0
first_mismatch=""

paste "$META_FILE" "${HEX_FILE}.expected" "${LST_FILE}.bytes" | \
while IFS=$'\t' read -r mn opcode length expected got; do
	total=$((total+1))
	if [ "$expected" = "$got" ]; then
		ok=$((ok+1))
	else
		mismatch=$((mismatch+1))
		if [ -z "$first_mismatch" ] || [ $(echo "$first_mismatch" | wc -l) -lt 25 ]; then
			first_mismatch+="$(printf '  %-10s op=%s len=%s expected=%-12s got=%s\n' \
				"$mn" "$opcode" "$length" "$expected" "$got")"$'\n'
		fi
	fi
	# Persist counts via files since pipe + subshell
	echo "$total $ok $mismatch" > /tmp/_mos65816_counts
done

# Re-read from file (because pipe→subshell scope)
read total ok mismatch < /tmp/_mos65816_counts || true

# Independent recount in case loop variable leak doesn't survive
total_lines=$(wc -l < "$META_FILE")
expected_lines=$(wc -l < "${HEX_FILE}.expected")
got_lines=$(wc -l < "${LST_FILE}.bytes")

# Use paste+awk for the actual reliable count:
read total ok mismatch <<< "$(paste "${HEX_FILE}.expected" "${LST_FILE}.bytes" | \
	awk -F'\t' '
		BEGIN { ok=0; mis=0; t=0 }
		{ t++; if ($1==$2) ok++; else mis++ }
		END { print t, ok, mis }
	')"

echo "===================================================================="
printf "  TOTAL entries:    %s\n" "$total"
printf "  Expected lines:   %s\n" "$expected_lines"
printf "  ca65 byte lines:  %s\n" "$got_lines"
printf "  OK matches:       %s\n" "$ok"
printf "  MISMATCHES:       %s\n" "$mismatch"
echo "===================================================================="

if [ "$mismatch" -gt 0 ]; then
	echo "First mismatches:"
	paste "$META_FILE" "${HEX_FILE}.expected" "${LST_FILE}.bytes" | \
		awk -F'\t' '$4 != $5 { printf "  %-10s op=%s len=%s\n    expected: %s\n    ca65 got: %s\n", $1, $2, $3, $4, $5 }' | \
		head -30
fi

[ "$mismatch" -eq 0 ] && [ "$total" = "$total_lines" ] && \
	echo "PERFECT — every entry assembles to its expected bytes via ca65"
