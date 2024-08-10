//+build linux, openbsd, freebsd
package xlib

foreign import xlib "system:X11"
foreign xlib {
	@(link_name="_Xdebug") _Xdebug: i32
}

foreign import xcursor "system:Xcursor"
@(default_calling_convention="c", link_prefix="X")
foreign xcursor {
	cursorGetTheme          :: proc(display: ^Display) -> cstring ---
	cursorGetDefaultSize    :: proc(display: ^Display) -> i32 ---
	cursorLibraryLoadCursor :: proc(display: ^Display, name: cstring) -> Cursor ---
	cursorLibraryLoadImage  :: proc(name: cstring, theme: cstring, size: i32) -> rawptr ---
	cursorImageLoadCursor   :: proc(display: ^Display, img: rawptr) -> Cursor ---
	cursorImageDestroy      :: proc(img: rawptr) ---
}

foreign import xfixes "system:Xfixes"
@(default_calling_convention="c", link_prefix="XFixes")
foreign xfixes {
	HideCursor :: proc(display: ^Display, window: Window) ---
	ShowCursor :: proc(display: ^Display, window: Window) ---
}

foreign import xrandr "system:Xrandr"
@(default_calling_convention="c")
foreign xrandr {
	XRRSizes :: proc(display: ^Display, screen: i32, nsizes: ^i32) -> [^]XRRScreenSize ---
	XRRGetScreenResources :: proc(display: ^Display, window: Window) -> ^XRRScreenResources ---
	XRRFreeScreenResources :: proc(resources: ^XRRScreenResources) ---
	XRRGetOutputInfo :: proc(display: ^Display, resources: ^XRRScreenResources, output: RROutput) -> ^XRROutputInfo ---
	XRRFreeOutputInfo :: proc(output_info: ^XRROutputInfo) ---
	XRRGetCrtcInfo :: proc(display: ^Display, resources: ^XRRScreenResources, crtc: RRCrtc) -> ^XRRCrtcInfo ---
	XRRFreeCrtcInfo :: proc(crtc_info: ^XRRCrtcInfo) ---
	XRRGetMonitors :: proc(dpy: ^Display, window: Window, get_active: b32, nmonitors: ^i32) -> [^]XRRMonitorInfo ---
}

foreign import xinput "system:Xi"
foreign xinput {
	XISelectEvents :: proc(display: ^Display, window: Window, masks: [^]XIEventMask, num_masks: i32) -> i32 ---
	XIQueryVersion :: proc(display: ^Display, major: ^i32, minor: ^i32) -> Status ---
}

XISetMask :: proc(ptr: [^]u8, event: XIEventType) {
	ptr[cast(i32)event >> 3] |= (1 << cast(uint)((cast(i32)event) & 7))
}

XIMaskIsSet :: proc(ptr: [^]u8, event: i32) -> bool {
	return (ptr[event >> 3] & (1 << cast(uint)((event) & 7))) != 0
}


/* ----  X11/Xlib.h ---------------------------------------------------------*/

