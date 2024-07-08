//+build linux, freebsd, openbsd
package xlib

// Since this is a unix-only library we make a few simplifying assumptions
import "core:c"
#assert(size_of(int)  == size_of(c.long))
#assert(size_of(uint) == size_of(c.ulong))
#assert(size_of(i32)  == size_of(c.int))
#assert(size_of(u32)  == size_of(c.uint))

/* ----  X11/X.h ------------------------------------------------------------*/

XID      :: distinct uint
Mask     :: distinct uint
Atom     :: distinct uint
VisualID :: distinct uint
Time     :: distinct uint

Window   :: XID
Drawable :: XID
Font     :: XID
Pixmap   :: XID
Cursor   :: XID
Colormap :: XID
GContext :: XID

RRCrtc   :: XID
RROutput :: XID

KeyCode  :: u8

/* ----  X11/Xlib.h ---------------------------------------------------------*/

XExtData :: struct {
	number:                i32,
	next:                  ^XExtData,
	free_private:          #type proc "c" (extension: ^XExtData) -> Status,
	private_data:          rawptr,
}

XExtCodes :: struct {
	extension:             i32,
	major_opcode:          i32,
	first_event:           i32,
	first_error:           i32,
}

XPixmapFormatValues :: struct {
    depth:                 i32,
    bits_per_pixel:        i32,
    scanline_pad:          i32,
}

XGCValues :: struct {
	function:              GCFunction,
	plane_mask:            uint,
	foreground:            uint,
	background:            uint,
	line_width:            i32,
	line_style:            LineStyle,
	cap_style:             CapStyle,
	join_style:            JoinStyle,
	fill_style:            FillStyle,
	fill_rule:             FillRule,
	arc_mode:              ArcMode,
	tile:                  Pixmap,
	stipple:               Pixmap,
	ts_x_origin:           i32,
	ts_y_origin:           i32,
	font:                  Font,
	subwindow_mode:        SubwindowMode,
	graphics_exposures:    b32,
	clip_x_origin:         i32,
	clip_y_origin:         i32,
	clip_mask:             Pixmap,
	dash_offset:           i32,
	dashes:                i8,
}

GC :: distinct rawptr

Visual :: struct {
	ext_data:              ^XExtData,
	visualid:              VisualID,
	class:                 i32,
	red_mask:              uint,
	green_mask:            uint,
	blue_mask:             uint,
	bits_per_rgb:          i32,
	map_entries:           i32,
}

Depth :: struct {
	depth:                 i32,
	nvisuals:              i32,
	visuals:               ^Visual,
}

XDisplay :: distinct struct {}

Screen :: struct {
	ext_data:              ^XExtData,
	display:               ^XDisplay,
	root:                  Window,
	width:                 i32,
	height:                i32,
	mwidth:                i32,
	mheight:               i32,
	ndepths:               i32,
	depths:                ^Depth,
	root_depth:            i32,
	root_visual:           ^Visual,
	default_gc:            GC,
	cmap:                  Colormap,
	white_pixel:           uint,
	black_pixel:           uint,
	max_maps:              i32,
	min_maps:              i32,
	backing_store:         i32,
	save_unders:           i32,
	root_input_mask:       int,
}

ScreenFormat :: struct {
	ext_data:              ^XExtData,
	depth:                 i32,
	bits_per_pixel:        i32,
	scanline_pad:          i32,
}

XSetWindowAttributes :: struct {
    background_pixmap:     Pixmap,
    background_pixel:      uint,
    border_pixmap:         Pixmap,
    border_pixel:          uint,
    bit_gravity:           Gravity,
    win_gravity:           Gravity,
    backing_store:         BackingStore,
    backing_planes:        uint,
    backing_pixel:         uint,
    save_under:            b32,
    event_mask:            EventMask,
    do_not_propagate_mask: EventMask,
    override_redirect:     b32,
    colormap:              Colormap,
    cursor:                Cursor,
}

XWindowAttributes :: struct {
    x:                     i32,
    y:                     i32,
    width:                 i32,
    height:                i32,
    border_width:          i32,
    depth:                 i32,
    visual:                ^Visual,
    root:                  Window,
    class:                 WindowClass,
    bit_gravity:           Gravity,
    win_gravity:           Gravity,
    backing_store:         BackingStore,
    backing_planes:        uint,
    backing_pixel:         uint,
    save_under:            b32,
    colormap:              Colormap,
    map_installed:         b32,
    map_state:             WindowMapState,
    all_event_masks:       EventMask,
    your_event_mask:       EventMask,
    do_not_propagate_mask: EventMask,
    override_redirect:     b32,
    screen:                ^Screen,
}

XHostAddress :: struct {
	family:                i32,
	length:                i32,
	address:               rawptr,
}

XServerInterpretedAddress :: struct {
	typelength:            i32,
	valuelength:           i32,
	type:                  [^]u8,
	value:                 [^]u8,
}

XImage :: struct {
    width:                 i32,
    height:                i32,
    xoffset:               i32,
    format:                ImageFormat,
    data:                  rawptr,
    byte_order:            i32,
    bitmap_unit:           i32,
    bitmap_bit_order:      ByteOrder,
    bitmap_pad:            i32,
    depth:                 i32,
    bytes_per_line:        i32,
    bits_per_pixel:        i32,
    red_mask:              uint,
    green_mask:            uint,
    blue_mask:             uint,
    obdata:                rawptr,
    f: struct {
    	create_image: proc "c" (
    		display: ^Display,
    		visual: ^Visual,
    		depth: u32,
    		format: i32,
    		offset: i32,
    		data: rawptr,
    		width: u32,
    		height: u32,
    		pad: i32,
    		stride: i32) -> ^XImage,
    	destroy_image: proc "c" (image: ^XImage) -> i32,
    	get_pixel: proc "c" (image: ^XImage) -> uint,
    	put_pixel: proc "c" (image: ^XImage, x: i32, y: i32, pixel: uint) -> i32,
    	sub_image: proc "c" (image: ^XImage, x: i32, y: i32, w: u32, h: u32) -> ^XImage,
    	add_pixel: proc "c" (image: ^XImage, val: int) -> i32,
	},
}

XWindowChanges :: struct {
    x:                     i32,
    y:                     i32,
    width:                 i32,
    height:                i32,
    border_width:          i32,
    sibling:               Window,
    stack_mode:            WindowStacking,
}

XColor :: struct {
	pixel:  uint,
	red:    u16,
	green:  u16,
	blue:   u16,
	flags:  u8,
	pad:    u8,
}

XSegment :: struct {
    x1:     i16,
    y1:     i16,
    x2:     i16,
    y2:     i16,
}

