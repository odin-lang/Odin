package compress_xz

import "base:runtime"
import "core:compress"
import "core:compress/filters"
import "core:compress/lzma"
import "core:crypto/sha2"
import "core:io"

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
UNPADDED_SIZE_MAX     :: VLI_MAX &~ 3
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

Block_Info :: struct {
	stream:              int,
	compressed_offset:   i64,
	uncompressed_offset: i64,
	unpadded_size:       i64,
	uncompressed_size:   i64,
}

Stream_Info :: struct {
	check_id:            u8,
	compressed_offset:   i64,
	compressed_size:     i64,
	uncompressed_offset: i64,
	uncompressed_size:   i64,
	padding:             i64,
	first_block:         int,
	block_count:         int,
}

Index :: struct {
	streams:           [dynamic]Stream_Info,
	blocks:            [dynamic]Block_Info,
	compressed_size:   i64,
	uncompressed_size: i64,
}

Reader :: struct {
	z:                ^compress.Context,
	flags:            Decode_Flags,
	options:          compress.Options,
	allocator:        runtime.Allocator,
	size:             int,
	total_in:         i64,
	consumed:         i64,
	produced:         i64,
	done:             bool,
	err:              Error,

	check_id:         u8,
	stream_flags:     [2]u8,
	records:          u64,
	unpadded_sum:     u64,
	uncompressed_sum: u64,
	index_hash:       sha2.Context_256,

	in_block:         bool,
	lzma:             lzma.Reader,
	chain:            [FILTERS_MAX - 1]filters.Reader,
	chain_count:      int,
	header_size:      int,
	compressed:       u64,
	uncompressed:     u64,
	has_compressed:   bool,
	has_uncompressed: bool,
	block_out:        u64,
	crc32:            u32,
	crc64:            u64,
	sha256:           sha2.Context_256,

	bounded:          bool,
	block_view:       bool,
	block_z:          compress.Context,
	block_data:       []u8,
	block_left:       u64,
	block_eof:        bool,
	block_backing:    []u8,
}

Writer :: struct {
	w:           io.Writer,
	opts:        Options,
	options:     compress.Options,
	allocator:   runtime.Allocator,
	check:       Check,
	props:       lzma.Properties,
	lzma:        lzma.Writer,
	chain:       [FILTERS_MAX - 1]filters.Writer,
	chain_count: int,
	open:        bool,
	in_block:    bool,
	block_in:    u64,
	block_start: i64,
	header_size: int,
	records:     [dynamic][2]u64,
	total_in:    i64,
	total_out:   i64,
	next_report: i64,
	crc32:       u32,
	crc64:       u64,
	sha256:      sha2.Context_256,
	err:         Error,
	finished:    bool,
}

@(private)
INDEX_SCAN_CHUNK :: 4096

@(private)
Index_Source :: struct {
	bytes:     []u8,
	stream:    io.Stream,
	is_stream: bool,
	size:      i64,
	buffer:    [dynamic]u8,
}

@(private)
Index_Location :: struct {
	offset: i64,
	size:   i64,
	padded: i64,
}

@(private)
Index_Summary :: struct {
	count:        u64,
	padded:       i64,
	uncompressed: i64,
}

@(private)
Block_Filter :: struct {
	id:     Filter_ID,
	branch: filters.Branch_State,
	delta:  filters.Delta_State,
}
