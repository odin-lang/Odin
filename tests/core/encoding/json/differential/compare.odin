package test_core_json_differential

import "base:runtime"
import "core:encoding/json"
import "core:fmt"
import "core:mem"
import "core:reflect"
import ref "../reference"

// Results from the two packages have distinct types, so both are normalized before comparing.

Norm_Token :: struct {
	kind:   int,
	text:   string,
	offset: int,
	line:   int,
	column: int,
}

norm_token_current :: proc(t: json.Token) -> Norm_Token {
	return {int(t.kind), t.text, t.offset, t.line, t.column}
}

norm_token_reference :: proc(t: ref.Token) -> Norm_Token {
	return {int(t.kind), t.text, t.offset, t.line, t.column}
}

// Every field of the public `Tokenizer`, which user unmarshalers can see through `Parser.tok`.
Norm_Tokenizer :: struct {
	offset, line, column: int,
	r:                    rune,
	w:                    int,
	curr_line_offset:     int,
	insert_comma:         bool,
}

norm_tokenizer_current :: proc(t: json.Tokenizer) -> Norm_Tokenizer {
	return {t.offset, t.line, t.column, t.r, t.w, t.curr_line_offset, t.insert_comma}
}

norm_tokenizer_reference :: proc(t: ref.Tokenizer) -> Norm_Tokenizer {
	return {t.offset, t.line, t.column, t.r, t.w, t.curr_line_offset, t.insert_comma}
}

Error_Kind :: enum u8 {
	None,
	Error,
	Data,
	Unsupported,
}

Norm_Error :: struct {
	kind:  Error_Kind,
	code:  int,
	id:    typeid,
	token: Norm_Token,
}

norm_error_current :: proc(e: json.Unmarshal_Error) -> (n: Norm_Error) {
	switch v in e {
	case json.Error:
		n.kind, n.code = .Error, int(v)
	case json.Unmarshal_Data_Error:
		n.kind, n.code = .Data, int(v)
	case json.Unsupported_Type_Error:
		n.kind, n.id, n.token = .Unsupported, v.id, norm_token_current(v.token)
	}
	return
}

norm_error_reference :: proc(e: ref.Unmarshal_Error) -> (n: Norm_Error) {
	switch v in e {
	case ref.Error:
		n.kind, n.code = .Error, int(v)
	case ref.Unmarshal_Data_Error:
		n.kind, n.code = .Data, int(v)
	case ref.Unsupported_Type_Error:
		n.kind, n.id, n.token = .Unsupported, v.id, norm_token_reference(v.token)
	}
	return
}

fmt_token :: proc(n: Norm_Token) -> string {
	return fmt.tprintf("%v %q @%d (%d:%d)", json.Token_Kind(n.kind), n.text, n.offset, n.line, n.column)
}

fmt_error :: proc(n: Norm_Error) -> string {
	switch n.kind {
	case .None:        return "nil"
	case .Error:       return fmt.tprintf("Error.%v", json.Error(n.code))
	case .Data:        return fmt.tprintf("Unmarshal_Data_Error.%v", json.Unmarshal_Data_Error(n.code))
	case .Unsupported: return fmt.tprintf("Unsupported_Type_Error{{id=%v, token=%s}}", n.id, fmt_token(n.token))
	}
	return ""
}

// Types that only differ because each package has its own `Value`.
EQUIVALENT_TYPES := [?][2]typeid{
	{json.Value,              ref.Value},
	{json.Array,              ref.Array},
	{json.Object,             ref.Object},
	{json.Null,               ref.Null},
	{[]json.Value,            []ref.Value},
	{map[string]json.Value,   map[string]ref.Value},
	{With_Value_Current,      With_Value_Reference},
}

ids_equivalent :: proc(a, b: typeid) -> bool {
	if a == b {
		return true
	}
	for pair in EQUIVALENT_TYPES {
		if pair[0] == a && pair[1] == b {
			return true
		}
	}
	return false
}

