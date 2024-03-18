package orca

import "core:c"

ui_key :: struct {
	hash: u64
}

ui_axis :: enum c.int {
	X,
	Y,
}

ui_align :: enum c.int {
	START,
	END,
	CENTER,
}

ui_layout_align :: [2]ui_align

ui_layout :: struct {
	axis: ui_axis,
	spacing: f32,
	margin: [2]f32,
	align: ui_layout_align,
}

ui_size_kind :: enum c.int {
	TEXT,
	PIXELS,
	CHILDREN,
	PARENT,
	PARENT_MINUS_PIXELS,
}

ui_size :: struct {
	kind: ui_size_kind,
	value: f32,
	relax: f32,
	minSize: f32,
}

ui_box_size :: [2]ui_size
ui_box_floating :: [2]c.bool

//NOTE: flags for axis-dependent properties (e.g. UI_STYLE_FLOAT_X/Y) need to be consecutive bits
//      in order to play well with axis agnostic functions
ui_style_mask :: enum u64 {
	NONE = 0,
	SIZE_WIDTH = 1 << 1,
	SIZE_HEIGHT = 1 << 2,
	LAYOUT_AXIS = 1 << 3,
	LAYOUT_ALIGN_X = 1 << 4,
	LAYOUT_ALIGN_Y = 1 << 5,
	LAYOUT_SPACING = 1 << 6,
	LAYOUT_MARGIN_X = 1 << 7,
	LAYOUT_MARGIN_Y = 1 << 8,
	FLOAT_X = 1 << 9,
	FLOAT_Y = 1 << 10,
	COLOR = 1 << 11,
	BG_COLOR = 1 << 12,
	BORDER_COLOR = 1 << 13,
	BORDER_SIZE = 1 << 14,
	ROUNDNESS = 1 << 15,
	FONT = 1 << 16,
	FONT_SIZE = 1 << 17,
	ANIMATION_TIME = 1 << 18,
	ANIMATION_MASK = 1 << 19,

	//masks
	SIZE = SIZE_WIDTH | SIZE_HEIGHT,

	LAYOUT_MARGINS = LAYOUT_MARGIN_X | LAYOUT_MARGIN_Y,

	LAYOUT = LAYOUT_AXIS | LAYOUT_ALIGN_X | LAYOUT_ALIGN_Y | LAYOUT_SPACING | LAYOUT_MARGIN_X | LAYOUT_MARGIN_Y,

	FLOAT = FLOAT_X | FLOAT_Y,

	MASK_INHERITED = COLOR | FONT | FONT_SIZE | ANIMATION_TIME | ANIMATION_MASK,
}

ui_style :: struct {
	size: ui_box_size,
	layout: ui_layout,
	floating: ui_box_floating,
	floatTarget: vec2,
	_color: color,
	bgColor: color,
	borderColor: color,
	font: font,
	fontSize: f32,
	borderSize: f32,
	roundness: f32,
	animationTime: f32,
	animationMask: ui_style_mask,
}

