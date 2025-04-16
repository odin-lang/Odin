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

// Result from b2World_RayCastClosest
// @ingroup world
RayResult :: struct {
	shapeId:  ShapeId,
	point:    Vec2,
	normal:   Vec2,
	fraction: f32,
	hit:      bool,
}

// World definition used to create a simulation world.
// Must be initialized using b2DefaultWorldDef().
// @ingroup world
WorldDef :: struct {
	// Gravity vector. Box2D has no up-vector defined.
	gravity: Vec2,

	// Restitution velocity threshold, usually in m/s. Collisions above this
	// speed have restitution applied (will bounce).
	restitutionThreshold: f32,

	// This parameter controls how fast overlap is resolved and has units of meters per second
	contactPushoutVelocity: f32,

	// Threshold velocity for hit events. Usually meters per second.
	hitEventThreshold: f32,

	// Contact stiffness. Cycles per second.
	contactHertz: f32,

	// Contact bounciness. Non-dimensional.
	contactDampingRatio: f32,

	// Joint stiffness. Cycles per second.
	jointHertz: f32,

	// Joint bounciness. Non-dimensional.
	jointDampingRatio: f32,

	// Can bodies go to sleep to improve performance
	enableSleep: bool,

	// Enable continuous collision
	enableContinous: bool,

	// Number of workers to use with the provided task system. Box2D performs best when using only
	//	performance cores and accessing a single L2 cache. Efficiency cores and hyper-threading provide
	//	little benefit and may even harm performance.
	workerCount: i32,

	// Function to spawn tasks
	enqueueTask: EnqueueTaskCallback,

	// Function to finish a task
	finishTask: FinishTaskCallback,

	// User context that is provided to enqueueTask and finishTask
	userTaskContext: rawptr,

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

	// The initial linear velocity of the body's origin. Typically in meters per second.
	linearVelocity: Vec2,

	// The initial angular velocity of the body. Radians per second.
	angularVelocity: f32,

	// Linear damping is use to reduce the linear velocity. The damping parameter
	// can be larger than 1 but the damping effect becomes sensitive to the
	// time step when the damping parameter is large.
	//	Generally linear damping is undesirable because it makes objects move slowly
	//	as if they are f32ing.
	linearDamping: f32,

	// Angular damping is use to reduce the angular velocity. The damping parameter
	// can be larger than 1.0f but the damping effect becomes sensitive to the
	// time step when the damping parameter is large.
	//	Angular damping can be use slow down rotating bodies.
	angularDamping: f32,

	// Scale the gravity applied to this body. Non-dimensional.
	gravityScale: f32,

	// Sleep velocity threshold, default is 0.05 meter per second
	sleepThreshold: f32,

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

	// Automatically compute mass and related properties on this body from shapes.
	// Triggers whenever a shape is add/removed/changed. Default is true.
	automaticMass: bool,

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
	//	My_Categories :: enum u32 {
	//		Static  = 0x00000001,
	//		Dynamic = 0x00000002,
	//		Debris  = 0x00000004,
	//		Player  = 0x00000008,
	//		// etc
	//	};
	//	@endcode
	//      Or use a bit_set.
	categoryBits: u32,

	// The collision mask bits. This states the categories that this
	// shape would accept for collision.
	//	For example, you may want your player to only collide with static objects
	//	and other players.
	//	@code{.odin}
	//	maskBits = u32(My_Categories.Static | My_Categories.Player);
	//	@endcode
	maskBits: u32,

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
	categoryBits: u32,

	// The collision mask bits. This states the shape categories that this
	// query would accept for collision.
	maskBits: u32,
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

	// A smooth segment owned by a chain shape
	smoothSegmentShape,
}

// The number of shape types
shapeTypeCount :: len(ShapeType)

