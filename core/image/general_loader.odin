package image

import "core:mem"
import "core:os"

Loader_Proc :: #type proc(data: []byte, options: Options, allocator: mem.Allocator) -> (img: ^Image, err: Error)
Destroy_Proc :: #type proc(img: ^Image)

@(private)
_internal_loaders: [Which_File_Type]Loader_Proc
_internal_destroyers: [Which_File_Type]Destroy_Proc

register :: proc(kind: Which_File_Type, loader: Loader_Proc, destroyer: Destroy_Proc) {
	assert(loader != nil)
	assert(destroyer != nil)
	assert(_internal_loaders[kind] == nil)
	_internal_loaders[kind] = loader

	assert(_internal_destroyers[kind] == nil)
	_internal_destroyers[kind] = destroyer
}

load :: proc{
	load_from_bytes,
	load_from_file,
}

load_from_bytes :: proc(data: []byte, options := Options{}, allocator := context.allocator) -> (img: ^Image, err: Error) {
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
		return load_from_bytes(data, options, allocator)
	} else {
		return nil, .Unable_To_Read_File
	}
}

destroy :: proc(img: ^Image, allocator := context.allocator) -> bool {
	if img == nil {
		return true
	}
	context.allocator = allocator
	destroyer := _internal_destroyers[img.which]
	if destroyer != nil {
		destroyer(img)
	} else {
		assert(img.metadata == nil)
		free(img)
	}
	return true
}