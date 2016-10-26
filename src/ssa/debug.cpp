ssaDebugInfo *ssa_add_debug_info_file(ssaProcedure *proc, AstFile *file) {
	if (!proc->module->generate_debug_info) {
		return NULL;
	}

	GB_ASSERT(file != NULL);
	ssaDebugInfo *di = ssa_alloc_debug_info(proc->module->allocator, ssaDebugInfo_File);
	di->File.file = file;

	String filename = file->tokenizer.fullpath;
	String directory = filename;
	isize slash_index = 0;
	for (isize i = filename.len-1; i >= 0; i--) {
		if (filename.text[i] == '\\' ||
		    filename.text[i] == '/') {
			break;
		}
		slash_index = i;
	}
	directory.len = slash_index-1;
	filename.text = filename.text + slash_index;
	filename.len -= slash_index;


	di->File.filename = filename;
	di->File.directory = directory;

	map_set(&proc->module->debug_info, hash_pointer(file), di);
	return di;
}


ssaDebugInfo *ssa_add_debug_info_proc(ssaProcedure *proc, Entity *entity, String name, ssaDebugInfo *file) {
	if (!proc->module->generate_debug_info) {
		return NULL;
	}

	GB_ASSERT(entity != NULL);
	ssaDebugInfo *di = ssa_alloc_debug_info(proc->module->allocator, ssaDebugInfo_Proc);
	di->Proc.entity = entity;
	di->Proc.name = name;
	di->Proc.file = file;
	di->Proc.pos = entity->token.pos;

	map_set(&proc->module->debug_info, hash_pointer(entity), di);
	return di;
}

