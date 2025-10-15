// Bindings for [[ SDL2 Image; https://wiki.libsdl.org/SDL2/FrontPage ]].
package sdl2_image

import "core:c"
import SDL ".."

when ODIN_OS == .Windows {
	foreign import lib "SDL2_image.lib"
} else {
	foreign import lib "system:SDL2_image"
}

bool :: SDL.bool

MAJOR_VERSION :: 2
MINOR_VERSION :: 0
PATCHLEVEL    :: 5

@(default_calling_convention="c", link_prefix="IMG_")
foreign lib {
	Linked_Version :: proc() -> ^SDL.version ---
}

InitFlag :: enum c.int {
	JPG  = 0,
	PNG  = 1,
	TIF  = 2,
	WEBP = 3,
}

InitFlags :: distinct bit_set[InitFlag; c.int]

INIT_JPG  :: InitFlags{.JPG}
INIT_PNG  :: InitFlags{.PNG}
INIT_TIF  :: InitFlags{.TIF}
INIT_WEBP :: InitFlags{.WEBP}

/* Animated image support
   Currently only animated GIFs are supported.
 */
Animation :: struct {
	w, h:   c.int,
	count:  c.int,
	frames: [^]^SDL.Surface,
	delays: [^]c.int,
}

/* We'll use SDL for reporting errors */
SetError :: SDL.SetError
GetError :: SDL.GetError

@(default_calling_convention="c", link_prefix="IMG_")
foreign lib {
	Init :: proc(flags: InitFlags) -> InitFlags ---
	Quit :: proc() ---

	/* Load an image from an SDL data source.
	   The 'type' may be one of: "BMP", "GIF", "PNG", etc.
	   If the image format supports a transparent pixel, SDL will set the
	   colorkey for the surface.  You can enable RLE acceleration on the
	   surface afterwards by calling:
	    SDL_SetColorKey(image, SDL_RLEACCEL, image->format->colorkey);
	 */
	LoadTyped_RW :: proc(src: ^SDL.RWops, freesrc: bool, type: cstring) -> ^SDL.Surface ---
	/* Convenience functions */
	Load    :: proc(file: cstring) -> ^SDL.Surface ---
	Load_RW :: proc(src: ^SDL.RWops, freesrc: bool) -> ^SDL.Surface ---

	/* Load an image directly into a render texture. */
	LoadTexture          :: proc(renderer: ^SDL.Renderer, file: cstring) -> ^SDL.Texture ---
	LoadTexture_RW       :: proc(renderer: ^SDL.Renderer, src: ^SDL.RWops, freesrc: bool) -> ^SDL.Texture ---
	LoadTextureTyped_RW  :: proc(renderer: ^SDL.Renderer, src: ^SDL.RWops, freesrc: bool, type: cstring) -> ^SDL.Texture ---

	/* Functions to detect a file type, given a seekable source */
	isICO  :: proc(src: ^SDL.RWops) -> bool ---
	isCUR  :: proc(src: ^SDL.RWops) -> bool ---
	isBMP  :: proc(src: ^SDL.RWops) -> bool ---
	isGIF  :: proc(src: ^SDL.RWops) -> bool ---
	isJPG  :: proc(src: ^SDL.RWops) -> bool ---
	isLBM  :: proc(src: ^SDL.RWops) -> bool ---
	isPCX  :: proc(src: ^SDL.RWops) -> bool ---
	isPNG  :: proc(src: ^SDL.RWops) -> bool ---
	isPNM  :: proc(src: ^SDL.RWops) -> bool ---
	isSVG  :: proc(src: ^SDL.RWops) -> bool ---
	isTIF  :: proc(src: ^SDL.RWops) -> bool ---
	isXCF  :: proc(src: ^SDL.RWops) -> bool ---
	isXPM  :: proc(src: ^SDL.RWops) -> bool ---
	isXV   :: proc(src: ^SDL.RWops) -> bool ---
	isWEBP :: proc(src: ^SDL.RWops) -> bool ---

	/* Individual loading functions */
	LoadICO_RW  :: proc(src: ^SDL.RWops) -> ^SDL.Surface ---
	LoadCUR_RW  :: proc(src: ^SDL.RWops) -> ^SDL.Surface ---
	LoadBMP_RW  :: proc(src: ^SDL.RWops) -> ^SDL.Surface ---
	LoadGIF_RW  :: proc(src: ^SDL.RWops) -> ^SDL.Surface ---
	LoadJPG_RW  :: proc(src: ^SDL.RWops) -> ^SDL.Surface ---
	LoadLBM_RW  :: proc(src: ^SDL.RWops) -> ^SDL.Surface ---
	LoadPCX_RW  :: proc(src: ^SDL.RWops) -> ^SDL.Surface ---
	LoadPNG_RW  :: proc(src: ^SDL.RWops) -> ^SDL.Surface ---
	LoadPNM_RW  :: proc(src: ^SDL.RWops) -> ^SDL.Surface ---
	LoadSVG_RW  :: proc(src: ^SDL.RWops) -> ^SDL.Surface ---
	LoadTGA_RW  :: proc(src: ^SDL.RWops) -> ^SDL.Surface ---
	LoadTIF_RW  :: proc(src: ^SDL.RWops) -> ^SDL.Surface ---
	LoadXCF_RW  :: proc(src: ^SDL.RWops) -> ^SDL.Surface ---
	LoadXPM_RW  :: proc(src: ^SDL.RWops) -> ^SDL.Surface ---
	LoadXV_RW   :: proc(src: ^SDL.RWops) -> ^SDL.Surface ---
	LoadWEBP_RW :: proc(src: ^SDL.RWops) -> ^SDL.Surface ---

	ReadXPMFromArray :: proc(xpm: [^]cstring) -> ^SDL.Surface ---

	/* Individual saving functions */
	SavePNG    :: proc(surface: ^SDL.Surface, file: cstring) -> c.int ---
	SavePNG_RW :: proc(surface: ^SDL.Surface, dst: ^SDL.RWops, freedst: bool) -> c.int ---
	SaveJPG    :: proc(surface: ^SDL.Surface, file: cstring, quality: c.int) -> c.int ---
	SaveJPG_RW :: proc(surface: ^SDL.Surface, dst: ^SDL.RWops, freedst: bool, quality: c.int) -> c.int ---

	LoadAnimation         :: proc(file: cstring) -> ^Animation ---
	LoadAnimation_RW      :: proc(src: ^SDL.RWops, freesrc: bool) -> ^Animation ---
	LoadAnimationTyped_RW :: proc(src: ^SDL.RWops, freesrc: bool, type: cstring) -> ^Animation ---
	FreeAnimation         :: proc(anim: ^Animation) ---

	/* Individual loading functions */
	LoadGIFAnimation_RW :: proc(src: ^SDL.RWops) -> ^Animation ---
}
