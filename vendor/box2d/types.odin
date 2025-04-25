package vendor_box2d

import "core:c"

// Task interface
// This is prototype for a Box2D task. Your task system is expected to invoke the Box2D task with these arguments.
// The task spans a range of the parallel-for: [startIndex, endIndex)
// The worker index must correctly identify each worker in the user thread pool, expected in [0, workerCount).
//	A worker must only exist on only one thread at a time and is analogous to the thread index.
// The task context is the context pointer sent from Box2D when it is enqueued.
//	The startIndex and endIndex are expected in the range [0, itemCount) where itemCount is the argument to b2EnqueueTaskCallback
// below. Box2D expects startIndex < endIndex and will execute a loop like this:
//
//	@code{.odin}
// 	for i in startIndex ..< endIndex {
//		DoWork()
//	}
//	@endcode
//	@ingroup world
TaskCallback :: #type proc "c" (startIndex, endIndex: i32, workerIndex: u32, taskContext: rawptr)


// These functions can be provided to Box2D to invoke a task system. These are designed to work well with enkiTS.
// Returns a pointer to the user's task object. May be nullptr. A nullptr indicates to Box2D that the work was executed
//	serially within the callback and there is no need to call b2FinishTaskCallback.
//	The itemCount is the number of Box2D work items that are to be partitioned among workers by the user's task system.
//	This is essentially a parallel-for. The minRange parameter is a suggestion of the minimum number of items to assign
//	per worker to reduce overhead. For example, suppose the task is small and that itemCount is 16. A minRange of 8 suggests
//	that your task system should split the work items among just two workers, even if you have more available.
//	In general the range [startIndex, endIndex) send to TaskCallback should obey:
//	endIndex - startIndex >= minRange
//	The exception of course is when itemCount < minRange.
//	@ingroup world
EnqueueTaskCallback :: #type proc "c" (task: TaskCallback, itemCount: i32, minRange: i32, taskContext: rawptr, userContext: rawptr) -> rawptr

// Finishes a user task object that wraps a Box2D task.
//	@ingroup world
FinishTaskCallback :: #type proc "c" (userTask: rawptr, userContext: rawptr)

// Optional friction mixing callback. This intentionally provides no context objects because this is called
// from a worker thread.
// @warning This function should not attempt to modify Box2D state or user application state.
// @ingroup world
FrictionCallback :: #type proc "c" (frictionA: f32, userMaterialIdA: i32, frictionB: f32, userMaterialIdB: i32)

// Optional restitution mixing callback. This intentionally provides no context objects because this is called
// from a worker thread.
// @warning This function should not attempt to modify Box2D state or user application state.
// @ingroup world
RestitutionCallback :: #type proc "c" (restitutionA: f32, userMaterialIdA: i32, restitutuionB: f32, userMaterialIdB: i32)

// Result from b2World_RayCastClosest
// @ingroup world
RayResult :: struct {
	shapeId:    ShapeId,
	point:      Vec2,
	normal:     Vec2,
	fraction:   f32,
	nodeVisits: i32,
	leafVisits: i32,
	hit:        bool,
}

// World definition used to create a simulation world.
// Must be initialized using b2DefaultWorldDef().
// @ingroup world
WorldDef :: struct {
	// Gravity vector. Box2D has no up-vector defined.
	gravity: Vec2,

	// Restitution speed threshold, usually in m/s. Collisions above this
	// speed have restitution applied (will bounce).
	restitutionThreshold: f32,

	// Threshold speed for hit events. Usually meters per second.
	hitEventThreshold: f32,

	// Contact stiffness. Cycles per second. Increasing this increases the speed of overlap recovery, but can introduce jitter.
	contactHertz: f32,

	// Contact bounciness. Non-dimensional. You can speed up overlap recovery by decreasing this with
	// the trade-off that overlap resolution becomes more energetic.
	contactDampingRatio: f32,

	// This parameter controls how fast overlap is resolved and usually has units of meters per second. This only
	// puts a cap on the resolution speed. The resolution speed is increased by increasing the hertz and/or
	// decreasing the damping ratio.
	maxContactPushSpeed: f32,

	// Joint stiffness. Cycles per second.
	jointHertz: f32,

	// Joint bounciness. Non-dimensional.
	jointDampingRatio: f32,

	// Maximum linear speed. Usually meters per second.
	maximumLinearSpeed: f32,

	// Optional mixing callback for friction. The default uses sqrt(frictionA * frictionB).
	frictionCallback: FrictionCallback,

	// Optional mixing callback for restitution. The default uses max(restitutionA, restitutionB).
	restitutionCallback: RestitutionCallback,

	// Can bodies go to sleep to improve performance
	enableSleep: bool,

	// Enable continuous collision
	enableContinuous: bool,

	// Number of workers to use with the provided task system. Box2D performs best when using only
	// performance cores and accessing a single L2 cache. Efficiency cores and hyper-threading provide
	// little benefit and may even harm performance.
	// @note Box2D does not create threads. This is the number of threads your applications has created
	// that you are allocating to b2World_Step.
	// @warning Do not modify the default value unless you are also providing a task system and providing
	// task callbacks (enqueueTask and finishTask).
	workerCount: i32,

	// Function to spawn tasks
	enqueueTask: EnqueueTaskCallback,

	// Function to finish a task
	finishTask: FinishTaskCallback,

	// User context that is provided to enqueueTask and finishTask
	userTaskContext: rawptr,

	// User data
	userData: rawptr,

	// Used internally to detect a valid definition. DO NOT SET.
	internalValue: i32,
}