ui_palette :: struct {
	red0: color,
	red1: color,
	red2: color,
	red3: color,
	red4: color,
	red5: color,
	red6: color,
	red7: color,
	red8: color,
	red9: color,
	orange0: color,
	orange1: color,
	orange2: color,
	orange3: color,
	orange4: color,
	orange5: color,
	orange6: color,
	orange7: color,
	orange8: color,
	orange9: color,
	amber0: color,
	amber1: color,
	amber2: color,
	amber3: color,
	amber4: color,
	amber5: color,
	amber6: color,
	amber7: color,
	amber8: color,
	amber9: color,
	yellow0: color,
	yellow1: color,
	yellow2: color,
	yellow3: color,
	yellow4: color,
	yellow5: color,
	yellow6: color,
	yellow7: color,
	yellow8: color,
	yellow9: color,
	lime0: color,
	lime1: color,
	lime2: color,
	lime3: color,
	lime4: color,
	lime5: color,
	lime6: color,
	lime7: color,
	lime8: color,
	lime9: color,
	lightGreen0: color,
	lightGreen1: color,
	lightGreen2: color,
	lightGreen3: color,
	lightGreen4: color,
	lightGreen5: color,
	lightGreen6: color,
	lightGreen7: color,
	lightGreen8: color,
	lightGreen9: color,
	green0: color,
	green1: color,
	green2: color,
	green3: color,
	green4: color,
	green5: color,
	green6: color,
	green7: color,
	green8: color,
	green9: color,
	teal0: color,
	teal1: color,
	teal2: color,
	teal3: color,
	teal4: color,
	teal5: color,
	teal6: color,
	teal7: color,
	teal8: color,
	teal9: color,
	cyan0: color,
	cyan1: color,
	cyan2: color,
	cyan3: color,
	cyan4: color,
	cyan5: color,
	cyan6: color,
	cyan7: color,
	cyan8: color,
	cyan9: color,
	lightBlue0: color,
	lightBlue1: color,
	lightBlue2: color,
	lightBlue3: color,
	lightBlue4: color,
	lightBlue5: color,
	lightBlue6: color,
	lightBlue7: color,
	lightBlue8: color,
	lightBlue9: color,
	blue0: color,
	blue1: color,
	blue2: color,
	blue3: color,
	blue4: color,
	blue5: color,
	blue6: color,
	blue7: color,
	blue8: color,
	blue9: color,
	indigo0: color,
	indigo1: color,
	indigo2: color,
	indigo3: color,
	indigo4: color,
	indigo5: color,
	indigo6: color,
	indigo7: color,
	indigo8: color,
	indigo9: color,
	violet0: color,
	violet1: color,
	violet2: color,
	violet3: color,
	violet4: color,
	violet5: color,
	violet6: color,
	violet7: color,
	violet8: color,
	violet9: color,
	purple0: color,
	purple1: color,
	purple2: color,
	purple3: color,
	purple4: color,
	purple5: color,
	purple6: color,
	purple7: color,
	purple8: color,
	purple9: color,
	pink0: color,
	pink1: color,
	pink2: color,
	pink3: color,
	pink4: color,
	pink5: color,
	pink6: color,
	pink7: color,
	pink8: color,
	pink9: color,
	grey0: color,
	grey1: color,
	grey2: color,
	grey3: color,
	grey4: color,
	grey5: color,
	grey6: color,
	grey7: color,
	grey8: color,
	grey9: color,
	black: color,
	white: color,
}

// TODO exteern
// ui_palette: UI_DARK_PALETTE
// ui_palette: UI_LIGHT_PALETTE

ui_theme :: struct {
	white: color,
	primary: color,
	primaryHover: color,
	primaryActive: color,
	border: color,
	fill0: color,
	fill1: color,
	fill2: color,
	bg0: color,
	bg1: color,
	bg2: color,
	bg3: color,
	bg4: color,
	text0: color,
	text1: color,
	text2: color,
	text3: color,
	sliderThumbBorder: color,
	elevatedBorder: color,

	roundnessSmall: f32,
	roundnessMedium: f32,
	roundnessLarge: f32,

	palette: ^ui_palette,
}

@export UI_DARK_THEME: ui_theme
@export UI_LIGHT_THEME: ui_theme

ui_tag :: struct {
	hash: u64,
}

ui_selector_kind :: enum c.int {
	ANY,
	OWNER,
	TEXT,
	TAG,
	STATUS,
	KEY,
}

ui_status :: enum u8 {
	NONE = 0,
	HOVER = 1 << 1,
	HOT = 1 << 2,
	ACTIVE = 1 << 3,
	DRAGGING = 1 << 4,
}

ui_selector_op :: enum c.int {
	DESCENDANT = 0,
	AND = 1,
}

ui_selector :: struct {
	listElt: list_elt,
	kind: ui_selector_kind,
	op: ui_selector_op,

	type: struct #raw_union {
		text: str8,
		key: ui_key,
		tag: ui_tag,
		status: ui_status,
	}
}

ui_pattern :: struct {
	l: list,
}

ui_style_rule :: struct {
	boxElt: list_elt,
	buildElt: list_elt,
	tmpElt: list_elt,

	owner: ^ui_box,
	pattern: ui_pattern,
	mask: ui_style_mask,
	style: ^ui_style,
}

ui_sig :: struct {
	box: ^ui_box,

	mouse: vec2,
	delta: vec2,
	wheel: vec2,

	pressed: c.bool,
	released: c.bool,
	clicked: c.bool,
	doubleClicked: c.bool,
	tripleClicked: c.bool,
	rightPressed: c.bool,

	dragging: c.bool,
	hovering: c.bool,

	pasted: c.bool,

}

ui_box_draw_proc :: proc "c" (box: ^ui_box, data: rawptr)

ui_flags :: enum c.int {
	NONE = 0,
	CLICKABLE = (1 << 0),
	SCROLL_WHEEL_X = (1 << 1),
	SCROLL_WHEEL_Y = (1 << 2),
	BLOCK_MOUSE = (1 << 3),
	HOT_ANIMATION = (1 << 4),
	ACTIVE_ANIMATION = (1 << 5),
	//WARN: these two following flags need to be kept as consecutive bits to
	//      play well with axis-agnostic functions
	OVERFLOW_ALLOW_X = (1 << 6),
	OVERFLOW_ALLOW_Y = (1 << 7),
	CLIP = (1 << 8),
	DRAW_BACKGROUND = (1 << 9),
	DRAW_FOREGROUND = (1 << 10),
	DRAW_BORDER = (1 << 11),
	DRAW_TEXT = (1 << 12),
	DRAW_PROC = (1 << 13),

	OVERLAY = (1 << 16),
}

