package mem_virtual

Map_File_Error :: enum {
	None,
	Open_Failure,
	Stat_Failure,
	Negative_Size,
	Too_Large_Size,
	Map_Failure,
}

Map_File_Flag :: enum u32 {
	Read,
	Write,
}
Map_File_Flags :: distinct bit_set[Map_File_Flag; u32]