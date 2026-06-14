#!/bin/bash
# Per-line llvm-mc disassembly wrapper.
#
# llvm-mc reads the entire stdin as a stream and decodes greedily, so a
# T32 32-bit input that LLVM doesn't recognize will be re-interpreted as
# two adjacent T16 16-bit instructions, breaking 1:1 alignment with our
# meta file. This script invokes llvm-mc once per input line so each
# output line corresponds to exactly one input line (or "" on failure).
#
# Usage:
#   llvm_per_line.sh <hex_file> <output_file> <triple> <mattr>
#
# Example:
#   llvm_per_line.sh /tmp/rexcode_arm32_a32.hex /tmp/rexcode_arm32_a32_llvm.txt \
#                    arm-none-eabi "+armv8.6-a,+neon,+vfp4,+fullfp16"

hex_file="$1"
output_file="$2"
triple="$3"
mattr="$4"

if [ -z "$mattr" ]; then
	echo "Usage: $0 <hex_file> <output_file> <triple> <mattr>" >&2
	exit 1
fi

> "$output_file"
while IFS= read -r line; do
	out=$(echo "$line" | llvm-mc --disassemble -triple="$triple" -mattr="$mattr" 2>&1 | grep -E "^[[:space:]]+[a-zA-Z]" | head -1)
	if [ -z "$out" ]; then
		echo "" >> "$output_file"
	else
		echo "$out" >> "$output_file"
	fi
done < "$hex_file"
