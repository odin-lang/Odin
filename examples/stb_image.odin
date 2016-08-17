type Bitmap: struct {
	width, height: i32,
	comp: i32,
	data: []u8,
}

make_bitmap :: proc(filename: string) -> Bitmap {
	stbi_load :: proc(filename: ^u8, x, y, comp: ^i32, req_comp: i32) -> ^u8 #foreign

	c_buf: [1024]u8;
	bytes :=  filename as []byte;
	str_len := copy(c_buf[:], bytes);

	b: Bitmap;
	pixels := stbi_load(^c_buf[0], ^b.width, ^b.height, ^b.comp, 4);
	len := (b.width*b.height*b.comp) as int;
	b.data = pixels[:len];

	return b;
}

destroy_bitmap :: proc(b: ^Bitmap) {
	stbi_image_free :: proc(retval_from_stbi_load: rawptr) #foreign

	stbi_image_free(^b.data[0]);
	b.data   = b.data[:0];
	b.width  = 0;
	b.height = 0;
	b.comp   = 0;
}
