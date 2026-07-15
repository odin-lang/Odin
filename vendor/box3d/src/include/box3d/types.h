// SPDX-FileCopyrightText: 2025 Erin Catto
// SPDX-License-Identifier: MIT

#pragma once

#include "base.h"
#include "constants.h"
#include "id.h"
#include "math_functions.h"

#include <stdint.h>

#define B3_DEFAULT_CATEGORY_BITS UINT64_MAX
#define B3_DEFAULT_MASK_BITS UINT64_MAX

/// Task interface
/// This is the prototype for a Box3D task. Your task system is expected to run this callback on a worker thread,
/// exactly once per enqueue, passing back the same taskContext pointer supplied to b3EnqueueTaskCallback.
/// @ingroup world
typedef void b3TaskCallback( void* taskContext );

/// These functions can be provided to Box3D to invoke a task system.
/// Returns a pointer to the user's task object. May be nullptr. A nullptr indicates to Box3D that the work was executed
/// serially within the callback and there is no need to call b3FinishTaskCallback. Otherwise the returned
/// value must be non-null will be passed to b3FinishTaskCallback as the userTask.
/// @param task the Box3D task to be called by the scheduler
/// @param taskContext the Box3D context object that the scheduler must pass to the task
/// @param userContext the scheduler context object that is opaque to Box3D
/// @param taskName the Box3D task name that the scheduler can use for diagnostics
/// @ingroup world
typedef void* b3EnqueueTaskCallback( b3TaskCallback* task, void* taskContext, void* userContext, const char* taskName );

/// Finishes a user task object that wraps a Box3D task. This must block until the task has completed.
/// The step blocks here on the tasks it spawned, so b3World_Step holds its stack across every
/// fork/join. Drive it from a thread you can dedicate to the step, or from a fiber this callback can
/// park to free the underlying thread. In a job system that cannot park a job's stack, do not call
/// b3World_Step from inside a job: a job that blocks on its own sub-jobs without yielding its thread
/// can deadlock. The in-tree scheduler instead runs other pending tasks on the waiting thread.
/// @ingroup world
typedef void b3FinishTaskCallback( void* userTask, void* userContext );

typedef struct b3DebugShape b3DebugShape;

/// The user needs to be able to create debug draw shapes for multi-pass rendering to work efficiently.
/// These user shapes are created and destroyed via callback so they can be bound to shape lifetime and scaling updates.
/// @ingroup debug_draw
typedef void* b3CreateDebugShapeCallback( const b3DebugShape* debugShape, void* userContext );
typedef void b3DestroyDebugShapeCallback( void* userShape, void* userContext );

/// Optional friction mixing callback. This intentionally provides no context objects because this is called
/// from a worker thread.
/// @warning This function should not attempt to modify Box3D state or user application state.
/// @ingroup world
typedef float b3FrictionCallback( float frictionA, uint64_t userMaterialIdA, float frictionB, uint64_t userMaterialIdB );

/// Optional restitution mixing callback. This intentionally provides no context objects because this is called
/// from a worker thread.
/// @warning This function should not attempt to modify Box3D state or user application state.
/// @ingroup world
typedef float b3RestitutionCallback( float restitutionA, uint64_t userMaterialIdA, float restitutionB, uint64_t userMaterialIdB );

/// Prototype for a contact filter callback.
/// This is called when a contact pair is considered for collision. This allows you to
/// perform custom logic to prevent collision between shapes. This is only called if
/// one of the two shapes has custom filtering enabled. @see b3ShapeDef.
/// Notes:
/// - this function must be thread-safe
/// - this is only called if one of the two shapes has enabled custom filtering
/// - this is called only for awake dynamic bodies
/// Return false if you want to disable the collision
/// @warning Do not attempt to modify the world inside this callback
/// @ingroup world
typedef bool b3CustomFilterFcn( b3ShapeId shapeIdA, b3ShapeId shapeIdB, void* context );

/// Prototype for a pre-solve callback.
/// This is called after a contact is updated. This allows you to inspect a
/// collision before it goes to the solver.
/// Notes:
/// - this function must be thread-safe
/// - this is only called if the shape has enabled pre-solve events
/// - this may be called for awake dynamic bodies and sensors
/// - this is not called for sensors
/// Return false if you want to disable the contact this step
/// This has limited information because it is used during CCD which does not have the
/// full contact manifold.
/// @warning Do not attempt to modify the world inside this callback
/// @ingroup world
typedef bool b3PreSolveFcn( b3ShapeId shapeIdA, b3ShapeId shapeIdB, b3Pos point, b3Vec3 normal, void* context );

/// Prototype callback for overlap queries.
/// Called for each shape found in the query.
/// @see b3World_OverlapAABB
/// @return false to terminate the query.
/// @ingroup world
typedef bool b3OverlapResultFcn( b3ShapeId shapeId, void* context );

/// Prototype callback for ray casts.
/// Called for each shape found in the query. You control how the ray cast
/// proceeds by returning a float:
/// return -1: ignore this shape and continue
/// return 0: terminate the ray cast
/// return fraction: clip the ray to this point
/// return 1: don't clip the ray and continue
/// @param shapeId the shape hit by the ray
/// @param point the point of initial intersection
/// @param normal the normal vector at the point of intersection
/// @param fraction the fraction along the ray at the point of intersection
/// @param userMaterialId the shape or triangle surface type
/// @param triangleIndex the triangle index for mesh or height field shapes or -1 for other shape types
/// @param childIndex the child shape index for compound shapes
/// @param context the user context
/// @return -1 to filter, 0 to terminate, fraction to clip the ray for closest hit, 1 to continue
/// @see b3World_CastRay
/// @ingroup world
typedef float b3CastResultFcn( b3ShapeId shapeId, b3Pos point, b3Vec3 normal, float fraction, uint64_t userMaterialId,
							   int triangleIndex, int childIndex, void* context );

/// Optional world capacities that can be use to avoid run-time allocations
/// @ingroup world
typedef struct b3Capacity
{
	/// Number of expected static shapes.
	int staticShapeCount;

	/// Number of expected dynamic and kinematic shapes.
	int dynamicShapeCount;

	/// Number of expected static bodies.
	int staticBodyCount;

	/// Number of expected dynamic and kinematic bodies.
	int dynamicBodyCount;

	/// Number of expected contacts.
	int contactCount;
} b3Capacity;

/// World definition used to create a simulation world. Must be initialized using b3DefaultWorldDef.
/// @ingroup world
typedef struct b3WorldDef
{
	/// Gravity vector. Box3D has no up-vector defined.
	b3Vec3 gravity;

	/// Restitution speed threshold, usually in m/s. Collisions above this
	/// speed have restitution applied (will bounce).
	float restitutionThreshold;

	/// Hit event speed threshold, usually in m/s. Collisions above this
	/// speed can generate hit events if the shape also enables hit events.
	float hitEventThreshold;

	/// Contact stiffness. Cycles per second. Increasing this increases the speed of overlap recovery, but can introduce jitter.
	float contactHertz;

	/// Contact bounciness. Non-dimensional. You can speed up overlap recovery by decreasing this with
	/// the trade-off that overlap resolution becomes more energetic.
	float contactDampingRatio;

	/// This parameter controls how fast overlap is resolved and usually has units of meters per second. This only
	/// puts a cap on the resolution speed. The resolution speed is increased by increasing the hertz and/or
	/// decreasing the damping ratio.
	float contactSpeed;

	/// Maximum linear speed. Usually meters per second.
	float maximumLinearSpeed;

	/// Optional mixing callback for friction. The default uses sqrt(frictionA * frictionB).
	b3FrictionCallback* frictionCallback;

	/// Optional mixing callback for restitution. The default uses max(restitutionA, restitutionB).
	b3RestitutionCallback* restitutionCallback;

	/// Can bodies go to sleep to improve performance
	bool enableSleep;

	/// Enable continuous collision
	bool enableContinuous;

	/// Number of workers to use with the provided task system. Box3D performs best when using only
	/// performance cores and accessing a single L2 cache. Efficiency cores and hyper-threading provide
	/// little benefit and may even harm performance.
	/// This is clamped to the range [1, B3_MAX_WORKERS]. Using a value above 1 will turn on multithreading.
	/// If task callbacks are provided then Box3D will use the user provided task system. Otherwise Box3D
	/// will create threads and use an internal scheduler.
	uint32_t workerCount;

	/// function to spawn task
	b3EnqueueTaskCallback* enqueueTask;

	/// function to finish a task
	b3FinishTaskCallback* finishTask;

	/// User context that is provided to enqueueTask and finishTask
	void* userTaskContext;

	/// User data associated with a world
	void* userData;

	/// Used to create debug draw shapes. This is called when a shape is
	/// first drawn using b3DebugDraw.
	b3CreateDebugShapeCallback* createDebugShape;

	/// Used to destroy debug draw shapes. This is called when a shape is modified or destroyed.
	b3DestroyDebugShapeCallback* destroyDebugShape;

	/// This is passed to the debug shape callbacks to provide a user context.
	void* userDebugShapeContext;

	/// Optional initial capacities
	b3Capacity capacity;

	/// Used internally to detect a valid definition. DO NOT SET.
	int internalValue;
} b3WorldDef;

/// Use this to initialize your world definition
/// @ingroup world
B3_API b3WorldDef b3DefaultWorldDef( void );

/// The body simulation type.
/// Each body is one of these three types. The type determines how the body behaves in the simulation.
/// @ingroup body
typedef enum b3BodyType
{
	/// zero mass, zero velocity, may be manually moved
	b3_staticBody = 0,

	/// zero mass, velocity set by user, moved by solver
	b3_kinematicBody = 1,

	/// positive mass, velocity determined by forces, moved by solver
	b3_dynamicBody = 2,

	/// number of body types
	b3_bodyTypeCount,
} b3BodyType;

/// Motion locks to restrict the body movement
/// @ingroup body
typedef struct b3MotionLocks
{
	/// Prevent translation along the x-axis
	bool linearX;

	/// Prevent translation along the y-axis
	bool linearY;

	/// Prevent translation along the z-axis
	bool linearZ;

	/// Prevent rotation around the x-axis
	bool angularX;

	/// Prevent rotation around the y-axis
	bool angularY;

	/// Prevent rotation around the z-axis
	bool angularZ;
} b3MotionLocks;