// Used to create a shape.
// This is a temporary object used to bundle shape creation parameters. You may use
//	the same shape definition to create multiple shapes.
// Must be initialized using b2DefaultShapeDef().
// @ingroup shape
ShapeDef :: struct {
	// Use this to store application specific shape data.
	userData: rawptr,

	// The Coulomb (dry) friction coefficient, usually in the range [0,1].
	friction: f32,

	// The restitution (bounce) usually in the range [0,1].
	restitution: f32,

	// The density, usually in kg/m^2.
	density: f32,

	// Collision filtering data.
	filter: Filter,

	// Custom debug draw color.
	customColor: u32,

	// A sensor shape generates overlap events but never generates a collision response.
	isSensor: bool,

	// Enable sensor events for this shape. Only applies to kinematic and dynamic bodies. Ignored for sensors.
	enableSensorEvents: bool,

	// Enable contact events for this shape. Only applies to kinematic and dynamic bodies. Ignored for sensors.
	enableContactEvents: bool,

	// Enable hit events for this shape. Only applies to kinematic and dynamic bodies. Ignored for sensors.
	enableHitEvents: bool,

	// Enable pre-solve contact events for this shape. Only applies to dynamic bodies. These are expensive
	//	and must be carefully handled due to threading. Ignored for sensors.
	enablePreSolveEvents: bool,

	// Normally shapes on static bodies don't invoke contact creation when they are added to the world. This overrides
	//	that behavior and causes contact creation. This significantly slows down static body creation which can be important
	//	when there are many static shapes.
	forceContactCreation: bool,

	// Used internally to detect a valid definition. DO NOT SET.
	internalValue: i32,
}


// Used to create a chain of edges. This is designed to eliminate ghost collisions with some limitations.
//	- chains are one-sided
//	- chains have no mass and should be used on static bodies
//	- chains have a counter-clockwise winding order
//	- chains are either a loop or open
// - a chain must have at least 4 points
//	- the distance between any two points must be greater than b2_linearSlop
//	- a chain shape should not self intersect (this is not validated)
//	- an open chain shape has NO COLLISION on the first and final edge
//	- you may overlap two open chains on their first three and/or last three points to get smooth collision
//	- a chain shape creates multiple smooth edges shapes on the body
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

	// The friction coefficient, usually in the range [0,1].
	friction: f32,

	// The restitution (elasticity) usually in the range [0,1].
	restitution: f32,

	// Contact filtering data.
	filter: Filter,

	// Indicates a closed chain formed by connecting the first and last points
	isLoop: bool,

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
	buildIslands:        f32,
	solveConstraints:    f32,
	prepareTasks:        f32,
	solverTasks:         f32,
	prepareConstraints:  f32,
	integrateVelocities: f32,
	warmStart:           f32,
	solveVelocities:     f32,
	integratePositions:  f32,
	relaxVelocities:     f32,
	applyRestitution:    f32,
	storeImpulses:       f32,
	finalizeBodies:      f32,
	splitIslands:        f32,
	sleepIslands:        f32,
	hitEvents:           f32,
	broadphase:          f32,
	continuous:          f32,
}

