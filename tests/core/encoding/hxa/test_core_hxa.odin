// Tests "core:encoding:hxa".
// Must be run with `-collection:tests=` flag, e.g.
// ./odin run tests/core/encoding/hxa/test_core_hxa.odin -out=tests/core/test_core_hxa -collection:tests=./tests
package test_core_hxa

import "core:encoding/hxa"
import "core:fmt"
import "core:testing"

TEAPOT_PATH :: ODIN_ROOT + "tests/core/assets/HXA/teapot.hxa"

import "core:os"

@test
test_read :: proc(t: ^testing.T) {
	data, _ := os.read_entire_file(TEAPOT_PATH)
	// file, err := hxa.read_from_file(TEAPOT_PATH)
	file, err := hxa.read(data)
	file.backing = data
	file.allocator = context.allocator
	hxa.file_destroy(file)
	// fmt.printfln("%#v", file)

	e :: hxa.Read_Error.None
	testing.expectf(t, err == e, "read_from_file(%v) -> %v != %v", TEAPOT_PATH, err, e)

	/* Header */
	testing.expectf(t, file.magic_number == 0x417848, "file.magic_number %v != %v", file.magic_number, 0x417848)
	testing.expectf(t, file.version == 1, "file.version %v != %v", file.version, 1)
	testing.expectf(t, file.internal_node_count == 1, "file.internal_node_count %v != %v", file.internal_node_count, 1)

	/* Nodes (only one) */
	testing.expectf(t, len(file.nodes) == 1, "len(file.nodes) %v != %v", len(file.nodes), 1)

	m := &file.nodes[0].meta_data
	testing.expectf(t, len(m^) == 38, "len(m^) %v != %v", len(m^), 38)
	{
		e :: "Texture resolution"
		testing.expectf(t, m[0].name == e, "m[0].name %v != %v", m[0].name, e)

		m_v, m_v_ok := m[0].value.([]i64le)
		testing.expectf(t, m_v_ok,           "m_v_ok %v != %v",   m_v_ok,   true)
		testing.expectf(t, len(m_v) == 1,    "len(m_v) %v != %v", len(m_v), 1)
		testing.expectf(t, m_v[0]   == 1024, "m_v[0] %v != %v",   len(m_v), 1024)
	}
	{
		e :: "Validate"
		testing.expectf(t, m[37].name == e, "m[37].name %v != %v", m[37].name, e)

		m_v, m_v_ok := m[37].value.([]i64le)
		testing.expectf(t, m_v_ok,                  "m_v_ok %v != %v",   m_v_ok,   true)
		testing.expectf(t, len(m_v) == 1,           "len(m_v) %v != %v", len(m_v), 1)
		testing.expectf(t, m_v[0]   == -2054847231, "m_v[0] %v != %v",   len(m_v), -2054847231)
	}

	/* Node content */
	v, v_ok := file.nodes[0].content.(hxa.Node_Geometry)
	testing.expectf(t, v_ok, "v_ok %v != %v", v_ok, true)

	testing.expectf(t, v.vertex_count      == 530,  "v.vertex_count %v != %v",      v.vertex_count, 530)
	testing.expectf(t, v.edge_corner_count == 2026, "v.edge_corner_count %v != %v", v.edge_corner_count, 2026)
	testing.expectf(t, v.face_count        == 517,  "v.face_count %v != %v",        v.face_count, 517)

	/* Vertex stack */
	testing.expectf(t, len(v.vertex_stack) == 1, "len(v.vertex_stack) %v != %v", len(v.vertex_stack), 1)
	{
		e := "vertex"
		testing.expectf(t, v.vertex_stack[0].name == e, "v.vertex_stack[0].name %v != %v", v.vertex_stack[0].name, e)
	}
	testing.expectf(t, v.vertex_stack[0].components == 3, "v.vertex_stack[0].components %v != %v", v.vertex_stack[0].components, 3)

	/* Vertex stack data */
	vs_d, vs_d_ok := v.vertex_stack[0].data.([]f64le)
	testing.expectf(t, vs_d_ok,                          "vs_d_ok %v != %v",              vs_d_ok, true)
	testing.expectf(t, len(vs_d) == 1590,                "len(vs_d) %v != %v",            len(vs_d), 1590)
	testing.expectf(t, vs_d[0] == 4.06266,               "vs_d[0] %v (%h) != %v (%h)",    vs_d[0], vs_d[0], 4.06266, 4.06266)
	testing.expectf(t, vs_d[1] == 2.83457,               "vs_d[1] %v (%h) != %v (%h)",    vs_d[1], vs_d[1], 2.83457, 2.83457)
	testing.expectf(t, vs_d[2] == 0hbfbc5da6a4441787,    "vs_d[2] %v (%h) != %v (%h)",    vs_d[2], vs_d[2], 0hbfbc5da6a4441787, 0hbfbc5da6a4441787)
	testing.expectf(t, vs_d[3] == 0h4010074fb549f948,    "vs_d[3] %v (%h) != %v (%h)",    vs_d[3], vs_d[3], 0h4010074fb549f948, 0h4010074fb549f948)
	testing.expectf(t, vs_d[1587] == 0h400befa82e87d2c7, "vs_d[1587] %v (%h) != %v (%h)", vs_d[1587], vs_d[1587], 0h400befa82e87d2c7, 0h400befa82e87d2c7)
	testing.expectf(t, vs_d[1588] == 2.83457,            "vs_d[1588] %v (%h) != %v (%h)", vs_d[1588], vs_d[1588], 2.83457, 2.83457)
	testing.expectf(t, vs_d[1589] == -1.56121,           "vs_d[1589] %v (%h) != %v (%h)", vs_d[1589], vs_d[1589], -1.56121, -1.56121)

	/* Corner stack */
	testing.expectf(t, len(v.corner_stack) == 1,         "len(v.corner_stack) %v != %v", len(v.corner_stack), 1)
	{
		e := "reference"
		testing.expectf(t, v.corner_stack[0].name == e, "v.corner_stack[0].name %v != %v", v.corner_stack[0].name, e)
	}
	testing.expectf(t, v.corner_stack[0].components == 1, "v.corner_stack[0].components %v != %v", v.corner_stack[0].components, 1)

	/* Corner stack data */
	cs_d, cs_d_ok := v.corner_stack[0].data.([]i32le)
	testing.expectf(t, cs_d_ok,                "cs_d_ok %v != %v",           cs_d_ok, true)
	testing.expectf(t, len(cs_d) == 2026,      "len(cs_d) %v != %v",         len(cs_d), 2026)
	testing.expectf(t, cs_d[0] == 6,           "cs_d[0] %v != %v",           cs_d[0], 6)
	testing.expectf(t, cs_d[2025] == -32,      "cs_d[2025] %v != %v",        cs_d[2025], -32)

	/* Edge and face stacks (empty) */
	testing.expectf(t, len(v.edge_stack) == 0, "len(v.edge_stack) %v != %v", len(v.edge_stack), 0)
	testing.expectf(t, len(v.face_stack) == 0, "len(v.face_stack) %v != %v", len(v.face_stack), 0)
}

