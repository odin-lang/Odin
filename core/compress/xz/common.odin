package compress_xz

import "core:compress"
import "core:compress/filters"
import "core:compress/lzma"

Error         :: compress.Error
General_Error :: compress.General_Error
XZ_Error      :: compress.XZ_Error

HEADER_SIZE           :: 12
FOOTER_SIZE           :: 12
BLOCK_HEADER_SIZE_MAX :: 1024
FILTERS_MAX           :: 4
VLI_BYTES_MAX         :: 9
VLI_MAX               :: u64(max(i64))
INDEX_SIZE_MAX        :: u64(1) << 34
UNPADDED_SIZE_MIN     :: 5
BLOCK_SIZE_MIN        :: 1 << 20
INDEX_RECORD_MAX      :: 2 * VLI_BYTES_MAX

@(rodata)
HEADER_MAGIC := [6]u8{0xFD, '7', 'z', 'X', 'Z', 0x00}

@(rodata)
FOOTER_MAGIC := [2]u8{'Y', 'Z'}

@(rodata)
CHECK_SIZES := [16]int{0, 4, 4, 4, 8, 8, 8, 16, 16, 16, 32, 32, 32, 64, 64, 64}

Check :: enum u8 {
	None   = 0x00,
	CRC32  = 0x01,
	CRC64  = 0x04,
	SHA256 = 0x0A,
}

Filter_ID :: enum u64 {
	Delta     = 0x03,
	X86       = 0x04,
	PowerPC   = 0x05,
	IA64      = 0x06,
	ARM       = 0x07,
	ARM_Thumb = 0x08,
	SPARC     = 0x09,
	ARM64     = 0x0A,
	RISCV     = 0x0B,
	LZMA2     = 0x21,
}

Filter :: struct {
	id:             Filter_ID,
	start_offset:   u32,
	delta_distance: int,
}

Level :: lzma.Level

Options :: struct {
	lzma2:        lzma.Options,
	check:        Maybe(Check),
	block_size:   int,
	filters:      [FILTERS_MAX - 1]Filter,
	filter_count: int,
}

Decode_Flag :: enum u8 {
	Ignore_Check,
}

Decode_Flags :: bit_set[Decode_Flag; u8]

@(private)
Block_Filter :: struct {
	id:     Filter_ID,
	branch: filters.Branch_State,
	delta:  filters.Delta_State,
}
