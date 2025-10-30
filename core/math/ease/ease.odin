// Easing procedures and flux easing used for animations.
package ease

import "core:math"
import "base:intrinsics"
import "core:time"

@(private) PI_2 :: math.PI / 2

// converted to odin from https://github.com/warrenm/AHEasing
// with additional enum based call

// Modeled after the parabola y = x^2
@(require_results)
quadratic_in :: proc "contextless" (p: $T) -> T where intrinsics.type_is_float(T) {
	return p * p
}

// Modeled after the parabola y = -x^2 + 2x
@(require_results)
quadratic_out :: proc "contextless" (p: $T) -> T where intrinsics.type_is_float(T) {
	return -(p * (p - 2))
}

// Modeled after the piecewise quadratic
// y = (1/2)((2x)^2)             ; [0, 0.5)
// y = -(1/2)((2x-1)*(2x-3) - 1) ; [0.5, 1]
@(require_results)
quadratic_in_out :: proc "contextless" (p: $T) -> T where intrinsics.type_is_float(T) {
	if p < 0.5 {
		return 2 * p * p
	}	else {
		return (-2 * p * p) + (4 * p) - 1
	}
}

// Modeled after the cubic y = x^3
@(require_results)
cubic_in :: proc "contextless" (p: $T) -> T where intrinsics.type_is_float(T) {
	return p * p * p
}

// Modeled after the cubic y = (x - 1)^3 + 1
@(require_results)
cubic_out :: proc "contextless" (p: $T) -> T where intrinsics.type_is_float(T) {
	f := p - 1
	return f * f * f + 1
}

// Modeled after the piecewise cubic
// y = (1/2)((2x)^3)       ; [0, 0.5)
// y = (1/2)((2x-2)^3 + 2) ; [0.5, 1]
@(require_results)
cubic_in_out :: proc "contextless" (p: $T) -> T where intrinsics.type_is_float(T) {
	if p < 0.5 {
		return 4 * p * p * p
	} else {
		f := (2 * p) - 2
		return 0.5 * f * f * f + 1
	}
}

// Modeled after the quartic x^4
@(require_results)
quartic_in :: proc "contextless" (p: $T) -> T where intrinsics.type_is_float(T) {
	return p * p * p * p
}

// Modeled after the quartic y = 1 - (x - 1)^4
@(require_results)
quartic_out :: proc "contextless" (p: $T) -> T where intrinsics.type_is_float(T) {
	f := p - 1
	return f * f * f * (1 - p) + 1
}

// Modeled after the piecewise quartic
// y = (1/2)((2x)^4)        ; [0, 0.5)
// y = -(1/2)((2x-2)^4 - 2) ; [0.5, 1]
@(require_results)
quartic_in_out :: proc "contextless" (p: $T) -> T where intrinsics.type_is_float(T) {
	if p < 0.5 {
		return 8 * p * p * p * p
	}	else {
		f := p - 1
		return -8 * f * f * f * f + 1
	}
}

// Modeled after the quintic y = x^5
@(require_results)
quintic_in :: proc "contextless" (p: $T) -> T where intrinsics.type_is_float(T) {
	return p * p * p * p * p
}

// Modeled after the quintic y = (x - 1)^5 + 1
@(require_results)
quintic_out :: proc "contextless" (p: $T) -> T where intrinsics.type_is_float(T) {
	f := p - 1
	return f * f * f * f * f + 1
}

// Modeled after the piecewise quintic
// y = (1/2)((2x)^5)       ; [0, 0.5)
// y = (1/2)((2x-2)^5 + 2) ; [0.5, 1]
@(require_results)
quintic_in_out :: proc "contextless" (p: $T) -> T where intrinsics.type_is_float(T) {
	if p < 0.5 {
		return 16 * p * p * p * p * p
	}	else {
		f := (2 * p) - 2
		return  0.5 * f * f * f * f * f + 1
	}
}

// Modeled after quarter-cycle of sine wave
@(require_results)
sine_in :: proc "contextless" (p: $T) -> T where intrinsics.type_is_float(T) {
	return math.sin((p - 1) * PI_2) + 1
}

// Modeled after quarter-cycle of sine wave (different phase)
@(require_results)
sine_out :: proc "contextless" (p: $T) -> T where intrinsics.type_is_float(T) {
	return math.sin(p * PI_2)
}

// Modeled after half sine wave
@(require_results)
sine_in_out :: proc "contextless" (p: $T) -> T where intrinsics.type_is_float(T) {
	return 0.5 * (1 - math.cos(p * math.PI))
}

