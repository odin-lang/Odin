class WasmMemoryInterface {
	constructor() {
		this.memory = null;
		this.exports = null;
	}

	setMemory(memory) {
		this.memory = memory;
	}

	setExports(exports) {
		this.exports = exports;
		this.listenerMap = {};
	}

	get mem() {
		return new DataView(this.memory.buffer);
	}


	loadF32Array(addr, len) {
		let array = new Float32Array(this.memory.buffer, addr, len);
		return array;
	}
	loadF64Array(addr, len) {
		let array = new Float64Array(this.memory.buffer, addr, len);
		return array;
	}
	loadU32Array(addr, len) {
		let array = new Uint32Array(this.memory.buffer, addr, len);
		return array;
	}
	loadI32Array(addr, len) {
		let array = new Int32Array(this.memory.buffer, addr, len);
		return array;
	}


	loadU8(addr) { return this.mem.getUint8  (addr, true); }
	loadI8(addr) { return this.mem.getInt8   (addr, true); }
	loadU16(addr) { return this.mem.getUint16 (addr, true); }
	loadI16(addr) { return this.mem.getInt16  (addr, true); }
	loadU32(addr) { return this.mem.getUint32 (addr, true); }
	loadI32(addr) { return this.mem.getInt32  (addr, true); }
	loadU64(addr) {
		const lo = this.mem.getUint32(addr + 0, true);
		const hi = this.mem.getUint32(addr + 4, true);
		return lo + hi*4294967296;
	};
	loadI64(addr) {
		// TODO(bill): loadI64 correctly
		const lo = this.mem.getUint32(addr + 0, true);
		const hi = this.mem.getUint32(addr + 4, true);
		return lo + hi*4294967296;
	};
	loadF32(addr)  { return this.mem.getFloat32(addr, true); }
	loadF64(addr)  { return this.mem.getFloat64(addr, true); }
	loadInt(addr)  { return this.mem.getInt32  (addr, true); }
	loadUint(addr) { return this.mem.getUint32 (addr, true); }

	loadPtr(addr) { return this.loadUint(addr); }

	loadBytes(ptr, len) {
		return new Uint8Array(this.memory.buffer, ptr, len);
	}

	loadString(ptr, len) {
		const bytes = this.loadBytes(ptr, len);
		return new TextDecoder("utf-8").decode(bytes);
	}

	storeU8(addr, value)  { this.mem.setUint8  (addr, value, true); }
	storeI8(addr, value)  { this.mem.setInt8   (addr, value, true); }
	storeU16(addr, value) { this.mem.setUint16 (addr, value, true); }
	storeI16(addr, value) { this.mem.setInt16  (addr, value, true); }
	storeU32(addr, value) { this.mem.setUint32 (addr, value, true); }
	storeI32(addr, value) { this.mem.setInt32  (addr, value, true); }
	storeU64(addr, value) {
		this.mem.setUint32(addr + 0, value, true);
		this.mem.setUint32(addr + 4, Math.floor(value / 4294967296), true);
	}
	storeI64(addr, value) {
		// TODO(bill): storeI64 correctly
		this.mem.setUint32(addr + 0, value, true);
		this.mem.setUint32(addr + 4, Math.floor(value / 4294967296), true);
	}
	storeF32(addr, value)  { this.mem.setFloat32(addr, value, true); }
	storeF64(addr, value)  { this.mem.setFloat64(addr, value, true); }
	storeInt(addr, value)  { this.mem.setInt32  (addr, value, true); }
	storeUint(addr, value) { this.mem.setUint32 (addr, value, true); }
};

