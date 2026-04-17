package sdl3

import "core:c"

Tray :: struct {}
TrayMenu :: struct {}
TrayEntry :: struct {}

TrayEntryFlags :: distinct bit_set[TrayEntryFlag; Uint32]
TrayEntryFlag :: enum Uint32 {
	BUTTON   = 0,  /**< Make the entry a simple button. Required. */
	CHECKBOX = 1,  /**< Make the entry a checkbox. Required. */
	SUBMENU  = 2,  /**< Prepare the entry to have a submenu. Required */
	DISABLED = 31, /**< Make the entry disabled. Optional. */
	CHECKED  = 30, /**< Make the entry checked. This is valid only for checkboxes. Optional. */
}

TRAYENTRY_BUTTON    :: TrayEntryFlags{.BUTTON}   /**< Make the entry a simple button. Required. */
TRAYENTRY_CHECKBOX  :: TrayEntryFlags{.CHECKBOX} /**< Make the entry a checkbox. Required. */
TRAYENTRY_SUBMENU   :: TrayEntryFlags{.SUBMENU}  /**< Prepare the entry to have a submenu. Required */
TRAYENTRY_DISABLED  :: TrayEntryFlags{.DISABLED} /**< Make the entry disabled. Optional. */
TRAYENTRY_CHECKED   :: TrayEntryFlags{.CHECKED}  /**< Make the entry checked. This is valid only for checkboxes. Optional. */

TrayCallback :: #type proc "c" (userdata: rawptr, entry: ^TrayEntry)
TrayClickCallback :: #type proc "c" (userdata: rawptr, tray: ^Tray) -> bool

PROP_TRAY_CREATE_ICON_POINTER                 :: "SDL.tray.create.icon"
PROP_TRAY_CREATE_TOOLTIP_STRING               :: "SDL.tray.create.tooltip"
PROP_TRAY_CREATE_USERDATA_POINTER             :: "SDL.tray.create.userdata"
PROP_TRAY_CREATE_LEFTCLICK_CALLBACK_POINTER   :: "SDL.tray.create.leftclick_callback"
PROP_TRAY_CREATE_RIGHTCLICK_CALLBACK_POINTER  :: "SDL.tray.create.rightclick_callback"
PROP_TRAY_CREATE_MIDDLECLICK_CALLBACK_POINTER :: "SDL.tray.create.middleclick_callback"

@(default_calling_convention="c", link_prefix="SDL_", require_results)
foreign lib {
	CreateTray               :: proc(icon: ^Surface, tooltip: cstring) -> ^Tray ---
	CreateTrayWithProperties :: proc(props: PropertiesID) -> ^Tray ---
	SetTrayIcon              :: proc(tray: ^Tray, icon: ^Surface) ---
	SetTrayTooltip           :: proc(tray: ^Tray, tooltip: cstring) ---
	CreateTrayMenu           :: proc(tray: ^Tray) -> ^TrayMenu ---
	CreateTraySubmenu        :: proc(entry: ^TrayEntry) -> ^TrayMenu ---
	GetTrayMenu              :: proc(tray: ^Tray) -> TrayMenu ---
	GetTraySubmenu           :: proc(entry: ^TrayEntry) -> ^TrayMenu ---
	GetTrayEntries           :: proc(menu: ^TrayMenu, size: ^c.int) -> [^]^TrayEntry ---
	RemoveTrayEntry          :: proc(entry: ^TrayEntry) ---
	InsertTrayEntryAt        :: proc(menu: ^TrayMenu, pos: c.int, label: cstring, flags: TrayEntryFlags) -> ^TrayEntry ---
	SetTrayEntryLabel        :: proc(entry: ^TrayEntry, label: cstring) ---
	GetTrayEntryLabel        :: proc(entry: ^TrayEntry) -> cstring ---
	SetTrayEntryChecked      :: proc(entry: ^TrayEntry, checked: bool) ---
	GetTrayEntryChecked      :: proc(entry: ^TrayEntry) -> bool ---
	SetTrayEntryEnabled      :: proc(entry: ^TrayEntry, enabled: bool) ---
	GetTrayEntryEnabled      :: proc(entry: ^TrayEntry) -> bool ---
	SetTrayEntryCallback     :: proc(entry: ^TrayEntry, callback: TrayCallback, userdata: rawptr) ---
	ClickTrayEntry           :: proc(entry: ^TrayEntry) ---
	DestroyTray              :: proc(tray: ^Tray) ---
	GetTrayEntryParent       :: proc(entry: ^TrayEntry) -> ^TrayMenu ---
	GetTrayMenuParentEntry   :: proc(menu: ^TrayMenu) -> ^TrayEntry ---
	GetTrayMenuParentTray    :: proc(menu: ^TrayMenu) -> ^Tray ---
	UpdateTrays              :: proc() ---
}