// Modeled after shifted quadrant IV of unit circle
@(require_results)
circular_in :: proc "contextless" (p: $T) -> T where intrinsics.type_is_float(T) {
	return 1 - math.sqrt(1 - (p * p))
}

// Modeled after shifted quadrant II of unit circle
@(require_results)
circular_out :: proc "contextless" (p: $T) -> T where intrinsics.type_is_float(T) {
	return math.sqrt((2 - p) * p)
}

// Modeled after the piecewise circular function
// y = (1/2)(1 - sqrt(1 - 4x^2))           ; [0, 0.5)
// y = (1/2)(sqrt(-(2x - 3)*(2x - 1)) + 1) ; [0.5, 1]
@(require_results)
circular_in_out :: proc "contextless" (p: $T) -> T where intrinsics.type_is_float(T) {
	if p < 0.5 {
		return 0.5 * (1 - math.sqrt(1 - 4 * (p * p)))
	}	else {
		return 0.5 * (math.sqrt(-((2 * p) - 3) * ((2 * p) - 1)) + 1)
	}
}

// Modeled after the exponential function y = 2^(10(x - 1))
@(require_results)
exponential_in :: proc "contextless" (p: $T) -> T where intrinsics.type_is_float(T) {
	return p == 0.0 ? p : math.pow(2, 10 * (p - 1))
}

// Modeled after the exponential function y = -2^(-10x) + 1
@(require_results)
exponential_out :: proc "contextless" (p: $T) -> T where intrinsics.type_is_float(T) {
	return p == 1.0 ? p : 1 - math.pow(2, -10 * p)
}

// Modeled after the piecewise exponential
// y = (1/2)2^(10(2x - 1))         ; [0,0.5)
// y = -(1/2)*2^(-10(2x - 1))) + 1 ; [0.5,1]
@(require_results)
exponential_in_out :: proc "contextless" (p: $T) -> T where intrinsics.type_is_float(T) {
	if p == 0.0 || p == 1.0 {
		return p
	}
	
	if p < 0.5 {
		return 0.5 * math.pow(2, (20 * p) - 10)
	} else {
		return -0.5 * math.pow(2, (-20 * p) + 10) + 1
	}
}

// Modeled after the damped sine wave y = sin(13pi/2*x)*pow(2, 10 * (x - 1))
@(require_results)
elastic_in :: proc "contextless" (p: $T) -> T where intrinsics.type_is_float(T) {
	return math.sin(13 * PI_2 * p) * math.pow(2, 10 * (p - 1))
}

// Modeled after the damped sine wave y = sin(-13pi/2*(x + 1))*pow(2, -10x) + 1
@(require_results)
elastic_out :: proc "contextless" (p: $T) -> T where intrinsics.type_is_float(T) {
	return math.sin(-13 * PI_2 * (p + 1)) * math.pow(2, -10 * p) + 1
}

// Modeled after the piecewise exponentially-damped sine wave:
// y = (1/2)*sin(13pi/2*(2*x))*pow(2, 10 * ((2*x) - 1))      ; [0,0.5)
// y = (1/2)*(sin(-13pi/2*((2x-1)+1))*pow(2,-10(2*x-1)) + 2) ; [0.5, 1]
@(require_results)
elastic_in_out :: proc "contextless" (p: $T) -> T where intrinsics.type_is_float(T) {
	if p < 0.5 {
		return 0.5 * math.sin(13 * PI_2 * (2 * p)) * math.pow(2, 10 * ((2 * p) - 1))
	} else {
		return 0.5 * (math.sin(-13 * PI_2 * ((2 * p - 1) + 1)) * math.pow(2, -10 * (2 * p - 1)) + 2)
	}
}

// Modeled after the overshooting cubic y = x^3-x*sin(x*pi)
@(require_results)
back_in :: proc "contextless" (p: $T) -> T where intrinsics.type_is_float(T) {
	return p * p * p - p * math.sin(p * math.PI)
}

// Modeled after overshooting cubic y = 1-((1-x)^3-(1-x)*sin((1-x)*pi))
@(require_results)
back_out :: proc "contextless" (p: $T) -> T where intrinsics.type_is_float(T) {
	f := 1 - p
	return 1 - (f * f * f - f * math.sin(f * math.PI))
}

// Modeled after the piecewise overshooting cubic function:
// y = (1/2)*((2x)^3-(2x)*sin(2*x*pi))           ; [0, 0.5)
// y = (1/2)*(1-((1-x)^3-(1-x)*sin((1-x)*pi))+1) ; [0.5, 1]
@(require_results)
back_in_out :: proc "contextless" (p: $T) -> T where intrinsics.type_is_float(T) {
	if p < 0.5 {
		f := 2 * p
		return 0.5 * (f * f * f - f * math.sin(f * math.PI))
	} else {
		f := (1 - (2*p - 1))
		return 0.5 * (1 - (f * f * f - f * math.sin(f * math.PI))) + 0.5
	}
}

