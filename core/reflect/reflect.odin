package reflect

import "core:runtime"
import "core:mem"


Type_Kind :: enum {
	Invalid,

	Named,
	Integer,
	Rune,
	Float,
	Complex,
	Quaternion,
	String,
	Boolean,
	Any,
	Type_Id,
	Pointer,
	Procedure,
	Array,
	Dynamic_Array,
	Slice,
	Tuple,
	Struct,
	Union,
	Enum,
	Map,
	Bit_Field,
	Bit_Set,
	Opaque,
	Simd_Vector,
}


type_kind :: proc(T: typeid) -> Type_Kind {
	ti := type_info_of(T);
	if ti != nil {
		#complete switch _ in ti.variant {
		case runtime.Type_Info_Named:         return .Named;
		case runtime.Type_Info_Integer:       return .Integer;
		case runtime.Type_Info_Rune:          return .Rune;
		case runtime.Type_Info_Float:         return .Float;
		case runtime.Type_Info_Complex:       return .Complex;
		case runtime.Type_Info_Quaternion:    return .Quaternion;
		case runtime.Type_Info_String:        return .String;
		case runtime.Type_Info_Boolean:       return .Boolean;
		case runtime.Type_Info_Any:           return .Any;
		case runtime.Type_Info_Type_Id:       return .Type_Id;
		case runtime.Type_Info_Pointer:       return .Pointer;
		case runtime.Type_Info_Procedure:     return .Procedure;
		case runtime.Type_Info_Array:         return .Array;
		case runtime.Type_Info_Dynamic_Array: return .Dynamic_Array;
		case runtime.Type_Info_Slice:         return .Slice;
		case runtime.Type_Info_Tuple:         return .Tuple;
		case runtime.Type_Info_Struct:        return .Struct;
		case runtime.Type_Info_Union:         return .Union;
		case runtime.Type_Info_Enum:          return .Enum;
		case runtime.Type_Info_Map:           return .Map;
		case runtime.Type_Info_Bit_Field:     return .Bit_Field;
		case runtime.Type_Info_Bit_Set:       return .Bit_Set;
		case runtime.Type_Info_Opaque:        return .Opaque;
		case runtime.Type_Info_Simd_Vector:   return .Simd_Vector;
		}

	}
	return .Invalid;
}

// TODO(bill): Better name
underlying_type_kind :: proc(T: typeid) -> Type_Kind {
	return type_kind(runtime.typeid_base(T));
}

// TODO(bill): Better name
backing_type_kind :: proc(T: typeid) -> Type_Kind {
	return type_kind(runtime.typeid_core(T));
}



size_of_typeid :: proc(T: typeid) -> int {
	if ti := type_info_of(T); ti != nil {
		return ti.size;
	}
	return 0;
}

align_of_typeid :: proc(T: typeid) -> int {
	if ti := type_info_of(T); ti != nil {
		return ti.align;
	}
	return 1;
}

to_bytes :: proc(v: any) -> []byte {
	if v != nil {
		sz := size_of_typeid(v.id);
		return mem.slice_ptr((^byte)(v.data), sz);
	}
	return nil;
}

any_data :: inline proc(v: any) -> (data: rawptr, id: typeid) {
	return v.data, v.id;
}

is_nil :: proc(v: any) -> bool {
	data := to_bytes(v);
	if data != nil {
		return true;
	}
	for v in data do if v != 0 {
		return false;
	}
	return true;
}

length :: proc(val: any) -> int {
	if val == nil do return 0;

	v := val;
	v.id = runtime.typeid_base(v.id);
	switch a in v {
	case runtime.Type_Info_Array:
		return a.count;

	case runtime.Type_Info_Slice:
		return (^mem.Raw_Slice)(v.data).len;

	case runtime.Type_Info_Dynamic_Array:
		return (^mem.Raw_Dynamic_Array)(v.data).len;

	case runtime.Type_Info_String:
		if a.is_cstring {
			return len((^cstring)(v.data)^);
		} else {
			return (^mem.Raw_String)(v.data).len;
		}
	}
	return 0;
}


index :: proc(val: any, i: int, loc := #caller_location) -> any {
	if val == nil do return nil;

	v := val;
	v.id = runtime.typeid_base(v.id);
	switch a in v {
	case runtime.Type_Info_Array:
		runtime.bounds_check_error_loc(loc, i, a.count);
		offset := uintptr(a.elem.size * i);
		data := rawptr(uintptr(v.data) + offset);
		return any{data, a.elem.id};

	case runtime.Type_Info_Slice:
		raw := (^mem.Raw_Slice)(v.data);
		runtime.bounds_check_error_loc(loc, i, raw.len);
		offset := uintptr(a.elem.size * i);
		data := rawptr(uintptr(raw.data) + offset);
		return any{data, a.elem.id};

	case runtime.Type_Info_Dynamic_Array:
		raw := (^mem.Raw_Dynamic_Array)(v.data);
		runtime.bounds_check_error_loc(loc, i, raw.len);
		offset := uintptr(a.elem.size * i);
		data := rawptr(uintptr(raw.data) + offset);
		return any{data, a.elem.id};

	case runtime.Type_Info_String:
		if a.is_cstring do return nil;

		raw := (^mem.Raw_String)(v.data);
		runtime.bounds_check_error_loc(loc, i, raw.len);
		offset := uintptr(size_of(u8) * i);
		data := rawptr(uintptr(raw.data) + offset);
		return any{data, typeid_of(u8)};
	}
	return nil;
}




Struct_Tag :: distinct string;

Struct_Field :: struct {
	name:   string,
	type:   typeid,
	tag:    Struct_Tag,
	offset: uintptr,
}

