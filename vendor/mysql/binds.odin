// file provides wrappers around the Bind datastructure that is used for prepared statements.
// bindp_* are procedures that should be used with mysql.stmt_bind_param, and bindr_* with mysql.stmt_bind_result.
// See for the C documentation: https://dev.mysql.com/doc/c-api/8.0/en/c-api-prepared-statement-data-structures.html
package mysql

import "core:c"
import "core:time"

@(private)
Bind_Nil :: Bind {
	buffer_type = .Null,
}

@(private)
not_nil := false
@(private)
is_nil := true

bindp_nil :: proc() -> Bind {
	return Bind_Nil
}

// Binds the given string to the parameter, returns a pointer to the length, which you should free later.
bindp_text :: proc(
	str: string,
	allocator := context.allocator,
) -> (
	bind: Bind,
	allocated_len: ^c.ulong,
) {
	str_len := new(c.ulong, allocator)
	str_len^ = c.ulong(len(str))

	return Bind{
			buffer_type = .String,
			buffer = raw_data(str),
			buffer_length = str_len^,
			length = str_len,
			is_null = &not_nil,
		},
		str_len
}
bindp_char :: bindp_text
bindp_var_char :: bindp_text

// Binds a buffer to write a result into, length_ptr will be set to the amount of bytes written into the buffer
// after having executed the statement.
//
// If you want to allocate a buffer of the exact length of the stored value, you can do the following:
//  stmt: mysql.Statement
//  rbinds := make([^]mysql.Bind, 1)
//  code_len: c.ulong
//  rbinds[0] = mysql.bindr_text(nil, &code_len)
//  mysql.stmt_bind_result(stmt, raw_data(rbinds))
//  mysql.stmt_store_result(stmt)
//  mysql.stmt_fetch(stmt) // After this call, code_len is set to the size of the stored value.
//
//  code_buf := make([]byte, code_len) // Creates the buffer with the right length.
//  rbinds[0].buffer = raw_data(code_buf)
//  rbinds[0].buffer_length = code_len
//  mysql.stmt_fetch_column(stmt, raw_data(rbinds), 0, 0) // Will write the column into buffer.
bindr_text :: proc(buf: []byte, length_ptr: ^c.ulong) -> Bind {
	return(
		Bind{
			buffer_type = .String,
			buffer = raw_data(buf),
			buffer_length = c.ulong(len(buf)),
			length = length_ptr,
		} \
	)
}
bindr_char :: bindr_text
bindr_var_char :: bindr_text

// Binds the given string to the parameter, returns a pointer to the length, which you should free later.
bindp_blob :: proc(
	str: string,
	allocator := context.allocator,
) -> (
	bind: Bind,
	allocated_len: ^c.ulong,
) {
	str_len := new(c.ulong, allocator)
	str_len^ = c.ulong(len(str))

	return Bind{
			buffer_type = .Blob,
			buffer = raw_data(str),
			buffer_length = str_len^,
			length = str_len,
			is_null = &not_nil,
		},
		str_len
}
bindp_binary :: bindp_blob
bindp_var_binary :: bindp_blob

// Binds a buffer to write a result into, length_ptr will be set to the amount of bytes written into the buffer
// after having executed the statement.
//
// If you want to allocate a buffer of the exact length of the stored value, you can do the following:
//  stmt: mysql.Statement
//  rbinds := make([^]mysql.Bind, 1)
//  code_len: c.ulong
//  rbinds[0] = mysql.bindr_text(nil, &code_len)
//  mysql.stmt_bind_result(stmt, raw_data(rbinds))
//  mysql.stmt_store_result(stmt)
//  mysql.stmt_fetch(stmt) // After this call, code_len is set to the size of the stored value.
//
//  code_buf := make([]byte, code_len) // Creates the buffer with the right length.
//  rbinds[0].buffer = raw_data(code_buf)
//  rbinds[0].buffer_length = code_len
//  mysql.stmt_fetch_column(stmt, raw_data(rbinds), 0, 0) // Will write the column into buffer.
bindr_blob :: proc(buf: []byte, length_ptr: ^c.ulong) -> Bind {
	return(
		Bind{
			buffer_type = .String,
			buffer = raw_data(buf),
			buffer_length = c.ulong(len(buf)),
			length = length_ptr,
		} \
	)
}
bindr_binary :: bindr_blob
bindr_var_binary :: bindr_blob

bindp_tiny_int :: proc(ch: ^c.char) -> Bind {
	return Bind{buffer_type = .Tiny, buffer = ch, is_null = ch == nil ? &is_nil : &not_nil}
}

bindr_tiny_int :: proc(i: ^c.char) -> Bind {
	return Bind{buffer_type = .Tiny, buffer = i}
}

bindp_small_int :: proc(i: ^c.short) -> Bind {
	return Bind{buffer_type = .Short, buffer = i, is_null = i == nil ? &is_nil : &not_nil}
}

bindr_small_int :: proc(i: ^c.short) -> Bind {
	return Bind{buffer_type = .Short, buffer = i}
}

bindp_int :: proc(i: ^c.int) -> Bind {
	return Bind{buffer_type = .Long, buffer = i, is_null = i == nil ? &is_nil : &not_nil}
}

bindr_int :: proc(i: ^c.int) -> Bind {
	return Bind{buffer_type = .Long, buffer = i}
}

bindp_big_int :: proc(i: ^c.longlong) -> Bind {
	return Bind{buffer_type = .Long_Long, buffer = i, is_null = i == nil ? &is_nil : &not_nil}
}

bindr_big_int :: proc(i: ^c.longlong) -> Bind {
	return Bind{buffer_type = .Long_Long, buffer = i}
}

bindp_float :: proc(i: ^c.float) -> Bind {
	return Bind{buffer_type = .Float, buffer = i, is_null = i == nil ? &is_nil : &not_nil}
}

bindr_float :: proc(i: ^c.float) -> Bind {
	return Bind{buffer_type = .Float, buffer = i}
}

bindp_double :: proc(i: ^c.double) -> Bind {
	return Bind{buffer_type = .Double, buffer = i, is_null = i == nil ? &is_nil : &not_nil}
}

bindr_double :: proc(i: ^c.double) -> Bind {
	return Bind{buffer_type = .Double, buffer = i}
}

bindp_time_mysql :: proc(t: ^Time, type: Time_Type) -> Bind {
	return Bind{buffer_type = time_to_buffer_type(type), buffer = t}
}

bindp_time_time :: proc(
	t: time.Time,
	type: Time_Type,
	allocator := context.allocator,
) -> (
	Bind,
	^Time,
) {
	mt := new(Time, allocator)
	time_from_time(mt, t, type)
	return bindp_time_mysql(mt, type), mt
}

bindp_time :: proc {
	bindp_time_mysql,
	bindp_time_time,
}

bindr_time_mysql :: proc(t: ^Time, type: Time_Type) -> Bind {
	return Bind{buffer_type = time_to_buffer_type(type), buffer = t}
}

@(private)
time_to_buffer_type :: proc(type: Time_Type) -> Buffer_Type {
	switch type {
	case .Time:
		return .Time
	case .Date_Time:
		return .Date_Time
	case .Timestamp:
		return .Timestamp
	case .Date:
		return .Date
	case:
		return nil
	}
}
