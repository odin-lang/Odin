package objc_Foundation

import "base:intrinsics"
import "base:builtin"
import "core:mem"

@(objc_class="NSBlock")
Block :: struct {using _: Object}

@(objc_type=Block, objc_name="createGlobal", objc_is_class_method=true)
Block_createGlobal :: proc (user_data: rawptr, user_proc: proc "c" (user_data: rawptr), allocator := context.allocator) -> (^Block, mem.Allocator_Error) #optional_allocator_error {
	return Block_createInternal(true, user_data, user_proc, allocator)
}
@(objc_type=Block, objc_name="createLocal", objc_is_class_method=true)
Block_createLocal :: proc (user_data: rawptr, user_proc: proc "c" (user_data: rawptr)) -> ^Block {
	b, _ := Block_createInternal(false, user_data, user_proc, {})
	return b
}
@(objc_type=Block, objc_name="createGlobalWithParam", objc_is_class_method=true)
Block_createGlobalWithParam :: proc (user_data: rawptr, user_proc: proc "c" (user_data: rawptr, t: $T), allocator := context.allocator) -> (^Block, mem.Allocator_Error) #optional_allocator_error {
	return Block_createInternalWithParam(true, user_data, user_proc, allocator)
}
@(objc_type=Block, objc_name="createLocalWithParam", objc_is_class_method=true)
Block_createLocalWithParam :: proc (user_data: rawptr, user_proc: proc "c" (user_data: rawptr, t: $T)) -> ^Block {
	b, _ := Block_createInternalWithParam(false, user_data, user_proc, {})
	return b
}
@(objc_type=Block, objc_name="invoke")
Block_invoke :: proc "c" (self: ^Block, args: ..any) -> ^Object {
	return msgSend(^Object, self, "invoke:", ..args)
}

@(private)
Internal_Block_Literal_Base :: struct {
	isa:        ^intrinsics.objc_class,
	flags:      u32,
	reserved:   u32,
	invoke:     rawptr, // contains a pointer to a proc "c" (^Internal_Block_Literal, ...)
	descriptor: ^Block_Descriptor,
}

@(private)
Internal_Block_Literal :: struct {
	using base: Internal_Block_Literal_Base,
	// Imported Variables
	user_proc:  rawptr, // contains a pointer to a proc "c" (user_data: rawptr, ...)
	user_data:  rawptr,
}

@(private)
Block_Descriptor :: struct {
	reserved:       uint,
	size:           uint,
	copy_helper:    proc "c" (dst, src: rawptr),
	dispose_helper: proc "c" (src: rawptr),
	signature:      cstring,
}

@(private)
global_block_descriptor := Block_Descriptor{
	reserved = 0,
	size     = size_of(Internal_Block_Literal),
}

foreign import libSystem "system:System.framework"
foreign libSystem {
	_NSConcreteGlobalBlock: intrinsics.objc_class
	_NSConcreteStackBlock: intrinsics.objc_class
}

@(private="file")
internal_block_literal_make :: proc (is_global: bool, user_data: rawptr, user_proc: rawptr, invoke: rawptr, allocator: mem.Allocator) ->  (b: ^Block, err: mem.Allocator_Error) {
	_init :: proc(bl: ^Internal_Block_Literal, is_global: bool, user_data: rawptr, user_proc: rawptr, invoke: rawptr) {
		// Set to true on blocks that have captures (and thus are not true
		// global blocks) but are known not to escape for various other
		// reasons. For backward compatibility with old runtimes, whenever
		// BLOCK_IS_NOESCAPE is set, BLOCK_IS_GLOBAL is set too. Copying a
		// non-escaping block returns the original block and releasing such a
		// block is a no-op, which is exactly how global blocks are handled.
		BLOCK_IS_NOESCAPE      :: (1 << 23)|BLOCK_IS_GLOBAL

		BLOCK_HAS_COPY_DISPOSE :: 1 << 25
		BLOCK_HAS_CTOR         :: 1 << 26 // helpers have C++ code
		BLOCK_IS_GLOBAL        :: 1 << 28
		BLOCK_HAS_STRET        :: 1 << 29 // IFF BLOCK_HAS_SIGNATURE
		BLOCK_HAS_SIGNATURE    :: 1 << 30

		bl.isa = is_global ? &_NSConcreteGlobalBlock : &_NSConcreteStackBlock
		bl.flags = BLOCK_IS_GLOBAL if is_global else 0
		bl.invoke = invoke
		bl.descriptor = &global_block_descriptor
		bl.user_proc = auto_cast user_proc
		bl.user_data = user_data
	}
	if is_global {
		bl := builtin.new (Internal_Block_Literal, allocator) or_return
		_init(bl, true, user_data, user_proc, invoke)
		return auto_cast bl, .None
	} else {
		// malloc blocks are created by calling 'copy' on a stack block
		bl: Internal_Block_Literal
		_init(&bl, false, user_data, user_proc, invoke)
		return auto_cast copy(cast(^Copying(Block))(&bl)), .None
	}
}

@(private="file")
Block_createInternal :: proc (is_global: bool, user_data: rawptr, user_proc: proc "c" (user_data: rawptr), allocator: mem.Allocator) -> (b: ^Block, err: mem.Allocator_Error) {
	invoke :: proc "c" (bl: ^Internal_Block_Literal) {
		user_proc := (proc "c" (rawptr))(bl.user_proc)
		user_proc(bl.user_data)
	}
	return internal_block_literal_make(is_global, user_data, auto_cast user_proc, auto_cast invoke, allocator)
}

@(private="file")
Block_createInternalWithParam :: proc (is_global: bool, user_data: rawptr, user_proc: proc "c" (user_data: rawptr, t: $T), allocator: mem.Allocator) -> (b: ^Block, err: mem.Allocator_Error) {
	invoke :: proc "c" (bl: ^Internal_Block_Literal, t: T) {
		user_proc := (proc "c" (rawptr, T))(bl.user_proc)
		user_proc(bl.user_data, t)
	}
	return internal_block_literal_make(is_global, user_data, auto_cast user_proc, auto_cast invoke, allocator)
}

