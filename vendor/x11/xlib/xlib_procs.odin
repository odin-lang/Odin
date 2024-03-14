//+build linux, openbsd, freebsd
package xlib

foreign import xlib "system:X11"
foreign xlib {
	@(link_name="_Xdebug") _Xdebug: i32
}

/* ----  X11/Xlib.h ---------------------------------------------------------*/

@(default_calling_convention="c")
foreign xlib {
	// Free data allocated by Xlib
	XFree              :: proc(ptr: rawptr) ---
	// Opening/closing a display
	XOpenDisplay       :: proc(name: cstring) -> ^Display ---
	XCloseDisplay      :: proc(display: ^Display) ---
	XSetCloseDownMode  :: proc(display: ^Display, mode: CloseMode) ---
	// Generate a no-op request
	XNoOp              :: proc(display: ^Display) ---
	// Display macros (connection)
	XConnectionNumber  :: proc(display: ^Display) -> i32 ---
	XExtendedMaxRequestSize ::
	                      proc(display: ^Display) -> int ---
	XMaxRequestSize    :: proc(display: ^Display) -> int ---
	XLastKnownRequestProcessed ::
	                      proc(display: ^Display) -> uint ---
	XNextRequest       :: proc(display: ^Display) -> uint ---
	XProtocolVersion   :: proc(display: ^Display) -> i32 ---
	XProtocolRevision  :: proc(display: ^Display) -> i32 ---
	XQLength           :: proc(display: ^Display) -> i32 ---
	XServerVendor      :: proc(display: ^Display) -> cstring ---
	XVendorRelease     :: proc(display: ^Display) -> i32 ---
	// Display macros (display properties)
	XBlackPixel        :: proc(display: ^Display, screen_no: i32) -> uint ---
	XWhitePixel        :: proc(display: ^Display, screen_no: i32) -> uint ---
	XListDepths        :: proc(display: ^Display, screen_no: i32, count: ^i32) -> [^]i32 ---
	XDisplayCells      :: proc(display: ^Display, screen_no: i32) -> i32 ---
	XDisplayPlanes     :: proc(display: ^Display, screen_no: i32) -> i32 ---
	XScreenOfDisplay   :: proc(display: ^Display, screen_no: i32) -> ^Screen ---
	XDisplayString     :: proc(display: ^Display) -> cstring ---
	// Display macros (defaults)
	XDefaultColormap   :: proc(display: ^Display, screen_no: i32) -> Colormap ---
	XDefaultDepth      :: proc(display: ^Display) -> i32 ---
	XDefaultGC         :: proc(display: ^Display, screen_no: i32) -> GC ---
	XDefaultRootWindow :: proc(display: ^Display) -> Window ---
	XDefaultScreen     :: proc(display: ^Display) -> i32 ---
	XDefaultVisual     :: proc(display: ^Display, screen_no: i32) -> ^Visual ---
	XDefaultScreenOfDisplay ::
	                      proc(display: ^Display) -> ^Screen ---
	// Display macros (other)
	XRootWindow        :: proc(display: ^Display, screen_no: i32) -> Window ---
	XScreenCount       :: proc(display: ^Display) -> i32 ---
	// Display image format macros
	XListPixmapFormats :: proc(display: ^Display, count: ^i32) -> [^]XPixmapFormatValues ---
	XImageByteOrder    :: proc(display: ^Display) -> ByteOrder ---
	XBitmapUnit        :: proc(display: ^Display) -> i32 ---
	XBitmapBitOrder    :: proc(display: ^Display) -> ByteOrder ---
	XBitmapPad         :: proc(display: ^Display) -> i32 ---
	XDisplayHeight     :: proc(display: ^Display, screen_no: i32) -> i32 ---
	XDisplayHeightMM   :: proc(display: ^Display, screen_no: i32) -> i32 ---
	XDisplayWidth      :: proc(display: ^Display, screen_no: i32) -> i32 ---
	XDisplayWidthMM    :: proc(display: ^Display, screen_no: i32) -> i32 ---
	// Screen macros
	XBlackPixelsOfScreen :: proc(screen: ^Screen) -> uint ---
	XWhitePixelsOfScreen :: proc(screen: ^Screen) -> uint ---
	XCellsOfScreen       :: proc(screen: ^Screen) -> i32 ---
	XDefaultColormapOfScreen :: proc(screen: ^Screen) -> Colormap ---
	XDefaultDepthOfScreen    :: proc(screen: ^Screen) -> i32 ---
	XDefaultGCOfScreen       :: proc(screen: ^Screen) -> GC ---
	XDefaultVisualOfScreen   :: proc(screen: ^Screen) -> ^Visual ---
	XDoesBackingStore    :: proc(screen: ^Screen) -> BackingStore ---
	XDoesSaveUnders      :: proc(screen: ^Screen) -> b32 ---
	XDisplayOfScreen     :: proc(screen: ^Screen) -> ^Display ---
	XScreenNumberOfScreens :: proc(screen: ^Screen) -> i32 ---
	XEventMaskOfScreen   :: proc(screen: ^Screen) -> EventMask ---
	XWidthOfScreen       :: proc(screen: ^Screen) -> i32 ---
	XHeightOfScreen      :: proc(screen: ^Screen) -> i32 ---
	XWidthMMOfScreen     :: proc(screen: ^Screen) -> i32 ---
	XHeightMMOfScreen    :: proc(screen: ^Screen) -> i32 ---
	XMaxCmapsOfScreen    :: proc(screen: ^Screen) -> i32 ---
	XMinCmapsOfScreen    :: proc(screen: ^Screen) -> i32 ---
	XPlanesOfScreen      :: proc(screen: ^Screen) -> i32 ---
	XRootWindowOfScreen  :: proc(screen: ^Screen) -> Window ---
	// Threading functions
	XInitThreads         :: proc() -> Status ---
	XLockDisplay         :: proc(display: ^Display) ---
	XUnlockDisplay       :: proc(display: ^Display) ---
	// Internal connections
	XAddConnectionWatch  :: proc(
		display:   ^Display,
		procedure: XConnectionWatchProc,
		data:      rawptr,
		) -> Status ---
	XRemoveConnectionWatch :: proc(
		display:   ^Display,
		procedure: XConnectionWatchProc,
		data:      rawptr,
		) -> Status ---
	XProcessInternalConnections :: proc(
		display:   ^Display,
		fd:        i32,
		) ---
	XInternalConnectionNumbers :: proc(
		display:   ^Display,
		fds:       ^[^]i32,
		count:     ^i32,
		) -> Status ---
	// Windows functions
	XVisualIDFromVisual :: proc(visual: ^Visual) -> VisualID ---
	// Windows: creation/destruction
	XCreateWindow :: proc(
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
	XCreateSimpleWindow :: proc(
		display:   ^Display,
		parent:    Window,
		x:         i32,
		y:         i32,
		width:     u32,
		height:    u32,
		bordersz:  u32,
		border:    int,
		bg:        int,
		) -> Window ---
	XDestroyWindow     :: proc(display: ^Display, window: Window) ---
	XDestroySubwindows :: proc(display: ^Display, window: Window) ---
	// Windows: mapping/unmapping
	XMapWindow         :: proc(display: ^Display, window: Window) ---
	XMapRaised         :: proc(display: ^Display, window: Window) ---
	XMapSubwindows     :: proc(display: ^Display, window: Window) ---
	XUnmapWindow       :: proc(display: ^Display, window: Window) ---
	XUnmapSubwindows   :: proc(display: ^Display, window: Window) ---
	// Windows: configuring
	XConfigureWindow :: proc(
		display: ^Display,
		window:  Window,
		mask:    WindowChangesMask,
		values:  XWindowChanges,
		) ---
	XMoveWindow :: proc(
		display: ^Display,
		window:  Window,
		x:       i32,
		y:       i32,
		) ---
	XResizeWindow :: proc(
		display: ^Display,
		window:  Window,
		width:   u32,
		height:  u32,
		) ---
	XMoveResizeWindow :: proc(
		display: ^Display,
		window:  Window,
		x:       i32,
		y:       i32,
		width:   u32,
		height:  u32,
		) ---
	XSetWindowBorderWidth :: proc(
		display: ^Display,
		window:  Window,
		width:   u32,
		) ---
	// Window: changing stacking order
	XRaiseWindow :: proc(display: ^Display, window: Window) ---
	XLowerWindow :: proc(display: ^Display, window: Window) ---
	XCirculateSubwindows :: proc(display: ^Display, window: Window, direction: CirculationDirection) ---
	XCirculateSubwindowsUp :: proc(display: ^Display, window: Window) ---
	XCirculateSubwindowsDown :: proc(display: ^Display, window: Window) ---
	XRestackWindows :: proc(display: ^Display, windows: [^]Window, nwindows: i32) ---
	// Window: changing attributes
	XChangeWindowAttributes :: proc(
		display:   ^Display,
		window:    Window,
		attr_mask: WindowAttributeMask,
		attr:      XWindowAttributes,
		) ---
	XSetWindowBackground :: proc(
		display:   ^Display,
		window:    Window,
		pixel:     uint,
		) ---
	XSetWindowBackgroundMap :: proc(
		display:   ^Display,
		window:    Window,
		pixmap:    Pixmap,
		) ---
	XSetWindowColormap :: proc(
		display:   ^Display,
		window:    Window,
		colormap:  Colormap,
		) ---
	XDefineCursor :: proc(
		display:   ^Display,
		window:    Window,
		cursor:    Cursor,
		) ---
	XUndefineCursor :: proc(
		display:   ^Display,
		window:    Window,
		) ---
	// Windows: querying information
	XQueryTree :: proc(
		display:   ^Display,
		window:    Window,
		root:      ^Window,
		parent:    ^Window,
		children:  ^[^]Window,
		nchildren: ^u32,
		) -> Status ---
	XGetWindowAttributes :: proc(
		display: ^Display,
		window:  Window,
		attr:    ^XWindowAttributes,
		) ---
	XGetGeometry :: proc(
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
	XTranslateCoordinates :: proc(
		display: ^Display,
		src_window: Window,
		dst_window: Window,
		src_x:      i32,
		src_y:      i32,
		dst_x:      ^i32,
		dst_y:      ^i32,
		) -> b32 ---
	XQueryPointer :: proc(
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
	XInternAtom :: proc(
		display:  ^Display,
		name:     cstring,
		existing: b32,
		) -> Atom ---
	XInternAtoms :: proc(
		display: ^Display,
		names:   [^]cstring,
		count:   i32,
		atoms:   [^]Atom,
		) -> Status ---
	XGetAtomName :: proc(
		display: ^Display,
		atom:    Atom,
		) -> cstring ---
	XGetAtomNames :: proc(
		display: ^Display,
		atoms:   [^]Atom,
		count:   i32,
		names:   [^]cstring,
		) -> Status ---
	// Windows: Obtaining and changing properties
	XGetWindowProperty :: proc(
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
	XListProperties :: proc(
		display:     ^Display,
		window:      Window,
		num:         ^i32,
		) -> [^]Atom ---
	XChangeProperty :: proc(
		display:     ^Display,
		window:      Window,
		property:    Atom,
		type:        Atom,
		format:      i32,
		mode:        i32,
		data:        rawptr,
		count:       i32,
		) ---
	XRotateWindowProperties :: proc(
		display:     ^Display,
		window:      Window,
		props:       [^]Atom,
		nprops:      i32,
		npos:        i32,
		) ---
	XDeleteProperty :: proc(
		display:     ^Display,
		window:      Window,
		prop:        Atom,
		) ---
	// Selections
	XSetSelectionOwner :: proc(
		display:     ^Display,
		selection:   Atom,
		owber:       Window,
		time:        Time,
		) ---
	XGetSelectionOwner :: proc(
		display:     ^Display,
		selection:   Atom,
		) -> Window ---
	XConvertSelection :: proc(
		display:     ^Display,
		selection:   Atom,
		target:      Atom,
		property:    Atom,
		requestor:   Window,
		time:        Time,
		) ---
	// Creating and freeing pixmaps
	XCreatePixmap :: proc(
		display:   ^Display,
		drawable:  Drawable,
		width:     u32,
		height:    u32,
		depth:     u32,
		) -> Pixmap ---
	XFreePixmap :: proc(
		display:   ^Display,
		pixmap:    Pixmap,
		) ---
	// Creating recoloring and freeing cursors
	XCreateFontCursor :: proc(
		display:   ^Display,
		shape:     CursorShape,
		) -> Cursor ---
	XCreateGlyphCursor :: proc(
		display:   ^Display,
		src_font:  Font,
		mask_font: Font,
		src_char:  u32,
		mask_char: u32,
		fg:        ^XColor,
		bg:        ^XColor,
		) -> Cursor ---
	XCreatePixmapCursor :: proc(
		display:   ^Display,
		source:    Pixmap,
		mask:      Pixmap,
		fg:        XColor,
		bg:        ^XColor,
		x:         u32,
		y:         u32,
		) -> Cursor ---
	XQueryBestCursor :: proc(
		display:    ^Display,
		drawable:   Drawable,
		width:      u32,
		height:     u32,
		out_width:  ^u32,
		out_height: ^u32,
		) -> Status ---
	XRecolorCursor :: proc(
		display:    ^Display,
		cursor:     Cursor,
		fg:         ^XColor,
		bg:         ^XColor,
		) ---
	XFreeCursor :: proc(display: ^Display, cursor: Cursor) ---
	// Creation/destruction of colormaps
	XCreateColormap :: proc(
		display:  ^Display,
		window:   Window,
		visual:   ^Visual,
		alloc:    ColormapAlloc,
		) -> Colormap ---
	XCopyColormapAndFree :: proc(
		display:  ^Display,
		colormap: Colormap,
		) -> Colormap ---
	XFreeColormap :: proc(
		display:  ^Display,
		colormap: Colormap,
		) ---
	// Mapping color names to values
	XLookupColor :: proc(
		display:  ^Display,
		colomap:  Colormap,
		name:     cstring,
		exact:    ^XColor,
		screen:   ^XColor,
		) -> Status ---
	XcmsLookupColor :: proc(
		display:  ^Display,
		colormap: Colormap,
		name:     cstring,
		exact:    XcmsColor,
		screen:   XcmsColor,
		format:   XcmsColorFormat,
		) -> Status ---
	// Allocating and freeing color cells
	XAllocColor :: proc(
		display:  ^Display,
		colormap: Colormap,
		screen:   ^XColor,
		) -> Status ---
	XcmsAllocColor :: proc(
		display:  ^Display,
		colormap: Colormap,
		color:    ^XcmsColor,
		format:   XcmsColorFormat,
		) -> Status ---
	XAllocNamedColor :: proc(
		display:  ^Display,
		colormap: Colormap,
		name:     cstring,
		screen:   ^XColor,
		exact:    ^XColor,
		) -> Status ---
	XcmsAllocNamedColor :: proc(
		display:  ^Display,
		colormap: Colormap,
		name:     cstring,
		screen:   ^XcmsColor,
		exact:    ^XcmsColor,
		format:   XcmsColorFormat,
		) -> Status ---
	XAllocColorCells :: proc(
		display:  ^Display,
		colormap: Colormap,
		contig:   b32,
		pmasks:   [^]uint,
		np:       u32,
		pixels:   [^]uint,
		npixels:  u32,
		) -> Status ---
	XAllocColorPlanes :: proc(
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
	XFreeColors :: proc(
		display:  ^Display,
		colormap: Colormap,
		pixels:   [^]uint,
		npixels:  i32,
		planes:   uint,
		) ---
	// Modifying and querying colormap cells
	XStoreColor :: proc(
		display:  ^Display,
		colormap: Colormap,
		color:    ^XColor,
		) ---
	XStoreColors :: proc(
		display:  ^Display,
		colormap: Colormap,
		color:    [^]XColor,
		ncolors:  i32,
		) ---
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
	XStoreNamedColor :: proc(
		display:  ^Display,
		colormap: Colormap,
		name:     cstring,
		pixel:    uint,
		flags:    ColorFlags,
		) ---
	XQueryColor :: proc(
		display:  ^Display,
		colormap: Colormap,
		color:    ^XColor,
		) ---
	XQueryColors :: proc(
		display:  ^Display,
		colormap: Colormap,
		colors:   [^]XColor,
		ncolors:  i32,
		) ---
	XQueryExtension :: proc(
		display:             ^Display,
		name:                cstring,
		major_opcode_return: ^i32,
		first_event_return:  ^i32,
		first_error_return:  ^i32,
		) -> b32 ---
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
	XcmsScreenNumberOfCCC ::
						proc(ccc: XcmsCCC) -> i32 ---
	XcmsScreenWhitePointOfCCC ::
						proc(ccc: XcmsCCC) -> XcmsColor ---
	XcmsClientWhitePointOfCCC ::
						proc(ccc: XcmsCCC) -> XcmsColor ---
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
	// Graphics context functions
	XCreateGC :: proc(
		display:  ^Display,
		drawable: Drawable,
		mask:     GCAttributeMask,
		attr:     ^XGCValues,
		) -> GC ---
	XCopyGC :: proc(
		display:  ^Display,
		src:      GC,
		dst:      GC,
		mask:     GCAttributeMask,
		) ---
	XChangeGC :: proc(
		display:  ^Display,
		gc:       GC,
		mask:     GCAttributeMask,
		values:   ^XGCValues,
		) ---
	XGetGCValues :: proc(
		display:  ^Display,
		gc:       GC,
		mask:     GCAttributeMask,
		values:   ^XGCValues,
		) -> Status ---
	XFreeGC :: proc(display: ^Display, gc: GC) ---
	XGCContextFromGC :: proc(gc: GC) -> GContext ---
	XFlushGC :: proc(display: ^Display, gc: GC) ---
	// Convenience routines for GC
	XSetState :: proc(
		display: ^Display,
		gc:      GC,
		fg:      uint,
		bg:      uint,
		fn:      GCFunction,
		pmask:   uint,
		) ---
	XSetForeground :: proc(
		display: ^Display,
		gc:      GC,
		fg:      uint,
		) ---
	XSetBackground :: proc(
		display: ^Display,
		gc:      GC,
		bg:      uint,
		) ---
	XSetFunction :: proc(
		display: ^Display,
		gc:      GC,
		fn:      GCFunction,
		) ---
	XSetPlaneMask :: proc(
		display: ^Display,
		gc:      GC,
		pmask:   uint,
		) ---
	XSetLineAttributes :: proc(
		display:    ^Display,
		gc:         GC,
		width:      u32,
		line_style: LineStyle,
		cap_style:  CapStyle,
		join_style: JoinStyle,
		) ---
	XSetDashes :: proc(
		display:   ^Display,
		gc:        GC,
		dash_offs: i32,
		dash_list: [^]i8,
		n:         i32,
		) ---
	XSetFillStyle :: proc(
		display: ^Display,
		gc:      GC,
		style:   FillStyle,
		) ---
	XSetFillRule :: proc(
		display: ^Display,
		gc:      GC,
		rule:    FillRule,
		) ---
	XQueryBestSize :: proc(
		display:    ^Display,
		class:      i32,
		which:      Drawable,
		width:      u32,
		height:     u32,
		out_width:  ^u32,
		out_height: ^u32,
		) -> Status ---
	XQueryBestTile :: proc(
		display:    ^Display,
		which:      Drawable,
		width:      u32,
		height:     u32,
		out_width:  ^u32,
		out_height: ^u32,
		) -> Status ---
	XQueryBestStripple :: proc(
		display:    ^Display,
		which:      Drawable,
		width:      u32,
		height:     u32,
		out_width:  u32,
		out_height: u32,
		) -> Status ---
	XSetTile       :: proc(display: ^Display, gc: GC, tile: Pixmap) ---
	XSetStripple   :: proc(display: ^Display, gc: GC, stripple: Pixmap) ---
	XSetTSOrigin   :: proc(display: ^Display, gc: GC, x: i32, y: i32) ---
	XSetFont       :: proc(display: ^Display, gc: GC, font: Font) ---
	XSetClipOrigin :: proc(display: ^Display, gc: GC, x: i32, y: i32) ---
	XSetClipMask   :: proc(display: ^Display, gc: GC, pixmap: Pixmap) ---
	XSetClipRectangles :: proc(
		display:  ^Display,
		gc:       GC,
		x:        i32,
		y:        i32,
		rects:    [^]XRectangle,
		n:        i32,
		ordering: i32,
		) ---
	XSetArcMode           :: proc(display: ^Display, gc: GC, mode: ArcMode) ---
	XSetSubwindowMode     :: proc(display: ^Display, gc: GC, mode: SubwindowMode) ---
	XSetGraphicsExposures :: proc(display: ^Display, gc: GC, exp: b32) ---
	// Graphics functions
	XClearArea :: proc(
		display: ^Display, 
		window:  Window, 
		x:       i32, 
		y:       i32, 
		width:   u32, 
		height:  u32, 
		exp:     b32,
		) ---
	XClearWindow :: proc(
		display: ^Display,
		window: Window,
		) ---
	XCopyArea :: proc(
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
	XCopyPlane :: proc(
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
	XDrawPoint :: proc(
		display:  ^Display,
		drawable: Drawable,
		gc:       GC,
		x:        i32,
		y:        i32,
		) ---
	XDrawPoints :: proc(
		display:  Display,
		drawable: Drawable,
		gc:       GC,
		point:    [^]XPoint,
		npoints:  i32,
		mode:     CoordMode,
		) ---
	XDrawLine :: proc(
		display:  ^Display,
		drawable: Drawable,
		gc:       GC,
		x1:       i32,
		y1:       i32,
		x2:       i32,
		y2:       i32,
		) ---
	XDrawLines :: proc(
		display:  ^Display,
		drawable: Drawable,
		gc:       GC,
		points:   [^]XPoint,
		npoints:  i32,
		) ---
	XDrawSegments :: proc(
		display:  ^Display,
		drawable: Drawable,
		gc:       GC,
		segs:     [^]XSegment,
		nsegs:    i32,
		) ---
	XDrawRectangle :: proc(
		display:  ^Display,
		drawable: Drawable,
		gc:       GC,
		x:        i32,
		y:        i32,
		width:    u32,
		height:   u32,
		) ---
	XDrawRectangles :: proc(
		display:  ^Display,
		drawable: Drawable,
		gc:       GC,
		rects:    [^]XRectangle,
		nrects:   i32,
		) ---
	XDrawArc :: proc(
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
	XDrawArcs :: proc(
		display:  ^Display,
		drawable: Drawable,
		gc:       GC,
		arcs:     [^]XArc,
		narcs:    i32,
		) ---
	// Filling areas
	XFillRectangle :: proc(
		display:  ^Display,
		drawable: Drawable,
		gc:       GC,
		x:        i32,
		y:        i32,
		width:    u32,
		height:   u32,
		) ---
	XFillRectangles :: proc(
		display:  ^Display,
		drawable: Drawable,
		gc:       GC,
		rects:    [^]XRectangle,
		nrects:   i32,
		) ---
	XFillPolygon :: proc(
		display:  ^Display,
		drawable: Drawable,
		gc:       GC,
		points:   [^]XPoint,
		npoints:  i32,
		shape:    Shape,
		mode:     CoordMode,
		) ---
	XFillArc :: proc(
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
	XFillArcs :: proc(
		display:  ^Display,
		drawable: Drawable,
		gc:       GC,
		arcs:     [^]XArc,
		narcs:    i32,
		) ---
	// Font metrics
	XLoadFont        :: proc(display: ^Display, name: cstring) -> Font ---
	XQueryFont       :: proc(display: ^Display, id: XID) -> ^XFontStruct ---
	XLoadQueryFont   :: proc(display: ^Display, name: cstring) -> ^XFontStruct ---
	XFreeFont        :: proc(display: ^Display, font_struct: ^XFontStruct) ---
	XGetFontProperty :: proc(font_struct: ^XFontStruct, atom: Atom, ret: ^uint) -> b32 ---
	XUnloadFont      :: proc(display: ^Display, font: Font) ---
	XListFonts       :: proc(display: ^Display, pat: cstring, max: i32, count: ^i32) -> [^]cstring ---
	XFreeFontNames   :: proc(display: ^Display, list: [^]cstring) ---
	XListFontsWithInfo :: proc(
		display: ^Display,
		pat:     cstring,
		max:     i32,
		count:   ^i32,
		info:    ^[^]XFontStruct,
		) -> [^]cstring ---
	XFreeFontInfo :: proc(names: [^]cstring, info: [^]XFontStruct, count: i32) ---
	// Computing character string sizes
	XTextWidth :: proc(font_struct: ^XFontStruct, string: [^]u8, count: i32) -> i32 ---
	XTextWidth16 :: proc(font_struct: ^XFontStruct, string: [^]XChar2b, count: i32) -> i32 ---
	XTextExtents :: proc(
		font_struct: ^XFontStruct,
		string:      [^]u8,
		nchars:      i32,
		direction:   ^FontDirection,
		ascent:      ^i32,
		descent:     ^i32,
		ret:         ^XCharStruct,
		) ---
	XTextExtents16 :: proc(
		font_struct: ^XFontStruct,
		string:      [^]XChar2b,
		nchars:      i32,
		direction:   ^FontDirection,
		ascent:      ^i32,
		descent:     ^i32,
		ret:         ^XCharStruct,
		) ---
	XQueryTextExtents :: proc(
		display:     ^Display,
		font_id:     XID,
		string:      [^]u8,
		nchars:      i32,
		direction:   ^FontDirection,
		ascent:      ^i32,
		descent:     ^i32,
		ret:         ^XCharStruct,
		) ---
	XQueryTextExtents16 :: proc(
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
	XDrawText :: proc(
		display:  ^Display,
		drawable: Drawable,
		gc:       GC,
		x:        i32,
		y:        i32,
		items:    XTextItem,
		nitems:   i32,
		) ---
	XDrawText16 :: proc(
		display:  ^Display,
		drawable: Drawable,
		gc:       GC,
		x:        i32,
		y:        i32,
		items:    XTextItem16,
		nitems:   i32,
		) ---
	// Drawing text characters
	XDrawString :: proc(
		display:  ^Display,
		drawable: Drawable,
		gc:       GC,
		x:        i32,
		y:        i32,
		string:   [^]u8,
		length:   i32,
		) ---
	XDrawString16 :: proc(
		display:  ^Display,
		drawable: Drawable,
		gc:       GC,
		x:        i32,
		y:        i32,
		string:   [^]XChar2b,
		length:   i32,
		) ---
	XDrawImageString :: proc(
		display:  ^Display,
		drawable: Drawable,
		gc:       GC,
		x:        i32,
		y:        i32,
		string:   [^]u8,
		length:   i32,
		) ---
	XDrawImageString16 :: proc(
		display:  ^Display,
		drawable: Drawable,
		gc:       GC,
		x:        i32,
		y:        i32,
		string:   [^]XChar2b,
		length:   i32,
		) ---
	// Transferring images between client and server
	XInitImage :: proc(image: ^XImage) -> Status ---
	XPutImage :: proc(
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
	XGetImage :: proc(
		display:  ^Display,
		drawable: Drawable,
		x:        i32,
		y:        i32,
		width:    u32,
		height:   u32,
		mask:     uint,
		format:   ImageFormat,
		) -> ^XImage ---
	XGetSubImage :: proc(
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
	XReparentWindow :: proc(
		display: ^Display,
		window:  Window,
		parent:  Window,
		x:       i32,
		y:       i32,
		) ---
	XChangeSaveSet :: proc(
		display: ^Display,
		window:  Window,
		mode:    SaveSetChangeMode,
		) ---
	XAddToSaveSet :: proc(
		display: ^Display,
		window:  Window,
		) ---
	XRemoveFromSaveSet :: proc(
		display: ^Display,
		window:  Window,
		) ---
	// Managing installed colormaps
	XInstallColormap        :: proc(display: ^Display, colormap: Colormap) ---
	XUninstallColormap      :: proc(display: ^Display, colormap: Colormap) ---
	XListInstalledColormaps :: proc(display: ^Display, window: Window, n: ^i32) -> [^]Colormap ---
	// Setting and retrieving font search paths
	XSetFontPath            :: proc(display: ^Display, dirs: [^]cstring, ndirs: i32) ---
	XGetFontPath            :: proc(display: ^Display, npaths: ^i32) -> [^]cstring ---
	XFreeFontPath           :: proc(list: [^]cstring) ---
	// Grabbing the server
	XGrabServer             :: proc(display: ^Display) ---
	XUngrabServer           :: proc(display: ^Display) ---
	// Killing clients
	XKillClient             :: proc(display: ^Display, resource: XID) ---
	// Controlling the screen saver
	XSetScreenSaver :: proc(
		display:   ^Display,
		timeout:   i32,
		interval:  i32,
		blanking:  ScreenSaverBlanking,
		exposures: ScreenSavingExposures,
		) ---
	XForceScreenSaver    :: proc(display: ^Display, mode: ScreenSaverForceMode) ---
	XActivateScreenSaver :: proc(display: ^Display) ---
	XResetScreenSaver    :: proc(display: ^Display) ---
	XGetScreenSaver :: proc(
		display: ^Display,
		timeout: ^i32,
		interval: ^i32,
		blanking: ^ScreenSaverBlanking,
		exposures: ^ScreenSavingExposures,
		) ---
	// Controlling host address
	XAddHost     :: proc(display: ^Display, addr: ^XHostAddress) ---
	XAddHosts    :: proc(display: ^Display, hosts: [^]XHostAddress, nhosts: i32) ---
	XListHosts   :: proc(display: ^Display, nhosts: ^i32, state: [^]b32) -> [^]XHostAddress ---
	XRemoveHost  :: proc(display: ^Display, host: XHostAddress) ---
	XRemoveHosts :: proc(display: ^Display, hosts: [^]XHostAddress, nhosts: i32) ---
	// Access control list
	XSetAccessControl     :: proc(display: ^Display, mode: AccessControlMode) ---
	XEnableAccessControl  :: proc(display: ^Display) ---
	XDisableAccessControl :: proc(display: ^Display) ---
	// Events
	XSelectInput   :: proc(display: ^Display, window: Window, mask: EventMask) ---
	XFlush         :: proc(display: ^Display) ---
	XSync          :: proc(display: ^Display) ---
	XEventsQueued  :: proc(display: ^Display, mode: EventQueueMode) -> i32 ---
	XPending       :: proc(display: ^Display) -> i32 ---
	XNextEvent     :: proc(display: ^Display, event: ^XEvent) ---
	XPeekEvent     :: proc(display: ^Display, event: ^XEvent) ---
	XGetEventData  :: proc(display: ^Display, cookie: ^XGenericEventCookie) -> b32 ---
	XFreeEventData :: proc(display: ^Display, cookie: ^XGenericEventCookie) ---
	// Selecting events using a predicate procedure
	XIfEvent :: proc(
		display:   ^Display,
		event:     ^XEvent,
		predicate: #type proc "c" (display: ^Display, event: ^XEvent, ctx: rawptr) -> b32,
		ctx:       rawptr,
		) ---
	XCheckIfEvent :: proc(
		display:   ^Display,
		event:     ^XEvent,
		predicate: #type proc "c" (display: ^Display, event: ^XEvent, ctx: rawptr) -> b32,
		arg:       rawptr,
		) -> b32 ---
	XPeekIfEvent :: proc(
		display:   ^Display,
		event:     ^XEvent,
		predicate: #type proc "c" (display: ^Display, event: ^XEvent, ctx: rawptr) -> b32,
		ctx:       rawptr,
		) ---
	// Selecting events using a window or event mask
	XWindowEvent :: proc(
		display:   ^Display,
		window:    Window,
		mask:      EventMask,
		event:     ^XEvent,
		) ---
	XCheckWindowEvent :: proc(
		display:   ^Display,
		window:    Window,
		mask:      EventMask,
		event:     ^XEvent,
		) -> b32 ---
	XMaskEvent :: proc(
		display: ^Display,
		mask:    EventMask,
		event:   ^XEvent,
		) ---
	XCheckMaskEvent :: proc(
		display: ^Display,
		mask:    EventMask,
		event:   ^XEvent,
		) -> b32 ---
	XCheckTypedEvent :: proc(
		display: ^Display,
		type:    EventType,
		event:   ^XEvent,
		) -> b32 ---
	XCheckTypedWindowEvent :: proc(
		display: ^Display,
		window:  Window,
		type:    EventType,
		event:   ^XEvent,
		) -> b32 ---
	// Putting events back
	XPutBackEvent :: proc(
		display: ^Display,
		event:   ^XEvent,
		) ---
	// Sending events to other applications
	XSendEvent :: proc(
		display:   ^Display,
		window:    Window,
		propagate: b32,
		mask:      EventMask,
		event:     ^XEvent,
		) -> Status ---
	// Getting the history of pointer motion
	XDisplayMotionBufferSize :: proc(display: ^Display) -> uint ---
	XGetMotionEvents :: proc(
		display: ^Display,
		window: Window,
		start: Time,
		stop: Time,
		nevents: ^i32,
		) -> [^]XTimeCoord ---
	// Enabling or disabling synchronization
	XSetAfterFunction :: proc(
		display:   ^Display,
		procedure: #type proc "c" (display: ^Display) -> i32,
		) -> i32 ---
	XSynchronize :: proc(
		display: ^Display,
		onoff: b32,
		) -> i32 ---
	// Error handling
	XSetErrorHandler :: proc(
		handler: #type proc "c" (display: ^Display, event: ^XErrorEvent) -> i32,
		) -> i32 ---
	XGetErrorText :: proc(
		display: ^Display,
		code: i32,
		buffer: [^]u8,
		size: i32,
		) ---
	XGetErrorDatabaseText :: proc(
		display: ^Display,
		name: cstring,
		message: cstring,
		default_string: cstring,
		buffer: [^]u8,
		size: i32,
		) ---
	XDisplayName :: proc(string: cstring) -> cstring ---
	XSetIOErrorHandler :: proc(
		handler: #type proc "c" (display: ^Display) -> i32,
		) -> i32 ---
	// Pointer grabbing
	XGrabPointer :: proc(
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
	XUngrabPointer :: proc(
		display:       ^Display,
		time:          Time,
		) -> i32 ---
	XChangeActivePointerGrab :: proc(
		display:       ^Display,
		event_mask:    EventMask,
		cursor:        Cursor,
		time:          Time,
		) ---
	XGrabButton :: proc(
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
	XUngrabButton :: proc(
		display:       ^Display,
		button:        u32,
		modifiers:     InputMask,
		grab_window:   Window,
		) ---
	XGrabKeyboard :: proc(
		display:       ^Display,
		grab_window:   Window,
		owner_events:  b32,
		pointer_mode:  GrabMode,
		keyboard_mode: GrabMode,
		time:          Time,
		) -> i32 ---
	XUngrabKeyboard :: proc(
		display:       ^Display,
		time:          Time,
		) ---
	XGrabKey :: proc(
		display:       ^Display,
		keycode:       i32,
		modifiers:     InputMask,
		grab_window:   Window,
		owner_events:  b32,
		pointer_mode:  GrabMode,
		keyboard_mode: GrabMode,
		) ---
	XUngrabKey :: proc(
		display:       ^Display,
		keycode:       i32,
		modifiers:     InputMask,
		grab_window:   Window,
		) ---
	// Resuming event processing
	XAllowEvents :: proc(display: ^Display, evend_mode: AllowEventsMode, time: Time) ---
	// Moving the pointer
	XWarpPointer :: proc(
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
	XSetInputFocus :: proc(
		display: ^Display,
		focus: Window,
		revert_to: FocusRevert,
		time: Time,
		) ---
	XGetInputFocus :: proc(
		display: ^Display,
		focus: ^Window,
		revert_to: ^FocusRevert,
		) ---
	// Manipulating the keyboard and pointer settings
	XChangeKeyboardControl :: proc(
		display: ^Display,
		mask: KeyboardControlMask,
		values: ^XKeyboardControl,
		) ---
	XGetKeyboardControl :: proc(
		display: ^Display,
		values: ^XKeyboardState,
		) ---
	XAutoRepeatOn  :: proc(display: ^Display) ---
	XAutoRepeatOff :: proc(display: ^Display) ---
	XBell          :: proc(display: ^Display, percent: i32) ---
	XQueryKeymap   :: proc(display: ^Display, keys: [^]u32) ---
	XSetPointerMapping :: proc(display: ^Display, map_should_not_be_a_keyword: [^]u8, nmap: i32) -> i32 ---
	XGetPointerMapping :: proc(display: ^Display, map_should_not_be_a_keyword: [^]u8, nmap: i32) -> i32 ---
	XChangePointerControl :: proc(
		display:           ^Display,
		do_accel:          b32,
		do_threshold:      b32,
		accel_numerator:   i32,
		accel_denominator: i32,
		threshold:         i32,
		) ---
	XGetPointerControl :: proc(
		display: ^Display,
		accel_numerator:   ^i32,
		accel_denominator: ^i32,
		threshold:         ^i32,
		) ---
	// Manipulating the keyboard encoding
	XDisplayKeycodes :: proc(
		display:      ^Display,
		min_keycodes: ^i32,
		max_keycodes: ^i32,
		) ---
	XGetKeyboardMapping :: proc(
		display:     ^Display,
		first:       KeyCode,
		count:       i32,
		keysyms_per: ^i32,
		) -> ^KeySym ---
	XChangeKeyboardMapping :: proc(
		display:     ^Display,
		first:       KeyCode,
		keysyms_per: i32,
		keysyms:     [^]KeySym,
		num_codes:   i32,
		) ---
	XNewModifiermap :: proc(max_keys_per_mode: i32) -> ^XModifierKeymap ---
	XInsertModifiermapEntry :: proc(
		modmap:        ^XModifierKeymap,
		keycode_entry: KeyCode,
		modifier:      i32,
		) -> ^XModifierKeymap ---
	XDeleteModifiermapEntry :: proc(
		modmap: ^XModifierKeymap,
		keycode_entry: KeyCode,
		modifier: i32,
		) -> ^XModifierKeymap ---
	XFreeModifiermap :: proc(modmap: ^XModifierKeymap) ---
	XSetModifierMapping :: proc(display: ^Display, modmap: ^XModifierKeymap) -> i32 ---
	XGetModifierMapping :: proc(display: ^Display) -> ^XModifierKeymap ---
	// Manipulating top-level windows
	XIconifyWindow :: proc(
		dipslay:   ^Display,
		window:    Window,
		screen_no: i32,
		) -> Status ---
	XWithdrawWindow :: proc(
		dipslay:   ^Display,
		window:    Window,
		screen_no: i32,
		) -> Status ---
	XReconfigureWMWindow :: proc(
		dipslay:   ^Display,
		window:    Window,
		screen_no: i32,
		mask:      WindowChangesMask,
		changes:   ^XWindowChanges,
		) -> Status ---
	// Getting and setting the WM_NAME property
	XSetWMName :: proc(
		display:   ^Display,
		window:    Window,
		prop:      ^XTextProperty,
		) ---
	XGetWMName :: proc(
		display: ^Display,
		window:  Window,
		prop:    ^XTextProperty,
		) -> Status ---
	XStoreName :: proc(
		display: ^Display,
		window:  Window,
		name:    cstring,
		) ---
	XFetchName :: proc(
		display: ^Display,
		window:  Window,
		name:    ^cstring,
		) -> Status ---
	XSetWMIconName :: proc(
		display: ^Display,
		window:  Window,
		prop:    ^XTextProperty,
		) ---
	XGetWMIconName :: proc(
		display: ^Display,
		window:  Window,
		prop:    ^XTextProperty,
		) -> Status ---
	XSetIconName :: proc(
		display: ^Display,
		window:  Window,
		name:    cstring,
		) ---
	XGetIconName :: proc(
		display: ^Display,
		window:  Window,
		prop:    ^cstring,
		) -> Status ---
	// Setting and reading WM_HINTS property
	XAllocWMHints :: proc() -> ^XWMHints ---
	XSetWMHints :: proc(
		display: ^Display,
		window:  Window,
		hints:   ^XWMHints,
		) ---
	XGetWMHints :: proc(
		display: ^Display,
		window:  Window,
		) -> ^XWMHints ---
	// Setting and reading MW_NORMAL_HINTS property
	XAllocSizeHints :: proc() -> ^XSizeHints ---
	XSetWMNormalHints :: proc(
		display: ^Display,
		window:  Window,
		hints:   ^XSizeHints,
		) ---
	XGetWMNormalHints :: proc(
		display: ^Display,
		window: Window,
		hints: ^XSizeHints,
		flags: ^SizeHints,
		) -> Status ---
	XSetWMSizeHints :: proc(
		display: ^Display,
		window:  Window,
		hints:   ^XSizeHints,
		prop:    Atom,
		) ---
	XGetWMSizeHints :: proc(
		display: ^Display,
		window:  Window,
		hints:   ^XSizeHints,
		masks:   ^SizeHints,
		prop:    Atom,
		) -> Status ---
	// Setting and reading the WM_CLASS property
	XAllocClassHint :: proc() -> ^XClassHint ---
	XSetClassHint :: proc(
		display: ^Display,
		window:  Window,
		hint:    ^XClassHint,
		) ---
	XGetClassHint :: proc(
		display: ^Display,
		window:  Window,
		hint:    ^XClassHint,
		) -> Status ---
	// Setting and reading WM_TRANSIENT_FOR property
	XSetTransientForHint :: proc(
		display:     ^Display,
		window:      Window,
		prop_window: Window,
		) ---
	XGetTransientForHint :: proc(
		display:     ^Display,
		window:      Window,
		prop_window: ^Window,
		) -> Status ---
	// Setting and reading the WM_PROTOCOLS property
	XSetWMProtocols :: proc(
		display:   ^Display,
		window:    Window,
		protocols: [^]Atom,
		count:     i32,
		) -> Status ---
	XGetWMProtocols :: proc(
		display:   ^Display,
		window:    Window,
		protocols: ^[^]Atom,
		count:     ^i32,
		) -> Status ---
	// Setting and reading the WM_COLORMAP_WINDOWS property
	XSetWMColormapWindows :: proc(
		display:          ^Display,
		window:           Window,
		colormap_windows: [^]Window,
		count:            i32,
		) -> Status ---
	XGetWMColormapWindows :: proc(
		display:          ^Display,
		window:           Window,
		colormap_windows: ^[^]Window,
		count:            ^i32,
		) -> Status ---
	// Setting and reading the WM_ICON_SIZE_PROPERTY
	XAllocIconSize :: proc() -> ^XIconSize ---
	XSetIconSizes :: proc(
		display:   ^Display,
		window:    Window,
		size_list: [^]XIconSize,
		count:     i32,
		) ---
	XGetIconSizes :: proc(
		display:   ^Display,
		window:    Window,
		size_list: ^[^]XIconSize,
		count:     ^i32,
		) -> Status ---
	// Using window manager convenience functions
	XmbSetWMProperties :: proc(
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
	XSetWMProperties :: proc(
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
	XSetCommand :: proc(
		display: ^Display,
		window:  Window,
		argv:    [^]cstring,
		argc:    i32,
		) ---
	XGetCommand :: proc(
		display: ^Display,
		window:  Window,
		argv:    ^[^]cstring,
		argc:    ^i32,
		) -> Status ---
	XSetWMClientMachine :: proc(
		display: ^Display,
		window:  Window,
		prop:    ^XTextProperty,
		) ---
	XGetWMClientMachine :: proc(
		display: ^Display,
		window:  Window,
		prop:    ^XTextProperty,
		) -> Status ---
	XSetRGBColormaps :: proc(
		display:  ^Display,
		window:   Window,
		colormap: ^XStandardColormap,
		prop:     Atom,
		) ---
	XGetRGBColormaps :: proc(
		display:  ^Display,
		window:   Window,
		colormap: ^[^]XStandardColormap,
		count:    ^i32,
		prop:     Atom,
		) -> Status ---
	// Keyboard utility functions
	XLookupKeysym :: proc(
		event: ^XKeyEvent,
		index: i32,
		) -> KeySym ---
	XKeycodeToKeysym :: proc(
		display: ^Display,
		keycode: KeyCode,
		index: i32,
		) -> KeySym ---
	XKeysymToKeycode :: proc(
		display: ^Display,
		keysym: KeySym,
		) -> KeyCode ---
	XRefreshKeyboardMapping :: proc(event_map: ^XMappingEvent) ---
	XConvertCase :: proc(
		keysym: KeySym,
		lower:  ^KeySym,
		upper:  ^KeySym,
		) ---
	XStringToKeysym :: proc(str: cstring) -> KeySym ---
	XKeysymToString :: proc(keysym: KeySym) -> cstring ---
	XLookupString :: proc(
		event: ^XKeyEvent,
		buffer: [^]u8,
		count: i32,
		keysym: ^KeySym,
		status: ^XComposeStatus,
		) -> i32 ---
	XRebindKeysym :: proc(
		display: ^Display,
		keysym: KeySym,
		list: [^]KeySym,
		mod_count: i32,
		string: [^]u8,
		num_bytes: i32,
		) ---
	// Allocating permanent storage
	XPermalloc :: proc(size: u32) -> rawptr ---
	// Parsing the window geometry
	XParseGeometry :: proc(
		parsestring: cstring,
		x_ret:       ^i32,
		y_ret:       ^i32,
		width:       ^u32,
		height:      ^u32,
		) -> i32 ---
	XWMGeometry :: proc(
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
	XCreateRegion :: proc() -> Region ---
	XPolygonRegion :: proc(
		points: [^]XPoint,
		n:      i32,
		fill:   FillRule,
		) -> Region ---
	XSetRegion :: proc(
		display: ^Display,
		gc:      GC,
		region:  Region,
		) ---
	XDestroyRegion :: proc(r: Region) ---
	// Moving or shrinking regions
	XOffsetRegion :: proc(region: Region, dx, dy: i32) ---
	XShrinkRegion :: proc(region: Region, dx, dy: i32) ---
	// Computing with regions
	XClipBox :: proc(region: Region, rect: ^XRectangle) ---
	XIntersectRegion :: proc(sra, srb, ret: Region) ---
	XUnionRegion :: proc(sra, srb, ret: Region) ---
	XUnionRectWithRegion :: proc(rect: ^XRectangle, src, dst: Region) ---
	XSubtractRegion :: proc(sra, srb, ret: Region) ---
	XXorRegion :: proc(sra, srb, ret: Region) ---
	XEmptyRegion :: proc(reg: Region) -> b32 ---
	XEqualRegion :: proc(a,b: Region) -> b32 ---
	XPointInRegion :: proc(reg: Region, x,y: i32) -> b32 ---
	XRectInRegion :: proc(reg: Region, x,y: i32, w,h: u32) -> b32 ---
	// Using cut buffers
	XStoreBytes :: proc(display: ^Display, bytes: [^]u8, nbytes: i32) ---
	XStoreBuffer :: proc(display: ^Display, bytes: [^]u8, nbytes: i32, buffer: i32) ---
	XFetchBytes :: proc(display: ^Display, nbytes: ^i32) -> [^]u8 ---
	XFetchBuffer :: proc(display: ^Display, nbytes: ^i32, buffer: i32) -> [^]u8 ---
	// Determining the appropriate visual types
	XGetVisualInfo :: proc(
		display: ^Display,
		mask:    VisualInfoMask,
		info:    ^XVisualInfo,
		nret:    ^i32,
		) -> [^]XVisualInfo ---
	XMatchVisualInfo :: proc(
		display:   ^Display,
		screen_no: i32,
		depth:     i32,
		class:     i32,
		ret:       ^XVisualInfo,
		) -> Status ---
	// Manipulating images
	XCreateImage :: proc(
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
	XGetPixel :: proc(
		image: ^XImage,
		x:     i32,
		y:     i32,
		) -> uint ---
	XPutPixel :: proc(
		image: ^XImage,
		x:     i32,
		y:     i32,
		pixel: uint,
		) ---
	XSubImage :: proc(
		image: ^XImage,
		x: i32,
		y: i32,
		w: u32,
		h: u32,
		) -> ^XImage ---
	XAddPixel :: proc(
		image: ^XImage,
		value: int,
		) ---
	XDestroyImage :: proc(image: ^XImage) ---
}