XPoint :: struct {
    x:      i16,
    y:      i16,
}

XRectangle :: struct {
    x:      i16,
    y:      i16,
    width:  u16,
    height: u16,
}

XArc :: struct {
    x:      i16,
    y:      i16,
    width:  u16,
    height: u16,
    angle1: i16,
    angle2: i16,
}

XKeyboardControl :: struct {
    key_click_percent:  i32,
    bell_percent:       i32,
    bell_pitch:         i32,
    bell_duration:      i32,
    led:                i32,
    led_mode:           KeyboardLedMode,
    key:                i32,
    auto_repeat_mode:   KeyboardAutoRepeatMode,
}

XKeyboardState :: struct {
	key_click_percent:  i32,
	bell_percent:       i32,
	bell_pitch:         u32,
	bell_duration:      u32,
	led_mask:           uint,
	global_auto_repeat: i32,
	auto_repeats:       [32]u8,
}

XTimeCoord :: struct {
	time:               Time,
	x:                  i16,
	y:                  i16,
}

XModifierKeymap :: struct {
	max_keypermod:      i32,
	modifiermap:        ^KeyCode,
}

Display :: distinct struct {}

XKeyEvent :: struct {
	type:              EventType,
	serial:            uint,
	send_event:        b32,
	display:           ^Display,
	window:            Window,
	root:              Window,
	subwindow:         Window,
	time:              Time,
	x:                 i32,
	y:                 i32,
	x_root:            i32,
	y_root:            i32,
	state:             InputMask,
	keycode:           u32,
	same_screen:       b32,
}

XKeyPressedEvent  :: XKeyEvent
XKeyReleasedEvent :: XKeyEvent

XButtonEvent :: struct {
	type:              EventType,
	serial:            uint,
	send_event:        b32,
	display:           ^Display,
	window:            Window,
	root:              Window,
	subwindow:         Window,
	time:              Time,
	x:                 i32,
	y:                 i32,
	x_root:            i32,
	y_root:            i32,
	state:             InputMask,
	button:            MouseButton,
	same_screen:       b32,
}

XButtonPressedEvent  :: XButtonEvent
XButtonReleasedEvent :: XButtonEvent

XMotionEvent :: struct {
	type:              EventType,
	serial:            uint,
	send_event:        b32,
	display:           ^Display,
	window:            Window,
	root:              Window,
	subwindow:         Window,
	time:              Time,
	x:                 i32,
	y:                 i32,
	x_root:            i32,
	y_root:            i32,
	state:             InputMask,
	is_hint:           b8,
	same_screen:       b32,
}

XPointerMovedEvent :: XMotionEvent

XCrossingEvent :: struct {
	type:              EventType,
	serial:            uint,
	send_event:        b32,
	display:           ^Display,
	window:            Window,
	root:              Window,
	subwindow:         Window,
	time:              Time,
	x:                 i32,
	y:                 i32,
	x_root:            i32,
	y_root:            i32,
	mode:              NotifyMode,
	detail:            NotifyDetail,
	same_screen:       b32,
	focus:             i32,
	state:             InputMask,
}

XEnterWindowEvent :: XCrossingEvent
XLeaveWindowEvent :: XCrossingEvent

XFocusChangeEvent :: struct {
	type:              EventType,
	serial:            uint,
	send_event:        b32,
	display:           ^Display,
	window:            Window,
	mode:              NotifyMode,
	detail:            NotifyDetail,
}

XFocusInEvent  :: XFocusChangeEvent
XFocusOutEvent :: XFocusChangeEvent

XKeymapEvent :: struct {
	type:              EventType,
	serial:            uint,
	send_event:        b32,
	display:           ^Display,
	window:            Window,
	key_vector:        [32]u8,
}

XExposeEvent :: struct {
	type:              EventType,
	serial:            uint,
	send_event:        b32,
	display:           ^Display,
	window:            Window,
	x:                 i32,
	y:                 i32,
	width:             i32,
	height:            i32,
	count:             i32,
}

XGraphicsExposeEvent :: struct {
	type:              EventType,
	serial:            uint,
	send_event:        b32,
	display:           ^Display,
	drawable:          Drawable,
	x:                 i32,
	y:                 i32,
	width:             i32,
	height:            i32,
	count:             i32,
	major_code:        i32,
	minor_code:        i32,
}

XNoExposeEvent :: struct {
	type:              EventType,
	serial:            uint,
	send_event:        b32,
	display:           ^Display,
	drawable:          Drawable,
	major_code:        i32,
	minor_code:        i32,
}

XVisibilityEvent :: struct {
	type:              EventType,
	serial:            uint,
	send_event:        b32,
	display:           ^Display,
	window:            Window,
	state:             VisibilityState,
}

XCreateWindowEvent :: struct {
	type:              EventType,
	serial:            uint,
	send_event:        b32,
	display:           ^Display,
	parent:            Window,
	window:            Window,
	x:                 i32,
	y:                 i32,
	width:             i32,
	height:            i32,
	border_width:      i32,
	override_redirect: b32,
}

XDestroyWindowEvent :: struct {
	type:              EventType,
	serial:            uint,
	send_event:        b32,
	display:           ^Display,
	event:             Window,
	window:            Window,
}

XUnmapEvent :: struct {
	type:              EventType,
	serial:            uint,
	send_event:        b32,
	display:           ^Display,
	event:             Window,
	window:            Window,
	from_configure:    b32,
}

XMapEvent :: struct {
	type:              EventType,
	serial:            uint,
	send_event:        b32,
	display:           ^Display,
	event:             Window,
	window:            Window,
	override_redirect: b32,
}

XMapRequestEvent :: struct {
	type:              EventType,
	serial:            uint,
	send_event:        b32,
	display:           ^Display,
	parent:            Window,
	window:            Window,
}

XReparentEvent :: struct {
	type:              EventType,
	serial:            uint,
	send_event:        b32,
	display:           ^Display,
	event:             Window,
	window:            Window,
	parent:            Window,
	x:                 i32,
	y:                 i32,
	override_redirect: b32,
}

XConfigureEvent :: struct {
	type:              EventType,
	serial:            uint,
	send_event:        b32,
	display:           ^Display,
	event:             Window,
	window:            Window,
	x:                 i32,
	y:                 i32,
	width:             i32,
	height:            i32,
	border_width:      i32,
	above:             Window,
	override_redirect: b32,
}

XGravityEvent :: struct {
	type:              EventType,
	serial:            uint,
	send_event:        b32,
	display:           ^Display,
	event:             Window,
	window:            Window,
	x:                 i32,
	y:                 i32,
}

