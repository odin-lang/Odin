package reflect

import "core:runtime"
import "core:mem"

Type_Info :: runtime.Type_Info;

Type_Info_Named            :: runtime.Type_Info_Named;
Type_Info_Integer          :: runtime.Type_Info_Integer;
Type_Info_Rune             :: runtime.Type_Info_Rune;
Type_Info_Float            :: runtime.Type_Info_Float;
Type_Info_Complex          :: runtime.Type_Info_Complex;
Type_Info_Quaternion       :: runtime.Type_Info_Quaternion;
Type_Info_String           :: runtime.Type_Info_String;
Type_Info_Boolean          :: runtime.Type_Info_Boolean;
Type_Info_Any              :: runtime.Type_Info_Any;
Type_Info_Type_Id          :: runtime.Type_Info_Type_Id;
Type_Info_Pointer          :: runtime.Type_Info_Pointer;
Type_Info_Procedure        :: runtime.Type_Info_Procedure;
Type_Info_Array            :: runtime.Type_Info_Array;
Type_Info_Enumerated_Array :: runtime.Type_Info_Enumerated_Array;
Type_Info_Dynamic_Array    :: runtime.Type_Info_Dynamic_Array;
Type_Info_Slice            :: runtime.Type_Info_Slice;
Type_Info_Tuple            :: runtime.Type_Info_Tuple;
Type_Info_Struct           :: runtime.Type_Info_Struct;
Type_Info_Union            :: runtime.Type_Info_Union;
Type_Info_Enum             :: runtime.Type_Info_Enum;
Type_Info_Map              :: runtime.Type_Info_Map;
Type_Info_Bit_Field        :: runtime.Type_Info_Bit_Field;
Type_Info_Bit_Set          :: runtime.Type_Info_Bit_Set;
Type_Info_Opaque           :: runtime.Type_Info_Opaque;
Type_Info_Simd_Vector      :: runtime.Type_Info_Simd_Vector;
Type_Info_Relative_Pointer :: runtime.Type_Info_Relative_Pointer;
Type_Info_Relative_Slice   :: runtime.Type_Info_Relative_Slice;


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
	Enumerated_Array,
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
	Relative_Pointer,
	Relative_Slice,
}


type_kind :: proc(T: typeid) -> Type_Kind {
	ti := type_info_of(T);
	if ti != nil {
		switch _ in ti.variant {
		case Type_Info_Named:            return .Named;
		case Type_Info_Integer:          return .Integer;
		case Type_Info_Rune:             return .Rune;
		case Type_Info_Float:            return .Float;
		case Type_Info_Complex:          return .Complex;
		case Type_Info_Quaternion:       return .Quaternion;
		case Type_Info_String:           return .String;
		case Type_Info_Boolean:          return .Boolean;
		case Type_Info_Any:              return .Any;
		case Type_Info_Type_Id:          return .Type_Id;
		case Type_Info_Pointer:          return .Pointer;
		case Type_Info_Procedure:        return .Procedure;
		case Type_Info_Array:            return .Array;
		case Type_Info_Enumerated_Array: return .Enumerated_Array;
		case Type_Info_Dynamic_Array:    return .Dynamic_Array;
		case Type_Info_Slice:            return .Slice;
		case Type_Info_Tuple:            return .Tuple;
		case Type_Info_Struct:           return .Struct;
		case Type_Info_Union:            return .Union;
		case Type_Info_Enum:             return .Enum;
		case Type_Info_Map:              return .Map;
		case Type_Info_Bit_Field:        return .Bit_Field;
		case Type_Info_Bit_Set:          return .Bit_Set;
		case Type_Info_Opaque:           return .Opaque;
		case Type_Info_Simd_Vector:      return .Simd_Vector;
		case Type_Info_Relative_Pointer: return .Relative_Pointer;
		case Type_Info_Relative_Slice:   return .Relative_Slice;
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


type_info_base :: proc(info: ^runtime.Type_Info) -> ^runtime.Type_Info {
	if info == nil do return nil;

	base := info;
	loop: for {
		#partial switch i in base.variant {
		case Type_Info_Named: base = i.base;
		case: break loop;
		}
	}
	return base;
}


type_info_core :: proc(info: ^runtime.Type_Info) -> ^runtime.Type_Info {
	if info == nil do return nil;

	base := info;
	loop: for {
		#partial switch i in base.variant {
		case Type_Info_Named:  base = i.base;
		case Type_Info_Enum:   base = i.base;
		case Type_Info_Opaque: base = i.elem;
		case: break loop;
		}
	}
	return base;
}
type_info_base_without_enum :: type_info_core;


typeid_base :: proc(id: typeid) -> typeid {
	ti := type_info_of(id);
	ti = type_info_base(ti);
	return ti.id;
}
typeid_core :: proc(id: typeid) -> typeid {
	ti := type_info_base_without_enum(type_info_of(id));
	return ti.id;
}
typeid_base_without_enum :: typeid_core;

typeid_elem :: proc(id: typeid) -> typeid {
	ti := type_info_of(id);
	if ti == nil do return nil;

	bits := 8*ti.size;

	#partial switch v in ti.variant {
	case Type_Info_Complex:
		switch bits {
		case 64:  return f32;
		case 128: return f64;
		}
	case Type_Info_Quaternion:
		switch bits {
		case 128: return f32;
		case 256: return f64;
		}
	case Type_Info_Pointer:          return v.elem.id;
	case Type_Info_Opaque:           return v.elem.id;
	case Type_Info_Array:            return v.elem.id;
	case Type_Info_Enumerated_Array: return v.elem.id;
	case Type_Info_Slice:            return v.elem.id;
	case Type_Info_Dynamic_Array:    return v.elem.id;
	}
	return id;
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

as_bytes :: proc(v: any) -> []byte {
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
	if v == nil {
		return true;
	}
	data := as_bytes(v);
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

	#partial switch a in type_info_of(val.id).variant {
	case Type_Info_Named:
		return length({val.data, a.base.id});

	case Type_Info_Pointer:
		return length({val.data, a.elem.id});

	case Type_Info_Array:
		return a.count;

	case Type_Info_Enumerated_Array:
		return a.count;

	case Type_Info_Slice:
		return (^mem.Raw_Slice)(val.data).len;

	case Type_Info_Dynamic_Array:
		return (^mem.Raw_Dynamic_Array)(val.data).len;

	case Type_Info_Map:
		return (^mem.Raw_Map)(val.data).entries.len;

	case Type_Info_String:
		if a.is_cstring {
			return len((^cstring)(val.data)^);
		} else {
			return (^mem.Raw_String)(val.data).len;
		}
	}
	return 0;
}

