//+build js wasm32, js wasm64
package wasm_js_interface

foreign import dom_lib "odin_dom"

@(default_calling_convention="contextless")
foreign dom_lib {
	get_element_value_f64    :: proc(id: string) -> f64 ---
	get_element_min_max      :: proc(id: string) -> (min, max: f64) ---
	set_element_value        :: proc(id: string, value: f64) ---
}

get_element_value_string :: proc(id: string, buf: []byte) -> string {
	@(default_calling_convention="contextless")
	foreign dom_lib {
		@(link_name="get_element_value_string")
		_get_element_value_string :: proc(id: string, buf: []byte) -> int ---
	}
	n := _get_element_value_string(id, buf)
	return string(buf[:n])

}
