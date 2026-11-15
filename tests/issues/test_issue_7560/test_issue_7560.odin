package test_issue_7560

import "core:testing"

// Indexing a global matrix with a runtime index emitted a constant GEP with a non-constant index, which LLVM
// rejected with "Use of instruction is not an instruction!".

global_col := matrix[2, 3]i32{
	1, 2, 3,
	4, 5, 6,
}

global_row := #row_major matrix[2, 3]i32{
	1, 2, 3,
	4, 5, 6,
}

global_store: matrix[3, 3]i32

@(test)
test_global_matrix_runtime_index_read :: proc(t: ^testing.T) {
	i, r, c := 1, 1, 2

	testing.expect_value(t, global_col[i], [2]i32{2, 5})
	testing.expect_value(t, global_row[i], [3]i32{4, 5, 6})
	testing.expect_value(t, global_col[r, c], 6)
	testing.expect_value(t, global_row[r, c], 6)
}

@(test)
test_global_matrix_runtime_index_write :: proc(t: ^testing.T) {
	for i in 0..<3 {
		global_store[i] = {i32(i), i32(i), i32(i)}
	}
	for i in 0..<3 {
		global_store[i, i] = 9
	}

	testing.expect_value(t, global_store, matrix[3, 3]i32{
		9, 1, 2,
		0, 9, 2,
		0, 1, 9,
	})
}