errors_equal :: proc(a, b: Norm_Error) -> bool {
	return a.kind == b.kind && a.code == b.code && ids_equivalent(a.id, b.id) && a.token == b.token
}

values_equal :: proc(a: json.Value, b: ref.Value) -> bool {
	switch av in a {
	case json.Null:
		bv, ok := b.(ref.Null)
		return ok && rawptr(av) == rawptr(bv)
	case json.Integer:
		bv, ok := b.(ref.Integer)
		return ok && av == bv
	case json.Float:
		bv, ok := b.(ref.Float)
		return ok && transmute(u64)av == transmute(u64)bv
	case json.Boolean:
		bv, ok := b.(ref.Boolean)
		return ok && av == bv
	case json.String:
		bv, ok := b.(ref.String)
		return ok && av == bv
	case json.Array:
		bv, ok := b.(ref.Array)
		if !ok || len(av) != len(bv) || cap(av) != cap(bv) {
			return false
		}
		for x, i in av {
			if !values_equal(x, bv[i]) {
				return false
			}
		}
		return true
	case json.Object:
		bv, ok := b.(ref.Object)
		if !ok || len(av) != len(bv) {
			return false
		}
		for k, x in av {
			y, found := bv[k]
			if !found || !values_equal(x, y) {
				return false
			}
		}
		return true
	case:
		return b == nil
	}
}

@(private="file")
ptr_add :: #force_inline proc(p: rawptr, offset: uintptr) -> rawptr {
	return rawptr(uintptr(p) + offset)
}

@(private="file")
read_union_tag :: proc(p: rawptr, info: reflect.Type_Info_Union) -> u64 {
	tag := ptr_add(p, info.tag_offset)
	switch info.tag_type.size {
	case 1: return u64((^u8)(tag)^)
	case 2: return u64((^u16)(tag)^)
	case 4: return u64((^u32)(tag)^)
	case 8: return (^u64)(tag)^
	}
	panic("unexpected union tag size")
}

@(private="file")
allocators_equal :: proc(a, b: runtime.Allocator) -> bool {
	return a.procedure == b.procedure && a.data == b.data
}

@(private="file")
elems_diff :: proc(a, b: rawptr, ea, eb: ^reflect.Type_Info, size_a, size_b, count: int, flags: Diff_Flags) -> string {
	for i in 0..<count {
		pa := ptr_add(a, uintptr(i*size_a))
		pb := ptr_add(b, uintptr(i*size_b))
		if d := diff_values(pa, pb, ea, eb, flags); d != "" {
			return fmt.tprintf("[%d]%s", i, d)
		}
	}
	return ""
}

// Returns "" when the value at `a` (type `ta`, written by the current package) is observably
// the same as the value at `b` (type `tb`, written by the reference), otherwise the path to the
// first difference and what differs. `ta` and `tb` are the same type except where `Value` is
// involved.
Diff_Flag :: enum {
	After_Error, // Both packages returned the same error, see the union case.
	Any_Map_Cap, // `.Reserve_Maps` sizes maps up front, so their capacity may differ.
}
Diff_Flags :: bit_set[Diff_Flag]

