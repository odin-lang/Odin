package encoding_toml

import "base:runtime"
import "core:io"
import "core:mem"
import "core:reflect"

Null :: distinct rawptr
Integer :: i64
Float :: f64
Boolean :: bool
String :: string
Offset_DateTime :: distinct string
Local_DateTime :: distinct string
Local_Date :: distinct string
Local_Time :: distinct string
Array :: distinct [dynamic]Value
Table :: distinct map[string]Value

Value :: union {
	Null,
	Integer,
	Float,
	Boolean,
	String,
	Offset_DateTime,
	Local_DateTime,
	Local_Date,
	Local_Time,
	Array,
	Table,
}

Parse_Error :: enum {
	None,
	Invalid_Data,
	Invalid_Key,
	Invalid_Value,
	Duplicate_Key,
	Duplicate_Table,
	Invalid_Table,
	Invalid_String,
	Unterminated_String,
	Unterminated_Array,
	Unterminated_Inline_Table,
	Expected_Equals,
	Expected_Section_Close,
	Maximum_Depth,
	Out_Of_Memory,
}

Marshal_Data_Error :: enum {
	None,
	Unsupported_Type,
	Non_Finite_Float,
	Invalid_Key,
}

Marshal_Error :: union #shared_nil {
	Marshal_Data_Error,
	io.Error,
	runtime.Allocator_Error,
}

Unmarshal_Data_Error :: enum {
	None,
	Invalid_Parameter,
	Non_Pointer_Parameter,
	Unknown_Field,
	Type_Mismatch,
	Unsupported_Type,
	Integer_Out_Of_Range,
}

Unmarshal_Error :: union {
	Parse_Error,
	Unmarshal_Data_Error,
	runtime.Allocator_Error,
}

Marshal_Options :: struct {
	pretty:           bool,
	sort_maps_by_key: bool,
}

destroy_value :: proc(value: Value, allocator := context.allocator) {
	#partial switch v in value {
	case Table:
		for key, elem in v {
			delete(key, allocator)
			destroy_value(elem, allocator)
		}
		delete(v)
	case Array:
		for elem in v {
			destroy_value(elem, allocator)
		}
		delete(v)
	case String:
		delete(v, allocator)
	case Offset_DateTime:
		delete(string(v), allocator)
	case Local_DateTime:
		delete(string(v), allocator)
	case Local_Date:
		delete(string(v), allocator)
	case Local_Time:
		delete(string(v), allocator)
	}
}

/*
Recursively releases allocations owned by a TOML string, generic `Value`, or value
whose type contains allocated fields.

Example:
	data, err := toml.marshal(config)
	defer toml.destroy(data)

	var decoded Config
	err = toml.unmarshal(data, &decoded)
	defer toml.destroy(&decoded)
*/
destroy :: proc(v: any, allocator := context.allocator) {
	if v == nil {return}
	ti := reflect.type_info_base(type_info_of(v.id))

	#partial switch info in ti.variant {
	case ^runtime.Type_Info_Named:
		destroy(any{v.data, info.base.id}, allocator)
	case ^runtime.Type_Info_Pointer:
		if ptr := (^rawptr)(v.data)^; ptr != nil {
			destroy(any{ptr, info.elem.id}, allocator)
		}
	case ^runtime.Type_Info_String:
		switch s in v {
		case string:
			delete(s, allocator)
		case cstring:
			delete(s, allocator)
		}
	case ^runtime.Type_Info_Dynamic_Array:
		raw := (^runtime.Raw_Dynamic_Array)(v.data)
		elem_ti := info.elem
		for i in 0 ..< raw.len {
			elem := rawptr(uintptr(raw.data) + uintptr(i) * uintptr(elem_ti.size))
			destroy(any{elem, elem_ti.id}, allocator)
		}
		mem.free(raw.data, allocator)
		raw^ = {}
	case ^runtime.Type_Info_Slice:
		raw := (^runtime.Raw_Slice)(v.data)
		elem_ti := info.elem
		for i in 0 ..< raw.len {
			elem := rawptr(uintptr(raw.data) + uintptr(i) * uintptr(elem_ti.size))
			destroy(any{elem, elem_ti.id}, allocator)
		}
		mem.free(raw.data, allocator)
		raw^ = {}
	case ^runtime.Type_Info_Map:
		it := 0
		for key, elem in reflect.iterate_map(v, &it) {
			destroy(key, allocator)
			destroy(elem, allocator)
		}
		_ = runtime.map_free_dynamic((^runtime.Raw_Map)(v.data)^, info.map_info)
	case ^runtime.Type_Info_Struct:
		for i in 0 ..< info.field_count {
			field := any{rawptr(uintptr(v.data) + info.offsets[i]), info.types[i].id}
			destroy(field, allocator)
		}
	case ^runtime.Type_Info_Array:
		elem_ti := info.elem
		for i in 0 ..< info.count {
			elem := rawptr(uintptr(v.data) + uintptr(i) * uintptr(elem_ti.size))
			destroy(any{elem, elem_ti.id}, allocator)
		}
	case ^runtime.Type_Info_Enumerated_Array:
		elem_ti := info.elem
		for i in 0 ..< info.count {
			elem := rawptr(uintptr(v.data) + uintptr(i) * uintptr(elem_ti.size))
			destroy(any{elem, elem_ti.id}, allocator)
		}
	case ^runtime.Type_Info_Union:
		if table, ok := v.(Value); ok {
			destroy_value(table, allocator)
		}
	}
}
