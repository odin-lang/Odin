// +build windows
package win32

foreign import "system:gdi32.lib"

WHITENESS :: 0x00FF0062;
BLACKNESS :: 0x00000042;

@(default_calling_convention = "std")
foreign gdi32 {
	GetStockObject :: proc(fn_object: i32) -> HGDIOBJ ---;

	StretchDIBits :: proc(hdc: HDC,
	                       x_dst, y_dst, width_dst, height_dst: i32,
	                       x_src, y_src, width_src, header_src: i32,
	                       bits: rawptr, bits_info: ^BITMAPINFO,
	                       usage: u32,
	                       rop: u32) -> i32 ---;

	SetPixelFormat    :: proc(hdc: HDC, pixel_format: i32, pfd: ^PIXELFORMATDESCRIPTOR) -> BOOL ---;
	ChoosePixelFormat :: proc(hdc: HDC, pfd: ^PIXELFORMATDESCRIPTOR) -> i32 ---;
	SwapBuffers       :: proc(hdc: HDC) -> BOOL ---;

	PatBlt :: proc(hdc: HDC, x, y, w, h: i32, rop: u32) -> BOOL ---;
}

get_stock_object    :: GetStockObject;
stretch_dibits      :: StretchDIBits;
set_pixel_format    :: SetPixelFormat;
choose_pixel_format :: ChoosePixelFormat;
swap_buffers        :: SwapBuffers;
pat_blt             :: PatBlt;