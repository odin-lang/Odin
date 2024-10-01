package test_internal

import "core:log"
import "core:testing"

@(test)
test_internal_pointer_union_switch :: proc(t: ^testing.T) {
	foo: Maybe(^int)

	switch _ in foo {
	case ^int:
		log.error("incorrect case")
	case nil:
	}

	v := 1
	foo = &v

	switch _ in foo {
	case ^int:
	case nil:
		log.error("incorrect case")
	}
}
