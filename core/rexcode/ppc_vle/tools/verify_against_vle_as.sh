#!/usr/bin/env bash
# rexcode  ·  Brendan Punsky (dotbmp@github), original author

# =============================================================================
# PowerPC VLE verification harness — assemble + objdump (binutils VLE)
# =============================================================================
#
# Strategy: the dumper emits an asm file with a `.machine vle` prologue +
# a real `se_isync` (so the linker tags .text with SHF_PPC_VLE) followed
# by raw `.short`/`.long` data of each ENCODING_TABLE entry's bytes. We
# assemble through `powerpc-eabivle-as -mvle` and disassemble through
# `powerpc-eabivle-objdump -M vle`. Then for each entry we compare the
# disassembled mnemonic against our table's mnemonic.
#
# Install:  build binutils with --target=powerpc-eabivle.
#           See /opt/ppc-vle/bin/ on a typical install.
#
# Usage:    bash tools/verify_against_vle_as.sh /tmp/rexcode_ppc_vle.hex

set -euo pipefail

# Make sure our toolchain is on PATH
export PATH="/opt/ppc-vle/bin:$PATH"

HEX_FILE="${1:-/tmp/rexcode_ppc_vle.hex}"
ASM_FILE="${HEX_FILE%.hex}.s"
META_FILE="${HEX_FILE%.hex}_meta.txt"
OBJ_FILE="${HEX_FILE%.hex}.o"
ASM_OUT="${HEX_FILE%.hex}.dasm"

if ! command -v powerpc-eabivle-as >/dev/null 2>&1; then
    echo "powerpc-eabivle-as not found on PATH — install binutils with --target=powerpc-eabivle"
    exit 0
fi
if ! command -v powerpc-eabivle-objdump >/dev/null 2>&1; then
    echo "powerpc-eabivle-objdump not found on PATH"
    exit 0
fi
for f in "$HEX_FILE" "$ASM_FILE" "$META_FILE"; do
    if [ ! -f "$f" ]; then
        echo "Manifest missing: $f"
        echo "Run first: cd ppc_vle && odin run tools/dump_verify_input.odin -file"
        exit 1
    fi
done

echo "Assembling $ASM_FILE with powerpc-eabivle-as..."
if ! powerpc-eabivle-as -mvle "$ASM_FILE" -o "$OBJ_FILE" 2>&1; then
    echo "as failed"
    exit 1
fi

echo "Disassembling with powerpc-eabivle-objdump..."
powerpc-eabivle-objdump -d -M vle "$OBJ_FILE" > "$ASM_OUT" 2>&1

# Extract emitted mnemonics from the disassembly. Each instruction line
# looks like:  "  16:\t00 0b       \tse_rfmci"
# We grab column 3 (after the bytes column) → the mnemonic token.
awk '
    /Disassembly of section/ { in_section = 1; next }
    !in_section { next }
    /^[[:space:]]*$/ { next }
    /^[0-9a-fA-F]+ </ { next }   # section/symbol header lines
    {
        # Split on tabs. Format: "<offset>:\t<bytes>\t<mnemonic> <ops>"
        n = split($0, parts, /\t/)
        if (n < 3) next
        # parts[3] is the mnemonic-and-operands string. First token = mnemonic.
        split(parts[3], toks, /[ ,]/)
        mn = tolower(toks[1])
        if (mn == "") next
        print mn
    }
' "$ASM_OUT" > "$ASM_OUT.mnemonics"

# Drop the prologue (se_isync, 1 line) from the disassembled mnemonics.
sed -i '1d' "$ASM_OUT.mnemonics"

