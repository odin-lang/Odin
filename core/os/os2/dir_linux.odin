//+private
package os2

Read_Directory_Iterator_Impl :: struct {

}


@(require_results)
_read_directory_iterator :: proc(it: ^Read_Directory_Iterator) -> (fi: File_Info, index: int, ok: bool) {
	return
}

@(require_results)
_read_directory_iterator_create :: proc(f: ^File) -> (Read_Directory_Iterator, Error) {
	return {}, nil
}

_read_directory_iterator_destroy :: proc(it: ^Read_Directory_Iterator) {
}