XResizeRequestEvent :: struct {
	type:              EventType,
	serial:            uint,
	send_event:        b32,
	display:           ^Display,
	window:            Window,
	width:             i32,
	height:            i32,
}

XConfigureRequestEvent :: struct {
	type:              EventType,
	serial:            uint,
	send_event:        b32,
	display:           ^Display,
	parent:            Window,
	window:            Window,
	x:                 i32,
	y:                 i32,
	width:             i32,
	height:            i32,
	border_width:      i32,
	above:             Window,
	detail:            WindowStacking,
	value_mask:        uint,
}

XCirculateEvent :: struct {
	type:              EventType,
	serial:            uint,
	send_event:        b32,
	display:           ^Display,
	event:             Window,
	window:            Window,
	place:             CirculationRequest,
}

XCirculateRequestEvent :: struct {
	type:              EventType,
	serial:            uint,
	send_event:        b32,
	display:           ^Display,
	parent:            Window,
	window:            Window,
	place:             CirculationRequest,
}

XPropertyEvent :: struct {
	type:              EventType,
	serial:            uint,
	send_event:        b32,
	display:           ^Display,
	window:            Window,
	atom:              Atom,
	time:              Time,
	state:             PropertyState,
}

XSelectionClearEvent :: struct {
	type:              EventType,
	serial:            uint,
	send_event:        b32,
	display:           ^Display,
	window:            Window,
	selection:         Atom,
	time:              Time,
}

XSelectionRequestEvent :: struct {
	type:              EventType,
	serial:            uint,
	send_event:        b32,
	display:           ^Display,
	owner:             Window,
	requestor:         Window,
	selection:         Atom,
	target:            Atom,
	property:          Atom,
	time:              Time,
}

XSelectionEvent :: struct {
	type:              EventType,
	serial:            uint,
	send_event:        b32,
	display:           ^Display,
	requestor:         Window,
	selection:         Atom,
	target:            Atom,
	property:          Atom,
	time:              Time,
}

XColormapEvent :: struct {
	type:              EventType,
	serial:            uint,
	send_event:        b32,
	display:           ^Display,
	window:            Window,
	colormap:          Colormap,
	new:               b32,
	state:             ColormapState,
}

XClientMessageEvent :: struct {
	type:              EventType,
	serial:            uint,
	send_event:        b32,
	display:           ^Display,
	window:            Window,
	message_type:      Atom,
	format:            i32,
	data: struct #raw_union {
		b: [20]i8,
		s: [10]i16,
		l: [5]int,
	},
}

XMappingEvent :: struct {
	type:              EventType,
	serial:            uint,
	send_event:        b32,
	display:           ^Display,
	window:            Window,
	request:           MappingRequest,
	first_keycode:     i32,
	count:             i32,
}

XErrorEvent :: struct {
	type:              EventType,
	display:           ^Display,
	resourceid:        XID,
	serial:            uint,
	error_code:        u8,
	request_code:      u8,
	minor_code:        u8,
}

XAnyEvent :: struct {
	type:              EventType,
	serial:            uint,
	send_event:        b32,
	display:           ^Display,
	window:            Window,
}

XGenericEvent :: struct {
    type:              EventType,
    serial:            uint,
    send_event:        b32,
    display:           ^Display,
    extension:         i32,
    evtype:            i32,
}

XGenericEventCookie :: struct {
    type:              EventType,
    serial:            uint,
    send_event:        b32,
    display:           ^Display,
    extension:         i32,
    evtype:            i32,
    cookie:            u32,
    data:              rawptr,
}

XEvent :: struct #raw_union {
	type:              EventType,
	xany:              XAnyEvent,
	xkey:              XKeyEvent,
	xbutton:           XButtonEvent,
	xmotion:           XMotionEvent,
	xcrossing:         XCrossingEvent,
	xfocus:            XFocusChangeEvent,
	xexpose:           XExposeEvent,
	xgraphicsexpose:   XGraphicsExposeEvent,
	xnoexpose:         XNoExposeEvent,
	xvisibility:       XVisibilityEvent,
	xcreatewindow:     XCreateWindowEvent,
	xdestroywindow:    XDestroyWindowEvent,
	xunmap:            XUnmapEvent,
	xmap:              XMapEvent,
	xmaprequest:       XMapRequestEvent,
	xreparent:         XReparentEvent,
	xconfigure:        XConfigureEvent,
	xgravity:          XGravityEvent,
	xresizerequest:    XResizeRequestEvent,
	xconfigurerequest: XConfigureRequestEvent,
	xcirculate:        XCirculateEvent,
	xcirculaterequest: XCirculateRequestEvent,
	xproperty:         XPropertyEvent,
	xselectionclear:   XSelectionClearEvent,
	xselectionrequest: XSelectionRequestEvent,
	xselection:        XSelectionEvent,
	xcolormap:         XColormapEvent,
	xclient:           XClientMessageEvent,
	xmapping:          XMappingEvent,
	xerror:            XErrorEvent,
	xkeymap:           XKeymapEvent,
	xgeneric:          XGenericEvent,
	xcookie:           XGenericEventCookie,
	_:                 [24]int,
}

XCharStruct :: struct {
    lbearing:          i16,
    rbearing:          i16,
    width:             i16,
    ascent:            i16,
    descent:           i16,
    attributes:        u16,
}

XFontProp :: struct {
    name:              Atom,
    card32:            uint,
}

XFontStruct :: struct {
    ext_data:          ^XExtData,
    fid:               Font,
    direction:         u32,
    min_char_or_byte2: u32,
    max_char_or_byte2: u32,
    min_byte1:         u32,
    max_byte1:         u32,
    all_chars_exist:   i32,
    default_char:      u32,
    n_properties:      i32,
    properties:        ^XFontProp,
    min_bounds:        XCharStruct,
    max_bounds:        XCharStruct,
    per_char:          ^XCharStruct,
    ascent:            i32,
    descent:           i32,
}

XTextItem :: struct {
    chars:  [^]u8,
    nchars: i32,
    delta:  i32,
    font:   Font,
}

XChar2b :: struct {
    byte1: u8,
    byte2: u8,
}

XTextItem16 :: struct {
    chars:  ^XChar2b,
    nchars: i32,
    delta:  i32,
    font:   Font,
}

XEDataObject :: struct #raw_union {
	display:            ^Display,
	gc:                 GC,
	visual:             ^Visual,
	screen:             ^Screen,
	pixmap_format:      ^ScreenFormat,
	font:               ^XFontStruct,
}

XFontSetExtents :: struct {
    max_ink_extent:     XRectangle,
    max_logical_extent: XRectangle,
}

