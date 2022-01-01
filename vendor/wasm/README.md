# WASM on the Web

This directory is for use when targeting the `js_wasm32` target and the packages that rely on it.

The `js_wasm32` target assumes that the WASM output will be ran within a web browser rather than a standalone VM. In the VM cases, either `wasi_wasm32` or `freestanding_wasm32` should be used accordingly.

## Example

```js
import {WasmMemoryInterface, odinSetupDefaultImports} from "./js/runtime.js";
import {WebGLInterface} from "./WebGL/runtime.js";

const runWasm = async (wasm_path, webglCanvasElement, consoleElement) => {
	let wasmMemoryInterface = new WasmMemoryInterface();

	let imports = odinSetupDefaultImports(wasmMemoryInterface, consoleElement);
	
	if (webglCanvasElement !== undefined) {
		let gl_context = new WebGLInterface(
			wasmMemoryInterface, 
			webglCanvasElement, 
			{antialias: false},
		);
		if (!gl_context.ctx) {
			return "WebGL is not available.";
		}	
		imports["webgl"] = gl_context.getWebGL1Interface()
		imports["webgl2"] = gl_context.getWebGL2Interface()
	}
		
	const response = await fetch(wasm_path);
	const file = await response.arrayBuffer();
	const wasm = await WebAssembly.instantiate(file, imports);
	const exports = wasm.instance.exports;
	wasmMemoryInterface.setMemory(exports.memory);
	
	exports._start();
	
	if (exports.step) {
		const odin_ctx = exports.default_context_ptr();
		
		let prevTimeStamp = undefined;
		const step = (currTimeStamp) => {
			if (prevTimeStamp == undefined) {
				prevTimeStamp = currTimeStamp;
			}

			const dt = (currTimeStamp - prevTimeStamp)*0.001;
			prevTimeStamp = currTimeStamp;
			exports.step(dt, odin_ctx);
			window.requestAnimationFrame(step);
		};
		
		window.requestAnimationFrame(step);
	}
	
	return;
};
```