struct_field_at :: proc(T: typeid, i: int) -> (field: Struct_Field) {
	ti := runtime.type_info_base(type_info_of(T));
	if s, ok := ti.variant.(runtime.Type_Info_Struct); ok {
		if 0 <= i && i < len(s.names) {
			field.name   = s.names[i];
			field.type   = s.types[i].id;
			field.tag    = Struct_Tag(s.tags[i]);
			field.offset = s.offsets[i];
		}
	}
	return;
}

struct_field_by_name :: proc(T: typeid, name: string) -> (field: Struct_Field) {
	ti := runtime.type_info_base(type_info_of(T));
	if s, ok := ti.variant.(runtime.Type_Info_Struct); ok {
		for fname, i in s.names {
			if fname == name {
				field.name   = s.names[i];
				field.type   = s.types[i].id;
				field.tag    = Struct_Tag(s.tags[i]);
				field.offset = s.offsets[i];
				break;
			}
		}
	}
	return;
}

struct_field_value_by_name :: proc(a: any, field: string, recurse := false) -> any {
	if a == nil do return nil;

	ti := runtime.type_info_base(type_info_of(a.id));

	if s, ok := ti.variant.(runtime.Type_Info_Struct); ok {
		for name, i in s.names {
			if name == field {
				return any{
					rawptr(uintptr(a.data) + s.offsets[i]),
					s.types[i].id,
				};
			}

			if recurse && s.usings[i] {
				f := any{
					rawptr(uintptr(a.data) + s.offsets[i]),
					s.types[i].id,
				};

				if res := struct_field_value_by_name(f, field, recurse); res != nil {
					return res;
				}
			}
		}
	}
	return nil;
}



struct_field_names :: proc(T: typeid) -> []string {
	ti := runtime.type_info_base(type_info_of(T));
	if s, ok := ti.variant.(runtime.Type_Info_Struct); ok {
		return s.names;
	}
	return nil;
}

struct_field_types :: proc(T: typeid) -> []^runtime.Type_Info {
	ti := runtime.type_info_base(type_info_of(T));
	if s, ok := ti.variant.(runtime.Type_Info_Struct); ok {
		return s.types;
	}
	return nil;
}


struct_field_tags :: proc(T: typeid) -> []Struct_Tag {
	ti := runtime.type_info_base(type_info_of(T));
	if s, ok := ti.variant.(runtime.Type_Info_Struct); ok {
		return transmute([]Struct_Tag)s.tags;
	}
	return nil;
}

struct_field_offsets :: proc(T: typeid) -> []uintptr {
	ti := runtime.type_info_base(type_info_of(T));
	if s, ok := ti.variant.(runtime.Type_Info_Struct); ok {
		return s.offsets;
	}
	return nil;
}



struct_tag_get :: proc(tag: Struct_Tag, key: string) -> (value: string) {
	value, _ = struct_tag_lookup(tag, key);
	return;
}

struct_tag_lookup :: proc(tag: Struct_Tag, key: string) -> (value: string, ok: bool) {
	for t := tag; t != ""; /**/ {
		i := 0;
		for i < len(t) && t[i] == ' ' { // Skip whitespace
			i += 1;
		}
		t = t[i:];
		if len(t) == 0 do break;

		i = 0;
		loop: for i < len(t) {
			switch t[i] {
			case ':', '"':
				break loop;
			case 0x00 ..< ' ', 0x7f .. 0x9f: // break if control character is found
				break loop;
			}
			i += 1;
		}

		if i == 0 do break;
		if i+1 >= len(t) do break;

		if t[i] != ':' || t[i+1] != '"' {
			break;
		}
		name := string(t[:i]);
		t = t[i+1:];

		i = 1;
		for i < len(t) && t[i] != '"' { // find closing quote
			if t[i] == '\\' do i += 1; // Skip escaped characters
			i += 1;
		}

		if i >= len(t) do break;

		val := string(t[:i+1]);
		t = t[i+1:];

		if key == name {
			return val[1:i], true;
		}
	}
	return;
}


enum_string :: proc(a: any) -> string {
	if a == nil do return "";
	ti := runtime.type_info_base(type_info_of(a.id));
	if e, ok := ti.variant.(runtime.Type_Info_Enum); ok {
		for _, i in e.values {
			value := &e.values[i];
			n := mem.compare_byte_ptrs((^byte)(a.data), (^byte)(value), ti.size);
			if n == 0 {
				return e.names[i];
			}
		}
	} else {
		panic("expected an enum to reflect.enum_string");
	}

	return "";
}

union_variant_type_info :: proc(a: any) -> ^runtime.Type_Info {
	id := union_variant_typeid(a);
	return type_info_of(id);
}

union_variant_typeid :: proc(a: any) -> typeid {
	if a == nil do return nil;

	ti := runtime.type_info_base(type_info_of(a.id));
	if info, ok := ti.variant.(runtime.Type_Info_Union); ok {
		tag_ptr := uintptr(a.data) + info.tag_offset;
		tag_any := any{rawptr(tag_ptr), info.tag_type.id};

		tag: i64 = ---;
		switch i in tag_any {
		case u8:   tag = i64(i);
		case i8:   tag = i64(i);
		case u16:  tag = i64(i);
		case i16:  tag = i64(i);
		case u32:  tag = i64(i);
		case i32:  tag = i64(i);
		case u64:  tag = i64(i);
		case i64:  tag = i64(i);
		case: unimplemented();
		}

		if a.data != nil && tag != 0 {
			return info.variants[tag-1].id;
		}
	} else {
		panic("expected a union to reflect.union_variant_typeid");
	}

	return nil;
}
