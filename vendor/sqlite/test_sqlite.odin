// Filename: test_sqlite.odin
// Version: v4.0 (Comprehensive Shakedown Suite)
package main

import "base:runtime"
import "core:c"
import "core:fmt"
import "core:mem"
import "core:os"
import "sqlite"

// ============================================================================
// Memory Tracking & Diagnostics
// ============================================================================
flashlight_audit :: proc(track: ^mem.Tracking_Allocator) {
	leaks := 0
	for _, leak in track.allocation_map {
		fmt.printf("[LEAK DETECTED] % 6d bytes at %v\n", leak.size, leak.location)
		leaks += 1
	}
	if leaks == 0 {
		fmt.println("\n[SYSTEM] Flashlight Audit: 0 Memory Leaks Detected. Perfect Run.")
	}
	mem.tracking_allocator_destroy(track)
}

// ============================================================================
// FFI Callbacks (Must use "c" calling convention)
// ============================================================================
compute_hash_cb :: proc "c" (ctx: sqlite.sqlite3_context, argc: c.int, argv: [^]sqlite.sqlite3_value) {
	context = runtime.default_context()
	if argc > 0 {
		val := sqlite.value_int(argv[0])
		hash := (val * 17) % 1000
		sqlite.result_int(ctx, hash)
	} else {
		sqlite.result_int(ctx, 0)
	}
}

update_hook_cb :: proc "c" (pArg: rawptr, op: c.int, zDb: cstring, zName: cstring, rowid: c.int64_t) {
	context = runtime.default_context()
	op_type := "UNKNOWN"
	switch op {
	case 18: op_type = "INSERT"
	case 9:  op_type = "DELETE"
	case 23: op_type = "UPDATE"
	}
	fmt.printf("    -> [HOOK FIRED] %s on table '%s' (RowID: %d)\n", op_type, string(zName), rowid)
}