/// A body definition holds all the data needed to construct a rigid body.
/// You can safely re-use body definitions. Shapes are added to a body after construction.
/// Body definitions are temporary objects used to bundle creation parameters.
/// Must be initialized using b3DefaultBodyDef().
/// @ingroup body
typedef struct b3BodyDef
{
	/// The body type: static, kinematic, or dynamic.
	b3BodyType type;

	/// The initial world position of the body. Bodies should be created with the desired position.
	/// @note Creating bodies at the origin and then moving them nearly doubles the cost of body creation, especially
	/// if the body is moved after shapes have been added.
	b3Pos position;

	/// The initial world rotation of the body.
	b3Quat rotation;

	/// The initial linear velocity of the body's origin. Usually in meters per second.
	b3Vec3 linearVelocity;

	/// The initial angular velocity of the body. Radians per second.
	b3Vec3 angularVelocity;

	/// Linear damping is used to reduce the linear velocity. The damping parameter
	/// can be larger than 1 but the damping effect becomes sensitive to the
	/// time step when the damping parameter is large.
	/// Generally linear damping is undesirable because it makes objects move slowly
	/// as if they are floating.
	float linearDamping;

	/// Angular damping is used to reduce the angular velocity. The damping parameter
	/// can be larger than 1.0f but the damping effect becomes sensitive to the
	/// time step when the damping parameter is large.
	/// Angular damping can be used to slow down rotating bodies.
	float angularDamping;

	/// Scale the gravity applied to this body. Non-dimensional.
	float gravityScale;

	/// Sleep speed threshold, default is 0.05 meters per second
	float sleepThreshold;

	/// Optional body name for debugging.
	const char* name;

	/// Use this to store application specific body data.
	void* userData;

	/// Motions locks to restrict linear and angular movement
	b3MotionLocks motionLocks;

	/// Set this flag to false if this body should never fall asleep.
	bool enableSleep;

	/// Is this body initially awake or sleeping?
	bool isAwake;

	/// Treat this body as a high speed object that performs continuous collision detection
	/// against dynamic and kinematic bodies, but not other bullet bodies.
	/// @warning Bullets should be used sparingly. They are not a solution for general dynamic-versus-dynamic
	/// continuous collision. They do not guarantee accurate collision if both bodies are fast moving because
	/// the bullet does a continuous check after all non-bullet bodies have moved. You could get unlucky and have
	/// the bullet body end a time step very close to a non-bullet body and the non-bullet body then moves over
	/// the bullet body. In continuous collision, initial overlap is ignored to avoid freezing bodies in place.
	/// I do not recommend using them for game projectiles if precise collision timing is needed. Instead consider
	/// using a ray or shape cast. You can use a marching ray or shape cast for projectile that moves over time.
	/// If you want a fast moving projectile to collide with a fast moving target, you need to consider the relative
	/// movement in your ray or shape cast. This is out of the scope of Box3D.
	/// So what are good use cases for bullets? Pinball games or games with dynamic containers that hold other objects.
	/// It should be a use case where it doesn't break the game if there is a collision missed, but having them
	/// captured improves the quality of the game.
	bool isBullet;

	/// Used to disable a body. A disabled body does not move or collide.
	bool isEnabled;

	/// This allows this body to bypass rotational speed limits. Should only be used
	/// for circular objects, like wheels.
	bool allowFastRotation;

	/// Enable contact recycling. True by default. Leaving this enabled improves performance
	/// but may lead to ghost collision that should be avoided on characters.
	bool enableContactRecycling;

	/// Used internally to detect a valid definition. DO NOT SET.
	int internalValue;
} b3BodyDef;

/// Use this to initialize your body definition
/// @ingroup body
B3_API b3BodyDef b3DefaultBodyDef( void );

/// This is used to filter collision on shapes. It affects shape-vs-shape collision
/// and shape-versus-query collision (such as b3World_CastRay).
/// @ingroup shape
typedef struct b3Filter
{
	/// The collision category bits. Normally you would just set one bit. The category bits should
	/// represent your application object types. For example:
	/// @code{.cpp}
	/// enum MyCategories
	/// {
	///    Static  = 0x00000001,
	///    Dynamic = 0x00000002,
	///    Debris  = 0x00000004,
	///    Player  = 0x00000008,
	///    // etc
	/// };
	/// @endcode
	uint64_t categoryBits;

	/// The collision mask bits. This states the categories that this
	/// shape would accept for collision.
	/// For example, you may want your player to only collide with static objects
	/// and other players.
	/// @code{.c}
	/// maskBits = Static | Player;
	/// @endcode
	uint64_t maskBits;

	/// Collision groups allow a certain group of objects to never collide (negative)
	/// or always collide (positive). A group index of zero has no effect. Non-zero group filtering
	/// always wins against the mask bits.
	/// For example, you may want ragdolls to collide with other ragdolls but you don't want
	/// ragdoll self-collision. In this case you would give each ragdoll a unique negative group index
	/// and apply that group index to all shapes on the ragdoll.
	int groupIndex;
} b3Filter;

/// Use this to initialize your filter
/// @ingroup shape
B3_API b3Filter b3DefaultFilter( void );

/// Material properties supported per triangle on meshes and height fields
/// @ingroup shape
typedef struct b3SurfaceMaterial
{
	/// The Coulomb (dry) friction coefficient, usually in the range [0,1].
	float friction;

	/// The coefficient of restitution (bounce) usually in the range [0,1].
	/// https://en.wikipedia.org/wiki/Coefficient_of_restitution
	float restitution;

	/// The rolling resistance usually in the range [0,1]. This is only used for spheres and capsules.
	float rollingResistance;

	/// The tangent velocity for conveyor belts. This is local to the shape and will be projected
	/// onto the contact surface.
	b3Vec3 tangentVelocity;

	/// User material identifier. This is passed with query results and to friction and restitution
	/// combining functions. It is not used internally.
	uint64_t userMaterialId;

	/// Custom debug draw color. Ignored if 0. The low 24 bits are RGB. The high byte may
	/// carry a b3DebugMaterial preset, see b3MakeDebugColor.
	/// @see b3HexColor
	uint32_t customColor;
} b3SurfaceMaterial;

/// Use this to initialize your surface material
/// @ingroup shape
B3_API b3SurfaceMaterial b3DefaultSurfaceMaterial( void );

/// Shape type
/// @ingroup shape
typedef enum b3ShapeType
{
	/// A capsule is an extruded sphere
	b3_capsuleShape,

	/// A baked compound shape composed of spheres, capsules, hulls, and meshes
	b3_compoundShape,

	/// A height field useful for terrain
	b3_heightShape,

	/// A convex hull
	b3_hullShape,

	/// A triangle soup
	b3_meshShape,

	/// A sphere with an offset
	b3_sphereShape,

	/// The number of shape types
	b3_shapeTypeCount
} b3ShapeType;

/// Used to create a shape
/// @ingroup shape
typedef struct b3ShapeDef
{
	/// Optional shape name for debugging
	const char* name;

	/// Use this to store application specific shape data.
	void* userData;

	/// Surface material used on mesh shapes per triangle. Ignored for convex shapes. Ignored for compound shapes.
	b3SurfaceMaterial* materials;

	/// Surface material count.
	int materialCount;

	/// The base surface material. Ignored for compound shapes.
	b3SurfaceMaterial baseMaterial;

	/// The density, usually in kg/m^3.
	float density;

	/// Explosion scale for b3World_Explode. non-dimensional
	float explosionScale;

	/// Contact filtering data.
	b3Filter filter;

	/// Enable custom filtering. Only one of the two shapes needs to enable custom filtering. See b3WorldDef.
	bool enableCustomFiltering;

	/// A sensor shape generates overlap events but never generates a collision response.
	/// Sensors do not have continuous collision. Instead, use a ray or shape cast for those scenarios.
	/// Sensors still contribute to the body mass if they have non-zero density.
	/// @note Sensor events are disabled by default.
	/// @see enableSensorEvents
	bool isSensor;

	/// Enable sensor events for this shape. This applies to sensors and non-sensors. False by default, even for sensors.
	bool enableSensorEvents;

	/// Enable contact events for this shape. Only applies to kinematic and dynamic bodies. Ignored for sensors. False by default.
	bool enableContactEvents;

	/// Enable hit events for this shape. Only applies to kinematic and dynamic bodies. Ignored for sensors. False by default.
	bool enableHitEvents;

	/// Enable pre-solve contact events for this shape. Only applies to dynamic bodies. These are expensive
	///	and must be carefully handled due to multithreading. Ignored for sensors.
	bool enablePreSolveEvents;

	/// When shapes are created they will scan the environment for collision the next time step. This can significantly slow down
	/// static body creation when there are many static shapes.
	/// This is flag is ignored for dynamic and kinematic shapes which always invoke contact creation.
	bool invokeContactCreation;

	/// Should the body update the mass properties when this shape is created. Default is true.
	/// Warning: if this is false, you MUST call b3Body_ApplyMassFromShapes or b3Body_SetMassData before simulating the world.
	bool updateBodyMass;

	/// Enable speculative collision. Leave this true unless you care about reducing ghost collision
	/// more than continuous collision under rotation.
	/// Experimental: this can only disable speculative contact between hulls and triangles (meshes and height fields).
	bool enableSpeculativeContact;

	/// Used internally to detect a valid definition. DO NOT SET.
	int internalValue;

} b3ShapeDef;

/// Use this to initialize your shape definition
/// @ingroup shape
B3_API b3ShapeDef b3DefaultShapeDef( void );

//! @cond
/// Profiling data. Times are in milliseconds.
/// @ingroup world
typedef struct b3Profile
{
	float step;
	float pairs;
	float collide;
	float solve;
	float solverSetup;
	float constraints;
	float prepareConstraints;
	float integrateVelocities;
	float warmStart;
	float solveImpulses;
	float integratePositions;
	float relaxImpulses;
	float applyRestitution;
	float storeImpulses;
	float splitIslands;
	float transforms;
	float sensorHits;
	float jointEvents;
	float hitEvents;
	float refit;
	float bullets;
	float sleepIslands;
	float sensors;
} b3Profile;

/// Counters that give details of the simulation size.
/// @ingroup world
typedef struct b3Counters
{
	int bodyCount;
	int shapeCount;
	int contactCount;
	int jointCount;
	int islandCount;
	int stackUsed;
	int arenaCapacity;
	int staticTreeHeight;
	int treeHeight;
	int satCallCount;
	int satCacheHitCount;
	int byteCount;
	int taskCount;
	int colorCounts[24];
	int manifoldCounts[B3_CONTACT_MANIFOLD_COUNT_BUCKETS];

	/// Number of contacts touched by the collide pass
	/// graph contacts + awake-set non-touching
	int awakeContactCount;

	/// Number of contacts recycled in the most recent step.
	int recycledContactCount;

	/// Maximum number of time of impact iterations
	int distanceIterations;
	int pushBackIterations;
	int rootIterations;
} b3Counters;
//! @endcond

/// Joint type enumeration. This is useful because all joint types use b3JointId and sometimes you
/// want to get the type of a joint.
/// @ingroup joint
typedef enum b3JointType
{
	b3_parallelJoint,
	b3_distanceJoint,
	b3_filterJoint,
	b3_motorJoint,
	b3_prismaticJoint,
	b3_revoluteJoint,
	b3_sphericalJoint,
	b3_weldJoint,
	b3_wheelJoint,
} b3JointType;

/// Base joint definition used by all joint types. The local frames are measured from the
/// body's origin rather than the center of mass because:
/// 1. You might not know where the center of mass will be.
/// 2. If you add/remove shapes from a body and recompute the mass, the joints will be broken.
/// @ingroup joint
typedef struct b3JointDef
{
	/// User data pointer
	void* userData;

	/// The first attached body
	b3BodyId bodyIdA;

	/// The second attached body
	b3BodyId bodyIdB;

	/// The first local joint frame
	b3Transform localFrameA;

	/// The second local joint frame
	b3Transform localFrameB;

	/// Force threshold for joint events
	float forceThreshold;

	/// Torque threshold for joint events
	float torqueThreshold;

	/// Constraint hertz (advanced feature)
	float constraintHertz;

	/// Constraint damping ratio (advanced feature)
	float constraintDampingRatio;

	/// Debug draw scale
	float drawScale;

	/// Set this flag to true if the attached bodies should collide
	bool collideConnected;

	/// Used internally to detect a valid definition. DO NOT SET.
	int internalValue;
} b3JointDef;

/// Distance joint definition.
/// Connects a point on body A with a point on body B by a segment.
/// Useful for ropes and springs.
/// @ingroup distance_joint
typedef struct b3DistanceJointDef
{
	/// Base joint definition
	b3JointDef base;

	/// The rest length of this joint. Clamped to a stable minimum value.
	float length;

	/// Enable the distance constraint to behave like a spring. If false
	/// then the distance joint will be rigid, overriding the limit and motor.
	bool enableSpring;

	/// The lower spring force controls how much tension it can sustain
	float lowerSpringForce;

	/// The upper spring force controls how much compression it can sustain
	float upperSpringForce;

	/// The spring linear stiffness Hertz, cycles per second
	float hertz;

	/// The spring linear damping ratio, non-dimensional
	float dampingRatio;

	/// Enable/disable the joint limit
	bool enableLimit;

	/// Minimum length. Clamped to a stable minimum value.
	float minLength;

	/// Maximum length. Must be greater than or equal to the minimum length.
	float maxLength;

	/// Enable/disable the joint motor
	bool enableMotor;

	/// The maximum motor force, usually in newtons
	float maxMotorForce;

	/// The desired motor speed, usually in meters per second
	float motorSpeed;
} b3DistanceJointDef;