@(require_results)
bounce_in :: proc "contextless" (p: $T) -> T where intrinsics.type_is_float(T) {
	return 1 - bounce_out(1 - p)
}

@(require_results)
bounce_out :: proc "contextless" (p: $T) -> T where intrinsics.type_is_float(T) {
	if p < 4/11.0 {
		return (121 * p * p)/16.0
	}	else if p < 8/11.0 {
		return (363/40.0 * p * p) - (99/10.0 * p) + 17/5.0
	}	else if p < 9/10.0 {
		return (4356/361.0 * p * p) - (35442/1805.0 * p) + 16061/1805.0
	}	else {
		return (54/5.0 * p * p) - (513/25.0 * p) + 268/25.0
	}
}

@(require_results)
bounce_in_out :: proc "contextless" (p: $T) -> T where intrinsics.type_is_float(T) {
	if p < 0.5 {
		return 0.5 * bounce_in(p*2)
	} else {
		return 0.5 * bounce_out(p * 2 - 1) + 0.5
	}
}

// additional enum variant

Ease :: enum {
	Linear,

	Quadratic_In,
	Quadratic_Out,
	Quadratic_In_Out,

	Cubic_In,
	Cubic_Out,
	Cubic_In_Out,

	Quartic_In,
	Quartic_Out,
	Quartic_In_Out,

	Quintic_In,
	Quintic_Out,
	Quintic_In_Out,

	Sine_In,
	Sine_Out,
	Sine_In_Out,

	Circular_In,
	Circular_Out,
	Circular_In_Out,

	Exponential_In,
	Exponential_Out,
	Exponential_In_Out,

	Elastic_In,
	Elastic_Out,
	Elastic_In_Out,

	Back_In,
	Back_Out,
	Back_In_Out,

	Bounce_In,
	Bounce_Out,
	Bounce_In_Out,
}

@(require_results)
ease :: proc "contextless" (type: Ease, p: $T) -> T 
	where intrinsics.type_is_float(T) {
	switch type {
	case .Linear: return p

	case .Quadratic_In: return quadratic_in(p)
	case .Quadratic_Out: return quadratic_out(p)
	case .Quadratic_In_Out: return quadratic_in_out(p)

	case .Cubic_In: return cubic_in(p)
	case .Cubic_Out: return cubic_out(p)
	case .Cubic_In_Out: return cubic_in_out(p)

	case .Quartic_In: return quartic_in(p)
	case .Quartic_Out: return quartic_out(p)
	case .Quartic_In_Out: return quartic_in_out(p)

	case .Quintic_In: return quintic_in(p)
	case .Quintic_Out: return quintic_out(p)
	case .Quintic_In_Out: return quintic_in_out(p)

	case .Sine_In: return sine_in(p)
	case .Sine_Out: return sine_out(p)
	case .Sine_In_Out: return sine_in_out(p)

	case .Circular_In: return circular_in(p)
	case .Circular_Out: return circular_out(p)
	case .Circular_In_Out: return circular_in_out(p)

	case .Exponential_In: return exponential_in(p)
	case .Exponential_Out: return exponential_out(p)
	case .Exponential_In_Out: return exponential_in_out(p)

	case .Elastic_In: return elastic_in(p)
	case .Elastic_Out: return elastic_out(p)
	case .Elastic_In_Out: return elastic_in_out(p)

	case .Back_In: return back_in(p)
	case .Back_Out: return back_out(p)
	case .Back_In_Out: return back_in_out(p)

	case .Bounce_In: return bounce_in(p)
	case .Bounce_Out: return bounce_out(p)
	case .Bounce_In_Out: return bounce_in_out(p)
	}

	// in case type was invalid
	return 0
}
Flux_Map :: struct($T: typeid) {
	values: map[^T]Flux_Tween(T),
	keys_to_be_deleted: [dynamic]^T,
}

Flux_Tween :: struct($T: typeid) {
	value: ^T,
	start: T,
	diff: T,
	goal: T,

	delay: f64, // in seconds
	duration: time.Duration,

	progress: f64,
	rate: f64,
	type: Ease,

	inited: bool,

	// callbacks, data can be set, will be pushed to callback
	data: rawptr, // by default gets set to value input
	on_start: proc(flux: ^Flux_Map(T), data: rawptr),
	on_update: proc(flux: ^Flux_Map(T), data: rawptr),
	on_complete: proc(flux: ^Flux_Map(T), data: rawptr),
}

