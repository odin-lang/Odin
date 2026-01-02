package sdl3

import "core:c"

PenID :: distinct Uint32

PEN_MOUSEID :: MouseID(1<<32 - 2)
PEN_TOUCHID :: TouchID(1<<64 - 2)


PenInputFlags :: distinct bit_set[PenInputFlag; Uint32]
PenInputFlag :: enum Uint32 {
	DOWN         = 0,  /**< pen is pressed down */
	BUTTON_1     = 1,  /**< button 1 is pressed */
	BUTTON_2     = 2,  /**< button 2 is pressed */
	BUTTON_3     = 3,  /**< button 3 is pressed */
	BUTTON_4     = 4,  /**< button 4 is pressed */
	BUTTON_5     = 5,  /**< button 5 is pressed */
	ERASER_TIP   = 30, /**< eraser tip is used */
	IN_PROXIMITY = 31, /**< pen is in proximity (since SDL 3.4.0) */
}

PenAxis :: enum c.int {
	PRESSURE,            /**< Pen pressure.  Unidirectional: 0 to 1.0 */
	XTILT,               /**< Pen horizontal tilt angle.  Bidirectional: -90.0 to 90.0 (left-to-right). */
	YTILT,               /**< Pen vertical tilt angle.  Bidirectional: -90.0 to 90.0 (top-to-down). */
	DISTANCE,            /**< Pen distance to drawing surface.  Unidirectional: 0.0 to 1.0 */
	ROTATION,            /**< Pen barrel rotation.  Bidirectional: -180 to 179.9 (clockwise, 0 is facing up, -180.0 is facing down). */
	SLIDER,              /**< Pen finger wheel or slider (e.g., Airbrush Pen).  Unidirectional: 0 to 1.0 */
	TANGENTIAL_PRESSURE, /**< Pressure from squeezing the pen ("barrel pressure"). */
}

PenDeviceType :: enum c.int {
	INVALID = -1, /**< Not a valid pen device. */
	UNKNOWN,      /**< Don't know specifics of this pen. */
	DIRECT,       /**< Pen touches display. */
	INDIRECT,     /**< Pen touches something that isn't the display. */
}

@(default_calling_convention="c", link_prefix="SDL_", require_results)
foreign lib {
	GetPenDeviceType :: proc(instance_id: PenID) ---
}
