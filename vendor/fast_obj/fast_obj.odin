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
	illum:    c.int,   // Illumination model 

	/* Set for materials that don't come from the associated mtllib */
	fallback: c.int,

	/* Texture map indices in Mesh textures array */
	map_Ka:   c.uint,
	map_Kd:   c.uint,
	map_Ks:   c.uint,
	map_Ke:   c.uint,
	map_Kt:   c.uint,
	map_Ns:   c.uint,
	map_Ni:   c.uint,
	map_d:    c.uint,
	map_bump: c.uint,

}

// The orignal C libary allows for overriding the field type.
// Here we're just using the default type.
Index :: struct {
	p: c.uint,
	t: c.uint,
	n: c.uint,
}


Group :: struct {
	/* Group name */
	name:         cstring,

	/* Number of faces */
	face_count:   c.uint,

	/* First face in Mesh face_* arrays */
	face_offset:  c.uint,

	/* First index in Mesh indices array */
	index_offset: c.uint,
}


/* Note: a dummy zero-initialized value is added to the first index
   of the positions, texcoords, normals and textures arrays. Hence,
   valid indices into these arrays start from 1, with an index of 0
   indicating that the attribute is not present. */
Mesh :: struct {
	/* Vertex data */
	position_count: c.uint,
	positions:      [^]f32,

	texcoord_count: c.uint,
	texcoords:      [^]f32,

	normal_count:   c.uint,
	normals:        [^]f32,

	color_count:    c.uint,
	colors:         [^]f32,

	/* Face data: one element for each face */
	face_count:     c.uint,
	face_vertices:  [^]c.uint,
	face_materials: [^]c.uint,
	face_lines:     [^]byte,

	/* Index data: one element for each face vertex */
	index_count:    c.uint,
	indices:        [^]Index,

	/* Materials */
	material_count: c.uint,
	materials:      [^]Material,

	/* Texture maps */
	texture_count:  c.uint,
	textures:       [^]Texture,

	/* Mesh objects ('o' tag in .obj file) */
	object_count:   c.uint,
	objects:        [^]Group,

	/* Mesh groups ('g' tag in .obj file) */
	group_count:    c.uint,
	groups:         [^]Group,
}

Callbacks :: struct {
	file_open:  #type proc "c" (path: cstring, user_data: rawptr) -> rawptr,
	file_close: #type proc "c" (file: rawptr,  user_data: rawptr),
	file_read:  #type proc "c" (file: rawptr,  dst: rawptr, bytes: c.size_t, user_data: rawptr) -> c.size_t,
	file_size:  #type proc "c" (file: rawptr,  user_data: rawptr) -> c.ulong,
}

@(default_calling_convention="c", link_prefix="fast_obj_")
foreign fast_obj {
	read                :: proc(path: cstring) -> ^Mesh ---
	read_with_callbacks :: proc(path: cstring, callbacks: ^Callbacks, user_data: rawptr) -> ^Mesh ---
	destroy             :: proc(mesh: ^Mesh) ---
}
