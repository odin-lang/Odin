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

	This bounds the maximum a buffer will resize to as needed, or the maximum we'll
	pre-allocate if you inform the decompression routine you know the payload size.

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

Error :: union #shared_nil {
	General_Error,
	Deflate_Error,
	ZLIB_Error,
	GZIP_Error,
	LZ4_Error,
	BZip2_Error,
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