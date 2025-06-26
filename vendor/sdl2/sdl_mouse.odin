package sdl2

import "core:c"

when ODIN_OS == .Windows {
	@(ignore_duplicates)
	foreign import lib "SDL2.lib"
} else {
	@(ignore_duplicates)
	foreign import lib "system:SDL2"
}

Cursor :: struct {}

BUTTON :: #force_inline proc "c" (X: c.int) -> c.int { return 1 << u32(X-1) }
BUTTON_LEFT     :: 1
BUTTON_MIDDLE   :: 2
BUTTON_RIGHT    :: 3
BUTTON_X1       :: 4
BUTTON_X2       :: 5
BUTTON_LMASK    :: 1<<(BUTTON_LEFT-1)
BUTTON_MMASK    :: 1<<(BUTTON_MIDDLE-1)
BUTTON_RMASK    :: 1<<(BUTTON_RIGHT-1)
BUTTON_X1MASK   :: 1<<(BUTTON_X1-1)
BUTTON_X2MASK   :: 1<<(BUTTON_X2-1)

SystemCursor :: enum c.int {
	ARROW,     /**< Arrow */
	IBEAM,     /**< I-beam */
	WAIT,      /**< Wait */
	CROSSHAIR, /**< Crosshair */
	WAITARROW, /**< Small wait cursor (or Wait if not available) */
	SIZENWSE,  /**< Double arrow pointing northwest and southeast */
	SIZENESW,  /**< Double arrow pointing northeast and southwest */
	SIZEWE,    /**< Double arrow pointing west and east */
	SIZENS,    /**< Double arrow pointing north and south */
	SIZEALL,   /**< Four pointed arrow pointing north, south, east, and west */
	NO,        /**< Slashed circle or crossbones */
	HAND,      /**< Hand */
	NUM_SYSTEM_CURSORS,
}

MouseWheelDirection :: enum c.int {
	NORMAL,    /**< The scroll direction is normal */
	FLIPPED,   /**< The scroll direction is flipped / natural */
}

@(default_calling_convention="c", link_prefix="SDL_")
foreign lib {
	GetMouseFocus         :: proc() -> ^Window ---
	GetMouseState         :: proc(x, y: ^c.int) -> u32 ---
	GetGlobalMouseState   :: proc(x, y: ^c.int) -> u32 ---
	GetRelativeMouseState :: proc(x, y: ^c.int) -> u32 ---
	WarpMouseInWindow     :: proc(window: ^Window, x, y: c.int) ---
	WarpMouseGlobal       :: proc(x, y: c.int) -> c.int ---
	SetRelativeMouseMode  :: proc(enabled: bool) -> c.int ---
	CaptureMouse          :: proc(enabled: bool) -> c.int ---
	GetRelativeMouseMode  :: proc() -> bool ---
	CreateCursor          :: proc(data: [^]u8, mask: [^]u8, w, h, hot_x, hot_y: c.int) -> ^Cursor ---
	CreateColorCursor     :: proc(surface: ^Surface, hot_x, hot_y: c.int) -> ^Cursor ---
	CreateSystemCursor    :: proc(id: SystemCursor) -> ^Cursor ---
	SetCursor             :: proc(cursor: ^Cursor) ---
	GetCursor             :: proc() -> ^Cursor ---
	GetDefaultCursor      :: proc() -> ^Cursor ---
	FreeCursor            :: proc(cursor: ^Cursor) ---
	ShowCursor            :: proc(toggle: c.int) -> c.int ---
}
