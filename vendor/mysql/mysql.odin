// package mysql contains bindings for libmysqlclient, targeting MySQL 8.x.
// Almost all referenced functions in the manual found here: https://dev.mysql.com/doc/c-api/8.0/en/
// have been added, excluding any deprecated functions and the client plugin system.
package mysql

import "core:c"

when ODIN_OS == .Darwin {
	foreign import lib "./includes/libmysqlclient.dylib"
} else {
	foreign import lib "system:mysqlclient"
}

// Opague structs, fields are never accessed (always through procedures),
// so no need to define them in bindings.
MySQL :: struct {}
Statement :: struct {}

Result :: struct {
	row_count:                  c.uint64_t,
	fields:                     [^]Field,
	data:                       ^Data,
	data_cursor:                ^Rows,
	lengths:                    [^]c.ulong,
	handle:                     ^MySQL,
	methods:                    rawptr,
	row:                        Row,
	current_row:                Row,
	field_alloc:                rawptr,
	field_count:                c.uint,
	current_field:              c.uint,
	eof:                        bool,
	unbuffered_fetch_cancelled: bool,
	metadata:                   Result_Metadata,
	extension:                  rawptr,
}

Data :: struct {
	data:   ^Rows,
	alloc:  rawptr,
	rows:   c.uint64_t,
	fields: c.uint,
}

// https://dev.mysql.com/doc/c-api/8.0/en/c-api-prepared-statement-data-structures.html
Bind :: struct {
	length:            ^c.ulong,
	is_null:           ^c.bool,
	buffer:            rawptr,
	error:             ^c.bool,
	_row_ptr:          ^c.uchar,
	_store_param_func: rawptr,
	_fetch_result:     rawptr,
	_skip_result:      rawptr,
	buffer_length:     c.ulong,
	_offset:           c.ulong,
	_length_value:     c.ulong,
	_param_number:     c.int,
	_pack_length:      c.int,
	buffer_type:       Buffer_Type,
	_error_value:      c.bool,
	is_unsigned:       c.bool,
	_long_data_used:   c.bool,
	_is_null_value:    c.bool,
	_extension:        rawptr,
}

// https://dev.mysql.com/doc/c-api/8.0/en/c-api-prepared-statement-type-codes.html
// https://github.com/paulfitz/mysql-connector-c/blob/8c058fab669d61a14ec23c714e09c8dfd3ec08cd/include/mysql_com.h#L309
Buffer_Type :: enum c.int {
	Decimal,
	Tiny,
	Short,
	Long,
	Float,
	Double,
	Null,
	Timestamp,
	Long_Long,
	Int24,
	Date,
	Time,
	Date_Time,
	Year,
	New_Date,
	Var_Char,
	Bit,
	New_Decimal = 246,
	Enum = 247,
	Set = 248,
	Tiny_Blob = 249,
	Medium_Blob = 250,
	Long_Blob = 251,
	Blob = 252,
	Var_String = 253,
	String = 254,
	Geometry = 255,
}

Option :: enum c.int {
	Opt_Connect_Timeout,
	Opt_Compress,
	Opt_Named_Pipe,
	Init_Command,
	Read_Default_File,
	Read_Default_Group,
	Set_Charset_Dir,
	Set_Charset_Name,
	Opt_Local_Infile,
	Opt_Protocol,
	Shared_Memory_Base_Name,
	Opt_Read_Timeout,
	Opt_Write_Timeout,
	Opt_Use_Result,
	Report_Data_Truncation,
	Opt_Reconnect,
	Plugin_Dir,
	Default_Auth,
	Opt_Bind,
	Opt_SSL_Key,
	Opt_SSL_Cert,
	Opt_SSL_CA,
	Opt_SSL_CA_Path,
	Opt_SSL_CA_Cipher,
	Opt_SSL_Crl,
	Opt_SSL_Crl_Path,
	Opt_Connect_Attr_Reset,
	Opt_Connect_Attr_Add,
	Opt_Connect_Attr_Delete,
	Server_Public_Key,
	Enable_Cleartext_Plugin,
	Opt_Can_Handle_Expired_Passwords,
	Opt_Max_Allowed_Packet,
	Opt_Net_Buffer_Length,
	Opt_TLS_Version,
	Opt_SSL_Mode,
	Opt_Get_Server_Public_Key,
	Opt_Retry_Count,
	Opt_Optional_Resultset_Metadata,
	Opt_SSL_Fips_Mode,
	Opt_TLS_Cipher_Suites,
	Opt_Compression_Algorithms,
	Opt_Zstd_Compression_Level,
	Opt_Load_Data_Local_Dir,
	Opt_User_Password,
	Opt_SSL_Session_Data,
}

