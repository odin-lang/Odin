import {WasmMemoryInterface, odinSetupDefaultImports} from "../js/runtime.mjs";
import {WebGLInterface} from "../WebGL/runtime.mjs";

export async function runWasmCanvas(wasmPath, webglCanvasElement, consoleElement, extraForeignImports) {
	let wasmMemoryInterface = new WasmMemoryInterface();

	let imports = odinSetupDefaultImports(wasmMemoryInterface, consoleElement);
	let exports = {};

	if (webglCanvasElement !== undefined) {
		let gl_context = new WebGLInterface(
			wasmMemoryInterface,
			webglCanvasElement,
			{antialias: false},
		);
		if (!gl_context.ctx) {
			return "WebGL is not available.";
		}
		imports["webgl"] = gl_context.getWebGL1Interface();
		imports["webgl2"] = gl_context.getWebGL2Interface();
	}

	if (extraForeignImports !== undefined) {
		imports = {
			...imports,
			...extraForeignImports,
		};
	}

	const response = await fetch(wasmPath);
	const file = await response.arrayBuffer();
	const wasm = await WebAssembly.instantiate(file, imports);
	exports = wasm.instance.exports;
	wasmMemoryInterface.setExports(exports);
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

	exports._end();

	return;
};


export {runWasmCanvas};
