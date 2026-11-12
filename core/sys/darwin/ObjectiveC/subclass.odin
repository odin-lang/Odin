#+build darwin
package darwin_ObjectiveC

import "base:intrinsics"
import "base:runtime"

/*
Helpers for registering Objective-C subclasses at runtime whose methods are implemented
with Odin procedures, without the `@(objc_implement)` attribute.

Each registered class stores a `Class_VTable_Info` after its metaclass data, and each
instance created with `alloc_user_object` stores a copy of it in its indexed ivars, so a
method implementation can recover its `runtime.Context` and the vtables it was given.
*/

Subclasser_Proc :: proc(cls: Class, vtable: rawptr)

Object_VTable_Info :: struct {
	vtable: rawptr,
	size:   uint,
	impl:   Subclasser_Proc,
}

Class_VTable_Info :: struct {
	_context:        runtime.Context,
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
object_get_super_vtable :: #force_inline proc "contextless" ($T: typeid, obj: id) -> ^T {
	return (^T)(object_get_vtable_info(obj).super_vtable)
}

@(require_results)
object_get_protocol_vtable :: #force_inline proc "contextless" ($T: typeid, obj: id) -> ^T {
	return (^T)(object_get_vtable_info(obj).protocol_vtable)
}

@(require_results)
make_subclasser :: #force_inline proc(vtable: ^$T, impl: proc(cls: Class, vt: ^T)) -> Object_VTable_Info {
	return Object_VTable_Info{
		vtable = vtable,
		size   = size_of(T),
		impl   = (Subclasser_Proc)(impl),
	}
}

/*
Registers `class_name` as a subclass of `superclass`, or returns the existing class of that name.

`superclass_overrides` and `protocol` add methods to the class through their `impl` procedures,
and their vtables are copied into the class so that `object_get_super_vtable` and
`object_get_protocol_vtable` can retrieve them.
*/
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

	if s, ok := superclass_overrides.?; ok {
		// Align to 8-byte boundary
		super_size = (s.size + 7)/8 * 8
	}

	if p, ok := protocol.?; ok {
		// Align to 8-byte boundary
		proto_size = (p.size + 7)/8 * 8
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
	meta_cls  := class_get_metaclass(cls)
	meta_size := uint(class_getInstanceSize(meta_cls))

	// Offsets are always aligned to 8-byte boundary
	info_offset         := (meta_size + 7) / 8 * 8
	super_vtable_offset := (info_offset + size_of(Class_VTable_Info) + 7) / 8 * 8
	proto_vtable_offset := super_vtable_offset + super_size

	p_info         := (^Class_VTable_Info)(([^]u8)(cls)[info_offset:])
	p_super_vtable := ([^]u8)(cls)[super_vtable_offset:]
	p_proto_vtable := ([^]u8)(cls)[proto_vtable_offset:]

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

	return (^Class_VTable_Info)(([^]u8)(cls)[info_offset:])
}

// Creates an instance of a class registered with `register_subclass`, optionally overriding its context.
@(require_results)
alloc_user_object :: proc "contextless" (cls: Class, _context: Maybe(runtime.Context) = nil) -> id {
	info := class_get_vtable_info(cls)

	obj := class_createInstance(cls, size_of(Class_VTable_Info))
	obj_info := (^Class_VTable_Info)(object_getIndexedIvars(obj))
	obj_info^ = info^

	if c, ok := _context.?; ok {
		obj_info._context = c
	}
	return obj
}
