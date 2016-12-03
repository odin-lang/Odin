typedef struct BuildContext {
	String ODIN_OS;      // target operating system
	String ODIN_ARCH;    // target architecture
	String ODIN_VENDOR;  // compiler vendor
	String ODIN_VERSION; // compiler version
	String ODIN_ROOT;    // Odin ROOT

	i64    word_size;
	i64    max_align;
	String llc_flags;
	String link_flags;
} BuildContext;

String odin_root_dir(void) {
	String path = global_module_path;
	Array(wchar_t) path_buf;
	isize len, i;
	gbTempArenaMemory tmp;
	wchar_t *text;

	if (global_module_path_set) {
		return global_module_path;
	}

	array_init_count(&path_buf, heap_allocator(), 300);

	len = 0;
	for (;;) {
		len = GetModuleFileNameW(NULL, &path_buf.e[0], path_buf.count);
		if (len == 0) {
			return make_string(NULL, 0);
		}
		if (len < path_buf.count) {
			break;
		}
		array_resize(&path_buf, 2*path_buf.count + 300);
	}

	tmp = gb_temp_arena_memory_begin(&string_buffer_arena);

	text = gb_alloc_array(string_buffer_allocator, wchar_t, len+1);

	GetModuleFileNameW(NULL, text, len);
	path = string16_to_string(heap_allocator(), make_string16(text, len));
	for (i = path.len-1; i >= 0; i--) {
		u8 c = path.text[i];
		if (c == '/' || c == '\\') {
			break;
		}
		path.len--;
	}

	global_module_path = path;
	global_module_path_set = true;

	gb_temp_arena_memory_end(tmp);

	array_free(&path_buf);

	return path;
}


void init_build_context(BuildContext *bc) {
	bc->ODIN_OS      = str_lit("windows");
	bc->ODIN_ARCH    = str_lit("amd64");
	bc->ODIN_VENDOR  = str_lit("odin");
	bc->ODIN_VERSION = str_lit("0.0.3d");
	bc->ODIN_ROOT    = odin_root_dir();


	if (str_eq(bc->ODIN_ARCH, str_lit("amd64"))) {
		bc->word_size = 8;
		bc->max_align = 16;
		bc->llc_flags = str_lit("-march=x86-64 ");
		bc->link_flags = str_lit("/machine:x64 ");
	} else if (str_eq(bc->ODIN_ARCH, str_lit("x86"))) {
		bc->word_size = 4;
		bc->max_align = 8;
		bc->llc_flags = str_lit("-march=x86 ");
		bc->link_flags = str_lit("/machine:x86 ");
	}
}
