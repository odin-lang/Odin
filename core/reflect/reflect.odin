package reflect

import "base:runtime"
import "base:intrinsics"
_ :: intrinsics

Type_Info :: runtime.Type_Info

Type_Info_Named                  :: runtime.Type_Info_Named
Type_Info_Integer                :: runtime.Type_Info_Integer
Type_Info_Rune                   :: runtime.Type_Info_Rune
Type_Info_Float                  :: runtime.Type_Info_Float
Type_Info_Complex                :: runtime.Type_Info_Complex
Type_Info_Quaternion             :: runtime.Type_Info_Quaternion
Type_Info_String                 :: runtime.Type_Info_String
Type_Info_Boolean                :: runtime.Type_Info_Boolean
Type_Info_Any                    :: runtime.Type_Info_Any
Type_Info_Type_Id                :: runtime.Type_Info_Type_Id
Type_Info_Pointer                :: runtime.Type_Info_Pointer
Type_Info_Multi_Pointer          :: runtime.Type_Info_Multi_Pointer
Type_Info_Procedure              :: runtime.Type_Info_Procedure
Type_Info_Array                  :: runtime.Type_Info_Array
Type_Info_Enumerated_Array       :: runtime.Type_Info_Enumerated_Array
Type_Info_Dynamic_Array          :: runtime.Type_Info_Dynamic_Array
Type_Info_Slice                  :: runtime.Type_Info_Slice
Type_Info_Parameters             :: runtime.Type_Info_Parameters
Type_Info_Struct                 :: runtime.Type_Info_Struct
Type_Info_Union                  :: runtime.Type_Info_Union
Type_Info_Enum                   :: runtime.Type_Info_Enum
Type_Info_Map                    :: runtime.Type_Info_Map
Type_Info_Bit_Set                :: runtime.Type_Info_Bit_Set
Type_Info_Simd_Vector            :: runtime.Type_Info_Simd_Vector
Type_Info_Matrix                 :: runtime.Type_Info_Matrix
Type_Info_Soa_Pointer            :: runtime.Type_Info_Soa_Pointer
Type_Info_Bit_Field              :: runtime.Type_Info_Bit_Field

Type_Info_Enum_Value :: runtime.Type_Info_Enum_Value


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
	Multi_Pointer,
	Procedure,
	Array,
	Enumerated_Array,
	Dynamic_Array,
	Slice,
	Parameters,
	Struct,
	Union,
	Enum,
	Map,
	Bit_Set,
	Simd_Vector,
	Matrix,
	Soa_Pointer,
	Bit_Field,
}


// type_kind returns a enum `Type_Kind` to state what kind of type a typeid is
@(require_results)
type_kind :: proc(T: typeid) -> Type_Kind {
	ti := type_info_of(T)
	if ti != nil {
		switch _ in ti.variant {
		case Type_Info_Named:            return .Named
		case Type_Info_Integer:          return .Integer
		case Type_Info_Rune:             return .Rune
		case Type_Info_Float:            return .Float
		case Type_Info_Complex:          return .Complex
		case Type_Info_Quaternion:       return .Quaternion
		case Type_Info_String:           return .String
		case Type_Info_Boolean:          return .Boolean
		case Type_Info_Any:              return .Any
		case Type_Info_Type_Id:          return .Type_Id
		case Type_Info_Pointer:          return .Pointer
		case Type_Info_Multi_Pointer:    return .Multi_Pointer
		case Type_Info_Procedure:        return .Procedure
		case Type_Info_Array:            return .Array
		case Type_Info_Enumerated_Array: return .Enumerated_Array
		case Type_Info_Dynamic_Array:    return .Dynamic_Array
		case Type_Info_Slice:            return .Slice
		case Type_Info_Parameters:       return .Parameters
		case Type_Info_Struct:           return .Struct
		case Type_Info_Union:            return .Union
		case Type_Info_Enum:             return .Enum
		case Type_Info_Map:              return .Map
		case Type_Info_Bit_Set:          return .Bit_Set
		case Type_Info_Simd_Vector:      return .Simd_Vector
		case Type_Info_Matrix:           return .Matrix
		case Type_Info_Soa_Pointer:      return .Soa_Pointer
		case Type_Info_Bit_Field:        return .Bit_Field
		}

	}
	return .Invalid
}

// Returns the `Type_Kind` of the base-type of a typeid.
@(require_results)
underlying_type_kind :: proc(T: typeid) -> Type_Kind {
	return type_kind(runtime.typeid_base(T))
}

// Returns the `Type_Kind` of the core-type of a typeid. See
@(require_results)
backing_type_kind :: proc(T: typeid) -> Type_Kind {
	return type_kind(runtime.typeid_core(T))
}


// type_info_base returns the base-type of a `^Type_Info` stripping the `distinct`ness from the first level
type_info_base :: runtime.type_info_base

// type_info_core returns the core-type of a `^Type_Info` stripping the `distinct`ness from the first level AND/OR
// returns the backing integer type of an enum or bit_set `^Type_Info`.
// This is also aliased as `type_info_base_without_enum`
type_info_core :: runtime.type_info_core 


// type_info_base_without_enum returns the core-type of a `^Type_Info` stripping the `distinct`ness from the first level AND/OR
// returns the backing integer type of an enum or bit_set `^Type_Info`.
// This is also aliased as `type_info_core`
type_info_base_without_enum :: type_info_core


when !ODIN_NO_RTTI {
	// typeid_base returns the base-type of a `typeid` stripping the `distinct`ness from the first level
	typeid_base :: runtime.typeid_base

	// typeid_core returns the core-type of a `typeid` stripping the `distinct`ness from the first level AND/OR
	// returns the backing integer type of an enum or bit_set `typeid`.
	// This is also aliased as `typeid_base_without_enum`
	typeid_core :: runtime.typeid_core

	// typeid_base_without_enum returns the core-type of a `typeid` stripping the `distinct`ness from the first level AND/OR
	// returns the backing integer type of an enum or bit_set `typeid`.
	// This is also aliased as `typeid_core`
	typeid_base_without_enum :: typeid_core
}


// any_base returns an `any` where the `typeid` has been replaced with the `base-type` equivalent
@(require_results)
any_base :: proc(v: any) -> any {
	v := v
	if v.id != nil {
		v.id = typeid_base(v.id)
	}
	return v
}

// any_core returns an `any` where the `typeid` has been replaced with the `core-type` equivalent
@(require_results)
any_core :: proc(v: any) -> any {
	v := v
	if v.id != nil {
		v.id = typeid_core(v.id)
	}
	return v
}

// typeid_elem returns a `typeid` of the element-type of a type if possible, otherwise it returns itself
//     complex32  -> f16
//     complex64  -> f32
//     complex128 -> f64
//     quaternion64  -> f16
//     quaternion128 -> f32
//     quaternion256 -> f64
//     ^T         -> T
//     [^]T       -> T
//     #soa^T     -> T
//     [N]T       -> T
//     []T        -> T
//     [dynamic]T -> T
//     #simd[N]T  -> T
@(require_results)
typeid_elem :: proc(id: typeid) -> typeid {
	ti := type_info_of(id)
	if ti == nil { return nil }

	bits := 8*ti.size

	#partial switch v in ti.variant {
	case Type_Info_Complex:
		switch bits {
		case 32:  return f16
		case 64:  return f32
		case 128: return f64
		}
	case Type_Info_Quaternion:
		switch bits {
		case  64: return f16
		case 128: return f32
		case 256: return f64
		}
	case Type_Info_Pointer:          return v.elem.id
	case Type_Info_Multi_Pointer:    return v.elem.id
	case Type_Info_Soa_Pointer:      return v.elem.id
	case Type_Info_Array:            return v.elem.id
	case Type_Info_Enumerated_Array: return v.elem.id
	case Type_Info_Slice:            return v.elem.id
	case Type_Info_Dynamic_Array:    return v.elem.id
	case Type_Info_Simd_Vector:      return v.elem.id
	}
	return id
}


