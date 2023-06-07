/*
	Copyright 2023 oskarnp <oskarnp@proton.me>
	Made available under Odin's BSD-3 license.

	List of contributors:
		oskarnp: Initial implementation.
*/

package text_table

import "core:io"
import "core:fmt"
import "core:mem"
import "core:mem/virtual"
import "core:runtime"

Cell :: struct {
	text: string,
	alignment: Cell_Alignment,
}

Cell_Alignment :: enum {
	Left,
	Center,
	Right,
}

Table :: struct {
	lpad, rpad: int, // Cell padding (left/right)
	cells: [dynamic]Cell,
	caption: string,
	nr_rows, nr_cols: int,
	has_header_row: bool,
	table_allocator: runtime.Allocator,  // Used for allocating cells/colw
	format_allocator: runtime.Allocator, // Used for allocating Cell.text when applicable

	dirty: bool, // True if build() needs to be called before rendering

	// The following are computed on build()
	colw: [dynamic]int, // Width of each column (including padding, excluding borders)
	tblw: int,          // Width of entire table (including padding, excluding borders)
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
	tbl.dirty = true
}

padding :: proc(tbl: ^Table, lpad, rpad: int) {
	tbl.lpad = lpad
	tbl.rpad = rpad
	tbl.dirty = true
}

get_cell :: proc(tbl: ^Table, row, col: int, loc := #caller_location) -> ^Cell {
	assert(col >= 0 && col < tbl.nr_cols, "cell column out of range", loc)
	assert(row >= 0 && row < tbl.nr_rows, "cell row out of range", loc)
	resize(&tbl.cells, tbl.nr_cols * tbl.nr_rows)
	return &tbl.cells[row*tbl.nr_cols + col]
}

set_cell_value_and_alignment :: proc(tbl: ^Table, row, col: int, value: string, alignment: Cell_Alignment) {
	cell := get_cell(tbl, row, col)
	cell.text = format(tbl, "%v", value)
	cell.alignment = alignment
	tbl.dirty = true
}

set_cell_value :: proc(tbl: ^Table, row, col: int, value: any, loc := #caller_location) {
	cell := get_cell(tbl, row, col, loc)
	switch val in value {
	case nil:
		cell.text = ""
	case string:
		cell.text = string(val)
	case cstring:
		cell.text = string(val)
	case:
		cell.text = format(tbl, "%v", val)
		if cell.text == "" {
			fmt.eprintf("{} text/table: format() resulted in empty string (arena out of memory?)\n", loc)
		}
	}
	tbl.dirty = true
}

set_cell_alignment :: proc(tbl: ^Table, row, col: int, alignment: Cell_Alignment, loc := #caller_location) {
	cell := get_cell(tbl, row, col, loc)
	cell.alignment = alignment
	tbl.dirty = true
}

format :: proc(tbl: ^Table, _fmt: string, args: ..any, loc := #caller_location) -> string {
	context.allocator = tbl.format_allocator
	return fmt.aprintf(fmt = _fmt, args = args)
}

header :: proc(tbl: ^Table, values: ..any, loc := #caller_location) {
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

	tbl.dirty = true
}

row :: proc(tbl: ^Table, values: ..any, loc := #caller_location) {
	if tbl.nr_cols == 0 {
		if len(values) == 0 {
			panic("Cannot create row without values unless knowing amount of columns in advance")
		} else {
			tbl.nr_cols = len(values)
		}
	}
	tbl.nr_rows += 1
	for col in 0..<tbl.nr_cols {
		val := values[col] if col < len(values) else nil
		set_cell_value(tbl, last_row(tbl), col, val)
	}
	tbl.dirty = true
}

last_row :: proc(tbl: ^Table) -> int {
	return tbl.nr_rows - 1
}

header_row :: proc(tbl: ^Table) -> int {
	return 0 if tbl.has_header_row else -1
}

first_row :: proc(tbl: ^Table) -> int {
	return header_row(tbl)+1 if tbl.has_header_row else 0
}

build :: proc(tbl: ^Table) {
	tbl.dirty = false

	resize(&tbl.colw, tbl.nr_cols)
	mem.zero_slice(tbl.colw[:])

	for row in 0..<tbl.nr_rows {
		for col in 0..<tbl.nr_cols {
			cell := get_cell(tbl, row, col)
			if w := len(cell.text) + tbl.lpad + tbl.rpad; w > tbl.colw[col] {
				tbl.colw[col] = w
			}
		}
	}

	colw_sum := 0
	for v in tbl.colw {
		colw_sum += v
	}

	tbl.tblw = max(colw_sum, len(tbl.caption) + tbl.lpad + tbl.rpad)

	// Resize columns to match total width of table
	remain := tbl.tblw-colw_sum
	for col := 0; remain > 0; col = (col + 1) % tbl.nr_cols {
		tbl.colw[col] += 1
		remain -= 1
	}

	return
}

