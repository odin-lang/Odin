package encoding_hxa

import "core:mem"

LATEST_VERSION :: 3
VERSION_API :: "0.3"

MAGIC_NUMBER :: 'H'<<0 | 'x'<<8 | 'A'<<16 | '\x00'<<24

Header :: struct #packed {
	magic_number:        u32le,
	version:             u32le,
	internal_node_count: u32le,
}

File :: struct {
	using header: Header,
	backing:   []byte,
	allocator: mem.Allocator,
	nodes:     []Node,
}

Node_Type :: enum u8 {
	Meta_Only = 0, // node only containing meta data.
	Geometry  = 1, // node containing a geometry mesh, and meta data.
	Image     = 2, // node containing a 1D, 2D, 3D, or Cube image, and meta data.
}

Layer_Data_Type :: enum u8 {
	Uint8  = 0, // 8-bit unsigned integer,
	Int32  = 1, // 32-bit little-endian signed integer
	Float  = 2, // 32-bit little-endian IEEE 754 floating point value
	Double = 3, // 64-bit little-endian IEEE 754 floating point value
}

// Pixel data is arranged in the following configurations
Image_Type :: enum u8 {
	Image_Cube = 0, // 6 sided qube, in the order of: +x, -x, +y, -y, +z, -z.
	Image_1D   = 1, // One dimensional pixel data.
	Image_2D   = 2, // Two dimensional pixel data.
	Image_3D   = 3, // Three dimensional pixel data.
}

Meta_Value_Type :: enum u8 {
	Int64  = 0,
	Double = 1,
	Node   = 2,
	Text   = 3,
	Binary = 4,
	Meta   = 5,
}

Meta :: struct {
	name: string, // name of the meta data value (maximum length is 255)
	value: union {
		[]i64le,
		[]f64le,
		[]Node_Index, // a reference to another node
		string, // text
		[]byte, // binary data
		[]Meta,
	},
}

Layer :: struct {
	name: string, // name of the layer (maximum length is 255)
	components: u8, // 2 for uv, 3 for xyz/rgb, 4 for rgba
	data: union {
		[]u8,
		[]i32le,
		[]f32le,
		[]f64le,
	},
}

// Layers stacks are arrays of layers where all the layers have the same number of entries (polygons, edges, vertices or pixels)
Layer_Stack :: distinct []Layer

Node_Geometry :: struct {
	vertex_count:      u32le,       // number of vertices
	vertex_stack:      Layer_Stack, // stack of vertex arrays. the first layer is always the vertex positions
	edge_corner_count: u32le,       // number of corners
	corner_stack:      Layer_Stack, // stack of corner arrays, the first layer is always a reference array (see below)
	edge_stack:        Layer_Stack, // stack of edge arrays
	face_count:        u32le,       // number of polygons
	face_stack:        Layer_Stack, // stack of per polygon data.
}

Node_Image :: struct {
	type:        Image_Type,
	resolution:  [3]u32le,
	image_stack: Layer_Stack,
}

Node_Index :: distinct u32le

// A file consists of an array of nodes, All nodes have meta data. Geometry nodes have geometry, image nodes have pixels
Node :: struct {
	meta_data: []Meta,
	content: union {
		Node_Geometry,
		Node_Image,
	},
}


/* Conventions */
/* ------------
Much of HxA's use is based on convention. HxA lets users store arbitrary data in its structure that can be parsed but whose semantic meaning does not need to be understood.
A few conventions are hard, and some are soft. Hard convention that a user HAS to follow in order to produce a valid file. Hard conventions simplify parsing becaus the parser can make some assumptions. Soft convenbtions are basically recomendations of how to store common data.
If you use HxA for something not covered by the conventions but need a convention for your use case. Please let us know so that we can add it!
*/

/* Hard conventions */
/* ---------------- */

CONVENTION_HARD_BASE_VERTEX_LAYER_NAME       :: "vertex"
CONVENTION_HARD_BASE_VERTEX_LAYER_ID         :: 0
CONVENTION_HARD_BASE_VERTEX_LAYER_COMPONENTS :: 3
CONVENTION_HARD_BASE_CORNER_LAYER_NAME       :: "reference"
CONVENTION_HARD_BASE_CORNER_LAYER_ID         :: 0
CONVENTION_HARD_BASE_CORNER_LAYER_COMPONENTS :: 1
CONVENTION_HARD_BASE_CORNER_LAYER_TYPE       :: Layer_Data_Type.Int32
CONVENTION_HARD_EDGE_NEIGHBOUR_LAYER_NAME    :: "neighbour"
CONVENTION_HARD_EDGE_NEIGHBOUR_LAYER_TYPE    :: Layer_Data_Type.Int32



/* Soft Conventions */
/* ---------------- */

/* geometry layers */

CONVENTION_SOFT_LAYER_SEQUENCE0      :: "sequence"
CONVENTION_SOFT_LAYER_NAME_UV0       :: "uv"
CONVENTION_SOFT_LAYER_NORMALS        :: "normal"
CONVENTION_SOFT_LAYER_BINORMAL       :: "binormal"
CONVENTION_SOFT_LAYER_TANGENT        :: "tangent"
CONVENTION_SOFT_LAYER_COLOR          :: "color"
CONVENTION_SOFT_LAYER_CREASES        :: "creases"
CONVENTION_SOFT_LAYER_SELECTION      :: "select"
CONVENTION_SOFT_LAYER_SKIN_WEIGHT    :: "skining_weight"
CONVENTION_SOFT_LAYER_SKIN_REFERENCE :: "skining_reference"
CONVENTION_SOFT_LAYER_BLENDSHAPE     :: "blendshape"
CONVENTION_SOFT_LAYER_ADD_BLENDSHAPE :: "addblendshape"
CONVENTION_SOFT_LAYER_MATERIAL_ID    :: "material"

/* Image layers */

CONVENTION_SOFT_ALBEDO            :: "albedo"
CONVENTION_SOFT_LIGHT             :: "light"
CONVENTION_SOFT_DISPLACEMENT      :: "displacement"
CONVENTION_SOFT_DISTORTION        :: "distortion"
CONVENTION_SOFT_AMBIENT_OCCLUSION :: "ambient_occlusion"

/* tags layers */

CONVENTION_SOFT_NAME      :: "name"
CONVENTION_SOFT_TRANSFORM :: "transform"

/* destroy procedures */

meta_destroy :: proc(meta: Meta, allocator := context.allocator, loc := #caller_location) {
	if nested, ok := meta.value.([]Meta); ok {
		for m in nested {
			meta_destroy(m, loc=loc)
		}
		delete(nested, allocator, loc=loc)
	}
}
nodes_destroy :: proc(nodes: []Node, allocator := context.allocator, loc := #caller_location) {
	for node in nodes {
		for meta in node.meta_data {
			meta_destroy(meta, loc=loc)
		}
		delete(node.meta_data, allocator, loc=loc)

		switch n in node.content {
		case Node_Geometry:
			delete(n.corner_stack, allocator, loc=loc)
			delete(n.vertex_stack, allocator, loc=loc)
			delete(n.edge_stack,   allocator, loc=loc)
			delete(n.face_stack,   allocator, loc=loc)
		case Node_Image:
			delete(n.image_stack,  allocator, loc=loc)
		}
	}
	delete(nodes, allocator, loc=loc)
}

file_destroy :: proc(file: File, loc := #caller_location) {
	nodes_destroy(file.nodes, file.allocator, loc=loc)
	delete(file.backing, file.allocator, loc=loc)
}