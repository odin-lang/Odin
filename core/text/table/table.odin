/*
	Copyright 2023 oskarnp <oskarnp@proton.me>
	Made available under Odin's BSD-3 license.

	List of contributors:
		oskarnp: Initial implementation.
		Feoramund: Unicode support.
*/

package text_table

import "core:io"
import "core:fmt"
import "core:log"
import "core:mem"
import "core:mem/virtual"
import "core:unicode/utf8"
import "base:runtime"

Cell :: struct {
	text: string,
	width: int,
	alignment: Cell_Alignment,
}

Cell_Alignment :: enum {
	Left,
	Center,
	Right,
}

Aligned_Value :: struct {
	alignment: Cell_Alignment,
	value: any,
}

// Determines the width of a string used in the table for alignment purposes.
Width_Proc :: #type proc(str: string) -> int

Table :: struct {
	lpad, rpad: int, // Cell padding (left/right)
	cells: [dynamic]Cell,
	caption: string,
	nr_rows, nr_cols: int,
	has_header_row: bool,
	table_allocator: runtime.Allocator,  // Used for allocating cells/colw
	format_allocator: runtime.Allocator, // Used for allocating Cell.text when applicable

	// The following are computed on build()
	colw: [dynamic]int, // Width of each column (excluding padding and borders)
	tblw: int,          // Width of entire table (including padding, excluding borders)
}

Decorations :: struct {
	// These are strings, because of multi-codepoint Unicode graphemes.

	// Connecting decorations:
	nw, n, ne,
	 w, x,  e,
	sw, s, se: string,

	// Straight lines:
	vert: string,
	horz: string,
}

ascii_width_proc :: proc(str: string) -> int {
	return len(str)
}

unicode_width_proc :: proc(str: string) -> (width: int) {
	_, _, width = #force_inline utf8.grapheme_count(str)
	return
}

init :: proc{init_with_allocator, init_with_virtual_arena, init_with_mem_arena}

init_with_allocator :: proc(tbl: ^Table, format_allocator := context.temp_allocator, table_allocator := context.allocator) -> ^Table {
	tbl.table_allocator = table_allocator
	tbl.cells = make([dynamic]Cell, tbl.table_allocator)
	tbl.colw = make([dynamic]int, tbl.table_allocator)
	tbl.format_allocator = format_allocator
	return tbl
}
init_with_virtual_arena :: proc(tbl: ^Table, format_arena: ^virtual.Arena, table_allocator := context.allocator) -> ^Table {
	return init_with_allocator(tbl, virtual.arena_allocator(format_arena), table_allocator)
}
init_with_mem_arena :: proc(tbl: ^Table, format_arena: ^mem.Arena, table_allocator := context.allocator) -> ^Table {
	return init_with_allocator(tbl, mem.arena_allocator(format_arena), table_allocator)
}

destroy :: proc(tbl: ^Table) {
	free_all(tbl.format_allocator)
	delete(tbl.cells)
	delete(tbl.colw)
}

caption :: proc(tbl: ^Table, value: string) {
	tbl.caption = value
}

padding :: proc(tbl: ^Table, lpad, rpad: int) {
	tbl.lpad = lpad
	tbl.rpad = rpad
}

get_cell :: proc(tbl: ^Table, row, col: int, loc := #caller_location) -> ^Cell {
	assert(col >= 0 && col < tbl.nr_cols, "cell column out of range", loc)
	assert(row >= 0 && row < tbl.nr_rows, "cell row out of range", loc)
	resize(&tbl.cells, tbl.nr_cols * tbl.nr_rows)
	return &tbl.cells[row*tbl.nr_cols + col]
}

@private
to_string :: #force_inline proc(tbl: ^Table, value: any, loc := #caller_location) -> (result: string) {
	switch val in value {
	case nil:
		result = ""
	case string:
		result = val
	case cstring:
		result = cast(string)val
	case:
		result = format(tbl, "%v", val)
		if result == "" {
			log.error("text/table.format() resulted in empty string (arena out of memory?)", location = loc)
		}
	}
	return
}

set_cell_value :: proc(tbl: ^Table, row, col: int, value: any, loc := #caller_location) {
	cell := get_cell(tbl, row, col, loc)
	cell.text = to_string(tbl, value, loc)
}

set_cell_alignment :: proc(tbl: ^Table, row, col: int, alignment: Cell_Alignment, loc := #caller_location) {
	cell := get_cell(tbl, row, col, loc)
	cell.alignment = alignment
}

set_cell_value_and_alignment :: proc(tbl: ^Table, row, col: int, value: any, alignment: Cell_Alignment, loc := #caller_location) {
	cell := get_cell(tbl, row, col, loc)
	cell.text = to_string(tbl, value, loc)
	cell.alignment = alignment
}

