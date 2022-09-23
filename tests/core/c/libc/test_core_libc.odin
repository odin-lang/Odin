package test_core_libc

import "core:fmt"
import "core:os"
import "core:strings"
import "core:testing"

expect  :: testing.expect
log     :: testing.log

main :: proc() {
	t := testing.T{}
	test_libc_complex(&t)

	if t.error_count > 0 {
		os.exit(1)
	}
}