/// Use this to initialize your joint definition
/// @ingroup distance_joint
B3_API b3DistanceJointDef b3DefaultDistanceJointDef( void );

/// A motor joint is used to control the relative position and velocity between two bodies.
/// @ingroup motor_joint
typedef struct b3MotorJointDef
{
	/// Base joint definition
	b3JointDef base;

	/// The desired linear velocity
	b3Vec3 linearVelocity;

	/// The maximum motor force in newtons
	float maxVelocityForce;

	/// The desired angular velocity
	b3Vec3 angularVelocity;

	/// The maximum motor torque in newton-meters
	float maxVelocityTorque;

	/// Linear spring hertz for position control
	float linearHertz;

	/// Linear spring damping ratio
	float linearDampingRatio;

	/// Maximum spring force in newtons
	float maxSpringForce;

	/// Angular spring hertz for position control
	float angularHertz;

	/// Angular spring damping ratio
	float angularDampingRatio;

	/// Maximum spring torque in newton-meters
	float maxSpringTorque;
} b3MotorJointDef;

/// Use this to initialize your joint definition
/// @ingroup motor_joint
B3_API b3MotorJointDef b3DefaultMotorJointDef( void );

/// A filter joint is used to disable collision between two specific bodies.
/// @ingroup filter_joint
typedef struct b3FilterJointDef
{
	/// Base joint definition
	b3JointDef base;
} b3FilterJointDef;

/// Use this to initialize your joint definition
/// @ingroup filter_joint
B3_API b3FilterJointDef b3DefaultFilterJointDef( void );

/// Parallel joint definition. Constrains the angle between axis z in body A and axis z in body B
/// using a spring. Useful to keep a body upright.
/// @ingroup parallel_joint
typedef struct b3ParallelJointDef
{
	/// Base joint definition
	b3JointDef base;

	/// The spring stiffness Hertz, cycles per second
	float hertz;

	/// The spring damping ratio, non-dimensional
	float dampingRatio;

	/// The maximum spring torque, typically in newton-meters.
	float maxTorque;

} b3ParallelJointDef;

/// Use this to initialize your joint definition
/// @ingroup parallel_joint
B3_API b3ParallelJointDef b3DefaultParallelJointDef( void );

/// Prismatic joint definition. Body B may slide along the x-axis in local frame A.
/// Body B cannot rotate relative to body A. The joint translation is zero when the
/// local frame origins coincide in world space.
/// @ingroup prismatic_joint
typedef struct b3PrismaticJointDef
{
	/// Base joint definition
	b3JointDef base;

	/// Enable a linear spring along the prismatic joint axis
	bool enableSpring;

	/// The spring stiffness Hertz, cycles per second
	float hertz;

	/// The spring damping ratio, non-dimensional
	float dampingRatio;

	/// The target translation for the joint in meters. The spring-damper will drive
	/// to this translation.
	float targetTranslation;

	/// Enable/disable the joint limit
	bool enableLimit;

	/// The lower translation limit
	float lowerTranslation;

	/// The upper translation limit
	float upperTranslation;

	/// Enable/disable the joint motor
	bool enableMotor;

	/// The maximum motor force, typically in newtons
	float maxMotorForce;

	/// The desired motor speed, typically in meters per second
	float motorSpeed;
} b3PrismaticJointDef;

/// Use this to initialize your joint definition
/// @ingroup prismatic_joint
B3_API b3PrismaticJointDef b3DefaultPrismaticJointDef( void );

/// Revolute joint definition. A point on body B is fixed to a point on body A.
/// Allows relative rotation about the z-axis.
/// @ingroup revolute_joint
typedef struct b3RevoluteJointDef
{
	/// Base joint definition.
	b3JointDef base;

	/// The bodyB angle minus bodyA angle in the reference state (radians).
	/// This defines the zero angle for the joint limit.
	float targetAngle;

	/// Enable a rotational spring on the revolute hinge axis.
	bool enableSpring;

	/// The spring stiffness Hertz, cycles per second.
	float hertz;

	/// The spring damping ratio, non-dimensional.
	float dampingRatio;

	/// A flag to enable joint limits.
	bool enableLimit;

	/// The lower angle for the joint limit in radians. Minimum of -0.99*pi radians.
	float lowerAngle;

	/// The upper angle for the joint limit in radians. Maximum of 0.99*pi radians.
	float upperAngle;

	/// A flag to enable the joint motor.
	bool enableMotor;

	/// The maximum motor torque, typically in newton-meters.
	float maxMotorTorque;

	/// The desired motor speed in radians per second.
	float motorSpeed;
} b3RevoluteJointDef;

/// Use this to initialize your joint definition.
/// @ingroup revolute_joint
B3_API b3RevoluteJointDef b3DefaultRevoluteJointDef( void );

/// Spherical joint definition. A point on body B is fixed to a point on body A.
/// Allows rotation about the shared point.
/// @ingroup spherical_joint
typedef struct b3SphericalJointDef
{
	/// Base joint definition
	b3JointDef base;

	/// Enable a rotational spring that attempts to align the two joint frames.
	bool enableSpring;

	/// The spring stiffness Hertz, cycles per second. This may be clamped internally
	/// according to the time step to maintain stability. Non-negative number.
	float hertz;

	/// The spring damping ratio, non-dimensional. Non-negative number.
	float dampingRatio;

	/// Target spring rotation, joint frame B relative to joint frame A.
	b3Quat targetRotation;

	/// A flag to enable the cone limit. The cone is centered on the frameA z-axis.
	bool enableConeLimit;

	/// The angle for the cone limit in radians. Valid range is [0, pi]
	float coneAngle;

	/// A flag to enable the twist limit. The twist is centered on the frameB z-axis.
	bool enableTwistLimit;

	/// The angle for the lower twist limit in radians. Minimum of -0.99*pi radians.
	float lowerTwistAngle;

	/// The angle for the upper twist limit in radians. Maximum of 0.99*pi radians.
	float upperTwistAngle;

	/// A flag to enable the joint motor
	bool enableMotor;

	/// The maximum motor torque, typically in newton-meters. Non-negative number.
	float maxMotorTorque;

	/// The desired motor angular velocity in radians per second.
	b3Vec3 motorVelocity;
} b3SphericalJointDef;

/// Use this to initialize your joint definition.
/// @ingroup spherical_joint
B3_API b3SphericalJointDef b3DefaultSphericalJointDef( void );

/// Weld joint definition
/// Connects two bodies together rigidly. This constraint provides springs to mimic
/// soft-body simulation.
/// @note The approximate solver in Box3D cannot hold many bodies together rigidly
/// @ingroup weld_joint
typedef struct b3WeldJointDef
{
	/// Base joint definition
	b3JointDef base;

	/// Linear stiffness expressed as Hertz (cycles per second). Use zero for maximum stiffness.
	float linearHertz;

	/// Angular stiffness as Hertz (cycles per second). Use zero for maximum stiffness.
	float angularHertz;

	/// Linear damping ratio, non-dimensional. Use 1 for critical damping.
	float linearDampingRatio;

	/// Linear damping ratio, non-dimensional. Use 1 for critical damping.
	float angularDampingRatio;
} b3WeldJointDef;

/// Use this to initialize your joint definition
/// @ingroup weld_joint
B3_API b3WeldJointDef b3DefaultWeldJointDef( void );

/// Wheel joint definition
/// Body A is the chassis and body B is the wheel.
/// The wheel rotates around the local z-axis in frame B.
/// The wheel translates along the local x-axis in frame A.
/// The wheel can optionally steer along the x-axis in frame A.
/// @ingroup wheel_joint
typedef struct b3WheelJointDef
{
	/// Base joint definition
	b3JointDef base;

	/// Enable a linear spring along the local axis
	bool enableSuspensionSpring;

	/// Spring stiffness in Hertz
	float suspensionHertz;

	/// Spring damping ratio, non-dimensional
	float suspensionDampingRatio;

	/// Enable/disable the joint linear limit
	bool enableSuspensionLimit;

	/// The lower suspension translation limit
	float lowerSuspensionLimit;

	/// The upper translation limit
	float upperSuspensionLimit;

	/// Enable/disable the joint rotational motor
	bool enableSpinMotor;

	/// The maximum motor torque, typically in newton-meters
	float maxSpinTorque;

	/// The desired motor speed in radians per second
	float spinSpeed;

	/// Enable steering, otherwise the steering is fixed forward
	bool enableSteering;

	/// Steering stiffness in Hertz
	float steeringHertz;

	/// Spring damping ratio, non-dimensional
	float steeringDampingRatio;

	/// The target steering angle in radians
	float targetSteeringAngle;

	/// The maximum steering torque in N*m
	float maxSteeringTorque;

	/// Enable/disable the steering angular limit
	bool enableSteeringLimit;

	/// The lower steering angle in radians
	float lowerSteeringLimit;

	/// The upper steering angle in radians
	float upperSteeringLimit;
} b3WheelJointDef;

/// Use this to initialize your joint definition
/// @ingroup wheel_joint
B3_API b3WheelJointDef b3DefaultWheelJointDef( void );

/// The explosion definition is used to configure options for explosions. Explosions
/// consider shape geometry when computing the impulse.
/// @ingroup world
typedef struct b3ExplosionDef
{
	/// Mask bits to filter shapes
	uint64_t maskBits;

	/// The center of the explosion in world space
	b3Pos position;

	/// The radius of the explosion
	float radius;

	/// The falloff distance beyond the radius. Impulse is reduced to zero at this distance.
	float falloff;

	/// Impulse per unit area. This applies an impulse according to the shape area that
	/// is facing the explosion. Explosions only apply to spheres, capsules, and hulls. This
	/// may be negative for implosions.
	float impulsePerArea;
} b3ExplosionDef;

/// Use this to initialize your explosion definition
/// @ingroup world
B3_API b3ExplosionDef b3DefaultExplosionDef( void );

/**
 * @defgroup event Events
 * World event types.
 *
 * Events are used to collect events that occur during the world time step. These events
 * are then available to query after the time step is complete. This is preferable to callbacks
 * because Box3D uses multithreaded simulation.
 *
 * Also when events occur in the simulation step it may be problematic to modify the world, which is
 * often what applications want to do when events occur.
 *
 * With event arrays, you can scan the events in a loop and modify the world. However, you need to be careful
 * that some event data may become invalid. There are several samples that show how to do this safely.
 *
 * @{
 */

/// A begin-touch event is generated when a shape starts to overlap a sensor shape.
typedef struct b3SensorBeginTouchEvent
{
	/// The id of the sensor shape
	b3ShapeId sensorShapeId;

	/// The id of the shape that began touching the sensor shape
	b3ShapeId visitorShapeId;
} b3SensorBeginTouchEvent;

/// An end touch event is generated when a shape stops overlapping a sensor shape.
///	These include things like setting the transform, destroying a body or shape, or changing
///	a filter. You will also get an end event if the sensor or visitor are destroyed.
///	Therefore you should always confirm the shape id is valid using b3Shape_IsValid.
typedef struct b3SensorEndTouchEvent
{
	/// The id of the sensor shape
	///	@warning this shape may have been destroyed
	///	@see b3Shape_IsValid
	b3ShapeId sensorShapeId;

	/// The id of the shape that stopped touching the sensor shape
	///	@warning this shape may have been destroyed
	///	@see b3Shape_IsValid
	b3ShapeId visitorShapeId;
} b3SensorEndTouchEvent;

/// Sensor events are buffered in the world and are available
///	as begin/end overlap event arrays after the time step is complete.
///	Note: these may become invalid if bodies and/or shapes are destroyed
typedef struct b3SensorEvents
{
	/// Array of sensor begin touch events
	b3SensorBeginTouchEvent* beginEvents;

	/// Array of sensor end touch events
	b3SensorEndTouchEvent* endEvents;

	/// The number of begin touch events
	int beginCount;

	/// The number of end touch events
	int endCount;
} b3SensorEvents;

