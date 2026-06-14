#!/bin/bash
# Per-line llvm-mc disassembly wrapper. Reads a .hex manifest, runs each line
# through llvm-mc independently so output lines align 1:1 with input lines.
# (llvm-mc's stream mode is greedy: it consumes prefix bytes when a line looks
# like a partial 8-byte prefixed instruction, breaking alignment.)
#
# Usage:  bash llvm_per_line.sh <hex-file> <triple> <mattr>
#   <triple>  e.g. powerpc64-unknown-linux-gnu  or  powerpc64le-unknown-linux-gnu
#   <mattr>   e.g. +power10,+altivec,+vsx,+htm

set -u

HEX=$1
TRIPLE=$2
MATTR=$3

while IFS= read -r line; do
	out=$(echo "$line" | llvm-mc --disassemble -triple="$TRIPLE" -mattr="$MATTR" 2>/dev/null \
		  | awk '/^\t/ {print substr($0, 2); exit}')
	if [ -z "$out" ]; then
		echo "<unknown>"
	else
		echo "$out"
	fi
done < "$HEX"
