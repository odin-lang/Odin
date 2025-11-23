// Flux easing used for animations
package ease

import "core:time"

Flux_Map :: struct($T: typeid) {
	values: map[^T]Flux_Tween(T),
	keys_to_be_deleted: [dynamic]^T,
}

Flux_Tween :: struct($T: typeid) {
	value:       ^T,
	start:       T,
	diff:        T,
	goal:        T,

	delay:       f64, // in seconds
	duration:    time.Duration,

	progress:    f64,
	rate:        f64,
	type:        Ease,

	inited:      bool,

	// callbacks, data can be set, will be pushed to callback
	data:        rawptr, // by default gets set to value input
	on_start:    proc(flux: ^Flux_Map(T), data: rawptr),
	on_update:   proc(flux: ^Flux_Map(T), data: rawptr),
	on_complete: proc(flux: ^Flux_Map(T), data: rawptr),
}

// init flux map to a float type and a wanted cap
@(require_results)
flux_init :: proc($T: typeid, value_capacity := 8, allocator := context.allocator, loc := #caller_location) -> Flux_Map(T) where intrinsics.type_is_float(T) {
	return {
		values = make(map[^T]Flux_Tween(T), value_capacity, allocator, loc),
		keys_to_be_deleted = make([dynamic]^T, 0, value_capacity, allocator, loc),
	}
}

// delete map content
flux_destroy :: proc(flux: Flux_Map($T), allocator := context.allocator, loc := #caller_location) where intrinsics.type_is_float(T) {
	delete(flux.values, allocator, loc)
	delete(flux.keys_to_be_deleted, allocator, loc)
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
// returns 0 if the tween doesn't exist on the map
@(require_results)
flux_tween_time_left :: proc(flux: Flux_Map($T), key: ^T) -> f64 {
	if tween, ok := flux.values[key]; ok {
		return ((1 - tween.progress) * tween.rate) + tween.delay
	} else {
		return 0
	}
}
