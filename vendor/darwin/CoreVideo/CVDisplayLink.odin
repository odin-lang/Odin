// Bindings for [[ CoreVideo ; https://developer.apple.com/documentation/corevideo ]].
package CoreVideo

DisplayLinkRef :: distinct rawptr
Return :: i32

TimeStamp :: struct {
	version: u32,
	videoTimeScale: i32,
	videoTime: i64,
	hostTime: u64,
	rateScalar: f64,
	videoRefreshPeriod: i64,
	smpteTime: CVSMPTETime,
	flags: u64,
	reserved: u64,
}

CVSMPTETime :: struct {
	sbuframes: i16,
	subframeDivisor: i16,
	count: u32,
	type: u32,
	flags: u32,
	hours: i16,
	minutes: i16,
	seconds: i16,
	frames: i16,
}

OptionFlags :: u64
DisplayLinkOutputCallback :: #type proc "c" (displayLink: DisplayLinkRef, #by_ptr inNow: TimeStamp, #by_ptr inOutputTime: TimeStamp, flagsIn: OptionFlags, flagsOut: ^OptionFlags, displayLinkContext: rawptr) -> Return

foreign import CoreVideo "system:CoreVideo.framework"
@(link_prefix="CV")
foreign CoreVideo {
	DisplayLinkCreateWithActiveCGDisplays :: proc "c" (displayLinkOut: ^DisplayLinkRef) -> Return ---
	DisplayLinkStart :: proc "c" (displayLink: DisplayLinkRef) -> Return ---
	DisplayLinkStop :: proc "c" (displayLink: DisplayLinkRef) -> Return ---
	DisplayLinkSetOutputCallback :: proc "c" (displayLink: DisplayLinkRef, callback: DisplayLinkOutputCallback, userInfo: rawptr) -> Return ---
	DisplayLinkRelease :: proc "c" (displayLink: DisplayLinkRef) ---
	DisplayLinkRetain :: proc "c" (displayLink: DisplayLinkRef) -> DisplayLinkRef ---
}