/// A begin-touch event is generated when two shapes begin touching.
typedef struct b3ContactBeginTouchEvent
{
	/// Id of the first shape
	b3ShapeId shapeIdA;

	/// Id of the second shape
	b3ShapeId shapeIdB;

	/// The transient contact id. This contact may be destroyed automatically when the world is modified or simulated.
	/// Use b3Contact_IsValid before using this id.
	b3ContactId contactId;
} b3ContactBeginTouchEvent;

/// An end touch event is generated when two shapes stop touching.
///	You will get an end event if you do anything that destroys contacts previous to the last
///	world step. These include things like setting the transform, destroying a body
///	or shape, or changing a filter or body type.
typedef struct b3ContactEndTouchEvent
{
	/// Id of the first shape
	///	@warning this shape may have been destroyed
	///	@see b3Shape_IsValid
	b3ShapeId shapeIdA;

	/// Id of the first shape
	///	@warning this shape may have been destroyed
	///	@see b3Shape_IsValid
	b3ShapeId shapeIdB;

	/// Id of the contact.
	///	@warning this contact may have been destroyed
	///	@see b3Contact_IsValid
	b3ContactId contactId;
} b3ContactEndTouchEvent;

/// A hit touch event is generated when two shapes collide with a speed faster than the hit speed threshold.
/// This may be reported for speculative contacts that have a confirmed impulse.
typedef struct b3ContactHitEvent
{
	/// Id of the first shape
	b3ShapeId shapeIdA;

	/// Id of the second shape
	b3ShapeId shapeIdB;

	/// Id of the contact.
	///	@warning this contact may have been destroyed
	///	@see b3Contact_IsValid
	b3ContactId contactId;

	/// Point where the shapes hit at the beginning of the time step.
	/// This is a mid-point between the two surfaces. It could be at speculative
	/// point where the two shapes were not touching at the beginning of the time step.
	b3Pos point;

	/// Normal vector pointing from shape A to shape B
	b3Vec3 normal;

	/// The speed the shapes are approaching. Always positive. Typically in meters per second.
	float approachSpeed;

	/// User material on shape A
	uint64_t userMaterialIdA;

	/// User material on shape B
	uint64_t userMaterialIdB;

} b3ContactHitEvent;

/// Contact events are buffered in the world and are available
///	as event arrays after the time step is complete.
///	Note: these may become invalid if bodies and/or shapes are destroyed
typedef struct b3ContactEvents
{
	/// Array of begin touch events
	b3ContactBeginTouchEvent* beginEvents;

	/// Array of end touch events
	b3ContactEndTouchEvent* endEvents;

	/// Array of hit events
	b3ContactHitEvent* hitEvents;

	/// Number of begin touch events
	int beginCount;

	/// Number of end touch events
	int endCount;

	/// Number of hit events
	int hitCount;
} b3ContactEvents;

/// Body move events triggered when a body moves.
/// Triggered when a body moves due to simulation. Not reported for bodies moved by the user.
/// This also has a flag to indicate that the body went to sleep so the application can also
/// sleep that actor/entity/object associated with the body.
/// On the other hand if the flag does not indicate the body went to sleep then the application
/// can treat the actor/entity/object associated with the body as awake.
/// This is an efficient way for an application to update game object transforms rather than
/// calling functions such as b3Body_GetTransform() because this data is delivered as a contiguous array
/// and it is only populated with bodies that have moved.
/// @note If sleeping is disabled all dynamic and kinematic bodies will trigger move events.
typedef struct b3BodyMoveEvent
{
	/// The body user data.
	void* userData;

	/// The body transform.
	b3WorldTransform transform;

	/// The body id.
	b3BodyId bodyId;

	/// Did the body fall asleep this time step?
	bool fellAsleep;
} b3BodyMoveEvent;

/// Body events are buffered in the world and are available
///	as event arrays after the time step is complete.
///	Note: this data becomes invalid if bodies are destroyed
typedef struct b3BodyEvents
{
	/// Array of move events
	b3BodyMoveEvent* moveEvents;

	/// Number of move events
	int moveCount;
} b3BodyEvents;

/// Joint events report joints that are awake and have a force and/or torque exceeding the threshold
/// The observed forces and torques are not returned for efficiency reasons.
typedef struct b3JointEvent
{
	/// The joint id
	b3JointId jointId;

	/// The user data from the joint for convenience
	void* userData;
} b3JointEvent;

/// Joint events are buffered in the world and are available
/// as event arrays after the time step is complete.
/// Note: this data becomes invalid if joints are destroyed
typedef struct b3JointEvents
{
	/// Array of events
	b3JointEvent* jointEvents;

	/// Number of events
	int count;
} b3JointEvents;

/// The contact data for two shapes. By convention the manifold normal points
/// from shape A to shape B.
/// @see b3Shape_GetContactData() and b3Body_GetContactData()
typedef struct b3ContactData
{
	/// The contact id. You may hold onto this to track a contact across time steps.
	/// This id may become orphaned. Use b3Contact_IsValid before using it for other functions.
	b3ContactId contactId;

	/// The first shape id.
	b3ShapeId shapeIdA;

	/// The second shape id.
	b3ShapeId shapeIdB;

	/// The contact manifold. This points to internal data and may become invalid. Do not store
	/// this pointer.
	const struct b3Manifold* manifolds;

	/// The number of contact manifolds. For mesh and height-field collision there can be multiple manifolds.
	int manifoldCount;
} b3ContactData;

/**@}*/ // event

/**
 * @defgroup query Query
 * @brief Query types and functions
 *
 * Queries include ray casts, shapes casts, overlap, distance, and time of impact.
 * @{
 */

/// The query filter is used to filter collisions between queries and shapes. For example,
/// you may want a ray-cast representing a projectile to hit players and the static environment
/// but not debris.
typedef struct b3QueryFilter
{
	/// The collision category bits of this query. Normally you would just set one bit.
	uint64_t categoryBits;

	/// The collision mask bits. This states the shape categories that this
	/// query would accept for collision.
	uint64_t maskBits;

	/// Optional id combined with @ref name to identify this query in a recording, e.g. an entity id.
	/// Need not be unique on its own. 0 with a null name means untagged. Ignored when not recording.
	uint64_t id;

	/// Optional label combined with @ref id to identify this query, e.g. "bullet". Need not be unique
	/// on its own. The recorder hashes (id, name) into one stable key the viewer tracks the query by,
	/// so the same id and name pair identifies the same query across frames. NULL means none. Ignored
	/// when not recording.
	const char* name;
} b3QueryFilter;

/// Use this to initialize your query filter
B3_API b3QueryFilter b3DefaultQueryFilter( void );

/// Low level ray cast input data.
typedef struct b3RayCastInput
{
	/// Start point of the ray cast.
	b3Vec3 origin;

	/// Translation of the ray cast.
	/// end = start + translation.
	b3Vec3 translation;

	/// The maximum fraction of the translation to consider, typically 1
	float maxFraction;
} b3RayCastInput;

/// Result from b3World_RayCastClosest.
typedef struct b3RayResult
{
	/// The shape hit.
	b3ShapeId shapeId;

	/// The world point of the hit.
	b3Pos point;

	/// The world normal of the shape surface at the hit point.
	b3Vec3 normal;

	/// The user material id at the hit point. This can be per triangle
	/// if the shape is a mesh, height-field, or compound with child mesh.
	uint64_t userMaterialId;

	/// The fraction of the input ray.
	float fraction;

	/// The triangle index if the shape is a mesh, height-field, or compound with
	/// child mesh.
	int triangleIndex;

	/// The child index if the shape is a compound.
	int childIndex;

	/// The number of BVH nodes visited. Diagnostic.
	int nodeVisits;

	/// The number of BVH leaves visited. Diagnostic.
	int leafVisits;

	/// Did the ray hit? If false, all other data is invalid.
	bool hit;
} b3RayResult;

/// A shape proxy is used by the GJK algorithm. It can represent a convex shape.
typedef struct b3ShapeProxy
{
	/// The point cloud.
	const b3Vec3* points;

	/// The number of points. Do not exceed B3_MAX_SHAPE_CAST_POINTS.
	int count;

	/// The external radius of the point cloud.
	float radius;
} b3ShapeProxy;

/// Low level shape cast input in generic form. This allows casting an arbitrary point
/// cloud wrap with a radius. For example, a sphere is a single point with a non-zero radius.
/// A capsule is two points with a non-zero radius. A box is four points with a zero radius.
typedef struct b3ShapeCastInput
{
	/// A generic query shape.
	b3ShapeProxy proxy;

	/// The translation of the shape cast.
	b3Vec3 translation;

	/// The maximum fraction of the translation to consider, typically 1.
	float maxFraction;

	/// Allow shape cast to encroach when initially touching. This only works if the radius is greater than zero.
	bool canEncroach;
} b3ShapeCastInput;

/// Input for sweeping an AABB through a dynamic tree. The box is in the tree's world float frame.
/// The caller folds the cast shape radius and any world origin into the box, so the tree traversal
/// stays a conservative box sweep and the precise narrow phase happens per shape in the callback.
typedef struct b3BoxCastInput
{
	/// The AABB to cast, in the tree's frame.
	b3AABB box;

	/// The sweep translation.
	b3Vec3 translation;

	/// The maximum fraction of the translation to consider, typically 1.
	float maxFraction;
} b3BoxCastInput;

/// Low level ray cast or shape-cast output data.
typedef struct b3CastOutput
{
	/// The surface normal at the hit point.
	b3Vec3 normal;

	/// The surface hit point.
	b3Vec3 point;

	/// The fraction of the input translation at collision.
	float fraction;

	/// The number of iterations used.
	int iterations;

	/// The index of the mesh or height field triangle hit.
	int triangleIndex;

	/// The index of the compound child shape.
	int childIndex;

	/// The material index. May be -1 for null.
	int materialIndex;

	/// Did the cast hit?
	bool hit;
} b3CastOutput;

#if defined( BOX3D_DOUBLE_PRECISION )

/// Ray cast or shape-cast output in world space. The hit point is a world position so the result
/// stays precise far from the world origin. Mirrors b3CastOutput with a double precision point.
typedef struct b3WorldCastOutput
{
	/// The surface normal at the hit point.
	b3Vec3 normal;

	/// The surface hit point in world space.
	b3Pos point;

	/// The fraction of the input translation at collision.
	float fraction;

	/// The number of iterations used.
	int iterations;

	/// The index of the mesh or height field triangle hit.
	int triangleIndex;

	/// The index of the compound child shape.
	int childIndex;

	/// The material index. May be -1 for null.
	int materialIndex;

	/// Did the cast hit?
	bool hit;
} b3WorldCastOutput;

#else

/// Same type in single precision.
typedef b3CastOutput b3WorldCastOutput;

#endif

/// Body cast result for ray and shape casts.
typedef struct b3BodyCastResult
{
	/// The shape hit.
	b3ShapeId shapeId;

	/// The world point on the shape surface.
	b3Pos point;

	/// The world normal vector on the shape surface.
	b3Vec3 normal;

	/// The fraction along the ray hit.
	/// hit point = origin + fraction * translation
	float fraction;

	/// The triangle index if the shape is a mesh or height-field.
	int triangleIndex;

	/// The user material id at the hit point. This can be per triangle
	/// if the shape is a mesh, height-field, or compound with child mesh.
	uint64_t userMaterialId;

	/// The number of iterations used. Diagnostic.
	int iterations;

	/// Did the cast hit? If false, all other fields are invalid.
	bool hit;
} b3BodyCastResult;

/// Used to warm start the GJK simplex. If you call this function multiple times with nearby
/// transforms this might improve performance. Otherwise you can zero initialize this.
/// The distance cache must be initialized to zero on the first call.
/// Users should generally just zero initialize this structure for each call.
typedef struct b3SimplexCache
{
	/// Value use to compare length, area, volume of two simplexes.
	float metric;

	// todo use an index of 0xFF as a sentinel and remove the count
	/// The number of stored simplex points
	uint16_t count;

	/// The cached simplex indices on shape A
	uint8_t indexA[4];

	/// The cached simplex indices on shape B
	uint8_t indexB[4];

} b3SimplexCache;