// Counters that give details of the simulation size.
Counters :: struct {
	staticBodyCount:  i32,
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
	// The first attached body.
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

	// The lower angle for the joint limit in radians
	lowerAngle: f32,

	// The upper angle for the joint limit in radians
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
SensorEndTouchEvent :: struct {
	// The id of the sensor shape
	sensorShapeId: ShapeId,

	// The id of the dynamic shape that stopped touching the sensor shape
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
}

// An end touch event is generated when two shapes stop touching.
ContactEndTouchEvent :: struct {
	// Id of the first shape
	shapeIdA: ShapeId,

	// Id of the second shape
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

// These colors are used for debug draw.
//	See https://www.rapidtables.com/web/color/index.html
HexColor :: enum c.int {
	AliceBlue            = 0xf0f8ff,
	AntiqueWhite         = 0xfaebd7,
	Aqua                 = 0x00ffff,
	Aquamarine           = 0x7fffd4,
	Azure                = 0xf0ffff,
	Beige                = 0xf5f5dc,
	Bisque               = 0xffe4c4,
	Black                = 0x000000,
	BlanchedAlmond       = 0xffebcd,
	Blue                 = 0x0000ff,
	BlueViolet           = 0x8a2be2,
	Brown                = 0xa52a2a,
	Burlywood            = 0xdeb887,
	CadetBlue            = 0x5f9ea0,
	Chartreuse           = 0x7fff00,
	Chocolate            = 0xd2691e,
	Coral                = 0xff7f50,
	CornflowerBlue       = 0x6495ed,
	Cornsilk             = 0xfff8dc,
	Crimson              = 0xdc143c,
	Cyan                 = 0x00ffff,
	DarkBlue             = 0x00008b,
	DarkCyan             = 0x008b8b,
	DarkGoldenrod        = 0xb8860b,
	DarkGray             = 0xa9a9a9,
	DarkGreen            = 0x006400,
	DarkKhaki            = 0xbdb76b,
	DarkMagenta          = 0x8b008b,
	DarkOliveGreen       = 0x556b2f,
	DarkOrange           = 0xff8c00,
	DarkOrchid           = 0x9932cc,
	DarkRed              = 0x8b0000,
	DarkSalmon           = 0xe9967a,
	DarkSeaGreen         = 0x8fbc8f,
	DarkSlateBlue        = 0x483d8b,
	DarkSlateGray        = 0x2f4f4f,
	DarkTurquoise        = 0x00ced1,
	DarkViolet           = 0x9400d3,
	DeepPink             = 0xff1493,
	DeepSkyBlue          = 0x00bfff,
	DimGray              = 0x696969,
	DodgerBlue           = 0x1e90ff,
	Firebrick            = 0xb22222,
	FloralWhite          = 0xfffaf0,
	ForestGreen          = 0x228b22,
	Fuchsia              = 0xff00ff,
	Gainsboro            = 0xdcdcdc,
	GhostWhite           = 0xf8f8ff,
	Gold                 = 0xffd700,
	Goldenrod            = 0xdaa520,
	Gray                 = 0xbebebe,
	Gray1                = 0x1a1a1a,
	Gray2                = 0x333333,
	Gray3                = 0x4d4d4d,
	Gray4                = 0x666666,
	Gray5                = 0x7f7f7f,
	Gray6                = 0x999999,
	Gray7                = 0xb3b3b3,
	Gray8                = 0xcccccc,
	Gray9                = 0xe5e5e5,
	Green                = 0x00ff00,
	GreenYellow          = 0xadff2f,
	Honeydew             = 0xf0fff0,
	HotPink              = 0xff69b4,
	IndianRed            = 0xcd5c5c,
	Indigo               = 0x4b0082,
	Ivory                = 0xfffff0,
	Khaki                = 0xf0e68c,
	Lavender             = 0xe6e6fa,
	LavenderBlush        = 0xfff0f5,
	LawnGreen            = 0x7cfc00,
	LemonChiffon         = 0xfffacd,
	LightBlue            = 0xadd8e6,
	LightCoral           = 0xf08080,
	LightCyan            = 0xe0ffff,
	LightGoldenrod       = 0xeedd82,
	LightGoldenrodYellow = 0xfafad2,
	LightGray            = 0xd3d3d3,
	LightGreen           = 0x90ee90,
	LightPink            = 0xffb6c1,
	LightSalmon          = 0xffa07a,
	LightSeaGreen        = 0x20b2aa,
	LightSkyBlue         = 0x87cefa,
	LightSlateBlue       = 0x8470ff,
	LightSlateGray       = 0x778899,
	LightSteelBlue       = 0xb0c4de,
	LightYellow          = 0xffffe0,
	Lime                 = 0x00ff00,
	LimeGreen            = 0x32cd32,
	Linen                = 0xfaf0e6,
	Magenta              = 0xff00ff,
	Maroon               = 0xb03060,
	MediumAquamarine     = 0x66cdaa,
	MediumBlue           = 0x0000cd,
	MediumOrchid         = 0xba55d3,
	MediumPurple         = 0x9370db,
	MediumSeaGreen       = 0x3cb371,
	MediumSlateBlue      = 0x7b68ee,
	MediumSpringGreen    = 0x00fa9a,
	MediumTurquoise      = 0x48d1cc,
	MediumVioletRed      = 0xc71585,
	MidnightBlue         = 0x191970,
	MintCream            = 0xf5fffa,
	MistyRose            = 0xffe4e1,
	Moccasin             = 0xffe4b5,
	NavajoWhite          = 0xffdead,
	Navy                 = 0x000080,
	NavyBlue             = 0x000080,
	OldLace              = 0xfdf5e6,
	Olive                = 0x808000,
	OliveDrab            = 0x6b8e23,
	Orange               = 0xffa500,
	OrangeRed            = 0xff4500,
	Orchid               = 0xda70d6,
	PaleGoldenrod        = 0xeee8aa,
	PaleGreen            = 0x98fb98,
	PaleTurquoise        = 0xafeeee,
	PaleVioletRed        = 0xdb7093,
	PapayaWhip           = 0xffefd5,
	PeachPuff            = 0xffdab9,
	Peru                 = 0xcd853f,
	Pink                 = 0xffc0cb,
	Plum                 = 0xdda0dd,
	PowderBlue           = 0xb0e0e6,
	Purple               = 0xa020f0,
	RebeccaPurple        = 0x663399,
	Red                  = 0xff0000,
	RosyBrown            = 0xbc8f8f,
	RoyalBlue            = 0x4169e1,
	SaddleBrown          = 0x8b4513,
	Salmon               = 0xfa8072,
	SandyBrown           = 0xf4a460,
	SeaGreen             = 0x2e8b57,
	Seashell             = 0xfff5ee,
	Sienna               = 0xa0522d,
	Silver               = 0xc0c0c0,
	SkyBlue              = 0x87ceeb,
	SlateBlue            = 0x6a5acd,
	SlateGray            = 0x708090,
	Snow                 = 0xfffafa,
	SpringGreen          = 0x00ff7f,
	SteelBlue            = 0x4682b4,
	Tan                  = 0xd2b48c,
	Teal                 = 0x008080,
	Thistle              = 0xd8bfd8,
	Tomato               = 0xff6347,
	Turquoise            = 0x40e0d0,
	Violet               = 0xee82ee,
	VioletRed            = 0xd02090,
	Wheat                = 0xf5deb3,
	White                = 0xffffff,
	WhiteSmoke           = 0xf5f5f5,
	Yellow               = 0xffff00,
	YellowGreen          = 0x9acd32,
	Box2DRed             = 0xdc3132,
	Box2DBlue            = 0x30aebf,
	Box2DGreen           = 0x8cc924,
	Box2DYellow          = 0xffee8c,
}

// This struct holds callbacks you can implement to draw a Box2D world.
//	@ingroup world
DebugDraw :: struct {
	// Draw a closed polygon provided in CCW order.
	DrawPolygon: proc "c" (vertices: [^]Vec2, vertexCount: c.int, color: HexColor, ctx: rawptr),

	// Draw a solid closed polygon provided in CCW order.
	DrawSolidPolygon: proc "c" (transform: Transform, vertices: [^]Vec2, vertexCount: c.int, radius: f32, colr: HexColor, ctx: rawptr ),

	// Draw a circle.
	DrawCircle: proc "c" (center: Vec2, radius: f32, color: HexColor, ctx: rawptr),

	// Draw a solid circle.
	DrawSolidCircle: proc "c" (transform: Transform, radius: f32, color: HexColor, ctx: rawptr),

	// Draw a capsule.
	DrawCapsule: proc "c" (p1, p2: Vec2, radius: f32, color: HexColor, ctx: rawptr),

	// Draw a solid capsule.
	DrawSolidCapsule: proc "c" (p1, p2: Vec2, radius: f32, color: HexColor, ctx: rawptr),

	// Draw a line segment.
	DrawSegment: proc "c" (p1, p2: Vec2, color: HexColor, ctx: rawptr),

	// Draw a transform. Choose your own length scale.
	DrawTransform: proc "c" (transform: Transform, ctx: rawptr),

	// Draw a point.
	DrawPoint: proc "c" (p: Vec2, size: f32, color: HexColor, ctx: rawptr),

	// Draw a string.
	DrawString: proc "c" (p: Vec2, s: cstring, ctx: rawptr),

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
	drawAABBs: bool,

	// Option to draw the mass and center of mass of dynamic bodies
	drawMass: bool,

	// Option to draw contact points
	drawContacts: bool,

	// Option to visualize the graph coloring used for contacts and joints
	drawGraphColors: bool,

	// Option to draw contact normals
	drawContactNormals: bool,

	// Option to draw contact normal impulses
	drawContactImpulses: bool,

	// Option to draw contact friction impulses
	drawFrictionImpulses: bool,

	// User context that is passed as an argument to drawing callback functions
	userContext: rawptr,
}