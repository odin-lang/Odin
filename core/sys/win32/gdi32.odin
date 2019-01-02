// +build windows
package win32

foreign import "system:gdi32.lib"


@(default_calling_convention = "std")
foreign gdi32 {
	@(link_name="GetStockObject") get_stock_object :: proc(fn_object: i32) -> Hgdiobj ---;

	@(link_name="StretchDIBits")
	stretch_dibits :: proc(hdc: Hdc,
	                       x_dst, y_dst, width_dst, height_dst: i32,
	                       x_src, y_src, width_src, header_src: i32,
	                       bits: rawptr, bits_info: ^Bitmap_Info,
	                       usage: u32,
	                       rop: u32) -> i32 ---;

	@(link_name="SetPixelFormat")    set_pixel_format    :: proc(hdc: Hdc, pixel_format: i32, pfd: ^Pixel_Format_Descriptor) -> Bool ---;
	@(link_name="ChoosePixelFormat") choose_pixel_format :: proc(hdc: Hdc, pfd: ^Pixel_Format_Descriptor) -> i32 ---;
	@(link_name="SwapBuffers")       swap_buffers        :: proc(hdc: Hdc) -> Bool ---;

}
