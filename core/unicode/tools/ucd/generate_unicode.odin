package ucd

import "core:fmt"
import "core:os"
import "core:strings"
import "core:mem"
import "core:io"
import "core:log"

// Table 2-3. Types of Code Points
// Table 4-4. General_Category Values page 229
// Reference https://www.unicode.org/reports/tr44/

/*
Formats a `Dynamic_Range` into a set of fixed length arrays and writes them to an `io.Writer`.
The value of the parameter `name` will be used as a prefix to the array names.

If a dynamic array contained in the `range` is empty, no corresponding fixed length array will be written.

Inputs:
- writer: The `io.Writer` to be written to.
- name: Prefix to add to any array that is written to `writer`
- range: `The Dynamic_Range` to format and write to writer.
*/
write_range_arrays :: proc(writer: io.Writer, name: string, range: Dynamic_Range) {
	if len(range.single_16) > 0 {
		fmt.wprintln(writer, "@(rodata)")
		fmt.wprintf(writer, "%s_singles16 := [?]u16{{", name)
		for v, count in range.single_16 {
			if count % 8 == 0 {
				fmt.wprintf(writer, "\n\t0x%4X,", v)
				continue
			} else {
				fmt.wprintf(writer, " 0x%4X,", v)
			}
		}
		fmt.wprintln(writer, "\n}\n")
	}

	if len(range.ranges_16) > 0 {
		fmt.wprintln(writer, "@(rodata)")
		fmt.wprintfln(writer, "%s_ranges16 := [?]u16{{", name)
		for v in range.ranges_16 {
			fmt.wprintfln(writer, "\t0x%4X, 0x%4X,", v.first, v.last)
		}
		fmt.wprintln(writer, "}\n")
	}

	if len(range.single_32) > 0 {
		fmt.wprintln(writer, "@(rodata)")
		fmt.wprintf(writer, "%s_singles32 := [?]i32{{", name)
		for v, count in range.single_32 {
			if count % 8 == 0 {
				fmt.wprintf(writer, "\n\t0x%4X,", v)
				continue
			} else {
				fmt.wprintf(writer, " 0x%4X,", v)
			}
		}
		fmt.wprintln(writer, "\n}\n")
	}

	if len(range.ranges_32) > 0 {
		fmt.wprintln(writer, "@(rodata)")
		fmt.wprintfln(writer, "%s_ranges32 := [?]i32{{", name)
		for v in range.ranges_32 {
			fmt.wprintfln(writer, "\t0x%4X, 0x%4X,", v.first, v.last)
		}
		fmt.wprintln(writer, "}\n")
	}

	return
}

write_range :: proc(writer: io.Writer, name: union{string, General_Category}, range: Dynamic_Range) {
	buffer: [128]byte
	str: string

	switch n in name {
	case string:
		assert(len(n) <= len(buffer))
		copy(buffer[:], n)
		str = string(buffer[:len(n)])

	case General_Category:
		str = fmt.bprintf(buffer[:], "%s", n)
	}

	// lowercase table names
	for &b in buffer[0:len(str)] {
		if b >= 'A' && b <= 'Z' {
			b += ('a' - 'A')
		}
	}

	write_range_arrays(writer, str, range)

	fmt.wprintfln(writer, "%s_ranges := Range{{", str)
	if len(range.single_16) > 0 {
		fmt.wprintfln(writer, "\tsingle_16 = %s_singles16[:],", str)
	}
	if len(range.ranges_16) > 0 {
		fmt.wprintfln(writer, "\tranges_16 = %s_ranges16[:],", str)
	}
	if len(range.single_32) > 0 {
		fmt.wprintfln(writer, "\tsingle_32 = %s_singles32[:],", str)
	}
	if len(range.ranges_32) > 0 {
		fmt.wprintfln(writer, "\tranges_32 = %s_ranges32[:],", str)
	}
	fmt.wprintln(writer, "}\n")

	return
}