XOM      :: distinct rawptr
XOC      :: distinct rawptr
XFontSet :: XOC

XmbTextItem :: struct {
    chars:    [^]u8,
    nchars:   i32,
    delta:    i32,
    font_set: XFontSet,
}

XwcTextItem :: struct {
    chars:    [^]rune,
    nchars:   i32,
    delta:    i32,
    font_set: XFontSet,
}

XOMCharSetList :: struct {
    charset_count: i32,
    charset_list: [^]cstring,
}

XOrientation :: enum i32 {
    XOMOrientation_LTR_TTB = 0,
    XOMOrientation_RTL_TTB = 1,
    XOMOrientation_TTB_LTR = 2,
    XOMOrientation_TTB_RTL = 3,
    XOMOrientation_Context = 4,
}

XOMOrientation :: struct {
    num_orientation:  i32,
    orientation:      [^]XOrientation,
}

XOMFontInfo :: struct {
    num_font:         i32,
    font_struct_list: [^]^XFontStruct,
    font_name_list:   [^]cstring,
}

XIM :: distinct rawptr
XIC :: distinct rawptr

XIMProc :: #type proc "c" (xim: XIM, client_data: rawptr, call_data: rawptr)
XICProc :: #type proc "c" (xim: XIM, client_data: rawptr, call_data: rawptr)
XIDProc :: #type proc "c" (xim: XIM, client_data: rawptr, call_data: rawptr)

XIMStyle :: uint

XIMStyles :: struct {
    count_styles:     u16,
    supported_styles: [^]XIMStyle,
}

XVaNestedList :: distinct rawptr

XIMCallback :: struct {
    client_data: rawptr,
    callback:    XIMProc,
}

XICCallback :: struct {
    client_data: rawptr,
    callback:    XICProc,
}

XIMFeedback :: uint

XIMText :: struct {
    length:            u16,
    feedback:          ^XIMFeedback,
    encoding_is_wchar: b32,
    string: struct #raw_union {
		multi_byte: [^]u8,
		wide_char:  [^]rune,
    },
}

XIMPreeditState :: uint

XIMPreeditStateNotifyCallbackStruct :: struct {
    state: XIMPreeditState,
}

XIMResetState :: uint

XIMStringConversionFeedback :: uint

XIMStringConversionText :: struct {
    length: u16,
    feedback: ^XIMStringConversionFeedback,
    encoding_is_wchar: b32,
    string: struct #raw_union {
		mbs: [^]u8,
		wcs: [^]rune,
    },
}

XIMStringConversionPosition  :: u16
XIMStringConversionType      :: u16
XIMStringConversionOperation :: u16

XIMCaretDirection :: enum i32 {
    XIMForwardChar      = 0,
    XIMBackwardChar     = 1,
    XIMForwardWord      = 2,
    XIMBackwardWord     = 3,
    XIMCaretUp          = 4,
    XIMCaretDown        = 5,
    XIMNextLine         = 6,
    XIMPreviousLine     = 7,
    XIMLineStart        = 8,
    XIMLineEnd          = 9,
    XIMAbsolutePosition = 10,
    XIMDontChang        = 11,
}

XIMStringConversionCallbackStruct :: struct {
    position:  XIMStringConversionPosition,
    direction: XIMCaretDirection,
    operation: XIMStringConversionOperation,
    factor:    u16,
    text:      ^XIMStringConversionText,
}

XIMPreeditDrawCallbackStruct :: struct {
    caret:      i32,
    chg_first:  i32,
    chg_length: i32,
    text:       ^XIMText,
}

XIMCaretStyle :: enum i32 {
    XIMIsInvisible,
    XIMIsPrimary,
    XIMIsSecondary,
}

XIMPreeditCaretCallbackStruct :: struct {
    position:  i32,
    direction: XIMCaretDirection,
    style:     XIMCaretStyle,
}

XIMStatusDataType :: enum {
    XIMTextType,
    XIMBitmapType,
}

XIMStatusDrawCallbackStruct :: struct {
    type: XIMStatusDataType,
    data: struct #raw_union {
		text: ^XIMText,
		bitmap: Pixmap,
    },
}

XIMHotKeyTrigger :: struct {
    keysym:        KeySym,
    modifier:      i32,
    modifier_mask: i32,
}

XIMHotKeyTriggers :: struct {
    num_hot_key: i32,
    key:         [^]XIMHotKeyTrigger,
}

XIMHotKeyState :: uint

XIMValuesList :: struct {
    count_values: u16,
    supported_values: [^]cstring,
}

XConnectionWatchProc :: #type proc "c" (
	display: ^Display,
	client_data: rawptr,
	fd: i32,
	opening: b32,
	watch_data: rawptr)

/* ----  X11/extensions/XKBlib.h ---------------------------------------------------------*/

XkbAnyEvent :: struct {
	type: i32,
	serial: u64,
	send_event: b32,
	display: ^Display,
	time: Time,
	xkb_type: XkbEventType,
	device: u32,
}

XkbNewKeyboardNotifyEvent :: struct {
	type: i32,
	serial: u64,
	send_event: b32,
	display: ^Display,
	time: Time,
	xkb_type: XkbEventType,
	device: i32,
	old_device: i32,
	min_key_code: i32,
	max_key_code: i32,
	old_min_key_code: i32,
	old_max_key_code: i32,
	changed: u32,
	req_major: i8,
	req_minor: i8,
}

XkbMapNotifyEvent :: struct {
	type: i32,
	serial: u64,
	send_event: b32,
	display: ^Display,
	time: Time,
	xkb_type: XkbEventType,
	device: i32,
	changed: u32,
	flags: u32,
	first_type: i32,
	num_types: i32,
	min_key_code: KeyCode,
	max_key_code: KeyCode,
	first_key_sym: KeyCode,
	first_key_act: KeyCode,
	first_key_behavior: KeyCode,
	first_key_explicit: KeyCode,
	first_modmap_key: KeyCode,
	first_vmodmap_key: KeyCode,
	num_key_syms: i32,
	num_key_acts: i32,
	num_key_behaviors: i32,
	num_key_explicit: i32,
	num_modmap_keys: i32,
	num_vmodmap_keys: i32,
	vmods: u32,
}