// returns the size of the type that the passed typeid represents
@(require_results)
size_of_typeid :: proc(T: typeid) -> int {
	if ti := type_info_of(T); ti != nil {
		return ti.size
	}
	return 0
}

// returns the alignment of the type that the passed typeid represents
@(require_results)
align_of_typeid :: proc(T: typeid) -> int {
	if ti := type_info_of(T); ti != nil {
		return ti.align
	}
	return 1
}

// Reinterprets the data stored at `v` as a slice of bytes
@(require_results)
as_bytes :: proc(v: any) -> []byte {
	if v != nil {
		sz := size_of_typeid(v.id)
		return ([^]byte)(v.data)[:sz]
	}
	return nil
}

// Splits the data stored in `any` into its two components: `data` and `id`
@(require_results)
any_data :: #force_inline proc(v: any) -> (data: rawptr, id: typeid) {
	return v.data, v.id
}

// Returns true if the `any` value is either `nil` or the data stored at the address is all zeroed
@(require_results)
is_nil :: proc(v: any) -> bool {
	if v == nil {
		return true
	}
	data := as_bytes(v)
	if data == nil {
		return true
	}
	for v in data {
		if v != 0 {
			return false
		}
	}
	return true
}


// Returns the length of the type that represents the `any` value, or returns 0 if not possible
//     len(^T)   -> len(T)
//     len([N]T) -> N
//     len(#simd[N]T) -> N
//     len([]T)
//     len([dynamic]T)
//     len(map[K]V)
//     len(string) or len(cstring)
//     len(string16) or len(cstring16)
@(require_results)
length :: proc(val: any) -> int {
	if val == nil { return 0 }

	#partial switch a in type_info_of(val.id).variant {
	case Type_Info_Named:
		return length({val.data, a.base.id})

	case Type_Info_Pointer:
		return length({val.data, a.elem.id})

	case Type_Info_Array:
		return a.count

	case Type_Info_Enumerated_Array:
		return a.count

	case Type_Info_Slice:
		return (^runtime.Raw_Slice)(val.data).len

	case Type_Info_Dynamic_Array:
		return (^runtime.Raw_Dynamic_Array)(val.data).len

	case Type_Info_Map:
		return runtime.map_len((^runtime.Raw_Map)(val.data)^)

	case Type_Info_String:
		switch a.encoding {
		case .UTF_8:
			if a.is_cstring {
				return len((^cstring)(val.data)^)
			} else {
				return (^runtime.Raw_String)(val.data).len
			}
		case .UTF_16:
			if a.is_cstring {
				return len((^cstring16)(val.data)^)
			} else {
				return (^runtime.Raw_String16)(val.data).len
			}
		}

	case Type_Info_Simd_Vector:
		return a.count
	}

	return 0
}

// Returns the capacity of the type that represents the `any` value, or returns 0 if not possible
//     cap(^T)        -> cap(T)
//     cap([N]T)      -> N
//     cap(#simd[N]T) -> N
//     cap([dynamic]T)
//     cap(map[K]V)
@(require_results)
capacity :: proc(val: any) -> int {
	if val == nil { return 0 }

	#partial switch a in type_info_of(val.id).variant {
	case Type_Info_Named:
		return capacity({val.data, a.base.id})

	case Type_Info_Pointer:
		return capacity({val.data, a.elem.id})

	case Type_Info_Array:
		return a.count

	case Type_Info_Enumerated_Array:
		return a.count

	case Type_Info_Dynamic_Array:
		return (^runtime.Raw_Dynamic_Array)(val.data).cap

	case Type_Info_Map:
		return runtime.map_cap((^runtime.Raw_Map)(val.data)^)

	case Type_Info_Simd_Vector:
		return a.count
	}

	return 0
}


// Dynamically indexes `any` as an indexable-type if possible. Returns `nil` if not possible
@(require_results)
index :: proc(val: any, i: int, loc := #caller_location) -> any {
	if val == nil { return nil }

	#partial switch a in type_info_of(val.id).variant {
	case Type_Info_Named:
		return index({val.data, a.base.id}, i, loc)

	case Type_Info_Pointer:
		ptr := (^rawptr)(val.data)^
		if ptr == nil {
			return nil
		}
		return index({ptr, a.elem.id}, i, loc)

	case Type_Info_Multi_Pointer:
		ptr := (^rawptr)(val.data)^
		if ptr == nil {
			return nil
		}
		return index({ptr, a.elem.id}, i, loc)

	case Type_Info_Array:
		runtime.bounds_check_error_loc(loc, i, a.count)
		offset := uintptr(a.elem.size * i)
		data := rawptr(uintptr(val.data) + offset)
		return any{data, a.elem.id}

	case Type_Info_Enumerated_Array:
		runtime.bounds_check_error_loc(loc, i, a.count)
		offset := uintptr(a.elem.size * i)
		data := rawptr(uintptr(val.data) + offset)
		return any{data, a.elem.id}

	case Type_Info_Slice:
		raw := (^runtime.Raw_Slice)(val.data)
		runtime.bounds_check_error_loc(loc, i, raw.len)
		offset := uintptr(a.elem.size * i)
		data := rawptr(uintptr(raw.data) + offset)
		return any{data, a.elem.id}

	case Type_Info_Dynamic_Array:
		raw := (^runtime.Raw_Dynamic_Array)(val.data)
		runtime.bounds_check_error_loc(loc, i, raw.len)
		offset := uintptr(a.elem.size * i)
		data := rawptr(uintptr(raw.data) + offset)
		return any{data, a.elem.id}

	case Type_Info_String:
		if a.is_cstring { return nil }

		switch a.encoding {
		case .UTF_8:
			raw := (^runtime.Raw_String)(val.data)
			runtime.bounds_check_error_loc(loc, i, raw.len)
			offset := uintptr(size_of(u8) * i)
			data := rawptr(uintptr(raw.data) + offset)
			return any{data, typeid_of(u8)}
		case .UTF_16:
			raw := (^runtime.Raw_String16)(val.data)
			runtime.bounds_check_error_loc(loc, i, raw.len)
			offset := uintptr(size_of(u16) * i)
			data := rawptr(uintptr(raw.data) + offset)
			return any{data, typeid_of(u16)}
		}
	}
	return nil
}

// Dereferences `any` if it represents a pointer-based value (`^T -> T`)
@(require_results)
deref :: proc(val: any) -> any {
	if val != nil {
		ti := type_info_base(type_info_of(val.id))
		if info, ok := ti.variant.(Type_Info_Pointer); ok {
			return any{
				(^rawptr)(val.data)^,
				info.elem.id,
			}
		}
	}
	return val
}



// `Struct_Tag` represents the type of the `string` of a struct field
//
// Through convention, tags are the concatenation of optionally space-separated key:"value" pairs.
// Each key is a non-empty string which contains no control characters other than space, quotes, and colon.
Struct_Tag :: distinct string

// `Struct_Field` represents a information of a field of a struct
Struct_Field :: struct {
	name:     string,
	type:     ^Type_Info,
	tag:      Struct_Tag,
	offset:   uintptr, // in bytes
	is_using: bool,
}

