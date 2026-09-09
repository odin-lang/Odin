import assert from "node:assert/strict";
import fs from "node:fs";

const bytes = fs.readFileSync(process.argv[2]);
const module = await WebAssembly.compile(bytes);
const imports = WebAssembly.Module.imports(module);
const memoryImport = imports.find((entry) => entry.kind === "memory");
assert.deepEqual(memoryImport, { module: "env", name: "memory", kind: "memory" });

const memory = new WebAssembly.Memory({ initial: 256, maximum: 1024, shared: true });
const defaultImports = {
	memory,
};
const odinImports = {
	write() {},
	trap() { throw new Error("WASM trap"); },
	alert() {},
	abort() { throw new Error("WASM abort"); },
	evaluate() {},
	open() {},
	time_now() { return 0n; },
	tick_now() { return 0; },
	time_sleep() {},
	sqrt: Math.sqrt,
	sin: Math.sin,
	cos: Math.cos,
	pow: Math.pow,
	fmuladd: (x, y, z) => x * y + z,
	ln: Math.log,
	exp: Math.exp,
	ldexp: (x, exponent) => x * (2 ** exponent),
	rand_bytes() {},
};
const makeInstance = async () => WebAssembly.instantiate(module, {
	env: defaultImports,
	odin_env: odinImports,
});

const first = await makeInstance();
const second = await makeInstance();
assert.notEqual(first.exports.__stack_pointer, second.exports.__stack_pointer);
first.exports.__stack_pointer.value = 2 * 1024 * 1024;
second.exports.__stack_pointer.value = 3 * 1024 * 1024;
assert.equal(first.exports.__stack_pointer.value, 2 * 1024 * 1024);
assert.equal(second.exports.__stack_pointer.value, 3 * 1024 * 1024);

const sharedPointer = first.exports.fixture_shared_value_ptr();
assert.equal(sharedPointer, second.exports.fixture_shared_value_ptr());
assert.equal(new Uint32Array(memory.buffer, sharedPointer, 1)[0], 41);
assert.equal(first.exports.fixture_increment(), 42);
assert.equal(second.exports.fixture_increment(), 43);

const initializedPointer = first.exports.fixture_initialized_value_ptr();
new Uint32Array(memory.buffer, initializedPointer, 1)[0] = 99;
const third = await makeInstance();
assert.equal(third.exports.fixture_initialized_value_ptr(), initializedPointer);
assert.equal(new Uint32Array(memory.buffer, initializedPointer, 1)[0], 99);

const callbackPointer = first.exports.fixture_callback_pointer();
first.exports.fixture_dispatch(callbackPointer, sharedPointer);
assert.equal(new Uint32Array(memory.buffer, sharedPointer, 1)[0], 44);
second.exports.fixture_dispatch(callbackPointer, sharedPointer);
assert.equal(new Uint32Array(memory.buffer, sharedPointer, 1)[0], 45);

console.log(JSON.stringify({
	instances: 3,
	sharedValue: 45,
	initializedValue: 99,
	stacks: [first.exports.__stack_pointer.value, second.exports.__stack_pointer.value],
	imports,
}, null, 2));