write_html_table :: proc(w: io.Writer, tbl: ^Table) {
	if tbl.dirty {
		build(tbl)
	}

	io.write_string(w, "<table>\n")
	if tbl.caption != "" {
		io.write_string(w, "<caption>")
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
		io.write_string(w, "<thead>\n")
		io.write_string(w, "  <tr>\n")
		for col in 0..<tbl.nr_cols {
			cell := get_cell(tbl, header_row(tbl), col)
			io.write_string(w, "    <th")
			io.write_string(w, align_attribute(cell))
			io.write_string(w, ">")
			io.write_string(w, cell.text)
			io.write_string(w, "</th>\n")
		}
		io.write_string(w, "  </tr>\n")
		io.write_string(w, "</thead>\n")
	}

	io.write_string(w, "<tbody>\n")
	for row in 0..<tbl.nr_rows {
		if tbl.has_header_row && row == header_row(tbl) {
			continue
		}
		io.write_string(w, "  <tr>\n")
		for col in 0..<tbl.nr_cols {
			cell := get_cell(tbl, row, col)
			io.write_string(w, "    <td")
			io.write_string(w, align_attribute(cell))
			io.write_string(w, ">")
			io.write_string(w, cell.text)
			io.write_string(w, "</td>\n")
		}
		io.write_string(w, "  </tr>\n")
	}
	io.write_string(w, "  </tbody>\n")

	io.write_string(w, "</table>\n")
}

write_ascii_table :: proc(w: io.Writer, tbl: ^Table) {
	if tbl.dirty {
		build(tbl)
	}

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
			write_byte_repeat(w, tbl.colw[col], '-')
			io.write_byte(w, '+')
		}
		io.write_byte(w, '\n')
	}

	if tbl.caption != "" {
		write_caption_separator(w, tbl)
		io.write_byte(w, '|')
		write_text_align(w, tbl.tblw -  tbl.lpad - tbl.rpad + tbl.nr_cols - 1,
		                 tbl.lpad, tbl.rpad, tbl.caption, .Center)
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

// Renders table according to GitHub Flavored Markdown (GFM) specification
write_markdown_table :: proc(w: io.Writer, tbl: ^Table) {
	// NOTE(oskar): Captions or colspans are not supported by GFM as far as I can tell.

	if tbl.dirty {
		build(tbl)
	}

	for row in 0..<tbl.nr_rows {
		for col in 0..<tbl.nr_cols {
			cell := get_cell(tbl, row, col)
			if col == 0 {
				io.write_byte(w, '|')
			}
			write_text_align(w, tbl.colw[col] - tbl.lpad - tbl.rpad, tbl.lpad, tbl.rpad, cell.text,
			                 .Center if tbl.has_header_row && row == header_row(tbl) else .Left)
			io.write_string(w, "|")
		}
		io.write_byte(w, '\n')

		if tbl.has_header_row && row == header_row(tbl) {
			for col in 0..<tbl.nr_cols {
				cell := get_cell(tbl, row, col)
				if col == 0 {
					io.write_byte(w, '|')
				}
				switch cell.alignment {
				case .Left:
					io.write_byte(w, ':')
					write_byte_repeat(w, max(1, tbl.colw[col]-1), '-')
				case .Center:
					io.write_byte(w, ':')
					write_byte_repeat(w, max(1, tbl.colw[col]-2), '-')
					io.write_byte(w, ':')
				case .Right:
					write_byte_repeat(w, max(1, tbl.colw[col]-1), '-')
					io.write_byte(w, ':')
				}
				io.write_byte(w, '|')
			}
			io.write_byte(w, '\n')
		}
	}
}

write_byte_repeat :: proc(w: io.Writer, n: int, b: byte) {
	for _ in 0..<n {
		io.write_byte(w, b)
	}
}

write_table_cell :: proc(w: io.Writer, tbl: ^Table, row, col: int) {
	if tbl.dirty {
		build(tbl)
	}
	cell := get_cell(tbl, row, col)
	write_text_align(w, tbl.colw[col]-tbl.lpad-tbl.rpad, tbl.lpad, tbl.rpad, cell.text, cell.alignment)
}

write_text_align :: proc(w: io.Writer, colw, lpad, rpad: int, text: string, alignment: Cell_Alignment) {
	write_byte_repeat(w, lpad, ' ')
	switch alignment {
	case .Left:
		io.write_string(w, text)
		write_byte_repeat(w, colw - len(text), ' ')
	case .Center:
		pad := colw - len(text)
		odd := pad & 1 != 0
		write_byte_repeat(w, pad/2, ' ')
		io.write_string(w, text)
		write_byte_repeat(w, pad/2 + 1 if odd else pad/2, ' ')
	case .Right:
		write_byte_repeat(w, colw - len(text), ' ')
		io.write_string(w, text)
	}
	write_byte_repeat(w, rpad, ' ')
}