static const b3SimplexCache b3_emptyDistanceCache = B3_ZERO_INIT;

/// Input parameters for b3ShapeCast
typedef struct b3ShapeCastPairInput
{
	b3ShapeProxy proxyA;   ///< The proxy for shape A
	b3ShapeProxy proxyB;   ///< The proxy for shape B
	b3Transform transform; ///< Transform of shape B in shape A's frame, the relative pose B in A
	b3Vec3 translationB;   ///< The translation of shape B, in A's frame
	float maxFraction;	   ///< The fraction of the translation to consider, typically 1
	bool canEncroach;	   ///< Allows shapes with a radius to move slightly closer if already touching
} b3ShapeCastPairInput;

/// Input for b3ShapeDistance
typedef struct b3DistanceInput
{
	/// The proxy for shape A
	b3ShapeProxy proxyA;

	/// The proxy for shape B
	b3ShapeProxy proxyB;

	/// Transform of shape B in shape A's frame, the relative pose B in A
	/// (b3InvMulWorldTransforms( worldA, worldB )). The query is origin independent and runs in frame A.
	b3Transform transform;

	/// Should the proxy radius be considered?
	bool useRadii;
} b3DistanceInput;

/// Output for b3ShapeDistance
typedef struct b3DistanceOutput
{
	b3Vec3 pointA;	  ///< Closest point on shapeA, in shape A's frame
	b3Vec3 pointB;	  ///< Closest point on shapeB, in shape A's frame
	b3Vec3 normal;	  ///< A to B normal in shape A's frame. Invalid if distance is zero.
	float distance;	  ///< The final distance, zero if overlapped
	int iterations;	  ///< Number of GJK iterations used
	int simplexCount; ///< The number of simplexes stored in the simplex array
} b3DistanceOutput;

/// Simplex vertex for debugging the GJK algorithm
typedef struct b3SimplexVertex
{
	b3Vec3 wA;	///< support point in proxyA
	b3Vec3 wB;	///< support point in proxyB
	b3Vec3 w;	///< wB - wA
	float a;	///< barycentric coordinates
	int indexA; ///< wA index
	int indexB; ///< wB index
} b3SimplexVertex;

/// Simplex from the GJK algorithm
typedef struct b3Simplex
{
	b3SimplexVertex vertices[4]; ///< vertices
	int count;					 ///< number of valid vertices
} b3Simplex;

/// This describes the motion of a body/shape for TOI computation. Shapes are defined with respect to the body origin,
/// which may not coincide with the center of mass. However, to support dynamics we must interpolate the center of mass
/// position.
typedef struct b3Sweep
{
	b3Vec3 localCenter; ///< Local center of mass position
	b3Vec3 c1;			///< Starting center of mass world position
	b3Vec3 c2;			///< Ending center of mass world position
	b3Quat q1;			///< Starting world rotation
	b3Quat q2;			///< Ending world rotation
} b3Sweep;

/// Time of impact input
typedef struct b3TOIInput
{
	b3ShapeProxy proxyA; ///< The proxy for shape A
	b3ShapeProxy proxyB; ///< The proxy for shape B
	b3Sweep sweepA;		 ///< The movement of shape A
	b3Sweep sweepB;		 ///< The movement of shape B
	float maxFraction;	 ///< Defines the sweep interval [0, tMax]
} b3TOIInput;

/// Describes the TOI output
typedef enum b3TOIState
{
	b3_toiStateUnknown,
	b3_toiStateFailed,
	b3_toiStateOverlapped,
	b3_toiStateHit,
	b3_toiStateSeparated
} b3TOIState;

/// Time of impact output
typedef struct b3TOIOutput
{
	/// The type of result
	b3TOIState state;

	/// The hit point
	b3Vec3 point;

	/// The hit normal
	b3Vec3 normal;

	/// The sweep time of the collision
	float fraction;

	/// The final distance
	float distance;

	/// Number of outer iterations
	int distanceIterations;

	/// Total number of push back iterations
	int pushBackIterations;

	/// Total number of root iterations
	int rootIterations;

	/// Indicates that the time of impact detected initial
	/// overlap and used a fallback sphere as a last ditch effort
	/// to prevent tunneling.
	bool usedFallback;
} b3TOIOutput;

/**@}*/ // query

/**
 * @defgroup tree Dynamic Tree
 * The dynamic tree is a binary AABB tree to organize and query large numbers of geometric objects
 *
 * Box3D uses the dynamic tree internally to sort collision shapes into a binary bounding volume hierarchy.
 * This data structure may have uses in games for organizing other geometry data and may be used independently
 * of Box3D rigid body simulation.
 *
 * A dynamic AABB tree broad-phase, inspired by Nathanael Presson's btDbvt.
 * A dynamic tree arranges data in a binary tree to accelerate
 * queries such as AABB queries and ray casts. Leaf nodes are proxies
 * with an AABB. These are used to hold a user collision object.
 * Nodes are pooled and relocatable, so I use node indices rather than pointers.
 * The dynamic tree is made available for advanced users that would like to use it to organize
 * spatial game data besides rigid bodies.
 * @{
 */

/// Flags for tree nodes. For internal usage.
typedef enum b3TreeNodeFlags
{
	b3_allocatedNode = 0x0001,
	b3_enlargedNode = 0x0002,
	b3_leafNode = 0x0004,
} b3TreeNodeFlags;

/// Tree node child indices. For internal usage.
typedef struct b3TreeNodeChildren
{
	int child1; ///< child node index 1
	int child2; ///< child node index 2
} b3TreeNodeChildren;

/// A node in the dynamic tree. This is private data placed here for performance reasons.
/// todo test padding to 64 bytes to avoid straddling cache lines
typedef struct b3TreeNode
{
	/// The node bounding box
	b3AABB aabb; // 24

	/// Category bits for collision filtering
	uint64_t categoryBits; // 8

	union
	{
		/// Children (internal node)
		b3TreeNodeChildren children;

		/// User data (leaf node)
		uint64_t userData;
	}; // 8

	union
	{
		/// The node parent index (allocated node)
		int parent;

		/// The node freelist next index (free node)
		int next;
	}; // 4

	/// Height of the node. Leaves have a height of 0.
	uint16_t height; // 2

	/// @see b3TreeNodeFlags
	uint16_t flags; // 2
} b3TreeNode;

/// Dynamic tree version for compatibility testing.
#define B3_DYNAMIC_TREE_VERSION 0x93EDAF889FD30B4Aull

/// The dynamic tree structure. This should be considered private data.
/// It is placed here for performance reasons.
typedef struct b3DynamicTree
{
	/// The dynamic tree version. Always the first field. Useful
	/// if the tree is serialized.
	uint64_t version;

	/// The tree nodes
	b3TreeNode* nodes;

	/// The root index
	int root;

	/// The number of nodes
	int nodeCount;

	/// The allocated node space
	int nodeCapacity;

	/// Number of proxies created
	int proxyCount;

	/// Node free list
	int freeList;

	/// Leaf indices for rebuild
	int* leafIndices;

	/// Leaf bounding boxes for rebuild
	b3AABB* leafBoxes;

	/// Leaf bounding box centers for rebuild
	b3Vec3* leafCenters;

	/// Bins for sorting during rebuild
	int* binIndices;

	/// Allocated space for rebuilding
	int rebuildCapacity;
} b3DynamicTree;

/// These are performance results returned by dynamic tree queries.
typedef struct b3TreeStats
{
	/// Number of internal nodes visited during the query
	int nodeVisits;

	/// Number of leaf nodes visited during the query
	int leafVisits;
} b3TreeStats;

/// This function receives proxies found in the AABB query.
/// @return true if the query should continue
typedef bool b3TreeQueryCallbackFcn( int proxyId, uint64_t userData, void* context );

/// This function receives the minimum distance squared so far and proxy to check in the closest query.
/// @return minimum distance squared to user objects in the proxy
typedef float b3TreeQueryClosestCallbackFcn( float distanceSqrMin, int proxyId, uint64_t userData, void* context );

/// This function receives clipped AABB cast input for a proxy. The function returns the new cast
/// fraction.
/// - return a value of 0 to terminate the cast
/// - return a value less than input->maxFraction to clip the cast
/// - return a value of input->maxFraction to continue the cast without clipping
typedef float b3TreeBoxCastCallbackFcn( const b3BoxCastInput* input, int proxyId, uint64_t userData, void* context );

/// This function receives clipped ray cast input for a proxy. The function
/// returns the new ray fraction.
/// - return a value of 0 to terminate the ray cast
/// - return a value less than input->maxFraction to clip the ray
/// - return a value of input->maxFraction to continue the ray cast without clipping
typedef float b3TreeRayCastCallbackFcn( const b3RayCastInput* input, int proxyId, uint64_t userData, void* context );

/**@}*/ // tree

/**
 * @defgroup character Character Mover
 * Character movement solver
 * @{
 */

/// The plane between a character mover and a shape
typedef struct b3PlaneResult
{
	/// Outward pointing plane.
	b3Plane plane;

	/// Closest point on the shape. May not be unique.
	b3Vec3 point;

} b3PlaneResult;

/// These are collision planes that can be fed to b3SolvePlanes. Normally
/// this is assembled by the user from plane results in b3PlaneResult.
typedef struct b3CollisionPlane
{
	/// The collision plane between the mover and some shape.
	b3Plane plane;

	/// Setting this to FLT_MAX makes the plane as rigid as possible. Lower values can
	/// make the plane collision soft. Usually in meters.
	float pushLimit;

	/// The push on the mover determined by b3SolvePlanes. Usually in meters.
	float push;

	/// Indicates if b3ClipVector should clip against this plane. Should be false for soft collision.
	bool clipVelocity;
} b3CollisionPlane;

/// Result returned by b3SolvePlanes.
typedef struct b3PlaneSolverResult
{
	/// The final relative translation.
	b3Vec3 delta;

	/// The number of iterations used by the plane solver. For diagnostics.
	int iterationCount;
} b3PlaneSolverResult;

/// Body plane result for movers.
typedef struct b3BodyPlaneResult
{
	/// The shape id on the body.
	b3ShapeId shapeId;

	/// The plane result.
	b3PlaneResult result;
} b3BodyPlaneResult;

/// Used to collect collision planes for character movers.
/// Return true to continue gathering planes.
typedef bool b3PlaneResultFcn( b3ShapeId shapeId, const b3PlaneResult* plane, int planeCount, void* context );

/// Used to filter shapes for shape casting character movers.
/// Return true to accept the collision
typedef bool b3MoverFilterFcn( b3ShapeId shapeId, void* context );

/**@}*/ // mover

/**
 * @defgroup geometry Geometry
 * @brief Geometry types and algorithms
 *
 * Definitions of spheres, capsules, hulls, meshes, height fields, and compounds.
 * @{
 */

/// This holds the mass data computed for a shape.
typedef struct b3MassData
{
	/// The shape mass
	float mass;

	/// The local center of mass position.
	b3Vec3 center;

	/// The inertia tensor about the shape center of mass.
	b3Matrix3 inertia;
} b3MassData;

/**
 * @defgroup sphere Sphere
 * @brief Sphere primitive
 * @{
 */

/// A solid sphere
typedef struct b3Sphere
{
	/// The local center
	b3Vec3 center;

	/// The radius
	float radius;
} b3Sphere;

/**@}*/ // sphere

/**
 * @defgroup capsule Capsule
 * @brief Capsule primitive
 * @{
 */

/// A solid capsule can be viewed as two hemispheres connected
/// by a rectangle.
typedef struct b3Capsule
{
	/// Local center of the first hemisphere
	b3Vec3 center1;

	/// Local center of the second hemisphere
	b3Vec3 center2;

	/// The radius of the hemispheres
	float radius;
} b3Capsule;

