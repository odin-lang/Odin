package ucd

import "core:strings"
import "core:os"

load_unicode_data :: proc(
	filename: string,
	allocator := context.allocator,
) -> (unicode_data : Unicode_Data, err: Error) {

	data, os_error := os.read_entire_file(filename, context.temp_allocator)
	if os_error != nil {
		err = os_error
		return 
	}
	defer free_all(context.temp_allocator)

	line_iter := Line_Iterator{data = data }
	first_cp: rune

	line_loop: for line, line_num in line_iterator(&line_iter) {
		// Skip empty lines
		if len(line) == 0 do continue

		field_iter := Field_Iterator{line = line}
		is_range := false
		cp: rune
		name: string
		gc: General_Category

		num_6 : string
		num_7 : string
		nt := Numeric_Type.None
		nv : Numberic_Value

		for field, field_num in field_iterator(&field_iter) {
			switch field_num {
			case 0: // Code point
				cp = 0

				for c in field {
					if !(c >= '0' && c <= '9') && !(c >= 'A' && c <= 'F') do break 
					cp *= 16
					cp += cast(rune)(c >= '0' && c <= '9')  * cast(rune)(c - '0')  
					cp += cast(rune)(c >= 'A' && c <= 'F')  * cast(rune)(c - 'A' + 10)
				}

			case 1: // Name
				if len(field) > 9 && field[0] == '<' && strings.ends_with(transmute(string) field, ", First>") {
					first_cp = cp
					continue line_loop
				}
				
				if len(field) > 9 && field[0] == '<' && strings.ends_with(transmute(string) field, ", Last>") {
					name = strings.clone_from_bytes(field[1:len(field)-7], allocator)
					is_range = true
				} else {
					name = strings.clone_from_bytes(field[:], allocator)
				}

			case 2: // General_Category
				// NOTE: This is currently igorning a possible error it should probably be fixed
				gc, _ = string_to_general_category(transmute(string)field)

			case 3: // Canonical_Combining_Class
			case 4: // Bidi Class
			case 5: // Decomposition_Type and Decomposition_Mapping
			// Numeric_Type and Numberic_Value
			case 6:
				num_6 = transmute(string)field

			case 7:  
				num_7 = transmute(string)field

			case 8:
				switch {
				case num_6 != "" && num_7 != "" && transmute(string) field != "" :
					nt = .Decimal 

				case num_6 == "" && num_7 != "" && transmute(string) field != "" :
					nt = .Digit

				case num_6 == "" && num_7 == "" && transmute(string) field != "" :
					nt = .Numeric

				case:
					nt = .None
				}

			case 9: // Bidi mirrored
			case 10: // Unicode 1 Name (Obsolete as of 6.2.0)
			case 11: // should be null
			case 12:
			case 13:
			case 14:
			case: 
				unreachable()
			}
		}

		if is_range {
			cr : Char_Range
			cr.gc = gc
			cr.first_cp = first_cp
			cr.last_cp = cp
			cr.name = name
			cr.nt = nt
			append(&unicode_data, cr)
		} else {
			c : Char
			c.gc = gc
			c.cp = cp
			c.name = name
			c.nt = nt
			append(&unicode_data, c)
		}
	}
	return
}

destroy_unicode_data :: proc(unicode_data: Unicode_Data){
	for point in unicode_data {
		switch p in point {
		case Char:
			delete(p.name)
		case Char_Range:
			delete(p.name)
		}
	}
	delete(unicode_data)
}


gc_ranges :: proc(ud: ^Unicode_Data, allocator := context.allocator) -> (lst: [General_Category]Dynamic_Range) {
	range := Range_Rune {
		first = -1,
		last = -1,
	}
	gc: General_Category

	for point in ud {
		switch p in point {
		case Char:
			if range.first != -1 && (p.cp != range.last + 1 || p.gc != gc) {
				append_to_dynamic_range(&lst[gc], range, allocator)
				range.first = -1
				range.last = -1
			}

			range.first = transmute(rune) min(transmute(u32)range.first, transmute(u32)p.cp)
			gc = p.gc
			range.last = p.cp	

		case Char_Range:
			if range.first != -1 do append_to_dynamic_range(&lst[gc], range, allocator)
			
			range.first = p.first_cp
			range.last = p.last_cp
			append_to_dynamic_range(&lst[p.gc], range ,allocator)
			range.first = -1
			range.last = -1
		}
	}
	if range.first != -1 do append_to_dynamic_range(&lst[gc], range, allocator)

	return
}


