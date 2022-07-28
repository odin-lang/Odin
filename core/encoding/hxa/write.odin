package encoding_hxa

import "core:os"
import "core:mem"

Write_Error :: enum {
	None,
	Buffer_Too_Small,
	Failed_File_Write,
}

write_to_file :: proc(filepath: string, file: File) -> (err: Write_Error) {
	required := required_write_size(file)
	buf, alloc_err := make([]byte, required)
	if alloc_err == .Out_Of_Memory {
		return .Failed_File_Write
	}
	defer delete(buf)

	write_internal(&Writer{data = buf}, file)
	if !os.write_entire_file(filepath, buf) {
		err =.Failed_File_Write
	}
	return
}

write :: proc(buf: []byte, file: File) -> (n: int, err: Write_Error) {
	required := required_write_size(file)
	if len(buf) < required {
		err = .Buffer_Too_Small
		return
	}
	n = required
	write_internal(&Writer{data = buf}, file)
	return
}

required_write_size :: proc(file: File) -> (n: int) {
	writer := &Writer{dummy_pass = true}
	write_internal(writer, file)
	n = writer.offset
	return
}


@(private)
Writer :: struct {
	data:   []byte,
	offset: int,
	dummy_pass: bool,
}

@(private)
write_internal :: proc(w: ^Writer, file: File) {
	write_value :: proc(w: ^Writer, value: $T) {
		if !w.dummy_pass {
			remaining := len(w.data) - w.offset
			assert(size_of(T) <= remaining)
			ptr := raw_data(w.data[w.offset:])
			(^T)(ptr)^ = value
		}
		w.offset += size_of(T)
	}
	write_array :: proc(w: ^Writer, array: []$T) {
		if !w.dummy_pass {
			remaining := len(w.data) - w.offset
			assert(size_of(T)*len(array) <= remaining)
			ptr := raw_data(w.data[w.offset:])
			dst := mem.slice_ptr((^T)(ptr), len(array))
			copy(dst, array)
		}
		w.offset += size_of(T)*len(array)
	}
	write_string :: proc(w: ^Writer, str: string) {
		if !w.dummy_pass {
			remaining := len(w.data) - w.offset
			assert(size_of(byte)*len(str) <= remaining)
			ptr := raw_data(w.data[w.offset:])
			dst := mem.slice_ptr((^byte)(ptr), len(str))
			copy(dst, str)
		}
		w.offset += size_of(byte)*len(str)
	}

	write_metadata :: proc(w: ^Writer, meta_data: []Meta) {
		for m in meta_data {
			name_len := min(len(m.name), 255)
			write_value(w, u8(name_len))
			write_string(w, m.name[:name_len])

			meta_data_type: Meta_Value_Type
			length: u32le = 0
			switch v in m.value {
			case []i64le:
				meta_data_type = .Int64
				length = u32le(len(v))
			case []f64le:
				meta_data_type = .Double
				length = u32le(len(v))
			case []Node_Index:
				meta_data_type = .Node
				length = u32le(len(v))
			case string:
				meta_data_type = .Text
				length = u32le(len(v))
			case []byte:
				meta_data_type = .Binary
				length = u32le(len(v))
			case []Meta:
				meta_data_type = .Meta
				length = u32le(len(v))
			}
			write_value(w, meta_data_type)
			write_value(w, length)

			switch v in m.value {
			case []i64le:      write_array(w, v)
			case []f64le:      write_array(w, v)
			case []Node_Index: write_array(w, v)
			case string:       write_string(w, v)
			case []byte:       write_array(w, v)
			case []Meta:       write_metadata(w, v)
			}
		}
		return
	}
	write_layer_stack :: proc(w: ^Writer, layers: Layer_Stack) {
		write_value(w, u32(len(layers)))
		for layer in layers {
			name_len := min(len(layer.name), 255)
			write_value(w, u8(name_len))
			write_string(w, layer .name[:name_len])

			write_value(w, layer.components)

			layer_data_type: Layer_Data_Type
			switch v in layer.data {
			case []u8:    layer_data_type = .Uint8
			case []i32le: layer_data_type = .Int32
			case []f32le: layer_data_type = .Float
			case []f64le: layer_data_type = .Double
			}
			write_value(w, layer_data_type)

			switch v in layer.data {
			case []u8:   write_array(w, v)
			case []i32le: write_array(w, v)
			case []f32le: write_array(w, v)
			case []f64le: write_array(w, v)
			}
		}
		return
	}

	write_value(w, Header{
		magic_number = MAGIC_NUMBER,
		version = LATEST_VERSION,
		internal_node_count = u32le(len(file.nodes)),
	})

	for node in file.nodes {
		node_type: Node_Type
		switch content in node.content {
		case Node_Geometry: node_type = .Geometry
		case Node_Image:    node_type = .Image
		}
		write_value(w, node_type)

		write_value(w, u32(len(node.meta_data)))
		write_metadata(w, node.meta_data)

		switch content in node.content {
		case Node_Geometry:
			write_value(w, content.vertex_count)
			write_layer_stack(w, content.vertex_stack)
			write_value(w, content.edge_corner_count)
			write_layer_stack(w, content.corner_stack)
			write_layer_stack(w, content.edge_stack)
			write_value(w, content.face_count)
			write_layer_stack(w, content.face_stack)
		case Node_Image:
			write_value(w, content.type)
			dimensions := int(content.type)
			if content.type == .Image_Cube {
				dimensions = 2
			}
			for d in 0..<dimensions {
				write_value(w, content.resolution[d])
			}
			write_layer_stack(w, content.image_stack)
		}
	}
}