// init flux map to a float type and a wanted cap
@(require_results)
flux_init :: proc($T: typeid, value_capacity := 8) -> Flux_Map(T) where intrinsics.type_is_float(T) {
	return {
		values = make(map[^T]Flux_Tween(T), value_capacity),
		keys_to_be_deleted = make([dynamic]^T, 0, value_capacity),
	}
}

// delete map content
flux_destroy :: proc(flux: Flux_Map($T)) where intrinsics.type_is_float(T) {
	delete(flux.values)
	delete(flux.keys_to_be_deleted)
}

// clear map content, stops all animations
flux_clear :: proc(flux: ^Flux_Map($T)) where intrinsics.type_is_float(T) {
	clear(&flux.values)
}

// append / overwrite existing tween value to parameters
// rest is initialized in flux_tween_init, inside update
// return value can be used to set callbacks
@(require_results)
flux_to :: proc(
	flux: ^Flux_Map($T),
	value: ^T, 
	goal: T, 
	type: Ease = .Quadratic_Out,
	duration: time.Duration = time.Second, 
	delay: f64 = 0,
) -> (tween: ^Flux_Tween(T)) where intrinsics.type_is_float(T) {
	if res, ok := &flux.values[value]; ok {
		tween = res
	} else {
		flux.values[value] = {}
		tween = &flux.values[value]
	}

	tween^ = { 
		value = value, 
		goal = goal, 
		duration = duration,
		delay = delay,
		type = type,
		data = value,
	}

	return
}

// init internal properties
flux_tween_init :: proc(tween: ^Flux_Tween($T), duration: time.Duration) where intrinsics.type_is_float(T) {
	tween.inited = true
	tween.start = tween.value^
	tween.diff = tween.goal - tween.value^
	s := time.duration_seconds(duration)
	tween.rate = duration > 0 ? 1.0 / s : 0
	tween.progress = duration > 0 ? 0 : 1
}

// update all tweens, wait for their delay if one exists
// calls callbacks in all stages, when they're filled
// deletes tween from the map after completion
flux_update :: proc(flux: ^Flux_Map($T), dt: f64) where intrinsics.type_is_float(T) {
	clear(&flux.keys_to_be_deleted)

	for key, &tween in flux.values {
		delay_remainder := f64(0)

		// Update delay if necessary.
		if tween.delay > 0 {
			tween.delay -= dt

			if tween.delay < 0 {
				// We finished the delay, but in doing so consumed part of this frame's `dt` budget.
				// Keep track of it so we can apply it to this tween without affecting others.
				delay_remainder = tween.delay
				// We're done with this delay.
				tween.delay = 0
			}
		}

		// We either had no delay, or the delay has been consumed.
		if tween.delay <= 0 {
			if !tween.inited {
				flux_tween_init(&tween, tween.duration)
				
				if tween.on_start != nil {
					tween.on_start(flux, tween.data)
				}
			} 

			// If part of the `dt` budget was consumed this frame, then `delay_remainder` will be
			// that remainder, a negative value. Adding it to `dt` applies what's left of the `dt`
			// to the tween so it advances properly, instead of too much or little.
			tween.progress += tween.rate * (dt + delay_remainder)
			x := tween.progress >= 1 ? 1 : ease(tween.type, tween.progress)
			tween.value^ = tween.start + tween.diff * T(x)

			if tween.on_update != nil {
				tween.on_update(flux, tween.data)
			}

			if tween.progress >= 1 {
				// append keys to array that will be deleted after the loop
				append(&flux.keys_to_be_deleted, key)

				if tween.on_complete != nil {
					tween.on_complete(flux, tween.data)
				}
			}
		}
	}
	
	// loop through keys that should be deleted from the map
	if len(flux.keys_to_be_deleted) != 0 {
		for key in flux.keys_to_be_deleted {
			delete_key(&flux.values, key)
		}
	}
}

// stop a specific key inside the map
// returns true when it successfully removed the key
@(require_results)
flux_stop :: proc(flux: ^Flux_Map($T), key: ^T) -> bool where intrinsics.type_is_float(T) {
	if key in flux.values {
		delete_key(&flux.values, key)
		return true
	}

	return false
}

// returns the amount of time left for the tween animation, if the key exists in the map
// returns 0 if the tween doesnt exist on the map
@(require_results)
flux_tween_time_left :: proc(flux: Flux_Map($T), key: ^T) -> f64 {
	if tween, ok := flux.values[key]; ok {
		return ((1 - tween.progress) * tween.rate) + tween.delay
	} else {
		return 0
	}
}
