// Bindings for fast_obj (https://github.com/thisistherk/fast_obj).
package fast_obj 

import "core:c"

@(private)
LIB :: (
	     "./lib/fast_obj.lib"      when ODIN_OS == .Windows
	else "./lib/fast_obj.a"        when ODIN_OS == .Linux
	else "./lib/darwin/fast_obj.a" when ODIN_OS == .Darwin
	else "./lib/fast_obj_wasm.o"   when ODIN_ARCH == .wasm32 || ODIN_ARCH == .wasm64p32
	else ""
)

when LIB != "" {
	when !#exists(LIB) {
		// Windows library is shipped with the compiler, so a Windows specific message should not be needed.
		#panic("Could not find the compiled fast_obj library, it can be compiled by running `make -C \"" + ODIN_ROOT + "vendor/fast_obj/src\"`")
	}
}

when LIB != "" {
	foreign import fast_obj { LIB }
} else {
	foreign import fast_obj "system:fast_obj"
}

FAST_OBJ_VERSION_MAJOR :: 1
FAST_OBJ_VERSION_MINOR :: 3
FAST_OBJ_VERSION       :: (FAST_OBJ_VERSION_MAJOR << 8) | FAST_OBJ_VERSION_MINOR


Texture :: struct {
	/* Texture name from .mtl file */
	name: cstring,

	/* Resolved path to texture */
	path: cstring,
}

Material :: struct {
	/* Material name */
	name:     cstring,

	/* Parameters */
	Ka:       [3]f32,  // Ambient 
	Kd:       [3]f32,  // Diffuse 
	Ks:       [3]f32,  // Specular 
	Ke:       [3]f32,  // Emission 
	Kt:       [3]f32,  // Transmittance 
	Ns:       f32,     // Shininess 
	Ni:       f32,     // Index of refraction 
	Tf:       [3]f32,  // Transmission filter 
	d:        f32,     // Disolve (alpha) 
	illum:    i32,     // Illumination model 

	/* Set for materials that don't come from the associated mtllib */
	fallback: i32,

	/* Texture map indices in Mesh textures array */
	map_Ka:   u32,
	map_Kd:   u32,
	map_Ks:   u32,
	map_Ke:   u32,
	map_Kt:   u32,
	map_Ns:   u32,
	map_Ni:   u32,
	map_d:    u32,
	map_bump: u32,

}

/* The orignal libary allows for overriding the field type.
   Here we're just using the default type. */
Index :: struct {
	p: u32,
	t: u32,
	n: u32,
}


Group :: struct {
	/* Group name */
	name:         cstring,

	/* Number of faces */
	face_count:   u32,

	/* First face in Mesh face_* arrays */
	face_offset:  u32,

	/* First index in Mesh indices array */
	index_offset: u32,
}


/* Note: a dummy zero-initialized value is added to the first index
   of the positions, texcoords, normals and textures arrays. Hence,
   valid indices into these arrays start from 1, with an index of 0
   indicating that the attribute is not present. */
Mesh :: struct {
	/* Vertex data */
	position_count: u32,
	positions:      [^]f32,

	texcoord_count: u32,
	texcoords:      [^]f32,

	normal_count:   u32,
	normals:        [^]f32,

	color_count:    u32,
	colors:         [^]f32,

	/* Face data: one element for each face */
	face_count:     u32,
	face_vertices:  [^]u32,
	face_materials: [^]u32,
	face_lines:     [^]u8,

	/* Index data: one element for each face vertex */
	index_count:    u32,
	indices:        [^]Index,

	/* Materials */
	material_count: u32,
	materials:      [^]Material,

	/* Texture maps */
	texture_count:  u32,
	textures:       [^]Texture,

	/* Mesh objects ('o' tag in .obj file) */
	object_count:   u32,
	objects:        [^]Group,

	/* Mesh groups ('g' tag in .obj file) */
	group_count:    u32,
	groups:         [^]Group,
}

Callbacks :: struct {
	file_open:  #type proc "c" (path: cstring, user_data: rawptr) -> rawptr,
	file_close: #type proc "c" (file: rawptr,  user_data: rawptr),
	file_read:  #type proc "c" (file: rawptr,  dst: rawptr, bytes: uint, user_data: rawptr) -> uint,
	file_size:  #type proc "c" (file: rawptr,  user_data: rawptr) -> c.ulong,
}

@(default_calling_convention="c", link_prefix="fast_obj_")
foreign fast_obj {
	read                :: proc(path: cstring) -> ^Mesh ---
	read_with_callbacks :: proc(path: cstring, callbacks: ^Callbacks, user_data: rawptr) -> ^Mesh ---
	destroy             :: proc(mesh: ^Mesh) ---
}
