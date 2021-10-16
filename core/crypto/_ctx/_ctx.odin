package _ctx

/*
    Copyright 2021 zhibog
    Made available under the BSD-3 license.

    List of contributors:
        zhibog: Initial creation and testing of the bindings.

    Implementation of the context, used internally by the crypto library.
*/

import "core:io"
import "core:os"

Hash_Size :: enum {
    _16,
    _20,
    _24,
    _28,
    _32,
    _40,
    _48,
    _64,
    _128,
}

Hash_Context :: struct {
    botan_hash_algo: cstring,
    external_ctx:    any,
    internal_ctx:    any,
    hash_size:       Hash_Size,
    hash_size_val:   int,
    is_using_odin:   bool,
    using vtbl:      ^Hash_Context_Vtable,
}

Hash_Context_Vtable :: struct {
    hash_bytes_16     : proc (ctx: ^Hash_Context, input: []byte) -> [16]byte,
    hash_bytes_20     : proc (ctx: ^Hash_Context, input: []byte) -> [20]byte,
    hash_bytes_24     : proc (ctx: ^Hash_Context, input: []byte) -> [24]byte,
    hash_bytes_28     : proc (ctx: ^Hash_Context, input: []byte) -> [28]byte,
    hash_bytes_32     : proc (ctx: ^Hash_Context, input: []byte) -> [32]byte,
    hash_bytes_40     : proc (ctx: ^Hash_Context, input: []byte) -> [40]byte,
    hash_bytes_48     : proc (ctx: ^Hash_Context, input: []byte) -> [48]byte,
    hash_bytes_64     : proc (ctx: ^Hash_Context, input: []byte) -> [64]byte,
    hash_bytes_128    : proc (ctx: ^Hash_Context, input: []byte) -> [128]byte,
    hash_file_16      : proc (ctx: ^Hash_Context, hd: os.Handle, load_at_once := false) -> ([16]byte,  bool),
    hash_file_20      : proc (ctx: ^Hash_Context, hd: os.Handle, load_at_once := false) -> ([20]byte,  bool),
    hash_file_24      : proc (ctx: ^Hash_Context, hd: os.Handle, load_at_once := false) -> ([24]byte,  bool),
    hash_file_28      : proc (ctx: ^Hash_Context, hd: os.Handle, load_at_once := false) -> ([28]byte,  bool),
    hash_file_32      : proc (ctx: ^Hash_Context, hd: os.Handle, load_at_once := false) -> ([32]byte,  bool),
    hash_file_40      : proc (ctx: ^Hash_Context, hd: os.Handle, load_at_once := false) -> ([40]byte,  bool),
    hash_file_48      : proc (ctx: ^Hash_Context, hd: os.Handle, load_at_once := false) -> ([48]byte,  bool),
    hash_file_64      : proc (ctx: ^Hash_Context, hd: os.Handle, load_at_once := false) -> ([64]byte,  bool),
    hash_file_128     : proc (ctx: ^Hash_Context, hd: os.Handle, load_at_once := false) -> ([128]byte, bool),
    hash_stream_16    : proc (ctx: ^Hash_Context, s: io.Stream)  -> ([16]byte,  bool),
    hash_stream_20    : proc (ctx: ^Hash_Context, s: io.Stream)  -> ([20]byte,  bool),
    hash_stream_24    : proc (ctx: ^Hash_Context, s: io.Stream)  -> ([24]byte,  bool),
    hash_stream_28    : proc (ctx: ^Hash_Context, s: io.Stream)  -> ([28]byte,  bool),
    hash_stream_32    : proc (ctx: ^Hash_Context, s: io.Stream)  -> ([32]byte,  bool),
    hash_stream_40    : proc (ctx: ^Hash_Context, s: io.Stream)  -> ([40]byte,  bool),
    hash_stream_48    : proc (ctx: ^Hash_Context, s: io.Stream)  -> ([48]byte,  bool),
    hash_stream_64    : proc (ctx: ^Hash_Context, s: io.Stream)  -> ([64]byte,  bool),
    hash_stream_128   : proc (ctx: ^Hash_Context, s: io.Stream)  -> ([128]byte, bool),
    hash_bytes_slice  : proc (ctx: ^Hash_Context, input: []byte, out_size: int, allocator := context.allocator) -> []byte,
    hash_file_slice   : proc (ctx: ^Hash_Context, hd: os.Handle, out_size: int, load_at_once := false, allocator := context.allocator) -> ([]byte, bool),
    hash_stream_slice : proc (ctx: ^Hash_Context, s: io.Stream,  out_size: int, allocator := context.allocator) -> ([]byte, bool),
    init              : proc (ctx: ^Hash_Context),
    update            : proc (ctx: ^Hash_Context, data: []byte),
    final             : proc (ctx: ^Hash_Context, hash: []byte),
}

_init_vtable :: #force_inline proc() -> ^Hash_Context {
    ctx     := new(Hash_Context)
    vtbl    := new(Hash_Context_Vtable)
    ctx.vtbl = vtbl
    return ctx
}