@(default_calling_convention="c", link_prefix="X")
foreign xlib {
	// Free data allocated by Xlib
	Free              :: proc(ptr: rawptr) ---
	// Opening/closing a display
	OpenDisplay       :: proc(name: cstring) -> ^Display ---
	CloseDisplay      :: proc(display: ^Display) ---
	SetCloseDownMode  :: proc(display: ^Display, mode: CloseMode) ---
	// Generate a no-op request
	NoOp              :: proc(display: ^Display) ---
	// Display macros (connection)
	ConnectionNumber  :: proc(display: ^Display) -> i32 ---
	ExtendedMaxRequestSize :: proc(display: ^Display) -> int ---
	MaxRequestSize    :: proc(display: ^Display) -> int ---
	LastKnownRequestProcessed :: proc(display: ^Display) -> uint ---
	NextRequest       :: proc(display: ^Display) -> uint ---
	ProtocolVersion   :: proc(display: ^Display) -> i32 ---
	ProtocolRevision  :: proc(display: ^Display) -> i32 ---
	QLength           :: proc(display: ^Display) -> i32 ---
	ServerVendor      :: proc(display: ^Display) -> cstring ---
	VendorRelease     :: proc(display: ^Display) -> i32 ---
	// Display macros (display properties)
	BlackPixel        :: proc(display: ^Display, screen_no: i32) -> uint ---
	WhitePixel        :: proc(display: ^Display, screen_no: i32) -> uint ---
	ListDepths        :: proc(display: ^Display, screen_no: i32, count: ^i32) -> [^]i32 ---
	DisplayCells      :: proc(display: ^Display, screen_no: i32) -> i32 ---
	DisplayPlanes     :: proc(display: ^Display, screen_no: i32) -> i32 ---
	ScreenOfDisplay   :: proc(display: ^Display, screen_no: i32) -> ^Screen ---
	DisplayString     :: proc(display: ^Display) -> cstring ---
	// Display macros (defaults)
	DefaultColormap   :: proc(display: ^Display, screen_no: i32) -> Colormap ---
	DefaultDepth      :: proc(display: ^Display, screen_no: i32) -> i32 ---
	DefaultGC         :: proc(display: ^Display, screen_no: i32) -> GC ---
	DefaultRootWindow :: proc(display: ^Display) -> Window ---
	DefaultScreen     :: proc(display: ^Display) -> i32 ---
	DefaultVisual     :: proc(display: ^Display, screen_no: i32) -> ^Visual ---
	DefaultScreenOfDisplay :: proc(display: ^Display) -> ^Screen ---
	// Display macros (other)
	RootWindow        :: proc(display: ^Display, screen_no: i32) -> Window ---
	ScreenCount       :: proc(display: ^Display) -> i32 ---
	// Display image format macros
	ListPixmapFormats :: proc(display: ^Display, count: ^i32) -> [^]XPixmapFormatValues ---
	ImageByteOrder    :: proc(display: ^Display) -> ByteOrder ---
	BitmapUnit        :: proc(display: ^Display) -> i32 ---
	BitmapBitOrder    :: proc(display: ^Display) -> ByteOrder ---
	BitmapPad         :: proc(display: ^Display) -> i32 ---
	DisplayHeight     :: proc(display: ^Display, screen_no: i32) -> i32 ---
	DisplayHeightMM   :: proc(display: ^Display, screen_no: i32) -> i32 ---
	DisplayWidth      :: proc(display: ^Display, screen_no: i32) -> i32 ---
	DisplayWidthMM    :: proc(display: ^Display, screen_no: i32) -> i32 ---
	// Screen macros
	BlackPixelsOfScreen :: proc(screen: ^Screen) -> uint ---
	WhitePixelsOfScreen :: proc(screen: ^Screen) -> uint ---
	CellsOfScreen       :: proc(screen: ^Screen) -> i32 ---
	DefaultColormapOfScreen :: proc(screen: ^Screen) -> Colormap ---
	DefaultDepthOfScreen    :: proc(screen: ^Screen) -> i32 ---
	DefaultGCOfScreen       :: proc(screen: ^Screen) -> GC ---
	DefaultVisualOfScreen   :: proc(screen: ^Screen) -> ^Visual ---
	DoesBackingStore    :: proc(screen: ^Screen) -> BackingStore ---
	DoesSaveUnders      :: proc(screen: ^Screen) -> b32 ---
	DisplayOfScreen     :: proc(screen: ^Screen) -> ^Display ---
	ScreenNumberOfScreen :: proc(screen: ^Screen) -> i32 ---
	EventMaskOfScreen   :: proc(screen: ^Screen) -> EventMask ---
	WidthOfScreen       :: proc(screen: ^Screen) -> i32 ---
	HeightOfScreen      :: proc(screen: ^Screen) -> i32 ---
	WidthMMOfScreen     :: proc(screen: ^Screen) -> i32 ---
	HeightMMOfScreen    :: proc(screen: ^Screen) -> i32 ---
	MaxCmapsOfScreen    :: proc(screen: ^Screen) -> i32 ---
	MinCmapsOfScreen    :: proc(screen: ^Screen) -> i32 ---
	PlanesOfScreen      :: proc(screen: ^Screen) -> i32 ---
	RootWindowOfScreen  :: proc(screen: ^Screen) -> Window ---
	// Threading functions
	InitThreads         :: proc() -> Status ---
	LockDisplay         :: proc(display: ^Display) ---
	UnlockDisplay       :: proc(display: ^Display) ---
	// Internal connections
	AddConnectionWatch  :: proc(
		display:   ^Display,
		procedure: XConnectionWatchProc,
		data:      rawptr,
		) -> Status ---
	RemoveConnectionWatch :: proc(
		display:   ^Display,
		procedure: XConnectionWatchProc,
		data:      rawptr,
		) -> Status ---
	ProcessInternalConnections :: proc(
		display:   ^Display,
		fd:        i32,
		) ---
	InternalConnectionNumbers :: proc(
		display:   ^Display,
		fds:       ^[^]i32,
		count:     ^i32,
		) -> Status ---
	// Windows functions
	VisualIDFromVisual :: proc(visual: ^Visual) -> VisualID ---
	// Windows: creation/destruction
	CreateWindow :: proc(
		display:   ^Display,
		parent:    Window,
		x:         i32,
		y:         i32,
		width:     u32,
		height:    u32,
		bordersz:  u32,
		depth:     i32,
		class:     WindowClass,
		visual:    ^Visual,
		attr_mask: WindowAttributeMask,
		attr:      ^XSetWindowAttributes,
		) -> Window ---
	CreateSimpleWindow :: proc(
		display:   ^Display,
		parent:    Window,
		x:         i32,
		y:         i32,
		width:     u32,
		height:    u32,
		bordersz:  u32,
		border:    uint,
		bg:        uint,
		) -> Window ---
	DestroyWindow     :: proc(display: ^Display, window: Window) ---
	DestroySubwindows :: proc(display: ^Display, window: Window) ---
	// Windows: mapping/unmapping
	MapWindow         :: proc(display: ^Display, window: Window) ---
	MapRaised         :: proc(display: ^Display, window: Window) ---
	MapSubwindows     :: proc(display: ^Display, window: Window) ---
	UnmapWindow       :: proc(display: ^Display, window: Window) ---
	UnmapSubwindows   :: proc(display: ^Display, window: Window) ---
	// Windows: configuring
	ConfigureWindow :: proc(
		display: ^Display,
		window:  Window,
		mask:    WindowChangesMask,
		values:  XWindowChanges,
		) ---
	MoveWindow :: proc(
		display: ^Display,
		window:  Window,
		x:       i32,
		y:       i32,
		) ---
	ResizeWindow :: proc(
		display: ^Display,
		window:  Window,
		width:   u32,
		height:  u32,
		) ---
	MoveResizeWindow :: proc(
		display: ^Display,
		window:  Window,
		x:       i32,
		y:       i32,
		width:   u32,
		height:  u32,
		) ---
	SetWindowBorderWidth :: proc(
		display: ^Display,
		window:  Window,
		width:   u32,
		) ---
	// Window: changing stacking order
	RaiseWindow :: proc(display: ^Display, window: Window) ---
	LowerWindow :: proc(display: ^Display, window: Window) ---
	CirculateSubwindows :: proc(display: ^Display, window: Window, direction: CirculationDirection) ---
	CirculateSubwindowsUp :: proc(display: ^Display, window: Window) ---
	CirculateSubwindowsDown :: proc(display: ^Display, window: Window) ---
	RestackWindows :: proc(display: ^Display, windows: [^]Window, nwindows: i32) ---
	// Window: changing attributes
	ChangeWindowAttributes :: proc(
		display:   ^Display,
		window:    Window,
		attr_mask: WindowAttributeMask,
		attr:      XWindowAttributes,
		) ---
	SetWindowBackground :: proc(
		display:   ^Display,
		window:    Window,
		pixel:     uint,
		) ---
	SetWindowBackgroundMap :: proc(
		display:   ^Display,
		window:    Window,
		pixmap:    Pixmap,
		) ---
	SetWindowColormap :: proc(
		display:   ^Display,
		window:    Window,
		colormap:  Colormap,
		) ---
	DefineCursor :: proc(
		display:   ^Display,
		window:    Window,
		cursor:    Cursor,
		) ---
	UndefineCursor :: proc(
		display:   ^Display,
		window:    Window,
		) ---
	// Windows: querying information
	QueryTree :: proc(
		display:   ^Display,
		window:    Window,
		root:      ^Window,
		parent:    ^Window,
		children:  ^[^]Window,
		nchildren: ^u32,
		) -> Status ---
	GetWindowAttributes :: proc(
		display: ^Display,
		window:  Window,
		attr:    ^XWindowAttributes,
		) ---
	GetGeometry :: proc(
		display:   ^Display,
		drawable:  Drawable,
		root:      ^Window,
		x:         ^i32,
		y:         ^i32,
		width:     ^u32,
		height:    ^u32,
		border_sz: ^u32,
		depth:     ^u32,
		) -> Status ---
	// Windows: translating screen coordinates
	TranslateCoordinates :: proc(
		display: ^Display,
		src_window: Window,
		dst_window: Window,
		src_x:      i32,
		src_y:      i32,
		dst_x:      ^i32,
		dst_y:      ^i32,
		) -> b32 ---
	QueryPointer :: proc(
		display: ^Display,
		window:  Window,
		root:    ^Window,
		child:   ^Window,
		root_x:  ^i32,
		root_y:  ^i32,
		x:       ^i32,
		y:       ^i32,
		mask:    ^KeyMask,
		) -> b32 ---
	// Atoms
	InternAtom :: proc(
		display:  ^Display,
		name:     cstring,
		existing: b32,
		) -> Atom ---
	InternAtoms :: proc(
		display: ^Display,
		names:   [^]cstring,
		count:   i32,
		atoms:   [^]Atom,
		) -> Status ---
	GetAtomName :: proc(
		display: ^Display,
		atom:    Atom,
		) -> cstring ---
	GetAtomNames :: proc(
		display: ^Display,
		atoms:   [^]Atom,
		count:   i32,
		names:   [^]cstring,
		) -> Status ---
	// Windows: Obtaining and changing properties
	GetWindowProperty :: proc(
		display:     ^Display,
		window:      Window,
		property:    Atom,
		long_offs:   int,
		long_len:    int,
		delete:      b32,
		req_type:    Atom,
		act_type:    [^]Atom,
		act_format:  [^]i32,
		nitems:      [^]uint,
		bytes_after: [^]uint,
		props:       ^rawptr,
	) -> i32 ---
	ListProperties :: proc(
		display:     ^Display,
		window:      Window,
		num:         ^i32,
		) -> [^]Atom ---
	ChangeProperty :: proc(
		display:     ^Display,
		window:      Window,
		property:    Atom,
		type:        Atom,
		format:      i32,
		mode:        i32,
		data:        rawptr,
		count:       i32,
		) ---
	RotateWindowProperties :: proc(
		display:     ^Display,
		window:      Window,
		props:       [^]Atom,
		nprops:      i32,
		npos:        i32,
		) ---
	DeleteProperty :: proc(
		display:     ^Display,
		window:      Window,
		prop:        Atom,
		) ---
	// Selections
	SetSelectionOwner :: proc(
		display:     ^Display,
		selection:   Atom,
		owber:       Window,
		time:        Time,
		) ---
	GetSelectionOwner :: proc(
		display:     ^Display,
		selection:   Atom,
		) -> Window ---
	ConvertSelection :: proc(
		display:     ^Display,
		selection:   Atom,
		target:      Atom,
		property:    Atom,
		requestor:   Window,
		time:        Time,
		) ---
	// Creating and freeing pixmaps
	CreatePixmap :: proc(
		display:   ^Display,
		drawable:  Drawable,
		width:     u32,
		height:    u32,
		depth:     u32,
		) -> Pixmap ---
	FreePixmap :: proc(
		display:   ^Display,
		pixmap:    Pixmap,
		) ---
	// Creating recoloring and freeing cursors
	CreateFontCursor :: proc(
		display:   ^Display,
		shape:     CursorShape,
		) -> Cursor ---
	CreateGlyphCursor :: proc(
		display:   ^Display,
		src_font:  Font,
		mask_font: Font,
		src_char:  u32,
		mask_char: u32,
		fg:        ^XColor,
		bg:        ^XColor,
		) -> Cursor ---
	CreatePixmapCursor :: proc(
		display:   ^Display,
		source:    Pixmap,
		mask:      Pixmap,
		fg:        XColor,
		bg:        ^XColor,
		x:         u32,
		y:         u32,
		) -> Cursor ---
	QueryBestCursor :: proc(
		display:    ^Display,
		drawable:   Drawable,
		width:      u32,
		height:     u32,
		out_width:  ^u32,
		out_height: ^u32,
		) -> Status ---
	RecolorCursor :: proc(
		display:    ^Display,
		cursor:     Cursor,
		fg:         ^XColor,
		bg:         ^XColor,
		) ---
	FreeCursor :: proc(display: ^Display, cursor: Cursor) ---
	// Creation/destruction of colormaps
	CreateColormap :: proc(
		display:  ^Display,
		window:   Window,
		visual:   ^Visual,
		alloc:    ColormapAlloc,
		) -> Colormap ---
	CopyColormapAndFree :: proc(
		display:  ^Display,
		colormap: Colormap,
		) -> Colormap ---
	FreeColormap :: proc(
		display:  ^Display,
		colormap: Colormap,
		) ---
	// Mapping color names to values
	LookupColor :: proc(
		display:  ^Display,
		colomap:  Colormap,
		name:     cstring,
		exact:    ^XColor,
		screen:   ^XColor,
		) -> Status ---
	// Allocating and freeing color cells
	AllocColor :: proc(
		display:  ^Display,
		colormap: Colormap,
		screen:   ^XColor,
		) -> Status ---
	AllocNamedColor :: proc(
		display:  ^Display,
		colormap: Colormap,
		name:     cstring,
		screen:   ^XColor,
		exact:    ^XColor,
		) -> Status ---
	AllocColorCells :: proc(
		display:  ^Display,
		colormap: Colormap,
		contig:   b32,
		pmasks:   [^]uint,
		np:       u32,
		pixels:   [^]uint,
		npixels:  u32,
		) -> Status ---
	AllocColorPlanes :: proc(
		display:  ^Display,
		colormap: Colormap,
		contig:   b32,
		pixels:   [^]uint,
		ncolors:  i32,
		nreds:    i32,
		ngreens:  i32,
		nblues:   i32,
		rmask:    [^]uint,
		gmask:    [^]uint,
		bmask:    [^]uint,
		) -> Status ---
	FreeColors :: proc(
		display:  ^Display,
		colormap: Colormap,
		pixels:   [^]uint,
		npixels:  i32,
		planes:   uint,
		) ---
	// Modifying and querying colormap cells
	StoreColor :: proc(
		display:  ^Display,
		colormap: Colormap,
		color:    ^XColor,
		) ---
	StoreColors :: proc(
		display:  ^Display,
		colormap: Colormap,
		color:    [^]XColor,
		ncolors:  i32,
		) ---
	// Graphics context functions
	CreateGC :: proc(
		display:  ^Display,
		drawable: Drawable,
		mask:     GCAttributeMask,
		attr:     ^XGCValues,
		) -> GC ---
	CopyGC :: proc(
		display:  ^Display,
		src:      GC,
		dst:      GC,
		mask:     GCAttributeMask,
		) ---
	ChangeGC :: proc(
		display:  ^Display,
		gc:       GC,
		mask:     GCAttributeMask,
		values:   ^XGCValues,
		) ---
	GetGCValues :: proc(
		display:  ^Display,
		gc:       GC,
		mask:     GCAttributeMask,
		values:   ^XGCValues,
		) -> Status ---
	FreeGC :: proc(display: ^Display, gc: GC) ---
	GCContextFromGC :: proc(gc: GC) -> GContext ---
	FlushGC :: proc(display: ^Display, gc: GC) ---
	// Convenience routines for GC
	SetState :: proc(
		display: ^Display,
		gc:      GC,
		fg:      uint,
		bg:      uint,
		fn:      GCFunction,
		pmask:   uint,
		) ---
	SetForeground :: proc(
		display: ^Display,
		gc:      GC,
		fg:      uint,
		) ---
	SetBackground :: proc(
		display: ^Display,
		gc:      GC,
		bg:      uint,
		) ---
	SetFunction :: proc(
		display: ^Display,
		gc:      GC,
		fn:      GCFunction,
		) ---
	SetPlaneMask :: proc(
		display: ^Display,
		gc:      GC,
		pmask:   uint,
		) ---
	SetLineAttributes :: proc(
		display:    ^Display,
		gc:         GC,
		width:      u32,
		line_style: LineStyle,
		cap_style:  CapStyle,
		join_style: JoinStyle,
		) ---
	SetDashes :: proc(
		display:   ^Display,
		gc:        GC,
		dash_offs: i32,
		dash_list: [^]i8,
		n:         i32,
		) ---
	SetFillStyle :: proc(
		display: ^Display,
		gc:      GC,
		style:   FillStyle,
		) ---
	SetFillRule :: proc(
		display: ^Display,
		gc:      GC,
		rule:    FillRule,
		) ---
	QueryBestSize :: proc(
		display:    ^Display,
		class:      i32,
		which:      Drawable,
		width:      u32,
		height:     u32,
		out_width:  ^u32,
		out_height: ^u32,
		) -> Status ---
	QueryBestTile :: proc(
		display:    ^Display,
		which:      Drawable,
		width:      u32,
		height:     u32,
		out_width:  ^u32,
		out_height: ^u32,
		) -> Status ---
	QueryBestStripple :: proc(
		display:    ^Display,
		which:      Drawable,
		width:      u32,
		height:     u32,
		out_width:  u32,
		out_height: u32,
		) -> Status ---
	SetTile       :: proc(display: ^Display, gc: GC, tile: Pixmap) ---
	SetStripple   :: proc(display: ^Display, gc: GC, stripple: Pixmap) ---
	SetTSOrigin   :: proc(display: ^Display, gc: GC, x: i32, y: i32) ---
	SetFont       :: proc(display: ^Display, gc: GC, font: Font) ---
	SetClipOrigin :: proc(display: ^Display, gc: GC, x: i32, y: i32) ---
	SetClipMask   :: proc(display: ^Display, gc: GC, pixmap: Pixmap) ---
	SetClipRectangles :: proc(
		display:  ^Display,
		gc:       GC,
		x:        i32,
		y:        i32,
		rects:    [^]XRectangle,
		n:        i32,
		ordering: i32,
		) ---
	SetArcMode           :: proc(display: ^Display, gc: GC, mode: ArcMode) ---
	SetSubwindowMode     :: proc(display: ^Display, gc: GC, mode: SubwindowMode) ---
	SetGraphicsExposures :: proc(display: ^Display, gc: GC, exp: b32) ---
	// Graphics functions
	ClearArea :: proc(
		display: ^Display, 
		window:  Window, 
		x:       i32, 
		y:       i32, 
		width:   u32, 
		height:  u32, 
		exp:     b32,
		) ---
	ClearWindow :: proc(
		display: ^Display,
		window: Window,
		) ---
	CopyArea :: proc(
		display: ^Display,
		src:     Drawable,
		dst:     Drawable,
		gc:      GC,
		src_x:   i32,
		src_y:   i32,
		width:   u32,
		height:  u32,
		dst_x:   i32,
		dst_y:   i32,
		) ---
	CopyPlane :: proc(
		display: ^Display,
		src:     Drawable,
		dst:     Drawable,
		gc:      GC,
		src_x:   i32,
		src_y:   i32,
		width:   u32,
		height:  u32,
		dst_x:   i32,
		dst_y:   i32,
		plane:   uint,
		) ---
	// Drawing lines, points, rectangles and arc
	DrawPoint :: proc(
		display:  ^Display,
		drawable: Drawable,
		gc:       GC,
		x:        i32,
		y:        i32,
		) ---
	DrawPoints :: proc(
		display:  Display,
		drawable: Drawable,
		gc:       GC,
		point:    [^]XPoint,
		npoints:  i32,
		mode:     CoordMode,
		) ---
	DrawLine :: proc(
		display:  ^Display,
		drawable: Drawable,
		gc:       GC,
		x1:       i32,
		y1:       i32,
		x2:       i32,
		y2:       i32,
		) ---
	DrawLines :: proc(
		display:  ^Display,
		drawable: Drawable,
		gc:       GC,
		points:   [^]XPoint,
		npoints:  i32,
		) ---
	DrawSegments :: proc(
		display:  ^Display,
		drawable: Drawable,
		gc:       GC,
		segs:     [^]XSegment,
		nsegs:    i32,
		) ---
	DrawRectangle :: proc(
		display:  ^Display,
		drawable: Drawable,
		gc:       GC,
		x:        i32,
		y:        i32,
		width:    u32,
		height:   u32,
		) ---
	DrawRectangles :: proc(
		display:  ^Display,
		drawable: Drawable,
		gc:       GC,
		rects:    [^]XRectangle,
		nrects:   i32,
		) ---
	DrawArc :: proc(
		display:  ^Display,
		drawable: Drawable,
		gc:       GC,
		x:        i32,
		y:        i32,
		width:    u32,
		height:   u32,
		angle1:   i32,
		angle2:   i32,
		) ---
	DrawArcs :: proc(
		display:  ^Display,
		drawable: Drawable,
		gc:       GC,
		arcs:     [^]XArc,
		narcs:    i32,
		) ---
	// Filling areas
	FillRectangle :: proc(
		display:  ^Display,
		drawable: Drawable,
		gc:       GC,
		x:        i32,
		y:        i32,
		width:    u32,
		height:   u32,
		) ---
	FillRectangles :: proc(
		display:  ^Display,
		drawable: Drawable,
		gc:       GC,
		rects:    [^]XRectangle,
		nrects:   i32,
		) ---
	FillPolygon :: proc(
		display:  ^Display,
		drawable: Drawable,
		gc:       GC,
		points:   [^]XPoint,
		npoints:  i32,
		shape:    Shape,
		mode:     CoordMode,
		) ---
	FillArc :: proc(
		display:  ^Display,
		drawable: Drawable,
		gc:       GC,
		x:        i32,
		y:        i32,
		width:    u32,
		height:   u32,
		angle1:   i32,
		angle2:   i32,
		) ---
	FillArcs :: proc(
		display:  ^Display,
		drawable: Drawable,
		gc:       GC,
		arcs:     [^]XArc,
		narcs:    i32,
		) ---
	// Font metrics
	LoadFont        :: proc(display: ^Display, name: cstring) -> Font ---
	QueryFont       :: proc(display: ^Display, id: XID) -> ^XFontStruct ---
	LoadQueryFont   :: proc(display: ^Display, name: cstring) -> ^XFontStruct ---
	FreeFont        :: proc(display: ^Display, font_struct: ^XFontStruct) ---
	GetFontProperty :: proc(font_struct: ^XFontStruct, atom: Atom, ret: ^uint) -> b32 ---
	UnloadFont      :: proc(display: ^Display, font: Font) ---
	ListFonts       :: proc(display: ^Display, pat: cstring, max: i32, count: ^i32) -> [^]cstring ---
	FreeFontNames   :: proc(display: ^Display, list: [^]cstring) ---
	ListFontsWithInfo :: proc(
		display: ^Display,
		pat:     cstring,
		max:     i32,
		count:   ^i32,
		info:    ^[^]XFontStruct,
		) -> [^]cstring ---
	FreeFontInfo :: proc(names: [^]cstring, info: [^]XFontStruct, count: i32) ---
	// Computing character string sizes
	TextWidth :: proc(font_struct: ^XFontStruct, string: [^]u8, count: i32) -> i32 ---
	TextWidth16 :: proc(font_struct: ^XFontStruct, string: [^]XChar2b, count: i32) -> i32 ---
	TextExtents :: proc(
		font_struct: ^XFontStruct,
		string:      [^]u8,
		nchars:      i32,
		direction:   ^FontDirection,
		ascent:      ^i32,
		descent:     ^i32,
		ret:         ^XCharStruct,
		) ---
	TextExtents16 :: proc(
		font_struct: ^XFontStruct,
		string:      [^]XChar2b,
		nchars:      i32,
		direction:   ^FontDirection,
		ascent:      ^i32,
		descent:     ^i32,
		ret:         ^XCharStruct,
		) ---
	QueryTextExtents :: proc(
		display:     ^Display,
		font_id:     XID,
		string:      [^]u8,
		nchars:      i32,
		direction:   ^FontDirection,
		ascent:      ^i32,
		descent:     ^i32,
		ret:         ^XCharStruct,
		) ---
	QueryTextExtents16 :: proc(
		display:     ^Display,
		font_id:     XID,
		string:      [^]XChar2b,
		nchars:      i32,
		direction:   ^FontDirection,
		ascent:      ^i32,
		descent:     ^i32,
		ret:         ^XCharStruct,
		) ---
	// Drawing complex text
	DrawText :: proc(
		display:  ^Display,
		drawable: Drawable,
		gc:       GC,
		x:        i32,
		y:        i32,
		items:    XTextItem,
		nitems:   i32,
		) ---
	DrawText16 :: proc(
		display:  ^Display,
		drawable: Drawable,
		gc:       GC,
		x:        i32,
		y:        i32,
		items:    XTextItem16,
		nitems:   i32,
		) ---
	// Drawing text characters
	DrawString :: proc(
		display:  ^Display,
		drawable: Drawable,
		gc:       GC,
		x:        i32,
		y:        i32,
		string:   [^]u8,
		length:   i32,
		) ---
	DrawString16 :: proc(
		display:  ^Display,
		drawable: Drawable,
		gc:       GC,
		x:        i32,
		y:        i32,
		string:   [^]XChar2b,
		length:   i32,
		) ---
	DrawImageString :: proc(
		display:  ^Display,
		drawable: Drawable,
		gc:       GC,
		x:        i32,
		y:        i32,
		string:   [^]u8,
		length:   i32,
		) ---
	DrawImageString16 :: proc(
		display:  ^Display,
		drawable: Drawable,
		gc:       GC,
		x:        i32,
		y:        i32,
		string:   [^]XChar2b,
		length:   i32,
		) ---
	// Transferring images between client and server
	InitImage :: proc(image: ^XImage) -> Status ---
	PutImage :: proc(
		display:  ^Display,
		drawable: Drawable,
		gc:       GC,
		image:    ^XImage,
		src_x:    i32,
		src_y:    i32,
		dst_x:    i32,
		dst_y:    i32,
		width:    u32,
		height:   u32,
		) ---
	GetImage :: proc(
		display:  ^Display,
		drawable: Drawable,
		x:        i32,
		y:        i32,
		width:    u32,
		height:   u32,
		mask:     uint,
		format:   ImageFormat,
		) -> ^XImage ---
	GetSubImage :: proc(
		display:  ^Display,
		drawable: Drawable,
		src_x:    i32,
		src_y:    i32,
		width:    u32,
		height:   u32,
		mask:     uint,
		format:   ImageFormat,
		dst:      ^XImage,
		dst_x:    i32,
		dst_y:    i32,
		) -> ^XImage ---
	// Window and session manager functions
	ReparentWindow :: proc(
		display: ^Display,
		window:  Window,
		parent:  Window,
		x:       i32,
		y:       i32,
		) ---
	ChangeSaveSet :: proc(
		display: ^Display,
		window:  Window,
		mode:    SaveSetChangeMode,
		) ---
	AddToSaveSet :: proc(
		display: ^Display,
		window:  Window,
		) ---
	RemoveFromSaveSet :: proc(
		display: ^Display,
		window:  Window,
		) ---
	// Managing installed colormaps
	InstallColormap        :: proc(display: ^Display, colormap: Colormap) ---
	UninstallColormap      :: proc(display: ^Display, colormap: Colormap) ---
	ListInstalledColormaps :: proc(display: ^Display, window: Window, n: ^i32) -> [^]Colormap ---
	// Setting and retrieving font search paths
	SetFontPath            :: proc(display: ^Display, dirs: [^]cstring, ndirs: i32) ---
	GetFontPath            :: proc(display: ^Display, npaths: ^i32) -> [^]cstring ---
	FreeFontPath           :: proc(list: [^]cstring) ---
	// Grabbing the server
	GrabServer             :: proc(display: ^Display) ---
	UngrabServer           :: proc(display: ^Display) ---
	// Killing clients
	KillClient             :: proc(display: ^Display, resource: XID) ---
	// Controlling the screen saver
	SetScreenSaver :: proc(
		display:   ^Display,
		timeout:   i32,
		interval:  i32,
		blanking:  ScreenSaverBlanking,
		exposures: ScreenSavingExposures,
		) ---
	ForceScreenSaver    :: proc(display: ^Display, mode: ScreenSaverForceMode) ---
	ActivateScreenSaver :: proc(display: ^Display) ---
	ResetScreenSaver    :: proc(display: ^Display) ---
	GetScreenSaver :: proc(
		display: ^Display,
		timeout: ^i32,
		interval: ^i32,
		blanking: ^ScreenSaverBlanking,
		exposures: ^ScreenSavingExposures,
		) ---
	// Controlling host address
	AddHost     :: proc(display: ^Display, addr: ^XHostAddress) ---
	AddHosts    :: proc(display: ^Display, hosts: [^]XHostAddress, nhosts: i32) ---
	ListHosts   :: proc(display: ^Display, nhosts: ^i32, state: [^]b32) -> [^]XHostAddress ---
	RemoveHost  :: proc(display: ^Display, host: XHostAddress) ---
	RemoveHosts :: proc(display: ^Display, hosts: [^]XHostAddress, nhosts: i32) ---
	// Access control list
	SetAccessControl     :: proc(display: ^Display, mode: AccessControlMode) ---
	EnableAccessControl  :: proc(display: ^Display) ---
	DisableAccessControl :: proc(display: ^Display) ---
	// Events
	SelectInput   :: proc(display: ^Display, window: Window, mask: EventMask) ---
	Flush         :: proc(display: ^Display) ---
	Sync          :: proc(display: ^Display) ---
	EventsQueued  :: proc(display: ^Display, mode: EventQueueMode) -> i32 ---
	Pending       :: proc(display: ^Display) -> i32 ---
	NextEvent     :: proc(display: ^Display, event: ^XEvent) ---
	PeekEvent     :: proc(display: ^Display, event: ^XEvent) ---
	GetEventData  :: proc(display: ^Display, cookie: ^XGenericEventCookie) -> b32 ---
	FreeEventData :: proc(display: ^Display, cookie: ^XGenericEventCookie) ---
	// Selecting events using a predicate procedure
	IfEvent :: proc(
		display:   ^Display,
		event:     ^XEvent,
		predicate: #type proc "c" (display: ^Display, event: ^XEvent, ctx: rawptr) -> b32,
		ctx:       rawptr,
		) ---
	CheckIfEvent :: proc(
		display:   ^Display,
		event:     ^XEvent,
		predicate: #type proc "c" (display: ^Display, event: ^XEvent, ctx: rawptr) -> b32,
		arg:       rawptr,
		) -> b32 ---
	PeekIfEvent :: proc(
		display:   ^Display,
		event:     ^XEvent,
		predicate: #type proc "c" (display: ^Display, event: ^XEvent, ctx: rawptr) -> b32,
		ctx:       rawptr,
		) ---
	// Selecting events using a window or event mask
	WindowEvent :: proc(
		display:   ^Display,
		window:    Window,
		mask:      EventMask,
		event:     ^XEvent,
		) ---
	CheckWindowEvent :: proc(
		display:   ^Display,
		window:    Window,
		mask:      EventMask,
		event:     ^XEvent,
		) -> b32 ---
	MaskEvent :: proc(
		display: ^Display,
		mask:    EventMask,
		event:   ^XEvent,
		) ---
	CheckMaskEvent :: proc(
		display: ^Display,
		mask:    EventMask,
		event:   ^XEvent,
		) -> b32 ---
	CheckTypedEvent :: proc(
		display: ^Display,
		type:    EventType,
		event:   ^XEvent,
		) -> b32 ---
	CheckTypedWindowEvent :: proc(
		display: ^Display,
		window:  Window,
		type:    EventType,
		event:   ^XEvent,
		) -> b32 ---
	// Putting events back
	PutBackEvent :: proc(
		display: ^Display,
		event:   ^XEvent,
		) ---
	// Sending events to other applications
	SendEvent :: proc(
		display:   ^Display,
		window:    Window,
		propagate: b32,
		mask:      EventMask,
		event:     ^XEvent,
		) -> Status ---
	// Getting the history of pointer motion
	DisplayMotionBufferSize :: proc(display: ^Display) -> uint ---
	GetMotionEvents :: proc(
		display: ^Display,
		window: Window,
		start: Time,
		stop: Time,
		nevents: ^i32,
		) -> [^]XTimeCoord ---
	// Enabling or disabling synchronization
	SetAfterFunction :: proc(
		display:   ^Display,
		procedure: #type proc "c" (display: ^Display) -> i32,
		) -> i32 ---
	Synchronize :: proc(
		display: ^Display,
		onoff: b32,
		) -> i32 ---
	// Error handling
	SetErrorHandler :: proc(
		handler: #type proc "c" (display: ^Display, event: ^XErrorEvent) -> i32,
		) -> i32 ---
	GetErrorText :: proc(
		display: ^Display,
		code: i32,
		buffer: [^]u8,
		size: i32,
		) ---
	GetErrorDatabaseText :: proc(
		display: ^Display,
		name: cstring,
		message: cstring,
		default_string: cstring,
		buffer: [^]u8,
		size: i32,
		) ---
	DisplayName :: proc(string: cstring) -> cstring ---
	SetIOErrorHandler :: proc(
		handler: #type proc "c" (display: ^Display) -> i32,
		) -> i32 ---
	// Pointer grabbing
	GrabPointer :: proc(
		display:       ^Display,
		grab_window:   Window,
		owner_events:  b32,
		mask:          EventMask,
		pointer_mode:  GrabMode,
		keyboard_mode: GrabMode,
		confine_to:    Window,
		cursor:        Cursor,
		time:          Time,
		) -> i32 ---
	UngrabPointer :: proc(
		display:       ^Display,
		time:          Time,
		) -> i32 ---
	ChangeActivePointerGrab :: proc(
		display:       ^Display,
		event_mask:    EventMask,
		cursor:        Cursor,
		time:          Time,
		) ---
	GrabButton :: proc(
		display:       ^Display,
		button:        u32,
		modifiers:     InputMask,
		grab_window:   Window,
		owner_events:  b32,
		event_mask:    EventMask,
		pointer_mode:  GrabMode,
		keyboard_mode: GrabMode,
		confine_to:    Window,
		cursor:        Cursor,
		) ---
	UngrabButton :: proc(
		display:       ^Display,
		button:        u32,
		modifiers:     InputMask,
		grab_window:   Window,
		) ---
	GrabKeyboard :: proc(
		display:       ^Display,
		grab_window:   Window,
		owner_events:  b32,
		pointer_mode:  GrabMode,
		keyboard_mode: GrabMode,
		time:          Time,
		) -> i32 ---
	UngrabKeyboard :: proc(
		display:       ^Display,
		time:          Time,
		) ---
	GrabKey :: proc(
		display:       ^Display,
		keycode:       i32,
		modifiers:     InputMask,
		grab_window:   Window,
		owner_events:  b32,
		pointer_mode:  GrabMode,
		keyboard_mode: GrabMode,
		) ---
	UngrabKey :: proc(
		display:       ^Display,
		keycode:       i32,
		modifiers:     InputMask,
		grab_window:   Window,
		) ---
	// Resuming event processing
	AllowEvents :: proc(display: ^Display, evend_mode: AllowEventsMode, time: Time) ---
	// Moving the pointer
	WarpPointer :: proc(
		display:    ^Display,
		src_window: Window,
		dst_window: Window,
		src_x:      i32,
		src_y:      i32,
		src_width:  u32,
		src_height: u32,
		dst_x:      i32,
		dst_y:      i32,
		) ---
	// Controlling input focus
	SetInputFocus :: proc(
		display: ^Display,
		focus: Window,
		revert_to: FocusRevert,
		time: Time,
		) ---
	GetInputFocus :: proc(
		display: ^Display,
		focus: ^Window,
		revert_to: ^FocusRevert,
		) ---
	// Manipulating the keyboard and pointer settings
	ChangeKeyboardControl :: proc(
		display: ^Display,
		mask: KeyboardControlMask,
		values: ^XKeyboardControl,
		) ---
	GetKeyboardControl :: proc(
		display: ^Display,
		values: ^XKeyboardState,
		) ---
	AutoRepeatOn  :: proc(display: ^Display) ---
	AutoRepeatOff :: proc(display: ^Display) ---
	Bell          :: proc(display: ^Display, percent: i32) ---
	QueryKeymap   :: proc(display: ^Display, keys: [^]u32) ---
	SetPointerMapping :: proc(display: ^Display, map_should_not_be_a_keyword: [^]u8, nmap: i32) -> i32 ---
	GetPointerMapping :: proc(display: ^Display, map_should_not_be_a_keyword: [^]u8, nmap: i32) -> i32 ---
	ChangePointerControl :: proc(
		display:           ^Display,
		do_accel:          b32,
		do_threshold:      b32,
		accel_numerator:   i32,
		accel_denominator: i32,
		threshold:         i32,
		) ---
	GetPointerControl :: proc(
		display: ^Display,
		accel_numerator:   ^i32,
		accel_denominator: ^i32,
		threshold:         ^i32,
		) ---
	// Manipulating the keyboard encoding
	DisplayKeycodes :: proc(
		display:      ^Display,
		min_keycodes: ^i32,
		max_keycodes: ^i32,
		) ---
	GetKeyboardMapping :: proc(
		display:     ^Display,
		first:       KeyCode,
		count:       i32,
		keysyms_per: ^i32,
		) -> ^KeySym ---
	ChangeKeyboardMapping :: proc(
		display:     ^Display,
		first:       KeyCode,
		keysyms_per: i32,
		keysyms:     [^]KeySym,
		num_codes:   i32,
		) ---
	NewModifiermap :: proc(max_keys_per_mode: i32) -> ^XModifierKeymap ---
	InsertModifiermapEntry :: proc(
		modmap:        ^XModifierKeymap,
		keycode_entry: KeyCode,
		modifier:      i32,
		) -> ^XModifierKeymap ---
	DeleteModifiermapEntry :: proc(
		modmap: ^XModifierKeymap,
		keycode_entry: KeyCode,
		modifier: i32,
		) -> ^XModifierKeymap ---
	FreeModifiermap :: proc(modmap: ^XModifierKeymap) ---
	SetModifierMapping :: proc(display: ^Display, modmap: ^XModifierKeymap) -> i32 ---
	GetModifierMapping :: proc(display: ^Display) -> ^XModifierKeymap ---
	// Manipulating top-level windows
	IconifyWindow :: proc(
		dipslay:   ^Display,
		window:    Window,
		screen_no: i32,
		) -> Status ---
	WithdrawWindow :: proc(
		dipslay:   ^Display,
		window:    Window,
		screen_no: i32,
		) -> Status ---
	ReconfigureWMWindow :: proc(
		dipslay:   ^Display,
		window:    Window,
		screen_no: i32,
		mask:      WindowChangesMask,
		changes:   ^XWindowChanges,
		) -> Status ---
	// Getting and setting the WM_NAME property
	SetWMName :: proc(
		display:   ^Display,
		window:    Window,
		prop:      ^XTextProperty,
		) ---
	GetWMName :: proc(
		display: ^Display,
		window:  Window,
		prop:    ^XTextProperty,
		) -> Status ---
	StoreName :: proc(
		display: ^Display,
		window:  Window,
		name:    cstring,
		) ---
	FetchName :: proc(
		display: ^Display,
		window:  Window,
		name:    ^cstring,
		) -> Status ---
	SetWMIconName :: proc(
		display: ^Display,
		window:  Window,
		prop:    ^XTextProperty,
		) ---
	GetWMIconName :: proc(
		display: ^Display,
		window:  Window,
		prop:    ^XTextProperty,
		) -> Status ---
	SetIconName :: proc(
		display: ^Display,
		window:  Window,
		name:    cstring,
		) ---
	GetIconName :: proc(
		display: ^Display,
		window:  Window,
		prop:    ^cstring,
		) -> Status ---
	// Setting and reading WM_HINTS property
	AllocWMHints :: proc() -> ^XWMHints ---
	SetWMHints :: proc(
		display: ^Display,
		window:  Window,
		hints:   ^XWMHints,
		) ---
	GetWMHints :: proc(
		display: ^Display,
		window:  Window,
		) -> ^XWMHints ---
	// Setting and reading MW_NORMAL_HINTS property
	AllocSizeHints :: proc() -> ^XSizeHints ---
	SetWMNormalHints :: proc(
		display: ^Display,
		window:  Window,
		hints:   ^XSizeHints,
		) ---
	GetWMNormalHints :: proc(
		display: ^Display,
		window: Window,
		hints: ^XSizeHints,
		flags: ^SizeHints,
		) -> Status ---
	SetWMSizeHints :: proc(
		display: ^Display,
		window:  Window,
		hints:   ^XSizeHints,
		prop:    Atom,
		) ---
	GetWMSizeHints :: proc(
		display: ^Display,
		window:  Window,
		hints:   ^XSizeHints,
		masks:   ^SizeHints,
		prop:    Atom,
		) -> Status ---
	// Setting and reading the WM_CLASS property
	AllocClassHint :: proc() -> ^XClassHint ---
	SetClassHint :: proc(
		display: ^Display,
		window:  Window,
		hint:    ^XClassHint,
		) ---
	GetClassHint :: proc(
		display: ^Display,
		window:  Window,
		hint:    ^XClassHint,
		) -> Status ---
	// Setting and reading WM_TRANSIENT_FOR property
	SetTransientForHint :: proc(
		display:     ^Display,
		window:      Window,
		prop_window: Window,
		) ---
	GetTransientForHint :: proc(
		display:     ^Display,
		window:      Window,
		prop_window: ^Window,
		) -> Status ---
	// Setting and reading the WM_PROTOCOLS property
	SetWMProtocols :: proc(
		display:   ^Display,
		window:    Window,
		protocols: [^]Atom,
		count:     i32,
		) -> Status ---
	GetWMProtocols :: proc(
		display:   ^Display,
		window:    Window,
		protocols: ^[^]Atom,
		count:     ^i32,
		) -> Status ---
	// Setting and reading the WM_COLORMAP_WINDOWS property
	SetWMColormapWindows :: proc(
		display:          ^Display,
		window:           Window,
		colormap_windows: [^]Window,
		count:            i32,
		) -> Status ---
	GetWMColormapWindows :: proc(
		display:          ^Display,
		window:           Window,
		colormap_windows: ^[^]Window,
		count:            ^i32,
		) -> Status ---
	// Setting and reading the WM_ICON_SIZE_PROPERTY
	AllocIconSize :: proc() -> ^XIconSize ---
	SetIconSizes :: proc(
		display:   ^Display,
		window:    Window,
		size_list: [^]XIconSize,
		count:     i32,
		) ---
	GetIconSizes :: proc(
		display:   ^Display,
		window:    Window,
		size_list: ^[^]XIconSize,
		count:     ^i32,
		) -> Status ---
	// Using window manager convenience functions
	mbSetWMProperties :: proc(
		display:      ^Display,
		window:       Window,
		window_name:  cstring,
		icon_name:    cstring,
		argv:         [^]cstring,
		argc:         i32,
		normal_hints: ^XSizeHints,
		wm_hints:     ^XWMHints,
		class_hints:  ^XClassHint,
		) ---
	SetWMProperties :: proc(
		display:      ^Display,
		window:       Window,
		window_name:  ^XTextProperty,
		argv:         [^]cstring,
		argc:         i32,
		normal_hints: ^XSizeHints,
		wm_hints:     ^XWMHints,
		class_hints:  ^XWMHints,
		) ---
	// Client to session manager communication
	SetCommand :: proc(
		display: ^Display,
		window:  Window,
		argv:    [^]cstring,
		argc:    i32,
		) ---
	GetCommand :: proc(
		display: ^Display,
		window:  Window,
		argv:    ^[^]cstring,
		argc:    ^i32,
		) -> Status ---
	SetWMClientMachine :: proc(
		display: ^Display,
		window:  Window,
		prop:    ^XTextProperty,
		) ---
	GetWMClientMachine :: proc(
		display: ^Display,
		window:  Window,
		prop:    ^XTextProperty,
		) -> Status ---
	SetRGBColormaps :: proc(
		display:  ^Display,
		window:   Window,
		colormap: ^XStandardColormap,
		prop:     Atom,
		) ---
	GetRGBColormaps :: proc(
		display:  ^Display,
		window:   Window,
		colormap: ^[^]XStandardColormap,
		count:    ^i32,
		prop:     Atom,
		) -> Status ---
	// Keyboard utility functions
	LookupKeysym :: proc(
		event: ^XKeyEvent,
		index: i32,
		) -> KeySym ---
	KeycodeToKeysym :: proc(
		display: ^Display,
		keycode: KeyCode,
		index: i32,
		) -> KeySym ---
	KeysymToKeycode :: proc(
		display: ^Display,
		keysym: KeySym,
		) -> KeyCode ---
	RefreshKeyboardMapping :: proc(event_map: ^XMappingEvent) ---
	ConvertCase :: proc(
		keysym: KeySym,
		lower:  ^KeySym,
		upper:  ^KeySym,
		) ---
	StringToKeysym :: proc(str: cstring) -> KeySym ---
	KeysymToString :: proc(keysym: KeySym) -> cstring ---
	LookupString :: proc(
		event: ^XKeyEvent,
		buffer: [^]u8,
		count: i32,
		keysym: ^KeySym,
		status: ^XComposeStatus,
		) -> i32 ---
	RebindKeysym :: proc(
		display: ^Display,
		keysym: KeySym,
		list: [^]KeySym,
		mod_count: i32,
		string: [^]u8,
		num_bytes: i32,
		) ---
	// Allocating permanent storage
	Permalloc :: proc(size: u32) -> rawptr ---
	// Parsing the window geometry
	ParseGeometry :: proc(
		parsestring: cstring,
		x_ret:       ^i32,
		y_ret:       ^i32,
		width:       ^u32,
		height:      ^u32,
		) -> i32 ---
	WMGeometry :: proc(
		display:   ^Display,
		screen_no: i32,
		user_geom: cstring,
		def_geom:  cstring,
		bwidth:    u32,
		hints:     ^XSizeHints,
		x_ret:     ^i32,
		y_ret:     ^i32,
		w_ret:     ^u32,
		h_ret:     ^u32,
		grav:      ^Gravity,
		) -> i32 ---
	// Creating, copying and destroying regions
	CreateRegion :: proc() -> Region ---
	PolygonRegion :: proc(
		points: [^]XPoint,
		n:      i32,
		fill:   FillRule,
		) -> Region ---
	SetRegion :: proc(
		display: ^Display,
		gc:      GC,
		region:  Region,
		) ---
	DestroyRegion :: proc(r: Region) ---
	// Moving or shrinking regions
	OffsetRegion :: proc(region: Region, dx, dy: i32) ---
	ShrinkRegion :: proc(region: Region, dx, dy: i32) ---
	// Computing with regions
	ClipBox :: proc(region: Region, rect: ^XRectangle) ---
	IntersectRegion :: proc(sra, srb, ret: Region) ---
	UnionRegion :: proc(sra, srb, ret: Region) ---
	UnionRectWithRegion :: proc(rect: ^XRectangle, src, dst: Region) ---
	SubtractRegion :: proc(sra, srb, ret: Region) ---
	XorRegion :: proc(sra, srb, ret: Region) ---
	EmptyRegion :: proc(reg: Region) -> b32 ---
	EqualRegion :: proc(a,b: Region) -> b32 ---
	PointInRegion :: proc(reg: Region, x,y: i32) -> b32 ---
	RectInRegion :: proc(reg: Region, x,y: i32, w,h: u32) -> b32 ---
	// Using cut buffers
	StoreBytes :: proc(display: ^Display, bytes: [^]u8, nbytes: i32) ---
	StoreBuffer :: proc(display: ^Display, bytes: [^]u8, nbytes: i32, buffer: i32) ---
	FetchBytes :: proc(display: ^Display, nbytes: ^i32) -> [^]u8 ---
	FetchBuffer :: proc(display: ^Display, nbytes: ^i32, buffer: i32) -> [^]u8 ---
	// Determining the appropriate visual types
	GetVisualInfo :: proc(
		display: ^Display,
		mask:    VisualInfoMask,
		info:    ^XVisualInfo,
		nret:    ^i32,
		) -> [^]XVisualInfo ---
	MatchVisualInfo :: proc(
		display:   ^Display,
		screen_no: i32,
		depth:     i32,
		class:     i32,
		ret:       ^XVisualInfo,
		) -> Status ---
	// Manipulating images
	CreateImage :: proc(
		display: ^Display,
		visual:  ^Visual,
		depth:   u32,
		format:  ImageFormat,
		offset:  i32,
		data:    rawptr,
		width:   u32,
		height:  u32,
		pad:     i32,
		stride:  i32,
		) -> ^XImage ---
	GetPixel :: proc(
		image: ^XImage,
		x:     i32,
		y:     i32,
		) -> uint ---
	PutPixel :: proc(
		image: ^XImage,
		x:     i32,
		y:     i32,
		pixel: uint,
		) ---
	SubImage :: proc(
		image: ^XImage,
		x: i32,
		y: i32,
		w: u32,
		h: u32,
		) -> ^XImage ---
	AddPixel :: proc(
		image: ^XImage,
		value: int,
		) ---
	StoreNamedColor :: proc(
		display:  ^Display,
		colormap: Colormap,
		name:     cstring,
		pixel:    uint,
		flags:    ColorFlags,
		) ---
	QueryColor :: proc(
		display:  ^Display,
		colormap: Colormap,
		color:    ^XColor,
		) ---
	QueryColors :: proc(
		display:  ^Display,
		colormap: Colormap,
		colors:   [^]XColor,
		ncolors:  i32,
		) ---
	QueryExtension :: proc(
		display:             ^Display,
		name:                cstring,
		major_opcode_return: ^i32,
		first_event_return:  ^i32,
		first_error_return:  ^i32,
		) -> b32 ---
	DestroyImage :: proc(image: ^XImage) ---
	ResourceManagerString :: proc(display: ^Display) -> cstring ---
	utf8SetWMProperties :: proc(
		display:      ^Display,
		window:       Window,
		window_name:  cstring,
		icon_name:    cstring,
		argv:         ^cstring,
		argc:         i32,
		normal_hints: ^XSizeHints,
		wm_hints:     ^XWMHints,
		class_hints:  ^XClassHint,
	) ---
	OpenIM :: proc(
		display: ^Display,
		rdb:      XrmHashBucket,
		res_name: cstring,
		res_class: cstring,
	) -> XIM ---
	SetLocaleModifiers :: proc(modifiers: cstring) -> cstring ---
}

