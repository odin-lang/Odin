package cgltf

@(private)
LIB :: (
	     "lib/cgltf.lib"      when ODIN_OS == .Windows
	else "lib/cgltf.a"        when ODIN_OS == .Linux
	else "lib/darwin/cgltf.a" when ODIN_OS == .Darwin
	else "lib/cgltf_wasm.o"   when ODIN_ARCH == .wasm32 || ODIN_ARCH == .wasm64p32
	else ""
)

when LIB != "" {
	when !#exists(LIB) {
		// Windows library is shipped with the compiler, so a Windows specific message should not be needed.
		#panic("Could not find the compiled cgltf library, it can be compiled by running `make -C \"" + ODIN_ROOT + "vendor/cgltf/src\"`")
	}
}

when ODIN_ARCH == .wasm32 || ODIN_ARCH == .wasm64p32 {
	foreign import lib "lib/cgltf_wasm.o"
} else when LIB != "" {
	foreign import lib { LIB }
} else {
	foreign import lib "system:cgltf"
}

import "core:c"


file_type :: enum c.int {
	invalid,
	gltf,
	glb,
}

result :: enum c.int {
	success,
	data_too_short,
	unknown_format,
	invalid_json,
	invalid_gltf,
	invalid_options,
	file_not_found,
	io_error,
	out_of_memory,
	legacy_gltf,
}

memory_options :: struct {
	alloc_func: proc "c" (user: rawptr, size: uint) -> rawptr,
	free_func:  proc "c" (user: rawptr, ptr: rawptr),
	user_data:  rawptr,
}

file_options :: struct {
	read:      proc "c" (memory_options: ^/*const*/memory_options, file_options: ^/*const*/file_options, path: cstring, size: ^uint, data: ^rawptr) -> result,
	release:   proc "c" (memory_options: ^/*const*/memory_options, file_options: ^/*const*/file_options, data: rawptr),
	user_data: rawptr,
}

options :: struct {
	type:             file_type, /* invalid == auto detect */
	json_token_count: uint,      /* 0 == auto */
	memory:           memory_options,
	file:             file_options,
}

buffer_view_type :: enum c.int {
	invalid,
	indices,
	vertices,
}

attribute_type :: enum c.int {
	invalid,
	position,
	normal,
	tangent,
	texcoord,
	color,
	joints,
	weights,
	custom,
}

component_type :: enum c.int {
	invalid,
	r_8,   /* BYTE */
	r_8u,  /* UNSIGNED_BYTE */
	r_16,  /* SHORT */
	r_16u, /* UNSIGNED_SHORT */
	r_32u, /* UNSIGNED_INT */
	r_32f, /* FLOAT */
}

type :: enum c.int {
	invalid,
	scalar,
	vec2,
	vec3,
	vec4,
	mat2,
	mat3,
	mat4,
}

primitive_type :: enum c.int {
	points,
	lines,
	line_loop,
	line_strip,
	triangles,
	triangle_strip,
	triangle_fan,
}

alpha_mode :: enum c.int {
	opaque,
	mask,
	blend,
}

animation_path_type :: enum c.int {
	invalid,
	translation,
	rotation,
	scale,
	weights,
}

interpolation_type :: enum c.int {
	linear,
	step,
	cubic_spline,
}

camera_type :: enum c.int {
	invalid,
	perspective,
	orthographic,
}

light_type :: enum c.int {
	invalid,
	directional,
	point,
	spot,
}

data_free_method :: enum c.int {
	none,
	file_release,
	memory_free,
}

extras_t :: struct {
	start_offset: uint, /* this field is deprecated and will be removed in the future; use data instead */
	end_offset:   uint, /* this field is deprecated and will be removed in the future; use data instead */

	data: [^]byte,
}

extension :: struct {
	name: cstring,
	data: [^]byte,
}

buffer :: struct {
	name:             cstring,
	size:             uint,
	uri:              cstring,
	data:             rawptr, /* loaded by cgltf_load_buffers */
	data_free_method: data_free_method,
	extras:           extras_t,
	extensions_count: uint,
	extensions:       [^]extension `fmt:"v,extensions_count"`,
}

meshopt_compression_mode :: enum c.int {
	invalid,
	attributes,
	triangles,
	indices,
}

meshopt_compression_filter :: enum c.int {
	none,
	octahedral,
	quaternion,
	exponential,
}

meshopt_compression :: struct {
	buffer: ^buffer,
	offset: uint,
	size:   uint,
	stride: uint,
	count:  uint,
	mode:   meshopt_compression_mode,
	filter: meshopt_compression_filter,
}

