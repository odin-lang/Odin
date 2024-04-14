/*
The package `table` implements ASCII/markdown/HTML/custom rendering of tables.

**Custom rendering example:**

	tbl := init(&Table{})
	padding(tbl, 0, 1)
	row(tbl, "A_LONG_ENUM", "= 54,", "// A comment about A_LONG_ENUM")
	row(tbl, "AN_EVEN_LONGER_ENUM", "= 1,", "// A comment about AN_EVEN_LONGER_ENUM")
	build(tbl)
	for row in 0..<tbl.nr_rows {
		for col in 0..<tbl.nr_cols {
			write_table_cell(stdio_writer(), tbl, row, col)
		}
		io.write_byte(stdio_writer(), '\n')
	}

This outputs:

	A_LONG_ENUM         = 54, // A comment about A_LONG_ENUM
	AN_EVEN_LONGER_ENUM = 1,  // A comment about AN_EVEN_LONGER_ENUM

**ASCII rendering example:**

	tbl := init(&Table{})
	defer destroy(tbl)

	caption(tbl, "This is a table caption and it is very long")

	padding(tbl, 1, 1) // Left/right padding of cells

	header(tbl, "AAAAAAAAA", "B")
	header(tbl, "C") // Appends to previous header row. Same as if done header("AAAAAAAAA", "B", "C") from start.

	// Create a row with two values. Since there are three columns the third
	// value will become the empty string.
	//
	// NOTE: header() is not allowed anymore after this.
	row(tbl, 123, "foo")

	// Use `format()` if you need custom formatting. This will allocate into
	// the arena specified at init.
	row(tbl,
	    format(tbl, "%09d", 5),
	    format(tbl, "%.6f", 6.28318530717958647692528676655900576))

	// A row with zero values is allowed as long as a previous row or header
	// exist. The value and alignment of each cell can then be set
	// individually.
	row(tbl)
		set_cell_value_and_alignment(tbl, last_row(tbl), 0, "a", .Center)
		set_cell_value(tbl, last_row(tbl), 1, "bbb")
		set_cell_value(tbl, last_row(tbl), 2, "c")

	// Headers are regular cells, too. Use header_row() as row index to modify
	// header cells.
	set_cell_alignment(tbl, header_row(tbl), 1, .Center) // Sets alignment of 'B' column to Center.
	set_cell_alignment(tbl, header_row(tbl), 2, .Right) // Sets alignment of 'C' column to Right.

	build(tbl)

	write_ascii_table(stdio_writer(), tbl)
	write_markdown_table(stdio_writer(), tbl)

This outputs:

	+-----------------------------------------------+
	|  This is a table caption and it is very long  |
	+------------------+-----------------+----------+
	| AAAAAAAAA        |        B        |        C |
	+------------------+-----------------+----------+
	| 123              | foo             |          |
	| 000000005        | 6.283185        |          |
	|        a         | bbb             | c        |
	+------------------+-----------------+----------+

and

	|    AAAAAAAAA     |        B        |    C     |
	|:-----------------|:---------------:|---------:|
	| 123              | foo             |          |
	| 000000005        | 6.283185        |          |
	| a                | bbb             | c        |

respectively.
*/
package text_table
