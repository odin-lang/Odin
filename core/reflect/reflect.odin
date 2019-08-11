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


index :: proc(v: any, i: int, loc := #caller_location) -> any {
	if v == nil do return nil;

	v := v;
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
	for tag := tag; tag != ""; /**/ {
		i := 0;
		for i < len(tag) && tag[i] == ' ' { // Skip whitespace
			i += 1;
		}
		tag = tag[i:];
		if len(tag) == 0 do break;

		i = 0;
		loop: for i < len(tag) {
			switch tag[i] {
			case ':', '"':
				break loop;
			case 0x00 ..< ' ', 0x7f .. 0x9f: // break if control character is found
				break loop;
			}
			i += 1;
		}

		if i == 0 do break;
		if i+1 >= len(tag) do break;

		if tag[i] != ':' || tag[i+1] != '"' {
			break;
		}
		name := string(tag[:i]);
		tag = tag[i+1:];

		i = 1;
		for i < len(tag) && tag[i] != '"' { // find closing quote
			if tag[i] == '\\' do i += 1; // Skip escaped characters
			i += 1;
		}

		if i >= len(tag) do break;

		val := string(tag[:i+1]);
		tag = tag[i+1:];

		if key == name {
			return val[1:i], true;
		}
	}
	return;
}