function odinSetupDefaultImports(wasmMemoryInterface, consoleElement) {
	const MAX_INFO_CONSOLE_LINES = 512;
	let infoConsoleLines = new Array();
	const addConsoleLine = (line) => {
		if (line === undefined) {
			return;
		}
		if (line.endsWith("\n")) {
			line = line.substring(0, line.length-1);
		} else if (infoConsoleLines.length > 0) {
			let prev_line = infoConsoleLines.pop();
			line = prev_line.concat(line);
		}
		infoConsoleLines.push(line);

		if (infoConsoleLines.length > MAX_INFO_CONSOLE_LINES) {
			infoConsoleLines.shift();
		}

		let data = "";
		for (let i = 0; i < infoConsoleLines.length; i++) {
			if (i != 0) {
				data = data.concat("\n");
			}
			data = data.concat(infoConsoleLines[i]);
		}

		if (consoleElement !== undefined) {
			let info = consoleElement;
			info.innerHTML = data;
			info.scrollTop = info.scrollHeight;
		}
	};

	let event_temp_data = {};

	return {
		"env": {},
		"odin_env": {
			write: (fd, ptr, len) => {
				const str = wasmMemoryInterface.loadString(ptr, len);
				if (fd == 1) {
					addConsoleLine(str);
					return;
				} else if (fd == 2) {
					addConsoleLine(str);
					return;
				} else {
					throw new Error("Invalid fd to 'write'" + stripNewline(str));
				}
			},
			trap: () => { throw new Error() },
			alert: (ptr, len) => { alert(wasmMemoryInterface.loadString(ptr, len)) },
			abort: () => { Module.abort() },
			evaluate: (str_ptr, str_len) => { eval.call(null, wasmMemoryInterface.loadString(str_ptr, str_len)); },

			time_now: () => {
				return performance.now() * 1e6;
			},

			sqrt:    (x) => Math.sqrt(x),
			sin:     (x) => Math.sin(x),
			cos:     (x) => Math.cos(x),
			pow:     (x) => Math.pow(x),
			fmuladd: (x, y, z) => x*y + z,
			ln:      (x) => Math.log(x),
			exp:     (x) => Math.exp(x),
			ldexp:   (x) => Math.ldexp(x),
		},
		"odin_dom": {
			init_event_raw: (ep) => {
				const W = 4;
				let offset = ep;
				let off = (amount, alignment) => {
					if (alignment === undefined) {
						alignment = amount;
					}
					if (offset % alignment != 0) {
						offset += alignment - (offset%alignment);
					}
					let x = offset;
					offset += amount;
					return x;
				};

				let wmi = wasmMemoryInterface;

				let e = event_temp_data.event;

				wmi.storeU32(off(4), event_temp_data.name_code);
				if (e.target == document) {
					wmi.storeU32(off(4), 1);
				} else if (e.target == window) {
					wmi.storeU32(off(4), 2);
				} else {
					wmi.storeU32(off(4), 0);
				}
				if (e.currentTarget == document) {
					wmi.storeU32(off(4), 1);
				} else if (e.currentTarget == window) {
					wmi.storeU32(off(4), 2);
				} else {
					wmi.storeU32(off(4), 0);
				}

				wmi.storeUint(off(W), event_temp_data.id_ptr);
				wmi.storeUint(off(W), event_temp_data.id_len);

				wmi.storeF64(off(8), e.timeStamp*1e-3);

				wmi.storeU8(off(1), e.eventPhase);
				wmi.storeU8(off(1), !!e.bubbles);
				wmi.storeU8(off(1), !!e.cancelable);
				wmi.storeU8(off(1), !!e.composed);
				wmi.storeU8(off(1), !!e.isComposing);
				wmi.storeU8(off(1), !!e.isTrusted);

				off(0, 8);
				if (e instanceof MouseEvent) {
					wmi.storeI64(off(8), e.screenX);
					wmi.storeI64(off(8), e.screenY);
					wmi.storeI64(off(8), e.clientX);
					wmi.storeI64(off(8), e.clientY);
					wmi.storeI64(off(8), e.offsetX);
					wmi.storeI64(off(8), e.offsetY);
					wmi.storeI64(off(8), e.pageX);
					wmi.storeI64(off(8), e.pageY);
					wmi.storeI64(off(8), e.movementX);
					wmi.storeI64(off(8), e.movementY);
					wmi.storeI64(off(8), e.x);
					wmi.storeI64(off(8), e.y);

					wmi.storeU8(off(1), !!e.ctrlKey);
					wmi.storeU8(off(1), !!e.shiftKey);
					wmi.storeU8(off(1), !!e.altKey);
					wmi.storeU8(off(1), !!e.metaKey);

					wmi.storeI16(off(2), e.button);
					wmi.storeU16(off(2), e.buttons);
				} else if (e instanceof KeyboardEvent) {
					let keyOffset = off(W*2, W);
					let codeOffet = off(W*2, W);
					wmi.storeU8(off(1), e.location);

					wmi.storeU8(off(1), !!e.ctrlKey);
					wmi.storeU8(off(1), !!e.shiftKey);
					wmi.storeU8(off(1), !!e.altKey);
					wmi.storeU8(off(1), !!e.metaKey);

					wmi.storeU8(off(1), !!e.repeat);
				} else if (e instanceof WheelEvent) {
					wmi.storeF64(off(8), e.deltaX);
					wmi.storeF64(off(8), e.deltaY);
					wmi.storeF64(off(8), e.deltaZ);
					wmi.storeU32(off(4), e.deltaMode);
				} else if (e instanceof Event) {
					if ('scrollX' in e) {
						wmi.storeF64(off(8), e.scrollX);
						wmi.storeF64(off(8), e.scrollY);
					}
				}
			},

			add_event_listener: (id_ptr, id_len, name_ptr, name_len, name_code, data, callback, use_capture) => {
				let id = wasmMemoryInterface.loadString(id_ptr, id_len);
				let name = wasmMemoryInterface.loadString(name_ptr, name_len);
				let element = document.getElementById(id);
				if (element == undefined) {
					return false;
				}

				let listener = (e) => {
					const odin_ctx = wasmMemoryInterface.exports.default_context_ptr();
					event_temp_data.id_ptr = id_ptr;
					event_temp_data.id_len = id_len;
					event_temp_data.event = e;
					event_temp_data.name_code = name_code;
					// console.log(e);
					wasmMemoryInterface.exports.odin_dom_do_event_callback(data, callback, odin_ctx);
				};
				wasmMemoryInterface.listenerMap[{data: data, callback: callback}] = listener;
				element.addEventListener(name, listener, !!use_capture);
				return true;
			},

			remove_event_listener: (id_ptr, id_len, name_ptr, name_len, data, callback) => {
				let id = wasmMemoryInterface.loadString(id_ptr, id_len);
				let name = wasmMemoryInterface.loadString(name_ptr, name_len);
				let element = document.getElementById(id);
				if (element == undefined) {
					return false;
				}

				let listener = wasmMemoryInterface.listenerMap[{data: data, callback: callback}];
				if (listener == undefined) {
					return false;
				}
				element.removeEventListener(name, listener);
				return true;
			},


			add_window_event_listener: (name_ptr, name_len, name_code, data, callback, use_capture) => {
				let name = wasmMemoryInterface.loadString(name_ptr, name_len);
				let element = window;
				let listener = (e) => {
					const odin_ctx = wasmMemoryInterface.exports.default_context_ptr();
					event_temp_data.id_ptr = 0;
					event_temp_data.id_len = 0;
					event_temp_data.event = e;
					event_temp_data.name_code = name_code;
					// console.log(e);
					wasmMemoryInterface.exports.odin_dom_do_event_callback(data, callback, odin_ctx);
				};
				wasmMemoryInterface.listenerMap[{data: data, callback: callback}] = listener;
				element.addEventListener(name, listener, !!use_capture);
				return true;
			},

			remove_window_event_listener: (name_ptr, name_len, data, callback) => {
				let name = wasmMemoryInterface.loadString(name_ptr, name_len);
				let element = window;
				let listener = wasmMemoryInterface.listenerMap[{data: data, callback: callback}];
				if (listener == undefined) {
					return false;
				}
				element.removeEventListener(name, listener);
				return true;
			},

			event_stop_propagation: () => {
				if (event_temp_data && event_temp_data.event) {
					event_temp_data.event.eventStopPropagation();
				}
			},
			event_stop_immediate_propagation: () => {
				if (event_temp_data && event_temp_data.event) {
					event_temp_data.event.eventStopImmediatePropagation();
				}
			},
			event_prevent_default: () => {
				if (event_temp_data && event_temp_data.event) {
					event_temp_data.event.eventPreventDefault();
				}
			},

			get_element_value_f64: (id_ptr, id_len) => {
				let id = wasmMemoryInterface.loadString(id_ptr, id_len);
				let element = document.getElementById(id);
				return element.value;
			},
			get_element_value_string: (id_ptr, id_len, buf_ptr, buf_len) => {
				let id = wasmMemoryInterface.loadString(id_ptr, id_len);
				let element = document.getElementById(id);
				let str = element.value;
				if (buf_len > 0 && buf_ptr) {
					let n = Math.min(buf_len, str.length);
					str = str.substring(0, n);
					this.mem.loadBytes(buf_ptr, buf_len).set(new TextEncoder("utf-8").encode(str))
					return n;
				}
				return 0;
			},
			get_element_min_max: (ptr_array2_f64, id_ptr, id_len) => {
				let id = wasmMemoryInterface.loadString(id_ptr, id_len);
				let element = document.getElementById(id);
				let values = wasmMemoryInterface.loadF64Array(ptr_array2_f64, 2);
				values[0] = element.min;
				values[1] = element.max;
			},
			set_element_value: (id_ptr, id_len, value) => {
				let id = wasmMemoryInterface.loadString(id_ptr, id_len);
				document.getElementById(id).value = value;
			},
		},
	};
}


export {WasmMemoryInterface, odinSetupDefaultImports};