buffer_view :: struct {
	name:                    cstring,
	buffer:                  ^buffer,
	offset:                  uint,
	size:                    uint,
	stride:                  uint, /* 0 == automatically determined by accessor */
	type:                    buffer_view_type,
	data:                    rawptr, /* overrides buffer->data if present, filled by extensions */
	has_meshopt_compression: b32,
	meshopt_compression:     meshopt_compression,
	extras:                  extras_t,
	extensions_count:        uint,
	extensions:              [^]extension `fmt:"v,extensions_count"`,
}

accessor_sparse :: struct {
	count:                    uint,
	indices_buffer_view:      ^buffer_view,
	indices_byte_offset:      uint,
	indices_component_type:   component_type,
	values_buffer_view:       ^buffer_view,
	values_byte_offset:       uint,
	extras:                   extras_t,
	indices_extras:           extras_t,
	values_extras:            extras_t,
	extensions_count:         uint,
	extensions:               [^]extension `fmt:"v,extensions_count"`,
	indices_extensions_count: uint,
	indices_extensions:       [^]extension `fmt:"v,indices_extensions_count"`,
	values_extensions_count:  uint,
	values_extensions:        [^]extension `fmt:"v,values_extensions_count"`,
}

accessor :: struct {
	name:             cstring,
	component_type:   component_type,
	normalized:       b32,
	type:             type,
	offset:           uint,
	count:            uint,
	stride:           uint,
	buffer_view:      ^buffer_view,
	has_min:          b32,
	min:              [16]f32,
	has_max:          b32,
	max:              [16]f32,
	is_sparse:        b32,
	sparse:           accessor_sparse,
	extras:           extras_t,
	extensions_count: uint,
	extensions:       [^]extension `fmt:"v,extensions_count"`,
}

attribute :: struct {
	name:  cstring,
	type:  attribute_type,
	index: c.int,
	data:  ^accessor,
}

image :: struct {
	name:             cstring,
	uri:              cstring,
	buffer_view:      ^buffer_view,
	mime_type:        cstring,
	extras:           extras_t,
	extensions_count: uint,
	extensions:       [^]extension `fmt:"v,extensions_count"`,
}

sampler :: struct {
	name:             cstring,
	mag_filter:       c.int,
	min_filter:       c.int,
	wrap_s:           c.int,
	wrap_t:           c.int,
	extras:           extras_t,
	extensions_count: uint,
	extensions:       [^]extension `fmt:"v,extensions_count"`,
}

texture :: struct {
	name:             cstring,
	image_:           ^image,
	sampler:          ^sampler,
	has_basisu:       b32 ,
	basisu_image:     ^image,
	extras:           extras_t,
	extensions_count: uint,
	extensions:       [^]extension `fmt:"v,extensions_count"`,
}

texture_transform :: struct {
	offset:       [2]f32,
	rotation:     f32,
	scale:        [2]f32,
	has_texcoord: b32,
	texcoord:     c.int,
}

texture_view :: struct {
	texture:          ^texture,
	texcoord:         c.int,
	scale:            f32, /* equivalent to strength for occlusion_texture */
	has_transform:    b32,
	transform:        texture_transform,
	extras:           extras_t,
	extensions_count: uint,
	extensions:       [^]extension `fmt:"v,extensions_count"`,
}

pbr_metallic_roughness :: struct {
	base_color_texture:         texture_view,
	metallic_roughness_texture: texture_view,

	base_color_factor: [4]f32,
	metallic_factor:   f32,
	roughness_factor:  f32,
}

pbr_specular_glossiness :: struct {
	diffuse_texture:             texture_view,
	specular_glossiness_texture: texture_view,

	diffuse_factor:    [4]f32,
	specular_factor:   [3]f32,
	glossiness_factor: f32,
}

clearcoat :: struct {
	clearcoat_texture:           texture_view,
	clearcoat_roughness_texture: texture_view,
	clearcoat_normal_texture:    texture_view,

	clearcoat_factor:           f32,
	clearcoat_roughness_factor: f32,
}

transmission :: struct {
	transmission_texture: texture_view,
	transmission_factor:  f32,
}

ior :: struct {
	ior: f32,
}

specular :: struct {
	specular_texture:       texture_view,
	specular_color_texture: texture_view,
	specular_color_factor:  [3]f32,
	specular_factor:        f32,
}

volume :: struct {
	thickness_texture:    texture_view,
	thickness_factor:     f32,
	attenuation_color:    [3]f32,
	attenuation_distance: f32,
}

sheen :: struct {
	sheen_color_texture:     texture_view,
	sheen_color_factor:      [3]f32,
	sheen_roughness_texture: texture_view,
	sheen_roughness_factor:  f32,
}

emissive_strength :: struct {
	emissive_strength: f32,
}

iridescence :: struct {
	iridescence_factor:            f32,
	iridescence_texture:           texture_view,
	iridescence_ior:               f32,
	iridescence_thickness_min:     f32,
	iridescence_thickness_max:     f32,
	iridescence_thickness_texture: texture_view,
}

