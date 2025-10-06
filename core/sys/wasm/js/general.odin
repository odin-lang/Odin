#+build js wasm32, js wasm64p32
package wasm_js_interface

foreign import "odin_env"

@(default_calling_convention="contextless")
foreign odin_env {
	trap     :: proc() -> ! ---
	abort    :: proc() -> ! ---
	alert    :: proc(msg: string) ---
	evaluate :: proc(str: string) ---
	open     :: proc(url: string, name := "", specs := "") ---
}