// The body simulation type.
// Each body is one of these three types. The type determines how the body behaves in the simulation.
// @ingroup body
BodyType :: enum c.int {
	// zero mass, zero velocity, may be manually moved
	staticBody = 0,

	// zero mass, velocity set by user, moved by solver
	kinematicBody = 1,

	// positive mass, velocity determined by forces, moved by solver
	dynamicBody = 2,

}

// number of body types
bodyTypeCount :: len(BodyType)

// A body definition holds all the data needed to construct a rigid body.
// You can safely re-use body definitions. Shapes are added to a body after construction.
//	Body definitions are temporary objects used to bundle creation parameters.
// Must be initialized using b2DefaultBodyDef().
// @ingroup body
BodyDef :: struct {
	// The body type: static, kinematic, or dynamic.
	type: BodyType,

	// The initial world position of the body. Bodies should be created with the desired position.
	// @note Creating bodies at the origin and then moving them nearly doubles the cost of body creation, especially
	//	if the body is moved after shapes have been added.
	position: Vec2,

	// The initial world rotation of the body. Use b2MakeRot() if you have an angle.
	rotation: Rot,

	// The initial linear velocity of the body's origin. Usually in meters per second.
	linearVelocity: Vec2,

	// The initial angular velocity of the body. Radians per second.
	angularVelocity: f32,

	// Linear damping is used to reduce the linear velocity. The damping parameter
	// can be larger than 1 but the damping effect becomes sensitive to the
	// time step when the damping parameter is large.
	//	Generally linear damping is undesirable because it makes objects move slowly
	//	as if they are f32ing.
	linearDamping: f32,

	// Angular damping is used to reduce the angular velocity. The damping parameter
	// can be larger than 1.0f but the damping effect becomes sensitive to the
	// time step when the damping parameter is large.
	//	Angular damping can be use slow down rotating bodies.
	angularDamping: f32,

	// Scale the gravity applied to this body. Non-dimensional.
	gravityScale: f32,

	// Sleep speed threshold, default is 0.05 meters per second
	sleepThreshold: f32,

	// Optional body name for debugging. Up to 32 characters (excluding null termination)
	name: cstring,

	// Use this to store application specific body data.
	userData: rawptr,

	// Set this flag to false if this body should never fall asleep.
	enableSleep: bool,

	// Is this body initially awake or sleeping?
	isAwake: bool,

	// Should this body be prevented from rotating? Useful for characters.
	fixedRotation: bool,

	// Treat this body as high speed object that performs continuous collision detection
	// against dynamic and kinematic bodies, but not other bullet bodies.
	//	@warning Bullets should be used sparingly. They are not a solution for general dynamic-versus-dynamic
	//	continuous collision. They may interfere with joint constraints.
	isBullet: bool,

	// Used to disable a body. A disabled body does not move or collide.
	isEnabled: bool,

	// This allows this body to bypass rotational speed limits. Should only be used
	// for circular objects, like wheels.
	allowFastRotation: bool,

	// Used internally to detect a valid definition. DO NOT SET.
	internalValue: i32,
}


// This is used to filter collision on shapes. It affects shape-vs-shape collision
//	and shape-versus-query collision (such as b2World_CastRay).
// @ingroup shape
Filter :: struct {
	// The collision category bits. Normally you would just set one bit. The category bits should
	//	represent your application object types. For example:
	//	@code{.odin}
	//	My_Categories :: enum u64 {
	//		Static  = 0x00000001,
	//		Dynamic = 0x00000002,
	//		Debris  = 0x00000004,
	//		Player  = 0x00000008,
	//		// etc
	//	};
	//	@endcode
	//      Or use a bit_set.
	categoryBits: u64,

	// The collision mask bits. This states the categories that this
	// shape would accept for collision.
	//	For example, you may want your player to only collide with static objects
	//	and other players.
	//	@code{.odin}
	//	maskBits = u64(My_Categories.Static | My_Categories.Player);
	//	@endcode
	maskBits: u64,

	// Collision groups allow a certain group of objects to never collide (negative)
	// or always collide (positive). A group index of zero has no effect. Non-zero group filtering
	// always wins against the mask bits.
	//	For example, you may want ragdolls to collide with other ragdolls but you don't want
	//	ragdoll self-collision. In this case you would give each ragdoll a unique negative group index
	//	and apply that group index to all shapes on the ragdoll.
	groupIndex: i32,
}


// The query filter is used to filter collisions between queries and shapes. For example,
//	you may want a ray-cast representing a projectile to hit players and the static environment
//	but not debris.
// @ingroup shape
QueryFilter :: struct {
	// The collision category bits of this query. Normally you would just set one bit.
	categoryBits: u64,

	// The collision mask bits. This states the shape categories that this
	// query would accept for collision.
	maskBits: u64,
}


// Shape type
// @ingroup shape
ShapeType :: enum c.int {
	// A circle with an offset
	circleShape,

	// A capsule is an extruded circle
	capsuleShape,

	// A line segment
	segmentShape,

	// A convex polygon
	polygonShape,

	// A line segment owned by a chain shape
	chainSegmentShape,
}

// The number of shape types
shapeTypeCount :: len(ShapeType)

// Surface materials allow chain shapes to have per segment surface properties.
// @ingroup shape
SurfaceMaterial :: struct {
	// The Coulomb (dry) friction coefficient, usually in the range [0,1].
	friction: f32,

	// The coefficient of restitution (bounce) usually in the range [0,1].
	// https://en.wikipedia.org/wiki/Coefficient_of_restitution
	restitution: f32,

	// The rolling resistance usually in the range [0,1].
	rollingResistance: f32,

	// The tangent speed for conveyor belts
	tangentSpeed: f32,

	// User material identifier. This is passed with query results and to friction and restitution
	// combining functions. It is not used internally.
	userMaterialId: i32,

	// Custom debug draw color.
	customColor: u32,
}