capacity :: proc(val: any) -> int {
	if val == nil do return 0;

	#partial switch a in type_info_of(val.id).variant {
	case Type_Info_Named:
		return capacity({val.data, a.base.id});

	case Type_Info_Pointer:
		return capacity({val.data, a.elem.id});

	case Type_Info_Array:
		return a.count;

	case Type_Info_Enumerated_Array:
		return a.count;

	case Type_Info_Dynamic_Array:
		return (^mem.Raw_Dynamic_Array)(val.data).cap;

	case Type_Info_Map:
		return (^mem.Raw_Map)(val.data).entries.cap;
	}
	return 0;
}


index :: proc(val: any, i: int, loc := #caller_location) -> any {
	if val == nil do return nil;

	#partial switch a in type_info_of(val.id).variant {
	case Type_Info_Named:
		return index({val.data, a.base.id}, i, loc);

	case Type_Info_Pointer:
		ptr := (^rawptr)(val.data)^;
		if ptr == nil {
			return nil;
		}
		return index({ptr, a.elem.id}, i, loc);

	case Type_Info_Array:
		runtime.bounds_check_error_loc(loc, i, a.count);
		offset := uintptr(a.elem.size * i);
		data := rawptr(uintptr(val.data) + offset);
		return any{data, a.elem.id};

	case Type_Info_Enumerated_Array:
		runtime.bounds_check_error_loc(loc, i, a.count);
		offset := uintptr(a.elem.size * i);
		data := rawptr(uintptr(val.data) + offset);
		return any{data, a.elem.id};

	case Type_Info_Slice:
		raw := (^mem.Raw_Slice)(val.data);
		runtime.bounds_check_error_loc(loc, i, raw.len);
		offset := uintptr(a.elem.size * i);
		data := rawptr(uintptr(raw.data) + offset);
		return any{data, a.elem.id};

	case Type_Info_Dynamic_Array:
		raw := (^mem.Raw_Dynamic_Array)(val.data);
		runtime.bounds_check_error_loc(loc, i, raw.len);
		offset := uintptr(a.elem.size * i);
		data := rawptr(uintptr(raw.data) + offset);
		return any{data, a.elem.id};

	case Type_Info_String:
		if a.is_cstring do return nil;

		raw := (^mem.Raw_String)(val.data);
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



struct_tag_get :: proc(tag: Struct_Tag, key: string) -> (value: Struct_Tag) {
	value, _ = struct_tag_lookup(tag, key);
	return;
}

struct_tag_lookup :: proc(tag: Struct_Tag, key: string) -> (value: Struct_Tag, ok: bool) {
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
			return Struct_Tag(val[1:i]), true;
		}
	}
	return;
}


