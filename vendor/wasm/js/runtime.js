"use strict";

(function() {

function getElement(name) {
	if (name) {
		return document.getElementById(name);
	}
	return undefined;
}

class WasmMemoryInterface {
	constructor() {
		this.memory = null;
		this.exports = null;
		this.listenerMap = {};
	}

	setMemory(memory) {
		this.memory = memory;
	}

	setExports(exports) {
		this.exports = exports;
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

	storeString(addr, value) {
		const bytes = this.loadBytes(addr, value.length);
		new TextEncoder("utf-8").encodeInto(value, bytes);
	}
};

class WebGLInterface {
	constructor(wasmMemoryInterface) {
		this.wasmMemoryInterface = wasmMemoryInterface;
		this.ctxElement         = null;
		this.ctx                = null;
		this.ctxVersion         = 1.0;
		this.counter            = 1;
		this.lastError          = 0;
		this.buffers            = [];
		this.mappedBuffers      = {};
		this.programs           = [];
		this.framebuffers       = [];
		this.renderbuffers      = [];
		this.textures           = [];
		this.uniforms           = [];
		this.shaders            = [];
		this.vaos               = [];
		this.contexts           = [];
		this.currentContext     = null;
		this.offscreenCanvases  = {};
		this.timerQueriesEXT    = [];
		this.queries            = [];
		this.samplers           = [];
		this.transformFeedbacks = [];
		this.syncs              = [];
		this.programInfos       = {};
	}

	get mem() {
		return this.wasmMemoryInterface
	}

	setCurrentContext(element, contextSettings) {
		if (!element) {
			return false;
		}
		if (this.ctxElement == element) {
			return true;
		}

		contextSettings = contextSettings ?? {};
		this.ctx = element.getContext("webgl2", contextSettings) || element.getContext("webgl", contextSettings);
		if (!this.ctx) {
			return false;
		}
		this.ctxElement = element;
		if (this.ctx.getParameter(0x1F02).indexOf("WebGL 2.0") !== -1) {
			this.ctxVersion = 2.0;
		} else {
			this.ctxVersion = 1.0;
		}
		return true;
	}

	assertWebGL2() {
		if (this.ctxVersion < 2) {
			throw new Error("WebGL2 procedure called in a canvas without a WebGL2 context");
		}
	}
	getNewId(table) {
		for (var ret = this.counter++, i = table.length; i < ret; i++) {
			table[i] = null;
		}
		return ret;
	}
	recordError(errorCode) {
		this.lastError || (this.lastError = errorCode);
	}
	populateUniformTable(program) {
		let p = this.programs[program];
		this.programInfos[program] = {
			uniforms: {},
			maxUniformLength: 0,
			maxAttributeLength: -1,
			maxUniformBlockNameLength: -1,
		};
		for (let ptable = this.programInfos[program], utable = ptable.uniforms, numUniforms = this.ctx.getProgramParameter(p, this.ctx.ACTIVE_UNIFORMS), i = 0; i < numUniforms; ++i) {
			let u = this.ctx.getActiveUniform(p, i);
			let name = u.name;
			if (ptable.maxUniformLength = Math.max(ptable.maxUniformLength, name.length + 1), name.indexOf("]", name.length - 1) !== -1) {
				name = name.slice(0, name.lastIndexOf("["));
			}
			let loc = this.ctx.getUniformLocation(p, name);
			if (loc !== null) {
				let id = this.getNewId(this.uniforms);
				utable[name] = [u.size, id], this.uniforms[id] = loc;
				for (let j = 1; j < u.size; ++j) {
					let n = name + "[" + j + "]";
					let loc = this.ctx.getUniformLocation(p, n);
					let id = this.getNewId(this.uniforms);
					this.uniforms[id] = loc;
				}
			}
		}
	}
	getSource(shader, strings_ptr, strings_length) {
		const STRING_SIZE = 2*4;
		let source = "";
		for (let i = 0; i < strings_length; i++) {
			let ptr = this.mem.loadPtr(strings_ptr + i*STRING_SIZE);
			let len = this.mem.loadPtr(strings_ptr + i*STRING_SIZE + 4);
			let str = this.mem.loadString(ptr, len);
			source += str;
		}
		return source;
	}

	getWebGL1Interface() {
		return {
			SetCurrentContextById: (name_ptr, name_len) => {
				let name = this.mem.loadString(name_ptr, name_len);
				let element = getElement(name);
				return this.setCurrentContext(element, {alpha: true, antialias: true, depth: true, premultipliedAlpha: true});
			},
			CreateCurrentContextById: (name_ptr, name_len, attributes) => {
				let name = this.mem.loadString(name_ptr, name_len);
				let element = getElement(name);

				let contextSettings = {
					alpha:                        !(attributes & (1<<0)),
					antialias:                    !(attributes & (1<<1)),
					depth:                        !(attributes & (1<<2)),
					failIfMajorPerformanceCaveat: !!(attributes & (1<<3)),
					premultipliedAlpha:           !(attributes & (1<<4)),
					preserveDrawingBuffer:        !!(attributes & (1<<5)),
					stencil:                      !!(attributes & (1<<6)),
					desynchronized:               !!(attributes & (1<<7)),
				};

				return this.setCurrentContext(element, contextSettings);
			},
			GetCurrentContextAttributes: () => {
				if (!this.ctx) {
					return 0;
				}
				let attrs = this.ctx.getContextAttributes();
				let res = 0;
				if (!attrs.alpha)                        res |= 1<<0;
				if (!attrs.antialias)                    res |= 1<<1;
				if (!attrs.depth)                        res |= 1<<2;
				if (attrs.failIfMajorPerformanceCaveat)  res |= 1<<3;
				if (!attrs.premultipliedAlpha)           res |= 1<<4;
				if (attrs.preserveDrawingBuffer)         res |= 1<<5;
				if (attrs.stencil)                       res |= 1<<6;
				if (attrs.desynchronized)                res |= 1<<7;
				return res;
			},

			DrawingBufferWidth:  () => this.ctx.drawingBufferWidth,
			DrawingBufferHeight: () => this.ctx.drawingBufferHeight,

			IsExtensionSupported: (name_ptr, name_len) => {
				let name = this.mem.loadString(name_ptr, name_len);
				let extensions = this.ctx.getSupportedExtensions();
				return extensions.indexOf(name) !== -1
			},


			GetError: () => {
				let err = this.lastError;
				this.recordError(0);
				if (err) {
					return err;
				}
				return this.ctx.getError();
			},

			GetWebGLVersion: (major_ptr, minor_ptr) => {
				let version = this.ctx.getParameter(0x1F02);
				if (version.indexOf("WebGL 2.0") !== -1) {
					this.mem.storeI32(major_ptr, 2);
					this.mem.storeI32(minor_ptr, 0);
					return;
				}

				this.mem.storeI32(major_ptr, 1);
				this.mem.storeI32(minor_ptr, 0);
			},
			GetESVersion: (major_ptr, minor_ptr) => {
				let version = this.ctx.getParameter(0x1F02);
				if (version.indexOf("OpenGL ES 3.0") !== -1) {
					this.mem.storeI32(major_ptr, 3);
					this.mem.storeI32(minor_ptr, 0);
					return;
				}

				this.mem.storeI32(major_ptr, 2);
				this.mem.storeI32(minor_ptr, 0);
			},


			ActiveTexture: (x) => {
				this.ctx.activeTexture(x);
			},
			AttachShader: (program, shader) => {
				this.ctx.attachShader(this.programs[program], this.shaders[shader]);
			},
			BindAttribLocation: (program, index, name_ptr, name_len) => {
				let name = this.mem.loadString(name_ptr, name_len);
				this.ctx.bindAttribLocation(this.programs[program], index, name)
			},
			BindBuffer: (target, buffer) => {
				let bufferObj = buffer ? this.buffers[buffer] : null;
				if (target == 35051) {
					this.ctx.currentPixelPackBufferBinding = buffer;
				} else {
					if (target == 35052) {
						this.ctx.currentPixelUnpackBufferBinding = buffer;
					}
					this.ctx.bindBuffer(target, bufferObj)
				}
			},
			BindFramebuffer: (target, framebuffer) => {
				this.ctx.bindFramebuffer(target, framebuffer ? this.framebuffers[framebuffer] : null)
			},
			BindTexture: (target, texture) => {
				this.ctx.bindTexture(target, texture ? this.textures[texture] : null)
			},
			BlendColor: (red, green, blue, alpha) => {
				this.ctx.blendColor(red, green, blue, alpha);
			},
			BlendEquation: (mode) => {
				this.ctx.blendEquation(mode);
			},
			BlendFunc: (sfactor, dfactor) => {
				this.ctx.blendFunc(sfactor, dfactor);
			},
			BlendFuncSeparate: (srcRGB, dstRGB, srcAlpha, dstAlpha) => {
				this.ctx.blendFuncSeparate(srcRGB, dstRGB, srcAlpha, dstAlpha);
			},


			BufferData: (target, size, data, usage) => {
				if (data) {
					this.ctx.bufferData(target, this.mem.loadBytes(data, size), usage);
				} else {
					this.ctx.bufferData(target, size, usage);
				}
			},
			BufferSubData: (target, offset, size, data) => {
				if (data) {
					this.ctx.bufferSubData(target, offset, this.mem.loadBytes(data, size));
				} else {
					this.ctx.bufferSubData(target, offset, null);
				}
			},


			Clear: (x) => {
				this.ctx.clear(x);
			},
			ClearColor: (r, g, b, a) => {
				this.ctx.clearColor(r, g, b, a);
			},
			ClearDepth: (x) => {
				this.ctx.clearDepth(x);
			},
			ClearStencil: (x) => {
				this.ctx.clearStencil(x);
			},
			ColorMask: (r, g, b, a) => {
				this.ctx.colorMask(!!r, !!g, !!b, !!a);
			},
			CompileShader: (shader) => {
				this.ctx.compileShader(this.shaders[shader]);
			},


			CompressedTexImage2D: (target, level, internalformat, width, height, border, imageSize, data) => {
				if (data) {
					this.ctx.compressedTexImage2D(target, level, internalformat, width, height, border, this.mem.loadBytes(data, imageSize));
				} else {
					this.ctx.compressedTexImage2D(target, level, internalformat, width, height, border, null);
				}
			},
			CompressedTexSubImage2D: (target, level, xoffset, yoffset, width, height, format, imageSize, data) => {
				if (data) {
					this.ctx.compressedTexSubImage2D(target, level, xoffset, yoffset, width, height, format, this.mem.loadBytes(data, imageSize));
				} else {
					this.ctx.compressedTexSubImage2D(target, level, xoffset, yoffset, width, height, format, null);
				}
			},

			CopyTexImage2D: (target, level, internalformat, x, y, width, height, border) => {
				this.ctx.copyTexImage2D(target, level, internalformat, x, y, width, height, border);
			},
			CopyTexSubImage2D: (target, level, xoffset, yoffset, x, y, width, height) => {
				this.ctx.copyTexImage2D(target, level, xoffset, yoffset, x, y, width, height);
			},


			CreateBuffer: () => {
				let buffer = this.ctx.createBuffer();
				if (!buffer) {
					this.recordError(1282);
					return 0;
				}
				let id = this.getNewId(this.buffers);
				buffer.name = id
				this.buffers[id] = buffer;
				return id;
			},
			CreateFramebuffer: () => {
				let buffer = this.ctx.createFramebuffer();
				let id = this.getNewId(this.framebuffers);
				buffer.name = id
				this.framebuffers[id] = buffer;
				return id;
			},
			CreateProgram: () => {
				let program = this.ctx.createProgram();
				let id = this.getNewId(this.programs);
				program.name = id;
				this.programs[id] = program;
				return id;
			},
			CreateRenderbuffer: () => {
				let buffer = this.ctx.createRenderbuffer();
				let id = this.getNewId(this.renderbuffers);
				buffer.name = id;
				this.renderbuffers[id] = buffer;
				return id;
			},
			CreateShader: (shaderType) => {
				let shader = this.ctx.createShader(shaderType);
				let id = this.getNewId(this.shaders);
				shader.name = id;
				this.shaders[id] = shader;
				return id;
			},
			CreateTexture: () => {
				let texture = this.ctx.createTexture();
				if (!texture) {
					this.recordError(1282)
					return 0;
				}
				let id = this.getNewId(this.textures);
				texture.name = id;
				this.textures[id] = texture;
				return id;
			},


			CullFace: (mode) => {
				this.ctx.cullFace(mode);
			},


			DeleteBuffer: (id) => {
				let obj = this.buffers[id];
				if (obj && id != 0) {
					this.ctx.deleteBuffer(obj);
					this.buffers[id] = null;
				}
			},
			DeleteFramebuffer: (id) => {
				let obj = this.framebuffers[id];
				if (obj && id != 0) {
					this.ctx.deleteFramebuffer(obj);
					this.framebuffers[id] = null;
				}
			},
			DeleteProgram: (id) => {
				let obj = this.programs[id];
				if (obj && id != 0) {
					this.ctx.deleteProgram(obj);
					this.programs[id] = null;
				}
			},
			DeleteRenderbuffer: (id) => {
				let obj = this.renderbuffers[id];
				if (obj && id != 0) {
					this.ctx.deleteRenderbuffer(obj);
					this.renderbuffers[id] = null;
				}
			},
			DeleteShader: (id) => {
				let obj = this.shaders[id];
				if (obj && id != 0) {
					this.ctx.deleteShader(obj);
					this.shaders[id] = null;
				}
			},
			DeleteTexture: (id) => {
				let obj = this.textures[id];
				if (obj && id != 0) {
					this.ctx.deleteTexture(obj);
					this.textures[id] = null;
				}
			},


			DepthFunc: (func) => {
				this.ctx.depthFunc(func);
			},
			DepthMask: (flag) => {
				this.ctx.depthMask(!!flag);
			},
			DepthRange: (zNear, zFar) => {
				this.ctx.depthRange(zNear, zFar);
			},
			DetachShader: (program, shader) => {
				this.ctx.detachShader(this.programs[program], this.shaders[shader]);
			},
			Disable: (cap) => {
				this.ctx.disable(cap);
			},
			DisableVertexAttribArray: (index) => {
				this.ctx.disableVertexAttribArray(index);
			},
			DrawArrays: (mode, first, count) => {
				this.ctx.drawArrays(mode, first, count);
			},
			DrawElements: (mode, count, type, indices) => {
				this.ctx.drawElements(mode, count, type, indices);
			},


			Enable: (cap) => {
				this.ctx.enable(cap);
			},
			EnableVertexAttribArray: (index) => {
				this.ctx.enableVertexAttribArray(index);
			},
			Finish: () => {
				this.ctx.finish();
			},
			Flush: () => {
				this.ctx.flush();
			},
			FramebufferRenderBuffer: (target, attachment, renderbuffertarget, renderbuffer) => {
				this.ctx.framebufferRenderBuffer(target, attachment, renderbuffertarget, this.renderbuffers[renderbuffer]);
			},
			FramebufferTexture2D: (target, attachment, textarget, texture, level) => {
				this.ctx.framebufferTexture2D(target, attachment, textarget, this.textures[texture], level);
			},
			FrontFace: (mode) => {
				this.ctx.frontFace(mode);
			},


			GenerateMipmap: (target) => {
				this.ctx.generateMipmap(target);
			},


			GetAttribLocation: (program, name_ptr, name_len) => {
				let name = this.mem.loadString(name_ptr, name_len);
				return this.ctx.getAttribLocation(this.programs[program], name);
			},



			GetProgramParameter: (program, pname) => {
				return this.ctx.getProgramParameter(this.programs[program], pname)
			},
			GetProgramInfoLog: (program, buf_ptr, buf_len, length_ptr) => {
				let log = this.ctx.getProgramInfoLog(this.programs[program]);
				if (log === null) {
					log = "(unknown error)";
				}
				if (buf_len > 0 && buf_ptr) {
					let n = Math.min(buf_len, log.length);
					log = log.substring(0, n);
					this.mem.loadBytes(buf_ptr, buf_len).set(new TextEncoder("utf-8").encode(log))

					this.mem.storeInt(length_ptr, n);
				}
			},
			GetShaderInfoLog: (shader, buf_ptr, buf_len, length_ptr) => {
				let log = this.ctx.getShaderInfoLog(this.shaders[shader]);
				if (log === null) {
					log = "(unknown error)";
				}
				if (buf_len > 0 && buf_ptr) {
					let n = Math.min(buf_len, log.length);
					log = log.substring(0, n);
					this.mem.loadBytes(buf_ptr, buf_len).set(new TextEncoder("utf-8").encode(log))

					this.mem.storeInt(length_ptr, n);
				}
			},
			GetShaderiv: (shader, pname, p) => {
				if (p) {
					if (pname == 35716) {
						let log = this.ctx.getShaderInfoLog(this.shaders[shader]);
						if (log === null) {
							log = "(unknown error)";
						}
						this.mem.storeInt(p, log.length+1);
					} else if (pname == 35720) {
						let source = this.ctx.getShaderSource(this.shaders[shader]);
						let sourceLength = (source === null || source.length == 0) ? 0 : source.length+1;
						this.mem.storeInt(p, sourceLength);
					} else {
						let param = this.ctx.getShaderParameter(this.shaders[shader], pname);
						this.mem.storeI32(p, param);
					}
				} else {
					this.recordError(1281);
				}
			},


			GetUniformLocation: (program, name_ptr, name_len) => {
				let name = this.mem.loadString(name_ptr, name_len);
				let arrayOffset = 0;
				if (name.indexOf("]", name.length - 1) !== -1) {
					let ls = name.lastIndexOf("["),
					arrayIndex = name.slice(ls + 1, -1);
					if (arrayIndex.length > 0 && (arrayOffset = parseInt(arrayIndex)) < 0) {
						return -1;
					}
					name = name.slice(0, ls)
				}
				var ptable = this.programInfos[program];
				if (!ptable) {
					return -1;
				}
				var uniformInfo = ptable.uniforms[name];
				return (uniformInfo && arrayOffset < uniformInfo[0]) ? uniformInfo[1] + arrayOffset : -1
			},


			GetVertexAttribOffset: (index, pname) => {
				return this.ctx.getVertexAttribOffset(index, pname);
			},


			Hint: (target, mode) => {
				this.ctx.hint(target, mode);
			},


			IsBuffer:       (buffer)       => this.ctx.isBuffer(this.buffers[buffer]),
			IsEnabled:      (enabled)      => this.ctx.isEnabled(this.enableds[enabled]),
			IsFramebuffer:  (framebuffer)  => this.ctx.isFramebuffer(this.framebuffers[framebuffer]),
			IsProgram:      (program)      => this.ctx.isProgram(this.programs[program]),
			IsRenderbuffer: (renderbuffer) => this.ctx.isRenderbuffer(this.renderbuffers[renderbuffer]),
			IsShader:       (shader)       => this.ctx.isShader(this.shaders[shader]),
			IsTexture:      (texture)      => this.ctx.isTexture(this.textures[texture]),

			LineWidth: (width) => {
				this.ctx.lineWidth(width);
			},
			LinkProgram: (program) => {
				this.ctx.linkProgram(this.programs[program]);
				this.programInfos[program] = null;
				this.populateUniformTable(program);
			},
			PixelStorei: (pname, param) => {
				this.ctx.pixelStorei(pname, param);
			},
			PolygonOffset: (factor, units) => {
				this.ctx.polygonOffset(factor, units);
			},


			ReadnPixels: (x, y, width, height, format, type, bufSize, data) => {
				this.ctx.readPixels(x, y, width, format, type, this.mem.loadBytes(data, bufSize));
			},
			RenderbufferStorage: (target, internalformat, width, height) => {
				this.ctx.renderbufferStorage(target, internalformat, width, height);
			},
			SampleCoverage: (value, invert) => {
				this.ctx.sampleCoverage(value, !!invert);
			},
			Scissor: (x, y, width, height) => {
				this.ctx.scissor(x, y, width, height);
			},
			ShaderSource: (shader, strings_ptr, strings_length) => {
				let source = this.getSource(shader, strings_ptr, strings_length);
				this.ctx.shaderSource(this.shaders[shader], source);
			},

			StencilFunc: (func, ref, mask) => {
				this.ctx.stencilFunc(func, ref, mask);
			},
			StencilFuncSeparate: (face, func, ref, mask) => {
				this.ctx.stencilFuncSeparate(face, func, ref, mask);
			},
			StencilMask: (mask) => {
				this.ctx.stencilMask(mask);
			},
			StencilMaskSeparate: (face, mask) => {
				this.ctx.stencilMaskSeparate(face, mask);
			},
			StencilOp: (fail, zfail, zpass) => {
				this.ctx.stencilOp(fail, zfail, zpass);
			},
			StencilOpSeparate: (face, fail, zfail, zpass) => {
				this.ctx.stencilOpSeparate(face, fail, zfail, zpass);
			},


			TexImage2D: (target, level, internalformat, width, height, border, format, type, size, data) => {
				if (data) {
					this.ctx.texImage2D(target, level, internalformat, width, height, border, format, type, this.mem.loadBytes(data, size));
				} else {
					this.ctx.texImage2D(target, level, internalformat, width, height, border, format, type, null);
				}
			},
			TexParameterf: (target, pname, param) => {
				this.ctx.texParameterf(target, pname, param);
			},
			TexParameteri: (target, pname, param) => {
				this.ctx.texParameteri(target, pname, param);
			},
			TexSubImage2D: (target, level, xoffset, yoffset, width, height, format, type, size, data) => {
				this.ctx.texSubImage2D(target, level, xoffset, yoffset, width, height, format, type, this.mem.loadBytes(data, size));
			},


			Uniform1f: (location, v0)             => { this.ctx.uniform1f(this.uniforms[location], v0);             },
			Uniform2f: (location, v0, v1)         => { this.ctx.uniform2f(this.uniforms[location], v0, v1);         },
			Uniform3f: (location, v0, v1, v2)     => { this.ctx.uniform3f(this.uniforms[location], v0, v1, v2);     },
			Uniform4f: (location, v0, v1, v2, v3) => { this.ctx.uniform4f(this.uniforms[location], v0, v1, v2, v3); },

			Uniform1i: (location, v0)             => { this.ctx.uniform1i(this.uniforms[location], v0);             },
			Uniform2i: (location, v0, v1)         => { this.ctx.uniform2i(this.uniforms[location], v0, v1);         },
			Uniform3i: (location, v0, v1, v2)     => { this.ctx.uniform3i(this.uniforms[location], v0, v1, v2);     },
			Uniform4i: (location, v0, v1, v2, v3) => { this.ctx.uniform4i(this.uniforms[location], v0, v1, v2, v3); },

			UniformMatrix2fv: (location, addr) => {
				let array = this.mem.loadF32Array(addr, 2*2);
				this.ctx.uniformMatrix4fv(this.uniforms[location], false, array);
			},
			UniformMatrix3fv: (location, addr) => {
				let array = this.mem.loadF32Array(addr, 3*3);
				this.ctx.uniformMatrix4fv(this.uniforms[location], false, array);
			},
			UniformMatrix4fv: (location, addr) => {
				let array = this.mem.loadF32Array(addr, 4*4);
				this.ctx.uniformMatrix4fv(this.uniforms[location], false, array);
			},

			UseProgram: (program) => {
				if (program) this.ctx.useProgram(this.programs[program]);
			},
			ValidateProgram: (program) => {
				if (program) this.ctx.validateProgram(this.programs[program]);
			},


			VertexAttrib1f: (index, x) => {
				this.ctx.vertexAttrib1f(index, x);
			},
			VertexAttrib2f: (index, x, y) => {
				this.ctx.vertexAttrib2f(index, x, y);
			},
			VertexAttrib3f: (index, x, y, z) => {
				this.ctx.vertexAttrib3f(index, x, y, z);
			},
			VertexAttrib4f: (index, x, y, z, w) => {
				this.ctx.vertexAttrib4f(index, x, y, z, w);
			},
			VertexAttribPointer: (index, size, type, normalized, stride, ptr) => {
				this.ctx.vertexAttribPointer(index, size, type, !!normalized, stride, ptr);
			},

			Viewport: (x, y, w, h) => {
				this.ctx.viewport(x, y, w, h);
			},
		};
	}

	getWebGL2Interface() {
		return {
			/* Buffer objects */
			CopyBufferSubData: (readTarget, writeTarget, readOffset, writeOffset, size) => {
				this.assertWebGL2();
				this.ctx.copyBufferSubData(readTarget, writeTarget, readOffset, writeOffset, size);
			},
			GetBufferSubData: (target, srcByteOffset, dst_buffer_ptr, dst_buffer_len, dstOffset, length) => {
				this.assertWebGL2();
				this.ctx.getBufferSubData(target, srcByteOffset, this.mem.loadBytes(dst_buffer_ptr, dst_buffer_len), dstOffset, length);
			},

			/* Framebuffer objects */
			BlitFramebuffer: (srcX0, srcY0, srcX1, srcY1, dstX0, dstY0, dstX1, dstY1, mask, filter) => {
				this.assertWebGL2();
				this.ctx.glitFramebuffer(srcX0, srcY0, srcX1, srcY1, dstX0, dstY0, dstX1, dstY1, mask, filter);
			},
			FramebufferTextureLayer: (target, attachment, texture, level, layer) => {
				this.assertWebGL2();
				this.ctx.framebufferTextureLayer(target, attachment, this.textures[texture], level, layer);
			},
			InvalidateFramebuffer: (target, attachments_ptr, attachments_len) => {
				this.assertWebGL2();
				let attachments = this.mem.loadU32Array(attachments_ptr, attachments_len);
				this.ctx.invalidateFramebuffer(target, attachments);
			},
			InvalidateSubFramebuffer: (target, attachments_ptr, attachments_len, x, y, width, height) => {
				this.assertWebGL2();
				let attachments = this.mem.loadU32Array(attachments_ptr, attachments_len);
				this.ctx.invalidateSubFramebuffer(target, attachments, x, y, width, height);
			},
			ReadBuffer: (src) => {
				this.assertWebGL2();
				this.ctx.readBuffer(src);
			},

			/* Renderbuffer objects */
			RenderbufferStorageMultisample: (target, samples, internalformat, width, height) => {
				this.assertWebGL2();
				this.ctx.renderbufferStorageMultisample(target, samples, internalformat, width, height);
			},

			/* Texture objects */

			TexStorage3D: (target, levels, internalformat, width, height, depth) => {
				this.assertWebGL2();
				this.ctx.texStorage3D(target, level, internalformat, width, heigh, depth);
			},
			TexImage3D: (target, level, internalformat, width, height, depth, border, format, type, size, data) => {
				this.assertWebGL2();
				if (data) {
					this.ctx.texImage3D(target, level, internalformat, width, height, depth, border, format, type, this.mem.loadBytes(data, size));
				} else {
					this.ctx.texImage3D(target, level, internalformat, width, height, depth, border, format, type, null);
				}
			},
			TexSubImage3D: (target, level, xoffset, yoffset, zoffset, width, height, depth, format, type, size, data) => {
				this.assertWebGL2();
				this.ctx.texSubImage3D(target, level, xoffset, yoffset, zoffset, width, height, depth, format, type, this.mem.loadBytes(data, size));
			},
			CompressedTexImage3D: (target, level, internalformat, width, height, depth, border, imageSize, data) => {
				this.assertWebGL2();
				if (data) {
					this.ctx.compressedTexImage3D(target, level, internalformat, width, height, depth, border, this.mem.loadBytes(data, imageSize));
				} else {
					this.ctx.compressedTexImage3D(target, level, internalformat, width, height, depth, border, null);
				}
			},
			CompressedTexSubImage3D: (target, level, xoffset, yoffset, zoffset, width, height, depth, format, imageSize, data) => {
				this.assertWebGL2();
				if (data) {
					this.ctx.compressedTexSubImage3D(target, level, xoffset, yoffset, zoffset, width, height, depth, format, this.mem.loadBytes(data, imageSize));
				} else {
					this.ctx.compressedTexSubImage3D(target, level, xoffset, yoffset, zoffset, width, height, depth, format, null);
				}
			},

			CopyTexSubImage3D: (target, level, xoffset, yoffset, zoffset, x, y, width, height) => {
				this.assertWebGL2();
				this.ctx.copyTexImage3D(target, level, xoffset, yoffset, zoffset, x, y, width, height);
			},

			/* Programs and shaders */
			GetFragDataLocation: (program, name_ptr, name_len) => {
				this.assertWebGL2();
				return this.ctx.getFragDataLocation(this.programs[program], this.mem.loadString(name_ptr, name_len));
			},

			/* Uniforms */
			Uniform1ui: (location, v0) => {
				this.assertWebGL2();
				this.ctx.uniform1ui(this.uniforms[location], v0);
			},
			Uniform2ui: (location, v0, v1) => {
				this.assertWebGL2();
				this.ctx.uniform2ui(this.uniforms[location], v0, v1);
			},
			Uniform3ui: (location, v0, v1, v2) => {
				this.assertWebGL2();
				this.ctx.uniform3ui(this.uniforms[location], v0, v1, v2);
			},
			Uniform4ui: (location, v0, v1, v2, v3) => {
				this.assertWebGL2();
				this.ctx.uniform4ui(this.uniforms[location], v0, v1, v2, v3);
			},

			UniformMatrix3x2fv: (location, addr) => {
				this.assertWebGL2();
				let array = this.mem.loadF32Array(addr, 3*2);
				this.ctx.uniformMatrix3x2fv(this.uniforms[location], false, array);
			},
			UniformMatrix4x2fv: (location, addr) => {
				this.assertWebGL2();
				let array = this.mem.loadF32Array(addr, 4*2);
				this.ctx.uniformMatrix4x2fv(this.uniforms[location], false, array);
			},
			UniformMatrix2x3fv: (location, addr) => {
				this.assertWebGL2();
				let array = this.mem.loadF32Array(addr, 2*3);
				this.ctx.uniformMatrix2x3fv(this.uniforms[location], false, array);
			},
			UniformMatrix4x3fv: (location, addr) => {
				this.assertWebGL2();
				let array = this.mem.loadF32Array(addr, 4*3);
				this.ctx.uniformMatrix4x3fv(this.uniforms[location], false, array);
			},
			UniformMatrix2x4fv: (location, addr) => {
				this.assertWebGL2();
				let array = this.mem.loadF32Array(addr, 2*4);
				this.ctx.uniformMatrix2x4fv(this.uniforms[location], false, array);
			},
			UniformMatrix3x4fv: (location, addr) => {
				this.assertWebGL2();
				let array = this.mem.loadF32Array(addr, 3*4);
				this.ctx.uniformMatrix3x4fv(this.uniforms[location], false, array);
			},

			/* Vertex attribs */
			VertexAttribI4i: (index, x, y, z, w) => {
				this.assertWebGL2();
				this.ctx.vertexAttribI4i(index, x, y, z, w);
			},
			VertexAttribI4ui: (index, x, y, z, w) => {
				this.assertWebGL2();
				this.ctx.vertexAttribI4ui(index, x, y, z, w);
			},
			VertexAttribIPointer: (index, size, type, stride, offset) => {
				this.assertWebGL2();
				this.ctx.vertexAttribIPointer(index, size, type, stride, offset);
			},

			/* Writing to the drawing buffer */
			VertexAttribDivisor: (index, divisor) => {
				this.assertWebGL2();
				this.ctx.vertexAttribDivisor(index, divisor);
			},
			DrawArraysInstanced: (mode, first, count, instanceCount) => {
				this.assertWebGL2();
				this.ctx.drawArraysInstanced(mode, first, count, instanceCount);
			},
			DrawElementsInstanced: (mode, count, type, offset, instanceCount) => {
				this.assertWebGL2();
				this.ctx.drawElementsInstanced(mode, count, type, offset, instanceCount);
			},
			DrawRangeElements: (mode, start, end, count, type, offset) => {
				this.assertWebGL2();
				this.ctx.drawRangeElements(mode, start, end, count, type, offset);
			},

			/* Multiple Render Targets */
			DrawBuffers: (buffers_ptr, buffers_len) => {
				this.assertWebGL2();
				let array = this.mem.loadU32Array(buffers_ptr, buffers_len);
				this.ctx.drawBuffers(array);
			},
			ClearBufferfv: (buffer, drawbuffer, values_ptr, values_len) => {
				this.assertWebGL2();
				let array = this.mem.loadF32Array(values_ptr, values_len);
				this.ctx.clearBufferfv(buffer, drawbuffer, array);
			},
			ClearBufferiv: (buffer, drawbuffer, values_ptr, values_len) => {
				this.assertWebGL2();
				let array = this.mem.loadI32Array(values_ptr, values_len);
				this.ctx.clearBufferiv(buffer, drawbuffer, array);
			},
			ClearBufferuiv: (buffer, drawbuffer, values_ptr, values_len) => {
				this.assertWebGL2();
				let array = this.mem.loadU32Array(values_ptr, values_len);
				this.ctx.clearBufferuiv(buffer, drawbuffer, array);
			},
			ClearBufferfi: (buffer, drawbuffer, depth, stencil) => {
				this.assertWebGL2();
				this.ctx.clearBufferfi(buffer, drawbuffer, depth, stencil);
			},

			/* Query Objects */
			CreateQuery: () => {
				this.assertWebGL2();
				let query = this.ctx.createQuery();
				let id = this.getNewId(this.queries);
				query.name = id;
				this.queries[id] = query;
				return id;
			},
			DeleteQuery: (id) => {
				this.assertWebGL2();
				let obj = this.querys[id];
				if (obj && id != 0) {
					this.ctx.deleteQuery(obj);
					this.querys[id] = null;
				}
			},
			IsQuery: (query) => {
				this.assertWebGL2();
				return this.ctx.isQuery(this.queries[query]);
			},
			BeginQuery: (target, query) => {
				this.assertWebGL2();
				this.ctx.beginQuery(target, this.queries[query])
			},
			EndQuery: (target) => {
				this.assertWebGL2();
				this.ctx.endQuery(target);
			},
			GetQuery: (target, pname) => {
				this.assertWebGL2();
				let query = this.ctx.getQuery(target, pname);
				if (!query) {
					return 0;
				}
				if (this.queries.indexOf(query) !== -1) {
					return query.name;
				}
				let id = this.getNewId(this.queries);
				query.name = id;
				this.queries[id] = query;
				return id;
			},

			/* Sampler Objects */
			CreateSampler: () => {
				this.assertWebGL2();
				let sampler = this.ctx.createSampler();
				let id = this.getNewId(this.samplers);
				sampler.name = id;
				this.samplers[id] = sampler;
				return id;
			},
			DeleteSampler: (id) => {
				this.assertWebGL2();
				let obj = this.samplers[id];
				if (obj && id != 0) {
					this.ctx.deleteSampler(obj);
					this.samplers[id] = null;
				}
			},
			IsSampler: (sampler) => {
				this.assertWebGL2();
				return this.ctx.isSampler(this.samplers[sampler]);
			},
			BindSampler: (unit, sampler) => {
				this.assertWebGL2();
				this.ctx.bindSampler(unit, this.samplers[Sampler]);
			},
			SamplerParameteri: (sampler, pname, param) => {
				this.assertWebGL2();
				this.ctx.samplerParameteri(this.samplers[sampler], pname, param);
			},
			SamplerParameterf: (sampler, pname, param) => {
				this.assertWebGL2();
				this.ctx.samplerParameterf(this.samplers[sampler], pname, param);
			},

			/* Sync objects */
			FenceSync: (condition, flags) => {
				this.assertWebGL2();
				let sync = this.ctx.fenceSync(condition, flags);
				let id = this.getNewId(this.syncs);
				sync.name = id;
				this.syncs[id] = sync;
				return id;
			},
			IsSync: (sync) => {
				this.assertWebGL2();
				return this.ctx.isSync(this.syncs[sync]);
			},
			DeleteSync: (id) => {
				this.assertWebGL2();
				let obj = this.syncs[id];
				if (obj && id != 0) {
					this.ctx.deleteSampler(obj);
					this.syncs[id] = null;
				}
			},
			ClientWaitSync: (sync, flags, timeout) => {
				this.assertWebGL2();
				return this.ctx.clientWaitSync(this.syncs[sync], flags, timeout);
			},
			WaitSync: (sync, flags, timeout) => {
				this.assertWebGL2();
				this.ctx.waitSync(this.syncs[sync], flags, timeout)	;
			},


			/* Transform Feedback */
			CreateTransformFeedback: () => {
				this.assertWebGL2();
				let transformFeedback = this.ctx.createtransformFeedback();
				let id = this.getNewId(this.transformFeedbacks);
				transformFeedback.name = id;
				this.transformFeedbacks[id] = transformFeedback;
				return id;
			},
			DeleteTransformFeedback: (id)  => {
				this.assertWebGL2();
				let obj = this.transformFeedbacks[id];
				if (obj && id != 0) {
					this.ctx.deleteTransformFeedback(obj);
					this.transformFeedbacks[id] = null;
				}
			},
			IsTransformFeedback: (tf) => {
				this.assertWebGL2();
				return this.ctx.isTransformFeedback(this.transformFeedbacks[tf]);
			},
			BindTransformFeedback: (target, tf) => {
				this.assertWebGL2();
				this.ctx.bindTransformFeedback(target, this.transformFeedbacks[tf]);
			},
			BeginTransformFeedback: (primitiveMode) => {
				this.assertWebGL2();
				this.ctx.beginTransformFeedback(primitiveMode);
			},
			EndTransformFeedback: () => {
				this.assertWebGL2();
				this.ctx.endTransformFeedback();
			},
			TransformFeedbackVaryings: (program, varyings_ptr, varyings_len, bufferMode) => {
				this.assertWebGL2();
				let varyings = [];
				for (let i = 0; i < varyings_len; i++) {
					let ptr = this.mem.loadPtr(varyings_ptr + i*STRING_SIZE + 0*4);
					let len = this.mem.loadPtr(varyings_ptr + i*STRING_SIZE + 1*4);
					varyings.push(this.mem.loadString(ptr, len));
				}
				this.ctx.transformFeedbackVaryings(this.programs[program], varyings, bufferMode);
			},
			PauseTransformFeedback: () => {
				this.assertWebGL2();
				this.ctx.pauseTransformFeedback();
			},
			ResumeTransformFeedback: () => {
				this.assertWebGL2();
				this.ctx.resumeTransformFeedback();
			},


			/* Uniform Buffer Objects and Transform Feedback Buffers */
			BindBufferBase: (target, index, buffer) => {
				this.assertWebGL2();
				this.ctx.bindBufferBase(target, index, this.buffers[buffer]);
			},
			BindBufferRange: (target, index, buffer, offset, size) => {
				this.assertWebGL2();
				this.ctx.bindBufferRange(target, index, this.buffers[buffer], offset, size);
			},
			GetUniformBlockIndex: (program, uniformBlockName_ptr, uniformBlockName_len) => {
				this.assertWebGL2();
				return this.ctx.getUniformBlockIndex(this.programs[program], this.mem.loadString(uniformBlockName_ptr, uniformBlockName_len));
			},
			// any getActiveUniformBlockParameter(WebGLProgram program, GLuint uniformBlockIndex, GLenum pname);
			GetActiveUniformBlockName: (program, uniformBlockIndex, buf_ptr, buf_len, length_ptr) => {
				this.assertWebGL2();
				let name = this.ctx.getActiveUniformBlockName(this.programs[program], uniformBlockIndex);

				let n = Math.min(buf_len, name.length);
				name = name.substring(0, n);
				this.mem.loadBytes(buf_ptr, buf_len).set(new TextEncoder("utf-8").encode(name))
				this.mem.storeInt(length_ptr, n);
			},
			UniformBlockBinding: (program, uniformBlockIndex, uniformBlockBinding) => {
				this.assertWebGL2();
				this.ctx.uniformBlockBinding(this.programs[program], uniformBlockIndex, uniformBlockBinding);
			},

			/* Vertex Array Objects */
			CreateVertexArray: () => {
				this.assertWebGL2();
				let vao = this.ctx.createVertexArray();
				let id = this.getNewId(this.vaos);
				vao.name = id;
				this.vaos[id] = vao;
				return id;
			},
			DeleteVertexArray: (id) => {
				this.assertWebGL2();
				let obj = this.vaos[id];
				if (obj && id != 0) {
					this.ctx.deleteVertexArray(obj);
					this.vaos[id] = null;
				}
			},
			IsVertexArray: (vertexArray) => {
				this.assertWebGL2();
				return this.ctx.isVertexArray(this.vaos[vertexArray]);
			},
			BindVertexArray: (vertexArray) => {
				this.assertWebGL2();
				this.ctx.bindVertexArray(this.vaos[vertexArray]);
			},
		};
	}
};


function odinSetupDefaultImports(wasmMemoryInterface, consoleElement) {
	const MAX_INFO_CONSOLE_LINES = 512;
	let infoConsoleLines = new Array();
	let currentLine = {};
	currentLine[false] = "";
	currentLine[true] = "";
	let prevIsError = false;

	const writeToConsole = (line, isError) => {
		if (!line) {
			return;
		}

		const println = (text, forceIsError) => {
			let style = [
				"color: #eee",
				"background-color: #d20",
				"padding: 2px 4px",
				"border-radius: 2px",
			].join(";");
			let doIsError = isError;
			if (forceIsError !== undefined) {
				doIsError = forceIsError;
			}

			if (doIsError) {
				console.log("%c"+text, style);
			} else {
				console.log(text);
			}

		};

		// Print to console
		if (line == "\n") {
			println(currentLine[isError]);
			currentLine[isError] = "";
		} else if (!line.includes("\n")) {
			currentLine[isError] = currentLine[isError].concat(line);
		} else {
			let lines = line.split("\n");
			let printLast = lines.length > 1 && line.endsWith("\n");
			println(currentLine[isError].concat(lines[0]));
			currentLine[isError] = "";
			for (let i = 1; i < lines.length-1; i++) {
				println(lines[i]);
			}
			let last = lines[lines.length-1];
			if (printLast) {
				println(last);
			} else {
				currentLine[isError] = last;
			}
		}

		if (prevIsError != isError) {
			if (prevIsError) {
				println(currentLine[prevIsError], prevIsError);
				currentLine[prevIsError] = "";
			}
		}
		prevIsError = isError;


		// HTML based console
		if (!consoleElement) {
			return;
		}
		const wrap = (x) => {
			if (isError) {
				return '<span style="color:#f21">'+x+'</span>';
			}
			return x;
		};

		if (line == "\n") {
			infoConsoleLines.push(line);
		} else if (!line.includes("\n")) {
			let prevLine = "";
			if (infoConsoleLines.length > 0) {
				prevLine = infoConsoleLines.pop();
			}
			infoConsoleLines.push(prevLine.concat(wrap(line)));
		} else {
			let lines = line.split("\n");
			let lastHasNewline = lines.length > 1 && line.endsWith("\n");

			let prevLine = "";
			if (infoConsoleLines.length > 0) {
				prevLine = infoConsoleLines.pop();
			}
			infoConsoleLines.push(prevLine.concat(wrap(lines[0]).concat("\n")));

			for (let i = 1; i < lines.length-1; i++) {
				infoConsoleLines.push(wrap(lines[i]).concat("\n"));
			}
			let last = lines[lines.length-1];
			if (lastHasNewline) {
				infoConsoleLines.push(last.concat("\n"));
			} else {
				infoConsoleLines.push(last);
			}
		}

		if (infoConsoleLines.length > MAX_INFO_CONSOLE_LINES) {
			infoConsoleLines.shift(MAX_INFO_CONSOLE_LINES);
		}

		let data = "";
		for (let i = 0; i < infoConsoleLines.length; i++) {
			data = data.concat(infoConsoleLines[i]);
		}

		let info = consoleElement;
		info.innerHTML = data;
		info.scrollTop = info.scrollHeight;
	};

	let event_temp_data = {};

	let webglContext = new WebGLInterface(wasmMemoryInterface);
	return {
		"env": {},
		"odin_env": {
			write: (fd, ptr, len) => {
				const str = wasmMemoryInterface.loadString(ptr, len);
				if (fd == 1) {
					writeToConsole(str, false);
					return;
				} else if (fd == 2) {
					writeToConsole(str, true);
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
				// convert ms to ns
				return Date.now() * 1e6;
			},
			tick_now: () => {
				// convert ms to ns
				return performance.now() * 1e6;
			},
			time_sleep: (duration_ms) => {
				if (duration_ms > 0) {
					// TODO(bill): Does this even make any sense?
				}
			},

			sqrt:    (x) => Math.sqrt(x),
			sin:     (x) => Math.sin(x),
			cos:     (x) => Math.cos(x),
			pow:     (x, power) => Math.pow(x, power),
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
						alignment = Math.min(amount, W);
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
				wmi.storeUint(off(W), 0); // padding

				wmi.storeF64(off(8), e.timeStamp*1e-3);

				wmi.storeU8(off(1), e.eventPhase);
				let options = 0;
				if (!!e.bubbles)    { options |= 1<<0; }
				if (!!e.cancelable) { options |= 1<<1; }
				if (!!e.composed)   { options |= 1<<2; }
				wmi.storeU8(off(1), options);
				wmi.storeU8(off(1), !!e.isComposing);
				wmi.storeU8(off(1), !!e.isTrusted);

				let base = off(0, 8);
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

					wmi.storeU8(off(1), !!e.ctrlKey);
					wmi.storeU8(off(1), !!e.shiftKey);
					wmi.storeU8(off(1), !!e.altKey);
					wmi.storeU8(off(1), !!e.metaKey);

					wmi.storeI16(off(2), e.button);
					wmi.storeU16(off(2), e.buttons);
				} else if (e instanceof KeyboardEvent) {
					// Note: those strigs are constructed
					// on the native side from buffers that
					// are filled later, so skip them 
					const keyPtr  = off(W*2, W);
					const codePtr = off(W*2, W);

					wmi.storeU8(off(1), e.location);

					wmi.storeU8(off(1), !!e.ctrlKey);
					wmi.storeU8(off(1), !!e.shiftKey);
					wmi.storeU8(off(1), !!e.altKey);
					wmi.storeU8(off(1), !!e.metaKey);

					wmi.storeU8(off(1), !!e.repeat);

					wmi.storeI32(off(W), e.key.length)
					wmi.storeI32(off(W), e.code.length)
					wmi.storeString(off(16, 1), e.key);
					wmi.storeString(off(16, 1), e.code);
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
				let element = getElement(id);
				if (element == undefined) {
					return false;
				}

				let listener = (e) => {
					const odin_ctx = wasmMemoryInterface.exports.default_context_ptr();
					event_temp_data.id_ptr = id_ptr;
					event_temp_data.id_len = id_len;
					event_temp_data.event = e;
					event_temp_data.name_code = name_code;
					wasmMemoryInterface.exports.odin_dom_do_event_callback(data, callback, odin_ctx);
				};
				wasmMemoryInterface.listenerMap[{data: data, callback: callback}] = listener;
				element.addEventListener(name, listener, !!use_capture);
				return true;
			},

			remove_event_listener: (id_ptr, id_len, name_ptr, name_len, data, callback) => {
				let id = wasmMemoryInterface.loadString(id_ptr, id_len);
				let name = wasmMemoryInterface.loadString(name_ptr, name_len);
				let element = getElement(id);
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
					wasmMemoryInterface.exports.odin_dom_do_event_callback(data, callback, odin_ctx);
				};
				wasmMemoryInterface.listenerMap[{data: data, callback: callback}] = listener;
				element.addEventListener(name, listener, !!use_capture);
				return true;
			},

			remove_window_event_listener: (name_ptr, name_len, data, callback) => {
				let name = wasmMemoryInterface.loadString(name_ptr, name_len);
				let element = window;
				let key = {data: data, callback: callback};
				let listener = wasmMemoryInterface.listenerMap[key];
				if (!listener) {
					return false;
				}
				wasmMemoryInterface.listenerMap[key] = undefined;

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
					event_temp_data.event.preventDefault();
				}
			},

			dispatch_custom_event: (id_ptr, id_len, name_ptr, name_len, options_bits) => {
				let id = wasmMemoryInterface.loadString(id_ptr, id_len);
				let name = wasmMemoryInterface.loadString(name_ptr, name_len);
				let options = {
					bubbles:   (options_bits & (1<<0)) !== 0,
					cancelabe: (options_bits & (1<<1)) !== 0,
					composed:  (options_bits & (1<<2)) !== 0,
				};

				let element = getElement(id);
				if (element) {
					element.dispatchEvent(new Event(name, options));
					return true;
				}
				return false;
			},

			get_element_value_f64: (id_ptr, id_len) => {
				let id = wasmMemoryInterface.loadString(id_ptr, id_len);
				let element = getElement(id);
				return element ? element.value : 0;
			},
			get_element_value_string: (id_ptr, id_len, buf_ptr, buf_len) => {
				let id = wasmMemoryInterface.loadString(id_ptr, id_len);
				let element = getElement(id);
				if (element) {
					let str = element.value;
					if (buf_len > 0 && buf_ptr) {
						let n = Math.min(buf_len, str.length);
						str = str.substring(0, n);
						this.mem.loadBytes(buf_ptr, buf_len).set(new TextEncoder("utf-8").encode(str))
						return n;
					}
				}
				return 0;
			},
			get_element_value_string_length: (id_ptr, id_len) => {
				let id = wasmMemoryInterface.loadString(id_ptr, id_len);
				let element = getElement(id);
				if (element) {
					return element.value.length;
				}
				return 0;
			},
			get_element_min_max: (ptr_array2_f64, id_ptr, id_len) => {
				let id = wasmMemoryInterface.loadString(id_ptr, id_len);
				let element = getElement(id);
				if (element) {
					let values = wasmMemoryInterface.loadF64Array(ptr_array2_f64, 2);
					values[0] = element.min;
					values[1] = element.max;
				}
			},
			set_element_value_f64: (id_ptr, id_len, value) => {
				let id = wasmMemoryInterface.loadString(id_ptr, id_len);
				let element = getElement(id);
				if (element) {
					element.value = value;
				}
			},
			set_element_value_string: (id_ptr, id_len, value_ptr, value_id) => {
				let id = wasmMemoryInterface.loadString(id_ptr, id_len);
				let value = wasmMemoryInterface.loadString(value_ptr, value_len);
				let element = getElement(id);
				if (element) {
					element.value = value;
				}
			},


			get_bounding_client_rect: (rect_ptr, id_ptr, id_len) => {
				let id = wasmMemoryInterface.loadString(id_ptr, id_len);
				let element = getElement(id);
				if (element) {
					let values = wasmMemoryInterface.loadF64Array(rect_ptr, 4);
					let rect = element.getBoundingClientRect();
					values[0] = rect.left;
					values[1] = rect.top;
					values[2] = rect.right  - rect.left;
					values[3] = rect.bottom - rect.top;
				}
			},
			window_get_rect: (rect_ptr) => {
				let values = wasmMemoryInterface.loadF64Array(rect_ptr, 4);
				values[0] = window.screenX;
				values[1] = window.screenY;
				values[2] = window.screen.width;
				values[3] = window.screen.height;
			},

			window_get_scroll: (pos_ptr) => {
				let values = wasmMemoryInterface.loadF64Array(pos_ptr, 2);
				values[0] = window.scrollX;
				values[1] = window.scrollY;
			},
			window_set_scroll: (x, y) => {
				window.scroll(x, y);
			},

			device_pixel_ratio: () => {
				return window.devicePixelRatio;
			},

		},

		"webgl": webglContext.getWebGL1Interface(),
		"webgl2": webglContext.getWebGL2Interface(),
	};
};

async function runWasm(wasmPath, consoleElement, extraForeignImports) {
	let wasmMemoryInterface = new WasmMemoryInterface();

	let imports = odinSetupDefaultImports(wasmMemoryInterface, consoleElement);
	let exports = {};

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

window.odin = {
	// Interface Types
	WasmMemoryInterface: WasmMemoryInterface,
	WebGLInterface:      WebGLInterface,

	// Functions
	setupDefaultImports: odinSetupDefaultImports,
	runWasm:             runWasm,
};
})();