format :: proc(tbl: ^Table, _fmt: string, args: ..any) -> string {
	context.allocator = tbl.format_allocator
	return fmt.aprintf(_fmt, ..args)
}

header :: header_of_values
header_of_values :: proc(tbl: ^Table, values: ..any, loc := #caller_location) {
	if (tbl.has_header_row && tbl.nr_rows != 1) || (!tbl.has_header_row && tbl.nr_rows != 0) {
		panic("Cannot add headers after rows have been added", loc)
	}

	if tbl.nr_rows == 0 {
		tbl.nr_rows += 1
		tbl.has_header_row = true
	}

	col := tbl.nr_cols
	tbl.nr_cols += len(values)
	for val in values {
		set_cell_value(tbl, header_row(tbl), col, val, loc)
		col += 1
	}
}

aligned_header_of_values :: proc(tbl: ^Table, alignment: Cell_Alignment, values: ..any, loc := #caller_location) {
	if (tbl.has_header_row && tbl.nr_rows != 1) || (!tbl.has_header_row && tbl.nr_rows != 0) {
		panic("Cannot add headers after rows have been added", loc)
	}

	if tbl.nr_rows == 0 {
		tbl.nr_rows += 1
		tbl.has_header_row = true
	}

	col := tbl.nr_cols
	tbl.nr_cols += len(values)
	for val in values {
		set_cell_value_and_alignment(tbl, header_row(tbl), col, val, alignment, loc)
		col += 1
	}
}

header_of_aligned_values :: proc(tbl: ^Table, aligned_values: []Aligned_Value, loc := #caller_location) {
	if (tbl.has_header_row && tbl.nr_rows != 1) || (!tbl.has_header_row && tbl.nr_rows != 0) {
		panic("Cannot add headers after rows have been added", loc)
	}

	if tbl.nr_rows == 0 {
		tbl.nr_rows += 1
		tbl.has_header_row = true
	}

	col := tbl.nr_cols
	tbl.nr_cols += len(aligned_values)
	for av in aligned_values {
		set_cell_value_and_alignment(tbl, header_row(tbl), col, av.value, av.alignment, loc)
		col += 1
	}
}

row :: row_of_values
row_of_values :: proc(tbl: ^Table, values: ..any, loc := #caller_location) {
	if tbl.nr_cols == 0 {
		if len(values) == 0 {
			panic("Cannot create empty row unless the number of columns is known in advance")
		} else {
			tbl.nr_cols = len(values)
		}
	}

	tbl.nr_rows += 1

	for col in 0..<tbl.nr_cols {
		val := values[col] if col < len(values) else nil
		set_cell_value(tbl, last_row(tbl), col, val, loc)
	}
}

aligned_row_of_values :: proc(tbl: ^Table, alignment: Cell_Alignment, values: ..any, loc := #caller_location) {
	if tbl.nr_cols == 0 {
		if len(values) == 0 {
			panic("Cannot create empty row unless the number of columns is known in advance")
		} else {
			tbl.nr_cols = len(values)
		}
	}

	tbl.nr_rows += 1

	for col in 0..<tbl.nr_cols {
		val := values[col] if col < len(values) else nil
		set_cell_value_and_alignment(tbl, last_row(tbl), col, val, alignment, loc)
	}
}

row_of_aligned_values :: proc(tbl: ^Table, aligned_values: []Aligned_Value, loc := #caller_location) {
	if tbl.nr_cols == 0 {
		if len(aligned_values) == 0 {
			panic("Cannot create empty row unless the number of columns is known in advance")
		} else {
			tbl.nr_cols = len(aligned_values)
		}
	}

	tbl.nr_rows += 1

	for col in 0..<tbl.nr_cols {
		if col < len(aligned_values) {
			val := aligned_values[col].value
			alignment := aligned_values[col].alignment
			set_cell_value_and_alignment(tbl, last_row(tbl), col, val, alignment, loc)
		} else {
			set_cell_value_and_alignment(tbl, last_row(tbl), col, "", .Left, loc)
		}
	}
}

// TODO: This should work correctly when #3262 is fixed.
// row :: proc {
// 	row_of_values,
// 	aligned_row_of_values,
// 	row_of_aligned_values,
// }

last_row :: proc(tbl: ^Table) -> int {
	return tbl.nr_rows - 1
}

header_row :: proc(tbl: ^Table) -> int {
	return 0 if tbl.has_header_row else -1
}

first_row :: proc(tbl: ^Table) -> int {
	return header_row(tbl)+1 if tbl.has_header_row else 0
}

