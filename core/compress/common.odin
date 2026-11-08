// A collection of utilities to aid with other `compress`ion packages.
package compress

import "base:runtime"
import "core:io"

/*
	Copyright 2021-2026 Jeroen van Rijn <nom@duclavier.com>.
	Made available under Odin's license.

	List of contributors:
		Jeroen van Rijn: Initial implementation, optimization.

	These settings bound how much compression algorithms will allocate for their output buffer.
	If streaming their output, these are unnecessary and will be ignored.

	`COMPRESS_OUTPUT_ALLOCATE_MAX` bounds the maximum a buffer will grow to as needed.

	`COMPRESS_INITIAL_RESERVATION` bounds what we'll pre-allocate up front. If you pass the payload size,
	we reserve up to that size. If you don't, but the input size is known, we reserve up to
	`COMPRESS_INITIAL_RESERVATION_RATIO` times the input size, otherwise 64 KiB. The reservation never
	exceeds what the input could decompress to.

	These defaults are deliberately conservative: a hostile payload can't make us allocate far
	ahead of the data it actually produces. All three can be tuned at compile time with `-define`.

	The caller still has the final say. Pass in a dynamic array that's already reserved, and if
	its capacity exceeds what we'd reserve, we use it as is and only grow it once the output
	outgrows it. Reserve the full expected size up front and the buffer never needs to regrow
	or be copied, which wins back the throughput the conservative defaults give up, at whatever
	memory cost you're willing to bear.

	For reference, the largest payload size of a GZIP file is 4 GiB.

*/
when size_of(uintptr) == 8 {

	// For 64-bit platforms, we set the default max buffer size to 4 GiB,
	// which is GZIP and PKZIP's max payload size.
	COMPRESS_OUTPUT_ALLOCATE_MAX :: int(#config(COMPRESS_OUTPUT_ALLOCATE_MAX, 1 << 32))
} else {

	// For 32-bit platforms, we set the default max buffer size to 512 MiB.
	COMPRESS_OUTPUT_ALLOCATE_MAX :: int(#config(COMPRESS_OUTPUT_ALLOCATE_MAX, 1 << 29))
}

COMPRESS_RESERVE_DEFAULT           :: 64 * 1024
COMPRESS_INITIAL_RESERVATION       :: int(#config(COMPRESS_INITIAL_RESERVATION, 16 * 1024 * 1024))
COMPRESS_INITIAL_RESERVATION_RATIO :: int(#config(COMPRESS_INITIAL_RESERVATION_RATIO, 4))
COMPRESS_GROWTH_MIN                :: 4 * 1024
COMPRESS_GROWTH_STEP               :: 16 * 1024 * 1024
#assert(COMPRESS_INITIAL_RESERVATION_RATIO >= 1 && COMPRESS_INITIAL_RESERVATION_RATIO <= 4)

DEFLATE_EXPANSION_MAX   :: 1032
DEFLATE64_EXPANSION_MAX :: 29128
LZ4_EXPANSION_MAX       :: 255
BZIP2_EXPANSION_MAX     :: 2_331_000
SHRINK_EXPANSION_MAX    :: 8192
REDUCE_EXPANSION_MAX    :: 512
IMPLODE_EXPANSION_MAX   :: 256
LZMA_EXPANSION_MAX      :: 7168

Error :: union #shared_nil {
	General_Error,
	Deflate_Error,
	ZLIB_Error,
	GZIP_Error,
	LZ4_Error,
	BZip2_Error,
	PKZIP_Legacy_Error,
	LZMA_Error,
	PPMd_Error,
	io.Error,
	runtime.Allocator_Error,
}

General_Error :: enum {
	None = 0,
	File_Not_Found,
	Cannot_Open_File,
	File_Too_Short,
	Stream_Too_Short,
	Output_Too_Short,
	Unknown_Compression_Method,
	Checksum_Failed,
	Incompatible_Options,
	Unimplemented,

	// Memory errors

	Allocation_Failed,

	// For buffered instead of streamed output, the payload size can't exceed
	// the max set by the `COMPRESS_OUTPUT_ALLOCATE_MAX` switch in compress/common.odin.
	//
	// You can tweak this setting using `-define:COMPRESS_OUTPUT_ALLOCATE_MAX=size_in_bytes`

	Output_Exceeds_COMPRESS_OUTPUT_ALLOCATE_MAX,
}

GZIP_Error :: enum {
	None = 0,
	Invalid_GZIP_Signature,
	Reserved_Flag_Set,
	Invalid_Extra_Data,
	Original_Name_Too_Long,
	Comment_Too_Long,
	Header_CRC_Invalid,
	Payload_Length_Invalid,
	Payload_CRC_Invalid,
}

LZ4_Error :: enum {
	None = 0,
	Invalid_Magic,
	Unsupported_Version,
	Reserved_Bit_Set,
	Invalid_Block_Max_Size,
	Header_Checksum_Failed,
	Block_Checksum_Failed,
	Content_Checksum_Failed,
	Content_Size_Mismatch,
	Block_Too_Large,
	Dictionary_Required,
	Invalid_Offset,
	Offset_Out_Of_Range,
	Literal_Overrun,
	Input_Too_Large,
}

BZip2_Error :: enum {
	None = 0,
	Invalid_Magic,
	Invalid_Block_Magic,
	Invalid_Original_Pointer,
	No_Symbols_In_Use,
	Invalid_Group_Count,
	Invalid_Selector_Count,
	Invalid_Selector,
	Invalid_Code_Length,
	Invalid_Huffman_Code,
	Selectors_Exhausted,
	Run_Too_Long,
	Block_Too_Large,
	Block_Checksum_Failed,
	Stream_Checksum_Failed,
	Input_Too_Large,
}

LZMA_Error :: enum {
	None = 0,
	Invalid_Properties,
	Invalid_Header,
	Corrupt_Range_Coder,
	Invalid_Distance,
	Unexpected_End_Marker,
	Size_Mismatch,
	Invalid_Chunk,
	Input_Too_Large,
}

PKZIP_Legacy_Error :: enum {
	None = 0,
	Invalid_First_Code,
	Invalid_Control_Code,
	Code_Size_Too_Large,
	Invalid_Code,
	Invalid_Follower_Set,
	Invalid_Follower_Index,
	Invalid_Tree,
}

PPMd_Error :: enum {
	None = 0,
	Invalid_Properties,
	Corrupt_Data,
	Unexpected_End_Marker,
	Memory_Limit_Exceeded,
}

ZLIB_Error :: enum {
	None = 0,
	Unsupported_Window_Size,
	FDICT_Unsupported,
	Code_Buffer_Malformed,
}

Deflate_Error :: enum {
	None = 0,
	Huffman_Bad_Sizes,
	Huffman_Bad_Code_Lengths,
	Bad_Distance,
	Bad_Huffman_Code,
	Len_Nlen_Mismatch,
	BType_3,
}