package os

import "core:time"


File_Info :: struct {
	fullpath: string,
	name:     string,
	size:     i64,
	mode:     File_Mode,
	is_dir:   bool,
	creation_time:     time.Time,
	modification_time: time.Time,
	access_time:       time.Time,
}

file_info_delete :: proc(fi: File_Info) {
	delete(fi.fullpath);
}

File_Mode :: distinct u32;

File_Mode_Dir         :: File_Mode(1<<16);
File_Mode_Named_Pipe  :: File_Mode(1<<17);
File_Mode_Device      :: File_Mode(1<<18);
File_Mode_Char_Device :: File_Mode(1<<19);
File_Mode_Sym_Link    :: File_Mode(1<<20);
