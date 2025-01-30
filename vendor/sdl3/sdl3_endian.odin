package sdl3

import "base:intrinsics"

LIL_ENDIAN :: 1234
BIG_ENDIAN :: 4321

BYTEORDER :: LIL_ENDIAN when ODIN_ENDIAN == .Little else BIG_ENDIAN

@(require_results) Swap16    :: #force_inline proc "c" (x: Uint16) -> Uint16 { return intrinsics.byte_swap(x) }
@(require_results) Swap32    :: #force_inline proc "c" (x: Uint32) -> Uint32 { return intrinsics.byte_swap(x) }
@(require_results) Swap64    :: #force_inline proc "c" (x: Uint64) -> Uint64 { return intrinsics.byte_swap(x) }
@(require_results) SwapFloat :: #force_inline proc "c" (x: f32)    -> f32    { return intrinsics.byte_swap(x) }


@(require_results) Swap16LE    :: #force_inline proc "c" (x: Uint16) -> Uint16 { return Uint16(transmute(u16le)x) }
@(require_results) Swap32LE    :: #force_inline proc "c" (x: Uint32) -> Uint32 { return Uint32(transmute(u32le)x) }
@(require_results) Swap64LE    :: #force_inline proc "c" (x: Uint64) -> Uint64 { return Uint64(transmute(u64le)x) }
@(require_results) SwapFloatLE :: #force_inline proc "c" (x: f32)    -> f32    { return f32   (transmute(f32le)x) }

@(require_results) Swap16BE    :: #force_inline proc "c" (x: Uint16) -> Uint16 { return Uint16(transmute(u16be)x) }
@(require_results) Swap32BE    :: #force_inline proc "c" (x: Uint32) -> Uint32 { return Uint32(transmute(u32be)x) }
@(require_results) Swap64BE    :: #force_inline proc "c" (x: Uint64) -> Uint64 { return Uint64(transmute(u64be)x) }
@(require_results) SwapFloatBE :: #force_inline proc "c" (x: f32)    -> f32    { return f32   (transmute(f32be)x) }