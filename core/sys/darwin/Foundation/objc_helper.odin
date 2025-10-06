package objc_Foundation

import "base:runtime"
import "base:intrinsics"

Subclasser_Proc :: proc(cls: Class, vtable: rawptr)

Object_VTable_Info :: struct {
	vtable: rawptr,
	size:   uint,
	impl:   Subclasser_Proc,
}

Class_VTable_Info :: struct {
	_context:    runtime.Context,
	super_vtable:    rawptr,
	protocol_vtable: rawptr,
}

@(require_results)
class_get_metaclass :: #force_inline proc "contextless" (cls: Class) -> Class {
	return (^Class)(cls)^
}

@(require_results)
object_get_vtable_info :: proc "contextless" (obj: id) -> ^Class_VTable_Info {
	return (^Class_VTable_Info)(object_getIndexedIvars(obj))
}

@(require_results)
make_subclasser :: #force_inline proc(vtable: ^$T, impl: proc(cls: Class, vt: ^T)) -> Object_VTable_Info {
	return Object_VTable_Info{
		vtable = vtable,
		size   = size_of(T),
		impl   = (Subclasser_Proc)(impl),
	}
}

@(require_results)
register_subclass :: proc(
	class_name:           cstring,
	superclass:           Class,
	superclass_overrides: Maybe(Object_VTable_Info) = nil,
	protocol:             Maybe(Object_VTable_Info) = nil,
	_context:             Maybe(runtime.Context)    = nil,
) -> Class {
	assert(superclass != nil)

	super_size: uint
	proto_size: uint

	if superclass_overrides != nil {
		// Align to 8-byte boundary
		super_size = (superclass_overrides.?.size + 7)/8 * 8
	}

	if protocol != nil {
		// Align to 8-byte boundary
		proto_size = (protocol.?.size + 7)/8 * 8
	}

	cls := objc_lookUpClass(class_name)
	if cls != nil {
		return cls
	}

	extra_size := uint(size_of(Class_VTable_Info)) + 8 + super_size + proto_size

	cls = objc_allocateClassPair(superclass, class_name, extra_size)
	assert(cls != nil)

	if s, ok := superclass_overrides.?; ok {
		s.impl(cls, s.vtable)
	}

	if p, ok := protocol.?; ok {
		p.impl(cls, p.vtable)
	}

	objc_registerClassPair(cls)
	meta_cls    := class_get_metaclass(cls)
	meta_size   := uint(class_getInstanceSize(meta_cls))

	// Offsets are always aligned to 8-byte boundary
	info_offset         := (meta_size + 7) / 8 * 8
	super_vtable_offset := (info_offset + size_of(Class_VTable_Info) + 7) / 8 * 8
	ptoto_vtable_offset := super_vtable_offset + super_size


	p_info := (^Class_VTable_Info)(([^]u8)(cls)[info_offset:])
	p_super_vtable := ([^]u8)(cls)[super_vtable_offset:]
	p_proto_vtable := ([^]u8)(cls)[ptoto_vtable_offset:]

	intrinsics.mem_zero(p_info, size_of(Class_VTable_Info))

	// Assign the context
	p_info._context = _context.? or_else context

	if s, ok := superclass_overrides.?; ok {
		p_info.super_vtable = p_super_vtable
		intrinsics.mem_copy(p_super_vtable, s.vtable, super_size)
	}
	if p, ok := protocol.?; ok {
		p_info.protocol_vtable = p_proto_vtable
		intrinsics.mem_copy(p_proto_vtable, p.vtable, p.size)
	}

	return cls
}

@(require_results)
class_get_vtable_info :: proc "contextless" (cls: Class) -> ^Class_VTable_Info {
	meta_cls  := class_get_metaclass(cls)
	meta_size := uint(class_getInstanceSize(meta_cls))

	// Align to 8-byte boundary
	info_offset := (meta_size+7) / 8 * 8

	p_cls := ([^]u8)(cls)[info_offset:]
	ctx := (^Class_VTable_Info)(p_cls)
	return ctx
}

@(require_results)
alloc_user_object :: proc "contextless" (cls: Class, _context: Maybe(runtime.Context) = nil) -> id {
	info := class_get_vtable_info(cls)

	obj := class_createInstance(cls, size_of(Class_VTable_Info))
	obj_info := (^Class_VTable_Info)(object_getIndexedIvars(obj))
	obj_info^ = info^

	if _context != nil {
		obj_info._context = _context.?
	}
	return obj
}