@test
test_write :: proc(t: ^testing.T) {
	n1: hxa.Node

	n1_m1_value := []f64le{0.4, -1.23, 2341.6, -333.333}
	n1_m1 := hxa.Meta{"m1", n1_m1_value}

	n1.meta_data = []hxa.Meta{n1_m1}

	n1_l1 := hxa.Layer{"l1", 2, []f32le{32.1, -41.3}}
	n1_l2 := hxa.Layer{"l2", 3, []f64le{0.64, 1.64, -2.64}}

	n1_content := hxa.Node_Image{.Image_1D, [3]u32le{1, 1, 2}, hxa.Layer_Stack{n1_l1, n1_l2}}

	n1.content = n1_content

	w_file: hxa.File
	w_file.nodes = []hxa.Node{n1}

	required_size := hxa.required_write_size(w_file)
	buf := make([]u8, required_size)
	defer delete(buf)

	n, write_err := hxa.write(buf, w_file)
	write_e :: hxa.Write_Error.None
	testing.expectf(t, write_err == write_e, fmt.tprintf("write_err %v != %v", write_err, write_e))
	testing.expectf(t, n == required_size, fmt.tprintf("n %v != %v", n, required_size))

	file, read_err := hxa.read(buf)
	read_e :: hxa.Read_Error.None
	testing.expectf(t, read_err == read_e, fmt.tprintf("read_err %v != %v", read_err, read_e))
	defer hxa.file_destroy(file)

	testing.expectf(t, file.magic_number == 0x417848, fmt.tprintf("file.magic_number %v != %v",
															file.magic_number, 0x417848))
	testing.expectf(t, file.version == 3, fmt.tprintf("file.version %v != %v", file.version, 3))
	testing.expectf(t, file.internal_node_count == 1, fmt.tprintf("file.internal_node_count %v != %v",
															file.internal_node_count, 1))

	testing.expectf(t, len(file.nodes) == len(w_file.nodes), fmt.tprintf("len(file.nodes) %v != %v",
																   len(file.nodes), len(w_file.nodes)))

	m := &file.nodes[0].meta_data
	w_m := &w_file.nodes[0].meta_data
	testing.expectf(t, len(m^) == len(w_m^), fmt.tprintf("len(m^) %v != %v", len(m^), len(w_m^)))
	testing.expectf(t, m[0].name == w_m[0].name, fmt.tprintf("m[0].name %v != %v", m[0].name, w_m[0].name))

	m_v, m_v_ok := m[0].value.([]f64le)
	testing.expectf(t, m_v_ok, fmt.tprintf("m_v_ok %v != %v", m_v_ok, true))
	testing.expectf(t, len(m_v) == len(n1_m1_value), fmt.tprintf("%v != len(m_v) %v",
														   len(m_v), len(n1_m1_value)))
	for i := 0; i < len(m_v); i += 1 {
		testing.expectf(t, m_v[i] == n1_m1_value[i], fmt.tprintf("m_v[%d] %v != %v",
														   i, m_v[i], n1_m1_value[i]))
	}

	v, v_ok := file.nodes[0].content.(hxa.Node_Image)
	testing.expectf(t, v_ok, fmt.tprintf("v_ok %v != %v", v_ok, true))
	testing.expectf(t, v.type == n1_content.type, fmt.tprintf("v.type %v != %v", v.type, n1_content.type))
	testing.expectf(t, len(v.resolution) == 3, fmt.tprintf("len(v.resolution) %v != %v",
													 len(v.resolution), 3))
	testing.expectf(t, len(v.image_stack) == len(n1_content.image_stack), fmt.tprintf("len(v.image_stack) %v != %v",
			  len(v.image_stack), len(n1_content.image_stack)))
	for i := 0; i < len(v.image_stack); i += 1 {
		testing.expectf(t, v.image_stack[i].name == n1_content.image_stack[i].name,
				  fmt.tprintf("v.image_stack[%d].name %v != %v",
							  i, v.image_stack[i].name, n1_content.image_stack[i].name))
		testing.expectf(t, v.image_stack[i].components == n1_content.image_stack[i].components,
				  fmt.tprintf("v.image_stack[%d].components %v != %v",
				  			  i, v.image_stack[i].components, n1_content.image_stack[i].components))

		switch n1_t in n1_content.image_stack[i].data {
		case []u8:
			testing.expectf(t, false, fmt.tprintf("n1_content.image_stack[i].data []u8", #procedure))
		case []i32le:
			testing.expectf(t, false, fmt.tprintf("n1_content.image_stack[i].data []i32le", #procedure))
		case []f32le:
			l, l_ok := v.image_stack[i].data.([]f32le)
			testing.expectf(t, l_ok, fmt.tprintf("l_ok %v != %v", l_ok, true))
			testing.expectf(t, len(l) == len(n1_t), fmt.tprintf("len(l) %v != %v", len(l), len(n1_t)))
			for j := 0; j < len(l); j += 1 {
				testing.expectf(t, l[j] == n1_t[j], fmt.tprintf("l[%d] %v (%h) != %v (%h)",
														  j, l[j], l[j], n1_t[j], n1_t[j]))
			}
		case []f64le:
			l, l_ok := v.image_stack[i].data.([]f64le)
			testing.expectf(t, l_ok, fmt.tprintf("l_ok %v != %v", l_ok, true))
			testing.expectf(t, len(l) == len(n1_t), fmt.tprintf("len(l) %v != %v", len(l), len(n1_t)))
			for j := 0; j < len(l); j += 1 {
				testing.expectf(t, l[j] == n1_t[j], fmt.tprintf("l[%d] %v != %v", j, l[j], n1_t[j]))
			}
		}
	}
}