XkbStateNotifyEvent :: struct {
	type: i32,
	serial: u64,
	send_event: b32,
	display: ^Display,
	time: Time,
	xkb_type: XkbEventType,
	device: i32,
	changed: u32,
	group: i32,
	base_group: i32,
	latched_group: i32,
	locked_group: i32,
	mods: u32,
	base_mods: u32,
	latched_mods: u32,
	locked_mods: u32,
	compat_state: i32,
	grab_mods: u8,
	compat_grab_mods: u8,
	lookup_mods: u8,
	compat_lookup_mods: u8,
	ptr_buttons: i32,
	keycode: KeyCode,
	event_type: i8, // should be EventType but needs to be i8 instead of i32
	req_major: i8,
	req_minor: i8,
}

XkbControlsNotifyEvent :: struct {
	type: i32,
	serial: u64,
	send_event: b32,
	display: ^Display,
	time: Time,
	xkb_type: XkbEventType,
	device: i32,
	changed_ctrls: u32,
	enabled_ctrls: u32,
	enabled_ctrls_changes: u32,
	num_groups: i32,
	keycode: KeyCode,
	event_type: i8,
	req_major: i8,
	req_minor: i8,
}

XkbIndicatorNotifyEvent :: struct {
	type: i32,
	serial: u64,
	send_event: b32,
	display: ^Display,
	time: Time,
	xkb_type: XkbEventType,
	device: i32,
	changed: u32,
	state: u32,
}

XkbNamesNotifyEvent :: struct {
	type: i32,
	serial: u64,
	send_event: b32,
	display: ^Display,
	time: Time,
	xkb_type: XkbEventType,
	device: i32,
	changed: u32,
	first_type: i32,
	num_types: i32,
	first_lvl: i32,
	num_lvls: i32,
	num_aliases: i32,
	num_radio_groups: i32,
	changed_vmods: u32,
	changed_groups: u32,
	changed_indicators: u32,
	first_key: i32,
	num_keys: i32,
}

XkbCompatMapNotifyEvent :: struct {
	type: i32,
	serial: u64,
	send_event: b32,
	display: ^Display,
	time: Time,
	xkb_type: XkbEventType,
	device: i32,
	changed_groups: u32,
	first_si: i32,
	num_si: i32,
	num_total_si: i32,
}

XkbBellNotifyEvent :: struct {
	type: i32,
	serial: u64,
	send_event: b32,
	display: ^Display,
	time: Time,
	xkb_type: XkbEventType,
	device: i32,
	percent: i32,
	pitch: i32,
	duration: i32,
	bell_class: i32,
	bell_id: i32,
	name: Atom,
	window: Window,
	event_only: b32,
}

XkbActionMessageEvent :: struct {
	type: i32,
	serial: u64,
	send_event: b32,
	display: ^Display,
	time: Time,
	xkb_type: XkbEventType,
	device: i32,
	keycode: KeyCode,
	press: b32,
	key_event_follows: b32,
	group: i32,
	mods: u32,
	message: [XkbActionMessageLength+1]i8,
}

XkbAccessXNotifyEvent :: struct {
	type: i32,
	serial: u64,
	send_event: b32,
	display: ^Display,
	time: Time,
	xkb_type: XkbEventType,
	device: i32,
	detail: i32,
	keycode: i32,
	sk_delay: i32,
	debounce_delay: i32,
}

XkbExtensionDeviceNotifyEvent :: struct {
	type: i32,
	serial: u64,
	send_event: b32,
	display: ^Display,
	time: Time,
	xkb_type: XkbEventType,
	device: i32,
	reason: u32,
	supported: u32,
	unsupported: u32,
	first_btn: i32,
	num_btns: i32,
	leds_defined: u32,
	led_state: u32,
	led_class: i32,
	led_id: i32,
}

XkbEvent :: struct #raw_union {
	type: XkbEventType,
	any: XkbAnyEvent,
	new_kbd: XkbNewKeyboardNotifyEvent,
	_map: XkbMapNotifyEvent,
	state: XkbStateNotifyEvent,
	ctrls: XkbControlsNotifyEvent,
	indicators: XkbIndicatorNotifyEvent,
	names: XkbNamesNotifyEvent,
	compat: XkbCompatMapNotifyEvent,
	bell: XkbBellNotifyEvent,
	message: XkbActionMessageEvent,
	accessx: XkbAccessXNotifyEvent,
	device: XkbExtensionDeviceNotifyEvent,
	core: XEvent,
}

/* ----  X11/extensions/XKBgeom.h ---------------------------------------------------------*/

XkbPointRec :: struct {
	x: i16,
	y: i16,
}
XkbPointPtr :: ^XkbPointRec

XkbBoundsRec :: struct {
	x1, x2: i16,
	y1, y2: i16,
}
XkbBoundsPtr :: ^XkbBoundsRec

XkbOutlineRec :: struct {
	num_points: u16,
	sz_points: u16,
	corner_radius: u16,
	points: [^]XkbPointRec,
}
XkbOutlinePtr :: ^XkbOutlineRec

XkbShapeRec :: struct {
	name: Atom,
	num_outlines: u16,
	sz_outlines: u16,
	outlines: [^]XkbOutlineRec,
	approx: XkbOutlinePtr,
	primary: XkbOutlinePtr,
	bounds: XkbBoundsRec,
}
XkbShapePtr :: ^XkbShapeRec

XkbPropertyRec :: struct {
	name: cstring,
	value: cstring,
}
XkbPropertyPtr :: ^XkbPropertyRec

XkbColorRec :: struct {
	pixel: u32,
	spec: ^u8, // cstring?
}
XkbColorPtr :: ^XkbColorRec

XkbKeyRec :: struct {
	name: XkbKeyNameRec,
	gap: i16,
	shape_ndx: u8,
	color_ndx: u8,
}
XkbKeyPtr :: ^XkbKeyRec

XkbRowRec :: struct {
	top: i16,
	left: i16,
	num_keys: u16,
	sz_keys: u16,
	vertical: i32,
	keys: [^]XkbKeyRec,
	bounds: XkbBoundsRec,
}
XkbRowPtr :: ^XkbRowRec

XkbAnyDoodadRec :: struct {
	name: Atom,
	type: u8,
	priority: u8,
	top: i16,
	left: i16,
	angle: i16,
}
XkbAnyDoodadPtr :: ^XkbAnyDoodadRec

XkbShapeDoodadRec :: struct {
	name: Atom,
	type: u8,
	priority: u8,
	top: i16,
	left: i16,
	angle: i16,
	color_ndx: u16,
	shape_ndx: u16,
}
XkbShapeDoodadPtr :: ^XkbShapeDoodadRec

XkbTextDoodadRec :: struct {
	name: Atom,
	type: u8,
	priority: u8,
	top: i16,
	left: i16,
	angle: i16,
	color_ndx: u16,
	text: cstring,
	font: cstring,
}
XkbTextDoodadPtr :: ^XkbTextDoodadRec