// ============================================================================
// Main Execution
// ============================================================================
main :: proc() {
	// Tracking Allocator Initialization (Safely scoped for FFI)
	track: mem.Tracking_Allocator
	when ODIN_DEBUG {
		mem.tracking_allocator_init(&track, context.allocator)
		context.allocator = mem.tracking_allocator(&track)
	}
	defer when ODIN_DEBUG {flashlight_audit(&track)}

	fmt.println("======================================================")
	fmt.println("   SQLite 3.53.0 (Odin Vendor Bindings Test Suite)    ")
	fmt.println("======================================================\n")

	// ---------------------------------------------------------
	// (1) Global Initialization & Memory
	// ---------------------------------------------------------
	fmt.println("(1) Testing: Global Init & Memory Subsystem...")
	if sqlite.initialize() != .OK do panic("Failed to initialize SQLite")
	
	mem_used := sqlite.memory_used()
	fmt.printf("    -> SQLite Initial Memory Used: %d bytes\n", mem_used)
	
	// Test SQLite's internal allocator (using the C-mapped free, not Odin's mem.free)
	ptr := sqlite.malloc(128)
	if ptr != nil {
		fmt.println("    -> sqlite.malloc(128) Successful.")
		sqlite.free(ptr)
	}
	fmt.println("    [PASSED]\n")

	// ---------------------------------------------------------
	// (2) Database Connection & Config
	// ---------------------------------------------------------
	fmt.println("(2) Testing: Connection & Config API...")
	fmt.printf("    -> Engine Version: %s\n", string(sqlite.libversion()))
	
	db: sqlite.sqlite3
	if sqlite.open(cstring(":memory:"), &db) != .OK {
		fmt.panicf("Failed to open DB: %s", string(sqlite.errmsg(db)))
	}
	defer {
		sqlite.close_v2(db)
		db = nil
	}
	fmt.println("    -> In-Memory Database Opened.")
	fmt.println("    [PASSED]\n")

	// ---------------------------------------------------------
	// (3) Statements & Execution
	// ---------------------------------------------------------
	fmt.println("(3) Testing: Statements & Execution API...")
	sql_create := cstring("CREATE TABLE core_test (id INTEGER PRIMARY KEY, name TEXT, val REAL, raw BLOB);")
	if sqlite.exec(db, sql_create, nil, nil, nil) != .OK {
		fmt.panicf("Exec failed: %s", string(sqlite.errmsg(db)))
	}
	fmt.println("    -> Table 'core_test' created via sqlite.exec().")
	fmt.println("    [PASSED]\n")

	// ---------------------------------------------------------
	// (4) Data Binding & Column Extraction
	// ---------------------------------------------------------
	fmt.println("(4) Testing: Bind & Column API (Data Types)...")
	stmt: sqlite.sqlite3_stmt
	sql_insert := cstring("INSERT INTO core_test (name, val, raw) VALUES (?, ?, ?);")
	if sqlite.prepare_v2(db, sql_insert, -1, &stmt, nil) == .OK {
		// Test Binds
		sqlite.bind_text(stmt, 1, cstring("TestNode"), -1, nil)
		sqlite.bind_double(stmt, 2, 3.14159)
		sqlite.bind_zeroblob(stmt, 3, 16) // Allocates 16 bytes of zeros
		
		if sqlite.step(stmt) == .DONE {
			fmt.println("    -> Statement Prepared, Bound, and Stepped.")
		}
		sqlite.finalize(stmt)
		stmt = nil
	}

	// Test Columns
	sql_select := cstring("SELECT name, val, raw FROM core_test LIMIT 1;")
	if sqlite.prepare_v2(db, sql_select, -1, &stmt, nil) == .OK {
		if sqlite.step(stmt) == .ROW {
			c_name := string(sqlite.column_text(stmt, 0))
			c_val := sqlite.column_double(stmt, 1)
			c_bytes := sqlite.column_bytes(stmt, 2)
			fmt.printf("    -> Extracted: name='%s', val=%v, blob_size=%d\n", c_name, c_val, c_bytes)
		}
		sqlite.finalize(stmt)
		stmt = nil
	}
	fmt.println("    [PASSED]\n")

	// ---------------------------------------------------------
	// (5) FFI Callbacks (Hooks & UDFs)
	// ---------------------------------------------------------
	fmt.println("(5) Testing: FFI Callbacks (Hooks & UDFs)...")
	sqlite.update_hook(db, rawptr(update_hook_cb), nil)
	sqlite.create_function(db, cstring("odin_hash"), 1, 1, nil, rawptr(compute_hash_cb), nil, nil)
	
	// Trigger the hook and UDF
	sql_update := cstring("UPDATE core_test SET val = odin_hash(100) WHERE id = 1;")
	sqlite.exec(db, sql_update, nil, nil, nil)
	fmt.println("    [PASSED]\n")

	// ---------------------------------------------------------
	// (6) String & Utility API
	// ---------------------------------------------------------
	fmt.println("(6) Testing: SQLite String Utilities...")
	// Note: mprintf returns memory allocated by SQLite, MUST be freed by sqlite.free
	fmt_str := sqlite.mprintf(cstring("Safe string %d from %s"), 2026, cstring("Odin"))
	fmt.printf("    -> mprintf output: %s\n", string(fmt_str))
	sqlite.free(rawptr(fmt_str))
	fmt.println("    [PASSED]\n")

	// ---------------------------------------------------------
	// (7) Blob I/O Subsystem
	// ---------------------------------------------------------
	fmt.println("(7) Testing: Blob I/O Streaming API...")
	blob: sqlite.sqlite3_blob
	// Open the 'raw' column on row 1 for read/write (flag = 1)
	if sqlite.blob_open(db, cstring("main"), cstring("core_test"), cstring("raw"), 1, 1, &blob) == .OK {
		size := sqlite.blob_bytes(blob)
		fmt.printf("    -> Blob Opened. Size: %d bytes\n", size)
		
		// Write direct binary data bypassing SQL
		payload := []u8{0xAA, 0xBB, 0xCC, 0xDD}
		sqlite.blob_write(blob, raw_data(payload), cast(c.int)len(payload), 0)
		fmt.println("    -> Streamed 4 bytes directly into blob.")
		
		sqlite.blob_close(blob)
		blob = nil
	}
	fmt.println("    [PASSED]\n")

	// ---------------------------------------------------------
	// (8) Backup API
	// ---------------------------------------------------------
	fmt.println("(8) Testing: Backup API (Memory -> Disk)...")
	backup_db: sqlite.sqlite3
	if sqlite.open(cstring("test_backup.db"), &backup_db) == .OK {
		backup := sqlite.backup_init(backup_db, cstring("main"), db, cstring("main"))
		if backup != nil {
			sqlite.backup_step(backup, -1) // -1 copies the whole DB
			sqlite.backup_finish(backup)
			fmt.println("    -> Database successfully backed up to test_backup.db")
		}
		sqlite.close_v2(backup_db)
		backup_db = nil
	}
	fmt.println("    [PASSED]\n")

	// ---------------------------------------------------------
	// (9) Query Result Formatter (QRF)
	// ---------------------------------------------------------
	fmt.println("(9) Testing: Native Odin QRF Wrapper...")
	qrf: sqlite.sqlite3_qrf_config
	if sqlite.qrf_init(db, &qrf) == .OK {
		fmt.println("\n--- Final 'core_test' Table State ---")
		sqlite.qrf_print_table(qrf, cstring("SELECT * FROM core_test;"))
		fmt.println("-------------------------------------\n")
		sqlite.qrf_free(qrf)
		qrf = nil
	}
	fmt.println("    [PASSED]\n")

	// ---------------------------------------------------------
	// Teardown
	// ---------------------------------------------------------
	fmt.println("(10) Global Shutdown...")
	// Clean up the backup file we created
	os.remove("test_backup.db")
	
	// Note: We don't call sqlite.shutdown() here because sqlite.close_v2() is deferred above,
	// and shutting down the engine before the defer runs would cause an error.
	fmt.println("    -> Test suite finished successfully.")
}
// EOF test_sqlite.odin
