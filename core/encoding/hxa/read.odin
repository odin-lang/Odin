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

read_from_file :: proc(filename: string, print_error := false, allocator := context.allocator) -> (file: File, err: Read_Error) {
	context.allocator = allocator;

	data, ok := os.read_entire_file(filename);
	if !ok {
		err = .Unable_To_Read_File;
		return;
	}
	defer if !ok {
		delete(data);
	} else {
		file.backing = data;
	}
	file, err = read(data, filename, print_error, allocator);
	return;
}

read :: proc(data: []byte, filename := "<input>", print_error := false, allocator := context.allocator) -> (file: File, err: Read_Error) {
	Reader :: struct {
		filename:    string,
		data:        []byte,
		offset:      int,
		print_error: bool,
	};

	read_value :: proc(r: ^Reader, $T: typeid) -> (value: T, err: Read_Error) {
		remaining := len(r.data) - r.offset;
		if remaining < size_of(T) {
			err = .Short_Read;
			return;
		}
		ptr := raw_data(r.data[r.offset:]);
		value = (^T)(ptr)^;
		r.offset += size_of(T);
		return;
	}

	read_array :: proc(r: ^Reader, $T: typeid, count: int) -> (value: []T, err: Read_Error) {
		remaining := len(r.data) - r.offset;
		if remaining < size_of(T)*count {
			err = .Short_Read;
			return;
		}
		ptr := raw_data(r.data[r.offset:]);

		value = mem.slice_ptr((^T)(ptr), count);
		r.offset += size_of(T)*count;
		return;
	}

	read_string :: proc(r: ^Reader, count: int) -> (string, Read_Error) {
		buf, err := read_array(r, byte, count);
		return string(buf), err;
	}

	read_name :: proc(r: ^Reader) -> (value: string, err: Read_Error) {
		len: u8;
		data: []byte;
		len, err = read_value(r, u8);
		if err != nil {
			return;
		}
		data, err = read_array(r, byte, int(len));
		if err == nil {
			value = string(data[:len]);
		}
		return;
	}

	read_meta :: proc(r: ^Reader, capacity: u32le) -> (meta_data: []Meta, err: Read_Error) {
		meta_data = make([]Meta, int(capacity));
		count := 0;
		defer meta_data = meta_data[:count];
		for m in &meta_data {
			if m.name, err = read_name(r); err != nil { return };

			type: Meta_Value_Type;
			if type, err = read_value(r, Meta_Value_Type); err != nil { return }
			if type > max(Meta_Value_Type) {
				if r.print_error {
					fmt.eprintf("HxA Error: file '%s' has meta value type %d. Maximum value is ", r.filename, u8(type), u8(max(Meta_Value_Type)));
				}
				err = .Invalid_Data;
				return;
			}
			array_length: u32le;
			if array_length, err = read_value(r, u32le); err != nil { return }

			switch type {
			case .Int64:
				if m.value, err = read_array(r, i64le, int(array_length)); err != nil { return }
			case .Double:
				if m.value, err = read_array(r, f64le, int(array_length)); err != nil { return }
			case .Node:
				if m.value, err = read_array(r, Node_Index, int(array_length)); err != nil { return }
			case .Text:
				if m.value, err = read_string(r, int(array_length)); err != nil { return }
			case .Binary:
				if m.value, err = read_array(r, byte, int(array_length)); err != nil { return }
			case .Meta:
				if m.value, err = read_meta(r, array_length); err != nil { return }
			}

			count += 1;
		}
		return;
	}

	read_layer_stack :: proc(r: ^Reader, capacity: u32le) -> (layers: Layer_Stack, err: Read_Error) {
		stack_count: u32le;
		if stack_count, err = read_value(r, u32le); err != nil { return }
		layer_count := 0;
		layers = make(Layer_Stack, stack_count);
		defer layers = layers[:layer_count];
		for layer in &layers {
			type: Layer_Data_Type;
			if layer.name, err = read_name(r); err != nil { return }
			if layer.components, err = read_value(r, u8); err != nil { return }
			if type, err = read_value(r, Layer_Data_Type); err != nil { return }
			if type > max(type) {
				if r.print_error {
					fmt.eprintf("HxA Error: file '%s' has layer data type %d. Maximum value is ", r.filename, u8(type), u8(max(Layer_Data_Type)));
				}
				err = .Invalid_Data;
				return;
			}
			data_len := int(layer.components) * int(capacity);

			switch type {
			case .Uint8:  if layer.data, err = read_array(r, u8,    data_len); err != nil { return }
			case .Int32:  if layer.data, err = read_array(r, i32le, data_len); err != nil { return }
			case .Float:  if layer.data, err = read_array(r, f32le, data_len); err != nil { return }
			case .Double: if layer.data, err = read_array(r, f64le, data_len); err != nil { return }
			}
			layer_count += 1;
		}

		return;
	}

	if len(data) < size_of(Header) {
		return;
	}

	context.allocator = allocator;

	header := cast(^Header)raw_data(data);
	assert(header.magic_number == MAGIC_NUMBER);

	r := &Reader{
		filename    = filename,
		data        = data[:],
		offset      = size_of(Header),
		print_error = print_error,
	};

	node_count := 0;
	file.nodes = make([]Node, header.internal_node_count);
	defer if err != nil {
		nodes_destroy(file.nodes);
		file.nodes = nil;
	}
	defer file.nodes = file.nodes[:node_count];

	for node_idx in 0..<header.internal_node_count {
		node := &file.nodes[node_count];
		type: Node_Type;
		if type, err = read_value(r, Node_Type); err != nil { return }
		if type > max(Node_Type) {
			if r.print_error {
				fmt.eprintf("HxA Error: file '%s' has node type %d. Maximum value is ", r.filename, u8(type), u8(max(Node_Type)));
			}
			err = .Invalid_Data;
			return;
		}
		node_count += 1;

		meta_data_count: u32le;
		if meta_data_count, err = read_value(r, u32le); err != nil { return }
		if node.meta_data, err = read_meta(r, meta_data_count); err != nil { return }

		switch type {
		case .Meta_Only:
			// Okay
		case .Geometry:
			g: Node_Geometry;

			if g.vertex_count, err = read_value(r, u32le); err != nil { return }
			if g.vertex_stack, err = read_layer_stack(r, g.vertex_count); err != nil { return }
			if g.edge_corner_count, err = read_value(r, u32le); err != nil { return }
			if g.corner_stack, err = read_layer_stack(r, g.edge_corner_count); err != nil { return }
			if header.version > 2 {
				if g.edge_stack, err = read_layer_stack(r, g.edge_corner_count); err != nil { return }
			}
			if g.face_count, err = read_value(r, u32le); err != nil { return }
			if g.face_stack, err = read_layer_stack(r, g.face_count); err != nil { return }

			node.content = g;

		case .Image:
			img: Node_Image;

			if img.type, err = read_value(r, Image_Type); err != nil { return }
			dimensions := int(img.type);
			if img.type == .Image_Cube {
				dimensions = 2;
			}
			img.resolution = {1, 1, 1};
			for d in 0..<dimensions {
				if img.resolution[d], err = read_value(r, u32le); err != nil { return }
			}
			size := img.resolution[0]*img.resolution[1]*img.resolution[2];
			if img.type == .Image_Cube {
				size *= 6;
			}
			if img.image_stack, err = read_layer_stack(r, size); err != nil { return }

			node.content = img;
		}
	}

	return;
}