XkbIndicatorDoodadRec :: struct {
	name: Atom,
	type: u8,
	priority: u8,
	top: i16,
	left: i16,
	angle: i16,
	color_ndx: u16,
	on_color_ndx: u16,
	off_color_ndx: u16,
}
XkbIndicatorDoodadPtr :: ^XkbIndicatorDoodadRec

XkbLogoDoodadRec :: struct {
	name: Atom,
	type: u8,
	priority: u8,
	top: i16,
	left: i16,
	angle: i16,
	color_ndx: u16,
	shape_ndx: u16,
	logo_name: cstring,
}
XkbLogoDoodadPtr :: ^XkbLogoDoodadRec

XkbDoodadRec :: struct #raw_union {
	any: XkbAnyDoodadRec,
	shape: XkbShapeDoodadRec,
	text: XkbTextDoodadRec,
	indicator: XkbIndicatorDoodadRec,
	logo: XkbLogoDoodadRec,
}
XkbDoodadPtr :: ^XkbDoodadRec

XkbOverlayKeyRec :: struct {
	over: XkbKeyNameRec,
	under: XkbKeyNameRec,
}
XkbOverlayKeyPtr :: ^XkbOverlayKeyRec

XkbOverlayRowRec :: struct {
	row_under: u16,
	num_keys: u16,
	sz_keys: u16,
	keys: [^]XkbOverlayKeyRec,
}
XkbOverlayRowPtr :: ^XkbOverlayRowRec

XkbOverlayRec :: struct {
	name: Atom,
	section_under: XkbSectionPtr,
	num_rows: u16,
	sz_rows: u16,
	rows: [^]XkbOverlayRowRec,
	bounds: [^]XkbBoundsRec,
}
XkbOverlayPtr :: ^XkbOverlayRec

XkbSectionRec :: struct {
	name: Atom,
	priority: u8,
	top: i16,
	left: i16,
	width: u16,
	height: u16,
	angle: i16,
	num_rows: u16,
	num_doodads: u16,
	num_overlays: u16,
	sz_rows: u16,
	sz_doodads: u16,
	sz_overlays: u16,
	rows: [^]XkbRowRec,
	doodads: [^]XkbDoodadRec,
	bounds: XkbBoundsRec,
	overlays: [^]XkbOverlayRec,
}
XkbSectionPtr :: ^XkbSectionRec

XkbGeometryRec :: struct {
	name: Atom,
	width_mm: u16,
	height_mm: u16,
	label_font: cstring,
	label_color: XkbColorPtr,
	base_color: XkbColorPtr,
	sz_properties: u16,
	sz_colors: u16,
	sz_shapes: u16,
	sz_sections: u16,
	sz_doodads: u16,
	sz_key_aliases: u16,
	num_properties: u16,
	num_colors: u16,
	num_shapes: u16,
	num_sections: u16,
	num_doodads: u16,
	num_key_aliases: u16,
	properties: [^]XkbPropertyRec,
	colors: [^]XkbColorRec,
	shapes: [^]XkbShapeRec,
	sections: [^]XkbSectionRec,
	doodads: [^]XkbDoodadRec,
	key_aliases: [^]XkbKeyAliasRec,
}
XkbGeometryPtr :: ^XkbGeometryRec


/* ----  X11/extensions/XKBstr.h ---------------------------------------------------------*/

XkbStateRec :: struct {
	group: u8,
	locked_group: u8,
	base_group: u16,
	latched_group: u16,
	mods: u8,
	base_mods: u8,
	latched_mods: u8,
	locked_mods: u8,
	compat_state: u8,
	grab_mods: u8,
	compat_grab_mods: u8,
	lookup_mods: u8,
	compat_lookup_mods: u8,
	ptr_buttons: u16,
}
XkbStatePtr :: ^XkbStateRec

XkbModsRec :: struct {
	mask: u8,	/* effective mods */
	real_mods: u8,
	vmods: u16,
}
XkbModsPtr :: ^XkbModsRec

XkbKTMapEntryRec :: struct {
	active: b32,
	level: u8,
	mods: XkbModsRec,
}
XkbKTMapEntryPtr :: ^XkbKTMapEntryRec

XkbKeyTypeRec :: struct {
	mod: XkbModsRec,
	num_levels: u8,
	map_count: u8,
	_map: [^]XkbKTMapEntryRec,
	preserve: [^]XkbModsRec,
	name: Atom,
	level_names: [^]Atom,
}
XkbKeyTypePtr :: ^XkbKeyTypeRec

XkbBehavior :: struct {
	type: u8,
	data: u8,
}

XkbAnyAction :: struct {
	type: u8,
	data: [XkbAnyActionDataSize]u8,
}

XkbModAction :: struct {
	type: u8,
	flags: u8,
	mask: u8,
	real_mods: u8,
	vmods1: u8,
	vmods2: u8,
}

XkbGroupAction :: struct {
	type: u8,
	flags: u8,
	group_XXX: i8,
}

XkbISOAction :: struct {
	type: u8,
	flags: u8,
	mask: u8,
	real_mods: u8,
	group_XXX: i8,
	affect: u8,
	vmods1: u8,
	vmods2: u8,
}

XkbPtrAction :: struct {
	type: u8,
	flags: u8,
	high_XXX: u8,
	low_XXX: u8,
	high_YYY: u8,
	low_YYY: u8,
}

XkbPtrBtnAction :: struct {
	type: u8,
	flags: u8,
	count: u8,
	button: u8,
}

XkbPtrDfltAction :: struct {
	type: u8,
	flags: u8,
	affect: u8,
	value_XXX: u8,
}

XkbSwitchScreenAction :: struct {
	type: u8,
	flags: u8,
	screenXXX: i8,
}

XkbCtrlsAction :: struct {
	type: u8,
	flags: u8,
	ctrls3: u8,
	ctrls2: u8,
	ctrls1: u8,
	ctrls0: u8,
}

XkbMessageAction :: struct {
	type: u8,
	flags: u8,
	message: [6]u8,
}

XkbRedirectKeyAction :: struct {
	type: u8,
	new_key: u8,
	mods_mask: u8,
	mods: u8,
	vmods_mask0: u8,
	vmods_mask1: u8,
	vmods0: u8,
	vmods1: u8,
}

XkbDeviceBtnAction :: struct {
	type: u8,
	flags: u8,
	count: u8,
	button: u8,
	device: u8,
}

XkbDeviceValuatorAction :: struct {
	type: u8,
	device: u8,
	v1_what: u8,
	v1_ndx: u8,
	v1_value: u8,
	v2_what: u8,
	v2_ndx: u8,
	v2_value: u8,
}