@(default_calling_convention="c")
foreign xlib {
	XcmsLookupColor :: proc(
		display:  ^Display,
		colormap: Colormap,
		name:     cstring,
		exact:    XcmsColor,
		screen:   XcmsColor,
		format:   XcmsColorFormat,
		) -> Status ---
	XcmsStoreColor :: proc(
		display:  ^Display,
		colormap: Colormap,
		color:    ^XcmsColor,
		) -> Status ---
	XcmsStoreColors :: proc(
		display:  ^Display,
		colormap: Colormap,
		colors:   [^]XcmsColor,
		ncolors:  XcmsColor,
		cflags:   [^]b32,
		) -> Status ---
	XcmsQueryColor :: proc(
		display:  ^Display,
		colormap: Colormap,
		color:    ^XcmsColor,
		format:   XcmsColorFormat,
		) -> Status ---
	XcmsQueryColors :: proc(
		display:  ^Display,
		colormap: Colormap,
		color:    [^]XcmsColor,
		ncolors:  i32,
		format:   XcmsColorFormat,
		) -> Status ---
	// Getting and setting the color conversion context (CCC) of a colormap
	XcmsCCCOfColormap :: proc(
		display:  ^Display,
		colormap: Colormap,
		) -> XcmsCCC ---
	XcmsSetCCCOfColormap :: proc(
		display:  ^Display,
		colormap: Colormap,
		ccc:      XcmsCCC) -> XcmsCCC ---
	XcmsDefaultCCC :: proc(display:   ^Display, screen_no: i32) -> XcmsCCC ---
	// Color conversion context macros
	XcmsDisplayOfCCC :: proc(ccc: XcmsCCC) -> ^Display ---
	XcmsVisualOfCCC  :: proc(ccc: XcmsCCC) -> ^Visual ---
	XcmsScreenNumberOfCCC :: proc(ccc: XcmsCCC) -> i32 ---
	XcmsScreenWhitePointOfCCC :: proc(ccc: XcmsCCC) -> XcmsColor ---
	XcmsClientWhitePointOfCCC :: proc(ccc: XcmsCCC) -> XcmsColor ---
	// Modifying the attributes of color conversion context
	XcmsSetWhitePoint :: proc(
		ccc: XcmsCCC,
		color: ^XcmsColor,
		) -> Status ---
	XcmsSetCompressionProc :: proc(
		ccc: XcmsCCC,
		cproc: XcmsCompressionProc,
		data: rawptr,
		) -> XcmsCompressionProc ---
	XcmsSetWhiteAdjustProc :: proc(
		ccc: XcmsCCC,
		aproc: XcmsWhiteAdjustProc,
		data: rawptr,
		) -> XcmsWhiteAdjustProc ---
	// Creating and freeing the color conversion context
	XcmsCreateCCC :: proc(
		display: ^Display,
		screen_no: i32,
		visual: ^Visual,
		white_point: ^XcmsColor,
		cproc: XcmsCompressionProc,
		cdata: rawptr,
		aproc: XcmsWhiteAdjustProc,
		adata: rawptr,
		) -> XcmsCCC ---
	XcmsFreeCCC :: proc(ccc: XcmsCCC) ---
	// Converting between colorspaces
	XcmsConvertColors :: proc(
		ccc:     XcmsCCC,
		colors:  [^]XcmsColor,
		ncolors: u32,
		format:  XcmsColorFormat,
		cflags:  [^]b32,
		) -> Status ---
	// Pre-defined gamut compression callbacks
	XcmsCIELabClipL :: proc(
		ctx:     XcmsCCC,
		colors:  [^]XcmsColor,
		ncolors: u32,
		index:   u32,
		flags:   [^]b32,
		) -> Status ---
	XcmsCIELabClipab :: proc(
		ctx:     XcmsCCC,
		colors:  [^]XcmsColor,
		ncolors: u32,
		index:   u32,
		flags:   [^]b32,
		) -> Status ---
	XcmsCIELabClipLab :: proc(
		ctx:     XcmsCCC,
		colors:  [^]XcmsColor,
		ncolors: u32,
		index:   u32,
		flags:   [^]b32,
		) -> Status ---
	XcmsCIELuvClipL :: proc(
		ctx:     XcmsCCC,
		colors:  [^]XcmsColor,
		ncolors: u32,
		index:   u32,
		flags:   [^]b32,
		) -> Status ---
	XcmsCIELuvClipuv :: proc(
		ctx:     XcmsCCC,
		colors:  [^]XcmsColor,
		ncolors: u32,
		index:   u32,
		flags:   [^]b32,
		) -> Status ---
	XcmsCIELuvClipLuv :: proc(
		ctx:     XcmsCCC,
		colors:  [^]XcmsColor,
		ncolors: u32,
		index:   u32,
		flags:   [^]b32,
		) -> Status ---
	XcmsTekHVCClipV :: proc(
		ctx:     XcmsCCC,
		colors:  [^]XcmsColor,
		ncolors: u32,
		index:   u32,
		flags:   [^]b32,
		) -> Status ---
	XcmsTekHVCClipC :: proc(
		ctx:     XcmsCCC,
		colors:  [^]XcmsColor,
		ncolors: u32,
		index:   u32,
		flags:   [^]b32,
		) -> Status ---
	XcmsTekHVCClipVC :: proc(
		ctx:     XcmsCCC,
		colors:  [^]XcmsColor,
		ncolors: u32,
		index:   u32,
		flags:   [^]b32,
		) -> Status ---
	// Pre-defined white-point adjustment procedures
	XcmsCIELabWhiteShiftColors :: proc(
		ctx:                 XcmsCCC,
		initial_white_point: ^XcmsColor,
		target_white_point:  ^XcmsColor,
		target_format:       XcmsColorFormat,
		colors:              [^]XcmsColor,
		ncolors:             u32,
		compression:         [^]b32,
		) -> Status ---
	XcmsCIELuvWhiteShiftColors :: proc(
		ctx:                 XcmsCCC,
		initial_white_point: ^XcmsColor,
		target_white_point:  ^XcmsColor,
		target_format:       XcmsColorFormat,
		colors:              [^]XcmsColor,
		ncolors:             u32,
		compression:         [^]b32,
		) -> Status ---
	XcmsTekHVCWhiteShiftColors :: proc(
		ctx:                 XcmsCCC,
		initial_white_point: ^XcmsColor,
		target_white_point:  ^XcmsColor,
		target_format:       XcmsColorFormat,
		colors:              [^]XcmsColor,
		ncolors:             u32,
		compression:         [^]b32,
		) -> Status ---
	// Color querying
	XcmsQueryBlack :: proc(
		ccc:    XcmsCCC,
		format: XcmsColorFormat,
		color:  ^XcmsColor,
		) -> Status ---
	XcmsQueryBlue :: proc(
		ccc:    XcmsCCC,
		format: XcmsColorFormat,
		color:  ^XcmsColor,
		) -> Status ---
	XcmsQueryGreen :: proc(
		ccc:    XcmsCCC,
		format: XcmsColorFormat,
		color:  ^XcmsColor,
		) -> Status ---
	XcmsQueryRed :: proc(
		ccc:    XcmsCCC,
		format: XcmsColorFormat,
		color:  ^XcmsColor,
		) -> Status ---
	XcmsQueryWhite :: proc(
		ccc:    XcmsCCC,
		format: XcmsColorFormat,
		color:  ^XcmsColor,
		) -> Status ---
	// CIELab queries
	XcmsCIELabQueryMaxC :: proc(
		ccc:   XcmsCCC,
		hue:   XcmsFloat,
		lstar: XcmsFloat,
		color: ^XcmsColor,
		) -> Status ---
	XcmsCIELabQueryMaxL :: proc(
		ccc:    XcmsCCC,
		hue:    XcmsFloat,
		chroma: XcmsFloat,
		color:  ^XcmsColor,
		) -> Status ---
	XcmsCIELabQueryMaxLC :: proc(
		ccc:    XcmsCCC,
		hue:    XcmsFloat,
		color:  ^XcmsColor,
		) -> Status ---
	XcmsCIELabQueryMinL :: proc(
		ccc:    XcmsCCC,
		hue:    XcmsFloat,
		chroma: XcmsFloat,
		color:  ^XcmsColor,
		) -> Status ---
	// CIEluv queries
	XcmsCIELuvQueryMaxC :: proc(
		ccc:   XcmsCCC,
		hue:   XcmsFloat,
		lstar: XcmsFloat,
		color: ^XcmsColor,
		) -> Status ---
	XcmsCIELuvQueryMaxL :: proc(
		ccc:    XcmsCCC,
		hue:    XcmsFloat,
		chroma: XcmsFloat,
		color:  ^XcmsColor,
		) -> Status ---
	XcmsCIELuvQueryMaxLC :: proc(
		ccc:   XcmsCCC,
		hue:   XcmsFloat,
		color: ^XcmsColor,
		) -> Status ---
	XcmsCIELuvQueryMinL :: proc(
		ccc:    XcmsCCC,
		hue:    XcmsFloat,
		chroma: XcmsFloat,
		color:  ^XcmsColor,
		) -> Status ---
	// TexHVX queries
	XcmsTekHVCQueryMaxC :: proc(
		ccc:   XcmsCCC,
		hue:   XcmsFloat,
		value: XcmsFloat,
		color: ^XcmsColor,
		) -> Status ---
	XcmsTekHVCQueryMaxV :: proc(
		ccc:    XcmsCCC,
		hue:    XcmsFloat,
		chroma: XcmsFloat,
		color:  ^XcmsColor,
		) -> Status ---
	XcmsTekHVCQueryMaxVC :: proc(
		ccc:    XcmsCCC,
		hue:    XcmsFloat,
		color:  ^XcmsColor,
		) -> Status ---
	XcmsTekHVCQueryMaxVSamples :: proc(
		ccc:      XcmsCCC,
		hue:      XcmsFloat,
		colors:   [^]XcmsColor,
		nsamples: u32,
		) -> Status ---
	XcmsTekHVCQueryMinV :: proc(
		ccc:    XcmsCCC,
		hue:    XcmsFloat,
		chroma: XcmsFloat,
		color:  ^XcmsColor,
		) -> Status ---
	XcmsAllocNamedColor :: proc(
		display:  ^Display,
		colormap: Colormap,
		name:     cstring,
		screen:   ^XcmsColor,
		exact:    ^XcmsColor,
		format:   XcmsColorFormat,
		) -> Status ---
	XcmsAllocColor :: proc(
		display:  ^Display,
		colormap: Colormap,
		color:    ^XcmsColor,
		format:   XcmsColorFormat,
		) -> Status ---
	XrmInitialize :: proc() ---
	XrmGetStringDatabase :: proc(data: cstring) -> XrmDatabase ---
	XrmGetResource :: proc(db: XrmDatabase, name: cstring, class: cstring, type_return: ^cstring, val_return: ^XrmValue) -> b32 ---

	/* ----  X11/XKBlib.h ---------------------------------------------------------*/

	XkbQueryExtension :: proc(
		display: ^Display,
		opcode_return: ^i32,
		event_base_return: ^i32,
		error_base_return: ^i32,
		major_return: ^i32,
		minor_return: ^i32,
	) -> b32 ---
	XkbUseExtension :: proc(
		display: ^Display,
		major_return: ^i32,
		minor_return: ^i32,
	) -> b32 ---
	XkbGetMap :: proc(
		display: ^Display,
		which: XkbInfoMask,
		device_spec: i32,
	) -> XkbDescPtr ---
	XkbGetUpdatedMap :: proc(
		display: ^Display,
		which: XkbInfoMask,
		desc: XkbDescPtr,
	) -> b32 ---
	XkbSelectEvents :: proc(
		display: ^Display,
		deviceID: u32,
		bits_to_change: XkbEventMask,
		values: XkbEventMask,
	) -> b32 ---
	XkbSetDetectableAutoRepeat :: proc(
		display: ^Display,
		detectable: b32,
		supported: ^b32,
	) -> b32 ---
	XkbGetState :: proc (
		display: ^Display,
		device_spec: u32,
		return_state: XkbStatePtr,
	) -> Status ---
	XkbGetKeySyms :: proc(
		display: ^Display,
		first: u32,
		num: u32,
		xkb: XkbDescPtr,
	) -> Status ---
}
