#+build windows amd64, linux amd64, darwin arm64
package test_vendor_box3d

// Sensor event test based on #7177

import    "core:math/linalg"
import    "core:testing"
import b3 "vendor:box3d"

// --- PHYSICS COLLISION MASKS ---
Collision_Layer :: enum u64 {
	None       = 0,
	World      = 1 << 0, // 1
	Player     = 1 << 1, // 2
	NPC        = 1 << 2, // 4
	Projectile = 1 << 3, // 8
	Sensor     = 1 << 4, // 16
	All        = ~u64(0),
}

Entity_Type :: enum { 
	None, 
	Floor, 
	Player, 
	NPC, 
	Projectile,
}

Vector3 :: [3]f32

BoundingBox :: struct {
	min: Vector3,
	max: Vector3,
}

// --- FLAT ENTITY STRUCTURE ---
Entity :: struct {
	active:        bool,
	id:            int,
	type:          Entity_Type,
	birth:         f32,
	last_shot:     f32,

	body:          b3.BodyId,
	pos:           Vector3,
	speed:         f32,

	// Projectile specifics
	direction:     Vector3,
}

World :: struct {
	world_def:           b3.WorldDef,
	world_id:            b3.WorldId,

	entities:            [16]Entity,
	player_id:           int,
	clock:               f32,

	sensor_start_count:  int,
	player_hit_count:    int,
	bullet_fired_count:  int,
}

@(test)
test_sensors :: proc(t: ^testing.T) {
	world: World
	world.world_def = b3.DefaultWorldDef()
	world.world_id  = b3.CreateWorld(world.world_def)

	spawn_floor(&world)
	world.player_id = spawn_player(&world, {0, 0, 0})
	assert(world.player_id == 1)

	// Spawn 3 enemies on the plane
	spawn_enemy(&world, {-8, 0, -8})
	spawn_enemy(&world, { 8, 0, -8})
	spawn_enemy(&world, { 0, 0, -12})

	dt := f32(1.0) / 60.0
	for world.clock = f32(0); world.clock <= 60; world.clock += dt {
		update_entities(&world, dt)
		update_physics(&world, dt)
	}

	testing.expect_value(t, world.sensor_start_count, 228)
	testing.expect_value(t, world.bullet_fired_count, 117)
	testing.expect_value(t, world.player_hit_count,   114)

}

// --- SPAWNERS ---
allocate_entity :: proc(world: ^World, type: Entity_Type) -> (int, ^Entity) {
	for &e, i in world.entities {
		if !e.active {
			e = Entity{}
			e.active = true
			e.birth  = world.clock
			e.id     = i
			e.type   = type
			return i, &e
		}
	}
	return -1, nil
}

spawn_floor :: proc(world: ^World) {
	_, e := allocate_entity(world, .Floor)
	e.pos = {0, -0.5, 0}

	s: f32 = 50.0
	body_def := b3.DefaultBodyDef()
	body_def.type = .staticBody
	body_def.position = {0, -0.5, 0}
	e.body = b3.CreateBody(world.world_id, body_def)

	shape_def := b3.DefaultShapeDef()
	shape_def.filter.categoryBits = u64(Collision_Layer.World)
	shape_def.filter.maskBits = u64(Collision_Layer.All)

	hull := b3.MakeBoxHull(s, 0.5, s)
	_ = b3.CreateHullShape(e.body, shape_def, &hull.base)
}

spawn_player :: proc(world: ^World, pos: Vector3) -> int {
	idx, e := allocate_entity(world, .Player)

	width: f32 = .8
	height: f32 = 5.2
	half_w := width / 2.0   // 0.40
	half_h := height / 2.0  // 2.6
	radius := half_w        // 0.40
	
	center_pos := pos
	center_pos.y += half_h

	e.pos = center_pos
	e.speed = 15.0

	body_def := b3.DefaultBodyDef()
	body_def.type = .dynamicBody
	body_def.position = {center_pos.x, center_pos.y, center_pos.z}
	body_def.motionLocks.angularX = true
	body_def.motionLocks.angularY = true
	body_def.motionLocks.angularZ = true
	e.body = b3.CreateBody(world.world_id, body_def)

	// World Collider (Capsule)
	shape_def := b3.DefaultShapeDef()
	shape_def.filter.categoryBits = u64(Collision_Layer.Player)
	shape_def.filter.maskBits = u64(Collision_Layer.World) | u64(Collision_Layer.NPC)

	capsule := b3.Capsule{
		center1 = {0.0, half_h - radius, 0.0},
		center2 = {0.0, -half_h + radius, 0.0},
		radius = radius,
	}
	_ = b3.CreateCapsuleShape(e.body, shape_def, &capsule)

	// Sensor Hitbox (BoxHull)
	sensor_def := b3.DefaultShapeDef()
	sensor_def.filter.categoryBits = u64(Collision_Layer.Sensor)
	sensor_def.filter.maskBits = u64(Collision_Layer.Projectile) | u64(Collision_Layer.NPC)
	sensor_def.isSensor = true
	sensor_def.enableSensorEvents = true

	sensor_half: f32 = half_w
	sensor_hull := b3.MakeBoxHull(sensor_half, half_h, sensor_half)
	_ = b3.CreateHullShape(e.body, sensor_def, &sensor_hull.base)

	return idx
}

