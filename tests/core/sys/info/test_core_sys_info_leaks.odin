package test_core_sys_info

import "base:runtime"
import "core:mem"
import "core:strings"
import "core:testing"
import si "core:sys/info"

@(private="file")
moving_proc :: proc(allocator_data: rawptr, mode: runtime.Allocator_Mode, size, alignment: int, old_memory: rawptr, old_size: int, loc := #caller_location) -> ([]byte, runtime.Allocator_Error) {
	backing := (^runtime.Allocator)(allocator_data)
	#partial switch mode {
	case .Resize, .Resize_Non_Zeroed:
		if old_memory == nil {
			return backing.procedure(backing.data, .Alloc, size, alignment, nil, 0, loc)
		}
		if size == 0 {
			_, err := backing.procedure(backing.data, .Free, 0, alignment, old_memory, old_size, loc)
			return nil, err
		}
		data, err := backing.procedure(backing.data, .Alloc, size, alignment, nil, 0, loc)
		if err != nil {
			return nil, err
		}
		copy(data, ([^]byte)(old_memory)[:min(old_size, size)])
		backing.procedure(backing.data, .Free, 0, alignment, old_memory, old_size, loc)
		return data, nil
	}
	return backing.procedure(backing.data, mode, size, alignment, old_memory, old_size, loc)
}

@(test)
os_version_release_lives_in_full :: proc(t: ^testing.T) {
	track: mem.Tracking_Allocator
	mem.tracking_allocator_init(&track, context.allocator)
	defer mem.tracking_allocator_destroy(&track)
	track.bad_free_callback = mem.tracking_allocator_bad_free_callback_add_to_array

	backing := mem.tracking_allocator(&track)
	moving := runtime.Allocator{moving_proc, &backing}

	for _ in 0 ..< 4 {
		version, ok := si.os_version(moving)
		if ok {
			testing.expect(t, len(version.full) > 0)
			if len(version.release) > 0 {
				full_start    := uintptr(raw_data(version.full))
				full_end      := full_start + uintptr(len(version.full))
				release_start := uintptr(raw_data(version.release))
				release_end   := release_start + uintptr(len(version.release))
				testing.expect(t, release_start >= full_start && release_end <= full_end)
				testing.expect(t, strings.contains(version.full, version.release))
			}
		}
		si.destroy_os_version(version, moving)
	}

	testing.expect_value(t, len(track.allocation_map), 0)
	testing.expect_value(t, len(track.bad_free_array), 0)
}