XkbAction :: struct #raw_union {
	any: XkbAnyAction,
	mod: XkbModAction,
	group: XkbGroupAction,
	iso: XkbISOAction,
	ptr: XkbPtrAction,
	btn: XkbPtrBtnAction,
	dflt: XkbPtrDfltAction,
	screen: XkbSwitchScreenAction,
	ctrls: XkbCtrlsAction,
	msg: XkbMessageAction,
	redirect: XkbRedirectKeyAction,
	devbtn: XkbDeviceBtnAction,
	devval: XkbDeviceValuatorAction,
	type: u8,
}

XkbControlsRec :: struct {
	mk_dflt_btn: u8,
	num_groups: u8,
	groups_wrap: u8,
	internal: XkbModsRec,
	ignore_lock: XkbModsRec,
	enabled_ctrls: u32,
	repeat_delay: u16,
	repeat_interval: u16,
	slow_keys_delay: u16,
	debounce_delay: u16,
	mk_delay: u16,
	mk_interval: u16,
	mk_time_to_max: u16,
	mk_max_speed: u16,
	mk_curve: i16,
	ax_options: u16,
	ax_timeout: u16,
	axt_opts_mask: u16,
	axt_opts_values: u16,
	axt_ctrls_mask: u32,
	axt_ctrls_values: u32,
	per_key_repeat: [XkbPerKeyBitArraySize]u8,
}
XkbControlsPtr :: ^XkbControlsRec

XkbServerMapRec :: struct {
	num_acts: u16,
	size_acts: u16,
	acts: [^]XkbAction,

	behaviors: [^]XkbBehavior,
	key_acts: [^]u16,
	explicit: [^]u8,
	vmods: [XkbNumVirtualMods]u8,
	vmodmap: [^]u16,
}
XkbServerMapPtr :: ^XkbServerMapRec

XkbSymMapRec :: struct {
	kt_index: [XkbNumKbdGroups]u8,
	group_info: u8,
	width: u8,
	offset: u16,
}
XkbSymMapPtr :: ^XkbSymMapRec

XkbClientMapRec :: struct {
	size_types: u8,
	num_types: u8,
	types: [^]XkbKeyTypeRec,

	size_syms: u16,
	num_syms: u16,
	syms: [^]XID, // Keysym
	key_sym_map: [^]XkbSymMapRec,

	modmap: [^]u8,
}
XkbClientMapPtr :: ^XkbClientMapRec

XkbSymInterpretRec :: struct {
	sym: XID, // KeySym
	flags: u8,
	match: u8,
	mods: u8,
	virtual_mod: u8,
	act: XkbAnyAction,
}
XkbSymInterpretPtr :: ^XkbSymInterpretRec

XkbCompatMapRec :: struct {
	sym_interpret: [^]XkbSymInterpretRec,
	groups: [XkbNumKbdGroups]XkbModsRec,
	num_si: u16,
	size_si: u16,
}
XkbCompatMapPtr :: ^XkbCompatMapRec

XkbIndicatorMapRec :: struct {
	flags: u8,
	which_groups: u8,
	groups: u8,
	which_mods: u8,
	mods: XkbModsRec,
	ctrls: u32,
}
XkbIndicatorMapPtr :: ^XkbIndicatorMapRec

XkbIndicatorRec :: struct {
	phys_indicators: u64,
	maps: [XkbNumIndicators]XkbIndicatorMapRec,
}
XkbIndicatorPtr :: ^XkbIndicatorRec

XkbKeyNameRec :: struct {
	name: [XkbKeyNameLength]i8, // Non nul-terminated string
}
XkbKeyNamePtr :: ^XkbKeyNameRec

XkbKeyAliasRec :: struct {
	real: [XkbKeyNameLength]i8, // Non nul-terminated string
	alias: [XkbKeyNameLength]i8, // Non nul-terminated string
}
XkbKeyAliasPtr :: ^XkbKeyAliasRec

XkbNamesRec :: struct {
	keycodes: Atom,
	geometry: Atom,
	symbols: Atom,
	types: Atom,
	compat: Atom,
	vmods: [XkbNumVirtualMods]Atom,
	indicators: [XkbNumIndicators]Atom,
	groups: [XkbNumKbdGroups]Atom,
	keys: [^]XkbKeyNameRec,
	key_aliases: [^]XkbKeyAliasRec,
	radio_groups: [^]Atom,
	phys_symbol: Atom,
	num_keys: u8,
	num_key_aliases: u8,
	num_rg: u16,
}
XkbNamesPtr :: ^XkbNamesRec

XkbDescRec :: struct {
	display: ^Display,
	flags: u16,
	device_spec: u16,
	min_key_code: KeyCode,
	max_key_code: KeyCode,

	ctrls: XkbControlsPtr,
	server: XkbServerMapPtr,
	_map: XkbClientMapPtr,
	indicators: XkbIndicatorPtr,
	names: XkbNamesPtr,
	compat: XkbCompatMapPtr,
	geom: XkbGeometryPtr,
}
XkbDescPtr :: ^XkbDescRec


/* ----  X11/Xcms.h ---------------------------------------------------------*/

XcmsColorFormat :: uint

XcmsFloat :: f64

XcmsRGB :: struct {
    red:   u16,
    green: u16,
    blue:  u16,
}

XcmsRGBi :: struct {
    red:   XcmsFloat,
    green: XcmsFloat,
    blue:  XcmsFloat,
}

XcmsCIEXYZ :: struct {
    X: XcmsFloat,
    Y: XcmsFloat,
    Z: XcmsFloat,
}

XcmsCIEuvY :: struct {
    u_prime: XcmsFloat,
    v_prime: XcmsFloat,
    Y:       XcmsFloat,
}

XcmsCIExyY :: struct {
    x: XcmsFloat,
    y: XcmsFloat,
    Y: XcmsFloat,
}

XcmsCIELab :: struct {
    L_star: XcmsFloat,
    a_star: XcmsFloat,
    b_star: XcmsFloat,
}

XcmsCIELuv :: struct {
    L_star: XcmsFloat,
    u_star: XcmsFloat,
    v_star: XcmsFloat,
}

XcmsTekHVC :: struct {
    H: XcmsFloat,
    V: XcmsFloat,
    C: XcmsFloat,
}

XcmsPad :: struct {
    _: XcmsFloat,
    _: XcmsFloat,
    _: XcmsFloat,
    _: XcmsFloat,
}