/**@}*/ // capsule

/**
 * @defgroup hull Convex Hull
 * @brief Convex hull primitive
 * @{
 */

/// A hull vertex. Identified by a half-edge with this
/// vertex as its tail.
typedef struct b3HullVertex
{
	/// A half-edge that has this vertex as the origin
	/// Can be used along with edge twins and winding order
	/// to traverse all the edges connected to this vertex.
	uint8_t edge;
} b3HullVertex;

/// Half-edge for hull data structure
typedef struct b3HullHalfEdge
{
	/// Next edge index CCW
	uint8_t next;

	/// Twin edge index
	uint8_t twin;

	/// index of origin vertex and point
	uint8_t origin;

	/// Face to the left of this edge
	uint8_t face;
} b3HullHalfEdge;

/// A hull face. Hulls use a half-edge data structure, so a face
/// can be determined from a single half-edge index.
typedef struct b3HullFace
{
	/// An arbitrary half-edge on this face
	uint8_t edge;
} b3HullFace;

/// 64-bit hull version. Useful for validating serialized data.
#define B3_HULL_VERSION 0x9D4716CE3793900Eull

/// A convex hull.
/// @note This data structure has data hanging off the end and cannot be directly copied.
typedef struct b3HullData
{
	/// Version must be first and match B3_HULL_VERSION
	uint64_t version;

	/// The total number of bytes for this hull.
	int byteCount;

	/// Hash of this hull (this field is zero when the hash is computed).
	uint32_t hash;

	/// Axis-aligned box in local space.
	b3AABB aabb;

	/// Surface area, typically in squared meters.
	float surfaceArea;

	/// Volume, typically in m^3.
	float volume;

	/// The radius of the largest sphere at the center.
	float innerRadius;

	/// The local centroid
	b3Vec3 center;

	/// The inertia tensor about the centroid.
	b3Matrix3 centralInertia;

	/// The vertex count.
	int vertexCount;

	/// Offset of the vertex array in bytes from the struct address.
	int vertexOffset;

	/// Offset of the point array in bytes from the struct address.
	int pointOffset;

	/// This is the half-edge count (double the edge count)
	int edgeCount;

	/// Offset of the edge array in bytes from the struct address.
	int edgeOffset;

	/// The face count. Hulls faces are convex polygons.
	int faceCount;

	/// Offset of the face array in bytes from the struct address.
	int faceOffset;

	/// Offset of the face plane array in bytes from the struct address.
	int planeOffset;

	/// Explicit padding. Hull identity is a content hash and memcmp over raw bytes,
	/// so there must be no unnamed padding for struct copies to scramble.
	int padding;
} b3HullData;

/// Efficient box hull
typedef struct b3BoxHull
{
	/// The embedded hull. So the offsets index into the arrays that follow.
	b3HullData base;
	b3HullVertex boxVertices[8]; ///< Box vertices.
	b3Vec3 boxPoints[8];		 ///< Box points.
	b3HullHalfEdge boxEdges[24]; ///< Box half-edges.
	b3HullFace boxFaces[6];		 ///< Box faces.
	uint8_t padding[2];			 ///< Explicit padding, see b3HullData::padding.
	b3Plane boxPlanes[6];		 ///< Box face planes.
} b3BoxHull;

/**@}*/ // hull

/**
 * @defgroup mesh Triangle Mesh
 * @brief Triangle mesh collision shape
 * @{
 */

/// This is used to create a re-usable collision mesh
typedef struct b3MeshDef
{
	/// Triangle vertices
	b3Vec3* vertices;

	/// Triangle vertex indices. 3 for each triangle.
	int32_t* indices;

	/// Triangle material index. 1 per triangle. Indexes into b3ShapeDef::materials.
	/// This allows different run-time material data to be associated with different
	/// instances of this mesh.
	uint8_t* materialIndices;

	/// Tolerance for vertex welding in length units.
	float weldTolerance;

	/// The vertex count. Must be 3 or more.
	int vertexCount;

	/// The triangle count. Must be 1 or more.
	int triangleCount;

	/// Optionally weld nearby vertices.
	bool weldVertices;

	/// Use the median split instead of SAH to speed up mesh creation. Good
	/// for meshes that are structured like a grid.
	bool useMedianSplit;

	/// Compute triangle adjacency information using shared edges
	bool identifyEdges;
} b3MeshDef;

/// 64-bit mesh version. Useful for validating serialized data.
#define B3_MESH_VERSION 0xABD11AB62A6E886Dull

/// Triangle mesh edge flags.
typedef enum b3MeshEdgeFlags
{
	b3_concaveEdge1 = 0x01,
	b3_concaveEdge2 = 0x02,
	b3_concaveEdge3 = 0x04,

	b3_inverseConcaveEdge1 = 0x10,
	b3_inverseConcaveEdge2 = 0x20,
	b3_inverseConcaveEdge3 = 0x40,

	b3_allConcaveEdges = b3_concaveEdge1 | b3_concaveEdge2 | b3_concaveEdge3,

	b3_flatEdge1 = b3_concaveEdge1 | b3_inverseConcaveEdge1,
	b3_flatEdge2 = b3_concaveEdge2 | b3_inverseConcaveEdge2,
	b3_flatEdge3 = b3_concaveEdge3 | b3_inverseConcaveEdge3,

	b3_allFlatEdges = b3_flatEdge1 | b3_flatEdge2 | b3_flatEdge3,

} b3MeshEdgeFlags;

/// A mesh triangle.
typedef struct b3MeshTriangle
{
	int32_t index1; ///< Index of vertex 1.
	int32_t index2; ///< Index of vertex 2.
	int32_t index3; ///< Index of vertex 3.
} b3MeshTriangle;

/// A mesh BVH node.
typedef struct b3MeshNode
{
	/// The lower bound of the node AABB. Strategic placement for SIMD.
	b3Vec3 lowerBound;

	/// Anonymous union.
	union
	{
		/// Internal node
		struct
		{
			/// Split axis. 0, 1, or 2.
			uint32_t axis : 2;
			/// Offset of the second child node.
			uint32_t childOffset : 30;
		} asNode;

		/// Leaf node
		struct
		{
			/// Aligned with axis above and has value of 3 if this is a leaf.
			uint32_t type : 2;

			/// The number of triangles for this leaf node.
			uint32_t triangleCount : 30;
		} asLeaf;
	} data;

	/// The upper bound of the node AABB.  Strategic placement for SIMD.
	b3Vec3 upperBound;

	/// The index of the leaf triangles.
	uint32_t triangleOffset;
} b3MeshNode;

/// This is a sorted triangle collision bounding volume hierarchy.
/// @note This struct has data hanging off the end and cannot be directly copied.
typedef struct b3MeshData
{
	/// Version must be first.
	uint64_t version;

	/// The total number of bytes for this mesh.
	int byteCount;

	/// Hash of this mesh (this field is zero when the hash is computed)
	uint32_t hash;

	/// Local axis-aligned box.
	b3AABB bounds;

	/// Combined surface area of all triangles. Single-sided.
	float surfaceArea;

	/// The height of the bounding volume hierarchy.
	int treeHeight;

	/// The number of degenerate triangles. Diagnostic.
	int degenerateCount;

	/// Offset of the node array in bytes from the struct address.
	int nodeOffset;

	/// The number of BVH nodes.
	int nodeCount;

	/// Offset of the vertex array in bytes from the struct address.
	int vertexOffset;

	/// The number of vertices.
	int vertexCount;

	/// Offset of the triangle array in bytes from the struct address.
	int triangleOffset;

	/// The number of triangles.
	int triangleCount;

	/// Offset of the material array in bytes from the struct address.
	int materialOffset;

	/// The number of materials.
	int materialCount;

	/// Offset of the triangle flag array in bytes from the struct address.
	int flagsOffset;
} b3MeshData;

/// This allows mesh data to be re-used with different scales.
typedef struct b3Mesh
{
	/// Immutable pointer to the mesh data.
	const b3MeshData* data;

	/// This scale may be non-uniform and have negative components. However,
	/// no component may be very small in magnitude.
	b3Vec3 scale;
} b3Mesh;

/**@}*/ // mesh

/**
 * @defgroup height_field Height Field
 * @brief Height field collision shape
 * @{
 */

/// Data used to create a height field
typedef struct b3HeightFieldDef
{
	/// Grid point heights
	/// count = countX * countZ
	float* heights;

	/// Grid cell material
	/// A value of 0xFF is reserved for holes
	/// count = (countX - 1) * (countZ - 1)
	uint8_t* materialIndices;

	/// The height field scale. All components must be positive values.
	b3Vec3 scale;

	/// The number of grid lines along the x-axis.
	int countX;

	/// The number of grid lines along the z-axis.
	int countZ;

	/// Global minimum and maximum heights used for quantization. This is important
	/// if you want height fields to be placed next to each other and line up exactly.
	/// In that case, both height fields should use the same minimum and maximum heights.
	/// All height values are clamped to this range.
	/// These values are in unscaled space.
	float globalMinimumHeight;

	/// The maximum.
	float globalMaximumHeight;

	/// Use clock-wise winding. This effectively inverts the height-field along the y-axis.
	bool clockwiseWinding;
} b3HeightFieldDef;

/// This material index is used to designate holes in a height field.
#define B3_HEIGHT_FIELD_HOLE 0xFF

/// 64-bit height-field version. Useful for validating serialized data.
#define B3_HEIGHT_FIELD_VERSION 0x8B18CBD138A6BC84ull

/// A height field with compressed storage.
/// @note This data structure has data hanging off the end and cannot be directly copied.
typedef struct b3HeightFieldData
{
	/// Version must be first and match B3_HEIGHT_FIELD_VERSION
	uint64_t version;

	/// The total number of bytes for this height field.
	int byteCount;

	/// Hash of this height field (this field is zero when the hash is computed).
	uint32_t hash;

	/// The local axis-aligned bounding box.
	b3AABB aabb;

	/// The minimum y value.
	float minHeight;

	/// The maximum y value
	float maxHeight;

	/// The quantization scale.
	float heightScale;

	/// The overall scale.
	b3Vec3 scale;

	/// The number of grid columns along the local x-axis.
	int columnCount;

	/// The number of grid rows along the local z-axis.
	int rowCount;

	/// Offset of the compressed height array in bytes from the struct address.
	/// uint16_t, one per grid point.
	int heightsOffset;

	/// Offset of the material index array in bytes from the struct address.
	/// uint8_t, one per cell.
	int materialOffset;

	/// Offset of the flag array in bytes from the struct address.
	/// uint8_t, one per triangle.
	int flagsOffset;

	/// Triangle winding.
	bool clockwise;

	/// Explicit padding. Identity is a content hash over raw bytes, so there must
	/// be no unnamed padding for struct copies to scramble.
	uint8_t padding[3];
} b3HeightFieldData;

/**@}*/ // height_field

/**
 * @defgroup compound Compound
 * @brief Compound collision shape
 * @{
 */

/// Definition for a capsule in a compound shape.
typedef struct b3CompoundCapsuleDef
{
	/// Local capsule.
	b3Capsule capsule;

	/// Material properties.
	b3SurfaceMaterial material;
} b3CompoundCapsuleDef;

/// Definition for a convex hull in a compound shape.
typedef struct b3CompoundHullDef
{
	/// Shared hull.
	const b3HullData* hull;

	/// Transform of the shared hull into compound local space.
	b3Transform transform;

	/// Material properties.
	b3SurfaceMaterial material;
} b3CompoundHullDef;

/// Definition for a triangle mesh in a compound shape.
typedef struct b3CompoundMeshDef
{
	/// Shared mesh.
	const b3MeshData* meshData;

	/// Transform of the shared mesh into compound local space.
	b3Transform transform;

	/// Local space non-uniform mesh scale. May have negative components.
	b3Vec3 scale;

	/// Material properties.
	/// This array must line up with the material indices on the triangles.
	const b3SurfaceMaterial* materials;

	/// Number of materials.
	int materialCount;
} b3CompoundMeshDef;