// Returns a `Struct_Field` containing the information for a struct field of a typeid `T` at index `i`
@(require_results)
struct_field_at :: proc(T: typeid, i: int) -> (field: Struct_Field) {
	ti := runtime.type_info_base(type_info_of(T))
	if s, ok := ti.variant.(runtime.Type_Info_Struct); ok {
		if 0 <= i && i < int(s.field_count) {
			field.name     = s.names[i]
			field.type     = s.types[i]
			field.tag      = Struct_Tag(s.tags[i])
			field.offset   = s.offsets[i]
			field.is_using = s.usings[i]
		}
	}
	return
}

// Returns a `Struct_Field` containing the information for a struct field by `name` of a typeid `T`
@(require_results)
struct_field_by_name :: proc(T: typeid, name: string) -> (field: Struct_Field) {
	ti := runtime.type_info_base(type_info_of(T))
	if s, ok := ti.variant.(runtime.Type_Info_Struct); ok {
		for fname, i in s.names[:s.field_count] {
			if fname == name {
				field.name     = s.names[i]
				field.type     = s.types[i]
				field.tag      = Struct_Tag(s.tags[i])
				field.offset   = s.offsets[i]
				field.is_using = s.usings[i]
				break
			}
		}
	}
	return
}

// Returns an `any` of a struct field specified by name
// Example:
// 	v := struct_field_value_by_name(the_struct, "field_name")
// 	nested_value_through_using := struct_field_value_by_name(the_struct, "field_name", allow_using=true)
@(require_results)
struct_field_value_by_name :: proc(a: any, field: string, allow_using := false) -> any {
	if a == nil { return nil }

	ti := runtime.type_info_base(type_info_of(a.id))

	if s, ok := ti.variant.(runtime.Type_Info_Struct); ok {
		for name, i in s.names[:s.field_count] {
			if name == field {
				return any{
					rawptr(uintptr(a.data) + s.offsets[i]),
					s.types[i].id,
				}
			}

			if allow_using && s.usings[i] {
				f := any{
					rawptr(uintptr(a.data) + s.offsets[i]),
					s.types[i].id,
				}

				if res := struct_field_value_by_name(f, field, allow_using); res != nil {
					return res
				}
			}
		}
	}
	return nil
}

// Returns an `any` of a struct field specified by a `Struct_Field`
// Example:
// 	field := struct_field_value_by_name(the_struct, "field_name")
// 	value_by_field := struct_field_value(the_struct, field)
@(require_results)
struct_field_value :: proc(a: any, field: Struct_Field) -> any {
	if a == nil { return nil }
	return any {
		rawptr(uintptr(a.data) + field.offset),
		field.type.id,
	}
}

// Returns a `[]string` of the names of the struct fields of type `T`
@(require_results)
struct_field_names :: proc(T: typeid) -> []string {
	ti := runtime.type_info_base(type_info_of(T))
	if s, ok := ti.variant.(runtime.Type_Info_Struct); ok {
		return s.names[:s.field_count]
	}
	return nil
}

// Returns a `[]^Type_Info` of the types of the struct fields of type `T`
@(require_results)
struct_field_types :: proc(T: typeid) -> []^Type_Info {
	ti := runtime.type_info_base(type_info_of(T))
	if s, ok := ti.variant.(runtime.Type_Info_Struct); ok {
		return s.types[:s.field_count]
	}
	return nil
}


// Returns a `[]Struct_Tag` of the tags of the struct fields of type `T`
@(require_results)
struct_field_tags :: proc(T: typeid) -> []Struct_Tag {
	ti := runtime.type_info_base(type_info_of(T))
	if s, ok := ti.variant.(runtime.Type_Info_Struct); ok {
		return transmute([]Struct_Tag)s.tags[:s.field_count]
	}
	return nil
}

// Returns a `[]uintptr` of the offsets in bytes of the struct fields of type `T`
@(require_results)
struct_field_offsets :: proc(T: typeid) -> []uintptr {
	ti := runtime.type_info_base(type_info_of(T))
	if s, ok := ti.variant.(runtime.Type_Info_Struct); ok {
		return s.offsets[:s.field_count]
	}
	return nil
}

// Struct_Field_Count_Method is the count method used by `struct_field_count` in order to find the number of fields
Struct_Field_Count_Method :: enum {
	Top_Level,
	Using,
	Recursive,
}

/*
Counts the number of fields in a struct

This procedure returns the number of fields in a struct, counting in one of three ways:
- .Top_Level: Only counts the top-level fields
- .Using:     Same count as .Top_Level, and adds the field count of any `using s: Struct` it encounters (in addition to itself)
- .Recursive: The count of all top-level fields, plus the count of any child struct's fields, recursively

Inputs:
- T:      The struct type
- method: The counting method

Returns:
- The `count`, enumerated using the `method`, which will be `0` if the type is not a struct

Example:
	symbols_loaded, ok := dynlib.initialize_symbols(&game_api, "game.dll")
	symbols_expected   := reflect.struct_field_count(Game_Api) - API_PRIVATE_COUNT

	if symbols_loaded != symbols_expected {
		fmt.eprintf("Expected %v symbols, got %v", symbols_expected, symbols_loaded)
		return
	}
*/
@(require_results)
struct_field_count :: proc(T: typeid, method := Struct_Field_Count_Method.Top_Level) -> (count: int) {
	ti := runtime.type_info_base(type_info_of(T))
	if s, ok := ti.variant.(runtime.Type_Info_Struct); ok {
		switch method {
		case .Top_Level:
			return int(s.field_count)

		case .Using:
			count = int(s.field_count)
			for type, i in s.types[:s.field_count] {
				if s.usings[i] {
					count += struct_field_count(type.id)
				}
			}

		case .Recursive:
			count = int(s.field_count)
			for type in s.types[:s.field_count] {
				count += struct_field_count(type.id)
			}

		case: return 0
		}
	}
	return
}

// Returns the fields of a struct type `T` as an `#soa` slice.
// This is useful to iterate over.
// Example:
// 	for field, i in reflect.struct_fields_zipped(Foo) { ... }
@(require_results)
struct_fields_zipped :: proc(T: typeid) -> (fields: #soa[]Struct_Field) {
	ti := runtime.type_info_base(type_info_of(T))
	if s, ok := ti.variant.(runtime.Type_Info_Struct); ok {
		return soa_zip(
			name     = s.names[:s.field_count],
			type     = s.types[:s.field_count],
			tag      = ([^]Struct_Tag)(s.tags)[:s.field_count],
			offset   = s.offsets[:s.field_count],
			is_using = s.usings[:s.field_count],
		)
	}
	return nil
}


// struct_tag_get returns the value associated with a key in the tag string.
// If the key is present in the tag, the value (which might be empty) is returned. Otherwise an empty string is returned.
// This is just a wrapper around `struct_tag_lookup` with the `ok` value being ignored.
//
// The convention for struct tags is usually of the form:
//
// 	`key:"value" another:"set" and:"whatever"`
@(require_results)
struct_tag_get :: proc(tag: Struct_Tag, key: string) -> (value: string) {
	v, _ := struct_tag_lookup(tag, key)
	return v
}