extra_digits :: proc(ud: ^Unicode_Data, allocator := context.allocator) -> (Dynamic_Range) {
	range := Range_Rune {
		first = -1,
		last = -1,
	}

	exd: Dynamic_Range
	for point in ud {
		switch p in point {

		case Char:
			exd_type :=  p.gc != .Nd && (p.nt == .Decimal || p.nt == .Digit)

			if range.first != -1 && (p.cp != range.last + 1 || !exd_type) {
				append_to_dynamic_range(&exd, range, allocator)
				range.first = -1
				range.last = -1
			}
		
			if exd_type {
				range.first = transmute(rune) min(transmute(u32)range.first, transmute(u32)p.cp)
				range.last = p.cp	
			}

		case Char_Range:
			exd_type :=  p.gc != .Nd && (p.nt == .Decimal || p.nt == .Digit)

			if range.first != -1 do append_to_dynamic_range(&exd, range, allocator)
		
			if exd_type {
				range.first = p.first_cp
				range.last = p.last_cp
				append_to_dynamic_range(&exd, range ,allocator)
			}
			range.first = -1
			range.last = -1
		}
	}
	if range.first != -1 do append_to_dynamic_range(&exd, range, allocator)

	return exd
}

/*
Data containted in the Unicode fiel PropList.txt 

A `PropList` is the data containted in the Unicode Database (UCD) file 
PropList.txt. It is created with the procedure `load_property_list` and 
destroy with the procedure `destroy_property_list`.
*/
PropList ::[PropList_Property]Dynamic_Range

/*
This function destroys a `PropList` created by `load_property_list`.

Inputs:
- props: The PropList to destroy
*/
destroy_protperty_list :: proc(
	props: [PropList_Property]Dynamic_Range,
){
	for r in props {
		delete(r.ranges_16)
		delete(r.ranges_32)
		delete(r.single_16)
		delete(r.single_32)
	}
}

load_protperty_list :: proc (
	filename : string,
	allocator := context.allocator,
) -> (props: [PropList_Property]Dynamic_Range, err: Error) {

	data, os_error := os.read_entire_file(filename, allocator)
	if os_error != nil {
		err = os_error
		return 
	}
	defer delete(data)

	line_iter := Line_Iterator{
		data = data
	}
	for line in line_iterator(&line_iter) {
		if len(line) == 0 do continue
		field_iter := Field_Iterator{ line = line}

		is_range: bool

		rr : Range_Rune

		prop: PropList_Property 
		for field, i in field_iterator(&field_iter) {
			switch i {
			case 0: // Code point or code point range
				for c in field {
					if !(c >= '0' && c <= '9') && !(c >= 'A' && c <= 'F') {
						if c == '.' {
							is_range = true
							rr.last = 0
							continue
						} else {
							err = UCD_Error.Invalid_Hex_Number
							return
						}
					}
					if is_range {
						rr.last *= 16
						rr.last += cast(rune)(c >= '0' && c <= '9')  * cast(rune)(c - '0')  
						rr.last += cast(rune)(c >= 'A' && c <= 'F')  * cast(rune)(c - 'A' + 10)
					} else {
						rr.first *= 16
						rr.first += cast(rune)(c >= '0' && c <= '9')  * cast(rune)(c - '0')  
						rr.first += cast(rune)(c >= 'A' && c <= 'F')  * cast(rune)(c - 'A' + 10)
						rr.last = rr.first
					}
				}

			case 1:
				prop, err = string_to_proplist_property(transmute(string)field)
				if err != nil {
					return
				}

			case:
				err = UCD_Error.Extra_Fields
				return
			}
		}

		append_to_dynamic_range(&props[prop], rr, allocator)
	}

	return
}



