package sdl3

import "core:c"

MouseID :: distinct Uint32

Cursor :: struct {}

SystemCursor :: enum c.int {
	DEFAULT,      /**< Default cursor. Usually an arrow. */
	TEXT,         /**< Text selection. Usually an I-beam. */
	WAIT,         /**< Wait. Usually an hourglass or watch or spinning ball. */
	CROSSHAIR,    /**< Crosshair. */
	PROGRESS,     /**< Program is busy but still interactive. Usually it's WAIT with an arrow. */
	NWSE_RESIZE,  /**< Double arrow pointing northwest and southeast. */
	NESW_RESIZE,  /**< Double arrow pointing northeast and southwest. */
	EW_RESIZE,    /**< Double arrow pointing west and east. */
	NS_RESIZE,    /**< Double arrow pointing north and south. */
	MOVE,         /**< Four pointed arrow pointing north, south, east, and west. */
	NOT_ALLOWED,  /**< Not permitted. Usually a slashed circle or crossbones. */
	POINTER,      /**< Pointer that indicates a link. Usually a pointing hand. */
	NW_RESIZE,    /**< Window resize top-left. This may be a single arrow or a double arrow like NWSE_RESIZE. */
	N_RESIZE,     /**< Window resize top. May be NS_RESIZE. */
	NE_RESIZE,    /**< Window resize top-right. May be NESW_RESIZE. */
	E_RESIZE,     /**< Window resize right. May be EW_RESIZE. */
	SE_RESIZE,    /**< Window resize bottom-right. May be NWSE_RESIZE. */
	S_RESIZE,     /**< Window resize bottom. May be NS_RESIZE. */
	SW_RESIZE,    /**< Window resize bottom-left. May be NESW_RESIZE. */
	W_RESIZE,     /**< Window resize left. May be EW_RESIZE. */
}

MouseWheelDirection :: enum c.int {
	NORMAL,    /**< The scroll direction is normal */
	FLIPPED,   /**< The scroll direction is flipped / natural */
}

MouseButtonFlags :: distinct bit_set[MouseButtonFlag; Uint32]
MouseButtonFlag :: enum Uint32 {
	LEFT   = 1 - 1,
	MIDDLE = 2 - 1,
	RIGHT  = 3 - 1,
	X1     = 4 - 1,
	X2     = 5 - 1,
}

BUTTON_LEFT   :: 1
BUTTON_MIDDLE :: 2
BUTTON_RIGHT  :: 3
BUTTON_X1     :: 4
BUTTON_X2     :: 5

BUTTON_LMASK  :: MouseButtonFlags{.LEFT}
BUTTON_MMASK  :: MouseButtonFlags{.MIDDLE}
BUTTON_RMASK  :: MouseButtonFlags{.RIGHT}
BUTTON_X1MASK :: MouseButtonFlags{.X1}
BUTTON_X2MASK :: MouseButtonFlags{.X2}

@(default_calling_convention="c", link_prefix="SDL_", require_results)
foreign lib {
	HasMouse                   :: proc() -> bool ---
	GetMice                    :: proc(count: ^c.int) -> [^]MouseID ---
	GetMouseNameForID          :: proc(instance_id: MouseID) -> cstring ---
	GetMouseFocus              :: proc() -> ^Window ---
	GetMouseState              :: proc(x, y: ^f32) -> MouseButtonFlags ---
	GetGlobalMouseState        :: proc(x, y: ^f32) -> MouseButtonFlags ---
	GetRelativeMouseState      :: proc(x, y: ^f32) -> MouseButtonFlags ---
	WarpMouseInWindow          :: proc(window: ^Window, x, y: f32) ---
	WarpMouseGlobal            :: proc(x, y: f32) -> bool ---
	SetWindowRelativeMouseMode :: proc(window: ^Window, enabled: bool) -> bool ---
	GetWindowRelativeMouseMode :: proc(window: ^Window) -> bool ---
	CaptureMouse               :: proc(enabled: bool) -> bool ---
	CreateCursor               :: proc(data: [^]byte, mask: [^]Uint8, w, h, hot_x, hot_y: c.int) -> ^Cursor ---
	CreateColorCursor          :: proc(surface: ^Surface, hot_x, hot_y: c.int) -> ^Cursor ---
	CreateSystemCursor         :: proc(id: SystemCursor) -> ^Cursor ---
	SetCursor                  :: proc(cursor: ^Cursor) -> bool ---
	GetCursor                  :: proc() -> ^Cursor ---
	GetDefaultCursor           :: proc() -> ^Cursor ---
	DestroyCursor              :: proc(cursor: ^Cursor) ---
	ShowCursor                 :: proc() -> bool ---
	HideCursor                 :: proc() -> bool ---
	CursorVisible              :: proc() -> bool ---
}