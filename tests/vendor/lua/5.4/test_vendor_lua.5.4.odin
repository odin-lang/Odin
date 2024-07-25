//+build windows, linux, darwin
package test_vendor_lua_54

import "core:testing"
import "core:c"
import lua "vendor:lua/5.4"
import "base:runtime"

@(test)
// Test context.allocator and returning a string
return_string_with_context_based_allocator :: proc(t: ^testing.T) {
	_context := context

	state: ^lua.State
	state = lua.newstate(lua_context_allocator, &_context)
	defer lua.close(state)

	lua.L_dostring(state, "return 'somestring'")
	str := lua.tostring(state, -1)

	testing.expectf(
		t, str == "somestring", "Expected Lua to return \"somestring\"",
	)
}

@(test)
// Test lua.dofile and returning an integer
dofile_factorial :: proc(t: ^testing.T) {
	state := lua.L_newstate()
	defer lua.close(state)

	FACT_10 :: 3628800

	res := lua.L_dofile(state, #directory + "/factorial.lua")
	testing.expectf(t, lua.Status(res) == .OK, "Expected L_dofile to return OKAY")

	fact := lua.L_checkinteger(state, -1)

	testing.expectf(t, fact == FACT_10, "Expected factorial(10) to return %v, got %v", FACT_10, fact)
}

@(test)
// Test that our bindings didn't get out of sync with the API version
verify_lua_api_version :: proc(t: ^testing.T) {
	state := lua.L_newstate()
	defer lua.close(state)

	version := int(lua.version(state))

	testing.expectf(t, version == lua.VERSION_NUM, "Expected lua.version to return %v, got %v", lua.VERSION_NUM, version)
}

// Simple context.allocator-based callback for Lua. Use `lua.newstate` to pass the context as user data.
lua_context_allocator :: proc "c" (ud: rawptr, ptr: rawptr, osize, nsize: c.size_t) -> (buf: rawptr) {
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