build :: proc(tbl: ^Table, width_proc: Width_Proc) {
	resize(&tbl.colw, tbl.nr_cols)
	mem.zero_slice(tbl.colw[:])

	for row in 0..<tbl.nr_rows {
		for col in 0..<tbl.nr_cols {
			cell := get_cell(tbl, row, col)
			cell.width = width_proc(cell.text)
			tbl.colw[col] = max(tbl.colw[col], cell.width)
		}
	}

	colw_sum := 0
	for v in tbl.colw {
		colw_sum += v + tbl.lpad + tbl.rpad
	}

	tbl.tblw = max(colw_sum, width_proc(tbl.caption) + tbl.lpad + tbl.rpad)

	// Resize columns to match total width of table
	remain := tbl.tblw-colw_sum
	for col := 0; remain > 0; col = (col + 1) % tbl.nr_cols {
		tbl.colw[col] += 1
		remain -= 1
	}

	return
}

write_html_table :: proc(w: io.Writer, tbl: ^Table) {
	io.write_string(w, "<table>\n")
	if tbl.caption != "" {
		io.write_string(w, "\t<caption>")
		io.write_string(w, tbl.caption)
		io.write_string(w, "</caption>\n")
	}

	align_attribute :: proc(cell: ^Cell) -> string {
		switch cell.alignment {
		case .Left:   return ` align="left"`
		case .Center: return ` align="center"`
		case .Right:  return ` align="right"`
		}
		unreachable()
	}

	if tbl.has_header_row {
		io.write_string(w, "\t<thead>\n")
		io.write_string(w, "\t\t<tr>\n")
		for col in 0..<tbl.nr_cols {
			cell := get_cell(tbl, header_row(tbl), col)
			io.write_string(w, "\t\t\t<th")
			io.write_string(w, align_attribute(cell))
			io.write_string(w, ">")
			io.write_string(w, cell.text)
			io.write_string(w, "</th>\n")
		}
		io.write_string(w, "\t\t</tr>\n")
		io.write_string(w, "\t</thead>\n")
	}

	io.write_string(w, "\t<tbody>\n")
	for row in 0..<tbl.nr_rows {
		if tbl.has_header_row && row == header_row(tbl) {
			continue
		}
		io.write_string(w, "\t\t<tr>\n")
		for col in 0..<tbl.nr_cols {
			cell := get_cell(tbl, row, col)
			io.write_string(w, "\t\t\t<td")
			io.write_string(w, align_attribute(cell))
			io.write_string(w, ">")
			io.write_string(w, cell.text)
			io.write_string(w, "</td>\n")
		}
		io.write_string(w, "\t\t</tr>\n")
	}
	io.write_string(w, "\t</tbody>\n")

	io.write_string(w, "</table>\n")
}

write_plain_table :: proc(w: io.Writer, tbl: ^Table, width_proc: Width_Proc = unicode_width_proc) {
	build(tbl, width_proc)

	write_caption_separator :: proc(w: io.Writer, tbl: ^Table) {
		io.write_byte(w, '+')
		write_byte_repeat(w, tbl.tblw + tbl.nr_cols - 1, '-')
		io.write_byte(w, '+')
		io.write_byte(w, '\n')
	}

	write_table_separator :: proc(w: io.Writer, tbl: ^Table) {
		for col in 0..<tbl.nr_cols {
			if col == 0 {
				io.write_byte(w, '+')
			}
			write_byte_repeat(w, tbl.colw[col] + tbl.lpad + tbl.rpad, '-')
			io.write_byte(w, '+')
		}
		io.write_byte(w, '\n')
	}

	if tbl.caption != "" {
		write_caption_separator(w, tbl)
		io.write_byte(w, '|')
		write_text_align(w, tbl.caption, .Center,
			tbl.lpad, tbl.rpad, tbl.tblw + tbl.nr_cols - 1 - width_proc(tbl.caption) - tbl.lpad - tbl.rpad)
		io.write_byte(w, '|')
		io.write_byte(w, '\n')
	}

	write_table_separator(w, tbl)
	for row in 0..<tbl.nr_rows {
		for col in 0..<tbl.nr_cols {
			if col == 0 {
				io.write_byte(w, '|')
			}
			write_table_cell(w, tbl, row, col)
			io.write_byte(w, '|')
		}
		io.write_byte(w, '\n')
		if tbl.has_header_row && row == header_row(tbl) {
			write_table_separator(w, tbl)
		}
	}
	write_table_separator(w, tbl)
}