// struct_tag_lookup returns the value associated with a key in the tag string.
// If the key is present in the tag, the value (which might be empty) is return. Otherwise an empty string is returned.
// The `ok` value returns whether the value was explicit set in the tag string.
//
// The convention for struct tags is usually of the form:
//
// 	`key:"value" another:"set" and:"whatever"`
@(require_results)
struct_tag_lookup :: proc(tag: Struct_Tag, key: string) -> (value: string, ok: bool) {
	for t := tag; t != ""; /**/ {
		i := 0
		for i < len(t) && t[i] == ' ' { // Skip whitespace
			i += 1
		}
		t = t[i:]
		if len(t) == 0 {
			break
		}

		i = 0
		loop: for i < len(t) {
			switch t[i] {
			case ':', '"':
				break loop
			case 0x00 ..< ' ', 0x7f ..= 0x9f: // break if control character is found
				break loop
			}
			i += 1
		}

		if i == 0 {
			break
		}
		if i+1 >= len(t) {
			break
		}

		if t[i] != ':' || t[i+1] != '"' {
			break
		}
		name := string(t[:i])
		t = t[i+1:]

		i = 1
		for i < len(t) && t[i] != '"' { // find closing quote
			if t[i] == '\\' {
				i += 1 // Skip escaped characters
			}
			i += 1
		}

		if i >= len(t) {
			break
		}

		val := string(t[:i+1])
		t = t[i+1:]

		if key == name {
			return val[1:i], true
		}
	}
	return
}


// Returns the string representation of an enum value. It will panic if the value passed is not an enum.
@(require_results)
enum_string :: proc(a: any) -> string {
	if a == nil { return "" }
	ti := runtime.type_info_base(type_info_of(a.id))
	if e, ok := ti.variant.(runtime.Type_Info_Enum); ok {
		v, _ := as_i64(a)
		for value, i in e.values {
			if value == Type_Info_Enum_Value(v) {
				return e.names[i]
			}
		}
	} else {
		panic("expected an enum to reflect.enum_string")
	}

	return ""
}

// Given an enum type and a value name, get the enum value.
@(require_results)
enum_from_name :: proc($Enum_Type: typeid, name: string) -> (value: Enum_Type, ok: bool) {
	ti := type_info_base(type_info_of(Enum_Type))
	if eti, eti_ok := ti.variant.(runtime.Type_Info_Enum); eti_ok {
		for value_name, i in eti.names {
			if value_name != name {
				continue
			}
			v := eti.values[i]
			value = Enum_Type(v)
			ok = true
			return
		}
	}
	return
}

// enum_from_name_any returns the value of an enum field's name if found, returns `0, false` otherwise.
@(require_results)
enum_from_name_any :: proc(Enum_Type: typeid, name: string) -> (value: Type_Info_Enum_Value, ok: bool) {
	ti := runtime.type_info_base(type_info_of(Enum_Type))
	if eti, eti_ok := ti.variant.(runtime.Type_Info_Enum); eti_ok {
		for value_name, i in eti.names {
			if value_name != name {
				continue
			}
			value = eti.values[i]
			ok = true
			return
		}
	}
	return
}

// enum_name_from_value returns the name of enum field if a valid name using parametric polymorphism, otherwise returns `"", false`
@(require_results)
enum_name_from_value :: proc(value: $Enum_Type) -> (name: string, ok: bool) where intrinsics.type_is_enum(Enum_Type) {
	ti := type_info_base(type_info_of(Enum_Type))
	e := ti.variant.(runtime.Type_Info_Enum) or_return
	if len(e.values) == 0 {
		return
	}
	ev := Type_Info_Enum_Value(value)
	for val, idx in e.values {
		if val == ev {
			return e.names[idx], true
		}
	}
	return
}

// enum_name_from_value_any returns the name of enum field if a valid name using reflection, otherwise returns `"", false`
@(require_results)
enum_name_from_value_any :: proc(value: any) -> (name: string, ok: bool) {
	if value.id == nil {
		return
	}
	ti := type_info_base(type_info_of(value.id))
	e := ti.variant.(runtime.Type_Info_Enum) or_return
	if len(e.values) == 0 {
		return
	}
	ev := Type_Info_Enum_Value(as_i64(value) or_return)
	for val, idx in e.values {
		if val == ev {
			return e.names[idx], true
		}
	}
	return
}

// Returns whether the value given has a defined name in the enum type.
@(require_results)
enum_value_has_name :: proc(value: $T) -> bool where intrinsics.type_is_enum(T) {
	when len(T) == cap(T) {
		return value >= min(T) && value <= max(T)
	} else {
		if value < min(T) || value > max(T) {
			return false
		}

		for valid_value in T {
			if valid_value == value {
				return true
			}
		}

		return false
	}
}



// enum_field_names returns `[]string` of the names of the fields of type `Enum_Type`
@(require_results)
enum_field_names :: proc(Enum_Type: typeid) -> []string {
	ti := runtime.type_info_base(type_info_of(Enum_Type))
	if eti, eti_ok := ti.variant.(runtime.Type_Info_Enum); eti_ok {
		return eti.names
	}
	return nil
}
// enum_field_values returns `[]Type_Info_Enum_Value` of the values of the fields of type `Enum_Type`
@(require_results)
enum_field_values :: proc(Enum_Type: typeid) -> []Type_Info_Enum_Value {
	ti := runtime.type_info_base(type_info_of(Enum_Type))
	if eti, eti_ok := ti.variant.(runtime.Type_Info_Enum); eti_ok {
		return eti.values
	}
	return nil
}

// Represents an `Enum_Field` storing the `name` and `value`
Enum_Field :: struct {
	name:  string,
	value: Type_Info_Enum_Value,
}

// Returns a #soa slice of the enum field information of type `Enum_Type`
// This is useful to iterate over.
// Example:
// 	for field, i in reflect.enum_fields_zipped(Foo) { ... }
@(require_results)
enum_fields_zipped :: proc(Enum_Type: typeid) -> (fields: #soa[]Enum_Field) {
	ti := runtime.type_info_base(type_info_of(Enum_Type))
	if eti, eti_ok := ti.variant.(runtime.Type_Info_Enum); eti_ok {
		return soa_zip(name=eti.names, value=eti.values)
	}
	return nil
}



// Returns `^Type_Info` of a any-encoded union type. Panics if a union was not passed.
@(require_results)
union_variant_type_info :: proc(a: any) -> ^Type_Info {
	id := union_variant_typeid(a)
	return type_info_of(id)
}

// Returns whether the `Type_Info_Union` store no tag (called a "pure maybe").
@(require_results)
type_info_union_is_pure_maybe :: proc(info: runtime.Type_Info_Union) -> bool {
	return len(info.variants) == 1 && is_pointer_internally(info.variants[0])
}

// UNSAFE: Returns `typeid` of a any-encoded union type. Panics if a union was not passed.
@(require_results)
union_variant_typeid :: proc(a: any) -> typeid {
	if a == nil { return nil }

	ti := runtime.type_info_base(type_info_of(a.id))
	if info, ok := ti.variant.(runtime.Type_Info_Union); ok {
		if type_info_union_is_pure_maybe(info) {
			if a.data != nil {
				return info.variants[0].id
			}
			return nil
		}

		tag_ptr := uintptr(a.data) + info.tag_offset
		tag_any := any{rawptr(tag_ptr), info.tag_type.id}

		tag: i64 = ---
		switch i in tag_any {
		case u8:   tag = i64(i)
		case i8:   tag = i64(i)
		case u16:  tag = i64(i)
		case i16:  tag = i64(i)
		case u32:  tag = i64(i)
		case i32:  tag = i64(i)
		case u64:  tag = i64(i)
		case i64:  tag = i
		case: unimplemented()
		}

		if info.no_nil {
			return info.variants[tag].id
		} else if tag != 0 {
			return info.variants[tag-1].id
		}

		return nil
	}
	panic("expected a union to reflect.union_variant_typeid")
}

