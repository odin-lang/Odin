package encoding_ini

import "base:runtime"
import "core:io"

Options :: struct {
	comment: string,
	key_lower_case: bool,
	keep_empty_sections: bool,
}

DEFAULT_OPTIONS :: Options {
	comment = ";",
	key_lower_case = false,
	keep_empty_sections = false,
}

Iterator :: struct {
	section: string,
	_src:    string,
	options: Options,
}

Map :: distinct map[string]map[string]string

Error :: union #shared_nil {
	runtime.Allocator_Error,
	io.Error,
	Write_Error,
}

Write_Error :: enum {
	None,
	Invalid_Section_Name,
}

@(private)
Error_Writer :: struct {
	w:   io.Writer,
	err: io.Error,
}