Result_Metadata :: enum c.int {
	None = 0,
	Full = 1,
}

Session_State_Type :: enum c.int {
	Track_System_Variables,
	Track_Schema,
	Track_State_Change,
	Track_Gtids,
	Track_Transaction_Characteristics,
	Track_Transaction_State,
}

Server_Option :: enum c.int {
	Multi_Statements_On,
	Multi_Statements_Off,
}

Statement_Attr_Type :: enum c.int {
	Update_Max_Length,
	Cursor_Type,
	Prefetch_Rows,
}

Net_Async_Status :: enum c.int {
	Complete = 0,
	Not_Ready,
	Error,
	Complete_No_More_Results,
}

Field_Type :: enum c.int {
	Decimal,
	Tiny,
	Short,
	Long,
	Float,
	Double,
	Null,
	Timestamp,
	Long_Long,
	Int24,
	Date,
	Time,
	Date_Time,
	Year,
	New_Date,
	Var_Char,
	Bit,
	Timestamp2,
	Date_Time2,
	Time2,
	Typed_Array,
	Invalid = 243,
	Bool = 244,
	Json = 245,
	New_Decimal = 246,
	Enum = 247,
	Set = 248,
	Tiny_Blob = 249,
	Medium_Blob = 250,
	Long_Blob = 251,
	Blob = 252,
	Var_String = 253,
	String = 254,
	Geometry = 255,
}

Field :: struct {
	name:             cstring,
	org_name:         cstring,
	table:            cstring,
	org_table:        cstring,
	db:               cstring,
	catalog:          cstring,
	def:              cstring,
	length:           c.ulong,
	max_length:       c.ulong,
	name_length:      c.uint,
	org_name_length:  c.uint,
	table_length:     c.uint,
	org_table_length: c.uint,
	db_length:        c.uint,
	catalog_length:   c.uint,
	def_length:       c.uint,
	flags:            c.uint,
	decimals:         c.uint,
	charsetnr:        c.uint,
	type:             Field_Type,
	extension:        rawptr,
}

Field_Offset :: c.uint

Row :: [^]cstring

Rows :: struct {
	next:   ^Rows,
	data:   Row,
	length: c.ulong,
}

Row_Offset :: ^Rows

Charset_Info :: struct {
	number:     c.uint,
	state:      c.uint,
	csname:     cstring,
	name:       cstring,
	comment:    cstring,
	dir:        cstring,
	mb_min_len: c.uint,
	mb_max_len: c.uint,
}

Rpl :: struct {
	file_name_length:      c.size_t,
	file_name:             cstring,
	start_position:        c.uint64_t,
	server_id:             c.uint,
	flags:                 c.uint,
	gtid_set_encoded_size: c.size_t,
	fix_gtid_set:          proc(rpl: ^Rpl, packet_gtid_set: cstring),
	gtid_set_arg:          rawptr,
	size:                  c.ulong,
	buffer:                cstring,
}

