package test_issue_define_config

import "core:testing"

E :: enum { A, B, C }

Distinct_String :: distinct string

VERSION_STRING  :: #config(DEFINE_VERSION, "")
VERSION_FLOAT   :: #config(DEFINE_VERSION, 0.0)
VERSION_F32     :: #config(DEFINE_VERSION, f32(0))
MODE_STRING     :: #config(DEFINE_MODE, "")
MODE_BOOL       :: #config(DEFINE_MODE, false)
MODE_B8         :: #config(DEFINE_MODE, b8(false))
HEX_INT         :: #config(DEFINE_HEX, 0)
HEX_STRING      :: #config(DEFINE_HEX, "")
MAX_U8          :: #config(DEFINE_MAX_U8, u8(0))
MIN_I32         :: #config(DEFINE_MIN_I32, i32(0))
INTEGRAL_FLOAT  :: #config(DEFINE_INTEGRAL_FLOAT, 0)
INT_FOR_FLOAT   :: #config(DEFINE_INT_FOR_FLOAT, 0.0)
EXPONENT        :: #config(DEFINE_EXPONENT, f64(0))
SEPARATORS      :: #config(DEFINE_SEPARATORS, int(0))
RUNE            :: #config(DEFINE_RUNE, 'a')
ENUM            :: #config(DEFINE_ENUM, E.A)
ENUM_STRING     :: #config(DEFINE_ENUM, "")
QUOTED          :: #config(DEFINE_QUOTED, "")
EMPTY           :: #config(DEFINE_EMPTY, "default")
SPACED          :: #config(DEFINE_SPACED, "")
CSTRING         :: #config(DEFINE_CSTRING, cstring(""))
DISTINCT_STRING :: #config(DEFINE_DISTINCT_STRING, Distinct_String(""))
UNSET           :: #config(DEFINE_UNSET, 42)

@(test)
test_define_config :: proc(t: ^testing.T) {
	testing.expect_value(t, VERSION_STRING, "1.0")
	testing.expect_value(t, VERSION_FLOAT, 1.0)
	testing.expect_value(t, VERSION_F32, f32(1.0))
	testing.expect_value(t, MODE_STRING, "true")
	testing.expect_value(t, MODE_BOOL, true)
	testing.expect_value(t, MODE_B8, b8(true))
	testing.expect_value(t, HEX_INT, -127)
	testing.expect_value(t, HEX_STRING, "-0x7f")
	testing.expect_value(t, MAX_U8, u8(255))
	testing.expect_value(t, MIN_I32, min(i32))
	testing.expect_value(t, INTEGRAL_FLOAT, 2)
	testing.expect_value(t, INT_FOR_FLOAT, 3.0)
	testing.expect_value(t, EXPONENT, 1.0)
	testing.expect_value(t, SEPARATORS, 1_000_000)
	testing.expect_value(t, RUNE, 'A')
	testing.expect_value(t, ENUM, E.C)
	testing.expect_value(t, ENUM_STRING, "C")
	testing.expect_value(t, QUOTED, "'x'")
	testing.expect_value(t, EMPTY, "")
	testing.expect_value(t, SPACED, "a b")
	testing.expect_value(t, string(CSTRING), "c")
	testing.expect_value(t, DISTINCT_STRING, Distinct_String("d"))
	testing.expect_value(t, UNSET, 42)
	testing.expect(t, !#defined(DEFINE_VERSION))
}