diff_values :: proc(a, b: rawptr, ta, tb: ^reflect.Type_Info, flags := Diff_Flags{}) -> string {
	if ta.id == json.Value || tb.id == ref.Value {
		va, vb := (^json.Value)(a)^, (^ref.Value)(b)^
		if ta.id != json.Value || tb.id != ref.Value {
			return fmt.tprintf(": type mismatch %v vs %v", ta.id, tb.id)
		}
		if !values_equal(va, vb) {
			return fmt.tprintf(": current %v, reference %v", va, vb)
		}
		return ""
	}

	ba, bb := reflect.type_info_base(ta), reflect.type_info_base(tb)
	if ba.size != bb.size {
		return fmt.tprintf(": type mismatch %v vs %v", ta.id, tb.id)
	}

	#partial switch ia in ba.variant {
	case reflect.Type_Info_Struct:
		ib, ok := bb.variant.(reflect.Type_Info_Struct)
		if !ok || ia.field_count != ib.field_count {
			return fmt.tprintf(": type mismatch %v vs %v", ta.id, tb.id)
		}
		if .raw_union in ia.flags {
			break
		}
		for i in 0..<int(ia.field_count) {
			pa := ptr_add(a, ia.offsets[i])
			pb := ptr_add(b, ib.offsets[i])
			if d := diff_values(pa, pb, ia.types[i], ib.types[i], flags); d != "" {
				return fmt.tprintf(".%s%s", ia.names[i], d)
			}
		}
		return ""

	case reflect.Type_Info_String:
		if ia.is_cstring {
			ca, cb := (^cstring)(a)^, (^cstring)(b)^
			if (ca == nil) != (cb == nil) || string(ca) != string(cb) {
				return fmt.tprintf(": current %q (nil=%v), reference %q (nil=%v)", ca, ca == nil, cb, cb == nil)
			}
			return ""
		}
		if ia.encoding != .UTF_8 {
			break
		}
		sa, sb := (^string)(a)^, (^string)(b)^
		if sa != sb {
			return fmt.tprintf(": current %q, reference %q", sa, sb)
		}
		if (raw_data(sa) == nil) != (raw_data(sb) == nil) {
			return fmt.tprintf(": empty string data is nil=%v in current, nil=%v in reference", raw_data(sa) == nil, raw_data(sb) == nil)
		}
		return ""

	case reflect.Type_Info_Pointer, reflect.Type_Info_Multi_Pointer, reflect.Type_Info_Procedure:
		pa, pb := (^rawptr)(a)^, (^rawptr)(b)^
		if (pa == nil) != (pb == nil) {
			return fmt.tprintf(": pointer is nil=%v in current, nil=%v in reference", pa == nil, pb == nil)
		}
		return ""

	case reflect.Type_Info_Array:
		ib := bb.variant.(reflect.Type_Info_Array)
		return elems_diff(a, b, ia.elem, ib.elem, ia.elem_size, ib.elem_size, ia.count, flags)

	case reflect.Type_Info_Enumerated_Array:
		ib := bb.variant.(reflect.Type_Info_Enumerated_Array)
		return elems_diff(a, b, ia.elem, ib.elem, ia.elem_size, ib.elem_size, ia.count, flags)

	case reflect.Type_Info_Slice:
		ib := bb.variant.(reflect.Type_Info_Slice)
		ra, rb := (^runtime.Raw_Slice)(a)^, (^runtime.Raw_Slice)(b)^
		if ra.len != rb.len {
			return fmt.tprintf(": len %d in current, %d in reference", ra.len, rb.len)
		}
		if (ra.data == nil) != (rb.data == nil) {
			return fmt.tprintf(": data is nil=%v in current, nil=%v in reference", ra.data == nil, rb.data == nil)
		}
		return elems_diff(ra.data, rb.data, ia.elem, ib.elem, ia.elem_size, ib.elem_size, ra.len, flags)

	case reflect.Type_Info_Dynamic_Array:
		ib := bb.variant.(reflect.Type_Info_Dynamic_Array)
		ra, rb := (^runtime.Raw_Dynamic_Array)(a)^, (^runtime.Raw_Dynamic_Array)(b)^
		if ra.len != rb.len || ra.cap != rb.cap {
			return fmt.tprintf(": len/cap %d/%d in current, %d/%d in reference", ra.len, ra.cap, rb.len, rb.cap)
		}
		if (ra.data == nil) != (rb.data == nil) {
			return fmt.tprintf(": data is nil=%v in current, nil=%v in reference", ra.data == nil, rb.data == nil)
		}
		if !allocators_equal(ra.allocator, rb.allocator) {
			return ": allocator differs"
		}
		return elems_diff(ra.data, rb.data, ia.elem, ib.elem, ia.elem_size, ib.elem_size, ra.len, flags)

	case reflect.Type_Info_Fixed_Capacity_Dynamic_Array:
		ib := bb.variant.(reflect.Type_Info_Fixed_Capacity_Dynamic_Array)
		la, lb := (^int)(ptr_add(a, ia.len_offset))^, (^int)(ptr_add(b, ib.len_offset))^
		if la != lb {
			return fmt.tprintf(": len %d in current, %d in reference", la, lb)
		}
		return elems_diff(a, b, ia.elem, ib.elem, ia.elem_size, ib.elem_size, ia.capacity, flags)

	case reflect.Type_Info_Union:
		ib := bb.variant.(reflect.Type_Info_Union)
		if reflect.type_info_union_is_pure_maybe(ia) {
			pa, pb := (^rawptr)(a)^, (^rawptr)(b)^
			if (pa == nil) != (pb == nil) {
				return fmt.tprintf(": pointer is nil=%v in current, nil=%v in reference", pa == nil, pb == nil)
			}
			return ""
		}
		tag_a, tag_b := read_union_tag(a, ia), read_union_tag(b, ib)
		if tag_a != tag_b {
			return fmt.tprintf(": union tag %d in current, %d in reference", tag_a, tag_b)
		}
		index := int(tag_a)
		if !ia.no_nil {
			if tag_a == 0 {
				return ""
			}
			index -= 1
		}
		if index < 0 || index >= len(ia.variants) {
			return fmt.tprintf(": invalid union tag %d", tag_a)
		}
		if .After_Error in flags {
			// A variant tried and abandoned during a failed unmarshal can leave its bytes behind, for
			// example a string's data pointer over the active `int`. Addresses differ between the
			// two packages, so after an error only the tags are compared.
			return ""
		}
		if d := diff_values(a, b, ia.variants[index], ib.variants[index], flags); d != "" {
			return fmt.tprintf(".(%v)%s", ia.variants[index].id, d)
		}
		return ""

	case reflect.Type_Info_Map:
		ib := bb.variant.(reflect.Type_Info_Map)
		ra, rb := (^runtime.Raw_Map)(a)^, (^runtime.Raw_Map)(b)^
		len_a, len_b := runtime.map_len(ra), runtime.map_len(rb)
		cap_a, cap_b := runtime.map_cap(ra), runtime.map_cap(rb)
		if len_a != len_b || (cap_a != cap_b && .Any_Map_Cap not_in flags) {
			return fmt.tprintf(": len/cap %d/%d in current, %d/%d in reference", len_a, cap_a, len_b, cap_b)
		}
		if !allocators_equal(ra.allocator, rb.allocator) {
			return ": allocator differs"
		}
		it_a := 0
		for ka, va in reflect.iterate_map(any{a, ta.id}, &it_a) {
			found := false
			it_b := 0
			for kb, vb in reflect.iterate_map(any{b, tb.id}, &it_b) {
				if diff_values(ka.data, kb.data, ia.key, ib.key, flags) != "" {
					continue
				}
				if d := diff_values(va.data, vb.data, ia.value, ib.value, flags); d != "" {
					return fmt.tprintf("[%v]%s", ka, d)
				}
				found = true
				break
			}
			if !found {
				return fmt.tprintf(": key %v is missing from reference", ka)
			}
		}
		return ""
	}

	// Integers, floats, booleans, runes, enums, bit_sets, bit_fields, complex numbers,
	// quaternions and #raw_union structs: compare the bytes.
	if mem.compare_ptrs(a, b, ba.size) != 0 {
		return fmt.tprintf(": current %v, reference %v", any{a, ta.id}, any{b, tb.id})
	}
	return ""
}
