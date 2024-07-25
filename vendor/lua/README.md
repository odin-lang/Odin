# Lua in Odin

Lua packages

* `vendor:lua/5.1` (version 5.1.5)
* `vendor:lua/5.2` (version 5.2.4)
* `vendor:lua/5.3` (version 5.3.6)
* `vendor:lua/5.4` (version 5.4.2)

With custom context-based allocator:

```odin
package lua_example_with_context

import "core:fmt"
import lua "vendor:lua/5.4" // or whatever version you want
import "core:c"
import "base:runtime"

state: ^lua.State

lua_allocator :: proc "c" (ud: rawptr, ptr: rawptr, osize, nsize: c.size_t) -> (buf: rawptr) {
	old_size := int(osize)
	new_size := int(nsize)
	context = (^runtime.Context)(ud)^

	if ptr == nil {
		data, err := runtime.mem_alloc(new_size)
		return raw_data(data) if err == .None else nil
	} else {
		if nsize > 0 {
			data, err := runtime.mem_resize(ptr, old_size, new_size)
			return raw_data(data) if err == .None else nil
		} else {
			runtime.mem_free(ptr)
			return
		}
	}
}

main :: proc() {
	_context := context
	state = lua.newstate(lua_allocator, &_context)
	defer lua.close(state)

	lua.L_dostring(state, "return 'somestring'")
	str := lua.tostring(state, -1)
	fmt.println(str)
}
```