write_decorated_table :: proc(w: io.Writer, tbl: ^Table, decorations: Decorations, width_proc: Width_Proc = unicode_width_proc) {
	draw_dividing_row :: proc(w: io.Writer, tbl: ^Table, left, horz, divider, right: string) {
		io.write_string(w, left)
		for col in 0..<tbl.nr_cols {
			for _ in 0..<tbl.colw[col] + tbl.lpad + tbl.rpad {
				io.write_string(w, horz)
			}
			if col < tbl.nr_cols-1 {
				io.write_string(w, divider)
			}
		}
		io.write_string(w, right)
		io.write_byte(w, '\n')
	}

	build(tbl, width_proc)

	// This determines whether or not to divide the top border.
	top_divider := decorations.n if len(tbl.caption) == 0 else decorations.horz

	// Draw the north border.
	draw_dividing_row(w, tbl, decorations.nw, decorations.horz, top_divider, decorations.ne)

	if len(tbl.caption) != 0 {
		// Draw the caption.
		io.write_string(w, decorations.vert)
		write_text_align(w, tbl.caption, .Center,
			tbl.lpad, tbl.rpad, tbl.tblw + tbl.nr_cols - 1 - width_proc(tbl.caption) - tbl.lpad - tbl.rpad)
		io.write_string(w, decorations.vert)
		io.write_byte(w, '\n')

		// Draw the divider between the caption and the table rows.
		draw_dividing_row(w, tbl, decorations.w, decorations.horz, decorations.n, decorations.e)
	}

	// Draw the header.
	start := 0
	if tbl.has_header_row {
		io.write_string(w, decorations.vert)
		row := header_row(tbl)
		for col in 0..<tbl.nr_cols {
			write_table_cell(w, tbl, row, col)
			io.write_string(w, decorations.vert)
		}
		io.write_byte(w, '\n')
		start += row + 1

		draw_dividing_row(w, tbl, decorations.w, decorations.horz, decorations.x, decorations.e)
	}

	// Draw the cells.
	for row in start..<tbl.nr_rows {
		for col in 0..<tbl.nr_cols {
			if col == 0 {
				io.write_string(w, decorations.vert)
			}
			write_table_cell(w, tbl, row, col)
			io.write_string(w, decorations.vert)
		}
		io.write_byte(w, '\n')
	}

	// Draw the south border.
	draw_dividing_row(w, tbl, decorations.sw, decorations.horz, decorations.s, decorations.se)
}

// Renders table according to GitHub Flavored Markdown (GFM) specification
write_markdown_table :: proc(w: io.Writer, tbl: ^Table, width_proc: Width_Proc = unicode_width_proc) {
	// NOTE(oskar): Captions or colspans are not supported by GFM as far as I can tell.
	build(tbl, width_proc)

	write_row :: proc(w: io.Writer, tbl: ^Table, row: int, alignment: Cell_Alignment = .Left) {
		for col in 0..<tbl.nr_cols {
			cell := get_cell(tbl, row, col)
			if col == 0 {
				io.write_byte(w, '|')
			}
			write_text_align(w, cell.text, alignment, tbl.lpad, tbl.rpad, tbl.colw[col] - cell.width)
			io.write_string(w, "|")
		}
		io.write_byte(w, '\n')
	}

	start := 0

	if tbl.has_header_row {
		row := header_row(tbl)

		write_row(w, tbl, row, .Center)

		for col in 0..<tbl.nr_cols {
			cell := get_cell(tbl, row, col)
			if col == 0 {
				io.write_byte(w, '|')
			}
			divider_width := tbl.colw[col] + tbl.lpad + tbl.rpad - 1
			switch cell.alignment {
			case .Left:
				io.write_byte(w, ':')
				write_byte_repeat(w, max(1, divider_width), '-')
			case .Center:
				io.write_byte(w, ':')
				write_byte_repeat(w, max(1, divider_width - 1), '-')
				io.write_byte(w, ':')
			case .Right:
				write_byte_repeat(w, max(1, divider_width), '-')
				io.write_byte(w, ':')
			}
			io.write_byte(w, '|')
		}
		io.write_byte(w, '\n')

		start += row + 1
	}

	for row in start..<tbl.nr_rows {
		write_row(w, tbl, row)
	}
}

write_byte_repeat :: proc(w: io.Writer, n: int, b: byte) {
	for _ in 0..<n {
		io.write_byte(w, b)
	}
}

write_table_cell :: proc(w: io.Writer, tbl: ^Table, row, col: int) {
	cell := get_cell(tbl, row, col)
	write_text_align(w, cell.text, cell.alignment, tbl.lpad, tbl.rpad, tbl.colw[col] - cell.width)
}

write_text_align :: proc(w: io.Writer, text: string, alignment: Cell_Alignment, lpad, rpad, space: int) {
	write_byte_repeat(w, lpad, ' ')
	switch alignment {
	case .Left:
		io.write_string(w, text)
		write_byte_repeat(w, space, ' ')
	case .Center:
		write_byte_repeat(w, space/2, ' ')
		io.write_string(w, text)
		write_byte_repeat(w, space/2 + space & 1, ' ')
	case .Right:
		write_byte_repeat(w, space, ' ')
		io.write_string(w, text)
	}
	write_byte_repeat(w, rpad, ' ')
}
