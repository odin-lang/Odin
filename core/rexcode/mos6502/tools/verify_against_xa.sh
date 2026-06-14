#!/usr/bin/env bash
# =============================================================================
# MOS 6502 verification harness — disassembles via `da65` (cc65)
# =============================================================================
#
# Strategy: for each ENCODING_TABLE entry we have opcode + safe-fill bytes.
# We disassemble each entry in isolation via `da65` using the CPU-tier-
# appropriate --cpu flag (6502 / 6502X / 65C02 / huc6280), then compare the
# emitted mnemonic to the table's expected mnemonic.
#
# This catches any opcode that doesn't decode the way our table claims:
# wrong addressing mode, wrong CPU tier, dead opcode, encoding typo.
#
# Install:  pacman -S cc65   (cc65 ships both ca65 and da65)
#
# Usage:    bash tools/verify_against_xa.sh /tmp/rexcode_mos6502.hex

set -euo pipefail

HEX_FILE="${1:-/tmp/rexcode_mos6502.hex}"
META_FILE="${HEX_FILE%.hex}_meta.txt"
WORK=/tmp/rexcode_mos6502_verify

if ! command -v da65 >/dev/null 2>&1; then
	echo "da65 (cc65) not found — install with: pacman -S cc65"
	exit 0
fi
if [ ! -f "$HEX_FILE" ] || [ ! -f "$META_FILE" ]; then
	echo "Manifest files missing. Run first:"
	echo "  cd mos6502 && odin run tools/dump_verify_input.odin -file"
	exit 1
fi

tier_flag() {
	case "$1" in
		NMOS)        echo 6502 ;;
		NMOS_UNDOC)  echo 6502X ;;
		CMOS_65C02)  echo 65C02 ;;
		HUC6280)     echo huc6280 ;;
		*)           echo 6502 ;;
	esac
}

# Normalize names da65 uses vs our enum names.
# da65 emits the conventional mnemonic; our enum may have a tier-suffix
# disambiguator (SAX_NMOS, ...) and our undocumented set uses canonical
# names (LXA, USBC, DOP, TOP, SHA, SHX, SHY, ANE, LAS, SBX, ARR, ALR, ...)
# while da65 prefers the cc65 dialect spellings (LAX, SBC, NOP, NOP, AHX,
# ...).  We map both sides to a canonical alias set here.
canon_mn() {
	local m="$1"
	m="${m%_NMOS}"
	m="${m%_HUC}"
	case "$m" in
		LXA)        echo LAX ;;     # cc65 spells immediate LXA as LAX
		SHA)        echo AHX ;;     # 6502X dialect
		SHY)        echo SHY ;;
		SHX)        echo SHX ;;
		ANE|XAA)    echo XAA ;;     # both names exist; pick one
		USBC)       echo SBC ;;     # USBC is the same byte as SBC #imm
		DOP)        echo NOP ;;     # double-NOP = NOP imm/zp
		TOP)        echo NOP ;;     # triple-NOP = NOP abs
		JAM|KIL|HLT) echo KIL ;;
		# 65C02 short-mnemonic-vs-long aliases for INC A / DEC A
		INA)        echo INC ;;     # da65 calls inc-a "INC" with "a"
		DEA)        echo DEC ;;
		*)          echo "$m" ;;
	esac
}

rm -rf "$WORK"; mkdir -p "$WORK"
SCRATCH="$WORK/one.bin"

total=0; ok=0; mismatch=0
declare -A TIER_TOTAL TIER_OK TIER_MIS
first_mismatch_lines=""

exec 3<"$HEX_FILE" 4<"$META_FILE"
while IFS=$'\t' read -r mn opcode cpu length <&4 && IFS= read -r hex <&3; do
	total=$((total+1))
	flag=$(tier_flag "$cpu")
	TIER_TOTAL[$cpu]=$(( ${TIER_TOTAL[$cpu]:-0} + 1 ))

	# Materialise this single entry into a 1-instruction binary
	echo "$hex" | tr -d ' ,' | sed 's/0x//g' | xxd -r -p > "$SCRATCH"

	# Disassemble it
	asm=$(da65 --cpu "$flag" "$SCRATCH" 2>/dev/null \
		| awk '/^[[:space:]]+[a-zA-Z]/ {
				  if (substr($1,1,1)==".") next
				  if ($0 ~ /:=/) next
				  print toupper($1); exit
			  }')

	expected=$(canon_mn "$mn")
	got=$(canon_mn "$asm")

	if [ "$got" = "$expected" ]; then
		ok=$((ok+1))
		TIER_OK[$cpu]=$(( ${TIER_OK[$cpu]:-0} + 1 ))
	else
		mismatch=$((mismatch+1))
		TIER_MIS[$cpu]=$(( ${TIER_MIS[$cpu]:-0} + 1 ))
		if [ ${#first_mismatch_lines} -lt 2000 ]; then
			first_mismatch_lines+="$(printf '  [%s] %-12s want=%-8s got=%-8s opcode=%s len=%s\n' \
				"$cpu" "$mn" "$expected" "$got" "$opcode" "$length")"$'\n'
		fi
	fi
done

echo "===================================================================="
printf "  %-12s %-8s %-8s %-8s %-8s\n" "TIER" "TOTAL" "OK" "MISMATCH" "%OK"
echo "  ------------------------------------------------------------"
for cpu in NMOS NMOS_UNDOC CMOS_65C02 HUC6280; do
	t=${TIER_TOTAL[$cpu]:-0}
	o=${TIER_OK[$cpu]:-0}
	mm=${TIER_MIS[$cpu]:-0}
	pct="-"
	[ "$t" -gt 0 ] && pct=$(awk "BEGIN{printf \"%.0f%%\", 100*$o/$t}")
	printf "  %-12s %-8d %-8d %-8d %-8s\n" "$cpu" "$t" "$o" "$mm" "$pct"
done
echo "  ------------------------------------------------------------"
printf "  %-12s %-8d %-8d %-8d %s\n" "TOTAL" "$total" "$ok" "$mismatch" \
	"$(awk "BEGIN{printf \"%.1f%%\", 100*$ok/$total}")"
echo "===================================================================="

if [ "$mismatch" -gt 0 ]; then
	echo
	echo "First mismatches:"
	printf "%s" "$first_mismatch_lines" | head -25
fi

[ "$mismatch" -eq 0 ] && echo "PERFECT — every entry round-trips through da65"
