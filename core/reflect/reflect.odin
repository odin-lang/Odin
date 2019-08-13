package reflect

import "core:runtime"
import "core:mem"
import "core:strings"


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


write_typeid :: proc(buf: ^strings.Builder, id: typeid) {
	write_type(buf, type_info_of(id));
}

write_type :: proc(buf: ^strings.Builder, ti: ^runtime.Type_Info) {
	using strings;
	if ti == nil {
		write_string(buf, "nil");
		return;
	}

	switch info in ti.variant {
	case runtime.Type_Info_Named:
		write_string(buf, info.name);
	case runtime.Type_Info_Integer:
		switch ti.id {
		case int:     write_string(buf, "int");
		case uint:    write_string(buf, "uint");
		case uintptr: write_string(buf, "uintptr");
		case:
			write_byte(buf, info.signed ? 'i' : 'u');
			write_i64(buf, i64(8*ti.size), 10);
			switch info.endianness {
			case runtime.Type_Info_Endianness.Little:
				write_string(buf, "le");
			case runtime.Type_Info_Endianness.Big:
				write_string(buf, "be");
			}
		}
	case runtime.Type_Info_Rune:
		write_string(buf, "rune");
	case runtime.Type_Info_Float:
		write_byte(buf, 'f');
		write_i64(buf, i64(8*ti.size), 10);
	case runtime.Type_Info_Complex:
		write_string(buf, "complex");
		write_i64(buf, i64(8*ti.size), 10);
	case runtime.Type_Info_String:
		if info.is_cstring {
			write_string(buf, "cstring");
		} else {
			write_string(buf, "string");
		}
	case runtime.Type_Info_Boolean:
		switch ti.id {
		case bool: write_string(buf, "bool");
		case:
			write_byte(buf, 'b');
			write_i64(buf, i64(8*ti.size), 10);
		}
	case runtime.Type_Info_Any:
		write_string(buf, "any");

	case runtime.Type_Info_Type_Id:
		write_string(buf, "typeid");

	case runtime.Type_Info_Pointer:
		if info.elem == nil {
			write_string(buf, "rawptr");
		} else {
			write_string(buf, "^");
			write_type(buf, info.elem);
		}
	case runtime.Type_Info_Procedure:
		write_string(buf, "proc");
		if info.params == nil {
			write_string(buf, "()");
		} else {
			t := info.params.variant.(runtime.Type_Info_Tuple);
			write_string(buf, "(");
			for t, i in t.types {
				if i > 0 do write_string(buf, ", ");
				write_type(buf, t);
			}
			write_string(buf, ")");
		}
		if info.results != nil {
			write_string(buf, " -> ");
			write_type(buf, info.results);
		}
	case runtime.Type_Info_Tuple:
		count := len(info.names);
		if count != 1 do write_string(buf, "(");
		for name, i in info.names {
			if i > 0 do write_string(buf, ", ");

			t := info.types[i];

			if len(name) > 0 {
				write_string(buf, name);
				write_string(buf, ": ");
			}
			write_type(buf, t);
		}
		if count != 1 do write_string(buf, ")");

	case runtime.Type_Info_Array:
		write_string(buf, "[");
		write_i64(buf, i64(info.count), 10);
		write_string(buf, "]");
		write_type(buf, info.elem);
	case runtime.Type_Info_Dynamic_Array:
		write_string(buf, "[dynamic]");
		write_type(buf, info.elem);
	case runtime.Type_Info_Slice:
		write_string(buf, "[]");
		write_type(buf, info.elem);

	case runtime.Type_Info_Map:
		write_string(buf, "map[");
		write_type(buf, info.key);
		write_byte(buf, ']');
		write_type(buf, info.value);

	case runtime.Type_Info_Struct:
		write_string(buf, "struct ");
		if info.is_packed    do write_string(buf, "#packed ");
		if info.is_raw_union do write_string(buf, "#raw_union ");
		if info.custom_align {
			write_string(buf, "#align ");
			write_i64(buf, i64(ti.align), 10);
			write_byte(buf, ' ');
		}
		write_byte(buf, '{');
		for name, i in info.names {
			if i > 0 do write_string(buf, ", ");
			write_string(buf, name);
			write_string(buf, ": ");
			write_type(buf, info.types[i]);
		}
		write_byte(buf, '}');

	case runtime.Type_Info_Union:
		write_string(buf, "union ");
		if info.custom_align {
			write_string(buf, "#align ");
			write_i64(buf, i64(ti.align), 10);
			write_byte(buf, ' ');
		}
		write_byte(buf, '{');
		for variant, i in info.variants {
			if i > 0 do write_string(buf, ", ");
			write_type(buf, variant);
		}
		write_byte(buf, '}');

	case runtime.Type_Info_Enum:
		write_string(buf, "enum ");
		write_type(buf, info.base);
		write_string(buf, " {");
		for name, i in info.names {
			if i > 0 do write_string(buf, ", ");
			write_string(buf, name);
		}
		write_byte(buf, '}');

	case runtime.Type_Info_Bit_Field:
		write_string(buf, "bit_field ");
		if ti.align != 1 {
			write_string(buf, "#align ");
			write_i64(buf, i64(ti.align), 10);
			write_byte(buf, ' ');
		}
		write_string(buf, " {");
		for name, i in info.names {
			if i > 0 do write_string(buf, ", ");
			write_string(buf, name);
			write_string(buf, ": ");
			write_i64(buf, i64(info.bits[i]), 10);
		}
		write_byte(buf, '}');

	case runtime.Type_Info_Bit_Set:
		write_string(buf, "bit_set[");
		switch {
		case is_enum(info.elem):
			write_type(buf, info.elem);
		case is_rune(info.elem):
			write_encoded_rune(buf, rune(info.lower));
			write_string(buf, "..");
			write_encoded_rune(buf, rune(info.upper));
		case:
			write_i64(buf, info.lower, 10);
			write_string(buf, "..");
			write_i64(buf, info.upper, 10);
		}
		if info.underlying != nil {
			write_string(buf, "; ");
			write_type(buf, info.underlying);
		}
		write_byte(buf, ']');

	case runtime.Type_Info_Opaque:
		write_string(buf, "opaque ");
		write_type(buf, info.elem);

	case runtime.Type_Info_Simd_Vector:
		if info.is_x86_mmx {
			write_string(buf, "intrinsics.x86_mmx");
		} else {
			write_string(buf, "intrinsics.vector(");
			write_i64(buf, i64(info.count));
			write_string(buf, ", ");
			write_type(buf, info.elem);
			write_byte(buf, ')');
		}
	}
}