/// Definition for a sphere in a compound shape.
typedef struct b3CompoundSphereDef
{
	/// Local sphere.
	b3Sphere sphere;

	/// Material properties.
	b3SurfaceMaterial material;
} b3CompoundSphereDef;

/// Definition for creating a compound shape. All this data is fully cloned
/// into the run-time compound shape.
typedef struct b3CompoundDef
{
	/// Capsule instances.
	b3CompoundCapsuleDef* capsules;

	/// Number of capsules.
	int capsuleCount;

	/// Hulls instances.
	b3CompoundHullDef* hulls;

	/// Number of hull instances.
	int hullCount;

	/// Mesh instances.
	b3CompoundMeshDef* meshes;

	/// Number of mesh instances.
	int meshCount;

	/// Sphere instances.
	b3CompoundSphereDef* spheres;

	/// Number of spheres.
	int sphereCount;
} b3CompoundDef;

/// The compound version depends on the tree, mesh, and hull versions.
#define B3_COMPOUND_VERSION ( 0x830778DB07086EB4ull ^ B3_DYNAMIC_TREE_VERSION ^ B3_MESH_VERSION ^ B3_HULL_VERSION )

/// Meshes used in compounds have limited space for materials. If you have
/// a mesh with many materials, you can use it outside of the compound.
#define B3_MAX_COMPOUND_MESH_MATERIALS 4

/// The runtime data for a baked compound shape. This is a potentially large yet highly optimized
/// data structure. It can contain thousands of child shapes, yet at runtime it populates
/// into the world as a single shape in the runtime broad-phase.
/// This data structure has data living off the end and must be accessed using offsets.
/// Accessors are provided for user relevant data.
/// Note: you don't need to use this to create runtime compounds. For runtime compounds you can
/// add multiple shapes to a body using the regular shape creation functions.
typedef struct b3CompoundData
{
	/// The compound version is always first.
	uint64_t version;

	/// The total number of bytes for this compound.
	int byteCount;

	/// Offset of the tree node array in bytes from the struct address.
	int nodeOffset;

	/// Immutable dynamic tree. The tree node pointer must be fixed up using the node offset
	b3DynamicTree tree;

	/// Offset of the material array in bytes from the struct address.
	int materialOffset;

	/// The number of materials.
	int materialCount;

	/// Offset of the capsule array in bytes from the struct address.
	int capsuleOffset;

	/// The number of capsules.
	int capsuleCount;

	/// Offset of the hull instance array in bytes from the struct address.
	int hullOffset;

	/// The number of hull instances.
	int hullCount;

	/// The number of unique hulls. Diagnostic.
	int sharedHullCount;

	/// Offset of the mesh instance array in bytes from the struct address.
	int meshOffset;

	/// The number of mesh instances.
	int meshCount;

	/// The number of unique meshes. Diagnostic.
	int sharedMeshCount;

	/// Offset of the sphere array in bytes from the struct address.
	int sphereOffset;

	/// The number of spheres.
	int sphereCount;
} b3CompoundData;

/// A capsule that lives in a compound.
typedef struct b3CompoundCapsule
{
	/// Local capsule.
	b3Capsule capsule;

	/// Index to a shared material.
	int materialIndex;
} b3CompoundCapsule;

/// A hull that lives in a compound.
typedef struct b3CompoundHull
{
	/// Pointer to the unique shared hull.
	const b3HullData* hull;

	/// The transform of this hull instance.
	b3Transform transform;

	/// Index to a shared material.
	int materialIndex;
} b3CompoundHull;

/// A mesh with non-uniform scale that lives in a compound.
typedef struct b3CompoundMesh
{
	/// Pointer to the unique shared mesh.
	const b3MeshData* meshData;

	/// The transform of this mesh instance.
	b3Transform transform;

	/// Non-uniform scale of this mesh instance.
	b3Vec3 scale;

	/// This is used to access the surface material from b3GetCompoundMaterials.
	/// Requires an extra level of indirection. The triangle material index
	/// is clamped to B3_MAX_COMPOUND_MESH_MATERIALS.
	/// materialIndex = materialIndices[triangle->materialIndex]
	int materialIndices[B3_MAX_COMPOUND_MESH_MATERIALS];
} b3CompoundMesh;

/// A sphere that lives in a compound.
typedef struct b3CompoundSphere
{
	/// Local sphere.
	b3Sphere sphere;

	/// Index to a shared material.
	int materialIndex;
} b3CompoundSphere;

/// Child shape of a compound
typedef struct b3ChildShape
{
	/// Tagged union.
	union
	{
		b3Capsule capsule;	///< Capsule.
		const b3HullData* hull; ///< Hull.
		b3Mesh mesh;		///< Mesh.
		b3Sphere sphere;	///< Sphere.
	};

	/// Transform of the shape into compound local space.
	b3Transform transform;

	/// Material indices. Index 0 is used for convex shapes.
	/// todo limit to 64K?
	int materialIndices[B3_MAX_COMPOUND_MESH_MATERIALS];

	/// The shape type (union tag).
	b3ShapeType type;
} b3ChildShape;

/// Callback for compound overlap queries.
typedef bool b3CompoundQueryFcn( const b3CompoundData* compound, int childIndex, void* context );

/**@}*/ // compound

/**@}*/ // geometry

/**
 * @defgroup collision Shape Collision
 * Collide pairs of shapes.
 * @{
 */

/// A manifold point is a contact point belonging to a contact manifold.
/// It holds details related to the geometry and dynamics of the contact points.
/// Box3D uses speculative collision so some contact points may be separated.
/// You may use the maxNormalImpulse to determine if there was an interaction during
/// the time step.
typedef struct b3ManifoldPoint
{
	/// Location of the contact point relative to the bodyA center of mass in world space.
	b3Vec3 anchorA;

	/// Location of the contact point relative to the bodyB center of mass in world space.
	b3Vec3 anchorB;

	/// The separation of the contact point, negative if penetrating
	float separation;

	/// Cached separation used for contact recycling
	float baseSeparation;

	/// The impulse along the manifold normal vector. Since Box3D uses sub-stepping, this is
	/// result from the final sub-step.
	float normalImpulse;

	/// The total normal impulse applied during sub-stepping. This is important
	/// to identify speculative contact points that had an interaction in the time step.
	float totalNormalImpulse;

	/// Relative normal velocity pre-solve. Used for hit events. If the normal impulse is
	/// zero then there was no hit. Negative means shapes are approaching.
	float normalVelocity;

	/// Local point for matching
	/// Uniquely identifies a contact point between two shapes
	uint32_t featureId;

	/// Triangle index if one of the shapes is a mesh or height field
	int triangleIndex;

	/// Did this contact point exist in the previous step?
	bool persisted;
} b3ManifoldPoint;

/// A contact manifold describes the contact points between colliding shapes.
/// @note Box3D uses speculative collision so some contact points may be separated.
typedef struct b3Manifold
{
	/// The manifold points. There may be 1 to 4 valid points.
	b3ManifoldPoint points[B3_MAX_MANIFOLD_POINTS];

	/// The unit normal vector in world space, points from shape A to shape B
	b3Vec3 normal;

	/// Central friction angular impulse (applied about the normal)
	float twistImpulse;

	/// Central friction linear impulse
	b3Vec3 frictionImpulse;

	/// Rolling resistance angular impulse
	b3Vec3 rollingImpulse;

	/// The number of contact points, will be 0 to 4
	int pointCount;

} b3Manifold;

/// Cached separating axis feature.
typedef enum
{
	b3_invalidAxis = 0,
	b3_backsideAxis,
	b3_faceAxisA,
	b3_faceAxisB,
	b3_edgePairAxis,
	b3_closestPointsAxis,

	/// These are for testing
	b3_manualFaceAxisA,
	b3_manualFaceAxisB,
	b3_manualEdgePairAxis,
} b3SeparatingFeature;

/// Cached triangle feature.
typedef enum
{
	b3_featureNone = 0,
	b3_featureTriangleFace,
	b3_featureHullFace,
	/// v1-v2
	b3_featureEdge1,
	/// v2-v3
	b3_featureEdge2,
	/// v3-v1
	b3_featureEdge3,
	b3_featureVertex1,
	b3_featureVertex2,
	b3_featureVertex3
} b3TriangleFeature;

/// Separating axis test cache. Provides temporal acceleration of collision routines.
typedef struct
{
	/// The separation when the cache is populated. Negative for overlap.
	float separation;

	/// b3SeparatingFeature.
	uint8_t type;

	/// Index of the feature on shape A.
	uint8_t indexA;

	/// Index of the feature on shape B.
	uint8_t indexB;

	/// Was the cache re-used?
	uint8_t hit;
} b3SATCache;

/// Contact points are always the result of two edges intersecting.
/// It can be two edges of the same shape, which is just a shape vertex.
/// Or a contact point can be the result of two edges crossing from different shapes.
/// This is designed to support hull versus hull, but it is adapted to work
/// with all shape types. The feature pair is used to identify contact points
/// for temporal coherence and warm starting.
typedef struct b3FeaturePair
{
	/// Incoming type (either edge on shape A or shape B)
	uint8_t owner1;
	/// Incoming edge index (into associated shape array)
	uint8_t index1;
	/// Outgoing type (either edge on shape A or shape B)
	uint8_t owner2;
	/// Outgoing edge index (into associated shape array)
	uint8_t index2;
} b3FeaturePair;

/// A local manifold point and normal in frame A.
typedef struct b3LocalManifoldPoint
{
	/// Local point in frame A.
	b3Vec3 point;

	/// The contact point separation. Negative for overlap.
	float separation;

	/// The feature pair for this point.
	b3FeaturePair pair;

	/// The triangle index when collide with a mesh or height-field.
	int triangleIndex;
} b3LocalManifoldPoint;

/// A local manifold with no dynamic information. Used by b3Collide functions.
typedef struct b3LocalManifold
{
	/// Local normal in frame A.
	b3Vec3 normal;

	/// The triangle normal.
	b3Vec3 triangleNormal;

	/// The manifold points. From a point buffer.
	b3LocalManifoldPoint* points;

	/// The number of manifold points. Only bounded by the buffer capacity.
	int pointCount;

	/// The index of the triangle.
	int triangleIndex;

	int i1; ///< Vertex 1 index.
	int i2; ///< Vertex 2 index.
	int i3; ///< Vertex 3 index.

	/// The squared distance of a sphere from a triangle. For ghost collision reduction.
	float squaredDistance;

	/// The triangle feature involved.
	b3TriangleFeature feature;

	/// b3MeshEdgeFlags.
	int triangleFlags;
} b3LocalManifold;

/**@}*/ // collision

/**
 * @defgroup debug_draw Debug Draw
 * @{
 */

