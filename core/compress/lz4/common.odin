package compress_lz4

import "base:intrinsics"
import "core:compress"

Error         :: compress.Error
General_Error :: compress.General_Error
LZ4_Error     :: compress.LZ4_Error

Level :: enum i32 {
	Level_1  = 1,
	Level_2  = 2,
	Level_3  = 3,
	Level_4  = 4,
	Level_5  = 5,
	Level_6  = 6,
	Level_7  = 7,
	Level_8  = 8,
	Level_9  = 9,
	Level_10 = 10,
	Level_11 = 11,
	Level_12 = 12,
	Fastest  = Level_1,
	Default  = Level_1,
	Best     = Level_12,
}

Block_Max_Size :: enum u8 {
	Max_4MiB   = 0,
	Max_1MiB   = 1,
	Max_256KiB = 2,
	Max_64KiB  = 3,
}

Frame_Flag :: enum u8 {
	Content_Checksum   = 2,
	Content_Size       = 3,
	Block_Checksum     = 4,
	Independent_Blocks = 5,
}
Frame_Flags :: bit_set[Frame_Flag; u8]

DEFAULT_FRAME_FLAGS :: Frame_Flags{.Content_Checksum, .Content_Size}

Frame_Options :: struct {
	block_max_size: Block_Max_Size,
	flags:          Frame_Flags,
	dictionary_id:  Maybe(u32),
}

LZ4 :: struct {
	head:  [LZ4_HASH_SIZE]u32,
	chain: [LZ4_WINDOW_SIZE]u16,
	fast:  [LZ4_FAST_HASH_SIZE]u32,
}

FRAME_MAGIC          :: u32(0x184D2204)
SKIPPABLE_MAGIC_MIN  :: u32(0x184D2A50)
SKIPPABLE_MAGIC_MAX  :: u32(0x184D2A5F)
LEGACY_MAGIC         :: u32(0x184C2102)
LEGACY_BLOCK_SIZE    :: 8 << 20

FRAME_HEADER_MAX     :: 4 + 2 + 8 + 4 + 1
FRAME_DESCRIPTOR_MAX :: 2 + 8 + 4
FRAME_FOOTER_MAX     :: 4 + 4

@(private)
LZ4_Descriptor_Flag :: enum u8 {
	Dictionary_ID      = 0,
	Reserved           = 1,
	Content_Checksum   = 2,
	Content_Size       = 3,
	Block_Checksum     = 4,
	Independent_Blocks = 5,
	Version_Low        = 6,
	Version_High       = 7,
}
@(private)
LZ4_Descriptor_Flags :: bit_set[LZ4_Descriptor_Flag; u8]

@(private)
LZ4_MIN_MATCH          :: 4
@(private)
LZ4_LAST_LITERALS      :: 5
@(private)
LZ4_MATCH_START_LIMIT  :: 12
@(private)
LZ4_MAX_OFFSET         :: 65535
@(private)
LZ4_WINDOW_SIZE        :: 1 << 16
@(private)
LZ4_HASH_LOG           :: 16
@(private)
LZ4_HASH_SIZE          :: 1 << LZ4_HASH_LOG
@(private)
LZ4_FAST_HASH_LOG      :: 12
@(private)
LZ4_FAST_HASH_SIZE     :: 1 << LZ4_FAST_HASH_LOG
@(private)
LZ4_INPUT_MAX          :: int(max(u32) >> 1)
@(private)
LZ4_EXPANSION_MAX      :: 255
@(private)
LZ4_INITIAL_SIZE_MAX   :: 16 << 20
@(private)
LZ4_GROWTH_STEP        :: 16 << 20

@(private)
LZ4_Level_Parameters :: struct {
	chain_depth: i32,
	nice_length: i32,
	strategy:    LZ4_Strategy,
}

@(private)
LZ4_Strategy :: enum u8 {
	Fast,
	Double,
	Greedy,
	Lazy,
	Optimal,
}

@(private, rodata)
LZ4_LEVELS := [Level]LZ4_Level_Parameters{
	.Level_1  = {0,    0,     .Fast},
	.Level_2  = {0,    0,     .Double},
	.Level_3  = {4,    16,    .Lazy},
	.Level_4  = {8,    64,    .Lazy},
	.Level_5  = {16,   128,   .Lazy},
	.Level_6  = {32,   256,   .Lazy},
	.Level_7  = {64,   512,   .Lazy},
	.Level_8  = {128,  1024,  .Lazy},
	.Level_9  = {256,  4096,  .Lazy},
	.Level_10 = {64,   128,   .Optimal},
	.Level_11 = {256,  512,   .Optimal},
	.Level_12 = {1024, 1024,  .Optimal},
}

@(private, rodata)
LZ4_BLOCK_MAX_BYTES := [Block_Max_Size]int{
	.Max_4MiB   = 4 << 20,
	.Max_1MiB   = 1 << 20,
	.Max_256KiB = 256 << 10,
	.Max_64KiB  = 64 << 10,
}

@(private, rodata)
LZ4_BLOCK_MAX_CODE := [Block_Max_Size]u8{
	.Max_4MiB   = 7,
	.Max_1MiB   = 6,
	.Max_256KiB = 5,
	.Max_64KiB  = 4,
}

@(private)
lz4_load_u16 :: #force_inline proc "contextless" (p: [^]u8) -> u16 {
	return u16(intrinsics.unaligned_load((^u16le)(p)))
}

@(private)
lz4_load_u32 :: #force_inline proc "contextless" (p: [^]u8) -> u32 {
	return u32(intrinsics.unaligned_load((^u32le)(p)))
}

@(private)
lz4_load_u64 :: #force_inline proc "contextless" (p: [^]u8) -> u64 {
	return u64(intrinsics.unaligned_load((^u64le)(p)))
}

@(private)
lz4_store_u16 :: #force_inline proc "contextless" (p: [^]u8, v: u16) {
	intrinsics.unaligned_store((^u16le)(p), u16le(v))
}

@(private)
lz4_store_u32 :: #force_inline proc "contextless" (p: [^]u8, v: u32) {
	intrinsics.unaligned_store((^u32le)(p), u32le(v))
}

@(private)
lz4_store_u64 :: #force_inline proc "contextless" (p: [^]u8, v: u64) {
	intrinsics.unaligned_store((^u64le)(p), u64le(v))
}

@(private)
lz4_copy_8 :: #force_inline proc "contextless" (dst, src: [^]u8) {
	intrinsics.unaligned_store((^u64)(dst), intrinsics.unaligned_load((^u64)(src)))
}

@(private)
lz4_copy_16 :: #force_inline proc "contextless" (dst, src: [^]u8) {
	intrinsics.unaligned_store((^[2]u64)(dst), intrinsics.unaligned_load((^[2]u64)(src)))
}