// Used to create a shape.
// This is a temporary object used to bundle shape creation parameters. You may use
//	the same shape definition to create multiple shapes.
// Must be initialized using b2DefaultShapeDef().
// @ingroup shape
ShapeDef :: struct {
	// Use this to store application specific shape data.
	userData: rawptr,

	// The surface material for this shape.
	material: SurfaceMaterial,

	// The density, usually in kg/m^2.
	// This is not part of the surface material because this is for the interior, which may have
	// other considerations, such as being hollow. For example a wood barrel may be hollow or full of water.
	density: f32,

	// Collision filtering data.
	filter: Filter,

	// A sensor shape generates overlap events but never generates a collision response.
	// Sensors do not have continuous collision. Instead, use a ray or shape cast for those scenarios.
	// Sensors still contribute to the body mass if they have non-zero density.
	// @note Sensor events are disabled by default.
	// @see enableSensorEvents
	isSensor: bool,

	// Enable sensor events for this shape. This applies to sensors and non-sensors. False by default, even for sensors.
	enableSensorEvents: bool,

	// Enable contact events for this shape. Only applies to kinematic and dynamic bodies. Ignored for sensors. False by default.
	enableContactEvents: bool,

	// Enable hit events for this shape. Only applies to kinematic and dynamic bodies. Ignored for sensors. False by default.
	enableHitEvents: bool,

	// Enable pre-solve contact events for this shape. Only applies to dynamic bodies. These are expensive
	//	and must be carefully handled due to threading. Ignored for sensors.
	enablePreSolveEvents: bool,

	// When shapes are created they will scan the environment for collision the next time step. This can significantly slow down
	// static body creation when there are many static shapes.
	// This is flag is ignored for dynamic and kinematic shapes which always invoke contact creation.
	invokeContactCreation: bool,

	// Should the body update the mass properties when this shape is created. Default is true.
	updateBodyMass: bool,

	// Used internally to detect a valid definition. DO NOT SET.
	internalValue: i32,
}


// Used to create a chain of line segments. This is designed to eliminate ghost collisions with some limitations.
//	- chains are one-sided
//	- chains have no mass and should be used on static bodies
//	- chains have a counter-clockwise winding order (normal points right of segment direction)
//	- chains are either a loop or open
// - a chain must have at least 4 points
//	- the distance between any two points must be greater than B2_LINEAR_SLOP
//	- a chain shape should not self intersect (this is not validated)
//	- an open chain shape has NO COLLISION on the first and final edge
//	- you may overlap two open chains on their first three and/or last three points to get smooth collision
//	- a chain shape creates multiple line segment shapes on the body
// https://en.wikipedia.org/wiki/Polygonal_chain
// Must be initialized using b2DefaultChainDef().
//	@warning Do not use chain shapes unless you understand the limitations. This is an advanced feature.
// @ingroup shape
ChainDef :: struct {
	// Use this to store application specific shape data.
	userData: rawptr,

	// An array of at least 4 points. These are cloned and may be temporary.
	points: [^]Vec2 `fmt:"v,count"`,

	// The point count, must be 4 or more.
	count: i32,

	// Surface materials for each segment. These are cloned.
	materials: [^]SurfaceMaterial `fmt:"v,materialCount"`,

	// The material count. Must be 1 or count. This allows you to provide one
	// material for all segments or a unique material per segment.
	materialCount: i32,

	// Contact filtering data.
	filter: Filter,

	// Indicates a closed chain formed by connecting the first and last points
	isLoop: bool,

	// Enable sensors to detect this chain. False by default.
	enableSensorEvents: bool,

	// Used internally to detect a valid definition. DO NOT SET.
	internalValue: i32,
}


//! @cond
// Profiling data. Times are in milliseconds.
Profile :: struct {
	step:                f32,
	pairs:               f32,
	collide:             f32,
	solve:               f32,
	mergeIslands:        f32,
	prepareStages:       f32,
	solveConstraints:    f32,
	prepareConstraints:  f32,
	integrateVelocities: f32,
	warmStart:           f32,
	solveImpulses:       f32,
	integratePositions:  f32,
	relaxImpulses:       f32,
	applyRestitution:    f32,
	storeImpulses:       f32,
	splitIslands:        f32,
	transforms:          f32,
	hitEvents:           f32,
	refit:               f32,
	bullets:             f32,
	sleepIslands:        f32,
	sensors:             f32,
}

// Counters that give details of the simulation size.
Counters :: struct {
	bodyCount:        i32,
	shapeCount:       i32,
	contactCount:     i32,
	jointCount:       i32,
	islandCount:      i32,
	stackUsed:        i32,
	staticTreeHeight: i32,
	treeHeight:       i32,
	byteCount:        i32,
	taskCount:        i32,
	colorCounts:      [12]i32,
}
//! @endcond

// Joint type enumeration
//
// This is useful because all joint types use b2JointId and sometimes you
// want to get the type of a joint.
// @ingroup joint
JointType :: enum c.int {
	distanceJoint,
	filterJoint,
	motorJoint,
	mouseJoint,
	prismaticJoint,
	revoluteJoint,
	weldJoint,
	wheelJoint,
}

