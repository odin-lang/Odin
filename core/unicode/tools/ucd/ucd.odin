package ucd

import "core:strings"
import "core:os"
import "core:strconv"

decode_rune :: proc(str: string) -> (cp1, cp2: rune, err: Error) {
	head, _, tail := strings.partition(str, "..")

	if _cp1, _ok := strconv.parse_int(head, 16); !_ok {
		return 0, 0, .Invalid_Hex_Number
	} else {
		cp1 = rune(_cp1)
	}

	if len(tail) == 0 {
		return cp1, cp1, nil
	}

	if _cp2, _ok := strconv.parse_int(tail, 16); !_ok {
		return 0, 0, .Invalid_Hex_Number
	} else {
		cp2 = rune(_cp2)
	}
	return
}

load_unicode_data :: proc(filename: string, allocator := context.allocator) -> (unicode_data: Unicode_Data, err: Error) {
	data := os.read_entire_file(filename, context.temp_allocator) or_return
	defer free_all(context.temp_allocator)

	first_cp: rune

	str := string(data)
	line_loop: for _line in strings.split_lines_iterator(&str) {
		// Ignore any comments
		line, _, _ := strings.partition(_line, "#")

		// Skip empty lines
		if len(line) == 0 { continue }

		is_range := false
		cp:    rune
		name:  string
		gc:    General_Category
		num_6: string
		num_7: string
		nt := Numeric_Type.None

		field_num := 0
		for _field in strings.split_iterator(&line, ";") {
			defer field_num += 1
			field := strings.trim_space(_field)

			switch field_num {
			case 0: // Code point
				cp, _ = decode_rune(field) or_return

			case 1: // Name
				if len(field) > 9 && field[0] == '<' && strings.ends_with(field, ", First>") {
					first_cp = cp
					continue line_loop
				}
				
				if len(field) > 9 && field[0] == '<' && strings.ends_with(field, ", Last>") {
					name = strings.clone(field[1:len(field)-7], allocator)
					is_range = true
				} else {
					name = strings.clone(field[:], allocator)
				}

			case 2: // General_Category
				// NOTE: This is currently igorning a possible error it should probably be fixed
				gc, _ = string_to_general_category(field)

			case 3: // Canonical_Combining_Class
			case 4: // Bidi Class
			case 5: // Decomposition_Type and Decomposition_Mapping
			// Numeric_Type and Numeric_Value
			case 6:
				num_6 = field

			case 7:  
				num_7 = field

			case 8:
				switch {
				case num_6 != "" && num_7 != "" && field != "" :
					nt = .Decimal 

				case num_6 == "" && num_7 != "" && field != "" :
					nt = .Digit

				case num_6 == "" && num_7 == "" && field != "" :
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

			range.first = rune(min(u32(range.first), u32(p.cp)))
			gc = p.gc
			range.last = p.cp	

		case Char_Range:
			if range.first != -1 {
				append_to_dynamic_range(&lst[gc], range, allocator)
			}
			
			range.first = p.first_cp
			range.last = p.last_cp
			append_to_dynamic_range(&lst[p.gc], range ,allocator)
			range.first = -1
			range.last = -1
		}
	}
	if range.first != -1 {
		append_to_dynamic_range(&lst[gc], range, allocator)
	}

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
				range.first = rune(min(u32(range.first), u32(p.cp)))
				range.last = p.cp	
			}

		case Char_Range:
			exd_type :=  p.gc != .Nd && (p.nt == .Decimal || p.nt == .Digit)

			if range.first != -1 {
				append_to_dynamic_range(&exd, range, allocator)
			}
		
			if exd_type {
				range.first = p.first_cp
				range.last = p.last_cp
				append_to_dynamic_range(&exd, range ,allocator)
			}
			range.first = -1
			range.last = -1
		}
	}
	if range.first != -1 {
		append_to_dynamic_range(&exd, range, allocator)
	}

	return exd
}

/*
Data contained in the Unicode fiel PropList.txt

A `Prop_List` is the data contained in the Unicode Database (UCD) file `PropList.txt`.
It is created with the procedure `load_property_list` and destroyed with the procedure `destroy_property_list`.
*/
Prop_List :: [PropList_Property]Dynamic_Range

/*
This function destroys a `Prop_List` created by `load_property_list`.

Inputs:
- props: The Prop_List to destroy
*/
destroy_property_list :: proc(props: Prop_List) {
	for r in props {
		delete(r.ranges_16)
		delete(r.ranges_32)
		delete(r.single_16)
		delete(r.single_32)
	}
}



load_property_list :: proc(filename: string, allocator := context.allocator) -> (props: Prop_List, err: Error) {
	data := os.read_entire_file(filename, allocator) or_return
	defer delete(data)

	str := string(data)
	for _line in strings.split_lines_iterator(&str) {
		line, _, _ := strings.partition(_line, "#")
		if len(line) == 0 {
			continue
		}

		rr:   Range_Rune
		prop: PropList_Property

		i := 0
		for _field in strings.split_iterator(&line, ";") {
			defer i += 1
			field := strings.trim_space(_field)

			switch i {
			case 0: // Code point or code point range
				rr.first, rr.last = decode_rune(field) or_return

			case 1:
				prop = string_to_proplist_property(field) or_return

			case:
				err = UCD_Error.Extra_Fields
				return
			}
		}

		append_to_dynamic_range(&props[prop], rr, allocator)
	}

	return
}