enum_string :: proc(a: any) -> string {
	if a == nil do return "";
	ti := runtime.type_info_base(type_info_of(a.id));
	if e, ok := ti.variant.(runtime.Type_Info_Enum); ok {
		v, _ := as_i64(a);
		for value, i in e.values {
			if value == runtime.Type_Info_Enum_Value(v) {
				return e.names[i];
			}
		}
	} else {
		panic("expected an enum to reflect.enum_string");
	}

	return "";
}

// Given a enum type and a value name, get the enum value.
enum_from_name :: proc($EnumType: typeid, name: string) -> (value: EnumType, ok: bool) {
    ti := type_info_base(type_info_of(EnumType));
    if eti, eti_ok := ti.variant.(runtime.Type_Info_Enum); eti_ok {
        for value_name, i in eti.names {
            if value_name != name do continue;
            v := eti.values[i];
            value = EnumType(v);
            ok = true;
            return;
        }
    } else {
        panic("expected enum type to reflect.enum_from_name");
    }
    return;
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


as_int :: proc(a: any) -> (value: int, valid: bool) {
	v: i64;
	v, valid = as_i64(a);
	value = int(v);
	return;
}

as_uint :: proc(a: any) -> (value: uint, valid: bool) {
	v: u64;
	v, valid = as_u64(a);
	value = uint(v);
	return;
}

as_i64 :: proc(a: any) -> (value: i64, valid: bool) {
	if a == nil do return;
	a := a;
	ti := runtime.type_info_core(type_info_of(a.id));
	a.id = ti.id;

	#partial switch info in ti.variant {
	case Type_Info_Integer:
		valid = true;
		switch v in a {
		case i8:      value = i64(v);
		case i16:     value = i64(v);
		case i32:     value = i64(v);
		case i64:     value = i64(v);
		case i128:    value = i64(v);
		case int:     value = i64(v);

		case u8:      value = i64(v);
		case u16:     value = i64(v);
		case u32:     value = i64(v);
		case u64:     value = i64(v);
		case u128:    value = i64(v);
		case uint:    value = i64(v);
		case uintptr: value = i64(v);

		case u16le:   value = i64(v);
		case u32le:   value = i64(v);
		case u64le:   value = i64(v);
		case u128le:  value = i64(v);

		case i16le:   value = i64(v);
		case i32le:   value = i64(v);
		case i64le:   value = i64(v);
		case i128le:  value = i64(v);

		case u16be:   value = i64(v);
		case u32be:   value = i64(v);
		case u64be:   value = i64(v);
		case u128be:  value = i64(v);

		case i16be:   value = i64(v);
		case i32be:   value = i64(v);
		case i64be:   value = i64(v);
		case i128be:  value = i64(v);
		case: valid = false;
		}

	case Type_Info_Rune:
		r := a.(rune);
		value = i64(r);
		valid = true;

	case Type_Info_Float:
		valid = true;
		switch v in a {
		case f32:   value = i64(f32(v));
		case f64:   value = i64(f64(v));
		case f32le: value = i64(f32(v));
		case f64le: value = i64(f64(v));
		case f32be: value = i64(f32(v));
		case f64be: value = i64(f64(v));
		case: valid = false;
		}

	case Type_Info_Boolean:
		valid = true;
		switch v in a {
		case bool: value = i64(bool(v));
		case b8:   value = i64(bool(v));
		case b16:  value = i64(bool(v));
		case b32:  value = i64(bool(v));
		case b64:  value = i64(bool(v));
		case: valid = false;
		}

	case Type_Info_Complex:
		switch v in a {
		case complex64:
			if imag(v) == 0 {
				value = i64(real(v));
				valid = true;
			}
		case complex128:
			if imag(v) == 0 {
				value = i64(real(v));
				valid = true;
			}
		}

	case Type_Info_Quaternion:
		switch v in a {
		case quaternion128:
			if imag(v) == 0 && jmag(v) == 0 && kmag(v) == 0 {
				value = i64(real(v));
				valid = true;
			}
		case quaternion256:
			if imag(v) == 0 && jmag(v) == 0 && kmag(v) == 0 {
				value = i64(real(v));
				valid = true;
			}
		}
	}

	return;
}