// Distance joint definition
//
// This requires defining an anchor point on both
// bodies and the non-zero distance of the distance joint. The definition uses
// local anchor points so that the initial configuration can violate the
// constraint slightly. This helps when saving and loading a game.
// @ingroup distance_joint
DistanceJointDef :: struct {
	// The first attached body
	bodyIdA: BodyId,

	// The second attached body
	bodyIdB: BodyId,

	// The local anchor point relative to bodyA's origin
	localAnchorA: Vec2,

	// The local anchor point relative to bodyB's origin
	localAnchorB: Vec2,

	// The rest length of this joint. Clamped to a stable minimum value.
	length: f32,

	// Enable the distance constraint to behave like a spring. If false
	//	then the distance joint will be rigid, overriding the limit and motor.
	enableSpring: bool,

	// The spring linear stiffness Hertz, cycles per second
	hertz: f32,

	// The spring linear damping ratio, non-dimensional
	dampingRatio: f32,

	// Enable/disable the joint limit
	enableLimit: bool,

	// Minimum length. Clamped to a stable minimum value.
	minLength: f32,

	// Maximum length. Must be greater than or equal to the minimum length.
	maxLength: f32,

	// Enable/disable the joint motor
	enableMotor: bool,

	// The maximum motor force, usually in newtons
	maxMotorForce: f32,

	// The desired motor speed, usually in meters per second
	motorSpeed: f32,

	// Set this flag to true if the attached bodies should collide
	collideConnected: bool,

	// User data pointer
	userData: rawptr,

	// Used internally to detect a valid definition. DO NOT SET.
	internalValue: i32,
}


// A motor joint is used to control the relative motion between two bodies
//
// A typical usage is to control the movement of a dynamic body with respect to the ground.
// @ingroup motor_joint
MotorJointDef :: struct {
	// The first attached body
	bodyIdA: BodyId,

	// The second attached body
	bodyIdB: BodyId,

	// Position of bodyB minus the position of bodyA, in bodyA's frame
	linearOffset: Vec2,

	// The bodyB angle minus bodyA angle in radians
	angularOffset: f32,

	// The maximum motor force in newtons
	maxForce: f32,

	// The maximum motor torque in newton-meters
	maxTorque: f32,

	// Position correction factor in the range [0,1]
	correctionFactor: f32,

	// Set this flag to true if the attached bodies should collide
	collideConnected: bool,

	// User data pointer
	userData: rawptr,

	// Used internally to detect a valid definition. DO NOT SET.
	internalValue: i32,
}


// A mouse joint is used to make a point on a body track a specified world point.
//
// This a soft constraint and allows the constraint to stretch without
// applying huge forces. This also applies rotation constraint heuristic to improve control.
// @ingroup mouse_joint
MouseJointDef :: struct {
	// The first attached body. This is assumed to be static.
	bodyIdA: BodyId,

	// The second attached body.
	bodyIdB: BodyId,

	// The initial target point in world space
	target: Vec2,

	// Stiffness in hertz
	hertz: f32,

	// Damping ratio, non-dimensional
	dampingRatio: f32,

	// Maximum force, typically in newtons
	maxForce: f32,

	// Set this flag to true if the attached bodies should collide.
	collideConnected: bool,

	// User data pointer
	userData: rawptr,

	// Used internally to detect a valid definition. DO NOT SET.
	internalValue: i32,
}

// A filter joint is used to disable collision between two specific bodies.
//
// @ingroup filter_joint
FilterJointDef :: struct {
	/// The first attached body.
	bodyIdA: BodyId,

	/// The second attached body.
	bodyIdB: BodyId,

	/// User data pointer
	userData: rawptr,

	/// Used internally to detect a valid definition. DO NOT SET.
	internalValue: i32,
}

// Prismatic joint definition
//
// This requires defining a line of motion using an axis and an anchor point.
// The definition uses local anchor points and a local axis so that the initial
// configuration can violate the constraint slightly. The joint translation is zero
// when the local anchor points coincide in world space.
// @ingroup prismatic_joint
PrismaticJointDef :: struct {
	// The first attached body
	bodyIdA: BodyId,

	// The second attached body
	bodyIdB: BodyId,

	// The local anchor point relative to bodyA's origin
	localAnchorA: Vec2,

	// The local anchor point relative to bodyB's origin
	localAnchorB: Vec2,

	// The local translation unit axis in bodyA
	localAxisA: Vec2,

	// The constrained angle between the bodies: bodyB_angle - bodyA_angle
	referenceAngle: f32,

	// Enable a linear spring along the prismatic joint axis
	enableSpring: bool,

	// The spring stiffness Hertz, cycles per second
	hertz: f32,

	// The spring damping ratio, non-dimensional
	dampingRatio: f32,

	// Enable/disable the joint limit
	enableLimit: bool,

	// The lower translation limit
	lowerTranslation: f32,

	// The upper translation limit
	upperTranslation: f32,

	// Enable/disable the joint motor
	enableMotor: bool,

	// The maximum motor force, typically in newtons
	maxMotorForce: f32,

	// The desired motor speed, typically in meters per second
	motorSpeed: f32,

	// Set this flag to true if the attached bodies should collide
	collideConnected: bool,

	// User data pointer
	userData: rawptr,

	// Used internally to detect a valid definition. DO NOT SET.
	internalValue: i32,
}