/// These colors are used for debug draw and mostly match the named SVG colors.
/// See https://www.rapidtables.com/web/color/index.html
/// https://johndecember.com/html/spec/colorsvg.html
/// https://upload.wikimedia.org/wikipedia/commons/2/2b/SVG_Recognized_color_keyword_names.svg
typedef enum b3HexColor
{
	b3_colorAliceBlue = 0xF0F8FF,
	b3_colorAntiqueWhite = 0xFAEBD7,
	b3_colorAqua = 0x00FFFF,
	b3_colorAquamarine = 0x7FFFD4,
	b3_colorAzure = 0xF0FFFF,
	b3_colorBeige = 0xF5F5DC,
	b3_colorBisque = 0xFFE4C4,
	b3_colorBlack = 0x000000,
	b3_colorBlanchedAlmond = 0xFFEBCD,
	b3_colorBlue = 0x0000FF,
	b3_colorBlueViolet = 0x8A2BE2,
	b3_colorBrown = 0xA52A2A,
	b3_colorBurlywood = 0xDEB887,
	b3_colorCadetBlue = 0x5F9EA0,
	b3_colorChartreuse = 0x7FFF00,
	b3_colorChocolate = 0xD2691E,
	b3_colorCoral = 0xFF7F50,
	b3_colorCornflowerBlue = 0x6495ED,
	b3_colorCornsilk = 0xFFF8DC,
	b3_colorCrimson = 0xDC143C,
	b3_colorCyan = 0x00FFFF,
	b3_colorDarkBlue = 0x00008B,
	b3_colorDarkCyan = 0x008B8B,
	b3_colorDarkGoldenRod = 0xB8860B,
	b3_colorDarkGray = 0xA9A9A9,
	b3_colorDarkGreen = 0x006400,
	b3_colorDarkKhaki = 0xBDB76B,
	b3_colorDarkMagenta = 0x8B008B,
	b3_colorDarkOliveGreen = 0x556B2F,
	b3_colorDarkOrange = 0xFF8C00,
	b3_colorDarkOrchid = 0x9932CC,
	b3_colorDarkRed = 0x8B0000,
	b3_colorDarkSalmon = 0xE9967A,
	b3_colorDarkSeaGreen = 0x8FBC8F,
	b3_colorDarkSlateBlue = 0x483D8B,
	b3_colorDarkSlateGray = 0x2F4F4F,
	b3_colorDarkTurquoise = 0x00CED1,
	b3_colorDarkViolet = 0x9400D3,
	b3_colorDeepPink = 0xFF1493,
	b3_colorDeepSkyBlue = 0x00BFFF,
	b3_colorDimGray = 0x696969,
	b3_colorDodgerBlue = 0x1E90FF,
	b3_colorFireBrick = 0xB22222,
	b3_colorFloralWhite = 0xFFFAF0,
	b3_colorForestGreen = 0x228B22,
	b3_colorFuchsia = 0xFF00FF,
	b3_colorGainsboro = 0xDCDCDC,
	b3_colorGhostWhite = 0xF8F8FF,
	b3_colorGold = 0xFFD700,
	b3_colorGoldenRod = 0xDAA520,
	b3_colorGray = 0x808080,
	b3_colorGreen = 0x008000,
	b3_colorGreenYellow = 0xADFF2F,
	b3_colorHoneyDew = 0xF0FFF0,
	b3_colorHotPink = 0xFF69B4,
	b3_colorIndianRed = 0xCD5C5C,
	b3_colorIndigo = 0x4B0082,
	b3_colorIvory = 0xFFFFF0,
	b3_colorKhaki = 0xF0E68C,
	b3_colorLavender = 0xE6E6FA,
	b3_colorLavenderBlush = 0xFFF0F5,
	b3_colorLawnGreen = 0x7CFC00,
	b3_colorLemonChiffon = 0xFFFACD,
	b3_colorLightBlue = 0xADD8E6,
	b3_colorLightCoral = 0xF08080,
	b3_colorLightCyan = 0xE0FFFF,
	b3_colorLightGoldenRodYellow = 0xFAFAD2,
	b3_colorLightGray = 0xD3D3D3,
	b3_colorLightGreen = 0x90EE90,
	b3_colorLightPink = 0xFFB6C1,
	b3_colorLightSalmon = 0xFFA07A,
	b3_colorLightSeaGreen = 0x20B2AA,
	b3_colorLightSkyBlue = 0x87CEFA,
	b3_colorLightSlateGray = 0x778899,
	b3_colorLightSteelBlue = 0xB0C4DE,
	b3_colorLightYellow = 0xFFFFE0,
	b3_colorLime = 0x00FF00,
	b3_colorLimeGreen = 0x32CD32,
	b3_colorLinen = 0xFAF0E6,
	b3_colorMagenta = 0xFF00FF,
	b3_colorMaroon = 0x800000,
	b3_colorMediumAquaMarine = 0x66CDAA,
	b3_colorMediumBlue = 0x0000CD,
	b3_colorMediumOrchid = 0xBA55D3,
	b3_colorMediumPurple = 0x9370DB,
	b3_colorMediumSeaGreen = 0x3CB371,
	b3_colorMediumSlateBlue = 0x7B68EE,
	b3_colorMediumSpringGreen = 0x00FA9A,
	b3_colorMediumTurquoise = 0x48D1CC,
	b3_colorMediumVioletRed = 0xC71585,
	b3_colorMidnightBlue = 0x191970,
	b3_colorMintCream = 0xF5FFFA,
	b3_colorMistyRose = 0xFFE4E1,
	b3_colorMoccasin = 0xFFE4B5,
	b3_colorNavajoWhite = 0xFFDEAD,
	b3_colorNavy = 0x000080,
	b3_colorOldLace = 0xFDF5E6,
	b3_colorOlive = 0x808000,
	b3_colorOliveDrab = 0x6B8E23,
	b3_colorOrange = 0xFFA500,
	b3_colorOrangeRed = 0xFF4500,
	b3_colorOrchid = 0xDA70D6,
	b3_colorPaleGoldenRod = 0xEEE8AA,
	b3_colorPaleGreen = 0x98FB98,
	b3_colorPaleTurquoise = 0xAFEEEE,
	b3_colorPaleVioletRed = 0xDB7093,
	b3_colorPapayaWhip = 0xFFEFD5,
	b3_colorPeachPuff = 0xFFDAB9,
	b3_colorPeru = 0xCD853F,
	b3_colorPink = 0xFFC0CB,
	b3_colorPlum = 0xDDA0DD,
	b3_colorPowderBlue = 0xB0E0E6,
	b3_colorPurple = 0x800080,
	b3_colorRebeccaPurple = 0x663399,
	b3_colorRed = 0xFF0000,
	b3_colorRosyBrown = 0xBC8F8F,
	b3_colorRoyalBlue = 0x4169E1,
	b3_colorSaddleBrown = 0x8B4513,
	b3_colorSalmon = 0xFA8072,
	b3_colorSandyBrown = 0xF4A460,
	b3_colorSeaGreen = 0x2E8B57,
	b3_colorSeaShell = 0xFFF5EE,
	b3_colorSienna = 0xA0522D,
	b3_colorSilver = 0xC0C0C0,
	b3_colorSkyBlue = 0x87CEEB,
	b3_colorSlateBlue = 0x6A5ACD,
	b3_colorSlateGray = 0x708090,
	b3_colorSnow = 0xFFFAFA,
	b3_colorSpringGreen = 0x00FF7F,
	b3_colorSteelBlue = 0x4682B4,
	b3_colorTan = 0xD2B48C,
	b3_colorTeal = 0x008080,
	b3_colorThistle = 0xD8BFD8,
	b3_colorTomato = 0xFF6347,
	b3_colorTurquoise = 0x40E0D0,
	b3_colorViolet = 0xEE82EE,
	b3_colorWheat = 0xF5DEB3,
	b3_colorWhite = 0xFFFFFF,
	b3_colorWhiteSmoke = 0xF5F5F5,
	b3_colorYellow = 0xFFFF00,
	b3_colorYellowGreen = 0x9ACD32,

	b3_colorBox2DRed = 0xDC3132,
	b3_colorBox2DBlue = 0x30AEBF,
	b3_colorBox2DGreen = 0x8CC924,
	b3_colorBox2DYellow = 0xFFEE8C
} b3HexColor;

/// Debug draw material preset. Optionally packed into the unused high byte of a
/// b3HexColor (or b3SurfaceMaterial::customColor) to drive the renderer's PBR
/// roughness and metalness. The low 24 bits stay RGB, so a plain 0xRRGGBB color
/// reads as b3_debugMaterialDefault and keeps the renderer's per-body-type look.
typedef enum b3DebugMaterial
{
	b3_debugMaterialDefault = 0,
	b3_debugMaterialMatte,
	b3_debugMaterialSoft,
	b3_debugMaterialDead,
	b3_debugMaterialGlossy,
	b3_debugMaterialMetallic
} b3DebugMaterial;

/// Pack an RGB color with a material preset for debug draw. The preset rides in
/// the high byte where the color converters ignore it.
B3_INLINE uint32_t b3MakeDebugColor( b3HexColor rgb, b3DebugMaterial material )
{
	return ( (uint32_t)rgb & 0x00FFFFFFu ) | ( (uint32_t)material << 24 );
}

/// Get the visualization color assigned to a constraint graph color slot. The last index
/// (B3_GRAPH_COLOR_COUNT - 1) is the overflow color.
B3_API b3HexColor b3GetGraphColor( int index );

/// This is sent to the user for debug shape creation. The user should know the type in case they have
/// custom sphere or capsule rendering.
typedef struct b3DebugShape
{
	/// Shape id.
	b3ShapeId shapeId;

	/// Shape type.
	b3ShapeType type;

	/// Tagged union.
	union
	{
		const b3Capsule* capsule;		  ///< Capsule shape.
		const b3CompoundData* compound;		  ///< Compound shape.
		const b3HeightFieldData* heightField; ///< Height-field shape.
		const b3HullData* hull;			  ///< Convex hull shape.
		const b3Mesh* mesh;				  ///< Mesh shape with scale.
		const b3Sphere* sphere;			  ///< Sphere shape.
	};
} b3DebugShape;

/// This struct is passed to b3World_Draw to draw a debug view of the simulation world.
/// Callbacks receive world coordinates. In large world mode the translation is double precision so
/// it stays accurate far from the origin. Shift into your own camera frame inside the callbacks.
typedef struct b3DebugDraw
{
	/// Draws a shape and returns true if drawing should continue
	bool ( *DrawShapeFcn )( void* userShape, b3WorldTransform transform, b3HexColor color, void* context );

	/// Draw a line segment.
	void ( *DrawSegmentFcn )( b3Pos p1, b3Pos p2, b3HexColor color, void* context );

	/// Draw a transform. Choose your own length scale.
	void ( *DrawTransformFcn )( b3WorldTransform transform, void* context );

	/// Draw a point.
	void ( *DrawPointFcn )( b3Pos p, float size, b3HexColor color, void* context );

	/// Draw a sphere.
	void ( *DrawSphereFcn )( b3Pos p, float radius, b3HexColor color, float alpha, void* context );

	/// Draw a capsule.
	void ( *DrawCapsuleFcn )( b3Pos p1, b3Pos p2, float radius, b3HexColor color, float alpha, void* context );

	/// Draw a bounding box.
	void ( *DrawBoundsFcn )( b3AABB aabb, b3HexColor color, void* context );

	/// Draw an oriented box.
	void ( *DrawBoxFcn )( b3Vec3 extents, b3WorldTransform transform, b3HexColor color, void* context );

	/// Draw a string in world space
	void ( *DrawStringFcn )( b3Pos p, const char* s, b3HexColor color, void* context );

	/// World bounds to use for debug draw
	b3AABB drawingBounds;

	/// Scale to use when drawing forces
	float forceScale;

	/// Global scaling for joint drawing
	float jointScale;

	/// Option to draw shapes
	bool drawShapes;

	/// Option to draw joints
	bool drawJoints;

	/// Option to draw additional information for joints
	bool drawJointExtras;

	/// Option to draw the bounding boxes for shapes
	bool drawBounds;

	/// Option to draw the mass and center of mass of dynamic bodies
	bool drawMass;

	/// Option to draw the sleep information for dynamic and kinematic bodies
	bool drawSleep;

	/// Option to draw body names
	bool drawBodyNames;

	/// Option to draw contact points
	bool drawContacts;

	/// Draw contact anchor A or B
	int drawAnchorA;

	/// Option to visualize the graph coloring used for contacts and joints
	bool drawGraphColors;

	/// Option to draw contact features
	bool drawContactFeatures;

	/// Option to draw contact normals
	bool drawContactNormals;

	/// Option to draw contact normal forces
	bool drawContactForces;

	/// Option to draw contact friction forces
	bool drawFrictionForces;

	/// Option to draw islands as bounding boxes
	bool drawIslands;

	/// User context that is passed as an argument to drawing callback functions
	void* context;
} b3DebugDraw;

/// Create a debug draw struct with default values.
B3_API b3DebugDraw b3DefaultDebugDraw( void );

/**@}*/ // debug_draw
