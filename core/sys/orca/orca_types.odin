package orca

import "core:c"
import ilist "core:container/intrusive/list"

list_elt :: ilist.Node
list :: ilist.List

vec2   :: [2]f32
vec3   :: [3]f32
vec4   :: [4]f32
vec2i  :: [2]i32
mat2x3 :: #row_major matrix[2, 3]f32
rect   :: struct {
	x, y: f32,
	w, h: f32,
}

color :: distinct [4]f32

str8  :: string
str16 :: []u16
str32 :: []rune



clock_kind :: enum c.int {
	MONOTONIC, // clock that increment monotonically
	UPTIME,    // clock that increment monotonically during uptime
	DATE       // clock that is driven by the platform time
}

@(default_calling_convention="c", link_prefix="oc_")
foreign {
	clock_time :: proc(clock: clock_kind) -> f64 ---
}


//----------------------------------------------------------------
// Assert / Abort
//----------------------------------------------------------------

@(default_calling_convention="c", link_prefix="oc_")
foreign {
	abort_ext   :: proc(file: cstring, function: cstring, line: c.int, fmt: cstring, #c_vararg args: ..any) -> ! ---
	assert_fail :: proc(file: cstring, function: cstring, line: c.int, src: cstring, fmt: cstring, #c_vararg args: ..any) -> ! ---
}

//----------------------------------------------------------------
// Logging
//----------------------------------------------------------------
log_level :: enum c.int {
   	ERROR,
   	WARNING,
   	INFO,
}

log_output :: struct {}


@(default_calling_convention="c", link_prefix="oc_")
foreign {
	@(link_name="OC_LOG_DEFAULT_OUTPUT")
	LOG_DEFAULT_OUTPUT: ^log_output

	log_set_level  :: proc(level: log_level) ---
	log_set_output :: proc(output: ^log_output) ---
	log_ext        :: proc(level: log_level,
	                       function: cstring,
	                       file: cstring,
	                       line: c.int,
	                       fmt: cstring,
	                       #c_vararg args: ..any) ---
}

//--------------------------------------------------------------------------------
//NOTE(martin): base allocator
//--------------------------------------------------------------------------------
mem_reserve_proc :: proc "c" (ctx: ^base_allocator, size: u64) -> rawptr
mem_modify_proc  :: proc "c" (ctx: ^base_allocator, ptr: rawptr, size: u64)

base_allocator :: struct {
	reserve:  mem_reserve_proc,
	commit:   mem_modify_proc,
	decommit: mem_modify_proc,
	release:  mem_modify_proc,

}

@(default_calling_convention="c", link_prefix="oc_")
foreign {
	base_allocator_default :: proc() -> ^base_allocator ---
}


//--------------------------------------------------------------------------------
//NOTE(martin): memory arena
//--------------------------------------------------------------------------------

arena_chunk :: struct {
	listElt:   list_elt,
	ptr:       [^]byte,
	offset:    u64,
	committed: u64,
	cap:       u64,
}

arena :: struct {
	base: ^base_allocator,
	chunks: list,
	currentChunk: ^arena_chunk,
}

arena_scope :: struct {
	arena: ^arena,
    	chunk: ^arena_chunk,
    	offset: u64,
}

arena_options :: struct {
	base: ^base_allocator,
	reserve: u64,
}

@(default_calling_convention="c", link_prefix="oc_")
foreign {
	arena_init              :: proc(arena: ^arena) ---
	arena_init_with_options :: proc(arena: ^arena, #by_ptr options: arena_options) ---
	arena_cleanup           :: proc(arena: ^arena) ---

	arena_push         :: proc(arena: ^arena, size: u64) -> rawptr ---
	arena_push_aligned :: proc(arena: ^arena, size: u64, alignment: u32) -> rawptr ---

	arena_clear :: proc(arena: ^arena) ---

	arena_scope_begin :: proc(arena: ^arena) -> arena_scope ---
	arena_scope_end   :: proc(scope: arena_scope) ---
}



arena_push_type  :: proc "c" (arena: ^arena, $T: typeid) -> ^T {
	return (^T)(arena_push_aligned(arena, size_of(type), align_of(type)))
}
arena_push_array :: proc "c" (arena: ^arena, $T: typeid, #any_int count: int) -> []T {
	return ([^]T)(arena_push_aligned(arena, size_of(type)*u64(count), align_of(type)))[:count]
}





//----------------------------------------------------------------
// IO API
//----------------------------------------------------------------

file :: struct {
	h: u64,
}

file_open_flags :: distinct bit_set[file_open_flags_enum; u16]
file_open_flags_enum :: enum u16 {
	APPEND    = 1,
	TRUNCATE  = 2,
	CREATE    = 3,

	SYMLINK   = 4,
	NO_FOLLOW = 5,
	RESTRICT  = 6,
}

file_access :: distinct bit_set[file_access_enum; u16]

file_access_enum :: enum u16 {
	READ  = 1,
	WRITE = 2,
}

file_whence :: enum c.int {
	SET,
	END,
	CURRENT,
}

io_req_id :: distinct u64

io_op :: enum u32 {
	OPEN_AT = 0,
	CLOSE,

	FSTAT,

	SEEK,
	READ,
	WRITE,

	ERROR,
};

io_req :: struct {
	id:     io_req_id,
	op:     io_op,
	handle: file,

	offset: i64,
	size:   u64,

	using _: struct #raw_union {
		buffer: [^]byte,
		_: u64,
	},
	using _: struct #raw_union {
		open: struct {
			rights: file_access,
			flags:  file_open_flags,
		},
		whence: file_whence,
	},
}


io_error :: enum u32 {
	NONE = 0,
	UNKNOWN,
	OP,          // unsupported operation
	HANDLE,      // invalid handle
	PREV,        // previously had a fatal error (last error stored on handle)
	ARG,         // invalid argument or argument combination
	PERM,        // access denied
	SPACE,       // no space left
	NO_ENTRY,    // file or directory does not exist
	EXISTS,      // file already exists
	NOT_DIR,     // path element is not a directory
	DIR,         // attempted to write directory
	MAX_FILES,   // max open files reached
	MAX_LINKS,   // too many symbolic links in path
	PATH_LENGTH, // path too long
	FILE_SIZE,   // file too big
	OVERFLOW,    // offset too big
	NOT_READY,   // no data ready to be read/written
	MEM,         // failed to allocate memory
	INTERRUPT,   // operation interrupted by a signal
	PHYSICAL,    // physical IO error
	NO_DEVICE,   // device not found
	WALKOUT,     // attempted to walk out of root directory
}

io_cmp :: struct {
	id:    io_req_id,
	error: io_error,

	using _: struct #raw_union {
		result: i64,
		size:   u64,
		offset: i64,
		handle: file,
	}
}


@(default_calling_convention="c", link_prefix="oc_", link_suffix="_argptr_stub")
foreign {
	//----------------------------------------------------------------
	//TODO: complete io queue api
	//----------------------------------------------------------------
	io_wait_single_req :: proc(req: ^io_req) -> io_cmp ---
}

@(default_calling_convention="c", link_prefix="oc_")
foreign {
	//----------------------------------------------------------------
	// File IO wrapper API
	//----------------------------------------------------------------

	file_nil        :: proc() -> file ---
	file_is_nil     :: proc(handle: file) -> bool ---

	file_open       :: proc(path: string, rights: file_access, flags: file_open_flags) -> file ---
	file_open_at    :: proc(dir: file, path: string, rights: file_access, flags: file_open_flags) -> file ---
	file_close      :: proc(file: file) ---

	file_pos        :: proc(file: file) -> i64 ---
	file_seek       :: proc(file: file, offset: i64, whence: file_whence) -> i64 ---

	file_write      :: proc(file: file, size: u64, buffer: rawptr) -> u64 ---
	file_read       :: proc(file: file, size: u64, buffer: rawptr) -> u64 ---

	file_last_error :: proc(handle: file) -> io_error ---
}


//----------------------------------------------------------------
// File System wrapper API
//----------------------------------------------------------------

file_type :: enum c.int {
	UNKNOWN,
	REGULAR,
	DIRECTORY,
	SYMLINK,
	BLOCK,
	CHARACTER,
	FIFO,
	SOCKET,
}

file_perm :: distinct bit_set[file_perm_enum; u16]

file_perm_enum :: enum u16 {
	OTHER_EXEC  = 0,
	OTHER_WRITE = 1,
	OTHER_READ  = 2,

	GROUP_EXEC  = 3,
	GROUP_WRITE = 4,
	GROUP_READ  = 5,

	OWNER_EXEC  = 6,
	OWNER_WRITE = 7,
	OWNER_READ  = 8,

	STICKY_BIT  = 9,
	SET_GID     = 10,
	SET_UID     = 11,
}

datestamp :: struct {
	seconds:  i64, // seconds relative to NTP epoch.
	fraction: u64, // fraction of seconds elapsed since the time specified by seconds.
}

file_status :: struct {
	uid:  u64,
	type: file_type,
	perm: file_perm,
	size: u64,

    	creationDate:     datestamp,
    	accessDate:       datestamp,
    	modificationDate: datestamp,
}

@(default_calling_convention="c", link_prefix="oc_")
foreign {
	file_get_status :: proc(file: file) -> file_status ---
	file_size       :: proc(file: file) -> u64 ---
}



file_open_with_dialog_elt :: struct {
	listElt: list_elt,
	file:    file,
}

file_open_with_dialog_result :: struct {
	button:    file_dialog_button,
	file:      file,
	selection: list,
}


@(default_calling_convention="c", link_prefix="oc_", link_suffix="_argptr_stub")
foreign {
	file_open_with_request :: proc(path: string, rights: file_access, flags: file_open_flags) -> file ---
	file_open_with_dialog :: proc(arena: ^arena, rights: file_access, flags: file_open_flags, #by_ptr desc: file_dialog_desc) -> file_open_with_dialog_result ---
}


//--------------------------------------------------------------------
// App typedefs, enums and constants
//--------------------------------------------------------------------


window :: struct {
	h: u64,
}

mouse_cursor :: enum c.int {
	ARROW,
	RESIZE_0,
	RESIZE_90,
	RESIZE_45,
	RESIZE_135,
	TEXT,
}

window_style :: distinct bit_set[window_style_enum; u32]

window_style_enum :: enum u32 {
	NO_TITLE   = 0,
	FIXED_SIZE = 1,
	NO_CLOSE   = 2,
	NO_MINIFY  = 3,
	NO_FOCUS   = 4,
	FLOAT      = 5,
	POPUPMENU  = 6,
	NO_BUTTONS = 7,
}

event_type :: enum c.int {
	NONE,
	KEYBOARD_MODS, //TODO: remove, keep only key?
	KEYBOARD_KEY,
	KEYBOARD_CHAR,
	MOUSE_BUTTON,
	MOUSE_MOVE,
	MOUSE_WHEEL,
	MOUSE_ENTER,
	MOUSE_LEAVE,
	CLIPBOARD_PASTE,
	WINDOW_RESIZE,
	WINDOW_MOVE,
	WINDOW_FOCUS,
	WINDOW_UNFOCUS,
	WINDOW_HIDE, // rename to minimize?
	WINDOW_SHOW, // rename to restore?
	WINDOW_CLOSE,
	PATHDROP,
	FRAME,
	QUIT,
}

key_action :: enum c.int {
	NO_ACTION,
	PRESS,
	RELEASE,
	REPEAT,
}

scan_code :: enum c.int {
	UNKNOWN       = 0,
	SPACE         = 32,
	APOSTROPHE    = 39,
	COMMA         = 44,
	MINUS         = 45,
	PERIOD        = 46,
	SLASH         = 47,
	_0            = 48,
	_1            = 49,
	_2            = 50,
	_3            = 51,
	_4            = 52,
	_5            = 53,
	_6            = 54,
	_7            = 55,
	_8            = 56,
	_9            = 57,
	SEMICOLON     = 59,
	EQUAL         = 61,
	LEFT_BRACKET  = 91,
	BACKSLASH     = 92,
	RIGHT_BRACKET = 93,
	GRAVE_ACCENT  = 96,
	A             = 97,
	B             = 98,
	C             = 99,
	D             = 100,
	E             = 101,
	F             = 102,
	G             = 103,
	H             = 104,
	I             = 105,
	J             = 106,
	K             = 107,
	L             = 108,
	M             = 109,
	N             = 110,
	O             = 111,
	P             = 112,
	Q             = 113,
	R             = 114,
	S             = 115,
	T             = 116,
	U             = 117,
	V             = 118,
	W             = 119,
	X             = 120,
	Y             = 121,
	Z             = 122,
	WORLD_1       = 161,
	WORLD_2       = 162,
	ESCAPE        = 256,
	ENTER         = 257,
	TAB           = 258,
	BACKSPACE     = 259,
	INSERT        = 260,
	DELETE        = 261,
	RIGHT         = 262,
	LEFT          = 263,
	DOWN          = 264,
	UP            = 265,
	PAGE_UP       = 266,
	PAGE_DOWN     = 267,
	HOME          = 268,
	END           = 269,
	CAPS_LOCK     = 280,
	SCROLL_LOCK   = 281,
	NUM_LOCK      = 282,
	PRINT_SCREEN  = 283,
	PAUSE         = 284,
	F1            = 290,
	F2            = 291,
	F3            = 292,
	F4            = 293,
	F5            = 294,
	F6            = 295,
	F7            = 296,
	F8            = 297,
	F9            = 298,
	F10           = 299,
	F11           = 300,
	F12           = 301,
	F13           = 302,
	F14           = 303,
	F15           = 304,
	F16           = 305,
	F17           = 306,
	F18           = 307,
	F19           = 308,
	F20           = 309,
	F21           = 310,
	F22           = 311,
	F23           = 312,
	F24           = 313,
	F25           = 314,
	KP_0          = 320,
	KP_1          = 321,
	KP_2          = 322,
	KP_3          = 323,
	KP_4          = 324,
	KP_5          = 325,
	KP_6          = 326,
	KP_7          = 327,
	KP_8          = 328,
	KP_9          = 329,
	KP_DECIMAL    = 330,
	KP_DIVIDE     = 331,
	KP_MULTIPLY   = 332,
	KP_SUBTRACT   = 333,
	KP_ADD        = 334,
	KP_ENTER      = 335,
	KP_EQUAL      = 336,
	LEFT_SHIFT    = 340,
	LEFT_CONTROL  = 341,
	LEFT_ALT      = 342,
	LEFT_SUPER    = 343,
	RIGHT_SHIFT   = 344,
	RIGHT_CONTROL = 345,
	RIGHT_ALT     = 346,
	RIGHT_SUPER   = 347,
	MENU          = 348,
}

key_code :: enum c.int {
	UNKNOWN = 0,
	SPACE = ' ',
	APOSTROPHE = '\'',
	COMMA = ',',
	MINUS = '-',
	PERIOD = '.',
	SLASH = '/',
	_0 = '0',
	_1 = '1',
	_2 = '2',
	_3 = '3',
	_4 = '4',
	_5 = '5',
	_6 = '6',
	_7 = '7',
	_8 = '8',
	_9 = '9',
	SEMICOLON = ';',
	EQUAL = '=',
	LEFT_BRACKET = '[',
	BACKSLASH = '\\',
	RIGHT_BRACKET = ']',
	GRAVE_ACCENT = '`',
	A = 'a',
	B = 'b',
	C = 'c',
	D = 'd',
	E = 'e',
	F = 'f',
	G = 'g',
	H = 'h',
	I = 'i',
	J = 'j',
	K = 'k',
	L = 'l',
	M = 'm',
	N = 'n',
	O = 'o',
	P = 'p',
	Q = 'q',
	R = 'r',
	S = 's',
	T = 't',
	U = 'u',
	V = 'v',
	W = 'w',
	X = 'x',
	Y = 'y',
	Z = 'z',
	WORLD_1,
	WORLD_2,
	ESCAPE,
	ENTER,
	TAB,
	BACKSPACE,
	INSERT,
	DELETE,
	RIGHT,
	LEFT,
	DOWN,
	UP,
	PAGE_UP,
	PAGE_DOWN,
	HOME,
	END,
	CAPS_LOCK,
	SCROLL_LOCK,
	NUM_LOCK,
	PRINT_SCREEN,
	PAUSE,
	F1,
	F2,
	F3,
	F4,
	F5,
	F6,
	F7,
	F8,
	F9,
	F10,
	F11,
	F12,
	F13,
	F14,
	F15,
	F16,
	F17,
	F18,
	F19,
	F20,
	F21,
	F22,
	F23,
	F24,
	F25,
	KP_0,
	KP_1,
	KP_2,
	KP_3,
	KP_4,
	KP_5,
	KP_6,
	KP_7,
	KP_8,
	KP_9,
	KP_DECIMAL,
	KP_DIVIDE,
	KP_MULTIPLY,
	KP_SUBTRACT,
	KP_ADD,
	KP_ENTER,
	KP_EQUAL,
	LEFT_SHIFT,
	LEFT_CONTROL,
	LEFT_ALT,
	LEFT_SUPER,
	RIGHT_SHIFT,
	RIGHT_CONTROL,
	RIGHT_ALT,
	RIGHT_SUPER,
	MENU,
}

keymod_flags :: distinct bit_set[keymod_flags_enum; c.int]
keymod_flags_enum :: enum c.int {
	ALT           = 0,
	SHIFT         = 1,
	CTRL          = 2,
	CMD           = 3,
	MAIN_MODIFIER = 4, // CMD on Mac, CTRL on Win32
}


mouse_button :: enum {
	LEFT   = 0x00,
	RIGHT  = 0x01,
	MIDDLE = 0x02,
	EXT1   = 0x03,
	EXT2   = 0x04,
}

key_event :: struct { // keyboard and mouse buttons input
	action:     key_action,
	scanCode:   scan_code,
	keyCode:    key_code,
	button:     mouse_button,
	mods:       keymod_flags,
	clickCount: u8,
}

char_event :: struct { // character input
	codepoint: rune,
	sequence:  [8]u8 `fmt:"s,seqLen"`,
	seqLen:    u8,
}

mouse_event :: struct { // mouse move/scroll
	x:      f32,
	y:      f32,
	deltaX: f32,
	deltaY: f32,
	mods:   keymod_flags,
}

move_event :: struct { // window resize / move
	frame:   rect,
	content: rect,
}

event :: struct {
	//TODO clipboard and path drop
	window: window,
	type:   event_type,

	using _: struct #raw_union {
		key:       key_event,
		character: char_event,
		mouse:     mouse_event,
		move:      move_event,
		paths:     str8_list,
	},
}

file_dialog_kind :: enum c.int {
	SAVE,
	OPEN,
}

file_dialog_flags :: distinct bit_set[file_dialog_flags_enum; u32]
file_dialog_flags_enum :: enum u32 {
	FILES              = 0,
	DIRECTORIES        = 1,
	MULTIPLE           = 2,
	CREATE_DIRECTORIES = 3,
}

file_dialog_desc :: struct {
	kind:      file_dialog_kind,
	flags:     file_dialog_flags,
	title:     str8,
	okLabel:   str8,
	startAt:   file,
	startPath: str8,
	filters:   str8_list,
	//... later customization options with checkboxes / radiobuttons
}

file_dialog_button :: enum c.int {
	CANCEL = 0,
	OK,
}

file_dialog_result :: struct {
	button:    file_dialog_button,
	path:      str8,
	selection: str8_list,
}



@(default_calling_convention="c", link_prefix="oc_", link_suffix="_argptr_stub")
foreign {
	window_set_title     :: proc(title:  str8) ---
	window_set_size      :: proc(size:   vec2) ---

	clipboard_set_string :: proc(string: str8) ---
}

@(default_calling_convention="c", link_prefix="oc_", link_suffix="_argptr_stub")
foreign {
	request_quit :: proc() ---
	scancode_to_keycode :: proc(scanCode: scan_code) -> key_code ---
}


/*NOTE:
	by convention, functions that take an arena and return a path
	allocated on that arena allocate 1 more character and null-terminate
	the string.
*/

@(default_calling_convention="c", link_prefix="oc_")
foreign {
	path_slice_directory :: proc(path: string) -> string ---
	path_slice_filename  :: proc(path: string) -> string ---

	path_split           :: proc(arena: ^arena, path: string) -> str8_list ---
	path_join            :: proc(arena: ^arena, elements: str8_list) -> string ---
	path_append          :: proc(arena: ^arena, parent, relPath: string) -> string ---

	path_is_absolute     :: proc(path: string) -> bool ---
}