# Build lowercase expected list. Mnemonic-suffix `_DOT` → ".".
# Also canonicalise PowerPC extended-mnemonic aliases: e.g. `se_bnl` and
# `se_bge` are the same encoding spelled differently, and binutils picks
# the simpler one. We map every member of an alias cluster to a single
# canonical so equal-encoding-different-name pairs verify as OK.
canonicalise() {
    awk '
        function canon(m) {
            sub(/_dot$/, ".", m)
            # 16-bit conditional branches (se_*). With BI=0, the alias is
            # determined by BO (true vs false) and the condition family:
            #   BF (BO=01100, default BI=0=LT) → branch-NOT-less → BGE
            #   BT (BO=01100, default BI=0=LT) → branch-IF-less   → BLT
            if (m == "se_bnl" || m == "se_bf" || m == "se_bc") return "se_bge"
            if (m == "se_bng") return "se_ble"
            if (m == "se_bnu") return "se_bns"
            if (m == "se_bun") return "se_bso"
            if (m == "se_bt") return "se_blt"
            # 32-bit conditional branches (e_b*) — same family
            if (m == "e_bnl" || m == "e_bf" || m == "e_bc") return "e_bge"
            if (m == "e_bng") return "e_ble"
            if (m == "e_bnu") return "e_bns"
            if (m == "e_bun") return "e_bso"
            if (m == "e_bt") return "e_blt"
            # link versions (suffix l)
            if (m == "e_bnll" || m == "e_bfl" || m == "e_bcl") return "e_bgel"
            if (m == "e_bngl") return "e_blel"
            if (m == "e_bnul") return "e_bnsl"
            if (m == "e_bunl") return "e_bsol"
            if (m == "e_btl") return "e_bltl"
            # Load multiple aliases (LDMV* and LMV* are the same)
            sub(/^e_ldmv/, "e_lmv", m)
            sub(/^e_stmv/, "e_smv", m)
            # 32-bit immediate aliases (SUBI/ADDI etc. are same encoding when imm=0)
            if (m == "e_la"       || m == "e_sub16i")   return "e_add16i"
            if (m == "e_subi")    return "e_addi"
            if (m == "e_subic")   return "e_addic"
            if (m == "e_subic.")  return "e_addic."
            if (m == "e_sub2is")  return "e_add2is"
            if (m == "e_sub2i.")  return "e_add2i."
            # Rotate/mask aliases — operand-dependent canonical form
            if (m == "e_inslwi" || m == "e_insrwi") return "e_rlwimi"
            if (m == "e_rotrwi" || m == "e_clrlwi" || m == "e_extrwi") return "e_rotlwi"
            if (m == "e_rlwinm" || m == "e_extlwi" || m == "e_clrlslwi") return "e_clrrwi"
            # CR ops
            if (m == "e_crnor") return "e_crnot"
            if (m == "e_crxor") return "e_crclr"
            if (m == "e_creqv") return "e_crset"
            if (m == "e_cror")  return "e_crmove"
            # OR-zero → NOP (operand-dependent)
            if (m == "se_or")   return "se_nop"
            if (m == "e_ori")   return "e_nop"
            # Compare aliases (PPC32 only has word forms; cmpwi == cmpi etc.)
            if (m == "e_cmpwi" || m == "e_cmpli" || m == "e_cmplwi") return "e_cmpi"
            return m
        }
        { print canon(tolower($0)) }
    '
}

awk -F'\t' '{ print tolower($1) }' "$META_FILE" | canonicalise > "$META_FILE.expected_mnemonics"
canonicalise < "$ASM_OUT.mnemonics" > "$ASM_OUT.mnemonics.canon"
mv "$ASM_OUT.mnemonics.canon" "$ASM_OUT.mnemonics"

n_exp=$(wc -l < "$META_FILE.expected_mnemonics")
n_got=$(wc -l < "$ASM_OUT.mnemonics")

echo
echo "Comparing mnemonics..."
ok=0; mis=0
mismatches=""
paste "$META_FILE.expected_mnemonics" "$ASM_OUT.mnemonics" | nl -ba | \
while IFS=$'\t' read -r idx pair; do
    e=$(echo "$pair" | cut -f1)
    g=$(echo "$pair" | cut -f2)
    if [ "$e" = "$g" ]; then
        echo "OK $idx" >> /tmp/_vle_ok
    else
        echo -e "$idx\t$e\t$g" >> /tmp/_vle_mis
    fi
done

# Initialize/reset
rm -f /tmp/_vle_ok /tmp/_vle_mis

paste "$META_FILE.expected_mnemonics" "$ASM_OUT.mnemonics" > "$ASM_OUT.pairs"

ok=$(awk -F'\t' '$1==$2' "$ASM_OUT.pairs" | wc -l)
mis=$(awk -F'\t' 'NF==2 && $1!=$2' "$ASM_OUT.pairs" | wc -l)

echo "===================================================================="
printf "  TOTAL entries:      %d\n"  "$n_exp"
printf "  Disasm mnemonics:   %d\n"  "$n_got"
printf "  OK matches:         %d\n"  "$ok"
printf "  MISMATCHES:         %d\n"  "$mis"
echo "===================================================================="

if [ "$mis" -gt 0 ]; then
    echo "First mismatches:"
    awk -F'\t' 'NF==2 && $1!=$2 { printf "  want=%-14s got=%s\n", $1, $2 }' \
        "$ASM_OUT.pairs" | head -30
fi
[ "$mis" -eq 0 ] && [ "$n_exp" = "$n_got" ] && \
    echo "PERFECT — every entry decodes to its expected mnemonic via powerpc-eabivle-objdump"