// UNSAFE: Returns the underlying tag value of a union. Panics if a union was not passed.
@(require_results)
get_union_variant_raw_tag :: proc(a: any) -> i64 {
	if a == nil { return -1 }

	ti := runtime.type_info_base(type_info_of(a.id))
	if info, ok := ti.variant.(runtime.Type_Info_Union); ok {
		if type_info_union_is_pure_maybe(info) {
			return 1 if a.data != nil else 0
		}

		tag_ptr := uintptr(a.data) + info.tag_offset
		tag_any := any{rawptr(tag_ptr), info.tag_type.id}

		tag: i64 = ---
		switch i in tag_any {
		case u8:   tag = i64(i)
		case i8:   tag = i64(i)
		case u16:  tag = i64(i)
		case i16:  tag = i64(i)
		case u32:  tag = i64(i)
		case i32:  tag = i64(i)
		case u64:  tag = i64(i)
		case i64:  tag = i
		case: unimplemented()
		}

		return tag
	}
	panic("expected a union to reflect.get_union_variant_raw_tag")
}

// Returns the underlying variant value of a union. Panics if a union was not passed.
@(require_results)
get_union_variant :: proc(a: any) -> any {
	if a == nil {
		return nil
	}
	id := union_variant_typeid(a)
	if id == nil {
		return nil
	}
	return any{a.data, id}
}

// Converts a pointer to a union, to a union containing the pointers to the variant types, and stores a pointer of the variant value in the new union
//
// Example:
// 	val: union{i32, f32, string}
//	val = "123"
// 	ptr: union{^i32, ^f32, ^string} = get_union_as_ptr_variants(&val)
// 	sp := ptr.(^string)
// 	assert(sp^ == "123")
@(require_results)
get_union_as_ptr_variants :: proc(val: ^$T) -> (res: intrinsics.type_convert_variants_to_pointers(T)) where intrinsics.type_is_union(T) {
	ptr := rawptr(val)
	tag := get_union_variant_raw_tag(val^)
	intrinsics.mem_copy(&res, &ptr, size_of(ptr))
	set_union_variant_raw_tag(res, tag)
	return
}


// UNSAFE: Manually set the tag value of a union using an integer. Panics if a union was not passed.
set_union_variant_raw_tag :: proc(a: any, tag: i64) {
	if a == nil { return }

	ti := runtime.type_info_base(type_info_of(a.id))
	if info, ok := ti.variant.(runtime.Type_Info_Union); ok {
		if type_info_union_is_pure_maybe(info) {
			// Cannot do anything
			return
		}

		tag_ptr := uintptr(a.data) + info.tag_offset
		tag_any := any{rawptr(tag_ptr), info.tag_type.id}

		switch &i in tag_any {
		case u8:   i = u8(tag)
		case i8:   i = i8(tag)
		case u16:  i = u16(tag)
		case i16:  i = i16(tag)
		case u32:  i = u32(tag)
		case i32:  i = i32(tag)
		case u64:  i = u64(tag)
		case i64:  i = tag
		case: unimplemented()
		}

		return
	}
	panic("expected a union to reflect.set_union_variant_raw_tag")
}

// UNSAFE: Manually set the tag value of a union using a `typeid`. Panics if a union was not passed.
set_union_variant_typeid :: proc(a: any, id: typeid) {
	if a == nil { return }

	ti := runtime.type_info_base(type_info_of(a.id))
	if info, ok := ti.variant.(runtime.Type_Info_Union); ok {
		if type_info_union_is_pure_maybe(info) {
			// Cannot do anything
			return
		}

		if id == nil && !info.no_nil {
			set_union_variant_raw_tag(a, 0)
			return
		}

		for variant, i in info.variants {
			if variant.id == id {
				tag := i64(i)
				if !info.no_nil {
					tag += 1
				}
				set_union_variant_raw_tag(a, tag)
				return
			}
		}
		return
	}
	panic("expected a union to reflect.set_union_variant_typeid")
}

// UNSAFE: Manually set the tag value of a union using a `^Type_Info`. Panics if a union was not passed.
set_union_variant_type_info :: proc(a: any, tag_ti: ^Type_Info) {
	if a == nil { return }

	ti := runtime.type_info_base(type_info_of(a.id))
	if info, ok := ti.variant.(runtime.Type_Info_Union); ok {
		if type_info_union_is_pure_maybe(info) {
			// Cannot do anything
			return
		}

		if tag_ti == nil && !info.no_nil {
			set_union_variant_raw_tag(a, 0)
			return
		}

		for variant, i in info.variants {
			if variant == tag_ti {
				tag := i64(i)
				if !info.no_nil {
					tag += 1
				}
				set_union_variant_raw_tag(a, tag)
				return
			}
		}
		return
	}
	panic("expected a union to reflect.set_union_variant_type_info")
}

// UNSAFE: Manually set the variant value of a union using an `any`. Panics if a union was not passed.
set_union_value :: proc(dst: any, value: any) -> bool {
	if dst == nil { return false }

	ti := runtime.type_info_base(type_info_of(dst.id))
	if info, ok := ti.variant.(runtime.Type_Info_Union); ok {
		if value.id == nil {
			intrinsics.mem_zero(dst.data, ti.size)
			return true
		}
		if ti.id == runtime.typeid_base(value.id) {
			intrinsics.mem_copy(dst.data, value.data, ti.size)
			return true
		}
		
		if type_info_union_is_pure_maybe(info) {
			if variant := info.variants[0]; variant.id == value.id {
				intrinsics.mem_copy(dst.data, value.data, variant.size)
				return true
			}
			return false
		}

		for variant, i in info.variants {
			if variant.id == value.id {
				tag := i64(i)
				if !info.no_nil {
					tag += 1
				}
				intrinsics.mem_copy(dst.data, value.data, variant.size)
				set_union_variant_raw_tag(dst, tag)
				return true
			}
		}
		return false
	}
	panic("expected a union to reflect.set_union_variant_typeid")
}

// UNSAFE: Checks to see if the data stored is a `bit_set` and is big endian. Panics if a `bit_set` was not passed.
@(require_results)
bit_set_is_big_endian :: proc(value: any, loc := #caller_location) -> bool {
	if value == nil { return ODIN_ENDIAN == .Big }
	
	ti := runtime.type_info_base(type_info_of(value.id))
	if info, ok := ti.variant.(runtime.Type_Info_Bit_Set); ok {
		if info.underlying == nil { return ODIN_ENDIAN == .Big }

		underlying_ti := runtime.type_info_base(info.underlying)
		if underlying_info, uok := underlying_ti.variant.(runtime.Type_Info_Integer); uok {
			switch underlying_info.endianness {
			case .Platform: return ODIN_ENDIAN == .Big
			case .Little:   return false
			case .Big:      return true
			}
		}

		return ODIN_ENDIAN == .Big
	}
	panic("expected a bit_set to reflect.bit_set_is_big_endian", loc)
}


Bit_Field :: struct {
	name:   string,
	type:   ^Type_Info,
	size:   uintptr,     // Size in bits
	offset: uintptr,     // Offset in bits
	tag:    Struct_Tag,
}

// Returns the fields of a `bit_field` type `T` as an `#soa` slice.
// This is useful to iterate over.
// Example:
// 	for field, i in reflect.bit_fields_zipped(Foo_Bit_Field) { ... }
@(require_results)
bit_fields_zipped :: proc(T: typeid) -> (fields: #soa[]Bit_Field) {
	ti := runtime.type_info_base(type_info_of(T))
	if s, ok := ti.variant.(runtime.Type_Info_Bit_Field); ok {
		return soa_zip(
			name   = s.names[:s.field_count],
			type   = s.types[:s.field_count],
			size   = s.bit_sizes[:s.field_count],
			offset = s.bit_offsets[:s.field_count],
			tag      = ([^]Struct_Tag)(s.tags)[:s.field_count],
		)
	}
	return nil
}