// Revolute joint definition
//
// This requires defining an anchor point where the bodies are joined.
// The definition uses local anchor points so that the
// initial configuration can violate the constraint slightly. You also need to
// specify the initial relative angle for joint limits. This helps when saving
// and loading a game.
// The local anchor points are measured from the body's origin
// rather than the center of mass because:
// 1. you might not know where the center of mass will be
// 2. if you add/remove shapes from a body and recompute the mass, the joints will be broken
// @ingroup revolute_joint
RevoluteJointDef :: struct {
	// The first attached body
	bodyIdA: BodyId,

	// The second attached body
	bodyIdB: BodyId,

	// The local anchor point relative to bodyA's origin
	localAnchorA: Vec2,

	// The local anchor point relative to bodyB's origin
	localAnchorB: Vec2,

	// The bodyB angle minus bodyA angle in the reference state (radians).
	// This defines the zero angle for the joint limit.
	referenceAngle: f32,

	// Enable a rotational spring on the revolute hinge axis
	enableSpring: bool,

	// The spring stiffness Hertz, cycles per second
	hertz: f32,

	// The spring damping ratio, non-dimensional
	dampingRatio: f32,

	// A flag to enable joint limits
	enableLimit: bool,

	// The lower angle for the joint limit in radians. Minimum of -0.95*pi radians.
	lowerAngle: f32,

	// The upper angle for the joint limit in radians. Maximum of 0.95*pi radians.
	upperAngle: f32,

	// A flag to enable the joint motor
	enableMotor: bool,

	// The maximum motor torque, typically in newton-meters
	maxMotorTorque: f32,

	// The desired motor speed in radians per second
	motorSpeed: f32,

	// Scale the debug draw
	drawSize: f32,

	// Set this flag to true if the attached bodies should collide
	collideConnected: bool,

	// User data pointer
	userData: rawptr,

	// Used internally to detect a valid definition. DO NOT SET.
	internalValue: i32,
}


// Weld joint definition
//
// A weld joint connect to bodies together rigidly. This constraint provides springs to mimic
//	soft-body simulation.
// @note The approximate solver in Box2D cannot hold many bodies together rigidly
// @ingroup weld_joint
WeldJointDef :: struct {
	// The first attached body
	bodyIdA: BodyId,

	// The second attached body
	bodyIdB: BodyId,

	// The local anchor point relative to bodyA's origin
	localAnchorA: Vec2,

	// The local anchor point relative to bodyB's origin
	localAnchorB: Vec2,

	// The bodyB angle minus bodyA angle in the reference state (radians)
	referenceAngle: f32,

	// Linear stiffness expressed as Hertz (cycles per second). Use zero for maximum stiffness.
	linearHertz: f32,

	// Angular stiffness as Hertz (cycles per second). Use zero for maximum stiffness.
	angularHertz: f32,

	// Linear damping ratio, non-dimensional. Use 1 for critical damping.
	linearDampingRatio: f32,

	// Linear damping ratio, non-dimensional. Use 1 for critical damping.
	angularDampingRatio: f32,

	// Set this flag to true if the attached bodies should collide
	collideConnected: bool,

	// User data pointer
	userData: rawptr,

	// Used internally to detect a valid definition. DO NOT SET.
	internalValue: i32,
}


// Wheel joint definition
//
// This requires defining a line of motion using an axis and an anchor point.
// The definition uses local  anchor points and a local axis so that the initial
// configuration can violate the constraint slightly. The joint translation is zero
// when the local anchor points coincide in world space.
// @ingroup wheel_joint
WheelJointDef :: struct {
	// The first attached body
	bodyIdA: BodyId,

	// The second attached body
	bodyIdB: BodyId,

	// The local anchor point relative to bodyA's origin
	localAnchorA: Vec2,

	// The local anchor point relative to bodyB's origin
	localAnchorB: Vec2,

	// The local translation unit axis in bodyA
	localAxisA: Vec2,

	// Enable a linear spring along the local axis
	enableSpring: bool,

	// Spring stiffness in Hertz
	hertz: f32,

	// Spring damping ratio, non-dimensional
	dampingRatio: f32,

	// Enable/disable the joint linear limit
	enableLimit: bool,

	// The lower translation limit
	lowerTranslation: f32,

	// The upper translation limit
	upperTranslation: f32,

	// Enable/disable the joint rotational motor
	enableMotor: bool,

	// The maximum motor torque, typically in newton-meters
	maxMotorTorque: f32,

	// The desired motor speed in radians per second
	motorSpeed: f32,

	// Set this flag to true if the attached bodies should collide
	collideConnected: bool,

	// User data pointer
	userData: rawptr,

	// Used internally to detect a valid definition. DO NOT SET.
	internalValue: i32,
}

// The explosion definition is used to configure options for explosions. Explosions
// consider shape geometry when computing the impulse.
// @ingroup world
ExplosionDef :: struct {
	/// Mask bits to filter shapes
	maskBits: u64,

	/// The center of the explosion in world space
	position: Vec2,

	/// The radius of the explosion
	radius: f32,

	/// The falloff distance beyond the radius. Impulse is reduced to zero at this distance.
	falloff: f32,

	/// Impulse per unit length. This applies an impulse according to the shape perimeter that
	/// is facing the explosion. Explosions only apply to circles, capsules, and polygons. This
	/// may be negative for implosions.
	impulsePerLength: f32,
}

/**
 * @defgroup events Events
 * World event types.
 *
 * Events are used to collect events that occur during the world time step. These events
 * are then available to query after the time step is complete. This is preferable to callbacks
 * because Box2D uses multithreaded simulation.
 *
 * Also when events occur in the simulation step it may be problematic to modify the world, which is
 * often what applications want to do when events occur.
 *
 * With event arrays, you can scan the events in a loop and modify the world. However, you need to be careful
 * that some event data may become invalid. There are several samples that show how to do this safely.
 *
 * @{
 */

// A begin touch event is generated when a shape starts to overlap a sensor shape.
SensorBeginTouchEvent :: struct {
	// The id of the sensor shape
	sensorShapeId: ShapeId,

	// The id of the dynamic shape that began touching the sensor shape
	visitorShapeId: ShapeId,
}

