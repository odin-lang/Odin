//+private
package testing

import "core:io"
import "core:os"
import "core:slice"

reset_t :: proc(t: ^T) {
	clear(&t.cleanups)
	t.error_count = 0
}
end_t :: proc(t: ^T) {
	for i := len(t.cleanups)-1; i >= 0; i -= 1 {
		c := t.cleanups[i]
		c.procedure(c.user_data)
	}
}

runner :: proc(internal_tests: []Internal_Test) -> bool {
	stream := os.stream_from_handle(os.stdout)
	w := io.to_writer(stream)

	t := &T{}
	t.w = w
	reserve(&t.cleanups, 1024)
	defer delete(t.cleanups)

	total_success_count := 0
	total_test_count := len(internal_tests)

	slice.sort_by(internal_tests, proc(a, b: Internal_Test) -> bool {
		if a.pkg < b.pkg {
			return true
		}
		return a.name < b.name
	})

	prev_pkg := ""

	for it in internal_tests {
		if it.p == nil {
			total_test_count -= 1
			continue
		}

		free_all(context.temp_allocator)
		reset_t(t)
		defer end_t(t)

		if prev_pkg != it.pkg {
			prev_pkg = it.pkg
			logf(t, "[Package: %s]", it.pkg)
		}

		logf(t, "[Test: %s]", it.name)

		run_internal_test(t, it)

		if failed(t) {
			logf(t, "[%s : FAILURE]", it.name)
		} else {
			logf(t, "[%s : SUCCESS]", it.name)
			total_success_count += 1
		}
	}
	logf(t, "----------------------------------------")
	if total_test_count == 0 {
		log(t, "NO TESTS RAN")
	} else {
		logf(t, "%d/%d SUCCESSFUL", total_success_count, total_test_count)
	}
	return total_success_count == total_test_count
}