// bit_field_names returns a `[]string` of the field names of a `bit_field` type `T`
@(require_results)
bit_field_names :: proc(T: typeid) -> []string {
	ti := runtime.type_info_base(type_info_of(T))
	if s, ok := ti.variant.(runtime.Type_Info_Bit_Field); ok {
		return s.names[:s.field_count]
	}
	return nil
}

// bit_field_types returns a `[]^Type_Info` of the field representation types of a `bit_field` type `T`, not the backing integer-bit-width types
@(require_results)
bit_field_types :: proc(T: typeid) -> []^Type_Info {
	ti := runtime.type_info_base(type_info_of(T))
	if s, ok := ti.variant.(runtime.Type_Info_Bit_Field); ok {
		return s.types[:s.field_count]
	}
	return nil
}

// bit_field_types returns a `[]uintptr` of the field bit-width-sizes of a `bit_field` type `T`
@(require_results)
bit_field_sizes :: proc(T: typeid) -> []uintptr {
	ti := runtime.type_info_base(type_info_of(T))
	if s, ok := ti.variant.(runtime.Type_Info_Bit_Field); ok {
		return s.bit_sizes[:s.field_count]
	}
	return nil
}

// bit_field_types returns a `[]uintptr` of the field offsets in bits of a `bit_field` type `T`
@(require_results)
bit_field_offsets :: proc(T: typeid) -> []uintptr {
	ti := runtime.type_info_base(type_info_of(T))
	if s, ok := ti.variant.(runtime.Type_Info_Bit_Field); ok {
		return s.bit_offsets[:s.field_count]
	}
	return nil
}

// bit_field_types returns a `[]Struct_Tag` of the field tags of a `bit_field` type `T`
@(require_results)
bit_field_tags :: proc(T: typeid) -> []Struct_Tag {
	ti := runtime.type_info_base(type_info_of(T))
	if s, ok := ti.variant.(runtime.Type_Info_Bit_Field); ok {
		return transmute([]Struct_Tag)s.tags[:s.field_count]
	}
	return nil
}

// as_bool attempts to convert an `any` to a `bool`.
@(require_results)
as_bool :: proc(a: any) -> (value: bool, valid: bool) {
	if a == nil { return }
	a := a
	ti := runtime.type_info_core(type_info_of(a.id))
	a.id = ti.id

	#partial switch info in ti.variant {
	case Type_Info_Boolean:
		valid = true
		switch v in a {
		case bool: value = v
		case b8:   value = bool(v)
		case b16:  value = bool(v)
		case b32:  value = bool(v)
		case b64:  value = bool(v)
		case: valid = false
		}
	}

	return
}

// as_int attempts to convert an `any` to a `int`.
@(require_results)
as_int :: proc(a: any) -> (value: int, valid: bool) {
	v: i64
	v, valid = as_i64(a)
	value = int(v)
	return
}

// as_uint attempts to convert an `any` to a `uint`.
@(require_results)
as_uint :: proc(a: any) -> (value: uint, valid: bool) {
	v: u64
	v, valid = as_u64(a)
	value = uint(v)
	return
}

// as_i64 attempts to convert an `any` to a `i64`.
@(require_results)
as_i64 :: proc(a: any) -> (value: i64, valid: bool) {
	if a == nil { return }
	a := a
	ti := runtime.type_info_core(type_info_of(a.id))
	a.id = ti.id

	#partial switch info in ti.variant {
	case Type_Info_Integer:
		valid = true
		switch v in a {
		case i8:      value = i64(v)
		case i16:     value = i64(v)
		case i32:     value = i64(v)
		case i64:     value =      v
		case i128:    value = i64(v)
		case int:     value = i64(v)

		case u8:      value = i64(v)
		case u16:     value = i64(v)
		case u32:     value = i64(v)
		case u64:     value = i64(v)
		case u128:    value = i64(v)
		case uint:    value = i64(v)
		case uintptr: value = i64(v)

		case u16le:   value = i64(v)
		case u32le:   value = i64(v)
		case u64le:   value = i64(v)
		case u128le:  value = i64(v)

		case i16le:   value = i64(v)
		case i32le:   value = i64(v)
		case i64le:   value = i64(v)
		case i128le:  value = i64(v)

		case u16be:   value = i64(v)
		case u32be:   value = i64(v)
		case u64be:   value = i64(v)
		case u128be:  value = i64(v)

		case i16be:   value = i64(v)
		case i32be:   value = i64(v)
		case i64be:   value = i64(v)
		case i128be:  value = i64(v)
		case: valid = false
		}

	case Type_Info_Rune:
		r := a.(rune)
		value = i64(r)
		valid = true

	case Type_Info_Float:
		valid = true
		switch v in a {
		case f32:   value = i64(v)
		case f64:   value = i64(v)
		case f32le: value = i64(v)
		case f64le: value = i64(v)
		case f32be: value = i64(v)
		case f64be: value = i64(v)
		case: valid = false
		}

	case Type_Info_Boolean:
		valid = true
		switch v in a {
		case bool: value = i64(v)
		case b8:   value = i64(v)
		case b16:  value = i64(v)
		case b32:  value = i64(v)
		case b64:  value = i64(v)
		case: valid = false
		}

	case Type_Info_Complex:
		switch v in a {
		case complex64:
			if imag(v) == 0 {
				value = i64(real(v))
				valid = true
			}
		case complex128:
			if imag(v) == 0 {
				value = i64(real(v))
				valid = true
			}
		}

	case Type_Info_Quaternion:
		switch v in a {
		case quaternion128:
			if imag(v) == 0 && jmag(v) == 0 && kmag(v) == 0 {
				value = i64(real(v))
				valid = true
			}
		case quaternion256:
			if imag(v) == 0 && jmag(v) == 0 && kmag(v) == 0 {
				value = i64(real(v))
				valid = true
			}
		}
	}

	return
}

// as_u64 attempts to convert an `any` to a `u64`.
@(require_results)
as_u64 :: proc(a: any) -> (value: u64, valid: bool) {
	if a == nil { return }
	a := a
	ti := runtime.type_info_core(type_info_of(a.id))
	a.id = ti.id

	#partial switch info in ti.variant {
	case Type_Info_Integer:
		valid = true
		switch v in a {
		case i8:     value = u64(v)
		case i16:    value = u64(v)
		case i32:    value = u64(v)
		case i64:    value = u64(v)
		case i128:   value = u64(v)
		case int:    value = u64(v)

		case u8:     value = u64(v)
		case u16:    value = u64(v)
		case u32:    value = u64(v)
		case u64:    value =    (v)
		case u128:   value = u64(v)
		case uint:   value = u64(v)
		case uintptr:value = u64(v)

		case u16le:  value = u64(v)
		case u32le:  value = u64(v)
		case u64le:  value = u64(v)
		case u128le: value = u64(v)

		case i16le:  value = u64(v)
		case i32le:  value = u64(v)
		case i64le:  value = u64(v)
		case i128le: value = u64(v)

		case u16be:  value = u64(v)
		case u32be:  value = u64(v)
		case u64be:  value = u64(v)
		case u128be: value = u64(v)

		case i16be:  value = u64(v)
		case i32be:  value = u64(v)
		case i64be:  value = u64(v)
		case i128be: value = u64(v)
		case: valid = false
		}

	case Type_Info_Rune:
		r := a.(rune)
		value = u64(r)
		valid = true

	case Type_Info_Float:
		valid = true
		switch v in a {
		case f16:   value = u64(v)
		case f32:   value = u64(v)
		case f64:   value = u64(v)
		case f32le: value = u64(v)
		case f64le: value = u64(v)
		case f32be: value = u64(v)
		case f64be: value = u64(v)
		case: valid = false
		}

	case Type_Info_Boolean:
		valid = true
		switch v in a {
		case bool: value = u64(v)
		case b8:   value = u64(v)
		case b16:  value = u64(v)
		case b32:  value = u64(v)
		case b64:  value = u64(v)
		case: valid = false
		}

	case Type_Info_Complex:
		switch v in a {
		case complex64:
			if imag(v) == 0 {
				value = u64(real(v))
				valid = true
			}
		case complex128:
			if imag(v) == 0 {
				value = u64(real(v))
				valid = true
			}
		}

	case Type_Info_Quaternion:
		switch v in a {
		case quaternion128:
			if imag(v) == 0 && jmag(v) == 0 && kmag(v) == 0 {
				value = u64(real(v))
				valid = true
			}
		case quaternion256:
			if imag(v) == 0 && jmag(v) == 0 && kmag(v) == 0 {
				value = u64(real(v))
				valid = true
			}
		}
	}

	return
}