GENERATED :: `/*
	------ GENERATED ------ DO NOT EDIT ------ GENERATED ------ DO NOT EDIT ------ GENERATED ------
*/
`

MESSAGE :: `/*
	This file is generated from UnicodeData.txt and PropList.txt. These files
	are part of the Unicode Database (UCD) and are covered by the license
	listed further down. They may be downloaded from the following locations;

	https://www.unicode.org/Public/UCD/latest/ucd/UnicodeData.txt
	https://www.unicode.org/Public/UCD/latest/ucd/PropList.txt
	https://www.unicode.org/license.txt

	------------------------------------------------------------------------------
	UNICODE LICENSE V3

	COPYRIGHT AND PERMISSION NOTICE

	Copyright © 1991-2026 Unicode, Inc.

	NOTICE TO USER: Carefully read the following legal agreement. BY
	DOWNLOADING, INSTALLING, COPYING OR OTHERWISE USING DATA FILES, AND/OR
	SOFTWARE, YOU UNEQUIVOCALLY ACCEPT, AND AGREE TO BE BOUND BY, ALL OF THE
	TERMS AND CONDITIONS OF THIS AGREEMENT. IF YOU DO NOT AGREE, DO NOT
	DOWNLOAD, INSTALL, COPY, DISTRIBUTE OR USE THE DATA FILES OR SOFTWARE.

	Permission is hereby granted, free of charge, to any person obtaining a
	copy of data files and any associated documentation (the "Data Files") or
	software and any associated documentation (the "Software") to deal in the
	Data Files or Software without restriction, including without limitation
	the rights to use, copy, modify, merge, publish, distribute, and/or sell
	copies of the Data Files or Software, and to permit persons to whom the
	Data Files or Software are furnished to do so, provided that either (a)
	this copyright and permission notice appear with all copies of the Data
	Files or Software, or (b) this copyright and permission notice appear in
	associated Documentation.

	THE DATA FILES AND SOFTWARE ARE PROVIDED "AS IS", WITHOUT WARRANTY OF ANY
	KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
	MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT OF
	THIRD PARTY RIGHTS.

	IN NO EVENT SHALL THE COPYRIGHT HOLDER OR HOLDERS INCLUDED IN THIS NOTICE
	BE LIABLE FOR ANY CLAIM, OR ANY SPECIAL INDIRECT OR CONSEQUENTIAL DAMAGES,
	OR ANY DAMAGES WHATSOEVER RESULTING FROM LOSS OF USE, DATA OR PROFITS,
	WHETHER IN AN ACTION OF CONTRACT, NEGLIGENCE OR OTHER TORTIOUS ACTION,
	ARISING OUT OF OR IN CONNECTION WITH THE USE OR PERFORMANCE OF THE DATA
	FILES OR SOFTWARE.

	Except as contained in this notice, the name of a copyright holder shall
	not be used in advertising or otherwise to promote the sale, use or other
	dealings in these Data Files or Software without prior written
	authorization of the copyright holder.

*/
`

