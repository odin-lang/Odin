package sdl3

import "core:c"

CameraID :: distinct Uint32

Camera :: struct {}

CameraSpec :: struct {
	format:                PixelFormat, /**< Frame format */
	colorspace:            Colorspace,  /**< Frame colorspace */
	width:                 c.int,       /**< Frame width */
	height:                c.int,       /**< Frame height */
	framerate_numerator:   c.int,       /**< Frame rate numerator ((num / denom) == FPS, (denom / num) == duration in seconds) */
	framerate_denominator: c.int,       /**< Frame rate demoninator ((num / denom) == FPS, (denom / num) == duration in seconds) */
}

CameraPosition :: enum c.int {
	UNKNOWN,
	FRONT_FACING,
	BACK_FACING,
}

@(default_calling_convention="c", link_prefix="SDL_")
foreign lib {
	GetNumCameraDrivers       :: proc() -> c.int ---
	GetCameraDriver           :: proc(index: c.int) -> cstring ---
	GetCurrentCameraDriver    :: proc() -> cstring ---
	GetCameras                :: proc(count: ^c.int) -> [^]CameraID ---
	GetCameraSupportedFormats :: proc(instance_id: CameraID, count: ^c.int) -> [^]^CameraSpec ---
	GetCameraName             :: proc(instance_id: CameraID) -> cstring ---
	GetCameraPosition         :: proc(instance_id: CameraID) -> CameraPosition ---
	OpenCamera                :: proc(instance_id: CameraID, spec: ^CameraSpec) -> ^Camera ---
	GetCameraPermissionState  :: proc(camera: ^Camera) -> c.int ---
	GetCameraID               :: proc(camera: ^Camera) -> CameraID ---
	GetCameraProperties       :: proc(camera: ^Camera) -> PropertiesID ---
	GetCameraFormat           :: proc(camera: ^Camera, spec: ^CameraSpec) -> bool ---
	AcquireCameraFrame        :: proc(camera: ^Camera, timestampNS: ^Uint64) -> ^Surface ---
	ReleaseCameraFrame        :: proc(camera: ^Camera, frame: ^Surface) ---
	CloseCamera               :: proc(camera: ^Camera) ---
}