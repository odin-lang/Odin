// Filename: sqlite3.odin
// Version: v4.0
/*
	zlib License

	Copyright (c) 2024-2026 Odin Language Contributors

	This software is provided 'as-is', without any express or implied
	warranty.  In no event will the authors be held liable for any damages
	arising from the use of this software.

	Permission is granted to anyone to use this software for any purpose,
	including commercial applications, and to alter it and redistribute it
	freely, subject to the following restrictions:

	1. The origin of this software must not be misrepresented; you must not
	   claim that you wrote the original software. If you use this software
	   in a product, an acknowledgment in the product documentation would be
	   appreciated but is not required.
	2. Altered source versions must be plainly marked as such, and must not be
	   misrepresented as being the original software.
	3. This notice may not be removed or altered from any source distribution.
*/
package sqlite

import "core:c"
import "core:fmt"
import "core:mem"

when ODIN_OS == .Windows {
	foreign import sqlite "sqlite3.lib"
} else {
	foreign import sqlite "system:sqlite3"
}

// Distinct rawptr handles for strict type safety across the C-ABI boundary
sqlite3 :: distinct rawptr
sqlite3_stmt :: distinct rawptr
sqlite3_value :: distinct rawptr
sqlite3_context :: distinct rawptr
sqlite3_changegroup :: distinct rawptr
sqlite3_qrf_config :: distinct rawptr
sqlite3_backup :: distinct rawptr
sqlite3_blob :: distinct rawptr
sqlite3_module :: distinct rawptr
sqlite3_vtab :: distinct rawptr
sqlite3_vfs :: distinct rawptr
sqlite3_mutex :: distinct rawptr
sqlite3_session :: distinct rawptr

// Standard SQLite Result Codes
Result :: enum c.int {
	OK         = 0,
	ERROR      = 1,
	INTERNAL   = 2,
	PERM       = 3,
	ABORT      = 4,
	BUSY       = 5,
	LOCKED     = 6,
	NOMEM      = 7,
	READONLY   = 8,
	INTERRUPT  = 9,
	IOERR      = 10,
	CORRUPT    = 11,
	NOTFOUND   = 12,
	FULL       = 13,
	CANTOPEN   = 14,
	PROTOCOL   = 15,
	EMPTY      = 16,
	SCHEMA     = 17,
	TOOBIG     = 18,
	CONSTRAINT = 19,
	MISMATCH   = 20,
	MISUSE     = 21,
	NOLFS      = 22,
	AUTH       = 23,
	FORMAT     = 24,
	RANGE      = 25,
	NOTADB     = 26,
	NOTICE     = 27,
	WARNING    = 28,
	ROW        = 100,
	DONE       = 101,
}

