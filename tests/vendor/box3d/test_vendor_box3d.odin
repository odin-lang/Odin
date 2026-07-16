#+build windows, linux, darwin
package test_vendor_box3d

import "core:math"
import "core:math/linalg"
import "core:os"
import "core:strings"
import "core:testing"

import b3 "vendor:box3d"

// Helper: record 8 steps of a falling sphere. The caller owns the returned handles.
record_falling_sphere :: proc() -> (b3.WorldId, ^b3.Recording) {
	world_def := b3.DefaultWorldDef()
	world := b3.CreateWorld(world_def)

	body_def := b3.DefaultBodyDef()
	body_def.type = .dynamicBody
	body_def.position = b3.Pos{0, 4, 0}
	body := b3.CreateBody(world, body_def)

	shape_def := b3.DefaultShapeDef()
	sphere := b3.Sphere{center = {0, 0, 0}, radius = 0.5}
	_ = b3.CreateSphereShape(body, shape_def, &sphere)

	rec := b3.CreateRecording(0)
	b3.World_StartRecording(world, rec)
	for _ in 0..<8 {
		b3.World_Step(world, 1.0 / 60, 4)
	}
	b3.World_StopRecording(world)

	return world, rec
}

// RotateVector, InvRotateVector, and InvMulQuat must match the C reference.
@(test)
test_quat_rotate_math :: proc(t: ^testing.T) {
	v := b3.Vec3{1, -2, 3}

	// The identity quaternion leaves any vector untouched (exactly).
	testing.expect(t, b3.RotateVector(b3.Quat(1), v) == v, "RotateVector with identity quaternion changed the vector")
	testing.expect(t, b3.InvRotateVector(b3.Quat(1), v) == v, "InvRotateVector with identity quaternion changed the vector")

	// A 90-degree rotation about +Z maps +X to +Y.
	q90 := linalg.quaternion_angle_axis_f32(math.PI / 2, b3.Vec3{0, 0, 1})
	rotated := b3.RotateVector(q90, b3.Vec3{1, 0, 0})
	testing.expect(t, linalg.distance(rotated, b3.Vec3{0, 1, 0}) < 1e-5, "RotateVector 90 degrees about +Z did not map +X to +Y")

	axis := linalg.normalize(b3.Vec3{0.3, 0.8, -0.5})
	q := linalg.quaternion_angle_axis_f32(0.9, axis)

	// RotateVector agrees with the linalg reference rotation.
	reference := linalg.quaternion_mul_vector3(q, v)
	testing.expect(t, linalg.distance(b3.RotateVector(q, v), reference) < 1e-5, "RotateVector disagrees with the linalg reference")

	// InvRotateVector inverts RotateVector for a normalized quaternion.
	round_trip := b3.InvRotateVector(q, b3.RotateVector(q, v))
	testing.expect(t, linalg.distance(round_trip, v) < 1e-5, "InvRotateVector did not invert RotateVector")

	// inv(q) * q is the identity quaternion.
	identity := b3.InvMulQuat(q, q)
	testing.expect(t, linalg.length(identity.xyz) < 1e-5, "InvMulQuat(q, q) has a non-zero vector part")
	testing.expect(t, math.abs(identity.w - 1) < 1e-5, "InvMulQuat(q, q) does not have w == 1")
}

// Recording and RecPlayer handle round-trip.
@(test)
test_recording_and_recplayer_round_trip :: proc(t: ^testing.T) {
	world, rec := record_falling_sphere()
	defer b3.DestroyWorld(world)
	defer b3.DestroyRecording(rec)

	size := b3.Recording_GetSize(rec)
	testing.expect(t, size > 0, "recording is empty after 8 steps")
	data := b3.Recording_GetData(rec)
	testing.expect(t, data != nil, "recording data is nil")

	path := "test_vendor_box3d_recording.b3rec"
	cpath := strings.clone_to_cstring(path, context.temp_allocator)
	testing.expect(t, b3.SaveRecordingToFile(rec, cpath), "SaveRecordingToFile failed")

	loaded := b3.LoadRecordingFromFile(cpath)
	defer b3.DestroyRecording(loaded)
	testing.expect(t, b3.Recording_GetSize(loaded) == size, "loaded recording size differs from saved recording")

	_ = os.remove(path)

	player := b3.RecPlayer_Create(rawptr(data), size, 1)
	testing.expect(t, player != nil, "RecPlayer_Create returned nil")
	if player == nil {
		return
	}
	defer b3.RecPlayer_Destroy(player)

	info := b3.RecPlayer_GetInfo(player)
	testing.expect(t, info.frameCount == 8, "unexpected recorded frame count in RecPlayerInfo")
	testing.expect(t, b3.RecPlayer_GetFrameCount(player) == 8, "unexpected frame count")

	testing.expect(t, b3.RecPlayer_StepFrame(player), "StepFrame failed on the first frame")
	testing.expect(t, b3.RecPlayer_GetFrame(player) == 1, "player did not advance to frame 1")

	replay_world := b3.RecPlayer_GetWorldId(player)
	testing.expect(t, b3.World_IsValid(replay_world), "replay world is not valid")
	testing.expect(t, !b3.RecPlayer_HasDiverged(player), "replay diverged from the recording")
}

// Body_SetUserData round-trips through Body_GetUserData.
@(test)
test_body_user_data_round_trip :: proc(t: ^testing.T) {
	world_def := b3.DefaultWorldDef()
	world := b3.CreateWorld(world_def)
	defer b3.DestroyWorld(world)

	body_def := b3.DefaultBodyDef()
	body := b3.CreateBody(world, body_def)

	sentinel := 42
	b3.Body_SetUserData(body, &sentinel)
	testing.expect(t, b3.Body_GetUserData(body) == &sentinel, "Body_GetUserData did not return the pointer set with Body_SetUserData")
}
