package ucd

/*
An iterator that allows simple iterating over the lines of of a slice of bytes, []byte,
without allocating. Each line must end in a new line, i.e., '\n'
*/
Line_Iterator :: struct {
	index: int, // current location in data
	data: []byte, // Data over which to iterate
	line_counter: int, // line number storage  
}

line_iterator :: proc(it: ^Line_Iterator) -> (line: []byte, line_number: int,  more: bool) {
	more = it.index < len(it.data)
	if more {
		it.line_counter += 1
		line_number = it.line_counter
	} else {
		return
	}	
	start:= it.index
	for it.index < len(it.data) && it.data[it.index] != '\n' && it.data[it.index] != '#' do it.index += 1
	line = it.data[start:it.index]
	//index = start

	if it.index < len(it.data) && it.data[it.index] == '#' {
		for it.index < len(it.data) && it.data[it.index] != '\n' do it.index += 1
	}
	if it.index < len(it.data) && it.data[it.index] == '\n' do it.index += 1
	return
}

Field_Iterator :: struct {
	index: int,
	field_counter: int,
	line: []byte,
}

field_iterator :: proc(it: ^Field_Iterator) -> (field: []byte, field_count: int,  valid: bool) {
	valid = it.index < len(it.line) && it.line[it.index] != '\n' && it.line[it.index] != '#'
	if !valid do return

	if it.index < len(it.line) && it.index != 0 && it.line[it.index] == ';' do it. index += 1

	start := it.index
	for it.index < len(it.line) && it.line[it.index] != ';'  && it.line[it.index] != '#' do it.index += 1

	field = it.line[start:it.index]	
	temp := field

	// Remove leading spaces
	for b, i in temp {
		if b != ' ' {
			field = temp[i:]
			break
		}
	}

	// Remove trailing spaces
	temp = field
	for b, i in temp {
		if b != ' ' {
			field = temp[0:i+1]
		}
	}

	field_count = it.field_counter
	it.field_counter += 1
	return
}
