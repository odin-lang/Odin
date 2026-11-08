// Reversible filters that make executables and some other data compress better
//
// Branch converters (BCJ) for x86, PowerPC, IA-64, ARM, ARM Thumb, SPARC, ARM64 and RISC-V, Delta, and Swap2/Swap4,
// as used by xz (and so zip method 95) and 7z, plus 7z's four-stream BCJ2.
// Each filter is a transform only: mapping xz filter IDs and 7z method IDs onto them is up to those containers.
// It is a port of Igor Pavlov's public domain LZMA SDK, and the output is byte-identical to the SDK's.
package compress_filters

import "base:intrinsics"
import "core:compress"

/*
	Copyright 2026 Jeroen van Rijn <nom@duclavier.com>.
	Made available under Odin's license.

	List of contributors:
		Jeroen van Rijn: Initial implementation.

	Ported from the LZMA SDK 26.05 (2026-10-21), written by Igor Pavlov and placed in the public domain:
		https://www.7-zip.org/sdk.html

		C/Bra.c:                 PowerPC, ARM, ARM Thumb, SPARC, ARM64 and RISC-V converters
		C/Bra86.c:               x86 converter, in the prev-mask form of the LZMA SDK 9.20
		C/BraIA64.c:             IA-64 converter
		C/Delta.c:               Delta
		C/SwapBytes.c:           Swap2 and Swap4
		C/Bcj2.c, C/Bcj2Enc.c:   BCJ2 decoder and encoder

	Many thanks to Igor Pavlov for these filters, and for placing the SDK in the public domain.
*/

Error         :: compress.Error
General_Error :: compress.General_Error
BCJ2_Error    :: compress.BCJ2_Error

Branch_Arch :: enum u8 {
	X86,
	PowerPC,
	IA64,
	ARM,
	ARM_Thumb,
	SPARC,
	ARM64,
	RISCV,
}

Branch_State :: struct {
	arch:     Branch_Arch,
	pc:       u32,
	x86_mask: u32,
}

DELTA_DISTANCE_MIN :: 1
DELTA_DISTANCE_MAX :: 256

Delta_State :: struct {
	distance: int,
	history:  [DELTA_DISTANCE_MAX]u8,
}

BRANCH_ALIGNMENT := [Branch_Arch]int{
	.X86       = 1,
	.PowerPC   = 4,
	.IA64      = 16,
	.ARM       = 4,
	.ARM_Thumb = 2,
	.SPARC     = 4,
	.ARM64     = 4,
	.RISCV     = 2,
}

BCJ2_RELAT_LIMIT_DEFAULT :: u32(0x0F) << 24
BCJ2_RELAT_LIMIT_MAX     :: u32(1) << 31

Bcj2_Streams :: struct {
	main: [dynamic]u8,
	call: [dynamic]u8,
	jump: [dynamic]u8,
	rc:   [dynamic]u8,
}

@(private) BCJ2_TOP        :: u32(1) << 24
@(private) BCJ2_PROB_BITS  :: 11
@(private) BCJ2_PROB_INIT  :: u16(1 << BCJ2_PROB_BITS >> 1)
@(private) BCJ2_MOVE_BITS  :: 5

@(private)
X86_MASK_TO_ALLOWED := [8]bool{true, true, true, false, true, false, false, false}

@(private)
X86_MASK_TO_BIT_NUMBER := [8]u32{0, 1, 2, 2, 3, 3, 3, 3}

@(private)
get_le16 :: #force_inline proc "contextless" (data: []u8, i: int) -> u32 #no_bounds_check {
	return u32(intrinsics.unaligned_load((^u16le)(&data[i])))
}

@(private)
get_le32 :: #force_inline proc "contextless" (data: []u8, i: int) -> u32 #no_bounds_check {
	return u32(intrinsics.unaligned_load((^u32le)(&data[i])))
}

@(private)
get_be32 :: #force_inline proc "contextless" (data: []u8, i: int) -> u32 #no_bounds_check {
	return u32(intrinsics.unaligned_load((^u32be)(&data[i])))
}

@(private)
put_le16 :: #force_inline proc "contextless" (data: []u8, i: int, v: u32) #no_bounds_check {
	intrinsics.unaligned_store((^u16le)(&data[i]), u16le(v))
}

@(private)
put_le32 :: #force_inline proc "contextless" (data: []u8, i: int, v: u32) #no_bounds_check {
	intrinsics.unaligned_store((^u32le)(&data[i]), u32le(v))
}

@(private)
put_be32 :: #force_inline proc "contextless" (data: []u8, i: int, v: u32) #no_bounds_check {
	intrinsics.unaligned_store((^u32be)(&data[i]), u32be(v))
}
