package sdl3_image

import "core:c"
import SDL "vendor:sdl3"

when ODIN_OS == .Windows {
	foreign import lib "SDL3_image.lib"
} else {
	foreign import lib "system:SDL3_image"
}

MAJOR_VERSION :: 3
MINOR_VERSION :: 2
PATCHLEVEL    :: 0

Animation :: struct {
	w, h:   c.int,
	count:  c.int,
	frames: [^]^SDL.Surface,
	delays: [^]c.int,
}

@(default_calling_convention="c", link_prefix="IMG_")
foreign lib {
	Version :: proc() -> c.int ---

	/* Load an image from an SDL data source.
	   The 'type' may be one of: "BMP", "GIF", "PNG", etc.
	   If the image format supports a transparent pixel, SDL will set the
	   colorkey for the surface.  You can enable RLE acceleration on the
	   surface afterwards by calling:
	    SDL_SetColorKey(image, SDL_RLEACCEL, image->format->colorkey);
	 */
	LoadTyped_IO :: proc(src: ^SDL.IOStream, closeio: bool, type: cstring) -> ^SDL.Surface ---

	/* Convenience functions */
	Load    :: proc(file: cstring) -> ^SDL.Surface ---
	Load_IO :: proc(src: ^SDL.IOStream, closeio: bool) -> ^SDL.Surface ---

	/* Load an image directly into a render texture. */
	LoadTexture          :: proc(renderer: ^SDL.Renderer, file: cstring) -> ^SDL.Texture ---
	LoadTexture_IO       :: proc(renderer: ^SDL.Renderer, src: ^SDL.IOStream, closeio: bool) -> ^SDL.Texture ---
	LoadTextureTyped_IO  :: proc(renderer: ^SDL.Renderer, src: ^SDL.IOStream, closeio: bool, type: cstring) -> ^SDL.Texture ---

	/* Functions to detect a file type, given a seekable source */
	isAVIF :: proc(src: ^SDL.IOStream) -> bool ---
	isICO  :: proc(src: ^SDL.IOStream) -> bool ---
	isCUR  :: proc(src: ^SDL.IOStream) -> bool ---
	isBMP  :: proc(src: ^SDL.IOStream) -> bool ---
	isGIF  :: proc(src: ^SDL.IOStream) -> bool ---
	isJPG  :: proc(src: ^SDL.IOStream) -> bool ---
	isJXL  :: proc(src: ^SDL.IOStream) -> bool ---
	isLBM  :: proc(src: ^SDL.IOStream) -> bool ---
	isPCX  :: proc(src: ^SDL.IOStream) -> bool ---
	isPNG  :: proc(src: ^SDL.IOStream) -> bool ---
	isPNM  :: proc(src: ^SDL.IOStream) -> bool ---
	isSVG  :: proc(src: ^SDL.IOStream) -> bool ---
	isQOI  :: proc(src: ^SDL.IOStream) -> bool ---
	isTIF  :: proc(src: ^SDL.IOStream) -> bool ---
	isXCF  :: proc(src: ^SDL.IOStream) -> bool ---
	isXPM  :: proc(src: ^SDL.IOStream) -> bool ---
	isXV   :: proc(src: ^SDL.IOStream) -> bool ---
	isWEBP :: proc(src: ^SDL.IOStream) -> bool ---

	/* Individual loading functions */
	LoadAVIF_IO :: proc(src: ^SDL.IOStream) -> ^SDL.Surface ---
	LoadICO_IO  :: proc(src: ^SDL.IOStream) -> ^SDL.Surface ---
	LoadCUR_IO  :: proc(src: ^SDL.IOStream) -> ^SDL.Surface ---
	LoadBMP_IO  :: proc(src: ^SDL.IOStream) -> ^SDL.Surface ---
	LoadGIF_IO  :: proc(src: ^SDL.IOStream) -> ^SDL.Surface ---
	LoadJPG_IO  :: proc(src: ^SDL.IOStream) -> ^SDL.Surface ---
	LoadJXL_IO  :: proc(src: ^SDL.IOStream) -> ^SDL.Surface ---
	LoadLBM_IO  :: proc(src: ^SDL.IOStream) -> ^SDL.Surface ---
	LoadPCX_IO  :: proc(src: ^SDL.IOStream) -> ^SDL.Surface ---
	LoadPNG_IO  :: proc(src: ^SDL.IOStream) -> ^SDL.Surface ---
	LoadPNM_IO  :: proc(src: ^SDL.IOStream) -> ^SDL.Surface ---
	LoadSVG_IO  :: proc(src: ^SDL.IOStream) -> ^SDL.Surface ---
	LoadQOI_IO  :: proc(src: ^SDL.IOStream) -> ^SDL.Surface ---
	LoadTGA_IO  :: proc(src: ^SDL.IOStream) -> ^SDL.Surface ---
	LoadTIF_IO  :: proc(src: ^SDL.IOStream) -> ^SDL.Surface ---
	LoadXCF_IO  :: proc(src: ^SDL.IOStream) -> ^SDL.Surface ---
	LoadXPM_IO  :: proc(src: ^SDL.IOStream) -> ^SDL.Surface ---
	LoadXV_IO   :: proc(src: ^SDL.IOStream) -> ^SDL.Surface ---
	LoadWEBP_IO :: proc(src: ^SDL.IOStream) -> ^SDL.Surface ---

	LoadSizedSVG_IO :: proc(src: ^SDL.IOStream, width, height: c.int) -> ^SDL.Surface ---

	ReadXPMFromArray :: proc(xpm: [^]cstring) -> ^SDL.Surface ---
	ReadXPMFromArrayToRGB888 :: proc(xpm: [^]cstring) -> ^SDL.Surface ---

	/* Individual saving functions */
	SaveAVIF    :: proc(surface: ^SDL.Surface, file: cstring, quality: c.int) -> c.int ---
	SaveAVIF_IO :: proc(surface: ^SDL.Surface, dst: ^SDL.IOStream, closeio: bool, quality: c.int) -> c.int ---
	SavePNG     :: proc(surface: ^SDL.Surface, file: cstring) -> c.int ---
	SavePNG_IO  :: proc(surface: ^SDL.Surface, dst: ^SDL.IOStream, closeio: bool) -> c.int ---
	SaveJPG     :: proc(surface: ^SDL.Surface, file: cstring, quality: c.int) -> c.int ---
	SaveJPG_IO  :: proc(surface: ^SDL.Surface, dst: ^SDL.IOStream, closeio: bool, quality: c.int) -> c.int ---

	LoadAnimation         :: proc(file: cstring) -> ^Animation ---
	LoadAnimation_IO      :: proc(src: ^SDL.IOStream, closeio: bool) -> ^Animation ---
	LoadAnimationTyped_IO :: proc(src: ^SDL.IOStream, closeio: bool, type: cstring) -> ^Animation ---
	FreeAnimation         :: proc(anim: ^Animation) ---

	/* Individual loading functions */
	LoadGIFAnimation_IO :: proc(src: ^SDL.IOStream) -> ^Animation ---
	LoadWEBPAnimation_IO :: proc(src: ^SDL.IOStream) -> ^Animation ---
}