// Foreign block inherently uses the "c" calling convention.
// link_prefix allows idiomatic Odin calls (e.g., sqlite.open instead of sqlite.sqlite3_open).
@(link_prefix = "sqlite3_")
foreign sqlite {
	// ========================================================================
	// Global Init/Shutdown API
	// ========================================================================
	initialize :: proc() -> Result ---
	shutdown :: proc() -> Result ---
	os_init :: proc() -> Result ---
	os_end :: proc() -> Result ---

	// ========================================================================
	// Core Database Connection API
	// ========================================================================
	open :: proc(filename: cstring, ppDb: ^sqlite3) -> Result ---
	open_v2 :: proc(filename: cstring, ppDb: ^sqlite3, flags: c.int, zVfs: cstring) -> Result ---
	close :: proc(db: sqlite3) -> Result ---
	close_v2 :: proc(db: sqlite3) -> Result ---
	exec :: proc(db: sqlite3, sql: cstring, callback: rawptr, cb_arg: rawptr, errmsg: ^cstring) -> Result ---
	busy_timeout :: proc(db: sqlite3, ms: c.int) -> Result ---

	// ========================================================================
	// Utility & Error API
	// ========================================================================
	errmsg :: proc(db: sqlite3) -> cstring ---
	errcode :: proc(db: sqlite3) -> Result ---
	extended_errcode :: proc(db: sqlite3) -> c.int ---
	errstr :: proc(err: Result) -> cstring ---
	changes :: proc(db: sqlite3) -> c.int ---
	total_changes :: proc(db: sqlite3) -> c.int ---
	last_insert_rowid :: proc(db: sqlite3) -> c.int64_t ---
	libversion :: proc() -> cstring ---
	libversion_number :: proc() -> c.int ---
	sourceid :: proc() -> cstring ---

	// ========================================================================
	// Statement API
	// ========================================================================
	prepare_v2 :: proc(db: sqlite3, zSql: cstring, nByte: c.int, ppStmt: ^sqlite3_stmt, pzTail: ^cstring) -> Result ---
	prepare_v3 :: proc(db: sqlite3, zSql: cstring, nByte: c.int, prepFlags: c.uint, ppStmt: ^sqlite3_stmt, pzTail: ^cstring) -> Result ---
	step :: proc(stmt: sqlite3_stmt) -> Result ---
	reset :: proc(stmt: sqlite3_stmt) -> Result ---
	clear_bindings :: proc(stmt: sqlite3_stmt) -> Result ---
	finalize :: proc(stmt: sqlite3_stmt) -> Result ---
	sql :: proc(stmt: sqlite3_stmt) -> cstring ---
	expanded_sql :: proc(stmt: sqlite3_stmt) -> cstring ---

	// ========================================================================
	// Bind API
	// ========================================================================
	bind_double :: proc(stmt: sqlite3_stmt, i: c.int, r: c.double) -> Result ---
	bind_int :: proc(stmt: sqlite3_stmt, i: c.int, a: c.int) -> Result ---
	bind_int64 :: proc(stmt: sqlite3_stmt, i: c.int, a: c.int64_t) -> Result ---
	bind_null :: proc(stmt: sqlite3_stmt, i: c.int) -> Result ---
	bind_text :: proc(stmt: sqlite3_stmt, i: c.int, zData: cstring, nData: c.int, xDel: rawptr) -> Result ---
	bind_blob :: proc(stmt: sqlite3_stmt, i: c.int, zData: rawptr, nData: c.int, xDel: rawptr) -> Result ---
	bind_zeroblob :: proc(stmt: sqlite3_stmt, i: c.int, n: c.int) -> Result ---
	bind_parameter_count :: proc(stmt: sqlite3_stmt) -> c.int ---
	bind_parameter_index :: proc(stmt: sqlite3_stmt, zName: cstring) -> c.int ---
	bind_parameter_name :: proc(stmt: sqlite3_stmt, i: c.int) -> cstring ---

	// ========================================================================
	// Column API
	// ========================================================================
	column_count :: proc(stmt: sqlite3_stmt) -> c.int ---
	column_name :: proc(stmt: sqlite3_stmt, N: c.int) -> cstring ---
	column_type :: proc(stmt: sqlite3_stmt, iCol: c.int) -> c.int ---
	column_bytes :: proc(stmt: sqlite3_stmt, iCol: c.int) -> c.int ---
	column_double :: proc(stmt: sqlite3_stmt, iCol: c.int) -> c.double ---
	column_int :: proc(stmt: sqlite3_stmt, iCol: c.int) -> c.int ---
	column_int64 :: proc(stmt: sqlite3_stmt, iCol: c.int) -> c.int64_t ---
	column_text :: proc(stmt: sqlite3_stmt, iCol: c.int) -> cstring ---
	column_blob :: proc(stmt: sqlite3_stmt, iCol: c.int) -> rawptr ---
	column_decltype :: proc(stmt: sqlite3_stmt, iCol: c.int) -> cstring ---

	// ========================================================================
	// Backup API
	// ========================================================================
	backup_init :: proc(pDest: sqlite3, zDestName: cstring, pSource: sqlite3, zSourceName: cstring) -> sqlite3_backup ---
	backup_step :: proc(p: sqlite3_backup, nPage: c.int) -> Result ---
	backup_finish :: proc(p: sqlite3_backup) -> Result ---
	backup_remaining :: proc(p: sqlite3_backup) -> c.int ---
	backup_pagecount :: proc(p: sqlite3_backup) -> c.int ---

	// ========================================================================
	// Blob I/O API
	// ========================================================================
	blob_open :: proc(db: sqlite3, zDb: cstring, zTable: cstring, zColumn: cstring, iRow: c.int64_t, flags: c.int, ppBlob: ^sqlite3_blob) -> Result ---
	blob_read :: proc(blob: sqlite3_blob, Z: rawptr, N: c.int, iOffset: c.int) -> Result ---
	blob_write :: proc(blob: sqlite3_blob, z: rawptr, n: c.int, iOffset: c.int) -> Result ---
	blob_close :: proc(blob: sqlite3_blob) -> Result ---
	blob_bytes :: proc(blob: sqlite3_blob) -> c.int ---

	// ========================================================================
	// User-Defined Functions (UDFs) API
	// ========================================================================
	create_function :: proc(db: sqlite3, zFunctionName: cstring, nArg: c.int, eTextRep: c.int, pApp: rawptr, xFunc: rawptr, xStep: rawptr, xFinal: rawptr) -> Result ---
	create_function_v2 :: proc(db: sqlite3, zFunctionName: cstring, nArg: c.int, eTextRep: c.int, pApp: rawptr, xFunc: rawptr, xStep: rawptr, xFinal: rawptr, xDestroy: rawptr) -> Result ---
	aggregate_context :: proc(ctx: sqlite3_context, nBytes: c.int) -> rawptr ---
	result_int :: proc(ctx: sqlite3_context, i: c.int) ---
	result_text :: proc(ctx: sqlite3_context, z: cstring, n: c.int, xDel: rawptr) ---
	result_error :: proc(ctx: sqlite3_context, z: cstring, n: c.int) ---
	value_int :: proc(val: sqlite3_value) -> c.int ---
	value_text :: proc(val: sqlite3_value) -> cstring ---

	// ========================================================================
	// Virtual Tables API
	// ========================================================================
	create_module :: proc(db: sqlite3, zName: cstring, p: ^sqlite3_module, pClientData: rawptr) -> Result ---
	declare_vtab :: proc(db: sqlite3, zSQL: cstring) -> Result ---

	// ========================================================================
	// Database Hooks & Callbacks API
	// ========================================================================
	commit_hook :: proc(db: sqlite3, xCallback: rawptr, pArg: rawptr) -> rawptr ---
	rollback_hook :: proc(db: sqlite3, xCallback: rawptr, pArg: rawptr) -> rawptr ---
	update_hook :: proc(db: sqlite3, xCallback: rawptr, pArg: rawptr) -> rawptr ---
	set_authorizer :: proc(db: sqlite3, xAuth: rawptr, pUserData: rawptr) -> Result ---

	// ========================================================================
	// Extensions API
	// ========================================================================
	load_extension :: proc(db: sqlite3, zFile: cstring, zProc: cstring, pzErrMsg: ^cstring) -> Result ---
	enable_load_extension :: proc(db: sqlite3, onoff: c.int) -> Result ---

	// ========================================================================
	// Collation API
	// ========================================================================
	create_collation :: proc(db: sqlite3, zName: cstring, eTextRep: c.int, pArg: rawptr, xCompare: rawptr) -> Result ---
	create_collation_v2 :: proc(db: sqlite3, zName: cstring, eTextRep: c.int, pArg: rawptr, xCompare: rawptr, xDestroy: rawptr) -> Result ---

	// ========================================================================
	// Advanced Config API
	// ========================================================================
	db_config :: proc(db: sqlite3, op: c.int, #c_vararg args: ..any) -> Result ---
	limit :: proc(db: sqlite3, id: c.int, newVal: c.int) -> c.int ---
	status :: proc(op: c.int, pCurrent: ^c.int, pHighwater: ^c.int, resetFlag: c.int) -> Result ---
	db_status :: proc(db: sqlite3, op: c.int, pCur: ^c.int, pHiwtr: ^c.int, resetFlg: c.int) -> Result ---

	// ========================================================================
	// Memory Management API
	// ========================================================================
	malloc :: proc(n: c.int) -> rawptr ---
	malloc64 :: proc(n: c.uint64_t) -> rawptr ---
	realloc :: proc(pOld: rawptr, n: c.int) -> rawptr ---
	free :: proc(p: rawptr) ---
	msize :: proc(p: rawptr) -> c.uint64_t ---
	memory_used :: proc() -> c.int64_t ---
	memory_highwater :: proc(resetFlag: c.int) -> c.int64_t ---

	// ========================================================================
	// Mutex Subsystem API
	// ========================================================================
	mutex_alloc :: proc(id: c.int) -> sqlite3_mutex ---
	mutex_free :: proc(p: sqlite3_mutex) ---
	mutex_enter :: proc(p: sqlite3_mutex) ---
	mutex_try :: proc(p: sqlite3_mutex) -> Result ---
	mutex_leave :: proc(p: sqlite3_mutex) ---

	// ========================================================================
	// VFS (Virtual File System) API
	// ========================================================================
	vfs_register :: proc(pVfs: sqlite3_vfs, makeDflt: c.int) -> Result ---
	vfs_unregister :: proc(pVfs: sqlite3_vfs) -> Result ---
	vfs_find :: proc(zVfsName: cstring) -> sqlite3_vfs ---

	// ========================================================================
	// WAL (Write-Ahead Logging) API
	// ========================================================================
	wal_autocheckpoint :: proc(db: sqlite3, N: c.int) -> Result ---
	wal_checkpoint :: proc(db: sqlite3, zDb: cstring) -> Result ---
	wal_checkpoint_v2 :: proc(db: sqlite3, zDb: cstring, eMode: c.int, pnLog: ^c.int, pnCkpt: ^c.int) -> Result ---
	wal_hook :: proc(db: sqlite3, xCallback: rawptr, pArg: rawptr) -> rawptr ---

	// ========================================================================
	// Strings & Utils API
	// ========================================================================
	mprintf :: proc(zFormat: cstring, #c_vararg args: ..any) -> cstring ---
	snprintf :: proc(n: c.int, zBuf: cstring, zFormat: cstring, #c_vararg args: ..any) -> cstring ---
	free_filename :: proc(z: cstring) ---
	randomness :: proc(N: c.int, P: rawptr) ---

	// ========================================================================
	// Session & Changegroup API
	// ========================================================================
	session_create :: proc(db: sqlite3, zDb: cstring, ppSession: ^sqlite3_session) -> Result ---
	session_delete :: proc(pSession: sqlite3_session) ---
	changegroup_new :: proc(pp: ^sqlite3_changegroup) -> Result ---
	changegroup_add :: proc(cg: sqlite3_changegroup, nData: c.int, pData: rawptr) -> Result ---
	changegroup_delete :: proc(cg: sqlite3_changegroup) ---
}

// ============================================================================
// 2026 JSONB API (Odin Native Wrappers)
// ============================================================================

// SQLite 3.45+ JSONB is stored internally as a standard BLOB.
// FFI Dimensionality Sync: Requires explicit length passed alongside the raw pointer.
bind_jsonb :: proc(stmt: sqlite3_stmt, i: c.int, jsonb_data: [^]u8, nData: c.int) -> Result {
	// Using SQLITE_STATIC (nil) since the Odin slice is guaranteed to outlive the step() execution
	// in our synchronous pipeline. This prevents FFI destructor translation crashes.
	return bind_blob(stmt, i, rawptr(jsonb_data), nData, nil)
}

// ============================================================================
// 2026 QRF (Query Result Formatter) API (Odin Native Implementation)
// ============================================================================

Qrf_Config :: struct {
	db:    sqlite3,
	style: string,
}

qrf_init :: proc(db: sqlite3, config: ^sqlite3_qrf_config) -> Result {
	cfg := new(Qrf_Config)
	cfg.db = db
	cfg.style = "DEFAULT"
	config^ = cast(sqlite3_qrf_config)cfg
	return .OK
}

qrf_set_style :: proc(config: sqlite3_qrf_config, style: cstring) -> Result {
	if config == nil do return .ERROR
	cfg := cast(^Qrf_Config)config
	cfg.style = string(style)
	return .OK
}

qrf_print_table :: proc(config: sqlite3_qrf_config, sql: cstring) -> Result {
	if config == nil do return .ERROR
	cfg := cast(^Qrf_Config)config

	stmt: sqlite3_stmt
	if prepare_v2(cfg.db, sql, -1, &stmt, nil) != .OK {
		return .ERROR
	}
	defer {
		finalize(stmt)
		stmt = nil
	}

	cols := column_count(stmt)

	// Render Header
	for i in 0 ..< cols {
		// Explicitly cast cstring to string to prevent fmt package buffer over-reads
		fmt.printf("%-15s | ", string(column_name(stmt, i)))
	}
	fmt.print("\n")
	for _ in 0 ..< cols {
		fmt.print("----------------| ")
	}
	fmt.print("\n")

	// Render Rows
	for step(stmt) == .ROW {
		for i in 0 ..< cols {
			text := column_text(stmt, i)
			if text == nil {
				fmt.printf("%-15s | ", "NULL")
			} else {
				// Explicitly cast cstring to string to prevent fmt package buffer over-reads
				fmt.printf("%-15s | ", string(text))
			}
		}
		fmt.print("\n")
	}

	return .OK
}

qrf_free :: proc(config: sqlite3_qrf_config) {
	if config != nil {
		mem.free(cast(^Qrf_Config)config) // Explicitly route to Odin's native allocator
	}
}
// EOF sqlite3.odin
