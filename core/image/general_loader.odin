package image

import "core:mem"
import "core:os"

Loader_Proc :: #type proc(data: []byte, options: Options, allocator: mem.Allocator) -> (img: ^Image, err: Error)

@(private)
_internal_loaders: [Which_File_Type]Loader_Proc

register_loader :: proc(kind: Which_File_Type, loader: Loader_Proc) {
	assert(_internal_loaders[kind] == nil)
	_internal_loaders[kind] = loader
}

load :: proc{
	load_from_slice,
	load_from_file,
}

load_from_slice :: proc(data: []u8, options := Options{}, allocator := context.allocator) -> (img: ^Image, err: Error) {
	loader := _internal_loaders[which(data)]
	if loader == nil {
		return nil, .Unsupported_Format
	}
	return loader(data, options, allocator)
}


load_from_file :: proc(filename: string, options := Options{}, allocator := context.allocator) -> (img: ^Image, err: Error) {
	data, ok := os.read_entire_file(filename, allocator)
	defer delete(data, allocator)
	if ok {
		return load_from_slice(data, options, allocator)
	} else {
		img = new(Image, allocator)
		return img, .Unable_To_Read_File
	}
}
