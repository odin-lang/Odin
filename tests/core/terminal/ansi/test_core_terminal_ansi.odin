package test_core_terminal_ansi

import "core:terminal/ansi"
import "core:testing"

@(test)
test_sgr_and_color_buffer_overloads :: proc(t: ^testing.T) {
	sgr_buf: [ansi.CURSOR_SEQUENCE_BUF_MAX]byte
	testing.expect_value(t, ansi.sgr(ansi.FG_RED), "\x1b[31m")
	testing.expect_value(t, ansi.sgr(sgr_buf[:], ansi.FG_RED), "\x1b[31m")

	color_buf: [32]byte
	testing.expect_value(t, ansi.color("warning", ansi.FG_YELLOW), "\x1b[33mwarning\x1b[0m")
	testing.expect_value(
		t,
		ansi.color(color_buf[:], "warning", ansi.FG_YELLOW),
		"\x1b[33mwarning\x1b[0m",
	)
	testing.expect_value(t, ansi.color(42, ansi.FG_GREEN), "\x1b[32m42\x1b[0m")
	testing.expect_value(t, ansi.color(color_buf[:], 42, ansi.FG_GREEN), "\x1b[32m42\x1b[0m")
}

@(test)
test_cursor_movement_buffer_overloads :: proc(t: ^testing.T) {
	buf: [ansi.CURSOR_SEQUENCE_BUF_MAX]byte
	testing.expect_value(t, ansi.move_cursor(12, 4), "\x1b[12;4H")
	testing.expect_value(t, ansi.move_cursor(buf[:], 12, 4), "\x1b[12;4H")
	testing.expect_value(t, ansi.move_cursor_up(3), "\x1b[3A")
	testing.expect_value(t, ansi.move_cursor_up(buf[:], 3), "\x1b[3A")
	testing.expect_value(t, ansi.move_cursor_down(buf[:]), "\x1b[1B")
	testing.expect_value(t, ansi.move_cursor_forward(buf[:], 5), "\x1b[5C")
	testing.expect_value(t, ansi.move_cursor_backward(buf[:], 2), "\x1b[2D")
	testing.expect_value(t, ansi.move_cursor_previous_line(buf[:], 4), "\x1b[4F")
}