ui_box :: struct {
	// hierarchy
	listElt: list_elt,
	children: list,
	parent: ^ui_box,

	overlayElt: list_elt,

	// keying and caching
	bucketElt: list_elt,
	key: ui_key,
	frameCounter: u64,

	// builder-provided info
	flags: ui_flags,
	string: str8,
	tags: list,

	drawProc: ui_box_draw_proc,
	drawData: rawptr,

	// styling
	beforeRules: list,
	afterRules: list,

	//ui_style_tag tag
	targetStyle: ^ui_style,
	style: ui_style,
	z: u32,

	floatPos: vec2,
	childrenSum: [2]f32,
	spacing: [2]f32,
	minSize: [2]f32,
	rect: rect,

	// signals
	sig: ^ui_sig,

	// stateful behaviour
	fresh: c.bool,
	closed: c.bool,
	parentClosed: c.bool,
	dragging: c.bool,
	hot: c.bool,
	active: c.bool,
	scroll: vec2,
	pressedMouse: vec2,

	// animation data
	hotTransition: f32,
	activeTransition: f32,
}

UI_MAX_INPUT_CHAR_PER_FRAME :: 64

ui_input_text :: struct {
	count: u8,
	codePoints: [UI_MAX_INPUT_CHAR_PER_FRAME]utf32,
}

ui_stack_elt :: struct {
	parent: ^ui_stack_elt,

	_: struct #raw_union {
		 box: ^ui_box,
		 size: ui_size,
		 clip: rect,
	}
}

ui_tag_elt :: struct {
	listElt: list_elt,
	tag: ui_tag,
}

UI_BOX_MAP_BUCKET_COUNT :: 1024

ui_edit_move :: enum c.int {
	NONE,
	CHAR,
	WORD,
	LINE,
}

ui_context :: struct {
	init: c.bool,

	input: input_state,

	frameCounter: u64,
	frameTime: f64,
	lastFrameDuration: f64,

	frameArena: arena,
	boxPool: pool,
	boxMap: [UI_BOX_MAP_BUCKET_COUNT]list,

	root: ^ui_box,
	overlay: ^ui_box,
	overlayList: list,
	boxStack: ^ui_stack_elt,
	clipStack: ^ui_stack_elt,

	nextBoxBeforeRules: list,
	nextBoxAfterRules: list,
	nextBoxTags: list,

	z: u32,
	hovered: ^ui_box,

	focus: ^ui_box,
	editCursor: i32,
	editMark: i32,
	editFirstDisplayedChar: i32,
	editCursorBlinkStart: f64,
	editSelectionMode: ui_edit_move,
	editWordSelectionInitialCursor: i32,
	editWordSelectionInitialMark: i32,

	clipboardRegistered: c.bool,

	theme: ^ui_theme,
}

ui_text_box_result :: struct {
	changed: c.bool,
	accepted: c.bool,
	text: str8,
}

ui_select_popup_info :: struct {
	changed: bool,
	selectedIndex: int, // -1 if nothing is selected
	optionCount: int,
	options: [^]str8,
	placeholder: str8,
}

ui_radio_group_info :: struct {
	changed: bool,
	selectedIndex: int, // -1 if nothing is selected
	optionCount: int,
	options: [^]str8,
}

//----------------------------------------------------------------
// Context and frame lifecycle
//----------------------------------------------------------------

@(default_calling_convention="c", link_prefix="oc_")
foreign {
	ui_init :: proc(ctx: ^ui_context) ---
	ui_get_context :: proc() -> ^ui_context ---
	ui_set_context :: proc(ctx: ^ui_context) ---

	ui_process_event :: proc(event: ^event) ---
	ui_begin_frame :: proc(size: vec2, defaultStyle: ^ui_style, mask: ui_style_mask) ---
	ui_end_frame :: proc() ---
	ui_draw :: proc() ---
}

@(deferred_none=ui_end_frame)
ui_frame :: proc "c" (size: vec2, defaultStyle: ^ui_style, mask: ui_style_mask) {
	ui_begin_frame(size, defaultStyle, mask)
}
ui_frame_scoped :: ui_frame

