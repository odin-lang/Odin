#+private
package archive_tar

import "core:archive"
import "core:io"

RECORD_SIZE       :: 20 * BLOCK_SIZE
WRITE_CHUNK_SIZE  :: 64 * 1024
USTAR_NAME_MAX    :: 100
USTAR_PREFIX_MAX  :: 155
USTAR_OWNER_MAX   :: 32
USTAR_SIZE_MAX    :: 0o777_7777_7777
USTAR_ID_MAX      :: 0o777_7777
BUFFER_SIZE       :: 64 * 1024
HEAD_SIZE         :: 1024
MEMBER_SIZE_MAX   :: max(i64) - BLOCK_SIZE
GNU_MAGIC         :: "ustar  \x00"
GNU_LONG_NAME     :: "././@LongLink"
GNU_BASE256_8_MAX :: 1 << 56 - 1
SPARSE_IN_HEADER  :: 4
SPARSE_IN_BLOCK   :: 21
ZERO_CHUNK_SIZE   :: 8 * 1024

Sparse_Region :: struct {
	offset: i64,
	size:   i64,
}

Global_Key :: enum u8 {
	Path,
	Link_Path,
	User,
	Group,
	Comment,
	Size,
	Uid,
	Gid,
	Modification_Time,
	Access_Time,
	Creation_Time,
}

@(rodata)
GLOBAL_KEYS := [Global_Key]string{
	.Path              = "path",
	.Link_Path         = "linkpath",
	.User              = "uname",
	.Group             = "gname",
	.Comment           = "comment",
	.Size              = "size",
	.Uid               = "uid",
	.Gid               = "gid",
	.Modification_Time = "mtime",
	.Access_Time       = "atime",
	.Creation_Time     = "LIBARCHIVE.creationtime",
}

Source :: enum u8 {
	Memory,
	Stream,
	Decoder,
}

Prefix_Stream :: struct {
	prefix: []u8,
	pos:    int,
	stream: io.Stream,
	err:    io.Error,
}

Long_Kind :: enum u8 {
	Name,
	Link,
}

Pax_Sparse :: struct {
	major:      string,
	minor:      string,
	name:       string,
	size:       string,
	numblocks:  string,
	sparse_map: string,
	has_map:    bool,
	has_pairs:  bool,
	has_keys:   bool,
}

Pending_Entry :: struct {
	name:      string,
	type:      archive.Entry_Type,
	typeflag:  u8,
	size:      i64,
	next:      i64,
	long_name: bool,
	long_link: bool,
}

Sniffed :: enum u8 {
	Unknown,
	Plain,
	Gzip,
	BZip2,
	LZ4,
	LZMA,
	XZ,
}