as_u64 :: proc(a: any) -> (value: u64, valid: bool) {
	if a == nil do return;
	a := a;
	ti := runtime.type_info_core(type_info_of(a.id));
	a.id = ti.id;

	#partial switch info in ti.variant {
	case Type_Info_Integer:
		valid = true;
		switch v in a {
		case i8:     value = u64(v);
		case i16:    value = u64(v);
		case i32:    value = u64(v);
		case i64:    value = u64(v);
		case i128:   value = u64(v);
		case int:    value = u64(v);

		case u8:     value = u64(v);
		case u16:    value = u64(v);
		case u32:    value = u64(v);
		case u64:    value = u64(v);
		case u128:   value = u64(v);
		case uint:   value = u64(v);
		case uintptr:value = u64(v);

		case u16le:  value = u64(v);
		case u32le:  value = u64(v);
		case u64le:  value = u64(v);
		case u128le: value = u64(v);

		case i16le:  value = u64(v);
		case i32le:  value = u64(v);
		case i64le:  value = u64(v);
		case i128le: value = u64(v);

		case u16be:  value = u64(v);
		case u32be:  value = u64(v);
		case u64be:  value = u64(v);
		case u128be: value = u64(v);

		case i16be:  value = u64(v);
		case i32be:  value = u64(v);
		case i64be:  value = u64(v);
		case i128be: value = u64(v);
		case: valid = false;
		}

	case Type_Info_Rune:
		r := a.(rune);
		value = u64(r);
		valid = true;

	case Type_Info_Float:
		valid = true;
		switch v in a {
		case f32:   value = u64(f32(v));
		case f64:   value = u64(f64(v));
		case f32le: value = u64(f32(v));
		case f64le: value = u64(f64(v));
		case f32be: value = u64(f32(v));
		case f64be: value = u64(f64(v));
		case: valid = false;
		}

	case Type_Info_Boolean:
		valid = true;
		switch v in a {
		case bool: value = u64(bool(v));
		case b8:   value = u64(bool(v));
		case b16:  value = u64(bool(v));
		case b32:  value = u64(bool(v));
		case b64:  value = u64(bool(v));
		case: valid = false;
		}

	case Type_Info_Complex:
		switch v in a {
		case complex64:
			if imag(v) == 0 {
				value = u64(real(v));
				valid = true;
			}
		case complex128:
			if imag(v) == 0 {
				value = u64(real(v));
				valid = true;
			}
		}

	case Type_Info_Quaternion:
		switch v in a {
		case quaternion128:
			if imag(v) == 0 && jmag(v) == 0 && kmag(v) == 0 {
				value = u64(real(v));
				valid = true;
			}
		case quaternion256:
			if imag(v) == 0 && jmag(v) == 0 && kmag(v) == 0 {
				value = u64(real(v));
				valid = true;
			}
		}
	}

	return;
}


as_f64 :: proc(a: any) -> (value: f64, valid: bool) {
	if a == nil do return;
	a := a;
	ti := runtime.type_info_core(type_info_of(a.id));
	a.id = ti.id;

	#partial switch info in ti.variant {
	case Type_Info_Integer:
		valid = true;
		switch v in a {
		case i8:    value = f64(v);
		case i16:   value = f64(v);
		case i32:   value = f64(v);
		case i64:   value = f64(v);
		case i128:  value = f64(v);

		case u8:    value = f64(v);
		case u16:   value = f64(v);
		case u32:   value = f64(v);
		case u64:   value = f64(v);
		case u128:  value = f64(v);

		case u16le: value = f64(v);
		case u32le: value = f64(v);
		case u64le: value = f64(v);
		case u128le:value = f64(v);

		case i16le: value = f64(v);
		case i32le: value = f64(v);
		case i64le: value = f64(v);
		case i128le:value = f64(v);

		case u16be: value = f64(v);
		case u32be: value = f64(v);
		case u64be: value = f64(v);
		case u128be:value = f64(v);

		case i16be: value = f64(v);
		case i32be: value = f64(v);
		case i64be: value = f64(v);
		case i128be:value = f64(v);
		case: valid = false;
		}

	case Type_Info_Rune:
		r := a.(rune);
		value = f64(i32(r));
		valid = true;

	case Type_Info_Float:
		valid = true;
		switch v in a {
		case f32:   value = f64(f32(v));
		case f64:   value = f64(f64(v));
		case f32le: value = f64(f32(v));
		case f64le: value = f64(f64(v));
		case f32be: value = f64(f32(v));
		case f64be: value = f64(f64(v));
		case: valid = false;
		}

	case Type_Info_Boolean:
		valid = true;
		switch v in a {
		case bool: value = f64(i32(bool(v)));
		case b8:   value = f64(i32(bool(v)));
		case b16:  value = f64(i32(bool(v)));
		case b32:  value = f64(i32(bool(v)));
		case b64:  value = f64(i32(bool(v)));
		case: valid = false;
		}

	case Type_Info_Complex:
		switch v in a {
		case complex64:
			if imag(v) == 0 {
				value = f64(real(v));
				valid = true;
			}
		case complex128:
			if imag(v) == 0 {
				value = f64(real(v));
				valid = true;
			}
		}

	case Type_Info_Quaternion:
		switch v in a {
		case quaternion128:
			if imag(v) == 0 && jmag(v) == 0 && kmag(v) == 0 {
				value = f64(real(v));
				valid = true;
			}
		case quaternion256:
			if imag(v) == 0 && jmag(v) == 0 && kmag(v) == 0 {
				value = f64(real(v));
				valid = true;
			}
		}
	}

	return;
}