material :: struct {
	name: cstring,
	has_pbr_metallic_roughness:  b32,
	has_pbr_specular_glossiness: b32,
	has_clearcoat:               b32,
	has_transmission:            b32,
	has_volume:                  b32,
	has_ior:                     b32,
	has_specular:                b32,
	has_sheen:                   b32,
	has_emissive_strength:       b32,
	has_iridescence:             b32,
	pbr_metallic_roughness:      pbr_metallic_roughness,
	pbr_specular_glossiness:     pbr_specular_glossiness,
	clearcoat:                   clearcoat,
	ior:                         ior,
	specular:                    specular,
	sheen:                       sheen,
	transmission:                transmission,
	volume:                      volume,
	emissive_strength:           emissive_strength,
	iridescence:                 iridescence,
	normal_texture:              texture_view,
	occlusion_texture:           texture_view,
	emissive_texture:            texture_view,
	emissive_factor:             [3]f32,
	alpha_mode:                  alpha_mode,
	alpha_cutoff:                f32,
	double_sided:                b32,
	unlit:                       b32,
	extras:                      extras_t,
	extensions_count:            uint,
	extensions:                  [^]extension `fmt:"v,extensions_count"`,
}

material_mapping :: struct {
	variant:  uint,
	material: ^material,
	extras:   extras_t,
}

morph_target :: struct {
	attributes: []attribute,
}

draco_mesh_compression :: struct {
	buffer_view: ^buffer_view,
	attributes:  []attribute,
}

mesh_gpu_instancing :: struct {
	buffer_view: ^buffer_view,
	attributes:  []attribute,
}

primitive :: struct {
	type:                       primitive_type,
	indices:                    ^accessor,
	material:                   ^material,
	attributes:                 []attribute,
	targets:                    []morph_target,
	extras:                     extras_t,
	has_draco_mesh_compression: b32,
	draco_mesh_compression:     draco_mesh_compression,
	mappings:                   []material_mapping,
	extensions_count:           uint,
	extensions:                 [^]extension `fmt:"v,extensions_count"`,
}

mesh :: struct {
	name:               cstring,
	primitives:         []primitive,
	weights:            []f32,
	target_names:       []cstring,
	extras:             extras_t,
	extensions_count:   uint,
	extensions:         [^]extension `fmt:"v,extensions_count"`,
}

skin :: struct {
	name:                  cstring,
	joints:                []^node,
	skeleton:              ^node,
	inverse_bind_matrices: ^accessor,
	extras:                extras_t,
	extensions_count:      uint,
	extensions:            [^]extension `fmt:"v,extensions_count"`,
}

camera_perspective :: struct {
	has_aspect_ratio: b32,
	aspect_ratio:     f32,
	yfov:             f32,
	has_zfar:         b32,
	zfar:             f32,
	znear:            f32,
	extras:           extras_t,
}

camera_orthographic :: struct {
	xmag:   f32,
	ymag:   f32,
	zfar:   f32,
	znear:  f32,
	extras: extras_t,
}

camera :: struct {
	name: cstring,
	type: camera_type,
	data: struct #raw_union {
		perspective:  camera_perspective,
		orthographic: camera_orthographic,
	},
	extras:           extras_t,
	extensions_count: uint,
	extensions:       [^]extension `fmt:"v,extensions_count"`,
}

light :: struct {
	name:                  cstring,
	color:                 [3]f32,
	intensity:             f32,
	type:                  light_type,
	range:                 f32,
	spot_inner_cone_angle: f32,
	spot_outer_cone_angle: f32,
	extras:                extras_t,
}

node :: struct {
	name:                    cstring,
	parent:                  ^node,
	children:                []^node,
	skin:                    ^skin,
	mesh:                    ^mesh,
	camera:                  ^camera,
	light:                   ^light,
	weights:                 []f32,
	has_translation:         b32,
	has_rotation:            b32,
	has_scale:               b32,
	has_matrix:              b32,
	translation:             [3]f32,
	rotation:                [4]f32,
	scale:                   [3]f32,
	matrix_:                 [16]f32,
	extras:                  extras_t,
	has_mesh_gpu_instancing: b32,
	mesh_gpu_instancing:     mesh_gpu_instancing,
	extensions_count:        uint,
	extensions:              [^]extension `fmt:"v,extensions_count"`,
}

scene :: struct {
	name:             cstring,
	nodes:            []^node,
	extras:           extras_t,
	extensions_count: uint,
	extensions:       [^]extension `fmt:"v,extensions_count"`,
}

animation_sampler :: struct {
	input:            ^accessor,
	output:           ^accessor,
	interpolation:    interpolation_type,
	extras:           extras_t,
	extensions_count: uint,
	extensions:       [^]extension `fmt:"v,extensions_count"`,
}

