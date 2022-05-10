class WebGLInterface {
	constructor(wasmMemoryInterface, canvasElement, contextSettings) {
		this.wasmMemoryInterface = wasmMemoryInterface;
		this.ctx                = null;
		this.ctx_version        = 1;
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

		if (contextSettings === undefined) {
			contextSettings = {antialias: false};
		}

		this.ctx = canvasElement.getContext("webgl2", contextSettings) || canvasElement.getContext("webgl", contextSettings);
		if (!this.ctx) {
			return;
		}
		if (this.ctx.getParameter(0x1F02).indexOf("WebGL 2.0") !== -1) {
			this.ctx_version = 2.0;
		} else {
			this.ctx_version = 1.0;
		}
	}

	get mem() {
		return this.wasmMemoryInterface
	}

	assertWebGL2() {
		if (this.ctx_version < 2) {
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
			BindFramebuffer: (target, buffer) => {
				// TODO: BindFramebuffer
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


export {WebGLInterface};