//----------------------------------------------------------------
// Common widget helpers
//----------------------------------------------------------------
@(default_calling_convention="c", link_prefix="oc_")
foreign {
	ui_label :: proc(label: cstring) -> ui_sig ---
	ui_label_str8 :: proc(label: str8) -> ui_sig ---
	ui_button :: proc(label: cstring) -> ui_sig ---
	ui_checkbox :: proc(name: cstring, checked: ^c.bool) -> ui_sig ---
	ui_slider :: proc(label: cstring, value: ^f32) -> ^ui_box ---
	ui_scrollbar :: proc(label: cstring, thumbRatio: f32, scrollValue: ^f32) -> ^ui_box ---
	ui_text_box :: proc(name: cstring, arena: ^arena, text: str8) -> ui_text_box_result ---
	ui_select_popup :: proc(name: cstring, info: ^ui_select_popup_info) -> ui_select_popup_info ---
	ui_radio_group :: proc(name: cstring, info: ^ui_radio_group_info) -> ui_radio_group_info ---

	ui_panel_begin :: proc(name: cstring, flags: ui_flags) ---
	ui_panel_end :: proc() ---

	ui_menu_bar_begin :: proc(label: cstring) ---
	ui_menu_bar_end :: proc() ---

	ui_menu_begin :: proc(label: cstring) ---
	ui_menu_end :: proc() ---

	ui_menu_button :: proc(name: cstring) -> ui_sig ---

	ui_tooltip_begin :: proc(name: cstring) -> ui_sig ---
	ui_tooltip_end :: proc() ---
}

@(deferred_none=ui_panel_end)
ui_panel :: proc "c" (name: cstring, flags: ui_flags) {
	ui_panel_begin(name, flags)
}
ui_panel_scoped :: ui_panel

@(deferred_none=ui_menu_bar_end)
ui_menu_bar :: proc "c" (label: cstring) {
	ui_menu_bar_begin(label)
}
ui_menu_bar_scoped :: ui_menu_bar

@(deferred_none=ui_menu_end)
ui_menu :: proc "c" (label: cstring) {
	ui_menu_begin(label)
}
ui_menu_scoped :: ui_menu

@(deferred_none=ui_tooltip_end)
ui_tooltip :: proc "c" (label: cstring) -> ui_sig {
	return ui_tooltip_begin(label)
}
ui_tooltip_scoped :: ui_menu

//-------------------------------------------------------------------------------------
// Styling
//-------------------------------------------------------------------------------------
@(default_calling_convention="c", link_prefix="oc_")
foreign {
	ui_style_next :: proc(style: ^ui_style, mask: ui_style_mask) ---

	ui_pattern_push :: proc(arena: ^arena, pattern: ^ui_pattern, selector: ui_selector) ---
	ui_pattern_all :: proc() -> ui_pattern ---
	ui_pattern_owner :: proc() -> ui_pattern ---

	ui_style_match_before :: proc(pattern: ui_pattern, style: ^ui_style, mask: ui_style_mask) ---
	ui_style_match_after :: proc(pattern: ui_pattern, style: ^ui_style, mask: ui_style_mask) ---
}

//-------------------------------------------------------------------------------------
// BOX
//-------------------------------------------------------------------------------------

@(default_calling_convention="c", link_prefix="oc_")
foreign {
	ui_box_make_str8 :: proc(str: str8, flags: ui_flags) -> ^ui_box ---
	ui_box_begin_str8 :: proc(str: str8, flags: ui_flags) -> ^ui_box ---
	ui_box_end :: proc() -> ^ui_box ---
}

@(deferred_none=ui_box_end)
ui_container :: proc "c" (str: string, flags: ui_flags) -> ^ui_box {
	return ui_box_begin_str8(str, flags)
}

@(deferred_none=ui_box_end)
ui_container_str8 :: proc "c" (str: str8, flags: ui_flags) -> ^ui_box {
	return ui_box_begin_str8(str, flags)
}

ui_box_make :: proc "c" (str: string, flags: ui_flags) -> ^ui_box {
	return ui_box_make_str8(str, flags)
}

ui_box_begin :: proc "c" (str: string, flags: ui_flags) -> ^ui_box {
	return ui_box_begin_str8(str, flags)
}

//-------------------------------------------------------------------------------------
// BOX
//-------------------------------------------------------------------------------------

@(default_calling_convention="c", link_prefix="oc_")
foreign {
	ui_tag_make_str8 :: proc(str: str8) -> ui_tag ---
	ui_tag_box_str8 :: proc(box: ^ui_box, str: str8) ---
	ui_tag_next_str8 :: proc(str: str8) ---
}

ui_tag_make :: proc "c" (s: string) -> ui_tag {
	return ui_tag_make_str8(s)
}

ui_tag_box :: proc "c" (b: ^ui_box, s: string) {
	ui_tag_box_str8(b, s)
}

ui_tag_next :: proc "c" (s: string) {
	ui_tag_next_str8(s)
}