XcmsColor :: struct {
    spec: struct #raw_union {
		RGB:    XcmsRGB,
		RGBi:   XcmsRGBi,
		CIEXYZ: XcmsCIEXYZ,
		CIEuvY: XcmsCIEuvY,
		CIExyY: XcmsCIExyY,
		CIELab: XcmsCIELab,
		CIELuv: XcmsCIELuv,
		TekHVC: XcmsTekHVC,
		_:      XcmsPad,
    },
    pixel:  uint,
    format: XcmsColorFormat,
}

XcmsPerScrnInfo :: struct {
    screenWhitePt: XcmsColor,
    functionSet:   rawptr,
    screenData:    rawptr,
    state:         u8,
    _:             [3]u8,
}

XcmsCCC :: distinct rawptr

XcmsCompressionProc :: #type proc "c" (
	ctx: XcmsCCC,
	colors: [^]XcmsColor,
	ncolors: u32,
	index: u32,
	flags: [^]b32) -> Status

XcmsWhiteAdjustProc :: #type proc "c" (
	ctx: XcmsCCC,
	initial_white_point: ^XcmsColor,
	target_white_point:  ^XcmsColor,
	target_format:       XcmsColorFormat,
	colors:              [^]XcmsColor,
	ncolors:             u32,
	compression: [^]b32) -> Status

XcmsCCCRec :: struct {
    dpy:                  ^Display,
    screenNumber:         i32,
    visual:               ^Visual,
    clientWhitePt:        XcmsColor,
    gamutCompProc:        XcmsCompressionProc,
    gamutCompClientData:  rawptr,
    whitePtAdjProc:       XcmsWhiteAdjustProc,
    whitePtAdjClientData: rawptr,
    pPerScrnInfo:         ^XcmsPerScrnInfo,
}

XcmsScreenInitProc :: #type proc "c" (
	display: ^Display,
	screen_number: i32,
	screen_info: ^XcmsPerScrnInfo) -> i32

XcmsScreenFreeProc :: #type proc "c" (screen: rawptr)

XcmsDDConversionProc :: #type proc "c" (
	ctx: XcmsCCC,
	colors: [^]XcmsColor,
	ncolors: u32,
	compressed: [^]b32) -> i32

XcmsDIConversionProc :: #type proc "c" (
	ctx: XcmsCCC,
	white_point: ^XcmsColor,
	colors: ^XcmsColor,
	ncolors: u32) -> i32


XcmsConversionProc :: XcmsDIConversionProc
XcmsFuncListPtr    :: [^]XcmsConversionProc

XcmsParseStringProc :: #type proc "c" (color_string: cstring, color: ^XcmsColor) -> i32

XcmsColorSpace :: struct {
    prefix:        cstring,
    id:            XcmsColorFormat,
    parseString:   XcmsParseStringProc,
    to_CIEXYZ:     XcmsFuncListPtr,
    from_CIEXYZ:   XcmsFuncListPtr,
    inverse_flag:  i32,
}

XcmsFunctionSet :: struct {
    DDColorSpaces: [^]^XcmsColorSpace,
    screenInitProc: XcmsScreenInitProc,
    screenFreeProc: XcmsScreenFreeProc,
}


/* ----  X11/Xutil.h --------------------------------------------------------*/

XSizeHints :: struct {
	flags:         SizeHints,
	x:             i32,
	y:             i32,
	width:         i32,
	height:        i32,
	min_width:     i32,
	min_height:    i32,
	max_width:     i32,
	max_height:    i32,
	width_inc:     i32,
	height_inc:    i32,
	min_aspect:    struct {x,y: i32},
	max_aspect:    struct {x,y: i32},
	base_width:    i32,
	base_height:   i32,
	win_gravity:   i32,
}

XWMHints :: struct {
	flags:         WMHints,
	input:         b32,
	initial_state: WMHintState,
	icon_pixmap:   Pixmap,
	icon_window:   Window,
	icon_x:        i32,
	icon_y:        i32,
	icon_mask:     Pixmap,
	window_group:  XID,
}

XTextProperty :: struct {
    value:         [^]u8,
    encoding:      Atom,
    format:        int,
    nitems:        uint,
}

XICCEncodingStyle :: enum i32 {
    XStringStyle,
    XCompoundTextStyle,
    XTextStyle,
    XStdICCTextStyle,
    XUTF8StringStyle,
}

XIconSize :: struct {
	min_width:     i32,
	min_height:    i32,
	max_width:     i32,
	max_height:    i32,
	width_inc:     i32,
	height_inc:    i32,
}

XClassHint :: struct {
	res_name:      cstring,
	res_class:     cstring,
}

XComposeStatus :: struct {
    compose_ptr:   rawptr,
    chars_matched: i32,
}

Region :: distinct rawptr

XVisualInfo :: struct {
	visual:        ^Visual,
	visualid:      VisualID,
	screen:        i32,
	depth:         i32,
	class:         i32,
	red_mask:      uint,
	green_mask:    uint,
	blue_mask:     uint,
	colormap_size: i32,
	bits_per_rgb:  i32,
}

XStandardColormap :: struct {
	colormap:      Colormap,
	red_max:       uint,
	red_mult:      uint,
	green_max:     uint,
	green_mult:    uint,
	blue_max:      uint,
	blue_mult:     uint,
	base_pixel:    uint,
	visualid:      VisualID,
	killid:        XID,
}

XContext :: i32

/* ----  X11/Xresource.h ----------------------------------------------------*/

XrmQuark     :: i32
XrmQuarkList :: [^]i32
XrmString    :: cstring

XrmBinding :: enum i32 {
	XrmBindTightly,
	XrmBindLoosely,
}

XrmBindingList :: [^]XrmBinding

XrmName           :: XrmQuark
XrmNameList       :: XrmQuarkList
XrmClass          :: XrmQuark
XrmClassList      :: XrmQuarkList
XrmRepresentation :: XrmQuark

XrmValue :: struct {
    size: u32,
    addr: rawptr,
}
XrmValuePtr   :: [^]XrmValue

XrmHashBucket :: distinct rawptr
XrmHashTable  :: [^]XrmHashBucket
XrmSearchList :: [^]XrmHashTable
XrmDatabase   :: distinct rawptr

XrmOptionKind :: enum {
    XrmoptionNoArg,
    XrmoptionIsArg,
    XrmoptionStickyArg,
    XrmoptionSepArg,
    XrmoptionResArg,
    XrmoptionSkipArg,
    XrmoptionSkipLine,
    XrmoptionSkipNArgs,
}

XrmOptionDescRec :: struct {
    option:    cstring,
    specifier: cstring,
    argKind:   XrmOptionKind,
    value:     rawptr,
}

XrmOptionDescList :: [^]XrmOptionDescRec
