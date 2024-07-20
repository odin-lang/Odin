(function() {

/**
 * Assumptions:
 * - Ability to allocate memory, set the context to allocate with using the global `wgpu.g_context`
 * - Exports a function table (for callbacks), added with `-extra-linker-flags:"--export-table"`
 */
class WebGPUInterface {

	/**
	 * @param {WasmMemoryInterface} mem
	 */
	constructor(mem) {
		this.mem = mem;

		this.enums = {
			FeatureName: [undefined, "depth-clip-control", "depth32float-stencil8", "timestamp-query", "texture-compression-bc", "texture-compression-etc2", "texture-compression-astc", "indirect-first-instance", "shader-f16", "rg11b10ufloat-renderable", "bgra8unorm-storage", "float32-filterable", ],
			StoreOp: [undefined, "store", "discard", ],
			LoadOp: [undefined, "clear", "load", ],
			BufferBindingType: [undefined, "uniform", "storage", "read-only-storage", ],
			SamplerBindingType: [undefined, "filtering", "non-filtering", "comparison", ],
			TextureSampleType: [undefined, "float", "unfilterable-float", "depth", "sint", "uint", ],
			TextureViewDimension: [undefined, "1d", "2d", "2d-array", "cube", "cube-array", "3d", ],
			StorageTextureAccess: [undefined, "write-only", "read-only", "read-write", ],
			TextureFormat: [undefined, "r8unorm", "r8snorm", "r8uint", "r8sint", "r16uint", "r16sint", "r16float", "rg8unorm", "rg8snorm", "rg8uint", "rg8sint", "r32float", "r32uint", "r32sint", "rg16uint", "rg16sint", "rg16float", "rgba8unorm", "rgba8unorm-srgb", "rgba8snorm", "rgba8uint", "rgba8sint", "bgra8unorm", "bgra8unorm-srgb", "rgb10a2uint", "rgb10a2unorm", "rg11b10ufloat", "rgb9e5ufloat", "rg32float", "rg32uint", "rg32sint", "rgba16uint", "rgba16sint", "rgba16float", "rgba32float", "rgba32uint", "rgba32sint", "stencil8", "depth16unorm", "depth24plus", "depth24plus-stencil8", "depth32float", "depth32float-stencil8", "bc1-rgba-unorm", "bc1-rgba-unorm-srgb", "bc2-rgba-unorm", "bc2-rgba-unorm-srgb", "bc3-rgba-unorm", "bc3-rgba-unorm-srgb", "bc4-r-unorm", "bc4-r-snorm", "bc5-rg-unorm", "bc5-rg-snorm", "bc6h-rgb-ufloat", "bc6h-rgb-float", "bc7-rgba-unorm", "bc7-rgba-unorm-srgb", "etc2-rgb8unorm", "etc2-rgb8unorm-srgb", "etc2-rgb8a1unorm", "etc2-rgb8a1unorm-srgb", "etc2-rgba8unorm", "etc2-rgba8unorm-srgb", "eac-r11unorm", "eac-r11snorm", "eac-rg11unorm", "eac-rg11snorm", "astc-4x4-unorm", "astc-4x4-unorm-srgb", "astc-5x4-unorm", "astc-5x4-unorm-srgb", "astc-5x5-unorm", "astc-5x5-unorm-srgb", "astc-6x5-unorm", "astc-6x5-unorm-srgb", "astc-6x6-unorm", "astc-6x6-unorm-srgb", "astc-8x5-unorm", "astc-8x5-unorm-srgb", "astc-8x6-unorm", "astc-8x6-unorm-srgb", "astc-8x8-unorm", "astc-8x8-unorm-srgb", "astc-10x5-unorm", "astc-10x5-unorm-srgb", "astc-10x6-unorm", "astc-10x6-unorm-srgb", "astc-10x8-unorm", "astc-10x8-unorm-srgb", "astc-10x10-unorm", "astc-10x10-unorm-srgb", "astc-12x10-unorm", "astc-12x10-unorm-srgb", "astc-12x12-unorm", "astc-12x12-unorm-srgb", ],
			QueryType: ["occlusion", "timestamp", ],
			VertexStepMode: ["vertex", "instance", "vertex-buffer-not-used", ],
			VertexFormat: [undefined, "uint8x2", "uint8x4", "sint8x2", "sint8x4", "unorm8x2", "unorm8x4", "snorm8x2", "snorm8x4", "uint16x2", "uint16x4", "sint16x2", "sint16x4", "unorm16x2", "unorm16x4", "snorm16x2", "snorm16x4", "float16x2", "float16x4", "float32", "float32x2", "float32x3", "float32x4", "uint32", "uint32x2", "uint32x3", "uint32x4", "sint32", "sint32x2", "sint32x3", "sint32x4", ],
			PrimitiveTopology: ["point-list", "line-list", "line-strip", "triangle-list", "triangle-strip", ],
			IndexFormat: [undefined, "uint16", "uint32", ],
			FrontFace: ["ccw", "cw", ],
			CullMode: ["none", "front", "back", ],
			AddressMode: ["repeat", "mirror-repeat", "clamp-to-edge", ],
			FilterMode: ["nearest", "linear", ],
			MipmapFilterMode: ["nearest", "linear", ],
			CompareFunction: [undefined, "never", "less", "less-equal", "greater", "greater-equal", "equal", "not-equal", "always", ],
			TextureDimension: ["1d", "2d", "3d", ],
			ErrorType: ["no-error", "validation", "out-of-memory", "internal", "unknown", "device-lost", ],
			WGSLFeatureName: [undefined, "readonly_and_readwrite_storage_textures", "packed_4x8_integer_dot_product", "unrestricted_pointer_parameters", "pointer_composite_access", ],
			PowerPreference: [undefined, "low-power", "high-performance", ],
			CompositeAlphaMode: ["auto", "opaque", "premultiplied", "unpremultiplied", "inherit", ],
			StencilOperation: ["keep", "zero", "replace", "invert", "increment-clamp", "decrement-clamp", "increment-wrap", "decrement-wrap", ],
			BlendOperation: ["add", "subtract", "reverse-subtract", "min", "max", ],
			BlendFactor: ["zero", "one", "src", "one-minus-src", "src-alpha", "one-minus-src-alpha", "dst", "one-minus-dst", "dst-alpha", "one-minus-dst-alpha", "src-alpha-saturated", "constant", "one-minus-constant", ],
			PresentMode: ["fifo", "fifo-relaxed", "immediate", "mailbox", ],
			TextureAspect: ["all", "stencil-only", "depth-only"],
		};

		/** @type {WebGPUObjectManager<{}>} */
		this.instances = new WebGPUObjectManager("Instance", this.mem);

		/** @type {WebGPUObjectManager<GPUAdapter>} */
		this.adapters = new WebGPUObjectManager("Adapter", this.mem);

		/** @type {WebGPUObjectManager<GPUBindGroup>} */
		this.bindGroups = new WebGPUObjectManager("BindGroup", this.mem);

		/** @type {WebGPUObjectManager<GPUBindGroupLayout>} */
		this.bindGroupLayouts = new WebGPUObjectManager("BindGroupLayout", this.mem);

		/** @type {WebGPUObjectManager<{ buffer: GPUBuffer, mapping: ?{ range: ArrayBuffer, ptr: number, size: number } }>} */
		this.buffers = new WebGPUObjectManager("Buffer", this.mem);

		/** @type {WebGPUObjectManager<GPUDevice>} */
		this.devices = new WebGPUObjectManager("Device", this.mem);

		/** @type {WebGPUObjectManager<GPUCommandBuffer>} */
		this.commandBuffers = new WebGPUObjectManager("CommandBuffer", this.mem);

		/** @type {WebGPUObjectManager<GPUCommandEncoder>} */
		this.commandEncoders = new WebGPUObjectManager("CommandEncoder", this.mem);

		/** @type {WebGPUObjectManager<GPUComputePassEncoder>} */
		this.computePassEncoders = new WebGPUObjectManager("ComputePassEncoder", this.mem);

		/** @type {WebGPUObjectManager<GPURenderPassEncoder>} */
		this.renderPassEncoders = new WebGPUObjectManager("RenderPassEncoder", this.mem);

		/** @type {WebGPUObjectManager<GPUQuerySet>} */
		this.querySets = new WebGPUObjectManager("QuerySet", this.mem);

		/** @type {WebGPUObjectManager<GPUComputePipeline>} */
		this.computePipelines = new WebGPUObjectManager("ComputePipeline", this.mem);

		/** @type {WebGPUObjectManager<GPUPipelineLayout>} */
		this.pipelineLayouts = new WebGPUObjectManager("PipelineLayout", this.mem);

		/** @type {WebGPUObjectManager<GPUQueue>} */
		this.queues = new WebGPUObjectManager("Queue", this.mem);

		/** @type {WebGPUObjectManager<GPURenderBundle>} */
		this.renderBundles = new WebGPUObjectManager("RenderBundle", this.mem);

		/** @type {WebGPUObjectManager<GPURenderBundleEncoder>} */
		this.renderBundleEncoders = new WebGPUObjectManager("RenderBundleEncoder", this.mem);

		/** @type {WebGPUObjectManager<GPURenderPipeline>} */
		this.renderPipelines = new WebGPUObjectManager("RenderPipeline", this.mem);

		/** @type {WebGPUObjectManager<GPUSampler>} */
		this.samplers = new WebGPUObjectManager("Sampler", this.mem);

		/** @type {WebGPUObjectManager<GPUShaderModule>} */
		this.shaderModules = new WebGPUObjectManager("ShaderModule", this.mem);

		/** @type {WebGPUObjectManager<HTMLCanvasElement>} */
		this.surfaces = new WebGPUObjectManager("Surface", this.mem);

		/** @type {WebGPUObjectManager<GPUTexture>} */
		this.textures = new WebGPUObjectManager("Texture", this.mem);

		/** @type {WebGPUObjectManager<GPUTextureView>} */
		this.textureViews = new WebGPUObjectManager("TextureView", this.mem);
	}

	/**
	 * @param {number|BigInt} src
	 * @returns {number|BigInt}
	 */
	uint(src) {
		if (this.mem.intSize == 8) {
			return BigInt(src);
		} else if (this.mem.intSize == 4) {
			return src;
		} else {
			throw new Error("unreachable");
		}
	}

	/**
	 * @param {number|BigInt} src
	 * @returns {number}
	 */
	unwrapBigInt(src) {
		if (typeof src == "number") {
			return src;
		}

		const MAX_SAFE_INTEGER = 9007199254740991n;
		if (typeof src != "bigint") {
			throw new TypeError(`unwrapBigInt got invalid param of type ${typeof src}`);
		}

		if (src > MAX_SAFE_INTEGER) {
			throw new Error(`unwrapBigInt precision would be lost converting ${src}`);
		}

		return Number(src);
	}

	/**
	 * @param {boolean} condition
	 * @param {string} message
	 */
	assert(condition, message = "assertion failure") {
		if (!condition) {
			throw new Error(message);
		}
	}

	/**
	 * @template T
	 *
	 * @param {number} count
	 * @param {number} start
	 * @param {function(number): T} decoder
	 * @param {number} stride
	 * @returns {Array<T>}
	 */
	array(count, start, decoder, stride) {
		if (count == 0) {
			return [];
		}
		this.assert(start != 0);

		const out = [];
		for (let i = 0; i < count; i += 1) {
			out.push(decoder.call(this, start));
			start += stride;
		}
		return out;
	}

	/**
	 * @param {string} name
	 * @param {number} ptr
	 * @returns {`GPU${name}`}
	 */
	enumeration(name, ptr) {
		const int = this.mem.loadI32(ptr);
		this.assert(this.enums[name], `Unknown enumeration "${name}"`);
		return this.enums[name][int];
	}

	/**
	 * @param {GPUSupportedFeatures} features
	 * @param {number} ptr
	 * @returns {BigInt|number}
	 */
	genericEnumerateFeatures(features, ptr) {
		const availableFeatures = [];
		this.enums.FeatureName.forEach((feature, value) => {
			if (!feature) {
				return;
			}

			if (features.has(feature)) {
				availableFeatures.push(value);
			}
		});

		if (ptr != 0) {
			for (let i = 0; i < availableFeatures.length; i += 1) {
				this.mem.storeI32(ptr + (i * 4), availableFeatures[i]);
			}
		}

		return this.uint(availableFeatures.length);
	}

	/**
	 * @param {GPUSupportedLimits} limits
	 * @param {number} ptr
	 */
	genericGetLimits(limits, supportedLimitsPtr) {
		this.assert(supportedLimitsPtr != 0);
		const limitsPtr = supportedLimitsPtr + 8;

		this.mem.storeU32(limitsPtr + 0,   limits.maxTextureDimension1D);
		this.mem.storeU32(limitsPtr + 4,   limits.maxTextureDimension2D);
		this.mem.storeU32(limitsPtr + 8,   limits.maxTextureDimension3D);
		this.mem.storeU32(limitsPtr + 12,  limits.maxTextureArrayLayers);
		this.mem.storeU32(limitsPtr + 16,  limits.maxBindGroups);
		this.mem.storeU32(limitsPtr + 20,  limits.maxBindGroupsPlusVertexBuffers);
		this.mem.storeU32(limitsPtr + 24,  limits.maxBindingsPerBindGroup);
		this.mem.storeU32(limitsPtr + 28,  limits.maxDynamicUniformBuffersPerPipelineLayout);
		this.mem.storeU32(limitsPtr + 32,  limits.maxDynamicStorageBuffersPerPipelineLayout);
		this.mem.storeU32(limitsPtr + 36,  limits.maxSampledTexturesPerShaderStage);
		this.mem.storeU32(limitsPtr + 40,  limits.maxSamplersPerShaderStage);
		this.mem.storeU32(limitsPtr + 44,  limits.maxStorageBuffersPerShaderStage);
		this.mem.storeU32(limitsPtr + 48,  limits.maxStorageTexturesPerShaderStage);
		this.mem.storeU32(limitsPtr + 52,  limits.maxUniformBuffersPerShaderStage);
		this.mem.storeU64(limitsPtr + 56,  limits.maxUniformBufferBindingSize);
		this.mem.storeU64(limitsPtr + 64,  limits.maxStorageBufferBindingSize);
		this.mem.storeU32(limitsPtr + 72,  limits.minUniformBufferOffsetAlignment);
		this.mem.storeU32(limitsPtr + 76,  limits.minStorageBufferOffsetAlignment);
		this.mem.storeU32(limitsPtr + 80,  limits.maxVertexBuffers);
		this.mem.storeU64(limitsPtr + 88,  limits.maxBufferSize);
		this.mem.storeU32(limitsPtr + 96,  limits.maxVertexAttributes);
		this.mem.storeU32(limitsPtr + 100, limits.maxVertexBufferArrayStride);
		this.mem.storeU32(limitsPtr + 104, limits.maxInterStageShaderComponents);
		this.mem.storeU32(limitsPtr + 108, limits.maxInterStageShaderVariables);
		this.mem.storeU32(limitsPtr + 112, limits.maxColorAttachments);
		this.mem.storeU32(limitsPtr + 116, limits.maxColorAttachmentBytesPerSample);
		this.mem.storeU32(limitsPtr + 120, limits.maxComputeWorkgroupStorageSize);
		this.mem.storeU32(limitsPtr + 124, limits.maxComputeInvocationsPerWorkgroup);
		this.mem.storeU32(limitsPtr + 128, limits.maxComputeWorkgroupSizeX);
		this.mem.storeU32(limitsPtr + 132, limits.maxComputeWorkgroupSizeY);
		this.mem.storeU32(limitsPtr + 136, limits.maxComputeWorkgroupSizeZ);
		this.mem.storeU32(limitsPtr + 140, limits.maxComputeWorkgroupsPerDimension);

		return true;
	}

	/**
	 * @param {number} ptr
	 * @returns {GPUFeatureName}
	 */
	FeatureNamePtr(ptr) {
		return this.FeatureName(this.mem.loadI32(ptr));
	}

	/**
	 * @param {number} featureInt
	 * @returns {GPUFeatureName}
	 */
	FeatureName(featureInt) {
		return this.enums.FeatureName[featureInt];
	}

	/**
	 * @param {number} ptr
	 * @returns {GPUSupportedLimits}
	 */
	RequiredLimitsPtr(ptr) {
		const start = this.mem.loadPtr(ptr);
		if (start == 0) {
			return undefined;
		}

		return this.Limits(start + 8);
	}

	/**
	 * @param {number} start
	 * @return {GPUSupportedLimits}
	 */
	Limits(start) {
		const limitU32 = (ptr) => {
			const value = this.mem.loadU32(ptr);
			if (value == 0xFFFFFFFF) { // LIMIT_32_UNDEFINED.
				return undefined;
			}
			return value;
		};

		const limitU64 = (ptr) => {
			const part1 = this.mem.loadU32(ptr);
			const part2 = this.mem.loadU32(ptr + 4);
			if (part1 != 0xFFFFFFFF || part2 != 0xFFFFFFFF) { // LIMIT_64_UNDEFINED.
				return this.mem.loadU64(ptr);
			}
			return undefined;
		};

		return {
			maxTextureDimension1D:                     limitU32(start + 0),
			maxTextureDimension2D:                     limitU32(start + 4),
			maxTextureDimension3D:                     limitU32(start + 8),
			maxTextureArrayLayers:                     limitU32(start + 12),
			maxBindGroups:                             limitU32(start + 16),
			maxBindGroupsPlusVertexBuffers:            limitU32(start + 20),
			maxBindingsPerBindGroup:                   limitU32(start + 24),
			maxDynamicUniformBuffersPerPipelineLayout: limitU32(start + 28),
			maxDynamicStorageBuffersPerPipelineLayout: limitU32(start + 32),
			maxSampledTexturesPerShaderStage:          limitU32(start + 36),
			maxSamplersPerShaderStage:                 limitU32(start + 40),
			maxStorageBuffersPerShaderStage:           limitU32(start + 44),
			maxStorageTexturesPerShaderStage:          limitU32(start + 48),
			maxUniformBuffersPerShaderStage:           limitU32(start + 52),
			maxUniformBufferBindingSize:               limitU64(start + 56),
			maxStorageBufferBindingSize:               limitU64(start + 64),
			minUniformBufferOffsetAlignment:           limitU32(start + 72),
			minStorageBufferOffsetAlignment:           limitU32(start + 76),
			maxVertexBuffers:                          limitU32(start + 80),
			maxBufferSize:                             limitU64(start + 88),
			maxVertexAttributes:                       limitU32(start + 96),
			maxVertexBufferArrayStride:                limitU32(start + 100),
			maxInterStageShaderComponents:             limitU32(start + 104),
			maxInterStageShaderVariables:              limitU32(start + 108),
			maxColorAttachments:                       limitU32(start + 112),
			maxColorAttachmentBytesPerSample:          limitU32(start + 116),
			maxComputeWorkgroupStorageSize:            limitU32(start + 120),
			maxComputeInvocationsPerWorkgroup:         limitU32(start + 124),
			maxComputeWorkgroupSizeX:                  limitU32(start + 128),
			maxComputeWorkgroupSizeY:                  limitU32(start + 132),
			maxComputeWorkgroupSizeZ:                  limitU32(start + 136),
			maxComputeWorkgroupsPerDimension:          limitU32(start + 140),
		};
	}

	/**
	 * @param {number} start
	 * @returns {GPUQueueDescriptor}
	 */
	QueueDescriptor(start) {
		return {
			label: this.mem.loadCstring(start + 4),
		};
	}

	/**
	 * @param {number} ptr
	 * @returns {GPUComputePassTimestampWrites}
	 */
	ComputePassTimestampWritesPtr(ptr) {
		const start = this.mem.loadPtr(ptr);
		if (start == 0) {
			return undefined;
		}

		return {
			querySet:                  this.querySets.get(this.mem.loadPtr(start + 0)),
			beginningOfPassWriteIndex: this.mem.loadU32(start + 4),
			endOfPassWriteIndex:       this.mem.loadU32(start + 8),
		};
	}

	/**
	 * @param {number} start
	 * @returns {GPURenderPassColorAttachment}
	 */
	RenderPassColorAttachment(start) {
		const viewIdx = this.mem.loadPtr(start + 4);
		const resolveTargetIdx = this.mem.loadPtr(start + 8);

		return {
			view: viewIdx > 0 ? this.textureViews.get(viewIdx) : undefined,
			resolveTarget: resolveTargetIdx > 0 ? this.textureViews.get(resolveTargetIdx) : undefined,
			loadOp: this.enumeration("LoadOp", start + 12),
			storeOp: this.enumeration("StoreOp", start + 16),
			clearValue: this.Color(start + 24),
		};
	}

	/**
	 * @param {number} start
	 * @returns {GPUColor}
	 */
	Color(start) {
		return {
			r: this.mem.loadF64(start + 0),
			g: this.mem.loadF64(start + 8),
			b: this.mem.loadF64(start + 16),
			a: this.mem.loadF64(start + 24),
		};
	}

	/**
	 * @param {number} ptr
	 * @returns {GPURenderPassDepthStencilAttachment}
	 */
	RenderPassDepthStencilAttachmentPtr(ptr) {
		const start = this.mem.loadPtr(ptr);
		if (start == 0) {
			return undefined;
		}

		return {
			view:              this.textureViews.get(this.mem.loadPtr(start + 0)),
			depthLoadOp:       this.enumeration("LoadOp", start + 4),
			depthStoreOp:      this.enumeration("StoreOp", start + 8),
			depthClearValue:   this.mem.loadF32(start + 12),
			depthReadOnly:     this.mem.loadB32(start + 16),
			stencilLoadOp:     this.enumeration("LoadOp", start + 20),
			stencilStoreOp:    this.enumeration("StoreOp", start + 24),
			stencilClearValue: this.mem.loadF32(start + 28),
			stencilReadOnly:   this.mem.loadB32(start + 32),
		};
	}

	/**
	 * @param {number} ptr
	 * @returns {undefined|GPUQuerySet}
	 */
	QuerySet(ptr) {
		ptr = this.mem.loadPtr(ptr);
		if (ptr == 0) {
			return undefined;
		}

		return this.querySets.get(ptr);
	}

	/**
	 * @param {number} ptr
	 * @returns {GPURenderPassTimestampWrites}
	 */
	RenderPassTimestampWritesPtr(ptr) {
		return this.ComputePassTimestampWritesPtr(ptr);
	}
	
	/**
	 * @param {number} start
	 * @returns {GPUImageDataLayout}
	 */
	TextureDataLayout(start) {
		return {
			offset: this.mem.loadU64(start + 8),
			bytesPerRow: this.mem.loadU32(start + 16),
			rowsPerImage: this.mem.loadU32(start + 20),
		};
	}

	/**
	 * @param {number} start
	 * @returns {GPUImageCopyBuffer}
	 */
	ImageCopyBuffer(start) {
		return {
			...this.TextureDataLayout(start + 8),
			buffer: this.buffers.get(this.mem.loadPtr(start + 32)).buffer,
		};
	}

	/**
	 * @param {number} start
	 * @returns {GPUImageCopyTexture}
	 */
	ImageCopyTexture(start) {
		return {
			texture: this.textures.get(this.mem.loadPtr(start + 4)),
			mipLevel: this.mem.loadU32(start + 8),
			origin: this.Origin3D(start + 12),
			aspect: this.enumeration("TextureAspect", start + 24),
		};
	}

	/**
	 * @param {number} start
	 * @returns {GPUOrigin3D}
	 */
	Origin3D(start) {
		return {
			x: this.mem.loadU32(start + 0),
			y: this.mem.loadU32(start + 4),
			z: this.mem.loadU32(start + 8),
		};
	}

	/**
	 * @param {number} start
	 * @returns {GPUExtent3D}
	 */
	Extent3D(start) {
		return {
			width:              this.mem.loadU32(start + 0),
			height:             this.mem.loadU32(start + 4),
			depthOrArrayLayers: this.mem.loadU32(start + 8),
		};
	}

	/**
	 * @param {number} start
	 * @returns {GPUBindGroupEntry}
	 */
	BindGroupEntry(start) {
		const buffer = this.mem.loadPtr(start + 8);
		const sampler = this.mem.loadPtr(start + 32);
		const textureView = this.mem.loadPtr(start + 36);

		/** @type {GPUBindingResource} */
		let resource;
		if (buffer > 0) {
			resource = {
				buffer: this.buffers.get(buffer).buffer,
				offset: this.mem.loadU64(start + 16),
				size: this.mem.loadU64(start + 24),
			}
		} else if (sampler > 0) {
			resource = this.samplers.get(sampler);
		} else if (textureView > 0) {
			resource = this.textureViews.get(textureView);
		}

		return {
			binding: this.mem.loadU32(start + 4),
			resource: resource,
		};
	}

	/**
	 * @param {number} start
	 * @returns {GPUBindGroupLayoutEntry}
	 */
	BindGroupLayoutEntry(start) {
		const entry = {
			binding:        this.mem.loadU32(start + 4),
			visibility:     this.mem.loadU32(start + 8),
			buffer:         this.BufferBindingLayout(start + 16),
			sampler:        this.SamplerBindingLayout(start + 40),
			texture:        this.TextureBindingLayout(start + 48),
			storageTexture: this.StorageTextureBindingLayout(start + 64),
		};
		if (!entry.buffer.type) {
			entry.buffer = undefined;
		}
		if (!entry.sampler.type) {
			entry.sampler = undefined;
		}
		if (!entry.texture.sampleType) {
			entry.texture = undefined;
		}
		if (!entry.storageTexture.access) {
			entry.storageTexture = undefined;
		}
		return entry;
	}

	/**
	 * @param {number} start
	 * @returns {GPUBufferBindingLayout}
	 */
	BufferBindingLayout(start) {
		return {
			type: this.enumeration("BufferBindingType", start + 4),
			hasDynamicOffset: this.mem.loadB32(start + 8),
			minBindingSize: this.mem.loadU64(start + 16),
		};
	}

	/**
	 * @param {number} start
	 * @returns {GPUSamplerBindingLayout}
	 */
	SamplerBindingLayout(start) {
		return {
			type: this.enumeration("SamplerBindingType", start + 4),
		};
	}

	/**
	 * @param {number} start
	 * @returns {GPUTextureBindingLayout}
	 */
	TextureBindingLayout(start) {
		return {
			sampleType: this.enumeration("TextureSampleType", start + 4),
			viewDimension: this.enumeration("TextureViewDimension", start + 8),
			multisampled: this.mem.loadB32(start + 12),
		};
	}

	/**
	 * @param {number} start
	 * @returns {GPUStorageTextureBindingLayout}
	 */
	StorageTextureBindingLayout(start) {
		return {
			access: this.enumeration("StorageTextureAccess", start + 4),
			format: this.enumeration("TextureFormat", start + 8),
			viewDimension: this.enumeration("TextureViewDimension", start + 12),
		};
	}

	/**
	 * @param {number} start
	 * @returns {GPUProgrammableStage}
	 */
	ProgrammableStageDescriptor(start) {
		const constantsArray = this.array(
			this.mem.loadUint(start + 8 + this.mem.intSize),
			this.mem.loadPtr(start + 8 + this.mem.intSize*2),
			this.ConstantEntry,
			16,
		);
		return {
			module:     this.shaderModules.get(this.mem.loadPtr(start + 4)),
			entryPoint: this.mem.loadCstring(start + 8),
			constants:  constantsArray.reduce((prev, curr) => {
				prev[curr.key] = curr.value;
				return prev;
			}, {}),
		};
	}

	/**
	 * @param {number} start
	 * @returns {{ key: string, value: number }}
	 */
	ConstantEntry(start) {
		return {
			key:   this.mem.loadCstring(start + 4),
			value: this.mem.loadF64(start + 8),
		};
	}

	/**
	 * @param {number} start
	 * @returns {GPUComputePipelineDescriptor}
	 */
	ComputePipelineDescriptor(start) {
		const layoutIdx = this.mem.loadPtr(start + 8)
		return {
			label: this.mem.loadCstring(start + 4),
			layout: layoutIdx > 0 ? this.pipelineLayouts.get(layoutIdx) : undefined,
			compute: this.ProgrammableStageDescriptor(start + 8 + this.mem.intSize),
		};
	}

	/**
	 * @param {number} start
	 * @returns {GPUVertexState}
	 */
	VertexState(start) {
		let off = 8 + this.mem.intSize;
		const constantsArray = this.array(
			this.mem.loadUint(start + off),
			this.mem.loadPtr(start + off + this.mem.intSize),
			this.ConstantEntry,
			16,
		);

		off += this.mem.intSize * 2;

		return {
			module: this.shaderModules.get(this.mem.loadPtr(start + 4)),
			entryPoint: this.mem.loadCstring(start + 8),
			constants: constantsArray.reduce((prev, curr) => {
				prev[curr.key] = curr.value;
				return prev;
			}, {}),
			buffers: this.array(
				this.mem.loadUint(start + off),
				this.mem.loadPtr(start + off + this.mem.intSize),
				this.VertexBufferLayout,
				this.mem.intSize == 8 ? 32 : 24,
			),
		};
	}

	/**
	 * @param {number} start
	 * @returns {?GPUVertexBufferLayout}
	 */
	VertexBufferLayout(start) {
		const stepMode = this.enumeration("VertexStepMode", start + 8);
		if (stepMode == "vertex-buffer-not-used") {
			return null;
		}
		return {
			arrayStride: this.mem.loadU64(start + 0),
			stepMode: stepMode,
			attributes: this.array(
				this.mem.loadUint(start + 8 + this.mem.intSize),
				this.mem.loadPtr(start + 8 + this.mem.intSize*2),
				this.VertexAttribute,
				24,
			),
		};
	}

	/**
	 * @param {number} start
	 * @returns {GPUVertexAttribute}
	 */
	VertexAttribute(start) {
		return {
			format:         this.enumeration("VertexFormat", start + 0),
			offset:         this.mem.loadU64(start + 8),
			shaderLocation: this.mem.loadU32(start + 16),
		};
	}

	/**
	 * @param {number} start
	 * @returns {GPUPrimitiveState}
	 */
	PrimitiveState(start) {
		let unclippedDepth = undefined;
		const nextInChain = this.mem.loadPtr(start);
		if (nextInChain != 0) {
			const nextInChainType = this.mem.loadI32(nextInChain + 4);
    		// PrimitiveDepthClipControl = 0x00000007,
			if (nextInChainType == 7) {
				unclippedDepth = this.mem.loadB32(nextInChain + 8);
			}
		}

		return {
			topology:         this.enumeration("PrimitiveTopology", start + 4),
			stripIndexFormat: this.enumeration("IndexFormat", start + 8),
			frontFace:        this.enumeration("FrontFace", start + 12),
			cullMode:         this.enumeration("CullMode", start + 16),
			unclippedDepth:   unclippedDepth,
		};
	}

	/**
	 * @param {number} start
	 * @returns {GPURenderPipelineDescriptor}
	 */
	RenderPipelineDescriptor(start) {
		const layoutIdx = this.mem.loadPtr(start + 8);
		const offs = this.mem.intSize == 8 ? [64, 84, 88, 104] : [40, 60, 64, 80];
		return {
			label:        this.mem.loadCstring(start + 4),
			layout:       layoutIdx > 0 ? this.pipelineLayouts.get(layoutIdx) : undefined,
			vertex:       this.VertexState(start + 8 + this.mem.intSize),
			primitive:    this.PrimitiveState(start + offs[0]),
			depthStencil: this.DepthStencilStatePtr(start + offs[1]),
			multisample:  this.MultisampleState(start + offs[2]),
			fragment:     this.FragmentStatePtr(start + offs[3]),
		};
	}

	/**
	 * @param {number} start
	 * @returns {GPUShaderModuleCompilationHint}
	 */
	ShaderModuleCompilationHint(start) {
		return {
			entryPoint: this.mem.loadCstring(start + 4),
			layout: this.pipelineLayouts.get(this.mem.loadPtr(start + 8)),
		};
	}

	/**
	 * @param {number} ptr
	 * @returns {?GPUDepthStencilState}
	 */
	DepthStencilStatePtr(ptr) {
		const start = this.mem.loadPtr(ptr);
		if (start == 0) {
			return undefined;
		}

		return {
			format:              this.enumeration("TextureFormat", start + 4),
			depthWriteEnabled:   this.mem.loadB32(start + 8),
			depthCompare:        this.enumeration("CompareFunction", start + 12),
			stencilFront:        this.StencilFaceState(start + 16),
			stencilBack:         this.StencilFaceState(start + 32),
			stencilReadMask:     this.mem.loadU32(start + 48),
			stencilWriteMask:    this.mem.loadU32(start + 52),
			depthBias:           this.mem.loadI32(start + 56),
			depthBiasSlopeScale: this.mem.loadF32(start + 60),
			depthBiasClamp:      this.mem.loadF32(start + 64),
		};
	}

	/**
	 * @param {number} start
	 * @returns {GPUStencilFaceState}
	 */
	StencilFaceState(start) {
		return {
			compare:     this.enumeration("CompareFunction",  start + 0),
			failOp:      this.enumeration("StencilOperation", start + 4),
			depthFailOp: this.enumeration("StencilOperation", start + 8),
			passOp:      this.enumeration("StencilOperation", start + 12),
		};
	}

	/**
	 * @param {number} start
	 * @returns {GPUMultisampleState}
	 */
	MultisampleState(start) {
		return {
			count:                  this.mem.loadU32(start + 4),
			mask:                   this.mem.loadU32(start + 8),
			alphaToCoverageEnabled: this.mem.loadB32(start + 12),
		};
	}

	/**
	 * @param {number} ptr
	 * @returns {?GPUFragmentState}
	 */
	FragmentStatePtr(ptr) {
		const start = this.mem.loadPtr(ptr);
		if (start == 0) {
			return undefined;
		}

		let off = 8 + this.mem.intSize;

		const constantsArray = this.array(
			this.mem.loadUint(start + off),
			this.mem.loadPtr(start + off + this.mem.intSize),
			this.ConstantEntry,
			16,
		);

		off += this.mem.intSize * 2;

		return {
			module:     this.shaderModules.get(this.mem.loadPtr(start + 4)),
			entryPoint: this.mem.loadCstring(start + 8),
			constants: constantsArray.reduce((prev, curr) => {
				prev[curr.key] = curr.value;
				return prev;
			}, {}),
			targets: this.array(
				this.mem.loadUint(start + off),
				this.mem.loadPtr(start + off + this.mem.intSize),
				this.ColorTargetState,
				16,
			),
		};
	}

	/**
	 * @param {number} start
	 * @returns {GPUColorTargetState}
	 */
	ColorTargetState(start) {
		return {
			format:    this.enumeration("TextureFormat", start + 4),
			blend:     this.BlendStatePtr(start + 8),
			writeMask: this.mem.loadU32(start + 12),
		};
	}

	/**
	 * @param {number} ptr
	 * @returns {?GPUBlendState}
	 */
	BlendStatePtr(ptr) {
		const start = this.mem.loadPtr(ptr);
		if (start == 0) {
			return undefined;
		}

		return {
			color: this.BlendComponent(start + 0),
			alpha: this.BlendComponent(start + 12),
		};
	}

	/**
	 * @param {number} start
	 * @returns {?GPUBlendComponent}
	 */
	BlendComponent(start) {
		return {
			operation: this.enumeration("BlendOperation", start + 0),
			srcFactor: this.enumeration("BlendFactor",    start + 4),
			dstFactor: this.enumeration("BlendFactor",    start + 8),
		};
	}

	getInterface() {
		return {
			/**
			 * @param {0|number} descriptorPtr
			 * @returns {number}
			 */
			wgpuCreateInstance: (descriptorPtr) => {
				if (!navigator.gpu) {
					console.error("WebGPU is not supported by this browser");
					return 0;
				}

				return this.instances.create({});
			},

			/**
			 * @param {number} deviceIdx
			 * @param {number} procNamePtr
			 * @returns {number}
			 */
			wgpuGetProcAddress: (deviceIdx, procNamePtr) => {
				console.error(`unimplemented: wgpuGetProcAddress`);
				return 0;
			},

			/* ---------------------- Adapter ---------------------- */

			/**
			 * @param {number} adapterIdx
			 * @param {number} featuresPtr
			 * @returns {number|BigInt}
			 */
			wgpuAdapterEnumerateFeatures: (adapterIdx, featuresPtr) => {
				const adapter = this.adapters.get(adapterIdx);
				return this.genericEnumerateFeatures(adapter.features, featuresPtr);
			},

			/**
			 * @param {number} adapterIdx
			 * @param {number} supportedLimitsPtr
			 * @returns {boolean}
			 */
			wgpuAdapterGetLimits: (adapterIdx, supportedLimitsPtr) => {
				const adapter = this.adapters.get(adapterIdx);
				return this.genericGetLimits(adapter.limits, supportedLimitsPtr);
			},

			/**
			 * @param {number} adapterIdx
			 * @param {number} propertiesPtr
			 */
			wgpuAdapterGetProperties: (adapterIdx, propertiesPtr) => {
				this.assert(propertiesPtr != 0);
 				// Unknown adapter.
				this.mem.storeI32(propertiesPtr + 28, 3);
				// WebGPU backend.
				this.mem.storeI32(propertiesPtr + 32, 2);
			},

			/**
			 * @param {number} adapterIdx
			 * @param {number} featureInt
			 * @returns {boolean}
			 */
			wgpuAdapterHasFeature: (adapterIdx, featureInt) => {
				const adapter = this.adapters.get(adapterIdx);
				return adapter.features.has(this.enums.FeatureName[featureInt]);
			},

			/**
			 * @param {number} adapterIdx
			 * @param {number} callbackPtr
			 * @param {0|number} userdata
			 */
			wgpuAdapterRequestAdapterInfo: async (adapterIdx, callbackPtr, userdata) => {
				const adapter  = this.adapters.get(adapterIdx);
				const callback = this.mem.exports.__indirect_function_table.get(callbackPtr);

				const info = await adapter.requestAdapterInfo();

				const addr = this.mem.exports.wgpu_alloc(16);

				const vendorLength = new TextEncoder().encode(info.vendor).length;
				const vendorAddr = this.mem.exports.wgpu_alloc(vendorLength);
				this.mem.storeString(vendorAddr, info.vendor);
				this.mem.storeI32(addr + 0, vendorAddr);

				const architectureLength = new TextEncoder().encode(info.architecture).length;
				const architectureAddr = this.mem.exports.wgpu_alloc(architectureLength);
				this.mem.storeString(architectureAddr, info.architecture);
				this.mem.storeI32(addr + 4, architectureAddr);


				const deviceLength = new TextEncoder().encode(info.device).length;
				const deviceAddr = this.mem.exports.wgpu_alloc(deviceLength);
				this.mem.storeString(deviceAddr, info.device);
				this.mem.storeI32(addr + 8, deviceAddr);


				const descriptionLength = new TextEncoder().encode(info.description).length;
				const descriptionAddr = this.mem.exports.wgpu_alloc(descriptionLength);
				this.mem.storeString(descriptionAddr, info.description);
				this.mem.storeI32(addr + 12, descriptionAddr);

				callback(addr, userdata);

				this.mem.exports.wgpu_free(descriptionAddr);
				this.mem.exports.wgpu_free(deviceAddr);
				this.mem.exports.wgpu_free(architectureAddr);
				this.mem.exports.wgpu_free(vendorAddr);
				this.mem.exports.wgpu_free(addr);
			},

			/**
			 * @param {number} adapterIdx
			 * @param {0|number} descriptorPtr
			 * @param {number} callbackPtr
			 * @param {0|number} userdata
			 */
			wgpuAdapterRequestDevice: async (adapterIdx, descriptorPtr, callbackPtr, userdata) => {
				const adapter  = this.adapters.get(adapterIdx);
				const callback = this.mem.exports.__indirect_function_table.get(callbackPtr);

				/** @type {GPUDeviceDescriptor} */
				let descriptor;
				if (descriptorPtr != 0) {
					descriptor = {
						label: this.mem.loadCstring(descriptorPtr + 4),
						requiredFeatures: this.array(
							this.mem.loadUint(descriptorPtr + 8),
							this.mem.loadPtr(descriptorPtr  + 8 + this.mem.intSize),
							this.FeatureNamePtr,
							4,
						),
						requiredLimits: this.RequiredLimitsPtr(descriptorPtr + 8 + this.mem.intSize + 4),
						defaultQueue:   this.QueueDescriptor(  descriptorPtr + 8 + this.mem.intSize + 4 + 4),
					};
				}

				let deviceIdx;
				try {
					const device = await adapter.requestDevice(descriptor);
					deviceIdx = this.devices.create(device);
					// NOTE: don't callback here, any errors that happen later will then be caught by the catch here.
				} catch (e) {
					console.warn(e);
					callback(1, null, null, userdata);
				}

				callback(0, deviceIdx, null, userdata);
			},

			...this.adapters.interface(),

			/* ---------------------- BindGroup ---------------------- */

			...this.bindGroups.interface(true),

			/* ---------------------- BindGroupLayout ---------------------- */

			...this.bindGroupLayouts.interface(true),

			/* ---------------------- Buffer ---------------------- */

			/** @param {number} bufferIdx */
			wgpuBufferDestroy: (bufferIdx) => {
				const buffer = this.buffers.get(bufferIdx);
				buffer.buffer.destroy();
			},

			/**
			 * @param {number} bufferIdx
			 * @param {number|BigInt} offset
			 * @param {number|BigInt} size
			 * @returns {number}
			 */
			wgpuBufferGetMappedRange: (bufferIdx, offset, size) => {
				const buffer = this.buffers.get(bufferIdx);
				offset = this.unwrapBigInt(offset);
				size   = this.unwrapBigInt(size);

				this.assert(!buffer.mapping, "buffer already mapped");

				const range = buffer.buffer.getMappedRange(offset, size);

				const ptr = this.mem.exports.wgpu_alloc(range.byteLength);

				buffer.mapping = { range: range, ptr: ptr, size: range.byteLength };
				return ptr;
			},

			/**
			 * @param {number} bufferIdx
			 * @returns {BigInt}
			 */
			wgpuBufferGetSize: (bufferIdx) => {
				const buffer = this.buffers.get(bufferIdx);
				return BigInt(buffer.buffer.size);
			},

			/**
			 * @param {number} bufferIdx
			 * @returns {number}
			 */
			wgpuBufferGetUsage: (bufferIdx) => {
				const buffer = this.buffers.get(bufferIdx);
				return buffer.buffer.usage;
			},

			/**
			 * @param {number} bufferIdx
			 * @param {number} mode
			 * @param {number|BigInt} offset
			 * @param {number|BigInt} size
			 * @param {number} callbackPtr
			 * @param {0|number} userdata
			 */
			wgpuBufferMapAsync: async (bufferIdx, mode, offset, size, callbackPtr, userdata) => {
				const buffer = this.buffers.get(bufferIdx);
				const callback = this.mem.exports.__indirect_function_table.get(callbackPtr);
				offset = this.unwrapBigInt(offset);
				size   = this.unwrapBigInt(size);

				if (buffer.buffer.mapState == "pending") {
					callback(this.enums.BufferMapAsyncStatus.MappingAlreadyPending, userdata);
				} else {
					let result;
					try {
						await buffer.buffer.mapAsync(mode, offset, size);
						result = 0; // Success.
					} catch(e) {
						console.warn(e);
						result = 2; // Unknown error.

						if (e instanceof DomException) {
							if (e.name == "OperationError") {
								result = 1; // Validation error.
							}
						}
					}

					callback(result, userdata);
				}
			},

			/**
			 * @param {number} bufferIdx
			 * @param {number} labelPtr
			 */
			wgpuBufferSetLabel: (bufferIdx, labelPtr) => {
				const buffer = this.buffers.get(bufferIdx);
				buffer.buffer.label = this.mem.loadCstring(labelPtr);
			},

			/**
			 * @param {number} bufferIdx
			 */
			wgpuBufferUnmap: (bufferIdx) => {
				const buffer = this.buffers.get(bufferIdx);
				this.assert(buffer.mapping, "buffer not mapped");

				const mapping = new Uint8Array(this.mem.memory.buffer, buffer.mapping.ptr, buffer.mapping.size);
				(new Uint8Array(buffer.mapping.range)).set(mapping);

				buffer.buffer.unmap();

				this.mem.exports.wgpu_free(buffer.mapping.ptr);
				buffer.mapping = null;
			},

			...this.buffers.interface(),

			/* ---------------------- CommandBuffer ---------------------- */

			...this.commandBuffers.interface(true),

			/* ---------------------- CommandEncoder ---------------------- */

			/**
			 * @param {number} commandEncoderIdx
			 * @param {0|number} descriptorPtr
			 * @return {number} The compute pass encoder
			 */
			wgpuCommandEncoderBeginComputePass: (commandEncoderIdx, descriptorPtr) => {
				const commandEncoder = this.commandEncoders.get(commandEncoderIdx);

				/** @type {?GPUComputePassDescriptor} */
				let descriptor;
				if (descriptorPtr != 0) {
					descriptor = {
						label:           this.mem.loadCstring(descriptorPtr + 4),
						timestampWrites: this.ComputePassTimestampWritesPtr(descriptorPtr + 8),
					};
				}

				const computePassEncoder = commandEncoder.beginComputePass(descriptor);
				return this.computePassEncoders.create(computePassEncoder);
			},

			/**
			 * @param {number} commandEncoderIdx
			 * @param {number} descriptorPtr
			 * @return {number} The render pass encoder
			 */
			wgpuCommandEncoderBeginRenderPass: (commandEncoderIdx, descriptorPtr) => {
				const commandEncoder = this.commandEncoders.get(commandEncoderIdx);
				this.assert(descriptorPtr != 0);

				let maxDrawCount = undefined;
				const nextInChain = this.mem.loadPtr(descriptorPtr);
				if (nextInChain != 0) {
					const nextInChainType = this.mem.loadI32(nextInChain + 4);
					// RenderPassDescriptorMaxDrawCount = 0x0000000F,
					if (nextInChainType == 0x0000000F) {
						maxDrawCount = this.mem.loadU64(nextInChain + 8);
					}
				}

				/** @type {GPURenderPassDescriptor} */
				const descriptor = {
					label: this.mem.loadCstring(descriptorPtr + 4),
					colorAttachments: this.array(
						this.mem.loadUint(descriptorPtr + 8),
						this.mem.loadPtr(descriptorPtr + 8 + this.mem.intSize),
						this.RenderPassColorAttachment,
						56,
					),
					depthStencilAttachment: this.RenderPassDepthStencilAttachmentPtr(descriptorPtr + 8 + this.mem.intSize + 4),
					occlusionQuerySet: this.QuerySet(descriptorPtr + 8 + this.mem.intSize + 4 + 4),
					timestampWrites: this.RenderPassTimestampWritesPtr(descriptorPtr + 8 + this.mem.intSize + 4 + 4),
					maxDrawCount: maxDrawCount,
				};

				const renderPassEncoder = commandEncoder.beginRenderPass(descriptor);
				return this.renderPassEncoders.create(renderPassEncoder);
			},

			/**
			 * @param {number} commandEncoderIdx
			 * @param {number} bufferIdx
			 * @param {BigInt} offset
			 * @param {BigInt} size
			 */
			wgpuCommandEncoderClearBuffer: (commandEncoderIdx, bufferIdx, offset, size) => {
				const commandEncoder = this.commandEncoders.get(commandEncoderIdx);
				const buffer = this.buffers.get(bufferIdx);
				offset = this.unwrapBigInt(offset);
				size = this.unwrapBigInt(size);
				commandEncoder.clearBuffer(buffer.buffer, offset, size);
			},

			/**
			 * @param {number} commandEncoderIdx
			 * @param {number} sourceIdx
			 * @param {BigInt} sourceOffset
			 * @param {number} destinationIdx
			 * @param {BigInt} destinationOffset
			 * @param {BigInt} size
			 */
			wgpuCommandEncoderCopyBufferToBuffer: (commandEncoderIdx, sourceIdx, sourceOffset, destinationIdx, destinationOffset, size) => {
				const commandEncoder = this.commandEncoders.get(commandEncoderIdx);
				const source = this.buffers.get(sourceIdx);
				const destination = this.buffers.get(destinationIdx);
				sourceOffset = this.unwrapBigInt(sourceOffset);
				destinationOffset = this.unwrapBigInt(destinationOffset);
				size = this.unwrapBigInt(size);
				commandEncoder.copyBufferToBuffer(source.buffer, sourceOffset, destination.buffer, destinationOffset, size);
			},

			/**
			 * @param {number} commandEncoderIdx
			 * @param {number} sourcePtr
			 * @param {number} destinationPtr
			 * @param {number} copySizePtr
			 */
			wgpuCommandEncoderCopyBufferToTexture: (commandEncoderIdx, sourcePtr, destinationPtr, copySizePtr) => {
				const commandEncoder = this.commandEncoders.get(commandEncoderIdx);
				commandEncoder.copyBufferToTexture(
					this.ImageCopyBuffer(sourcePtr),
					this.ImageCopyTexture(destinationPtr),
					this.Extent3D(copySizePtr),
				);
			},

			/**
			 * @param {number} commandEncoderIdx
			 * @param {number} sourcePtr
			 * @param {number} destinationPtr
			 * @param {number} copySizePtr
			 */
			wgpuCommandEncoderCopyTextureToBuffer: (commandEncoderIdx, sourcePtr, destinationPtr, copySizePtr) => {
				const commandEncoder = this.commandEncoders.get(commandEncoderIdx);
				commandEncoder.copyTextureToBuffer(
					this.ImageCopyTexture(sourcePtr),
					this.ImageCopyBuffer(destinationPtr),
					this.Extent3D(copySizePtr),
				);
			},

			/**
			 * @param {number} commandEncoderIdx
			 * @param {number} sourcePtr
			 * @param {number} destinationPtr
			 * @param {number} copySizePtr
			 */
			wgpuCommandEncoderCopyTextureToTexture: (commandEncoderIdx, sourcePtr, destinationPtr, copySizePtr) => {
				const commandEncoder = this.commandEncoders.get(commandEncoderIdx);
				commandEncoder.copyTextureToTexture(
					this.ImageCopyTexture(sourcePtr),
					this.ImageCopyTexture(destinationPtr),
					this.Extent3D(copySizePtr),
				);
			},

			/**
			 * @param {number} commandEncoderIdx
			 * @param {0|number} descriptorPtr
			 * @returns {number} The command buffer.
			 */
			wgpuCommandEncoderFinish: (commandEncoderIdx, descriptorPtr) => {
				const commandEncoder = this.commandEncoders.get(commandEncoderIdx);

				/** @type {undefined|GPUCommandBufferDescriptor} */
				let descriptor;
				if (descriptorPtr != 0) {
					descriptor = {
						label: this.mem.loadCstring(descriptorPtr + 4),
					};
				}

				const commandBuffer = commandEncoder.finish(descriptor);
				return this.commandBuffers.create(commandBuffer);
			},

			/**
			 * @param {number} commandEncoderIdx
			 * @param {number} markerLabelPtr
			 */
			wgpuCommandEncoderInsertDebugMarker: (commandEncoderIdx, markerLabelPtr) => {
				const commandEncoder = this.commandEncoders.get(commandEncoderIdx);
				commandEncoder.insertDebugMarker(this.mem.loadCstring(markerLabelPtr));
			},

			/**
			 * @param {number} commandEncoderIdx
			 */
			wgpuCommandEncoderPopDebugGroup: (commandEncoderIdx) => {
				const commandEncoder = this.commandEncoders.get(commandEncoderIdx);
				commandEncoder.popDebugGroup();
			},

			/**
			 * @param {number} commandEncoderIdx
			 * @param {number} markerLabelPtr
			 */
			wgpuCommandEncoderPushDebugGroup: (commandEncoderIdx, groupLabelPtr) => {
				const commandEncoder = this.commandEncoders.get(commandEncoderIdx);
				commandEncoder.pushDebugGroup(this.mem.loadCstring(groupLabelPtr));
			},

			/**
			 * @param {number} commandEncoderIdx
			 * @param {number} querySetIdx
			 * @param {number} firstQuery
			 * @param {number} queryCount
			 * @param {number} destinationIdx
			 * @param {BigInt} destinationOffset
			 */
			wgpuCommandEncoderResolveQuerySet: (commandEncoderIdx, querySetIdx, firstQuery, queryCount, destinationIdx, destinationOffset) => {
				const commandEncoder = this.commandEncoders.get(commandEncoderIdx);
				const querySet = this.querySets.get(querySetIdx);
				const destination = this.buffers.get(destinationIdx);
				destinationOffset = this.unwrapBigInt(destinationOffset);
				commandEncoder.resolveQuerySet(querySet, firstQuery, queryCount, destination.buffer, destinationOffset);
			},

			/**
			 * @param {number} commandEncoderIdx
			 * @param {number} querySetIdx
			 * @param {number} queryIndex
			 */
			wgpuCommandEncoderWriteTimestamp: (commandEncoderIdx, querySetIdx, queryIndex) => {
				const commandEncoder = this.commandEncoders.get(commandEncoderIdx);
				const querySet = this.querySets.get(querySetIdx);
				commandEncoder.writeTimestamp(querySet, queryIndex);
			},

			...this.commandEncoders.interface(true),

			/* ---------------------- ComputePassEncoder ---------------------- */


			/**
			 * @param {number} computePassEncoderIdx
			 * @param {number} workgroupCountX
			 * @param {number} workgroupCountY
			 * @param {number} workgroupCountZ
			 */
			wgpuComputePassEncoderDispachWorkgroups: (computePassEncoderIdx, workgroupCountX, workgroupCountY, workgroupCountZ) => {
				const computePassEncoder = this.computePassEncoders.get(computePassEncoderIdx);
				computePassEncoder.dispatchWorkgroups(workgroupCountX, workgroupCountY, workgroupCountZ);
			},

			/**
			 * @param {number} computePassEncoderIdx
			 * @param {number} indirectBufferIdx
			 * @param {BigInt} indirectOffset
			 */
			wgpuComputePassEncoderDispachWorkgroupsIndirect: (computePassEncoderIdx, indirectBufferIdx, indirectOffset) => {
				const computePassEncoder = this.computePassEncoders.get(computePassEncoderIdx);
				const indirectBuffer = this.buffers.get(indirectBufferIdx);
				indirectOffset = this.unwrapBigInt(indirectOffset);
				computePassEncoder.dispatchWorkgroupsIndirect(indirectBuffer.buffer, indirectOffset);
			},

			/**
			 * @param {number} computePassEncoderIdx
			 */
			wgpuComputePassEncoderEnd: (computePassEncoderIdx) => {
				const computePassEncoder = this.computePassEncoders.get(computePassEncoderIdx);
				computePassEncoder.end();
			},

			/**
			 * @param {number} computePassEncoderIdx
			 * @param {number} markerLabelPtr
			 */
			wgpuComputePassEncoderInsertDebugMarker: (computePassEncoderIdx, markerLabelPtr) => {
				const computePassEncoder = this.computePassEncoders.get(computePassEncoderIdx);
				computePassEncoder.insertDebugMarker(this.mem.loadCstring(markerLabelPtr));
			},

			/**
			 * @param {number} computePassEncoderIdx
			 */
			wgpuComputePassEncoderPopDebugGroup: (computePassEncoderIdx) => {
				const computePassEncoder = this.computePassEncoders.get(computePassEncoderIdx);
				computePassEncoder.popDebugGroup();
			},

			/**
			 * @param {number} computePassEncoderIdx
			 * @param {number} markerLabelPtr
			 */
			wgpuComputePassEncoderPushDebugGroup: (computePassEncoderIdx, groupLabelPtr) => {
				const computePassEncoder = this.computePassEncoders.get(computePassEncoderIdx);
				computePassEncoder.pushDebugGroup(this.mem.loadCstring(groupLabelPtr));
			},

			/**
			 * @param {number} computePassEncoderIdx
			 * @param {number} groupIndex
			 * @param {0|number} groupIdx
			 * @param {number|BigInt} dynamicOffsetCount
			 * @param {number} dynamicOffsetsPtr
			 */
			wgpuComputePassEncoderSetBindGroup: (computePassEncoderIdx, groupIndex, groupIdx, dynamicOffsetCount, dynamicOffsetsPtr) => {
				const computePassEncoder = this.computePassEncoders.get(computePassEncoderIdx);
				dynamicOffsetCount = this.unwrapBigInt(dynamicOffsetCount);

				let bindGroup;
				if (groupIdx != 0) {
					bindGroup = this.bindGroups.get(groupIdx);
				}

				const dynamicOffsets = [];
				for (let i = 0; i < dynamicOffsetCount; i += 1) {
					dynamicOffsets.push(this.mem.loadU32(dynamicOffsetsPtr));
					dynamicOffsetsPtr += 4;
				}

				computePassEncoder.setBindGroup(groupIndex, bindGroup, dynamicOffsets);
			},

			/**
			 * @param {number} computePassEncoderIdx
			 * @param {number} pipelineIdx
			 */
			wgpuComputePassEncoderSetPipeline: (computePassEncoderIdx, pipelineIdx) => {
				const computePassEncoder = this.computePassEncoders.get(computePassEncoderIdx);
				const pipeline = this.computePipelines.get(pipelineIdx);
				computePassEncoder.setPipeline(pipeline);
			},

			...this.computePassEncoders.interface(true),

			/* ---------------------- ComputePipeline ---------------------- */

			/**
			 * @param {number} computePipelineIdx
			 * @param {number} groupIndex
			 * @returns {number}
			 */
			wgpuComputePipelineGetBindGroupLayout: (computePipelineIdx, groupIndex) => {
				const computePipeline = this.computePipelines.get(computePipelineIdx);
				const bindGroupLayout = computePipeline.getBindGroupLayout(groupIndex);
				return this.bindGroupLayouts.create(bindGroupLayout);
			},

			...this.computePipelines.interface(true),

			/* ---------------------- Device ---------------------- */

			/**
			 * @param {number} deviceIdx
			 * @param {number} descriptorPtr
			 * @returns {number} The bind group.
			 */
			wgpuDeviceCreateBindGroup: (deviceIdx, descriptorPtr) => {
				const device = this.devices.get(deviceIdx);
				this.assert(descriptorPtr != 0);

				/** @type {GPUBindGroupDescriptor} */
				const descriptor = {
					label: this.mem.loadCstring(descriptorPtr + 4),
					layout: this.bindGroupLayouts.get(this.mem.loadPtr(descriptorPtr + 8)),
					entries: this.array(
						this.mem.loadUint(descriptorPtr + 8 + this.mem.intSize),
						this.mem.loadPtr(descriptorPtr + 8 + this.mem.intSize * 2),
						this.BindGroupEntry,
						40,
					),
				};
			
				const bindGroup = device.createBindGroup(descriptor);
				return this.bindGroups.create(bindGroup);
			},

			/**
			 * @param {number} deviceIdx
			 * @param {number} descriptorPtr
			 * @returns {number} The bind group layout.
			 */
			wgpuDeviceCreateBindGroupLayout: (deviceIdx, descriptorPtr) => {
				const device = this.devices.get(deviceIdx);
				this.assert(descriptorPtr != 0);

				/** @type {GPUBindGroupLayoutDescriptor} */
				const descriptor = {
					label: this.mem.loadCstring(descriptorPtr + 4),
					entries: this.array(
						this.mem.loadUint(descriptorPtr + 8),
						this.mem.loadPtr(descriptorPtr + 8 + this.mem.intSize),
						this.BindGroupLayoutEntry,
						80,
					),
				};

				const bindGroupLayout = device.createBindGroupLayout(descriptor);
				return this.bindGroupLayouts.create(bindGroupLayout);
			},

			/**
			 * @param {number} deviceIdx
			 * @param {number} descriptorPtr
			 * @returns {number} The buffer.
			 */
			wgpuDeviceCreateBuffer: (deviceIdx, descriptorPtr) => {
				const device = this.devices.get(deviceIdx);
				this.assert(descriptorPtr != 0);

				/** @type {GPUBufferDescriptor} */
				const descriptor = {
					label: this.mem.loadCstring(descriptorPtr + 4),
					usage: this.mem.loadU32(descriptorPtr + 8),
					size: this.mem.loadU64(descriptorPtr + 16),
					mappedAtCreation: this.mem.loadB32(descriptorPtr + 24),
				};

				const buffer = device.createBuffer(descriptor);
				return this.buffers.create({buffer: buffer, mapping: null});
			},

			/**
			 * @param {number} deviceIdx
			 * @param {0|number} descriptorPtr
			 * @returns {number} The command encoder.
			 */
			wgpuDeviceCreateCommandEncoder: (deviceIdx, descriptorPtr) => {
				const device = this.devices.get(deviceIdx);

				/** @type {GPUCommandEncoderDescriptor} */
				let descriptor;
				if (descriptor != 0) {
					descriptor = {
						label: this.mem.loadCstring(descriptorPtr + 4),
					};
				}

				const commandEncoder = device.createCommandEncoder(descriptor);
				return this.commandEncoders.create(commandEncoder);
			},

			/**
			 * @param {number} deviceIdx
			 * @param {number} descriptorPtr
			 * @returns {number} The compute pipeline.
			 */
			wgpuDeviceCreateComputePipeline: (deviceIdx, descriptorPtr) => {
				const device = this.devices.get(deviceIdx);
				this.assert(descriptorPtr != 0);
				const computePipeline = device.createComputePipeline(this.ComputePipelineDescriptor(descriptorPtr));
				return this.computePipelines.create(computePipeline);
			},

			/**
			 * @param {number} deviceIdx
			 * @param {number} descriptorPtr
			 * @param {number} callbackPtr
			 * @param {number} userdata
			 */
			wgpuDeviceCreateComputePipelineAsync: async (deviceIdx, descriptorPtr, callbackPtr, userdata) => {
				const device = this.devices.get(deviceIdx);
				const callback = this.mem.exports.__indirect_function_table.get(callbackPtr);
				this.assert(descriptorPtr != 0);

				let result;
				let resultIdx;
				try {
					const computePipeline = await device.createComputePipelineAsync(this.ComputePipelineDescriptor(descriptorPtr));
					resultIdx = this.computePipelines.create(computePipeline);
					result = 0; /* Success */
					// NOTE: don't callback here, any errors that happen later will then be caught by the catch here.
				} catch (e) {
					console.warn(e);
					result = 5; /* Unknown error */
				}

				callback(result, resultIdx, null, userdata);
			},

			/**
			 * @param {number} deviceIdx
			 * @param {number} descriptorPtr
			 * @returns {number} The pipeline layout.
			 */
			wgpuDeviceCreatePipelineLayout: (deviceIdx, descriptorPtr) => {
				const device = this.devices.get(deviceIdx);
				this.assert(descriptorPtr != 0);

				/** @type {GPUPipelineLayoutDescriptor} */
				const descriptor = {
					label: this.mem.loadCstring(descriptorPtr + 4),
					bindGroupLayouts: this.array(
						this.mem.loadUint(descriptorPtr + 8),
						this.mem.loadPtr(descriptorPtr + 8 + this.mem.intSize),
						(ptr) => this.bindGroupLayouts.get(this.mem.loadPtr(ptr)),
						4,
					),
				};

				const pipelineLayout = device.createPipelineLayout(descriptor);
				return this.pipelineLayouts.create(pipelineLayout);
			},

			/**
			 * @param {number} deviceIdx
			 * @param {number} descriptorPtr
			 * @returns {number} The query set.
			 */
			wgpuDeviceCreateQuerySet: (deviceIdx, descriptorPtr) => {
				const device = this.devices.get(deviceIdx);
				this.assert(descriptorPtr != 0);

				/** @type {GPUQuerySetDescriptor} */
				const descriptor = {
					label: this.mem.loadCstring(descriptorPtr + 4),
					type:  this.QueryType(descriptorPtr + 8),
					count: this.mem.loadU32(descriptorPtr + 12),
				};

				const querySet = device.createQuerySet(descriptor);
				return this.querySets.create(querySet);
			},

			/**
			 * @param {number} deviceIdx
			 * @param {number} descriptorPtr
			 * @returns {number} The query set.
			 */
			wgpuDeviceCreateRenderBundleEncoder: (deviceIdx, descriptorPtr) => {
				const device = this.devices.get(deviceIdx);
				this.assert(descriptorPtr != 0);

				/** @type {GPURenderBundleEncoderDescriptor} */
				const descriptor = {
					label: this.mem.loadCstring(descriptorPtr + 4),
					colorFormats: this.array(
						this.mem.loadUint(descriptorPtr + 8),
						this.mem.loadPtr(descriptorPtr + 8 + this.mem.intSize),
						this.TextureFormat,
						4,
					),
					depthStencilFormat: this.enumeration("TextureFormat", descriptorPtr + 8 + this.mem.intSize + 4),
					sampleCount:        this.mem.loadU32(descriptorPtr + 8 + this.mem.intSize + 8),
					depthReadOnly:      this.mem.loadB32(descriptorPtr + 8 + this.mem.intSize + 12),
					stencilReadOnly:    this.mem.loadB32(descriptorPtr + 8 + this.mem.intSize + 16),
				};

				const renderBundleEncoder = device.createRenderBundleEncoder(descriptor);
				return this.renderBundleEncoders.create(renderBundleEncoder);
			},

			/**
			 * @param {number} deviceIdx
			 * @param {number} descriptorPtr
			 * @returns {number} The render pipeline.
			 */
			wgpuDeviceCreateRenderPipeline: (deviceIdx, descriptorPtr) => {
				const device = this.devices.get(deviceIdx);
				this.assert(descriptorPtr != 0);

				const descriptor = this.RenderPipelineDescriptor(descriptorPtr);
				const renderPipeline = device.createRenderPipeline(descriptor);
				return this.renderPipelines.create(renderPipeline);
			},

			/**
			 * @param {number} deviceIdx
			 * @param {number} descriptorPtr
			 * @param {number} callbackPtr
			 * @param {number} userdata
			 */
			wgpuDeviceCreateRenderPipelineAsync: async (deviceIdx, descriptorPtr, callbackPtr, userdata) => {
				const device = this.devices.get(deviceIdx);
				const callback = this.mem.exports.__indirect_function_table.get(callbackPtr);
				this.assert(descriptorPtr != 0);

				let result;
				let resultIdx;
				try {
					const renderPipeline = await device.createRenderPipelineAsync(this.RenderPipelineDescriptor(descriptorPtr));
					resultIdx = this.renderPipelines.create(renderPipeline);
					result = 0; /* Success */
					// NOTE: don't callback here, any errors that happen later will then be caught by the catch here.
				} catch (e) {
					console.warn(e);
					result = 5; /* Unknown error */
				}

				callback(result, resultIdx, null, userdata);
			},

			/**
			 * @param {number} deviceIdx
			 * @param {0|number} descriptorPtr
			 * @returns {number} The sampler.
			 */
			wgpuDeviceCreateSampler: (deviceIdx, descriptorPtr) => {
				const device = this.devices.get(deviceIdx);

				/** @type {?GPUSamplerDescriptor} */
				let descriptor;
				if (descriptorPtr != 0) {
					descriptor = {
						label:         this.mem.loadCstring(descriptorPtr + 4),
						addressModeU:  this.enumeration("AddressMode", descriptorPtr + 8),
						addressModeV:  this.enumeration("AddressMode", descriptorPtr + 12),
						addressModeW:  this.enumeration("AddressMode", descriptorPtr + 16),
						magFilter:     this.enumeration("FilterMode", descriptorPtr + 20),
						minFilter:     this.enumeration("FilterMode", descriptorPtr + 24),
						mipMapFilter:  this.enumeration("MipmapFilterMode", descriptorPtr + 28),
						lodMinClamp:   this.mem.loadF32(descriptorPtr + 32),
						lodMaxClamp:   this.mem.loadF32(descriptorPtr + 36),
						compare:       this.enumeration("CompareFunction", descriptorPtr + 40),
						maxAnisotropy: this.mem.loadU16(descriptorPtr + 44),
					};
				}

				const sampler = device.createSampler(descriptor);
				return this.samplers.create(sampler);
			},

			/**
			 * @param {number} deviceIdx
			 * @param {number} descriptorPtr
			 * @returns {number} The shader module.
			 */
			wgpuDeviceCreateShaderModule: (deviceIdx, descriptorPtr) => {
				const device = this.devices.get(deviceIdx);
				this.assert(descriptorPtr != 0);

				const nextInChain = this.mem.loadPtr(descriptorPtr);
				const nextInChainType = this.mem.loadI32(nextInChain + 4);

				// ShaderModuleWGSLDescriptor = 0x00000006,
				if (nextInChainType != 6) {
					throw new TypeError(`Descriptor type should be 'ShaderModuleWGSLDescriptor', got ${nextInChainType}`);
				}

				/** @type {GPUShaderModuleDescriptor} */
				const descriptor = {
					label: this.mem.loadCstring(descriptorPtr + 4),
					code: this.mem.loadCstring(nextInChain + 8),
					compilationHints: this.array(
						this.mem.loadUint(descriptorPtr + 8),
						this.mem.loadPtr(descriptorPtr + 8 + this.mem.intSize),
						this.ShaderModuleCompilationHint,
						12,
					),
				};

				const shaderModule = device.createShaderModule(descriptor);
				return this.shaderModules.create(shaderModule);
			},

			/**
			 * @param {number} deviceIdx
			 * @param {number} descriptorPtr
			 * @returns {number} The texture.
			 */
			wgpuDeviceCreateTexture: (deviceIdx, descriptorPtr) => {
				const device = this.devices.get(deviceIdx);
				this.assert(descriptorPtr != 0);

				/** @type {GPUTextureDescriptor} */
				const descriptor = {
					label: this.mem.loadCstring(descriptorPtr + 4),
					usage: this.mem.loadU32(descriptorPtr + 8),
					dimension: this.enumeration("TextureDimension", descriptorPtr + 12),
					size: this.Extent3D(descriptorPtr + 16),
					format: this.enumeration("TextureFormat", descriptorPtr + 28),
					mipLevelCount: this.mem.loadU32(descriptorPtr + 32),
					sampleCount: this.mem.loadU32(descriptorPtr + 36),
					viewFormats: this.array(
						this.mem.loadUint(descriptorPtr + 40),
						this.mem.loadPtr(descriptorPtr + 40 + this.mem.intSize),
						(ptr) => this.enumeration("TextureFormat", ptr),
						4,
					),
				};

				const texture = device.createTexture(descriptor);
				return this.textures.create(texture);
			},

			/**
			 * @param {number} deviceIdx
			 */
			wgpuDeviceDestroy: (deviceIdx) => {
				const device = this.devices.get(deviceIdx);
				device.destroy();
			},

			/**
			 * @param {number} deviceIdx
			 * @param {number} featuresPtr
			 * @returns {number|BigInt}
			 */
			wgpuDeviceEnumerateFeatures: (deviceIdx, featuresPtr) => {
				const device = this.devices.get(deviceIdx);
				return this.genericEnumerateFeatures(device.features, featuresPtr);
			},

			/**
			 * @param {number} deviceIdx
			 * @param {number} limitsPtr
			 * @returns {boolean}
			 */
			wgpuDeviceGetLimits: (deviceIdx, limitsPtr) => {
				const device = this.devices.get(deviceIdx);
				return this.genericGetLimits(device.limits, limitsPtr);
			},

			/**
			 * @param {number} deviceIdx
			 * @returns {number}
			 */
			wgpuDeviceGetQueue: (deviceIdx) => {
				const device = this.devices.get(deviceIdx);
				return this.queues.create(device.queue);
			},

			/**
			 * @param {number} deviceIdx
			 * @param {number} featureInt
			 * @returns {boolean}
			 */
			wgpuDeviceHasFeature: (deviceIdx, featureInt) => {
				const device = this.devices.get(deviceIdx);
				return device.features.has(this.enums.FeatureName[featureInt]);
			},

			/**
			 * @param {number} deviceIdx
			 * @param {number} callbackPtr
			 * @param {number} userdata
			 */
			wgpuDevicePopErrorScope: async (deviceIdx, callbackPtr, userdata) => {
				const device = this.devices.get(deviceIdx);
				const callback = this.mem.exports.__indirect_function_table.get(callbackPtr);
				const error = await device.popErrorScope();
				if (!error) {
					callback(0, null, userdata);
					return;
				}
				console.warn(error);
				let status = 4;
				if (error instanceof GPUValidationError) {
					status = 1;
				} else if (error instanceof GPUOutOfMemoryError) {
					status = 2;
				} else if (error instanceof GPUInternalError) {
					status = 3;
				}
				callback(status, null, userdata);
			},

			/**
			 * @param {number} deviceIdx
			 * @param {number} filterInt 
			 */
			wgpuDevicePushErrorScope: (deviceIdx, filterInt) => {
				const device = this.devices.get(deviceIdx);
				device.pushErrorScope(this.enums.ErrorFilter[filterInt]);
			},

			/**
			 * @param {number} deviceIdx
			 * @param {number} callbackPtr
			 * @param {number} userdata
			 */
			wgpuDeviceSetUncapturedErrorCallback: (deviceIdx, callbackPtr, userdata) => {
				const device = this.devices.get(deviceIdx);
				const callback = this.mem.exports.__indirect_function_table.get(callbackPtr);

				device.onuncapturederror = (ev) => {
					console.warn(ev.error);
					let status = 4;
					if (error instanceof GPUValidationError) {
						status = 1;
					} else if (error instanceof GPUOutOfMemoryError) {
						status = 2;
					} else if (error instanceof GPUInternalError) {
						status = 3;
					}
					callback(status, null, userdata);
				};
			},

			...this.devices.interface(true),

			/* ---------------------- Instance ---------------------- */

			/**
			 * @param {number} instanceIdx
			 * @param {number} descriptorPtr
			 */
			wgpuInstanceCreateSurface: (instanceIdx, descriptorPtr) => {
				this.assert(instanceIdx > 0);
				this.assert(descriptorPtr != 0);

				const nextInChain = this.mem.loadPtr(descriptorPtr);
				const nextInChainType = this.mem.loadI32(nextInChain + 4);

    			// SurfaceDescriptorFromCanvasHTMLSelector = 0x00000004,
				if (nextInChainType != 4) {
					throw new TypeError(`Descriptor type should be 'SurfaceDescriptorFromCanvasHTMLSelector', got ${nextInChainType}`);
				}

				const selector = this.mem.loadCstring(nextInChain + 8);
				const surface = document.querySelector(selector);
				if (!surface) {
					throw new Error(`Selector '${selector}' did not match any element`);
				}
				if (!(surface instanceof HTMLCanvasElement)) {
					throw new Error('Selector matches an element that is not a canvas');
				}

				return this.surfaces.create(surface);
			},

			/**
			 * @param {number} instanceIdx
			 * @param {number} featureInt
			 * @returns {boolean}
			 */
			wgpuInstanceHasWGSLLanguageFeature: (instanceIdx, featureInt) => {
				return navigator.gpu.wgslLanguageFeatures.has(this.enums.WGSLFeatureName[featureInt]);
			},

			/**
			 * @param {number} instanceIdx
			 */
			wgpuInstanceProcessEvents: (instanceIdx) => {
				console.warn("unimplemented: wgpuInstanceProcessEvents");
			},

			/**
			 * @param {number} instanceIdx
			 * @param {0|number} optionsPtr
			 * @param {number} callbackPtr
			 * @param {number} userdata
			 */
			wgpuInstanceRequestAdapter: async (instanceIdx, optionsPtr, callbackPtr, userdata) => {
				this.assert(instanceIdx > 0);
				const callback = this.mem.exports.__indirect_function_table.get(callbackPtr);

				/** @type {GPURequestAdapterOptions} */
				let options;
				if (optionsPtr != 0) {
					options = {
						powerPreference: this.enumeration("PowerPreference", optionsPtr + 8),
						forceFallbackAdapter: this.mem.loadB32(optionsPtr + 16),
					};
				}

				let adapterIdx;
				try {
					const adapter = await navigator.gpu.requestAdapter(options);
					adapterIdx = this.adapters.create(adapter);
					// NOTE: don't callback here, any errors that happen later will then be caught by the catch here.
				} catch(e) {
					console.warn(e);
					callback(2, null, null, userdata);
				}

				callback(0, adapterIdx, null, userdata);
			},

			...this.instances.interface(false),

			/* ---------------------- PipelineLayout ---------------------- */

			...this.pipelineLayouts.interface(true),

			/* ---------------------- QuerySet ---------------------- */

			/**
			 * @param {number} querySetIdx
			 */
			wgpuQuerySetDestroy: (querySetIdx) => {
				const querySet = this.querySets.get(querySetIdx);
				querySet.destroy();
			},

			/**
			 * @param {number} querySetIdx
			 * @returns {number}
			 */
			wgpuQuerySetGetCount: (querySetIdx) => {
				const querySet = this.querySets.get(querySetIdx);
				return querySet.count;
			},

			/**
			 * @param {number} querySetIdx
			 * @returns {number}
			 */
			wgpuQuerySetGetType: (querySetIdx) => {
				const querySet = this.querySets.get(querySetIdx);
				return this.enums.QueryType.indexOf(querySet.type);
			},

			...this.querySets.interface(true),

			/* ---------------------- Queue ---------------------- */

			/**
			 * @param {number} queueIdx
			 * @param {number} callbackPtr
			 * @param {number} userdata
			 */
			wgpuQueueOnSubmittedWorkDone: async (queueIdx, callbackPtr, userdata) => {
				const queue = this.queues.get(queueIdx);
				const callback = this.mem.exports.__indirect_function_table.get(callbackPtr);
				let result;
				try {
					await queue.onSubmittedWorkDone();
					result = 0;
				} catch(e) {
					console.warn(e);
					result = 1;
				}
				callback(result, userdata);
			},

			/**
			 * @param {number} queueIdx
			 * @param {BigInt|number} commandCount
			 * @param {number} commandsPtr
			 */
			wgpuQueueSubmit: (queueIdx, commandCount, commandsPtr) => {
				const queue = this.queues.get(queueIdx);
				const commands = this.array(
					this.unwrapBigInt(commandCount),
					commandsPtr,
					(ptr) => this.commandBuffers.get(this.mem.loadPtr(ptr)),
					4,
				);
				queue.submit(commands);
			},

			/**
			 * @param {number} queueIdx
			 * @param {number} bufferIdx 
			 * @param {BigInt} bufferOffset
			 * @param {number} dataPtr
			 * @param {number|BigInt} size
			 */
			wgpuQueueWriteBuffer: (queueIdx, bufferIdx, bufferOffset, dataPtr, size) => {
				const queue = this.queues.get(queueIdx);
				const buffer = this.buffers.get(bufferIdx);
				bufferOffset = this.unwrapBigInt(bufferOffset);
				size = this.unwrapBigInt(size);
				queue.writeBuffer(buffer.buffer, bufferOffset, this.mem.loadBytes(dataPtr, size), 0, size);
			},

			/**
			 * @param {number} queueIdx
			 * @param {number} destinationPtr
			 * @param {number} dataPtr
			 * @param {number|BigInt} dataSize
			 * @param {number} dataLayoutPtr
			 * @param {number} writeSizePtr
			 */
			wgpuQueueWriteTexture: (queueIdx, destinationPtr, dataPtr, dataSize, dataLayoutPtr, writeSizePtr) => {
				const queue = this.queues.get(queueIdx);
				const destination = this.ImageCopyTexture(destinationPtr);
				dataSize = this.unwrapBigInt(dataSize);
				const dataLayout = this.TextureDataLayout(dataLayoutPtr);
				const writeSize = this.Extent3D(writeSizePtr);
				queue.writeTexture(destination, this.mem.loadBytes(dataPtr, dataSize), dataLayout, writeSize);
			},

			...this.queues.interface(true),

			/* ---------------------- RenderBundle ---------------------- */

			...this.renderBundles.interface(true),

			/* ---------------------- RenderBundleEncoder ---------------------- */

			/**
			 * @param {number} renderBundleEncoderIdx
			 * @param {number} vertexCount
			 * @param {number} instanceCount
			 * @param {number} firstVertex
			 * @param {number} firstInstance
			 */
			wgpuRenderBundleEncoderDraw: (renderBundleEncoderIdx, vertexCount, instanceCount, firstVertex, firstInstance) => {
				const renderBundleEncoder = this.renderBundleEncoders.get(renderBundleEncoderIdx);
				renderBundleEncoder.draw(vertexCount, instanceCount, firstVertex, firstInstance);
			},

			/**
			 * @param {number} renderBundleEncoderIdx
			 * @param {number} indexCount
			 * @param {number} instanceCount
			 * @param {number} firstIndex
			 * @param {number} baseVertex
			 * @param {number} firstInstance
			 */
			wgpuRenderBundleEncoderDrawIndexed: (renderBundleEncoderIdx, indexCount, instanceCount, firstIndex, baseVertex, firstInstance) => {
				const renderBundleEncoder = this.renderBundleEncoders.get(renderBundleEncoderIdx);
				renderBundleEncoder.drawIndexed(indexCount, instanceCount, firstIndex, baseVertex, firstInstance);
			},

			/**
			 * @param {number} renderBundleEncoderIdx
			 * @param {number} indirectBufferIdx
			 * @param {BigInt} indirectOffset
			 */
			wgpuRenderBundleEncoderDrawIndexedIndirect: (renderBundleEncoderIdx, indirectBufferIdx, indirectOffset) => {
				const renderBundleEncoder = this.renderBundleEncoders.get(renderBundleEncoderIdx);
				indirectOffset = this.unwrapBigInt(indirectOffset);
				const buffer = this.buffers.get(indirectBufferIdx);
				renderBundleEncoder.drawIndexedIndirect(buffer.buffer, indirectOffset);
			},

			/**
			 * @param {number} renderBundleEncoderIdx
			 * @param {number} indirectBufferIdx
			 * @param {BigInt} indirectOffset
			 */
			wgpuRenderBundleEncoderDrawIndirect: (renderBundleEncoderIdx, indirectBufferIdx, indirectOffset) => {
				const renderBundleEncoder = this.renderBundleEncoders.get(renderBundleEncoderIdx);
				indirectOffset = this.unwrapBigInt(indirectOffset);
				const buffer = this.buffers.get(indirectBufferIdx);
				renderBundleEncoder.drawIndirect(buffer.buffer, indirectOffset);
			},

			/**
			 * @param {number} renderBundleEncoderIdx
			 * @param {0|number} descriptorPtr
			 * @returns {number}
			 */
			wgpuRenderBundleEncoderFinish: (renderBundleEncoderIdx, descriptorPtr) => {
				const renderBundleEncoder = this.renderBundleEncoders.get(renderBundleEncoderIdx);

				/** @type {?GPURenderBundleDescriptor} */
				let descriptor;
				if (descriptorPtr != 0) {
					descriptor = {
						label: this.mem.loadCstring(descriptorPtr + 4),
					};
				}

				const renderBundle = renderBundleEncoder.finish(descriptor);
				return this.renderBundles.create(renderBundle);
			},

			/**
			 * @param {number} renderBundleEncoderIdx
			 * @param {number} markerLabelPtr
			 */
			wgpuRenderBundleEncoderInsertDebugMarker: (renderBundleEncoderIdx, markerLabelPtr) => {
				const renderBundleEncoder = this.renderBundleEncoders.get(renderBundleEncoderIdx);
				this.assert(markerLabelPtr != 0);
				const markerLabel = this.mem.loadCstring(markerLabelPtr);
				renderBundleEncoder.insertDebugMarker(markerLabel);
			},

			/**
			 * @param {number} renderBundleEncoderIdx
			 */
			wgpuRenderBundleEncoderPopDebugGroup: (renderBundleEncoderIdx) => {
				const renderBundleEncoder = this.renderBundleEncoders.get(renderBundleEncoderIdx);
				renderBundleEncoder.popDebugGroup();
			},

			/**
			 * @param {number} renderBundleEncoderIdx
			 * @param {number} groupLabelPtr
			 */
			wgpuRenderBundleEncoderPushDebugGroup: (renderBundleEncoderIdx, groupLabelPtr) => {
				const renderBundleEncoder = this.renderBundleEncoders.get(renderBundleEncoderIdx);
				this.assert(groupLabelPtr!= 0);
				const groupLabel = this.mem.loadCstring(groupLabelPtr);
				renderBundleEncoder.pushDebugGroup(groupLabel);
			},

			/**
			 * @param {number} renderBundleEncoderIdx
			 * @param {number} groupIndex
			 * @param {0|number} groupIdx
			 * @param {number|BigInt} dynamicOffsetCount
			 * @param {number} dynamicOffsetsPtr
			 */
			wgpuRenderBundleEncoderSetBindGroup: (renderBundleEncoderIdx, groupIndex, groupIdx, dynamicOffsetCount, dynamicOffsetsPtr) => {
				const renderBundleEncoder = this.renderBundleEncoders.get(renderBundleEncoderIdx);

				let group;
				if (groupIdx > 0) {
					group = this.bindGroups.get(groupIdx);
				}

				dynamicOffsetCount = this.unwrapBigInt(dynamicOffsetCount);
				const dynamicOffsets = this.array(dynamicOffsetCount, dynamicOffsetsPtr, this.mem.loadU32, 4);	

				renderBundleEncoder.setBindGroup(groupIndex, group, dynamicOffsets);
			},

			/**
			 * @param {number} renderBundleEncoderIdx
			 * @param {number} bufferIdx
			 * @param {number} formatInt
			 * @param {BigInt} offset
			 * @param {BigInt} size
			 */
			wgpuRenderBundleEncoderSetIndexBuffer: (renderBundleEncoderIdx, bufferIdx, formatInt, offset, size) => {
				const renderBundleEncoder = this.renderBundleEncoders.get(renderBundleEncoderIdx);
				const buffer = this.buffers.get(bufferIdx);
				const format = this.enums.IndexFormat[formatInt];
				offset = this.unwrapBigInt(offset);
				size = this.unwrapBigInt(size);
				renderBundleEncoder.setIndexBuffer(buffer.buffer, format, offset, size);
			},

			/**
			 * @param {number} renderBundleEncoderIdx
			 * @param {number} pipelineIdx
			 */
			wgpuRenderBundleEncoderSetPipeline: (renderBundleEncoderIdx, pipelineIdx) => {
				const renderBundleEncoder = this.renderBundleEncoders.get(renderBundleEncoderIdx);
				const pipeline = this.renderPipelines.get(pipelineIdx);
				renderBundleEncoder.setPipeline(pipeline);
			},

			/**
			 * @param {number} renderBundleEncoderIdx
			 * @param {number} slot
			 * @param {0|number} bufferIdx
			 * @param {BigInt} offset
			 * @param {BigInt} size
			 */
			wgpuRenderBundleEncoderSetVertexBuffer: (renderBundleEncoderIdx, slot, bufferIdx, offset, size) => {
				const renderBundleEncoder = this.renderBundleEncoders.get(renderBundleEncoderIdx);

				let buffer;
				if (bufferIdx > 0) {
					buffer = this.buffers.get(bufferIdx).buffer;
				}

				offset = this.unwrapBigInt(offset);
				size = this.unwrapBigInt(size);
				renderBundleEncoder.setVertexBuffer(slot, buffer, offset, size);
			},

			...this.renderBundleEncoders.interface(true),

			/* ---------------------- RenderPassEncoder ---------------------- */

			/**
			 * @param {number} renderPassEncoderIdx
			 * @param {number} queryIndex
			 */
			wgpuRenderPassEncoderBeginOcclusionQuery: (renderPassEncoderIdx, queryIndex) => {
				const renderPassEncoder = this.renderPassEncoders.get(renderPassEncoderIdx);
				renderPassEncoder.beginOcclusionQuery(queryIndex);
			},

			/**
			 * @param {number} renderPassEncoderIdx
			 * @param {number} vertexCount
			 * @param {number} instanceCount
			 * @param {number} firstVertex
			 * @param {number} firstInstance
			 */
			wgpuRenderPassEncoderDraw: (renderPassEncoderIdx, vertexCount, instanceCount, firstVertex, firstInstance) => {
				const renderPassEncoder = this.renderPassEncoders.get(renderPassEncoderIdx);
				renderPassEncoder.draw(vertexCount, instanceCount, firstVertex, firstInstance);
			},

			/**
			 * @param {number} renderPassEncoderIdx
			 * @param {number} indexCount
			 * @param {number} instanceCount
			 * @param {number} firstIndex
			 * @param {number} baseVertex
			 * @param {number} firstInstance
			 */
			wgpuRenderPassEncoderDrawIndexed: (renderPassEncoderIdx, indexCount, instanceCount, firstIndex, baseVertex, firstInstance) => {
				const renderPassEncoder = this.renderPassEncoders.get(renderPassEncoderIdx);
				renderPassEncoder.drawIndexed(indexCount, instanceCount, firstIndex, baseVertex, firstInstance);
			},

			/**
			 * @param {number} renderPassEncoderIdx
			 * @param {number} indirectBufferIdx
			 * @param {BigInt} indirectOffset
			 */
			wgpuRenderPassEncoderDrawIndexedIndirect: (renderPassEncoderIdx, indirectBufferIdx, indirectOffset) => {
				const renderPassEncoder = this.renderPassEncoders.get(renderPassEncoderIdx);
				const buffer = this.buffers.get(indirectBufferIdx);
				indirectOffset = this.unwrapBigInt(indirectOffset);
				renderPassEncoder.drawIndexedIndirect(buffer.buffer, indirectOffset);
			},

			/**
			 * @param {number} renderPassEncoderIdx
			 * @param {number} indirectBufferIdx
			 * @param {BigInt} indirectOffset
			 */
			wgpuRenderPassEncoderDrawIndirect: (renderPassEncoderIdx, indirectBufferIdx, indirectOffset) => {
				const renderPassEncoder = this.renderPassEncoders.get(renderPassEncoderIdx);
				const buffer = this.buffers.get(indirectBufferIdx);
				indirectOffset = this.unwrapBigInt(indirectOffset);
				renderPassEncoder.drawIndirect(buffer.buffer, indirectOffset);
			},

			/**
			 * @param {number} renderPassEncoderIdx
			 */
			wgpuRenderPassEncoderEnd: (renderPassEncoderIdx) => {
				const renderPassEncoder = this.renderPassEncoders.get(renderPassEncoderIdx);
				renderPassEncoder.end();
			},

			/**
			 * @param {number} renderPassEncoderIdx
			 */
			wgpuRenderPassEncoderEndOcclusionQuery: (renderPassEncoderIdx) => {
				const renderPassEncoder = this.renderPassEncoders.get(renderPassEncoderIdx);
				renderPassEncoder.endOcclusionQuery();
			},

			/**
			 * @param {number} renderPassEncoderIdx
			 * @param {number|BigInt} bundleCount
			 * @param {number} bundlesPtr
			 */
			wgpuRenderPassEncoderExecuteBundles: (renderPassEncoderIdx, bundleCount, bundlesPtr) => {
				const renderPassEncoder = this.renderPassEncoders.get(renderPassEncoderIdx);
				bundleCount = this.unwrapBigInt(bundleCount);
				const bundles = this.array(
					bundleCount,
					bundlesPtr,
					(ptr) => this.renderBundles.get(this.mem.loadPtr(ptr)),
					4,
				);
				renderPassEncoder.executeBundles(bundles);
			},

			/**
			 * @param {number} renderPassEncoderIdx
			 * @param {number} markerLabelPtr
			 */
			wgpuRenderPassEncoderInsertDebugMarker: (renderPassEncoderIdx, markerLabelPtr) => {
				const renderPassEncoder = this.renderPassEncoders.get(renderPassEncoderIdx);
				const markerLabel = this.mem.loadCstring(markerLabelPtr);
				renderPassEncoder.insertDebugMarker(markerLabel);
			},

			/**
			 * @param {number} renderPassEncoderIdx
			 */
			wgpuRenderPassEncoderPopDebugGroup: (renderPassEncoderIdx) => {
				const renderPassEncoder = this.renderPassEncoders.get(renderPassEncoderIdx);
				renderPassEncoder.popDebugGroup();
			},

			/**
			 * @param {number} renderPassEncoderIdx
			 * @param {number} groupLabelPtr
			 */
			wgpuRenderPassEncoderPushDebugGroup: (renderPassEncoderIdx, groupLabelPtr) => {
				const renderPassEncoder = this.renderPassEncoders.get(renderPassEncoderIdx);
				const groupLabel = this.mem.loadCstring(groupLabelPtr);
				renderPassEncoder.pushDebugGroup(groupLabel);
			},

			/**
			 * @param {number} renderPassEncoderIdx
			 * @param {number} groupIndex
			 * @param {0|number} groupIdx
			 * @param {number|BigInt} dynamicOffsetCount
			 * @param {number} dynamicOffsetsPtr
			 */
			wgpuRenderPassEncoderSetBindGroup: (renderPassEncoderIdx, groupIndex, groupIdx, dynamicOffsetCount, dynamicOffsetsPtr) => {
				const renderPassEncoder = this.renderPassEncoders.get(renderPassEncoderIdx);

				let group;
				if (groupIdx > 0) {
					group = this.bindGroups.get(groupIdx);
				}

				dynamicOffsetCount = this.unwrapBigInt(dynamicOffsetCount);
				const dynamicOffsets = this.array(dynamicOffsetCount, dynamicOffsetsPtr, this.mem.loadU32, 4);	

				renderPassEncoder.setBindGroup(groupIndex, group, dynamicOffsets);
			},

			/**
			 * @param {number} renderPassEncoderIdx
			 * @param {number} bufferIdx
			 * @param {number} formatInt
			 * @param {BigInt} offset
			 * @param {BigInt} size
			 */
			wgpuRenderPassEncoderSetIndexBuffer: (renderPassEncoderIdx, bufferIdx, formatInt, offset, size) => {
				const renderPassEncoder = this.renderPassEncoders.get(renderPassEncoderIdx);
				const buffer = this.buffers.get(bufferIdx);
				const format = this.enums.IndexFormat[formatInt];
				offset = this.unwrapBigInt(offset);
				size = this.unwrapBigInt(size);
				renderPassEncoder.setIndexBuffer(buffer.buffer, format, offset, size);
			},

			/**
			 * @param {number} renderPassEncoderIdx
			 * @param {number} pipelineIdx
			 */
			wgpuRenderPassEncoderSetPipeline: (renderPassEncoderIdx, pipelineIdx) => {
				const renderPassEncoder = this.renderPassEncoders.get(renderPassEncoderIdx);
				const pipeline = this.renderPipelines.get(pipelineIdx);
				renderPassEncoder.setPipeline(pipeline);
			},

			/**
			 * @param {number} renderPassEncoderIdx
			 * @param {number} x
			 * @param {number} y
			 * @param {number} width
			 * @param {number} height
			 */
			wgpuRenderPassEncoderSetScissorRect: (renderPassEncoderIdx, x, y, width, height) => {
				const renderPassEncoder = this.renderPassEncoders.get(renderPassEncoderIdx);
				renderPassEncoder.setScissorRect(x, y, width, height);
			},

			/**
			 * @param {number} renderPassEncoderIdx
			 * @param {number} reference
			 */
			wgpuRenderPassEncoderSetStencilReference: (renderPassEncoderIdx, reference) => {
				const renderPassEncoder = this.renderPassEncoders.get(renderPassEncoderIdx);
				renderPassEncoder.setStencilReference(reference);
			},

			/**
			 * @param {number} renderPassEncoderIdx
			 * @param {number} slot
			 * @param {0|number} bufferIdx
			 * @param {BigInt} offset
			 * @param {BigInt} size
			 */
			wgpuRenderPassEncoderSetVertexBuffer: (renderPassEncoderIdx, slot, bufferIdx, offset, size) => {
				const renderPassEncoder = this.renderPassEncoders.get(renderPassEncoderIdx);

				let buffer;
				if (bufferIdx > 0) {
					buffer = this.buffers.get(bufferIdx).buffer;
				}

				offset = this.unwrapBigInt(offset);
				size = this.unwrapBigInt(size);
				renderPassEncoder.setVertexBuffer(slot, buffer, offset, size);
			},

			/**
			 * @param {number} renderPassEncoderIdx
			 * @param {number} x
			 * @param {number} y
			 * @param {number} width
			 * @param {number} height
			 * @param {number} minDepth
			 * @param {number} maxDepth
			 */
			wgpuRenderPassEncoderSetViewport: (renderPassEncoderIdx, x, y, width, height, minDepth, maxDepth) => {
				const renderPassEncoder = this.renderPassEncoders.get(renderPassEncoderIdx);
				renderPassEncoder.setViewport(x, y, width, height, minDepth, maxDepth);
			},

			...this.renderPassEncoders.interface(true),

			/* ---------------------- RenderPipeline ---------------------- */

			/**
			 * @param {number} renderPipelineIdx
			 * @param {number} groupIndex
			 * @returns {number}
			 */
			wgpuRenderPipelineGetBindGroupLayout: (renderPipelineIdx, groupIndex) => {
				const renderPipeline = this.renderPipelines.get(renderPipelineIdx);
				const bindGroupLayout = renderPipeline.getBindGroupLayout(groupIndex);
				return this.bindGroupLayouts.create(bindGroupLayout);
			},

			...this.renderPipelines.interface(true),

			/* ---------------------- Sampler ---------------------- */

			...this.samplers.interface(true),

			/* ---------------------- ShaderModule ---------------------- */

			/**
			 * @param {number} shaderModuleIdx
			 * @param {number} callbackPtr
			 * @param {number} userdata
			 */
			wgpuShaderModuleGetCompilationInfo: async (shaderModuleIdx, callbackPtr, userdata) => {
				const shaderModule = this.shaderModules.get(shaderModuleIdx);
				const callback = this.mem.exports.__indirect_function_table.get(callbackPtr);

				let status = 0;
				let retAddr = 0;

				const ptrsToFree = [];

				try {
					const compilationInfo = await shaderModule.getCompilationInfo();

					const size = compilationInfo.messages.length * 72;
					const addr = this.mem.exports.wgpu_alloc(size);
					ptrsToFree.push(addr);
					compilationInfo.messages.forEach((message, i) => {
						const messageLength = new TextEncoder().encode(message.message).length;
						const messageAddr = this.mem.exports.wgpu_alloc(messageLength);
						ptrsToFree.push(messageAddr);
						this.mem.storeString(messageAddr, message.message);
						this.mem.storeI32(addr + (i * size) + 4);

						this.mem.storeI32(addr + (i * size) + 8, this.enums.CompilationMessageType.indexOf(message.type));

						this.mem.storeU64(addr + (i * size) + 16, message.lineNum);
						this.mem.storeU64(addr + (i * size) + 24, message.linePos);
						this.mem.storeU64(addr + (i * size) + 32, message.offset);
						this.mem.storeU64(addr + (i * size) + 40, message.length);

						// TODO: UTF16 units.
						this.mem.storeU64(addr + (i * size) + 48, message.linePos);
						this.mem.storeU64(addr + (i * size) + 56, message.offset);
						this.mem.storeU64(addr + (i * size) + 64, message.length);
					});

					retAddr = this.mem.exports.wgpu_alloc(3*this.mem.intSize);
					ptrsToFree.push(retAddr);
					this.mem.storeUint(retAddr + this.mem.intSize, compilationInfo.messages.length);
					this.mem.storeI32(retAddr + this.mem.intSize*2, addr);
				} catch (e) {
					console.warn(e);
					status = 1;
				}

				callback(status, retAddr, userdata);

				ptrsToFree.forEach(ptr => this.mem.exports.wgpu_free(ptr));
			},

			...this.shaderModules.interface(true),

			/* ---------------------- Surface ---------------------- */

			/**
			 * @param {number} surfaceIdx
			 * @param {number} configPtr
			 */
			wgpuSurfaceConfigure: (surfaceIdx, configPtr) => {
				const surface = this.surfaces.get(surfaceIdx);
				const context = surface.getContext('webgpu');

				const widthOff = 16 + this.mem.intSize + 8;
				surface.width  = this.mem.loadU32(configPtr + widthOff);
				surface.height = this.mem.loadU32(configPtr + widthOff + 4);

				/** @type {GPUCanvasConfiguration} */
				const config = {
					device: this.devices.get(this.mem.loadPtr(configPtr + 4)),
					format: this.enumeration("TextureFormat", configPtr + 8),
					usage: this.mem.loadU32(configPtr + 12),
					viewFormats: this.array(
						this.mem.loadUint(configPtr + 16),
						this.mem.loadPtr(configPtr + 16 + this.mem.intSize),
						(ptr) => this.enumeration("TextureFormat", ptr),
						4,
					),
					alphaMode: this.enumeration("CompositeAlphaMode", configPtr + widthOff - 4),
					// // NOTE: present mode seems unused.
					presentMode: this.enumeration("PresentMode", configPtr + widthOff + 4),
				};

				context.configure(config);
			},

			/**
			 * @param {number} surfaceIdx
			 * @param {number} adapterIdx
			 * @param {number} capabilitiesPtr
			 */
			wgpuSurfaceGetCapabilities: (surfaceIdx, adapterIdx, capabilitiesPtr) => {
				const formatStr = navigator.gpu.getPreferredCanvasFormat();
				const format = this.enums.TextureFormat.indexOf(formatStr);

				this.mem.storeUint(capabilitiesPtr + this.mem.intSize, 1);
				const formatAddr = this.mem.exports.wgpu_alloc(4);
				this.mem.storeI32(formatAddr, format);
				this.mem.storeI32(capabilitiesPtr + this.mem.intSize*2, formatAddr);

				// NOTE: present modes don't seem to actually do anything in JS, we can just give back a default FIFO though.
				this.mem.storeUint(capabilitiesPtr + this.mem.intSize*3, 1);
				const presentModesAddr = this.mem.exports.wgpu_alloc(4);
				this.mem.storeI32(presentModesAddr, 0);
				this.mem.storeI32(capabilitiesPtr + this.mem.intSize*4, presentModesAddr);

				// Browser seems to support opaque (1) and premultiplied (2).
				this.mem.storeUint(capabilitiesPtr + this.mem.intSize*5, 2);
				const alphaModesAddr = this.mem.exports.wgpu_alloc(8);
				this.mem.storeI32(alphaModesAddr + 0, 1); // Opaque.
				this.mem.storeI32(alphaModesAddr + 4, 2); // premultiplied.
				this.mem.storeI32(capabilitiesPtr + this.mem.intSize*6, alphaModesAddr);
			},

			/**
			 * @param {number} surfaceIdx
			 * @param {number} texturePtr
			 */
			wgpuSurfaceGetCurrentTexture: (surfaceIdx, texturePtr) => {
				const surface = this.surfaces.get(surfaceIdx);
				const context = surface.getContext('webgpu');
				const texture = context.getCurrentTexture();

				const textureIdx = this.textures.create(texture);
				this.mem.storeI32(texturePtr, textureIdx);

				// TODO: determine suboptimal and/or status.
			},

			/**
			 * @param {number} surfaceIdx
			 * @param {number} texturePtr
			 * @returns {number}
			 */
			wgpuSurfaceGetPreferredFormat: (surfaceIdx, adapterIdx) => {
				const formatStr = navigator.gpu.getPreferredCanvasFormat();
				const format = this.enums.TextureFormat.indexOf(formatStr);
				return format;
			},

			/**
			 * @param {number} surfaceIdx
			 */
			wgpuSurfacePresent: (surfaceIdx) => {
				// NOTE: Not really anything to do here.
			},

			/**
			 * @param {number} surfaceIdx
			 */
			wgpuSurfaceUnconfigure: (surfaceIdx) => {
				const surface = this.surfaces.get(surfaceIdx);
				surface.getContext('webgpu').unconfigure();
			},

			...this.surfaces.interface(true),

			/* ---------------------- SurfaceCapabilities ---------------------- */

			/**
			 * @param {number} surfaceCapabilitiesPtr
			 */
			wgpuSurfaceCapabilitiesFreeMembers: (surfaceCapabilitiesPtr) => {
				const formatsAddr = this.mem.loadI32(surfaceCapabilitiesPtr + this.mem.intSize*2);
				this.mem.exports.wgpu_free(formatsAddr);

				const presentModesAddr = this.mem.loadI32(surfaceCapabilitiesPtr + this.mem.intSize*4);
				this.mem.exports.wgpu_free(presentModesAddr);

				const alphaModesAddr = this.mem.loadI32(surfaceCapabilitiesPtr + this.mem.intSize*6);
				this.mem.exports.wgpu_free(alphaModesAddr);
			},

			/* ---------------------- Texture ---------------------- */
			
			/**
			 * @param {number} textureIdx
			 * @param {0|number} descriptorPtr
			 * @returns {number}
			 */
			wgpuTextureCreateView: (textureIdx, descriptorPtr) => {
				const texture = this.textures.get(textureIdx);

				/** @type {?GPUTextureViewDescriptor} */
				let descriptor;
				if (descriptorPtr != 0) {
					descriptor = {
						label:           this.mem.loadCstring(descriptorPtr + 4),
						format:          this.enumeration("TextureFormat", descriptorPtr + 8),
						dimension:       this.enumeration("TextureViewDimension", descriptorPtr + 12),
						baseMipLevel:    this.mem.loadU32(descriptorPtr + 16),
						mipLevelCount:   this.mem.loadU32(descriptorPtr + 20),
						baseArrayLayer:  this.mem.loadU32(descriptorPtr + 24),
						arrayLayerCount: this.mem.loadU32(descriptorPtr + 28),
						aspect:          this.enumeration("TextureAspect", descriptorPtr + 32),
					};
					if (descriptor.arrayLayerCount == 0xFFFFFFFF) {
						descriptor.arrayLayerCount = undefined;
					}
					if (descriptor.mipLevelCount == 0xFFFFFFFF) {
						descriptor.mipLevelCount = undefined;
					}
				}

				const textureView = texture.createView(descriptor);
				return this.textureViews.create(textureView);
			},

			/**
			 * @param {number} textureIdx
			 */
			wgpuTextureDestroy: (textureIdx) => {
				const texture = this.textures.get(textureIdx);
				texture.destroy();
			},

			/**
			 * @param {number} textureIdx
			 * @returns {number}
			 */
			wgpuTextureDepthOrArrayLayers: (textureIdx) => {
				const texture = this.textures.get(textureIdx);
				return texture.depthOrArrayLayers;
			},

			/**
			 * @param {number} textureIdx
			 * @returns {number}
			 */
			wgpuTextureGetDimension: (textureIdx) => {
				const texture = this.textures.get(textureIdx);
				return this.enums.TextureDimension.indexOf(texture.dimension);
			},

			/**
			 * @param {number} textureIdx
			 * @returns {number}
			 */
			wgpuTextureGetFormat: (textureIdx) => {
				const texture = this.textures.get(textureIdx);
				return this.enums.TextureFormat.indexOf(texture.format);
			},

			/**
			 * @param {number} textureIdx
			 * @returns {number}
			 */
			wgpuTextureGetHeight: (textureIdx) => {
				const texture = this.textures.get(textureIdx);
				return texture.height;
			},

			/**
			 * @param {number} textureIdx
			 * @returns {number}
			 */
			wgpuTextureGetMipLevelCount: (textureIdx) => {
				const texture = this.textures.get(textureIdx);
				return texture.mipLevelCount;
			},

			/**
			 * @param {number} textureIdx
			 * @returns {number}
			 */
			wgpuTextureGetSampleCount: (textureIdx) => {
				const texture = this.textures.get(textureIdx);
				return texture.sampleCount;
			},

			/**
			 * @param {number} textureIdx
			 * @returns {number}
			 */
			wgpuTextureGetUsage: (textureIdx) => {
				const texture = this.textures.get(textureIdx);
				return texture.usage;
			},

			/**
			 * @param {number} textureIdx
			 * @returns {number}
			 */
			wgpuTextureGetWidth: (textureIdx) => {
				const texture = this.textures.get(textureIdx);
				return texture.width;
			},

			...this.textures.interface(true),

			/* ---------------------- TextureView ---------------------- */

			...this.textureViews.interface(true),
		};
	}
}

/** @template T */
class WebGPUObjectManager {

	/**
	 * @param {string} name
	 * @param {WasmMemoryInterface} mem
	 */
	constructor(name, mem) {
		this.name = name;
		this.mem = mem;

		this.idx = 0;

		/** @type {Record<number, { references: number, object: T }>} */
		this.objects = {};
	}

	/**
	 * @param {T} object
	 * @returns {number}
	 */
	create(object) {
		this.objects[this.idx] = { references: 1, object };
		this.idx += 1;
		return this.idx;
	}

	/**
	 * @param {number} idx
	 * @returns {T}
	 */
	get(idx) {
		return this.objects[idx-1].object;
	}

	/** @param {number} idx */
	release(idx) {
		this.objects[idx-1].references -= 1;
		if (this.objects[idx-1].references == 0) {
			delete this.objects[idx-1];
		}
	}

	/** @param {number} idx */
	reference(idx) {
		this.objects[idx-1].references += 1;
	}
	
	interface(withLabelSetter = false) {
		const inter = {};
		inter[`wgpu${this.name}Reference`] = this.reference.bind(this);
		inter[`wgpu${this.name}Release`] = this.release.bind(this);
		if (withLabelSetter) {
			inter[`wgpu${this.name}SetLabel`] = (idx, labelPtr) => {
				const obj = this.get(idx);
				obj.label = this.mem.loadCstring(labelPtr);
			};
		}
		return inter;
	}
}

window.odin = window.odin || {};
window.odin.WebGPUInterface = WebGPUInterface;

})();