// An end touch event is generated when a shape stops overlapping a sensor shape.
// These include things like setting the transform, destroying a body or shape, or changing
// a filter. You will also get an end event if the sensor or visitor are destroyed.
// Therefore you should always confirm the shape id is valid using b2Shape_IsValid.
SensorEndTouchEvent :: struct {
	// The id of the sensor shape
	// @warning this shape may have been destroyed
	// @see b2Shape_IsValid
	sensorShapeId: ShapeId,

	// The id of the dynamic shape that stopped touching the sensor shape
	// @warning this shape may have been destroyed
	// @see b2Shape_IsValid
	visitorShapeId: ShapeId,
}

// Sensor events are buffered in the Box2D world and are available
//	as begin/end overlap event arrays after the time step is complete.
//	Note: these may become invalid if bodies and/or shapes are destroyed
SensorEvents :: struct {
	// Array of sensor begin touch events
	beginEvents: [^]SensorBeginTouchEvent `fmt:"v,beginCount"`,

	// Array of sensor end touch events
	endEvents: [^]SensorEndTouchEvent `fmt:"v,endCount"`,

	// The number of begin touch events
	beginCount: i32,

	// The number of end touch events
	endCount: i32,
}

// A begin touch event is generated when two shapes begin touching.
ContactBeginTouchEvent :: struct {
	// Id of the first shape
	shapeIdA: ShapeId,

	// Id of the second shape
	shapeIdB: ShapeId,

	// The initial contact manifold. This is recorded before the solver is called,
	// so all the impulses will be zero.
	manifold: Manifold,
}

// An end touch event is generated when two shapes stop touching.
// You will get an end event if you do anything that destroys contacts previous to the last
// world step. These include things like setting the transform, destroying a body
// or shape, or changing a filter or body type.
ContactEndTouchEvent :: struct {
	// Id of the first shape
	// @warning this shape may have been destroyed
	// @see b2Shape_IsValid
	shapeIdA: ShapeId,

	// Id of the second shape
	// @warning this shape may have been destroyed
	// @see b2Shape_IsValid
	shapeIdB: ShapeId,
}

// A hit touch event is generated when two shapes collide with a speed faster than the hit speed threshold.
ContactHitEvent :: struct {
	// Id of the first shape
	shapeIdA: ShapeId,

	// Id of the second shape
	shapeIdB: ShapeId,

	// Point where the shapes hit
	point: Vec2,

	// Normal vector pointing from shape A to shape B
	normal: Vec2,

	// The speed the shapes are approaching. Always positive. Typically in meters per second.
	approachSpeed: f32,
}

// Contact events are buffered in the Box2D world and are available
//	as event arrays after the time step is complete.
//	Note: these may become invalid if bodies and/or shapes are destroyed
ContactEvents :: struct {
	// Array of begin touch events
	beginEvents: [^]ContactBeginTouchEvent `fmt:"v,beginCount"`,

	// Array of end touch events
	endEvents: [^]ContactEndTouchEvent `fmt:"v,endCount"`,

	// Array of hit events
	hitEvents: [^]ContactHitEvent `fmt:"v,hitCount"`,

	// Number of begin touch events
	beginCount: i32,

	// Number of end touch events
	endCount: i32,

	// Number of hit events
	hitCount: i32,
}

// Body move events triggered when a body moves.
// Triggered when a body moves due to simulation. Not reported for bodies moved by the user.
// This also has a flag to indicate that the body went to sleep so the application can also
// sleep that actor/entity/object associated with the body.
// On the other hand if the flag does not indicate the body went to sleep then the application
// can treat the actor/entity/object associated with the body as awake.
//	This is an efficient way for an application to update game object transforms rather than
//	calling functions such as b2Body_GetTransform() because this data is delivered as a contiguous array
//	and it is only populated with bodies that have moved.
//	@note If sleeping is disabled all dynamic and kinematic bodies will trigger move events.
BodyMoveEvent :: struct {
	transform:  Transform,
	bodyId:     BodyId,
	userData:   rawptr,
	fellAsleep: bool,
}

// Body events are buffered in the Box2D world and are available
//	as event arrays after the time step is complete.
//	Note: this date becomes invalid if bodies are destroyed
BodyEvents :: struct {
	// Array of move events
	moveEvents: [^]BodyMoveEvent `fmt:"v,moveCount"`,

	// Number of move events
	moveCount: i32,

}

// The contact data for two shapes. By convention the manifold normal points
//	from shape A to shape B.
//	@see b2Shape_GetContactData() and b2Body_GetContactData()
ContactData :: struct {
	shapeIdA: ShapeId,
	shapeIdB: ShapeId,
	manifold: Manifold,
}

/**@}*/

// Prototype for a contact filter callback.
// This is called when a contact pair is considered for collision. This allows you to
//	perform custom logic to prevent collision between shapes. This is only called if
//	one of the two shapes has custom filtering enabled. @see b2ShapeDef.
// Notes:
//	- this function must be thread-safe
//	- this is only called if one of the two shapes has enabled custom filtering
// - this is called only for awake dynamic bodies
//	Return false if you want to disable the collision
//	@warning Do not attempt to modify the world inside this callback
//	@ingroup world
CustomFilterFcn :: #type proc "c" (shapeIdA, shapeIdB: ShapeId, ctx: rawptr) -> bool

// Prototype for a pre-solve callback.
// This is called after a contact is updated. This allows you to inspect a
// contact before it goes to the solver. If you are careful, you can modify the
// contact manifold (e.g. modify the normal).
// Notes:
//	- this function must be thread-safe
//	- this is only called if the shape has enabled pre-solve events
// - this is called only for awake dynamic bodies
// - this is not called for sensors
// - the supplied manifold has impulse values from the previous step
//	Return false if you want to disable the contact this step
//	@warning Do not attempt to modify the world inside this callback
//	@ingroup world
PreSolveFcn :: #type proc "c" (shapeIdA, shapeIdB: ShapeId, manifold: ^Manifold, ctx: rawptr) -> bool

