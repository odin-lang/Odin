package objc_Foundation

import "core:intrinsics"

Internal_Block_Literal_Base :: struct {
	isa:        ^intrinsics.objc_class,
	flags:      u32,
	reserved:   u32,
	invoke:     proc "c" (^Internal_Block_Literal),
	descriptor: ^Block_Descriptor,
}

Internal_Block_Literal :: struct {
	using base: Internal_Block_Literal_Base,
	// Imported Variables
	user_proc:  proc "c" (user_data: rawptr),
	user_data:  rawptr,
}

Block_Descriptor :: struct {
	reserved:       uint,
	size:           uint,
	copy_helper:    proc "c" (dst, src: rawptr),
	dispose_helper: proc "c" (src: rawptr),
	signature:      cstring,
}

global_block_descriptor := Block_Descriptor{
	reserved = 0,
	size     = size_of(Internal_Block_Literal),
}


@(objc_class="NSConcreteGlobalBlock")
Block :: struct {using _: Object}


@(private="file")
Block_createInternal :: proc "c" (is_global: bool, user_data: rawptr, user_proc: proc "c" (user_data: rawptr)) -> ^Block {
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

	extraBytes :: size_of(Internal_Block_Literal) - size_of(Internal_Block_Literal_Base)

	cls := intrinsics.objc_find_class("NSConcreteGlobalBlock")
	bl := (^Internal_Block_Literal)(AllocateObject(cls, extraBytes, nil))
	bl.isa = cls
	bl.flags = BLOCK_IS_GLOBAL if is_global else 0
	bl.invoke = proc "c" (bl: ^Internal_Block_Literal) {
		bl.user_proc(bl.user_data)
	}
	bl.descriptor = &global_block_descriptor
	bl.user_proc = user_proc
	bl.user_data = user_data

	return auto_cast bl
}

@(objc_type=Block, objc_name="createGlobal", objc_is_class_method=true)
Block_createGlobal :: proc "c" (user_data: rawptr, user_proc: proc "c" (user_data: rawptr)) -> ^Block {
	return Block_createInternal(true, user_data, user_proc)
}


@(objc_type=Block, objc_name="createLocal", objc_is_class_method=true)
Block_createLocal :: proc "c" (user_data: rawptr, user_proc: proc "c" (user_data: rawptr)) -> ^Block {
	return Block_createInternal(false, user_data, user_proc)
}