// as_f64 attempts to convert an `any` to a `f64`.
@(require_results)
as_f64 :: proc(a: any) -> (value: f64, valid: bool) {
	if a == nil { return }
	a := a
	ti := runtime.type_info_core(type_info_of(a.id))
	a.id = ti.id

	#partial switch info in ti.variant {
	case Type_Info_Integer:
		valid = true
		switch v in a {
		case i8:    value = f64(v)
		case i16:   value = f64(v)
		case i32:   value = f64(v)
		case i64:   value = f64(v)
		case i128:  value = f64(v)

		case u8:    value = f64(v)
		case u16:   value = f64(v)
		case u32:   value = f64(v)
		case u64:   value = f64(v)
		case u128:  value = f64(v)

		case u16le: value = f64(v)
		case u32le: value = f64(v)
		case u64le: value = f64(v)
		case u128le:value = f64(v)

		case i16le: value = f64(v)
		case i32le: value = f64(v)
		case i64le: value = f64(v)
		case i128le:value = f64(v)

		case u16be: value = f64(v)
		case u32be: value = f64(v)
		case u64be: value = f64(v)
		case u128be:value = f64(v)

		case i16be: value = f64(v)
		case i32be: value = f64(v)
		case i64be: value = f64(v)
		case i128be:value = f64(v)
		case: valid = false
		}

	case Type_Info_Rune:
		r := a.(rune)
		value = f64(i32(r))
		valid = true

	case Type_Info_Float:
		valid = true
		switch v in a {
		case f16:   value = f64(v)
		case f32:   value = f64(v)
		case f64:   value =    (v)
		case f32le: value = f64(v)
		case f64le: value = f64(v)
		case f32be: value = f64(v)
		case f64be: value = f64(v)
		case: valid = false
		}

	case Type_Info_Boolean:
		valid = true
		switch v in a {
		case bool: value = f64(i32(v))
		case b8:   value = f64(i32(v))
		case b16:  value = f64(i32(v))
		case b32:  value = f64(i32(v))
		case b64:  value = f64(i32(v))
		case: valid = false
		}

	case Type_Info_Complex:
		switch v in a {
		case complex32:
			if imag(v) == 0 {
				value = f64(real(v))
				valid = true
			}
		case complex64:
			if imag(v) == 0 {
				value = f64(real(v))
				valid = true
			}
		case complex128:
			if imag(v) == 0 {
				value = real(v)
				valid = true
			}
		}

	case Type_Info_Quaternion:
		switch v in a {
		case quaternion64:
			if imag(v) == 0 && jmag(v) == 0 && kmag(v) == 0 {
				value = f64(real(v))
				valid = true
			}
		case quaternion128:
			if imag(v) == 0 && jmag(v) == 0 && kmag(v) == 0 {
				value = f64(real(v))
				valid = true
			}
		case quaternion256:
			if imag(v) == 0 && jmag(v) == 0 && kmag(v) == 0 {
				value = real(v)
				valid = true
			}
		}
	}

	return
}


// as_string attempts to convert an `any` to a `string`.
@(require_results)
as_string :: proc(a: any) -> (value: string, valid: bool) {
	if a == nil { return }
	a := a
	ti := runtime.type_info_core(type_info_of(a.id))
	a.id = ti.id

	#partial switch info in ti.variant {
	case Type_Info_String:
		valid = true
		switch v in a {
		case string:  value = v
		case cstring: value = string(v)
		case: valid = false
		}
	}

	return
}

// as_string16 attempts to convert an `any` to a `string16`.
@(require_results)
as_string16 :: proc(a: any) -> (value: string16, valid: bool) {
	if a == nil { return }
	a := a
	ti := runtime.type_info_core(type_info_of(a.id))
	a.id = ti.id

	#partial switch info in ti.variant {
	case Type_Info_String:
		valid = true
		switch v in a {
		case string16:  value = v
		case cstring16: value = string16(v)
		case: valid = false
		}
	}

	return
}

@(require_results)
relative_pointer_to_absolute_raw :: proc(data: rawptr, base_integer_id: typeid) -> rawptr {
	_handle :: proc(ptr: ^$T) -> rawptr where intrinsics.type_is_integer(T) {
		if ptr^ == 0 {
			return nil
		}
		when intrinsics.type_is_unsigned(T) {
			return rawptr(uintptr(ptr) + uintptr(ptr^))
		} else {
			return rawptr(uintptr(ptr) + uintptr(i64(ptr^)))
		}
	}

	ptr_any := any{data, base_integer_id}
	ptr: rawptr
	switch &i in ptr_any {
	case u8:    ptr = _handle(&i)
	case u16:   ptr = _handle(&i)
	case u32:   ptr = _handle(&i)
	case u64:   ptr = _handle(&i)
	case i8:    ptr = _handle(&i)
	case i16:   ptr = _handle(&i)
	case i32:   ptr = _handle(&i)
	case i64:   ptr = _handle(&i)
	case u16le: ptr = _handle(&i)
	case u32le: ptr = _handle(&i)
	case u64le: ptr = _handle(&i)
	case i16le: ptr = _handle(&i)
	case i32le: ptr = _handle(&i)
	case i64le: ptr = _handle(&i)
	case u16be: ptr = _handle(&i)
	case u32be: ptr = _handle(&i)
	case u64be: ptr = _handle(&i)
	case i16be: ptr = _handle(&i)
	case i32be: ptr = _handle(&i)
	case i64be: ptr = _handle(&i)
	}
	return ptr

}



// as_pointer attempts to convert an `any` to a `rawptr`.
// This only works for `^T`, `[^]T`, `cstring`, `cstring16` based types
@(require_results)
as_pointer :: proc(a: any) -> (value: rawptr, valid: bool) {
	if a == nil { return }
	a := a
	ti := runtime.type_info_core(type_info_of(a.id))
	a.id = ti.id

	#partial switch info in ti.variant {
	case Type_Info_Pointer, Type_Info_Multi_Pointer:
		valid = true
		value = (^rawptr)(a.data)^

	case Type_Info_String:
		valid = true
		switch v in a {
		case cstring:   value = rawptr(v)
		case cstring16: value = rawptr(v)
		case: valid = false
		}
	}

	return
}


