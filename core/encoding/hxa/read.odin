package encoding_hxa

import "core:fmt"
import "core:os"
import "core:mem"

Read_Error :: enum {
	None,
	Short_Read,
	Invalid_Data,
	Unable_To_Read_File,
}

read_from_file :: proc(filename: string, print_error := false, allocator := context.allocator, loc := #caller_location) -> (file: File, err: Read_Error) {
	context.allocator = allocator

	data, ok := os.read_entire_file(filename, allocator, loc)
	if !ok {
		err = .Unable_To_Read_File
		delete(data, allocator, loc)
		return
	}
	file, err = read(data, filename, print_error, allocator, loc)
	file.backing   = data
	return
}

read :: proc(data: []byte, filename := "<input>", print_error := false, allocator := context.allocator, loc := #caller_location) -> (file: File, err: Read_Error) {
	Reader :: struct {
		filename:    string,
		data:        []byte,
		offset:      int,
		print_error: bool,
	}

	read_value :: proc(r: ^Reader, $T: typeid) -> (value: T, err: Read_Error) {
		remaining := len(r.data) - r.offset
		if remaining < size_of(T) {
			if r.print_error {
				fmt.eprintf("file '%s' failed to read value at offset %v\n", r.filename, r.offset)
			}
			err = .Short_Read
			return
		}
		ptr := raw_data(r.data[r.offset:])
		value = (^T)(ptr)^
		r.offset += size_of(T)
		return
	}

	read_array :: proc(r: ^Reader, $T: typeid, count: int) -> (value: []T, err: Read_Error) {
		remaining := len(r.data) - r.offset
		if remaining < size_of(T)*count {
			if r.print_error {
				fmt.eprintf("file '%s' failed to read array of %d elements at offset %v\n",
							r.filename, count, r.offset)
			}
			err = .Short_Read
			return
		}
		ptr := raw_data(r.data[r.offset:])

		value = mem.slice_ptr((^T)(ptr), count)
		r.offset += size_of(T)*count
		return
	}

	read_string :: proc(r: ^Reader, count: int) -> (string, Read_Error) {
		buf, err := read_array(r, byte, count)
		return string(buf), err
	}

	read_name :: proc(r: ^Reader) -> (value: string, err: Read_Error) {
		len  := read_value(r, u8)             or_return
		data := read_array(r, byte, int(len)) or_return
		return string(data[:len]), nil
	}

	read_meta :: proc(r: ^Reader, capacity: u32le, allocator := context.allocator, loc := #caller_location) -> (meta_data: []Meta, err: Read_Error) {
		meta_data = make([]Meta, int(capacity), allocator=allocator)
		count := 0
		defer meta_data = meta_data[:count]
		for &m in meta_data {
			m.name = read_name(r) or_return

			type := read_value(r, Meta_Value_Type) or_return
			if type > max(Meta_Value_Type) {
				if r.print_error {
					fmt.eprintf("HxA Error: file '%s' has meta value type %d. Maximum value is %d\n",
								r.filename, u8(type), u8(max(Meta_Value_Type)))
				}
				err = .Invalid_Data
				return
			}
			array_length := read_value(r, u32le) or_return

			switch type {
			case .Int64:  m.value = read_array(r, i64le, int(array_length))      or_return
			case .Double: m.value = read_array(r, f64le, int(array_length))      or_return
			case .Node:   m.value = read_array(r, Node_Index, int(array_length)) or_return
			case .Text:   m.value = read_string(r, int(array_length))            or_return
			case .Binary: m.value = read_array(r, byte, int(array_length))       or_return
			case .Meta:   m.value = read_meta(r, array_length)                   or_return
			}

			count += 1
		}
		return
	}

	read_layer_stack :: proc(r: ^Reader, capacity: u32le, allocator := context.allocator, loc := #caller_location) -> (layers: Layer_Stack, err: Read_Error) {
		stack_count := read_value(r, u32le) or_return
		layer_count := 0
		layers = make(Layer_Stack, stack_count, allocator=allocator, loc=loc)
		defer layers = layers[:layer_count]
		for &layer in layers {
			layer.name = read_name(r) or_return
			layer.components = read_value(r, u8) or_return
			type := read_value(r, Layer_Data_Type) or_return
			if type > max(Layer_Data_Type) {
				if r.print_error {
					fmt.eprintf("HxA Error: file '%s' has layer data type %d. Maximum value is %d\n",
								r.filename, u8(type), u8(max(Layer_Data_Type)))
				}
				err = .Invalid_Data
				return
			}
			data_len := int(layer.components) * int(capacity)

			switch type {
			case .Uint8:  layer.data = read_array(r, u8,    data_len) or_return
			case .Int32:  layer.data = read_array(r, i32le, data_len) or_return
			case .Float:  layer.data = read_array(r, f32le, data_len) or_return
			case .Double: layer.data = read_array(r, f64le, data_len) or_return
			}
			layer_count += 1
		}

		return
	}

	if len(data) < size_of(Header) {
		if print_error {
			fmt.eprintf("HxA Error: file '%s' has no header\n", filename)
		}
		err = .Short_Read
		return
	}

	context.allocator = allocator

	header := cast(^Header)raw_data(data)
	if (header.magic_number != MAGIC_NUMBER) {
		if print_error {
			fmt.eprintf("HxA Error: file '%s' has invalid magic number 0x%x\n", filename, header.magic_number)
		}
		err = .Invalid_Data
		return
	}

	r := &Reader{
		filename    = filename,
		data        = data[:],
		offset      = size_of(Header),
		print_error = print_error,
	}

	node_count := 0
	file.header = header^
	file.nodes = make([]Node, header.internal_node_count, allocator=allocator, loc=loc)
	file.allocator = allocator
	defer if err != nil {
		nodes_destroy(file.nodes)
		file.nodes = nil
	}
	defer file.nodes = file.nodes[:node_count]

	for _ in 0..<header.internal_node_count {
		node := &file.nodes[node_count]
		type := read_value(r, Node_Type) or_return
		if type > max(Node_Type) {
			if r.print_error {
				fmt.eprintf("HxA Error: file '%s' has node type %d. Maximum value is %d\n",
							r.filename, u8(type), u8(max(Node_Type)))
			}
			err = .Invalid_Data
			return
		}
		node_count += 1

		node.meta_data = read_meta(r, read_value(r, u32le) or_return) or_return

		switch type {
		case .Meta_Only:
			// Okay
		case .Geometry:
			g: Node_Geometry

			g.vertex_count      = read_value(r, u32le)                               or_return
			g.vertex_stack      = read_layer_stack(r, g.vertex_count, loc=loc)       or_return
			g.edge_corner_count = read_value(r, u32le)                               or_return
			g.corner_stack      = read_layer_stack(r, g.edge_corner_count, loc=loc)  or_return
			if header.version > 2 {
				g.edge_stack = read_layer_stack(r, g.edge_corner_count, loc=loc) or_return
			}
			g.face_count = read_value(r, u32le)                       or_return
			g.face_stack = read_layer_stack(r, g.face_count, loc=loc) or_return

			node.content = g

		case .Image:
			img: Node_Image

			img.type = read_value(r, Image_Type) or_return
			dimensions := int(img.type)
			if img.type == .Image_Cube {
				dimensions = 2
			}
			img.resolution = {1, 1, 1}
			for d in 0..<dimensions {
				img.resolution[d] = read_value(r, u32le) or_return
			}
			size := img.resolution[0]*img.resolution[1]*img.resolution[2]
			if img.type == .Image_Cube {
				size *= 6
			}
			img.image_stack = read_layer_stack(r, size) or_return

			node.content = img
		}
	}

	return
}