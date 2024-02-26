// Tests "core:encoding:hxa".
// Must be run with `-collection:tests=` flag, e.g.
// ./odin run tests/core/encoding/hxa/test_core_hxa.odin -out=tests/core/test_core_hxa -collection:tests=./tests
package test_core_hxa

import "core:encoding/hxa"
import "core:fmt"
import "core:testing"
import tc "tests:common"

TEAPOT_PATH   :: "core/assets/HXA/teapot.hxa"

main :: proc() {
    t := testing.T{}

	test_read(&t)
	test_write(&t)

	tc.report(&t)
}

@test
test_read :: proc(t: ^testing.T) {
	filename := tc.get_data_path(t, TEAPOT_PATH)
	defer delete(filename)

	file, err := hxa.read_from_file(filename)
	e :: hxa.Read_Error.None
	tc.expect(t, err == e, fmt.tprintf("%v: read_from_file(%v) -> %v != %v", #procedure, filename, err, e))
	defer hxa.file_destroy(file)

	/* Header */
	tc.expect(t, file.magic_number == 0x417848, fmt.tprintf("%v: file.magic_number %v != %v",
															#procedure, file.magic_number, 0x417848))
	tc.expect(t, file.version == 1, fmt.tprintf("%v: file.version %v != %v",
															#procedure, file.version, 1))
	tc.expect(t, file.internal_node_count == 1, fmt.tprintf("%v: file.internal_node_count %v != %v",
															#procedure, file.internal_node_count, 1))

	/* Nodes (only one) */
	tc.expect(t, len(file.nodes) == 1, fmt.tprintf("%v: len(file.nodes) %v != %v", #procedure, len(file.nodes), 1))

	m := &file.nodes[0].meta_data
	tc.expect(t, len(m^) == 38, fmt.tprintf("%v: len(m^) %v != %v", #procedure, len(m^), 38))
	{
		e :: "Texture resolution"
		tc.expect(t, m[0].name == e, fmt.tprintf("%v: m[0].name %v != %v", #procedure, m[0].name, e))

		m_v, m_v_ok := m[0].value.([]i64le)
		tc.expect(t, m_v_ok, fmt.tprintf("%v: m_v_ok %v != %v", #procedure, m_v_ok, true))
		tc.expect(t, len(m_v) == 1, fmt.tprintf("%v: len(m_v) %v != %v", #procedure, len(m_v), 1))
		tc.expect(t, m_v[0] == 1024, fmt.tprintf("%v: m_v[0] %v != %v", #procedure, len(m_v), 1024))
	}
	{
		e :: "Validate"
		tc.expect(t, m[37].name == e, fmt.tprintf("%v: m[37].name %v != %v", #procedure, m[37].name, e))

		m_v, m_v_ok := m[37].value.([]i64le)
		tc.expect(t, m_v_ok, fmt.tprintf("%v: m_v_ok %v != %v", #procedure, m_v_ok, true))
		tc.expect(t, len(m_v) == 1, fmt.tprintf("%v: len(m_v) %v != %v", #procedure, len(m_v), 1))
		tc.expect(t, m_v[0] == -2054847231, fmt.tprintf("%v: m_v[0] %v != %v", #procedure, len(m_v), -2054847231))
	}

	/* Node content */
	v, v_ok := file.nodes[0].content.(hxa.Node_Geometry)
	tc.expect(t, v_ok, fmt.tprintf("%v: v_ok %v != %v", #procedure, v_ok, true))

	tc.expect(t, v.vertex_count == 530, fmt.tprintf("%v: v.vertex_count %v != %v", #procedure, v.vertex_count, 530))
	tc.expect(t, v.edge_corner_count == 2026, fmt.tprintf("%v: v.edge_corner_count %v != %v",
														  #procedure, v.edge_corner_count, 2026))
	tc.expect(t, v.face_count == 517, fmt.tprintf("%v: v.face_count %v != %v", #procedure, v.face_count, 517))

	/* Vertex stack */
	tc.expect(t, len(v.vertex_stack) == 1, fmt.tprintf("%v: len(v.vertex_stack) %v != %v",
													   #procedure, len(v.vertex_stack), 1))
	{
		e := "vertex"
		tc.expect(t, v.vertex_stack[0].name == e, fmt.tprintf("%v: v.vertex_stack[0].name %v != %v",
															  #procedure, v.vertex_stack[0].name, e))
	}
	tc.expect(t, v.vertex_stack[0].components == 3, fmt.tprintf("%v: v.vertex_stack[0].components %v != %v",
																#procedure, v.vertex_stack[0].components, 3))

	/* Vertex stack data */
	vs_d, vs_d_ok := v.vertex_stack[0].data.([]f64le)
	tc.expect(t, vs_d_ok, fmt.tprintf("%v: vs_d_ok %v != %v", #procedure, vs_d_ok, true))
	tc.expect(t, len(vs_d) == 1590, fmt.tprintf("%v: len(vs_d) %v != %v", #procedure, len(vs_d), 1590))

	tc.expect(t, vs_d[0] == 4.06266, fmt.tprintf("%v: vs_d[0] %v (%h) != %v (%h)",
												 #procedure, vs_d[0], vs_d[0], 4.06266, 4.06266))
	tc.expect(t, vs_d[1] == 2.83457, fmt.tprintf("%v: vs_d[1] %v (%h) != %v (%h)",
												 #procedure, vs_d[1], vs_d[1], 2.83457, 2.83457))
	tc.expect(t, vs_d[2] == 0hbfbc5da6a4441787, fmt.tprintf("%v: vs_d[2] %v (%h) != %v (%h)",
															#procedure, vs_d[2], vs_d[2],
															0hbfbc5da6a4441787, 0hbfbc5da6a4441787))
	tc.expect(t, vs_d[3] == 0h4010074fb549f948, fmt.tprintf("%v: vs_d[3] %v (%h) != %v (%h)",
															#procedure, vs_d[3], vs_d[3],
															0h4010074fb549f948, 0h4010074fb549f948))
	tc.expect(t, vs_d[1587] == 0h400befa82e87d2c7, fmt.tprintf("%v: vs_d[1587] %v (%h) != %v (%h)",
															   #procedure, vs_d[1587], vs_d[1587],
															   0h400befa82e87d2c7, 0h400befa82e87d2c7))
	tc.expect(t, vs_d[1588] == 2.83457, fmt.tprintf("%v: vs_d[1588] %v (%h) != %v (%h)",
													#procedure, vs_d[1588], vs_d[1588], 2.83457, 2.83457))
	tc.expect(t, vs_d[1589] == -1.56121, fmt.tprintf("%v: vs_d[1589] %v (%h) != %v (%h)",
													 #procedure, vs_d[1589], vs_d[1589], -1.56121, -1.56121))

	/* Corner stack */
	tc.expect(t, len(v.corner_stack) == 1,
			  fmt.tprintf("%v: len(v.corner_stack) %v != %v", #procedure, len(v.corner_stack), 1))
	{
		e := "reference"
		tc.expect(t, v.corner_stack[0].name == e, fmt.tprintf("%v: v.corner_stack[0].name %v != %v",
															  #procedure, v.corner_stack[0].name, e))
	}
	tc.expect(t, v.corner_stack[0].components == 1, fmt.tprintf("%v: v.corner_stack[0].components %v != %v",
																#procedure, v.corner_stack[0].components, 1))

	/* Corner stack data */
	cs_d, cs_d_ok := v.corner_stack[0].data.([]i32le)
	tc.expect(t, cs_d_ok, fmt.tprintf("%v: cs_d_ok %v != %v", #procedure, cs_d_ok, true))
	tc.expect(t, len(cs_d) == 2026, fmt.tprintf("%v: len(cs_d) %v != %v", #procedure, len(cs_d), 2026))
	tc.expect(t, cs_d[0] == 6, fmt.tprintf("%v: cs_d[0] %v != %v", #procedure, cs_d[0], 6))
	tc.expect(t, cs_d[2025] == -32, fmt.tprintf("%v: cs_d[2025] %v != %v", #procedure, cs_d[2025], -32))

	/* Edge and face stacks (empty) */
	tc.expect(t, len(v.edge_stack) == 0, fmt.tprintf("%v: len(v.edge_stack) %v != %v",
													 #procedure, len(v.edge_stack), 0))
	tc.expect(t, len(v.face_stack) == 0, fmt.tprintf("%v: len(v.face_stack) %v != %v",
													 #procedure, len(v.face_stack), 0))
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
	tc.expect(t, write_err == write_e, fmt.tprintf("%v: write_err %v != %v", #procedure, write_err, write_e))
	tc.expect(t, n == required_size, fmt.tprintf("%v: n %v != %v", #procedure, n, required_size))

	file, read_err := hxa.read(buf)
	read_e :: hxa.Read_Error.None
	tc.expect(t, read_err == read_e, fmt.tprintf("%v: read_err %v != %v", #procedure, read_err, read_e))
	defer hxa.file_destroy(file)

	tc.expect(t, file.magic_number == 0x417848, fmt.tprintf("%v: file.magic_number %v != %v",
															#procedure, file.magic_number, 0x417848))
	tc.expect(t, file.version == 3, fmt.tprintf("%v: file.version %v != %v", #procedure, file.version, 3))
	tc.expect(t, file.internal_node_count == 1, fmt.tprintf("%v: file.internal_node_count %v != %v",
															#procedure, file.internal_node_count, 1))

	tc.expect(t, len(file.nodes) == len(w_file.nodes), fmt.tprintf("%v: len(file.nodes) %v != %v",
																   #procedure, len(file.nodes), len(w_file.nodes)))

	m := &file.nodes[0].meta_data
	w_m := &w_file.nodes[0].meta_data
	tc.expect(t, len(m^) == len(w_m^), fmt.tprintf("%v: len(m^) %v != %v", #procedure, len(m^), len(w_m^)))
	tc.expect(t, m[0].name == w_m[0].name, fmt.tprintf("%v: m[0].name %v != %v", #procedure, m[0].name, w_m[0].name))

	m_v, m_v_ok := m[0].value.([]f64le)
	tc.expect(t, m_v_ok, fmt.tprintf("%v: m_v_ok %v != %v", #procedure, m_v_ok, true))
	tc.expect(t, len(m_v) == len(n1_m1_value), fmt.tprintf("%v: %v != len(m_v) %v",
														   #procedure, len(m_v), len(n1_m1_value)))
	for i := 0; i < len(m_v); i += 1 {
		tc.expect(t, m_v[i] == n1_m1_value[i], fmt.tprintf("%v: m_v[%d] %v != %v",
														   #procedure, i, m_v[i], n1_m1_value[i]))
	}

	v, v_ok := file.nodes[0].content.(hxa.Node_Image)
	tc.expect(t, v_ok, fmt.tprintf("%v: v_ok %v != %v", #procedure, v_ok, true))
	tc.expect(t, v.type == n1_content.type, fmt.tprintf("%v: v.type %v != %v", #procedure, v.type, n1_content.type))
	tc.expect(t, len(v.resolution) == 3, fmt.tprintf("%v: len(v.resolution) %v != %v",
													 #procedure, len(v.resolution), 3))
	tc.expect(t, len(v.image_stack) == len(n1_content.image_stack), fmt.tprintf("%v: len(v.image_stack) %v != %v",
			  #procedure, len(v.image_stack), len(n1_content.image_stack)))
	for i := 0; i < len(v.image_stack); i += 1 {
		tc.expect(t, v.image_stack[i].name == n1_content.image_stack[i].name,
				  fmt.tprintf("%v: v.image_stack[%d].name %v != %v",
							  #procedure, i, v.image_stack[i].name, n1_content.image_stack[i].name))
		tc.expect(t, v.image_stack[i].components == n1_content.image_stack[i].components,
				  fmt.tprintf("%v: v.image_stack[%d].components %v != %v",
				  			  #procedure, i, v.image_stack[i].components, n1_content.image_stack[i].components))

		switch n1_t in n1_content.image_stack[i].data {
		case []u8:
			tc.expect(t, false, fmt.tprintf("%v: n1_content.image_stack[i].data []u8", #procedure))
		case []i32le:
			tc.expect(t, false, fmt.tprintf("%v: n1_content.image_stack[i].data []i32le", #procedure))
		case []f32le:
			l, l_ok := v.image_stack[i].data.([]f32le)
			tc.expect(t, l_ok, fmt.tprintf("%v: l_ok %v != %v", #procedure, l_ok, true))
			tc.expect(t, len(l) == len(n1_t), fmt.tprintf("%v: len(l) %v != %v", #procedure, len(l), len(n1_t)))
			for j := 0; j < len(l); j += 1 {
				tc.expect(t, l[j] == n1_t[j], fmt.tprintf("%v: l[%d] %v (%h) != %v (%h)",
														  #procedure, j, l[j], l[j], n1_t[j], n1_t[j]))
			}
		case []f64le:
			l, l_ok := v.image_stack[i].data.([]f64le)
			tc.expect(t, l_ok, fmt.tprintf("%v: l_ok %v != %v", #procedure, l_ok, true))
			tc.expect(t, len(l) == len(n1_t), fmt.tprintf("%v: len(l) %v != %v", #procedure, len(l), len(n1_t)))
			for j := 0; j < len(l); j += 1 {
				tc.expect(t, l[j] == n1_t[j], fmt.tprintf("%v: l[%d] %v != %v", #procedure, j, l[j], n1_t[j]))
			}
		}
	}
}