main :: proc() {
	track: mem.Tracking_Allocator

	mem.tracking_allocator_init(&track, context.allocator)
	defer {
		if len(track.allocation_map) > 0 {
			fmt.eprintf("=== %v allocations not freed: ===\n", len(track.allocation_map))
			for _, entry in track.allocation_map {
				fmt.eprintf("- %v bytes @ %v\n", entry.size, entry.location)
			}
		}
		mem.tracking_allocator_destroy(&track)
	}

	context.allocator = mem.tracking_allocator(&track)

	context.logger = log.create_console_logger()
	defer log.destroy_console_logger(context.logger)

	ucd_path := ODIN_ROOT + "tests/core/assets/UCD/UnicodeData.txt"

	unicode_data, ucd_err := load_unicode_data(ucd_path)
	if ucd_err != nil {
		log.errorf("Error loading Unicode data. %s", ucd_err)
	}
	defer destroy_unicode_data(unicode_data)

	general_category_ranges := gc_ranges(&unicode_data)
	defer destroy_general_category_ranges(general_category_ranges)

	extra_digits := extra_digits(&unicode_data)
	defer destroy_dynamic_range(extra_digits)


	proplist_path := ODIN_ROOT + "tests/core/assets/UCD/PropList.txt"
	proplist, proplist_err := load_property_list(proplist_path)
	if proplist_err != nil {
		log.errorf("Error loading PropList.txt. %s", proplist_err)
		return
	}
	defer destroy_property_list(proplist)

	sb := strings.builder_make_len_cap(0, 1024*32)
	defer strings.builder_destroy(&sb)

	writer := strings.to_writer(&sb)

	fmt.wprintfln(writer, "package unicode\n")
	fmt.wprintln(writer, GENERATED)
	fmt.wprintln(writer, MESSAGE)

	Range_Type :: "Range :: struct {\n" +
		"\tsingle_16 : []u16,\n" +
		"\tranges_16 : []u16,\n" +
		"\tsingle_32 : []i32,\n" +
		"\tranges_32 : []i32,\n" +
		"}\n"

	fmt.wprintfln(writer, "%s", Range_Type)

	//List of the general categories to skip when generating the code for
	//core/unicode/generated.txt.
	to_exclude := [?]General_Category{
		.Cc, // Control, a C0 or C1 control code
		.Cf, // Format, a format control character
		.Cn, // Unassigned, a reserved unassigned code point or a noncharacter
		.Co, // Private_Use, a private-use character
		.Cs, // Surrogate, a surrogate code point
		// .Ll, // Lowercase_Letter, a lowercase letter
		// .Lm, // Modifier_Letter, a modifier letter
		// .Lo, // Other_Letter, other letters, including syllables and ideographs
		// .Lt, // Titlecase_Letter, a digraph encoded as a single character, with first part uppercase
		// .Lu, // Uppercase_Letter, an uppercase letter
		// .Mc, // Spacing_Mark, a spacing combining mark (positive advance width)
		// .Me, // Enclosing_Mark, an enclosing combining mark
		// .Mn, // Nonspacing_Mark, a nonspacing combining mark (zero advance width)
		//.Nd, // Decimal_Number, a decimal digit
		//.Nl, // Letter_Number, a letterlike numeric character
		//.No, // Other_Number, a numeric character of other type
		// .Pc, // Connector_Punctuation, a connecting punctuation mark, like a tie
		// .Pd, // Dash_Punctuation, a dash or hyphen punctuation mark
		// .Pe, // Close_Punctuation, a closing punctuation mark (of a pair)
		// .Pf, // Final_Punctuation, a final quotation mark
		// .Pi, // Initial_Punctuation, an initial quotation mark
		// .Po, // Other_Punctuation, a punctuation mark of other type
		// .Ps, // Open_Punctuation, an opening punctuation mark (of a pair)
		// .Sc, // Currency_Symbol, a currency sign
		// .Sk, // Modifier_Symbol, a non-letterlike modifier symbol
		// .Sm, // Math_Symbol, a symbol of mathematical use
		// .So, // Other_Symbol, a symbol of other type
		 .Zl, // Line_Separator, U+2028 LINE SEPARATOR only
		 .Zp, // Paragraph_Separator, U+2029 PARAGRAPH SEPARATOR only
		//.Zs, // Space_Separator, a space character (of various non-zero widths)
	}

	write_loop: for range, category in general_category_ranges {
		for excluded in to_exclude {
			if category == excluded {
				continue write_loop
			}
		}
		write_range(writer, category, range)
	}

	write_range(writer, "extra_digits",    extra_digits)
	write_range(writer, "other_lowercase", proplist[.Other_Lowercase])
	write_range(writer, "other_uppercase", proplist[.Other_Uppercase])

	file_name := ODIN_ROOT + "core/unicode/generated.odin"

	if write_error := os.write_entire_file_from_string(file_name, strings.to_string(sb)); write_error != nil {
		log.errorf("Error %v writing %q", write_error, file_name)
	}
}