// Returns the equivalent of doing `raw_data(v)` where `v` is a non-any value
@(require_results)
as_raw_data :: proc(a: any) -> (value: rawptr, valid: bool) {
	if a == nil { return }
	a := a
	ti := runtime.type_info_core(type_info_of(a.id))
	a.id = ti.id

	#partial switch info in ti.variant {
	case Type_Info_String:
		valid = true
		switch v in a {
		case string:    value = raw_data(v)
		case cstring:   value = rawptr(v) // just in case
		case string16:  value = raw_data(v)
		case cstring16: value = rawptr(v) // just in case
		case: valid = false
		}

	case Type_Info_Array:
		valid = true
		value = a.data

	case Type_Info_Slice:
		valid = true
		value = (^runtime.Raw_Slice)(a.data).data

	case Type_Info_Dynamic_Array:
		valid = true
		value = (^runtime.Raw_Dynamic_Array)(a.data).data
	}

	return
}

eq :: equal
ne :: not_equal

DEFAULT_EQUAL_MAX_RECURSION_LEVEL :: 32

// Checks to see if two `any` values are not semantically equivalent
@(require_results)
not_equal :: proc(a, b: any, including_indirect_array_recursion := false, recursion_level := 0) -> bool {
	return !equal(a, b, including_indirect_array_recursion, recursion_level)
}

// Checks to see if two `any` values are semantically equivalent
@(require_results)
equal :: proc(a, b: any, including_indirect_array_recursion := false, recursion_level := 0) -> bool {
	if a == nil && b == nil {
		return true
	}

	if a.id != b.id {
		return false
	}

	if a.data == b.data {
		return true
	}
	
	including_indirect_array_recursion := including_indirect_array_recursion
	if recursion_level >= DEFAULT_EQUAL_MAX_RECURSION_LEVEL {
		including_indirect_array_recursion = false
	} 

	t := type_info_of(a.id)
	if .Comparable not_in t.flags && !including_indirect_array_recursion {
		return false
	}

	if t.size == 0 {
		return true
	}

	if .Simple_Compare in t.flags {
		return runtime.memory_compare(a.data, b.data, t.size) == 0
	}
	
	t = runtime.type_info_core(t)

	switch v in t.variant {
	case Type_Info_Named:
		unreachable()
	case Type_Info_Parameters:
		unreachable()
	case Type_Info_Any:
		if !including_indirect_array_recursion {
			return false
		}
		va := (^any)(a.data)
		vb := (^any)(b.data)
		return equal(va, vb, including_indirect_array_recursion, recursion_level+1) 
	case Type_Info_Map:
		return false
	case Type_Info_Float:
		x, _ := as_f64(a)
		y, _ := as_f64(b)
		return x == y
	case Type_Info_Complex:
		switch x in a {
		case complex32:
			#no_type_assert y := b.(complex32)
			return x == y
		case complex64:
			#no_type_assert y := b.(complex64)
			return x == y
		case complex128:
			#no_type_assert y := b.(complex128)
			return x == y
		}
		return false
	case Type_Info_Quaternion:
		switch x in a {
		case quaternion64:
			#no_type_assert y := b.(quaternion64)
			return x == y
		case quaternion128:
			#no_type_assert y := b.(quaternion128)
			return x == y
		case quaternion256:
			#no_type_assert y := b.(quaternion256)
			return x == y
		}
		return false
	case 
		Type_Info_Boolean,
		Type_Info_Integer, 
		Type_Info_Rune,
		Type_Info_Type_Id,
		Type_Info_Pointer,
		Type_Info_Multi_Pointer,
		Type_Info_Procedure,
		Type_Info_Bit_Set,
		Type_Info_Enum,
		Type_Info_Simd_Vector,
		Type_Info_Soa_Pointer,
		Type_Info_Matrix:
		return runtime.memory_compare(a.data, b.data, t.size) == 0
		
	case Type_Info_String:
		switch v.encoding {
		case .UTF_8:
			if v.is_cstring {
				x := string((^cstring)(a.data)^)
				y := string((^cstring)(b.data)^)
				return x == y
			} else {
				x := (^string)(a.data)^
				y := (^string)(b.data)^
				return x == y
			}
		case .UTF_16:
			if v.is_cstring {
				x := string16((^cstring16)(a.data)^)
				y := string16((^cstring16)(b.data)^)
				return x == y
			} else {
				x := (^string16)(a.data)^
				y := (^string16)(b.data)^
				return x == y
			}
		}
		return true
	case Type_Info_Array:
		for i in 0..<v.count {
			x := rawptr(uintptr(a.data) + uintptr(v.elem_size*i))
			y := rawptr(uintptr(b.data) + uintptr(v.elem_size*i))
			if !equal(any{x, v.elem.id}, any{y, v.elem.id}, including_indirect_array_recursion, recursion_level) {
				return false
			}
		}
		return true
	case Type_Info_Enumerated_Array:
		for i in 0..<v.count {
			x := rawptr(uintptr(a.data) + uintptr(v.elem_size*i))
			y := rawptr(uintptr(b.data) + uintptr(v.elem_size*i))
			if !equal(any{x, v.elem.id}, any{y, v.elem.id}, including_indirect_array_recursion, recursion_level) {
				return false
			}
		}
		return true
	case Type_Info_Struct:
		if v.equal != nil {
			return v.equal(a.data, b.data)
		} else {
			for offset, i in v.offsets[:v.field_count] {
				x := rawptr(uintptr(a.data) + offset)
				y := rawptr(uintptr(b.data) + offset)
				id := v.types[i].id
				if !equal(any{x, id}, any{y, id}, including_indirect_array_recursion, recursion_level) {
					return false
				}
			}
			return true
		}
	case Type_Info_Union:
		if v.equal != nil {
			return v.equal(a.data, b.data)
		}
		return false
	case Type_Info_Slice:
		if !including_indirect_array_recursion {
			return false
		}
		array_a := (^runtime.Raw_Slice)(a.data)
		array_b := (^runtime.Raw_Slice)(b.data)
		if array_a.len != array_b.len {
			return false
		}
		if array_a.data == array_b.data {
			return true
		}
		for i in 0..<array_a.len {
			x := rawptr(uintptr(array_a.data) + uintptr(v.elem_size*i))
			y := rawptr(uintptr(array_b.data) + uintptr(v.elem_size*i))
			if !equal(any{x, v.elem.id}, any{y, v.elem.id}, including_indirect_array_recursion, recursion_level+1) {
				return false
			}	
		}
		return true
	case Type_Info_Dynamic_Array:
		if !including_indirect_array_recursion {
			return false
		}
		array_a := (^runtime.Raw_Dynamic_Array)(a.data)
		array_b := (^runtime.Raw_Dynamic_Array)(b.data)
		if array_a.len != array_b.len {
			return false
		}
		if array_a.data == array_b.data {
			return true
		}
		if .Simple_Compare in v.elem.flags {
			return runtime.memory_compare((^byte)(array_a.data), (^byte)(array_b.data), array_a.len * v.elem.size) == 0
		}
		
		for i in 0..<array_a.len {
			x := rawptr(uintptr(array_a.data) + uintptr(v.elem_size*i))
			y := rawptr(uintptr(array_b.data) + uintptr(v.elem_size*i))
			if !equal(any{x, v.elem.id}, any{y, v.elem.id}, including_indirect_array_recursion, recursion_level+1) {
				return false
			}	
		}
		return true

	case Type_Info_Bit_Field:
		x, y := a, b
		x.id = v.backing_type.id
		y.id = v.backing_type.id
		return equal(x, y, including_indirect_array_recursion, recursion_level+0)

	}
	
	runtime.print_typeid(a.id)
	runtime.print_string("\n")
	return true
}