spawn_enemy :: proc(world: ^World, pos: Vector3) {
	_, e := allocate_entity(world, .NPC)

	width: f32 = 0.8
	height: f32 = 5.2
	half_w := width / 2.0
	half_h := height / 2.0
	
	center_pos := pos
	center_pos.y += half_h

	e.pos = center_pos

	body_def := b3.DefaultBodyDef()
	body_def.type = .kinematicBody
	body_def.position = {center_pos.x, center_pos.y, center_pos.z}
	e.body = b3.CreateBody(world.world_id, body_def)

	shape_def := b3.DefaultShapeDef()
	shape_def.filter.categoryBits = u64(Collision_Layer.NPC)
	shape_def.filter.maskBits = u64(Collision_Layer.World) | u64(Collision_Layer.Player) | u64(Collision_Layer.Sensor)

	capsule := b3.Capsule{
		center1 = {0.0, half_h - half_w, 0.0},
		center2 = {0.0, -half_h + half_w, 0.0},
		radius = half_w,
	}
	_ = b3.CreateCapsuleShape(e.body, shape_def, &capsule)
}

spawn_projectile :: proc(world: ^World, pos: Vector3, direction: Vector3) {
	_, e := allocate_entity(world, .Projectile)

	e.pos = pos
	e.direction = direction
	e.speed = 10.0

	half_ext: f32 = 0.5

	body_def := b3.DefaultBodyDef()
	body_def.type = .kinematicBody
	body_def.position = {pos.x, pos.y, pos.z}
	e.body = b3.CreateBody(world.world_id, body_def)

	shape_def := b3.DefaultShapeDef()
	shape_def.filter.categoryBits = u64(Collision_Layer.Projectile)
	shape_def.filter.maskBits = u64(Collision_Layer.Sensor)
	shape_def.isSensor = true 
	shape_def.enableSensorEvents = true

	bullet_hull := b3.MakeBoxHull(half_ext, half_ext, half_ext)
	_ = b3.CreateHullShape(e.body, shape_def, &bullet_hull.base)

	world.bullet_fired_count += 1
}

update_entities :: proc(world: ^World, dt: f32) {
	player_pos := world.entities[world.player_id].pos
		
	for &e in world.entities {
		if !e.active {
			continue
		}

		#partial switch e.type {
		case .NPC:
			if world.clock >= e.last_shot + 1.5 {
				pos := e.pos
				dir := linalg.normalize(player_pos - pos)
				spawn_projectile(world, pos, dir)
				e.last_shot = world.clock
			}

		case .Projectile:
			dir := linalg.normalize(e.direction)
			vel := b3.Vec3{dir.x * e.speed, dir.y * e.speed, dir.z * e.speed}
			b3.Body_SetLinearVelocity(e.body, vel)

			// Recycle old projectiles in case they missed
			if world.clock - e.birth > 5 {
				e.active = false
			}
		}
	}
}

update_physics :: proc(world: ^World, dt: f32) {
	b3.World_Step(world.world_id, dt, 4)
	sensor_events := b3.World_GetSensorEvents(world.world_id)

	world.sensor_start_count += int(sensor_events.beginCount)

	for i in 0..<sensor_events.beginCount {
		evt := sensor_events.beginEvents[i]
		body_a := b3.Shape_GetBody(evt.sensorShapeId)
		body_b := b3.Shape_GetBody(evt.visitorShapeId)

		ent_a := find_entity(world, body_a)
		ent_b := find_entity(world, body_b)

		if ent_a == nil || ent_b == nil {
			continue
		}

		if ent_a.type == .Player && ent_b.type == .Projectile {
			world.player_hit_count += 1
			ent_b.active = false
		}
	}
}

// --- UTILITIES ---
find_entity :: proc(world: ^World, body: b3.BodyId) -> ^Entity {
	for &e in world.entities {
		if e.active && e.body == body {
			return &e
		}
	}
	return nil
}