@(link_prefix = "mysql_")
foreign lib {
	// https://dev.mysql.com/doc/c-api/8.0/en/mysql-affected-rows.html
	affected_rows :: proc(mysql: ^MySQL) -> c.uint64_t ---
	// https://dev.mysql.com/doc/c-api/8.0/en/mysql-autocommit.html
	autocommit :: proc(mysql: ^MySQL, mode: c.bool) -> c.bool ---
	// https://dev.mysql.com/doc/c-api/8.0/en/mysql-bind-param.html
	bind_param :: proc(mysql: ^MySQL, n_params: c.uint, bind: [^]Bind, name: [^]cstring) -> c.bool ---
	// https://dev.mysql.com/doc/c-api/8.0/en/mysql-change-user.html
	change_user :: proc(mysql: ^MySQL, user: cstring, password: cstring, db: cstring) -> c.bool ---
	// https://dev.mysql.com/doc/c-api/8.0/en/mysql-character-set-name.html
	character_set_name :: proc(mysql: ^MySQL) -> cstring ---
	// https://dev.mysql.com/doc/c-api/8.0/en/mysql-close.html
	close :: proc(mysql: ^MySQL) ---
	// https://dev.mysql.com/doc/c-api/8.0/en/mysql-commit.html
	commit :: proc(mysql: ^MySQL) -> c.bool ---
	// https://dev.mysql.com/doc/c-api/8.0/en/mysql-real-connect.html
	@(link_name = "mysql_real_connect")
	connect :: proc(mysql: ^MySQL, host: cstring, user: cstring, passwd: cstring, db: cstring, port: c.uint = 0, unix_socket: cstring = nil, client_flag: c.ulong = 0) -> ^MySQL ---
	// https://dev.mysql.com/doc/c-api/8.0/en/mysql-real-connect-dns-srv.html
	@(link_name = "mysql_real_connect_dns_srv")
	connect_dns_srv :: proc(mysql: ^MySQL, dns_srv_name: cstring, user: cstring, passwd: cstring, db: cstring, client_flag: c.ulong = 0) -> ^MySQL ---
	// https://dev.mysql.com/doc/c-api/8.0/en/mysql-data-seek.html
	data_seek :: proc(result: ^Result, offset: c.uint64_t) ---
	// https://dev.mysql.com/doc/c-api/8.0/en/mysql-dump-debug-info.html
	dump_debug_info :: proc(mysql: ^MySQL) -> c.int ---
	// https://dev.mysql.com/doc/c-api/8.0/en/mysql-errno.html
	errno :: proc(mysql: ^MySQL) -> Errno ---
	// https://dev.mysql.com/doc/c-api/8.0/en/mysql-error.html
	error :: proc(mysql: ^MySQL) -> cstring ---
	// https://dev.mysql.com/doc/c-api/8.0/en/mysql-real-escape-string.html
	@(link_name = "mysql_real_escape_string")
	escape_string :: proc(mysql: ^MySQL, to: [^]byte, from: cstring, length: c.ulong) -> c.ulong ---
	// https://dev.mysql.com/doc/c-api/8.0/en/mysql-real-escape-string-quote.html
	@(link_name = "mysql_real_escape_string_quote")
	escape_string_quote :: proc(mysql: ^MySQL, to: [^]byte, from: cstring, length: c.ulong, quote: c.char) -> c.ulong ---
	// https://dev.mysql.com/doc/c-api/8.0/en/mysql-fetch-field.html
	fetch_field :: proc(result: ^Result) -> ^Field ---
	// https://dev.mysql.com/doc/c-api/8.0/en/mysql-fetch-field-direct.html
	fetch_field_direct :: proc(result: ^Result, fieldnr: c.uint) -> ^Field ---
	// https://dev.mysql.com/doc/c-api/8.0/en/mysql-fetch-fields.html
	fetch_fields :: proc(result: ^Result) -> [^]Field ---
	// https://dev.mysql.com/doc/c-api/8.0/en/mysql-fetch-lengths.html
	fetch_lengths :: proc(result: ^Result) -> [^]c.ulong ---
	// https://dev.mysql.com/doc/c-api/8.0/en/mysql-fetch-row.html
	fetch_row :: proc(result: ^Result) -> Row ---
	// https://dev.mysql.com/doc/c-api/8.0/en/mysql-field-count.html
	field_count :: proc(mysql: ^MySQL) -> c.uint ---
	// https://dev.mysql.com/doc/c-api/8.0/en/mysql-field-seek.html
	field_seek :: proc(result: ^Result, offset: Field_Offset) -> Field_Offset ---
	// https://dev.mysql.com/doc/c-api/8.0/en/mysql-field-tell.html
	field_tell :: proc(result: ^Result) -> Field_Offset ---
	// https://dev.mysql.com/doc/c-api/8.0/en/mysql-free-result.html
	free_result :: proc(result: ^Result) ---
	// https://dev.mysql.com/doc/c-api/8.0/en/mysql-free-ssl-session-data.html
	free_ssl_session_data :: proc(mysql: ^MySQL, data: rawptr) -> c.bool ---
	// https://dev.mysql.com/doc/c-api/8.0/en/mysql-get-character-set-info.html
	get_character_set_info :: proc(mysql: ^MySQL, info: ^Charset_Info) ---
	// https://dev.mysql.com/doc/c-api/8.0/en/mysql-get-client-info.html
	get_client_info :: proc() -> cstring ---
	// https://dev.mysql.com/doc/c-api/8.0/en/mysql-get-client-version.html
	get_client_version :: proc() -> c.ulong ---
	// https://dev.mysql.com/doc/c-api/8.0/en/mysql-get-host-info.html
	get_host_info :: proc(mysql: ^MySQL) -> cstring ---
	// https://dev.mysql.com/doc/c-api/8.0/en/mysql-get-option.html
	get_option :: proc(mysql: ^MySQL, option: Option, arg: rawptr) -> c.int ---
	// https://dev.mysql.com/doc/c-api/8.0/en/mysql-get-proto-info.html
	get_proto_info :: proc(mysql: ^MySQL) -> c.uint ---
	// https://dev.mysql.com/doc/c-api/8.0/en/mysql-get-server-info.html
	get_server_info :: proc(mysql: ^MySQL) -> cstring ---
	// https://dev.mysql.com/doc/c-api/8.0/en/mysql-get-server-version.html
	get_server_version :: proc(mysql: ^MySQL) -> c.ulong ---
	// https://dev.mysql.com/doc/c-api/8.0/en/mysql-get-ssl-cipher.html
	get_ssl_cypher :: proc(mysql: ^MySQL) -> cstring ---
	// https://dev.mysql.com/doc/c-api/8.0/en/mysql-get-ssl-session-data.html
	get_ssl_session_data :: proc(mysql: ^MySQL, n_ticket: c.uint, out_len: ^c.uint) -> rawptr ---
	// https://dev.mysql.com/doc/c-api/8.0/en/mysql-get-ssl-session-reused.html
	get_ssl_session_reused :: proc(mysql: ^MySQL) -> c.bool ---
	// https://dev.mysql.com/doc/c-api/8.0/en/mysql-info.html
	info :: proc(mysql: ^MySQL) -> cstring ---
	// https://dev.mysql.com/doc/c-api/8.0/en/mysql-init.html
	init :: proc(mysql: ^MySQL = nil) -> ^MySQL ---
	// https://dev.mysql.com/doc/c-api/8.0/en/mysql-insert-id.html
	insert_id :: proc(mysql: ^MySQL) -> c.uint64_t ---
	// https://dev.mysql.com/doc/c-api/8.0/en/mysql-library-end.html
	library_end :: proc() ---
	// https://dev.mysql.com/doc/c-api/8.0/en/mysql-library-init.html
	library_init :: proc(argc: c.int, argv: [^]cstring, groups: [^]cstring) -> c.int ---
	// https://dev.mysql.com/doc/c-api/8.0/en/mysql-list-dbs.html
	list_dbs :: proc(mysql: ^MySQL, wild: cstring) -> ^Result ---
	// https://dev.mysql.com/doc/c-api/8.0/en/mysql-list-tables.html
	list_tables :: proc(mysql: ^MySQL, wild: cstring) -> ^Result ---
	// https://dev.mysql.com/doc/c-api/8.0/en/mysql-more-results.html
	more_results :: proc(mysql: ^MySQL) -> c.bool ---
	// https://dev.mysql.com/doc/c-api/8.0/en/mysql-next-result.html
	next_result :: proc(mysql: ^MySQL) -> c.int ---
	// https://dev.mysql.com/doc/c-api/8.0/en/mysql-num-fields.html
	num_fields :: proc(result: ^Result) -> c.uint ---
	// https://dev.mysql.com/doc/c-api/8.0/en/mysql-num-rows.html
	num_rows :: proc(result: ^Result) -> c.uint64_t ---
	// https://dev.mysql.com/doc/c-api/8.0/en/mysql-options.html
	options :: proc(mysql: ^MySQL, option: Option, arg: rawptr) -> c.int ---
	// https://dev.mysql.com/doc/c-api/8.0/en/mysql-options4.html
	options4 :: proc(mysql: ^MySQL, option: Option, arg1: rawptr, arg2: rawptr) -> c.int ---
	// https://dev.mysql.com/doc/c-api/8.0/en/mysql-ping.html
	ping :: proc(mysql: ^MySQL) -> c.int ---
	// https://dev.mysql.com/doc/c-api/8.0/en/mysql-query.html
	@(link_name = "mysql_real_query")
	query :: proc(mysql: ^MySQL, stmt_str: cstring, length: c.ulong) -> c.int ---
	// https://dev.mysql.com/doc/c-api/8.0/en/mysql-reload.html
	reload :: proc(mysql: ^MySQL) -> c.int ---
	// https://dev.mysql.com/doc/c-api/8.0/en/mysql-reset-connection.html
	reset_connection :: proc(mysql: ^MySQL) -> c.int ---
	// https://dev.mysql.com/doc/c-api/8.0/en/mysql-reset-server-public-key.html
	reset_server_public_key :: proc() ---
	// https://dev.mysql.com/doc/c-api/8.0/en/mysql-result-metadata.html
	result_metadata :: proc(result: ^Result) -> Result_Metadata ---
	// https://dev.mysql.com/doc/c-api/8.0/en/mysql-rollback.html
	rollback :: proc(mysql: ^MySQL) -> c.bool ---
	// https://dev.mysql.com/doc/c-api/8.0/en/mysql-row-seek.html
	row_seek :: proc(result: ^Result, offset: Row_Offset) -> Row_Offset ---
	// https://dev.mysql.com/doc/c-api/8.0/en/mysql-row-tell.html
	row_tell :: proc(result: ^Result) -> Row_Offset ---
	// https://dev.mysql.com/doc/c-api/8.0/en/mysql-select-db.html
	select_db :: proc(mysql: ^MySQL, db: cstring) -> c.int ---
	// https://dev.mysql.com/doc/c-api/8.0/en/mysql-session-track-get-first.html
	session_track_get_first :: proc(mysql: ^MySQL, type: Session_State_Type, data: ^cstring, length: ^c.size_t) -> c.int ---
	// https://dev.mysql.com/doc/c-api/8.0/en/mysql-session-track-get-next.html
	session_track_get_next :: proc(mysql: ^MySQL, type: Session_State_Type, data: ^cstring, length: ^c.size_t) -> c.int ---
	// https://dev.mysql.com/doc/c-api/8.0/en/mysql-set-character-set.html
	set_character_set :: proc(mysql: ^MySQL, cs_name: cstring) -> c.int ---
	// https://dev.mysql.com/doc/c-api/8.0/en/mysql-set-local-infile-default.html
	set_local_infile_default :: proc(mysql: ^MySQL) ---
	// https://dev.mysql.com/doc/c-api/8.0/en/mysql-set-local-infile-handler.html
	set_local_infile_handler :: proc(mysql: ^MySQL, local_infile_init: proc "cdecl" (ptr: ^rawptr, filename: cstring, user_data: rawptr) -> c.int, local_infile_read: proc "cdecl" (ptr: rawptr, buf: cstring, buf_len: c.uint) -> c.int, local_infile_end: proc "cdecl" (ptr: rawptr), local_infile_error: proc "cdecl" (ptr: rawptr, error_msg: cstring, error_msg_len: c.uint) -> c.int, user_data: rawptr) ---
	// https://dev.mysql.com/doc/c-api/8.0/en/mysql-set-server-option.html
	set_server_option :: proc(mysql: ^MySQL, option: Server_Option) -> c.int ---
	// https://dev.mysql.com/doc/c-api/8.0/en/mysql-sqlstate.html
	sqlstate :: proc(mysql: ^MySQL) -> cstring ---
	// https://dev.mysql.com/doc/c-api/8.0/en/mysql-ssl-set.html
	ssl_set :: proc(mysql: ^MySQL, key: cstring, cert: cstring, ca: cstring, capath: cstring, cipher: cstring) -> c.bool ---
	// https://dev.mysql.com/doc/c-api/8.0/en/mysql-stat.html
	stat :: proc(mysql: ^MySQL) -> cstring ---
	// https://dev.mysql.com/doc/c-api/8.0/en/mysql-store-result.html
	store_result :: proc(mysql: ^MySQL) -> ^Result ---
	// https://dev.mysql.com/doc/c-api/8.0/en/mysql-thread-id.html
	thread_id :: proc(mysql: ^MySQL) -> c.ulong ---
	// https://dev.mysql.com/doc/c-api/8.0/en/mysql-use-result.html
	use_result :: proc(mysql: ^MySQL) -> ^Result ---
	// https://dev.mysql.com/doc/c-api/8.0/en/mysql-warning-count.html
	warning_count :: proc(mysql: ^MySQL) -> c.uint ---

	// https://dev.mysql.com/doc/c-api/8.0/en/mysql-stmt-affected-rows.html
	stmt_affected_rows :: proc(stmt: ^Statement) -> c.uint64_t ---
	// https://dev.mysql.com/doc/c-api/8.0/en/mysql-stmt-attr-get.html
	stmt_attr_get :: proc(stmt: ^Statement, option: Statement_Attr_Type, arg: rawptr) -> c.bool ---
	// https://dev.mysql.com/doc/c-api/8.0/en/mysql-stmt-attr-set.html
	stmt_attr_set :: proc(stmt: ^Statement, option: Statement_Attr_Type, arg: rawptr) -> c.bool ---
	// https://dev.mysql.com/doc/c-api/8.0/en/mysql-stmt-bind-param.html
	stmt_bind_param :: proc(stmt: ^Statement, bind: [^]Bind) -> c.bool ---
	// https://dev.mysql.com/doc/c-api/8.0/en/mysql-stmt-bind-result.html
	stmt_bind_result :: proc(stmt: ^Statement, bind: [^]Bind) -> c.bool ---
	// https://dev.mysql.com/doc/c-api/8.0/en/mysql-stmt-close.html
	stmt_close :: proc(stmt: ^Statement) -> c.bool ---
	// https://dev.mysql.com/doc/c-api/8.0/en/mysql-stmt-data-seek.html
	stmt_data_seek :: proc(stmt: ^Statement, offset: c.uint64_t) ---
	// https://dev.mysql.com/doc/c-api/8.0/en/mysql-stmt-errno.html
	stmt_errno :: proc(stmt: ^Statement) -> Errno ---
	// https://dev.mysql.com/doc/c-api/8.0/en/mysql-stmt-error.html
	stmt_error :: proc(stmt: ^Statement) -> cstring ---
	// https://dev.mysql.com/doc/c-api/8.0/en/mysql-stmt-execute.html
	stmt_execute :: proc(stmt: ^Statement) -> c.int ---
	// https://dev.mysql.com/doc/c-api/8.0/en/mysql-stmt-fetch.html
	stmt_fetch :: proc(stmt: ^Statement) -> c.int ---
	// https://dev.mysql.com/doc/c-api/8.0/en/mysql-stmt-fetch-column.html
	stmt_fetch_column :: proc(stmt: ^Statement, bind: ^Bind, column: c.uint, offset: c.ulong) -> c.int ---
	// https://dev.mysql.com/doc/c-api/8.0/en/mysql-stmt-field-count.html
	stmt_field_count :: proc(stmt: ^Statement) -> c.uint ---
	// https://dev.mysql.com/doc/c-api/8.0/en/mysql-stmt-free-result.html
	stmt_free_result :: proc(stmt: ^Statement) -> c.bool ---
	// https://dev.mysql.com/doc/c-api/8.0/en/mysql-stmt-init.html
	stmt_init :: proc(mysql: ^MySQL) -> ^Statement ---
	// https://dev.mysql.com/doc/c-api/8.0/en/mysql-stmt-insert-id.html
	stmt_insert_id :: proc(stmt: ^Statement) -> c.uint64_t ---
	// https://dev.mysql.com/doc/c-api/8.0/en/mysql-stmt-next-result.html
	stmt_next_result :: proc(stmt: ^Statement) -> c.int ---
	// https://dev.mysql.com/doc/c-api/8.0/en/mysql-stmt-num-rows.html
	stmt_num_rows :: proc(stmt: ^Statement) -> c.uint64_t ---
	// https://dev.mysql.com/doc/c-api/8.0/en/mysql-stmt-param-count.html
	stmt_param_count :: proc(stmt: ^Statement) -> c.ulong ---
	// https://dev.mysql.com/doc/c-api/8.0/en/mysql-stmt-param-metadata.html
	stmt_param_metadata :: proc(stmt: ^Statement) -> ^Result ---
	// https://dev.mysql.com/doc/c-api/8.0/en/mysql-stmt-prepare.html
	stmt_prepare :: proc(stmt: ^Statement, stmt_str: cstring, stmt_str_len: c.ulong) -> c.int ---
	// https://dev.mysql.com/doc/c-api/8.0/en/mysql-stmt-reset.html
	stmt_reset :: proc(stmt: ^Statement) -> c.bool ---
	// https://dev.mysql.com/doc/c-api/8.0/en/mysql-stmt-result-metadata.html
	stmt_result_metadata :: proc(stmt: ^Statement) -> ^Result ---
	// https://dev.mysql.com/doc/c-api/8.0/en/mysql-stmt-row-seek.html
	stmt_row_seek :: proc(stmt: ^Statement, offset: Row_Offset) -> Row_Offset ---
	// https://dev.mysql.com/doc/c-api/8.0/en/mysql-stmt-row-tell.html
	stmt_row_tell :: proc(stmt: ^Statement) -> Row_Offset ---
	// https://dev.mysql.com/doc/c-api/8.0/en/mysql-stmt-send-long-data.html
	stmt_send_long_data :: proc(stmt: ^Statement, parameter_number: c.uint, data: cstring, length: c.ulong) -> c.bool ---
	// https://dev.mysql.com/doc/c-api/8.0/en/mysql-stmt-sqlstate.html
	stmt_sqlstate :: proc(stmt: ^Statement) -> cstring ---
	// https://dev.mysql.com/doc/c-api/8.0/en/mysql-stmt-store-result.html
	stmt_store_result :: proc(stmt: ^Statement) -> c.int ---

	// https://dev.mysql.com/doc/c-api/8.0/en/mysql-fetch-row-nonblocking.html
	fetch_row_nonblocking :: proc(result: ^Result, row: ^Row) -> Net_Async_Status ---
	// https://dev.mysql.com/doc/c-api/8.0/en/mysql-free-result-nonblocking.html
	free_result_nonblocking :: proc(result: ^Result) -> Net_Async_Status ---
	// https://dev.mysql.com/doc/c-api/8.0/en/mysql-next-result-nonblocking.html
	next_result_nonblocking :: proc(mysql: ^MySQL) -> Net_Async_Status ---
	// https://dev.mysql.com/doc/c-api/8.0/en/mysql-real-connect-nonblocking.html
	@(link_name = "mysql_real_connect_nonblocking")
	connect_nonblocking :: proc(mysql: ^MySQL, host: cstring, user: cstring, passwd: cstring, db: cstring, port: c.uint = 0, unix_socket: cstring = nil, client_flag: c.ulong = 0) -> Net_Async_Status ---
	// https://dev.mysql.com/doc/c-api/8.0/en/mysql-real-query-nonblocking.html
	@(link_name = "mysql_real_query_nonblocking")
	query_nonblocking :: proc(mysql: ^MySQL, stmt: cstring, length: c.ulong) -> Net_Async_Status ---
	// https://dev.mysql.com/doc/c-api/8.0/en/mysql-store-result-nonblocking.html
	store_result_nonblocking :: proc(mysql: ^MySQL, result: ^^Result) -> Net_Async_Status ---

	// https://dev.mysql.com/doc/c-api/8.0/en/mysql-thread-end.html
	thread_end :: proc() ---
	// https://dev.mysql.com/doc/c-api/8.0/en/mysql-thread-init.html
	thread_init :: proc() -> c.bool ---
	// https://dev.mysql.com/doc/c-api/8.0/en/mysql-thread-safe.html
	thread_safe :: proc() -> c.uint ---

	// https://dev.mysql.com/doc/c-api/8.0/en/mysql-binlog-close.html
	binlog_close :: proc(mysql: ^MySQL, rpl: ^Rpl) ---
	// https://dev.mysql.com/doc/c-api/8.0/en/mysql-binlog-fetch.html
	binlog_fetch :: proc(mysql: ^MySQL, rpl: ^Rpl) -> c.int ---
	// https://dev.mysql.com/doc/c-api/8.0/en/mysql-binlog-open.html
	binlog_open :: proc(mysql: ^MySQL, rpl: ^Rpl) -> c.int ---
}
