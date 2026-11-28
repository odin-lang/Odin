package tests_nbio
import "core:nbio"
import "core:testing"
import "core:time"

@(test)
run_returns_after_next_tick_only :: proc(t: ^testing.T) {
	if event_loop_guard(t) {
		testing.set_fail_timeout(t, time.Minute)

		called := 0
		op := nbio.next_tick(on_tick)
		op.user_data[0] = &called
		ev(t, nbio.run(), nil)
		ev(t, called, 1)

		called = 0
		op = nbio.next_tick(on_tick_again)
		op.user_data[0] = &called
		ev(t, nbio.run(), nil)
		ev(t, called, 3)

		called = 0
		op = nbio.close(nbio.Closable{}, on_tick)
		op.user_data[0] = &called
		ev(t, nbio.run(), nil)
		ev(t, called, 1)

		on_tick :: proc(op: ^nbio.Operation) {
			(^int)(op.user_data[0])^ += 1
		}

		on_tick_again :: proc(op: ^nbio.Operation) {
			count := (^int)(op.user_data[0])
			count^ += 1
			if count^ < 3 {
				next := nbio.next_tick(on_tick_again)
				next.user_data[0] = count
			}
		}
	}
}
