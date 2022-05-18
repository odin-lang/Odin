import {WasmMemoryInterface, odinSetupDefaultImports, WebGLInterface} from "./runtime.mjs";

export async function runWasmCanvas(wasmPath, consoleElement, extraForeignImports) {
	let wasmMemoryInterface = new WasmMemoryInterface();

	let imports = odinSetupDefaultImports(wasmMemoryInterface, consoleElement);
	let exports = {};

	let gl_context = new WebGLInterface(
		wasmMemoryInterface,
		null,
		{antialias: false},
	);
	imports["webgl"] = gl_context.getWebGL1Interface();
	imports["webgl2"] = gl_context.getWebGL2Interface();

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