// Prototype callback for overlap queries.
// Called for each shape found in the query.
// @see b2World_QueryAABB
// @return false to terminate the query.
//	@ingroup world
OverlapResultFcn :: #type proc "c" (shapeId: ShapeId, ctx: rawptr) -> bool

// Prototype callback for ray casts.
// Called for each shape found in the query. You control how the ray cast
// proceeds by returning a f32:
// return -1: ignore this shape and continue
// return 0: terminate the ray cast
// return fraction: clip the ray to this point
// return 1: don't clip the ray and continue
// @param shapeId the shape hit by the ray
// @param point the point of initial intersection
// @param normal the normal vector at the point of intersection
// @param fraction the fraction along the ray at the point of intersection
//	@param context the user context
// @return -1 to filter, 0 to terminate, fraction to clip the ray for closest hit, 1 to continue
// @see b2World_CastRay
//	@ingroup world
CastResultFcn :: #type proc "c" (shapeId: ShapeId, point: Vec2, normal: Vec2, fraction: f32, ctx: rawptr) -> f32

// Used to collect collision planes for character movers.
// Return true to continue gathering planes.
PlaneResultFcn :: #type proc "c" (shapeId: ShapeId, plane: ^PlaneResult, ctx: rawptr) -> bool

// These colors are used for debug draw and mostly match the named SVG colors.
// See https://www.rapidtables.com/web/color/index.html
// https://johndecember.com/html/spec/colorsvg.html
// https://upload.wikimedia.org/wikipedia/commons/2/2b/SVG_Recognized_color_keyword_names.svg
HexColor :: enum c.int {
	AliceBlue            = 0xF0F8FF,
	AntiqueWhite         = 0xFAEBD7,
	Aqua                 = 0x00FFFF,
	Aquamarine           = 0x7FFFD4,
	Azure                = 0xF0FFFF,
	Beige                = 0xF5F5DC,
	Bisque               = 0xFFE4C4,
	Black                = 0x000000,
	BlanchedAlmond       = 0xFFEBCD,
	Blue                 = 0x0000FF,
	BlueViolet           = 0x8A2BE2,
	Brown                = 0xA52A2A,
	Burlywood            = 0xDEB887,
	CadetBlue            = 0x5F9EA0,
	Chartreuse           = 0x7FFF00,
	Chocolate            = 0xD2691E,
	Coral                = 0xFF7F50,
	CornflowerBlue       = 0x6495ED,
	Cornsilk             = 0xFFF8DC,
	Crimson              = 0xDC143C,
	Cyan                 = 0x00FFFF,
	DarkBlue             = 0x00008B,
	DarkCyan             = 0x008B8B,
	DarkGoldenRod        = 0xB8860B,
	DarkGray             = 0xA9A9A9,
	DarkGreen            = 0x006400,
	DarkKhaki            = 0xBDB76B,
	DarkMagenta          = 0x8B008B,
	DarkOliveGreen       = 0x556B2F,
	DarkOrange           = 0xFF8C00,
	DarkOrchid           = 0x9932CC,
	DarkRed              = 0x8B0000,
	DarkSalmon           = 0xE9967A,
	DarkSeaGreen         = 0x8FBC8F,
	DarkSlateBlue        = 0x483D8B,
	DarkSlateGray        = 0x2F4F4F,
	DarkTurquoise        = 0x00CED1,
	DarkViolet           = 0x9400D3,
	DeepPink             = 0xFF1493,
	DeepSkyBlue          = 0x00BFFF,
	DimGray              = 0x696969,
	DodgerBlue           = 0x1E90FF,
	FireBrick            = 0xB22222,
	FloralWhite          = 0xFFFAF0,
	ForestGreen          = 0x228B22,
	Fuchsia              = 0xFF00FF,
	Gainsboro            = 0xDCDCDC,
	GhostWhite           = 0xF8F8FF,
	Gold                 = 0xFFD700,
	GoldenRod            = 0xDAA520,
	Gray                 = 0x808080,
	Green                = 0x008000,
	GreenYellow          = 0xADFF2F,
	HoneyDew             = 0xF0FFF0,
	HotPink              = 0xFF69B4,
	IndianRed            = 0xCD5C5C,
	Indigo               = 0x4B0082,
	Ivory                = 0xFFFFF0,
	Khaki                = 0xF0E68C,
	Lavender             = 0xE6E6FA,
	LavenderBlush        = 0xFFF0F5,
	LawnGreen            = 0x7CFC00,
	LemonChiffon         = 0xFFFACD,
	LightBlue            = 0xADD8E6,
	LightCoral           = 0xF08080,
	LightCyan            = 0xE0FFFF,
	LightGoldenRodYellow = 0xFAFAD2,
	LightGray            = 0xD3D3D3,
	LightGreen           = 0x90EE90,
	LightPink            = 0xFFB6C1,
	LightSalmon          = 0xFFA07A,
	LightSeaGreen        = 0x20B2AA,
	LightSkyBlue         = 0x87CEFA,
	LightSlateGray       = 0x778899,
	LightSteelBlue       = 0xB0C4DE,
	LightYellow          = 0xFFFFE0,
	Lime                 = 0x00FF00,
	LimeGreen            = 0x32CD32,
	Linen                = 0xFAF0E6,
	Magenta              = 0xFF00FF,
	Maroon               = 0x800000,
	MediumAquaMarine     = 0x66CDAA,
	MediumBlue           = 0x0000CD,
	MediumOrchid         = 0xBA55D3,
	MediumPurple         = 0x9370DB,
	MediumSeaGreen       = 0x3CB371,
	MediumSlateBlue      = 0x7B68EE,
	MediumSpringGreen    = 0x00FA9A,
	MediumTurquoise      = 0x48D1CC,
	MediumVioletRed      = 0xC71585,
	MidnightBlue         = 0x191970,
	MintCream            = 0xF5FFFA,
	MistyRose            = 0xFFE4E1,
	Moccasin             = 0xFFE4B5,
	NavajoWhite          = 0xFFDEAD,
	Navy                 = 0x000080,
	OldLace              = 0xFDF5E6,
	Olive                = 0x808000,
	OliveDrab            = 0x6B8E23,
	Orange               = 0xFFA500,
	OrangeRed            = 0xFF4500,
	Orchid               = 0xDA70D6,
	PaleGoldenRod        = 0xEEE8AA,
	PaleGreen            = 0x98FB98,
	PaleTurquoise        = 0xAFEEEE,
	PaleVioletRed        = 0xDB7093,
	PapayaWhip           = 0xFFEFD5,
	PeachPuff            = 0xFFDAB9,
	Peru                 = 0xCD853F,
	Pink                 = 0xFFC0CB,
	Plum                 = 0xDDA0DD,
	PowderBlue           = 0xB0E0E6,
	Purple               = 0x800080,
	RebeccaPurple        = 0x663399,
	Red                  = 0xFF0000,
	RosyBrown            = 0xBC8F8F,
	RoyalBlue            = 0x4169E1,
	SaddleBrown          = 0x8B4513,
	Salmon               = 0xFA8072,
	SandyBrown           = 0xF4A460,
	SeaGreen             = 0x2E8B57,
	SeaShell             = 0xFFF5EE,
	Sienna               = 0xA0522D,
	Silver               = 0xC0C0C0,
	SkyBlue              = 0x87CEEB,
	SlateBlue            = 0x6A5ACD,
	SlateGray            = 0x708090,
	Snow                 = 0xFFFAFA,
	SpringGreen          = 0x00FF7F,
	SteelBlue            = 0x4682B4,
	Tan                  = 0xD2B48C,
	Teal                 = 0x008080,
	Thistle              = 0xD8BFD8,
	Tomato               = 0xFF6347,
	Turquoise            = 0x40E0D0,
	Violet               = 0xEE82EE,
	Wheat                = 0xF5DEB3,
	White                = 0xFFFFFF,
	WhiteSmoke           = 0xF5F5F5,
	Yellow               = 0xFFFF00,
	YellowGreen          = 0x9ACD32,
	Box2DRed             = 0xDC3132,
	Box2DBlue            = 0x30AEBF,
	Box2DGreen           = 0x8CC924,
	Box2DYellow          = 0xFFEE8C,
}

