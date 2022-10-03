// Tests "path.odin" in "core:path/filepath".
package test_core_filepath

import "core:fmt"
import "core:path/filepath"
import "core:testing"

@test
test_split_list_windows :: proc(t: ^testing.T) {

	using filepath

	Datum :: struct {
		i: int,
		v: string,
		e: [3]string,
	}
	@static data := []Datum{
		{ 0, "C:\\Odin;C:\\Visual Studio;\"C:\\Some Other\"",
			[3]string{"C:\\Odin", "C:\\Visual Studio", "C:\\Some Other"} }, // Issue #1537
		{ 1, "a;;b", [3]string{"a", "", "b"} },
		{ 2, "a;b;", [3]string{"a", "b", ""} },
		{ 3, ";a;b", [3]string{"", "a", "b"} },
		{ 4, ";;", [3]string{"", "", ""} },
		{ 5, "\"a;b\"c;d;\"f\"", [3]string{"a;bc", "d", "f"} },
		{ 6, "\"a;b;c\";d\";e\";f", [3]string{"a;b;c", "d;e", "f"} },
	}

	for d, i in data {
		assert(i == d.i, fmt.tprintf("wrong data index: i %d != d.i %d\n", i, d.i))
		r := split_list(d.v)
		defer delete(r)
		testing.expect(t, len(r) == len(d.e), fmt.tprintf("i:%d %s(%s) len(r) %d != len(d.e) %d",
													 i, #procedure, d.v, len(r), len(d.e)))
		if len(r) == len(d.e) {
			for _, j in r {
				testing.expect(t, r[j] == d.e[j], fmt.tprintf("i:%d %s(%v) -> %v[%d] != %v",
														 i, #procedure, d.v, r[j], j, d.e[j]))
			}
		}
	}

	{
		v := ""
		r := split_list(v)
		testing.expect(t, r == nil, fmt.tprintf("%s(%s) -> %v != nil", #procedure, v, r))
	}
	{
		v := "a"
		r := split_list(v)
		defer delete(r)
		testing.expect(t, len(r) == 1, fmt.tprintf("%s(%s) len(r) %d != 1", #procedure, v, len(r)))
		if len(r) == 1 {
			testing.expect(t, r[0] == "a", fmt.tprintf("%s(%v) -> %v[0] != a", #procedure, v, r[0]))
		}
	}
}