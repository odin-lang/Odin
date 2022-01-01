class WasmMemoryInterface {
	constructor() {	
		this.memory = null;
	}
	
	setMemory(memory) {
		this.memory = memory;
	}
		
	get mem() {
		return new DataView(this.memory.buffer);
	}
	
	
	loadF32Array(addr, len) {
		let array = new Float32Array(this.memory.buffer, addr, len);
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
	};
}


export {WasmMemoryInterface, odinSetupDefaultImports};