// This struct holds callbacks you can implement to draw a Box2D world.
//	@ingroup world
DebugDraw :: struct {
	// Draw a closed polygon provided in CCW order.
	DrawPolygonFcn: proc "c" (vertices: [^]Vec2, vertexCount: c.int, color: HexColor, ctx: rawptr),

	// Draw a solid closed polygon provided in CCW order.
	DrawSolidPolygonFcn: proc "c" (transform: Transform, vertices: [^]Vec2, vertexCount: c.int, radius: f32, colr: HexColor, ctx: rawptr ),

	// Draw a circle.
	DrawCircleFcn: proc "c" (center: Vec2, radius: f32, color: HexColor, ctx: rawptr),

	// Draw a solid circle.
	DrawSolidCircleFcn: proc "c" (transform: Transform, radius: f32, color: HexColor, ctx: rawptr),

	// Draw a solid capsule.
	DrawSolidCapsuleFcn: proc "c" (p1, p2: Vec2, radius: f32, color: HexColor, ctx: rawptr),

	// Draw a line segment.
	DrawSegmentFcn: proc "c" (p1, p2: Vec2, color: HexColor, ctx: rawptr),

	// Draw a transform. Choose your own length scale.
	DrawTransformFcn: proc "c" (transform: Transform, ctx: rawptr),

	// Draw a point.
	DrawPointFcn: proc "c" (p: Vec2, size: f32, color: HexColor, ctx: rawptr),

	// Draw a string in world space.
	DrawStringFcn: proc "c" (p: Vec2, s: cstring, color: HexColor, ctx: rawptr),

	// Bounds to use if restricting drawing to a rectangular region
	drawingBounds: AABB,

	// Option to restrict drawing to a rectangular region. May suffer from unstable depth sorting.
	useDrawingBounds: bool,

	// Option to draw shapes
	drawShapes: bool,

	// Option to draw joints
	drawJoints: bool,

	// Option to draw additional information for joints
	drawJointExtras: bool,

	// Option to draw the bounding boxes for shapes
	drawBounds: bool,

	// Option to draw the mass and center of mass of dynamic bodies
	drawMass: bool,

	// Option to draw body names
	drawBodyNames: bool,

	// Option to draw contact points
	drawContacts: bool,

	// Option to visualize the graph coloring used for contacts and joints
	drawGraphColors: bool,

	// Option to draw contact normals
	drawContactNormals: bool,

	// Option to draw contact normal impulses
	drawContactImpulses: bool,

	// Option to draw contact feature ids
	drawContactFeatures: bool,

	// Option to draw contact friction impulses
	drawFrictionImpulses: bool,

	// Option to draw islands as bounding boxes
	drawIslands: bool,

	// User context that is passed as an argument to drawing callback functions
	userContext: rawptr,
}