animation_channel :: struct {
	sampler:          ^animation_sampler,
	target_node:      ^node,
	target_path:      animation_path_type,
	extras:           extras_t,
	extensions_count: uint,
	extensions:       [^]extension `fmt:"v,extensions_count"`,
}

animation :: struct {
	name:             cstring,
	samplers:         []animation_sampler,
	channels:         []animation_channel,
	extras:           extras_t,
	extensions_count: uint,
	extensions:       [^]extension `fmt:"v,extensions_count"`,
}

material_variant :: struct {
	name:   cstring,
	extras: extras_t,
}

asset :: struct {
	copyright:        cstring,
	generator:        cstring,
	version:          cstring,
	min_version:      cstring,
	extras:           extras_t,
	extensions_count: uint,
	extensions:       [^]extension `fmt:"v,extensions_count"`,
}

data :: struct {
	file_type: file_type,
	file_data: rawptr,

	asset: asset,

	meshes:       []mesh,
	materials:    []material,
	accessors:    []accessor,
	buffer_views: []buffer_view,
	buffers:      []buffer,
	images:       []image,
	textures:     []texture,
	samplers:     []sampler,
	skins:        []skin,
	cameras:      []camera,
	lights:       []light,
	nodes:        []node,
	scenes:       []scene,

	scene: ^scene,

	animations: []animation,

	variants: []material_variant,

	extras: extras_t,

	data_extensions_count: uint,
	data_extensions:       [^]extension `fmt:"v,extensions_count"`,

	extensions_used:     []cstring,
	extensions_required: []cstring,

	json: string,

	bin: []byte,

	memory: memory_options,
	file:   file_options,
}

@(require_results)
parse :: proc "c" (#by_ptr options: options, data_ptr: rawptr, size: uint) -> (out_data: ^data, res: result) {
	foreign lib {
		cgltf_parse :: proc "c" (
			#by_ptr options: options,
			data_ptr: rawptr,
			size: uint,
			out_data: ^^data) -> result ---
	}
	res = cgltf_parse(options, data_ptr, size, &out_data)
	return
}

@(require_results)
parse_file :: proc "c" (#by_ptr options: options, path: cstring) -> (out_data: ^data, res: result) {
	foreign lib {
		cgltf_parse_file :: proc "c" (
			#by_ptr options: options,
			path: cstring,
			out_data: ^^data) -> result ---
	}
	res = cgltf_parse_file(options, path, &out_data)
	return
}

@(require_results)
load_buffer_base64 :: proc "c" (#by_ptr options: options, size: uint, base64: cstring) -> (out_data: rawptr, res: result) {
	foreign lib {
		cgltf_load_buffer_base64 :: proc "c" (#by_ptr options: options, size: uint, base64: cstring, out_data: ^rawptr) -> result ---
	}
	res = cgltf_load_buffer_base64(options, size, base64, &out_data)
	return
}

@(default_calling_convention="c")
@(link_prefix="cgltf_")
foreign lib {
	@(require_results)
	load_buffers :: proc(
		#by_ptr options: options,
		data: ^data,
		gltf_path: cstring) -> result ---

	@(require_results)
	decode_string :: proc(string: [^]byte) -> uint ---
	@(require_results)
	decode_uri    :: proc(uri: [^]byte) -> uint ---

	@(require_results)
	validate :: proc(data: ^data) -> result ---

	free :: proc(data: ^data) ---

	node_transform_local :: proc(node: ^node, out_matrix: [^]f32) ---
	node_transform_world :: proc(node: ^node, out_matrix: [^]f32) ---

	@(require_results)
	accessor_read_float :: proc(accessor: ^/*const*/accessor, index: uint, out: [^]f32,    element_size: uint) -> b32 ---
	@(require_results)
	accessor_read_uint  :: proc(accessor: ^/*const*/accessor, index: uint, out: [^]c.uint, element_size: uint) -> b32 ---
	@(require_results)
	accessor_read_index :: proc(accessor: ^/*const*/accessor, index: uint) -> uint ---

	@(require_results)
	num_components :: proc(type: type) -> uint ---

	@(require_results)
	accessor_unpack_floats :: proc(accessor: ^/*const*/accessor, out: [^]f32, float_count: uint) -> uint ---

	/* this function is deprecated and will be removed in the future; use cgltf_extras::data instead */
	@(require_results)
	copy_extras_json :: proc(data: ^data, extras: ^extras_t, dest: [^]byte, dest_size: ^uint) -> result ---

	@(require_results)
	write_file :: proc(#by_ptr options: options, path:   cstring,             data: ^data) -> result ---
	@(require_results)
	write      :: proc(#by_ptr options: options, buffer: [^]byte, size: uint, data: ^data) -> uint ---
}

