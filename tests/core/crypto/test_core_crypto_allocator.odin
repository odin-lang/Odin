package test_core_crypto

import "core:crypto/kmac"
import "core:crypto/noise"
import "core:mem"
import "core:testing"

@(test)
test_kmac_verify_allocator :: proc(t: ^testing.T) {
	arg_track, ctx_track: mem.Tracking_Allocator
	mem.tracking_allocator_init(&arg_track, context.allocator)
	defer mem.tracking_allocator_destroy(&arg_track)
	mem.tracking_allocator_init(&ctx_track, context.allocator)
	defer mem.tracking_allocator_destroy(&ctx_track)
	ctx_track.bad_free_callback = mem.tracking_allocator_bad_free_callback_add_to_array

	key: [32]byte
	key[0] = 1
	msg := "message"
	tag: [32]byte
	kmac.sum(128, tag[:], transmute([]byte)msg, key[:], nil)

	{
		context.allocator = mem.tracking_allocator(&ctx_track)
		testing.expect(t, kmac.verify(128, tag[:], transmute([]byte)msg, key[:], nil))
		testing.expect(t, kmac.verify(128, tag[:], transmute([]byte)msg, key[:], nil, mem.tracking_allocator(&arg_track)))
	}
	testing.expect_value(t, ctx_track.total_allocation_count, 0)
	testing.expect_value(t, len(ctx_track.bad_free_array), 0)
	testing.expect_value(t, arg_track.total_allocation_count, 1)
	testing.expect_value(t, len(arg_track.allocation_map), 0)
}

@(test)
test_noise_read_message_error_allocator :: proc(t: ^testing.T) {
	arg_track, ctx_track: mem.Tracking_Allocator
	mem.tracking_allocator_init(&arg_track, context.allocator)
	defer mem.tracking_allocator_destroy(&arg_track)
	mem.tracking_allocator_init(&ctx_track, context.allocator)
	defer mem.tracking_allocator_destroy(&ctx_track)
	ctx_track.bad_free_callback = mem.tracking_allocator_bad_free_callback_add_to_array

	PROTOCOL :: "Noise_NN_25519_ChaChaPoly_SHA256"
	ini, res: noise.Handshake_State
	testing.expect_value(t, noise.handshake_init(&ini, true, nil, nil, nil, PROTOCOL), noise.Status.Ok)
	defer noise.handshake_reset(&ini)
	testing.expect_value(t, noise.handshake_init(&res, false, nil, nil, nil, PROTOCOL), noise.Status.Ok)
	defer noise.handshake_reset(&res)

	msg1_buf, msg2_buf, payload_buf: [noise.MAX_STEP_MSG_SIZE]byte
	msg1, status := noise.handshake_write_message(&ini, nil, msg1_buf[:])
	testing.expect_value(t, status, noise.Status.Handshake_Pending)
	_, status = noise.handshake_read_message(&res, msg1, payload_buf[:])
	testing.expect_value(t, status, noise.Status.Handshake_Pending)
	msg2: []byte
	msg2, status = noise.handshake_write_message(&res, transmute([]byte)string("payload"), msg2_buf[:])
	testing.expect_value(t, status, noise.Status.Handshake_Complete)
	if len(msg2) == 0 {
		return
	}
	msg2[len(msg2) - 1] ~= 1

	payload: []byte
	{
		context.allocator = mem.tracking_allocator(&ctx_track)
		payload, status = noise.handshake_read_message(&ini, msg2, allocator = mem.tracking_allocator(&arg_track))
	}
	testing.expect_value(t, status, noise.Status.Handshake_Failed)
	testing.expect(t, payload == nil)
	testing.expect_value(t, ctx_track.total_allocation_count, 0)
	testing.expect_value(t, len(ctx_track.bad_free_array), 0)
	testing.expect_value(t, arg_track.total_allocation_count, 1)
	testing.expect_value(t, len(arg_track.allocation_map), 0)
}
