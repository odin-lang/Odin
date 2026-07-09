// SPDX-FileCopyrightText: 2025 Erin Catto
// SPDX-License-Identifier: MIT

#pragma once

#include "base.h"
#include "collision.h"
#include "id.h"
#include "math_functions.h"
#include "types.h"

#include <stdbool.h>

/**
 * @defgroup world World
 * These functions allow you to create a simulation world.
 *
 * You can add rigid bodies and joint constraints to the world and run the simulation. You can get contact
 * information to get contact points and normals as well as events. You can query the world, checking for overlaps and casting
 * rays or shapes. There is also debugging information such as debug draw, timing information, and counters. You can find
 * documentation here: https://box2d.org/
 * @{
 */

#if defined( BOX3D_DOUBLE_PRECISION )
// Force a link error if the application and library disagree on precision. A float app linking
// a double precision library, or the reverse, gets one unresolved external on the first call
// every program makes. CMake consumers inherit the define and cannot mismatch.
#define b3CreateWorld b3CreateWorldDoublePrecision
#endif

/// Create a world for rigid body simulation. A world contains bodies, shapes, and constraints. You may create
/// up to 128 worlds. Each world is completely independent and may be simulated in parallel.
/// @return the world id.
B3_API b3WorldId b3CreateWorld( const b3WorldDef* def );

/// Destroy a world
B3_API void b3DestroyWorld( b3WorldId worldId );

/// Get the current number of worlds
B3_API int b3GetWorldCount( void );

/// Get the maximum number of simultaneous worlds that have been created
B3_API int b3GetMaxWorldCount( void );

/// World id validation. Provides validation for up to 64K allocations.
B3_API bool b3World_IsValid( b3WorldId id );

/// Simulate a world for one time step. This performs collision detection, integration, and constraint solution.
/// @param worldId The world to simulate
/// @param timeStep The amount of time to simulate, this should be a fixed number. Usually 1/60.
/// @param subStepCount The number of sub-steps, increasing the sub-step count can increase accuracy. Usually 4.
B3_API void b3World_Step( b3WorldId worldId, float timeStep, int subStepCount );

/// Call this to draw shapes and other debug draw data
B3_API void b3World_Draw( b3WorldId worldId, b3DebugDraw* draw, uint64_t maskBits );

/// Get the world's bounds. This is the bounding box that covers the current simulation. May have a small
/// amount of padding.
B3_API b3AABB b3World_GetBounds( b3WorldId worldId );

/// Get the body events for the current time step. The event data is transient. Do not store a reference to this data.
B3_API b3BodyEvents b3World_GetBodyEvents( b3WorldId worldId );

/// Get sensor events for the current time step. The event data is transient. Do not store a reference to this data.
B3_API b3SensorEvents b3World_GetSensorEvents( b3WorldId worldId );

/// Get contact events for this current time step. The event data is transient. Do not store a reference to this data.
B3_API b3ContactEvents b3World_GetContactEvents( b3WorldId worldId );

/// Get the joint events for the current time step. The event data is transient. Do not store a reference to this data.
B3_API b3JointEvents b3World_GetJointEvents( b3WorldId worldId );

/// Overlap test for all shapes that *potentially* overlap the provided AABB
B3_API b3TreeStats b3World_OverlapAABB( b3WorldId worldId, b3AABB aabb, b3QueryFilter filter, b3OverlapResultFcn* fcn,
										void* context );

/// Overlap test for all shapes that overlap the provided shape proxy. The proxy points are relative
/// to the world origin, which lets the query stay precise far from the world origin.
B3_API b3TreeStats b3World_OverlapShape( b3WorldId worldId, b3Pos origin, const b3ShapeProxy* proxy, b3QueryFilter filter,
										 b3OverlapResultFcn* fcn, void* context );

/// Cast a ray into the world to collect shapes in the path of the ray.
/// Your callback function controls whether you get the closest point, any point, or n-points.
/// @note The callback function may receive shapes in any order
/// @param worldId The world to cast the ray against
/// @param origin The start point of the ray
/// @param translation The translation of the ray from the start point to the end point
/// @param filter Contains bit flags to filter unwanted shapes from the results
/// @param fcn A user implemented callback function
/// @param context A user context that is passed along to the callback function
///	@return traversal performance counters
B3_API b3TreeStats b3World_CastRay( b3WorldId worldId, b3Pos origin, b3Vec3 translation, b3QueryFilter filter,
									b3CastResultFcn* fcn, void* context );

/// Cast a ray into the world to collect the closest hit. This is a convenience function. Ignores initial overlap.
/// This is less general than b3World_CastRay() and does not allow for custom filtering.
B3_API b3RayResult b3World_CastRayClosest( b3WorldId worldId, b3Pos origin, b3Vec3 translation, b3QueryFilter filter );

/// Cast a shape through the world. Similar to a cast ray except that a shape is cast instead of a point.
/// The proxy points are relative to the origin and the hit points come back as world positions, so the
/// cast stays precise far from the world origin.
///	@see b3World_CastRay
B3_API b3TreeStats b3World_CastShape( b3WorldId worldId, b3Pos origin, const b3ShapeProxy* proxy, b3Vec3 translation,
									  b3QueryFilter filter, b3CastResultFcn* fcn, void* context );

/// Cast a capsule mover through the world. This is a special shape cast that handles sliding along other shapes while reducing
/// clipping. This is not a good source of information about what the mover is touching. Instead use the planes returned by
/// b3World_CollideMover.
/// @param worldId World to cast the mover against
/// @param origin World position the mover capsule is relative to
/// @param mover Capsule mover, relative to the origin
/// @param translation Desired mover translation
/// @param filter Contains bit flags to filter unwanted shapes from the results
/// @param fcn Optional callback for custom shape filtering
/// @param context A user context that is passed along to the callback function
/// @return the translation fraction
B3_API float b3World_CastMover( b3WorldId worldId, b3Pos origin, const b3Capsule* mover, b3Vec3 translation, b3QueryFilter filter,
								b3MoverFilterFcn* fcn, void* context );

/// Collide a capsule mover with the world, gathering collision planes that can be fed to b3SolvePlanes. Useful for
/// kinematic character movement. The mover and the returned planes are relative to the origin.
B3_API void b3World_CollideMover( b3WorldId worldId, b3Pos origin, const b3Capsule* mover, b3QueryFilter filter,
								  b3PlaneResultFcn* fcn, void* context );

/// Enable/disable sleep. If your application does not need sleeping, you can gain some performance
/// by disabling sleep completely at the world level.
/// @see b3WorldDef
B3_API void b3World_EnableSleeping( b3WorldId worldId, bool flag );

/// Is body sleeping enabled?
B3_API bool b3World_IsSleepingEnabled( b3WorldId worldId );

/// Enable/disable continuous collision between dynamic and static bodies. Generally you should keep continuous
/// collision enabled to prevent fast moving objects from going through static objects. The performance gain from
/// disabling continuous collision is minor.
/// @see b3WorldDef
B3_API void b3World_EnableContinuous( b3WorldId worldId, bool flag );

/// Is continuous collision enabled?
B3_API bool b3World_IsContinuousEnabled( b3WorldId worldId );

/// Adjust the restitution threshold. It is recommended not to make this value very small
/// because it will prevent bodies from sleeping. Usually in meters per second.
/// @see b3WorldDef
B3_API void b3World_SetRestitutionThreshold( b3WorldId worldId, float value );

/// Get the restitution speed threshold. Usually in meters per second.
B3_API float b3World_GetRestitutionThreshold( b3WorldId worldId );

/// Adjust the hit event threshold. This controls the collision speed needed to generate a b3ContactHitEvent.
/// Usually in meters per second.
/// @see b3WorldDef::hitEventThreshold
B3_API void b3World_SetHitEventThreshold( b3WorldId worldId, float value );

/// Get the hit event speed threshold. Usually in meters per second.
B3_API float b3World_GetHitEventThreshold( b3WorldId worldId );

/// Register the custom filter callback. This is optional.
B3_API void b3World_SetCustomFilterCallback( b3WorldId worldId, b3CustomFilterFcn* fcn, void* context );

/// Register the pre-solve callback. This is optional.
B3_API void b3World_SetPreSolveCallback( b3WorldId worldId, b3PreSolveFcn* fcn, void* context );

/// Set the gravity vector for the entire world. Box3D has no concept of an up direction and this
/// is left as a decision for the application. Usually in m/s^2.
/// @see b3WorldDef
B3_API void b3World_SetGravity( b3WorldId worldId, b3Vec3 gravity );

/// Get the gravity vector
B3_API b3Vec3 b3World_GetGravity( b3WorldId worldId );

/// Apply a radial explosion
/// @param worldId The world id
/// @param explosionDef The explosion definition
B3_API void b3World_Explode( b3WorldId worldId, const b3ExplosionDef* explosionDef );

/// Adjust contact tuning parameters
/// @param worldId The world id
/// @param hertz The contact stiffness (cycles per second)
/// @param dampingRatio The contact bounciness with 1 being critical damping (non-dimensional)
/// @param contactSpeed The maximum contact constraint push out speed (meters per second)
/// @note Advanced feature
B3_API void b3World_SetContactTuning( b3WorldId worldId, float hertz, float dampingRatio, float contactSpeed );

/// Set the contact point recycling distance. Setting this to zero disables contact point recycling.
/// Usually in meters.
B3_API void b3World_SetContactRecycleDistance( b3WorldId worldId, float recycleDistance );

/// Get the contact point recycling distance. Usually in meters.
B3_API float b3World_GetContactRecycleDistance( b3WorldId worldId );

/// Set the maximum linear speed. Usually in m/s.
B3_API void b3World_SetMaximumLinearSpeed( b3WorldId worldId, float maximumLinearSpeed );

/// Get the maximum linear speed. Usually in m/s.
B3_API float b3World_GetMaximumLinearSpeed( b3WorldId worldId );

/// Enable/disable constraint warm starting. Advanced feature for testing. Disabling
/// warm starting greatly reduces stability and provides no performance gain.
B3_API void b3World_EnableWarmStarting( b3WorldId worldId, bool flag );

/// Is constraint warm starting enabled?
B3_API bool b3World_IsWarmStartingEnabled( b3WorldId worldId );

/// Get the number of awake bodies
B3_API int b3World_GetAwakeBodyCount( b3WorldId worldId );

/// Get the current world performance profile
B3_API b3Profile b3World_GetProfile( b3WorldId worldId );

/// Get world counters and sizes
B3_API b3Counters b3World_GetCounters( b3WorldId worldId );

/// Get max capacity. This can be used with b3WorldDef to avoid run-time allocations and copies
B3_API b3Capacity b3World_GetMaxCapacity( b3WorldId worldId );

/// Set the user data pointer.
B3_API void b3World_SetUserData( b3WorldId worldId, void* userData );

/// Get the user data pointer.
B3_API void* b3World_GetUserData( b3WorldId worldId );

/// Set the friction callback. Passing NULL resets to default.
B3_API void b3World_SetFrictionCallback( b3WorldId worldId, b3FrictionCallback* callback );

/// Set the restitution callback. Passing NULL resets to default.
B3_API void b3World_SetRestitutionCallback( b3WorldId worldId, b3RestitutionCallback* callback );

/// Set the worker count. Must be in the range [1, B3_MAX_WORKERS]
B3_API void b3World_SetWorkerCount( b3WorldId worldId, int count );

/// Get the worker count.
B3_API int b3World_GetWorkerCount( b3WorldId worldId );

/// Dump memory stats to log.
B3_API void b3World_DumpMemoryStats( b3WorldId worldId );

/// Dump shape bounds to box3d_bounds.txt
B3_API void b3World_DumpShapeBounds( b3WorldId worldId, b3BodyType type );

/// This is for internal testing
B3_API void b3World_RebuildStaticTree( b3WorldId worldId );

/// This is for internal testing
B3_API void b3World_EnableSpeculative( b3WorldId worldId, bool flag );

/**
 * @defgroup recording Recording
 * @brief Record and replay world state for debugging.
 * @{
 */

/// Opaque recording handle. Create with b3CreateRecording, destroy with b3DestroyRecording.
typedef struct b3Recording b3Recording;

/// Create a recording buffer with an optional initial byte capacity.
/// Pass 0 to use the default (64 KiB). The buffer grows on demand.
/// @return a new recording, owned by the caller
B3_API b3Recording* b3CreateRecording( int byteCapacity );

/// Destroy a recording and free its buffer.
/// @param recording may be NULL
B3_API void b3DestroyRecording( b3Recording* recording );

/// Get a pointer to the raw recording bytes.
/// Valid until the recording buffer is modified or destroyed.
/// @param recording the recording handle
/// @return pointer to the byte buffer, or NULL if no bytes have been written
B3_API const uint8_t* b3Recording_GetData( const b3Recording* recording );

/// Get the number of bytes currently in the recording buffer.
/// @param recording the recording handle
B3_API int b3Recording_GetSize( const b3Recording* recording );

/// Begin recording world mutations into the provided buffer.
/// The buffer is reset on each call so a single b3Recording can be reused for multiple sessions.
/// @param worldId the world to record
/// @param recording the recording handle to write into
B3_API void b3World_StartRecording( b3WorldId worldId, b3Recording* recording );

/// End the current recording session. Writes the trailing geometry registry and
/// backpatches the header. The buffer remains valid until the recording is destroyed.
/// @param worldId the world currently being recorded
B3_API void b3World_StopRecording( b3WorldId worldId );

/// Save the recording buffer to a file. Returns true on success.
/// @param recording the recording to save
/// @param path file path to write
B3_API bool b3SaveRecordingToFile( const b3Recording* recording, const char* path );

/// Load a recording from a file. Returns NULL on failure (file not found, wrong magic).
/// The caller owns the returned recording and must destroy it with b3DestroyRecording.
/// @param path file path to read
B3_API b3Recording* b3LoadRecordingFromFile( const char* path );

/// Replay a recording from memory and verify it reproduces the same world-state hashes.
/// Stands up a fresh world, restores the seed snapshot, replays every op, and checks each embedded
/// StateHash record. Returns true if replay completed without id mismatches or hash divergences.
/// @param data pointer to recording bytes
/// @param size byte count of the recording
/// @param workerCount reserved for future multithreaded replay; pass 1 for now
B3_API bool b3ValidateReplay( const void* data, int size, int workerCount );

/// Opaque incremental replay player with a keyframe ring for O(interval) backward seek.
typedef struct b3RecPlayer b3RecPlayer;

/// Summary of a recording, read once at open so a viewer can frame and label it.
typedef struct b3RecPlayerInfo
{
	int frameCount;	   // total recorded steps
	int workerCount;   // worker count requested for the replay world
	float timeStep;	   // dt of the recorded steps
	int subStepCount;  // recorded sub-steps
	float lengthScale; // length units per meter in effect when recorded
	b3AABB bounds;	   // accumulated world bounds over the recording, zero-extent if unavailable
} b3RecPlayerInfo;

/// Create a player over a recording. Owns a private copy of the bytes.
/// @param data pointer to recording bytes
/// @param size byte count of the recording
/// @param workerCount worker count for the replay world; pass 1 to match a serial recording.
/// Replaying at a different count re-partitions the constraint graph, so the StateHash check
/// becomes a cross-thread determinism test. Adjustable later with b3RecPlayer_SetWorkerCount.
/// @return a new player, or NULL on bad header or deserialization failure
B3_API b3RecPlayer* b3RecPlayer_Create( const void* data, int size, int workerCount );

/// Destroy the player and free all memory. Restores the previous global length scale.
B3_API void b3RecPlayer_Destroy( b3RecPlayer* player );

/// Advance one frame. dispatch ops until the next Step completes.
/// @return true when a frame was stepped, false at end-of-recording
B3_API bool b3RecPlayer_StepFrame( b3RecPlayer* player );

/// Sub-step one frame. This will sub-step and return immediately after body creation.
/// The next call will execute the time step. This allows bodies to be rendered
/// at the creation pose.
B3_API void b3RecPlayer_SubStepFrame( b3RecPlayer* player );

/// Rewind to frame 0 (in-place restore so the world id stays stable).
B3_API void b3RecPlayer_Restart( b3RecPlayer* player );

/// Seek to a specific frame. Forward seek steps op-by-op; backward seek restores
/// the nearest keyframe then re-steps the remaining gap.
B3_API void b3RecPlayer_SeekFrame( b3RecPlayer* player, int targetFrame );

/// @return the world currently driven by this player
B3_API b3WorldId b3RecPlayer_GetWorldId( const b3RecPlayer* player );

/// @return the last fully-stepped frame index (0 before any step)
B3_API int b3RecPlayer_GetFrame( const b3RecPlayer* player );

/// @return total number of recorded frames
B3_API int b3RecPlayer_GetFrameCount( const b3RecPlayer* player );

/// @return true when the op stream is exhausted
B3_API bool b3RecPlayer_IsAtEnd( const b3RecPlayer* player );

/// @return true when the op stream is paused between body creation and world step.
B3_API bool b3RecPlayer_IsAtPreStep( const b3RecPlayer* player );

/// @return true when any StateHash mismatch has been detected
B3_API bool b3RecPlayer_HasDiverged( const b3RecPlayer* player );

/// @return a summary of the recording read at open: frame count, recorded tuning, and bounds
B3_API b3RecPlayerInfo b3RecPlayer_GetInfo( const b3RecPlayer* player );

/// @return the first frame at which replay diverged, or -1 if it has not diverged
B3_API int b3RecPlayer_GetDivergeFrame( const b3RecPlayer* player );

/// Set the worker count of the replay world. Clamped to [1, B3_MAX_WORKERS]. Applied to the live
/// world at once and reused whenever the player rebuilds its world on Restart or a backward seek.
/// Replaying at a different count than recorded re-partitions the constraint graph, so the StateHash
/// check becomes a cross-thread determinism test.
B3_API void b3RecPlayer_SetWorkerCount( b3RecPlayer* player, int count );

/// Tune the keyframe ring used to speed up backward seeking. A keyframe is a periodic snapshot the
/// player restores from instead of replaying from the start, trading memory for seek speed.
/// @param player the recording player
/// @param budgetBytes memory cap for the kept snapshots; the spacing widens to stay under it
/// @param minIntervalFrames finest spacing between keyframes, in frames
/// A zero budget or a non-positive interval keeps that value. Clears the existing ring, so call
/// b3RecPlayer_Restart afterward to repopulate it under the new policy.
B3_API void b3RecPlayer_SetKeyframePolicy( b3RecPlayer* player, size_t budgetBytes, int minIntervalFrames );

/// @return the keyframe memory budget in bytes
B3_API size_t b3RecPlayer_GetKeyframeBudget( const b3RecPlayer* player );

/// @return the finest keyframe spacing in frames
B3_API int b3RecPlayer_GetKeyframeMinInterval( const b3RecPlayer* player );

/// @return the current keyframe spacing in frames; starts at the min interval and doubles as the
/// ring evicts to stay under budget, so it reflects the effective backward-seek granularity now
B3_API int b3RecPlayer_GetKeyframeInterval( const b3RecPlayer* player );

/// @return the memory currently held by keyframe snapshots, in bytes
B3_API size_t b3RecPlayer_GetKeyframeBytes( const b3RecPlayer* player );

/// @return the number of bodies tracked in creation order (including holes for destroyed bodies)
B3_API int b3RecPlayer_GetBodyCount( const b3RecPlayer* player );

/// Resolve a creation ordinal to the live body id at the current frame.
/// @return the body id, or a null id if that ordinal is out of range or its body is destroyed
B3_API b3BodyId b3RecPlayer_GetBodyId( const b3RecPlayer* player, int index );

/// Wire host debug-shape callbacks into the player's replay world so a renderer can build
/// per-shape draw resources (the 3D sample needs this or the replay world draws nothing).
/// Rebuilds the current world under the new callbacks and rewinds to frame 0, so call it
/// once right after b3RecPlayer_Create and re-read the world id afterward. The callbacks
/// persist across Restart and backward seeks, which recreate the world internally.
/// @param player the player to configure
/// @param createDebugShape called when a replayed shape is added; returns a user draw handle
/// @param destroyDebugShape called when a replayed shape is removed; may be NULL
/// @param context user context passed to both callbacks
B3_API void b3RecPlayer_SetDebugShapeCallbacks( b3RecPlayer* player, b3CreateDebugShapeCallback* createDebugShape,
												b3DestroyDebugShapeCallback* destroyDebugShape, void* context );

/// Draw the spatial queries recorded during the most recently replayed frame, layered on top of the
/// world. Call after b3World_Draw. NULL draw function pointers are skipped.
/// @param player a valid player handle
/// @param draw debug draw callbacks
/// @param queryIndex index of the frame query to draw, or -1 to draw all of them
/// @param selectedIndex index of the query to emphasize (reserved color plus a label), or -1 for none
B3_API void b3RecPlayer_DrawFrameQueries( b3RecPlayer* player, b3DebugDraw* draw, int queryIndex, int selectedIndex );

/// The kind of a recorded spatial query, matching the public query and cast functions.
typedef enum b3RecQueryType
{
	b3_recQueryOverlapAABB,
	b3_recQueryOverlapShape,
	b3_recQueryCastRay,
	b3_recQueryCastShape,
	b3_recQueryCastRayClosest,
	b3_recQueryCastMover,
	b3_recQueryCollideMover,
} b3RecQueryType;

/// A spatial query recorded during a replayed frame, exposed for inspection.
typedef struct b3RecQueryInfo
{
	b3RecQueryType type;
	b3QueryFilter filter;
	b3AABB aabb;		// world-space bounds of the query, swept for casts
	b3Pos origin;		// query origin (zero for overlap AABB)
	b3Vec3 translation; // ray and cast translation
	int hitCount;		// number of recorded results
	uint64_t key;		// identity key, the hash of (id, name), 0 if untagged
	uint64_t id;		// query id, 0 if none
	const char* name;	// query label, NULL if none
} b3RecQueryInfo;

/// One result of a recorded spatial query.
typedef struct b3RecQueryHit
{
	b3ShapeId shape;
	b3Pos point;
	b3Vec3 normal;
	float fraction;
} b3RecQueryHit;

/// @return the number of spatial queries recorded for the most recently replayed frame
B3_API int b3RecPlayer_GetFrameQueryCount( const b3RecPlayer* player );

/// Get a recorded query from the most recently replayed frame by index.
B3_API b3RecQueryInfo b3RecPlayer_GetFrameQuery( const b3RecPlayer* player, int index );

/// Get one result of a recorded query from the most recently replayed frame.
B3_API b3RecQueryHit b3RecPlayer_GetFrameQueryHit( const b3RecPlayer* player, int queryIndex, int hitIndex );

/**@}*/ // recording

/** @} */ // world

/**
 * @defgroup body Body
 * This is the body API.
 * @{
 */

/// Create a rigid body given a definition. No reference to the definition is retained. So you can create the definition
/// on the stack and pass it as a pointer.
/// @code{.c}
/// b3BodyDef bodyDef = b3DefaultBodyDef();
/// b3BodyId myBodyId = b3CreateBody(myWorldId, &bodyDef);
/// @endcode
/// @warning This function is locked during callbacks.
B3_API b3BodyId b3CreateBody( b3WorldId worldId, const b3BodyDef* def );

/// Destroy a rigid body given an id. This destroys all shapes and joints attached to the body.
/// Do not keep references to the associated shapes and joints.
B3_API void b3DestroyBody( b3BodyId bodyId );

/// Body identifier validation. A valid body exists in a world and is non-null.
/// This can be used to detect orphaned ids. Provides validation for up to 64K allocations.
B3_API bool b3Body_IsValid( b3BodyId id );

/// Get the body type: static, kinematic, or dynamic
B3_API b3BodyType b3Body_GetType( b3BodyId bodyId );

/// Change the body type. This is an expensive operation. This automatically updates the mass
/// properties regardless of the automatic mass setting.
B3_API void b3Body_SetType( b3BodyId bodyId, b3BodyType type );

/// Set the body name.
B3_API void b3Body_SetName( b3BodyId bodyId, const char* name );

/// Get the body name. Returns an empty string if the name isn't set.
B3_API const char* b3Body_GetName( b3BodyId bodyId );

/// Set the user data for a body
B3_API void b3Body_SetUserData( b3BodyId bodyId, void* userData );

/// Get the user data stored in a body
B3_API void* b3Body_GetUserData( b3BodyId bodyId );

/// Get the world position of a body. This is the location of the body origin.
B3_API b3Pos b3Body_GetPosition( b3BodyId bodyId );

/// Get the world rotation of a body as a quaternion
B3_API b3Quat b3Body_GetRotation( b3BodyId bodyId );

/// Get the world transform of a body.
B3_API b3WorldTransform b3Body_GetTransform( b3BodyId bodyId );

/// Set the world transform of a body. This acts as a teleport and is fairly expensive.
/// @note Generally you should create a body with the intended transform.
/// @see b3BodyDef::position and b3BodyDef::rotation
B3_API void b3Body_SetTransform( b3BodyId bodyId, b3Pos position, b3Quat rotation );

/// Get a local point on a body given a world point
B3_API b3Vec3 b3Body_GetLocalPoint( b3BodyId bodyId, b3Pos worldPoint );

/// Get a world point on a body given a local point
B3_API b3Pos b3Body_GetWorldPoint( b3BodyId bodyId, b3Vec3 localPoint );

/// Get a local vector on a body given a world vector
B3_API b3Vec3 b3Body_GetLocalVector( b3BodyId bodyId, b3Vec3 worldVector );

/// Get a world vector on a body given a local vector
B3_API b3Vec3 b3Body_GetWorldVector( b3BodyId bodyId, b3Vec3 localVector );

/// Get the linear velocity of a body's center of mass. Usually in meters per second.
B3_API b3Vec3 b3Body_GetLinearVelocity( b3BodyId bodyId );

/// Get the angular velocity of a body in radians per second
B3_API b3Vec3 b3Body_GetAngularVelocity( b3BodyId bodyId );

/// Set the linear velocity of a body. Usually in meters per second.
B3_API void b3Body_SetLinearVelocity( b3BodyId bodyId, b3Vec3 linearVelocity );

/// Set the angular velocity of a body in radians per second
B3_API void b3Body_SetAngularVelocity( b3BodyId bodyId, b3Vec3 angularVelocity );

/// Set the velocity to reach the given transform after a given time step.
/// The result will be close but maybe not exact. This is meant for kinematic bodies.
/// The target is not applied if the velocity would be below the sleep threshold.
/// This will optionally wake the body if asleep, but only if the movement is significant.
B3_API void b3Body_SetTargetTransform( b3BodyId bodyId, b3WorldTransform target, float timeStep, bool wake );

/// Get the linear velocity of a local point attached to a body. Usually in meters per second.
B3_API b3Vec3 b3Body_GetLocalPointVelocity( b3BodyId bodyId, b3Vec3 localPoint );

/// Get the linear velocity of a world point attached to a body. Usually in meters per second.
B3_API b3Vec3 b3Body_GetWorldPointVelocity( b3BodyId bodyId, b3Pos worldPoint );

/// Apply a force at a world point. If the force is not applied at the center of mass,
/// it will generate a torque and affect the angular velocity. This optionally wakes up the body.
/// The force is ignored if the body is not awake.
/// @param bodyId The body id
/// @param force The world force vector, usually in newtons (N)
/// @param point The world position of the point of application
/// @param wake Option to wake up the body
B3_API void b3Body_ApplyForce( b3BodyId bodyId, b3Vec3 force, b3Pos point, bool wake );

/// Apply a force to the center of mass. This optionally wakes up the body.
/// The force is ignored if the body is not awake.
/// @param bodyId The body id
/// @param force the world force vector, usually in newtons (N).
/// @param wake also wake up the body
B3_API void b3Body_ApplyForceToCenter( b3BodyId bodyId, b3Vec3 force, bool wake );

/// Apply a torque. This affects the angular velocity without affecting the linear velocity.
/// This optionally wakes the body. The torque is ignored if the body is not awake.
/// @param bodyId The body id
/// @param torque the world torque vector, usually in N*m.
/// @param wake also wake up the body
B3_API void b3Body_ApplyTorque( b3BodyId bodyId, b3Vec3 torque, bool wake );

/// Apply an impulse at a point. This immediately modifies the velocity.
/// It also modifies the angular velocity if the point of application
/// is not at the center of mass. This optionally wakes the body.
/// The impulse is ignored if the body is not awake.
/// @param bodyId The body id
/// @param impulse the world impulse vector, usually in N*s or kg*m/s.
/// @param point the world position of the point of application.
/// @param wake also wake up the body
/// @warning This should be used for one-shot impulses. If you need a steady force,
/// use a force instead, which will work better with the sub-stepping solver.
B3_API void b3Body_ApplyLinearImpulse( b3BodyId bodyId, b3Vec3 impulse, b3Pos point, bool wake );

/// Apply an impulse to the center of mass. This immediately modifies the velocity.
/// The impulse is ignored if the body is not awake. This optionally wakes the body.
/// @param bodyId The body id
/// @param impulse the world impulse vector, usually in N*s or kg*m/s.
/// @param wake also wake up the body
/// @warning This should be used for one-shot impulses. If you need a steady force,
/// use a force instead, which will work better with the sub-stepping solver.
B3_API void b3Body_ApplyLinearImpulseToCenter( b3BodyId bodyId, b3Vec3 impulse, bool wake );

/// Apply an angular impulse in world space. The impulse is ignored if the body is not awake.
/// This optionally wakes the body.
/// @param bodyId The body id
/// @param impulse the world angular impulse vector, usually in units of kg*m*m/s
/// @param wake also wake up the body
/// @warning This should be used for one-shot impulses. If you need a steady torque,
/// use a torque instead, which will work better with the sub-stepping solver.
B3_API void b3Body_ApplyAngularImpulse( b3BodyId bodyId, b3Vec3 impulse, bool wake );

/// Get the mass of the body, usually in kilograms
B3_API float b3Body_GetMass( b3BodyId bodyId );

/// Get the rotational inertia of the body in local space, usually in kg*m^2
B3_API b3Matrix3 b3Body_GetLocalRotationalInertia( b3BodyId bodyId );

/// Get the inverse mass of the body, usually in 1/kilograms
B3_API float b3Body_GetInverseMass( b3BodyId bodyId );

/// Get the inverse rotational inertia of the body in world space, usually in 1/kg*m^2
B3_API b3Matrix3 b3Body_GetWorldInverseRotationalInertia( b3BodyId bodyId );

/// Get the center of mass position of the body in local space
B3_API b3Vec3 b3Body_GetLocalCenter( b3BodyId bodyId );

/// Get the center of mass position of the body in world space
B3_API b3Pos b3Body_GetWorldCenter( b3BodyId bodyId );

/// Override the body's mass properties. Normally this is computed automatically using the
/// shape geometry and density. This information is lost if a shape is added or removed or if the
/// body type changes.
B3_API void b3Body_SetMassData( b3BodyId bodyId, b3MassData massData );

/// Get the mass data for a body
B3_API b3MassData b3Body_GetMassData( b3BodyId bodyId );

/// This updates the mass properties to the sum of the mass properties of the shapes.
/// This normally does not need to be called unless you called SetMassData to override
/// the mass and you later want to reset the mass.
/// You may also use this when automatic mass computation has been disabled.
/// You should call this regardless of body type.
B3_API void b3Body_ApplyMassFromShapes( b3BodyId bodyId );

/// Adjust the linear damping. Normally this is set in b3BodyDef before creation.
B3_API void b3Body_SetLinearDamping( b3BodyId bodyId, float linearDamping );

/// Get the current linear damping.
B3_API float b3Body_GetLinearDamping( b3BodyId bodyId );

/// Adjust the angular damping. Normally this is set in b3BodyDef before creation.
B3_API void b3Body_SetAngularDamping( b3BodyId bodyId, float angularDamping );

/// Get the current angular damping.
B3_API float b3Body_GetAngularDamping( b3BodyId bodyId );

/// Adjust the gravity scale. Normally this is set in b3BodyDef before creation.
/// @see b3BodyDef::gravityScale
B3_API void b3Body_SetGravityScale( b3BodyId bodyId, float gravityScale );

/// Get the current gravity scale
B3_API float b3Body_GetGravityScale( b3BodyId bodyId );

/// @return true if this body is awake
B3_API bool b3Body_IsAwake( b3BodyId bodyId );

/// Wake a body from sleep. This wakes the entire island the body is touching.
/// @warning Putting a body to sleep will put the entire island of bodies touching this body to sleep,
/// which can be expensive and possibly unintuitive.
B3_API void b3Body_SetAwake( b3BodyId bodyId, bool awake );

/// Enable or disable sleeping for this body. If sleeping is disabled the body will wake.
B3_API void b3Body_EnableSleep( b3BodyId bodyId, bool enableSleep );

/// Returns true if sleeping is enabled for this body
B3_API bool b3Body_IsSleepEnabled( b3BodyId bodyId );

/// Set the sleep threshold, usually in meters per second
B3_API void b3Body_SetSleepThreshold( b3BodyId bodyId, float sleepThreshold );

/// Get the sleep threshold, usually in meters per second.
B3_API float b3Body_GetSleepThreshold( b3BodyId bodyId );

/// Returns true if this body is enabled
B3_API bool b3Body_IsEnabled( b3BodyId bodyId );

/// Disable a body by removing it completely from the simulation. This is expensive.
B3_API void b3Body_Disable( b3BodyId bodyId );

/// Enable a body by adding it to the simulation. This is expensive.
B3_API void b3Body_Enable( b3BodyId bodyId );

/// Set the motion locks on this body.
B3_API void b3Body_SetMotionLocks( b3BodyId bodyId, b3MotionLocks locks );

/// Get the motion locks for this body.
B3_API b3MotionLocks b3Body_GetMotionLocks( b3BodyId bodyId );

/// Set this body to be a bullet. A bullet does continuous collision detection
/// against dynamic bodies (but not other bullets).
B3_API void b3Body_SetBullet( b3BodyId bodyId, bool flag );

/// Is this body a bullet?
B3_API bool b3Body_IsBullet( b3BodyId bodyId );

/// Enable or disable contact recycling for this body. Contact recycling is a performance optimization
/// that reuses contact manifolds when bodies move slightly. Disabling it can avoid ghost collisions
/// on characters at the cost of higher per-step work. Existing contacts retain their prior setting;
/// only contacts created after this call see the new value.
/// @see b3BodyDef::enableContactRecycling
B3_API void b3Body_EnableContactRecycling( b3BodyId bodyId, bool flag );

/// Is contact recycling enabled on this body?
B3_API bool b3Body_IsContactRecyclingEnabled( b3BodyId bodyId );

/// Enable/disable hit events on all shapes
/// @see b3ShapeDef::enableHitEvents
B3_API void b3Body_EnableHitEvents( b3BodyId bodyId, bool flag );

/// Get the world that owns this body
B3_API b3WorldId b3Body_GetWorld( b3BodyId bodyId );

/// Get the number of shapes on this body
B3_API int b3Body_GetShapeCount( b3BodyId bodyId );

/// Get the shape ids for all shapes on this body, up to the provided capacity.
/// @returns the number of shape ids stored in the user array
B3_API int b3Body_GetShapes( b3BodyId bodyId, b3ShapeId* shapeArray, int capacity );

/// Get the number of joints on this body
B3_API int b3Body_GetJointCount( b3BodyId bodyId );

/// Get the joint ids for all joints on this body, up to the provided capacity
/// @returns the number of joint ids stored in the user array
B3_API int b3Body_GetJoints( b3BodyId bodyId, b3JointId* jointArray, int capacity );

/// Get the maximum capacity required for retrieving all the touching contacts on a body
B3_API int b3Body_GetContactCapacity( b3BodyId bodyId );

/// Get the touching contact data for a body
B3_API int b3Body_GetContactData( b3BodyId bodyId, b3ContactData* contactData, int capacity );

/// Get the current world AABB that contains all the attached shapes. Note that this may not encompass the body origin.
/// If there are no shapes attached then the returned AABB is empty and centered on the body origin.
B3_API b3AABB b3Body_ComputeAABB( b3BodyId bodyId );

/// Get the closest point on a body to a world target.
B3_API float b3Body_GetClosestPoint( b3BodyId bodyId, b3Vec3* result, b3Vec3 target );

/// Cast a ray at a specific body using a specified body transform.
B3_API b3BodyCastResult b3Body_CastRay( b3BodyId bodyId, b3Pos origin, b3Vec3 translation, b3QueryFilter filter,
										float maxFraction, b3WorldTransform bodyTransform );

/// Cast a shape at a specific body using a specified body transform.
B3_API b3BodyCastResult b3Body_CastShape( b3BodyId bodyId, b3Pos origin, const b3ShapeProxy* proxy, b3Vec3 translation,
										  b3QueryFilter filter, float maxFraction, bool canEncroach,
										  b3WorldTransform bodyTransform );

/// Overlap a shape with a specific body using a specified body transform.
B3_API bool b3Body_OverlapShape( b3BodyId bodyId, b3Pos origin, const b3ShapeProxy* proxy, b3QueryFilter filter,
								 b3WorldTransform bodyTransform );

/// Collide a character mover with a specific body using a specified body transform.
B3_API int b3Body_CollideMover( b3BodyId bodyId, b3BodyPlaneResult* bodyPlanes, int planeCapacity, b3Pos origin,
								const b3Capsule* mover, b3QueryFilter filter, b3WorldTransform bodyTransform );

/** @} */ // body

/**
 * @defgroup shape Shape
 * Functions to create, destroy, and access.
 * Shapes bind raw geometry to bodies and hold material properties including friction and restitution.
 * @{
 */

/// Create a circle shape and attach it to a body. The shape definition and geometry are fully cloned.
/// Contacts are not created until the next time step.
/// @return the shape id for accessing the shape
B3_API b3ShapeId b3CreateSphereShape( b3BodyId bodyId, const b3ShapeDef* def, const b3Sphere* sphere );

/// Create a capsule shape and attach it to a body. The shape definition and geometry are fully cloned.
/// Contacts are not created until the next time step.
/// @return the shape id for accessing the shape
B3_API b3ShapeId b3CreateCapsuleShape( b3BodyId bodyId, const b3ShapeDef* def, const b3Capsule* capsule );

/// Create a convex hull shape and attach it to a body. The shape definition is fully cloned. Contacts are not created
/// until the next time step.
/// @return the shape id for accessing the shape
B3_API b3ShapeId b3CreateHullShape( b3BodyId bodyId, const b3ShapeDef* def, const b3HullData* hull );

/// Create a convex hull shape and attach it to a body. The hull is cloned then transformed with scale applied first.
/// Use this for non-uniform or mirrored scale or a baked local transform. The baked result is shared through the
/// world hull database. The shape definition and geometry are fully cloned. Contacts are not created until the next time step.
/// @return the shape id for accessing the shape
B3_API b3ShapeId b3CreateTransformedHullShape( b3BodyId bodyId, const b3ShapeDef* def, const b3HullData* hull,
											   b3Transform transform, b3Vec3 scale );

/// Create a mesh hull shape and attach it to a body. The shape definition is fully cloned but the mesh is not.
/// Contacts are not created until the next time step.
/// Mesh collision only creates contacts on static bodies.
/// @warning this holds reference to the input mesh data which must remain valid for the lifetime of this shape
/// @return the shape id for accessing the shape
B3_API b3ShapeId b3CreateMeshShape( b3BodyId bodyId, const b3ShapeDef* def, const b3MeshData* mesh, b3Vec3 scale );

/// Create a height-field shape and attach it to a body. The shape definition is fully cloned but the height field is not.
/// Contacts are not created until the next time step.
/// Height field is only allowed on static bodies.
/// @warning this holds reference to the input height field which must remain valid for the lifetime of this shape
/// @return the shape id for accessing the shape
B3_API b3ShapeId b3CreateHeightFieldShape( b3BodyId bodyId, const b3ShapeDef* def, const b3HeightFieldData* heightField );

/// Compound shapes are only allowed on static bodies.
B3_API b3ShapeId b3CreateCompoundShape( b3BodyId bodyId, b3ShapeDef* def, const b3CompoundData* compound );

/// Destroy a shape. You may defer the body mass update which can improve performance if several shapes on a
///	body are destroyed at once.
///	@see b3Body_ApplyMassFromShapes
B3_API void b3DestroyShape( b3ShapeId shapeId, bool updateBodyMass );

/// Shape identifier validation. Provides validation for up to 64K allocations.
B3_API bool b3Shape_IsValid( b3ShapeId id );

/// Get the type of a shape
B3_API b3ShapeType b3Shape_GetType( b3ShapeId shapeId );

/// Get the id of the body that a shape is attached to
B3_API b3BodyId b3Shape_GetBody( b3ShapeId shapeId );

/// Get the world that owns this shape
B3_API b3WorldId b3Shape_GetWorld( b3ShapeId shapeId );

/// Returns true if the shape is a sensor
B3_API bool b3Shape_IsSensor( b3ShapeId shapeId );

/// Set the shape name.
B3_API void b3Shape_SetName( b3ShapeId shapeId, const char* name );

/// Get the shape name. Returns an empty string if the name isn't set.
B3_API const char* b3Shape_GetName( b3ShapeId shapeId );

/// Set the user data for a shape
B3_API void b3Shape_SetUserData( b3ShapeId shapeId, void* userData );

/// Get the user data for a shape. This is useful when you get a shape id
/// from an event or query.
B3_API void* b3Shape_GetUserData( b3ShapeId shapeId );

/// Set the mass density of a shape, usually in kg/m^3.
/// This will optionally update the mass properties on the parent body.
/// @see b3ShapeDef::density, b3Body_ApplyMassFromShapes
B3_API void b3Shape_SetDensity( b3ShapeId shapeId, float density, bool updateBodyMass );

/// Get the density of a shape, usually in kg/m^3
B3_API float b3Shape_GetDensity( b3ShapeId shapeId );

/// Set the friction on a shape
B3_API void b3Shape_SetFriction( b3ShapeId shapeId, float friction );

/// Get the friction of a shape
B3_API float b3Shape_GetFriction( b3ShapeId shapeId );

/// Set the shape restitution (bounciness)
B3_API void b3Shape_SetRestitution( b3ShapeId shapeId, float restitution );

/// Get the shape restitution
B3_API float b3Shape_GetRestitution( b3ShapeId shapeId );

/// Set the shape base surface material. Does not change per triangle materials.
B3_API void b3Shape_SetSurfaceMaterial( b3ShapeId shapeId, b3SurfaceMaterial surfaceMaterial );

/// Get the base shape surface material.
B3_API b3SurfaceMaterial b3Shape_GetSurfaceMaterial( b3ShapeId shapeId );

/// Get the number of mesh surface materials.
B3_API int b3Shape_GetMeshMaterialCount( b3ShapeId shapeId );

/// Set a surface material for a mesh shape.
B3_API void b3Shape_SetMeshMaterial( b3ShapeId shapeId, b3SurfaceMaterial surfaceMaterial, int index );

/// Get a surface material for a mesh shape
B3_API b3SurfaceMaterial b3Shape_GetMeshSurfaceMaterial( b3ShapeId shapeId, int index );

/// Get the shape filter
B3_API b3Filter b3Shape_GetFilter( b3ShapeId shapeId );

/// Set the current filter. This is almost as expensive as recreating the shape.
/// @see b3ShapeDef::filter
/// @param shapeId the shape
/// @param filter the new filter
/// @param invokeContacts if true then the shape will have all contacts recomputed the next time step (expensive)
B3_API void b3Shape_SetFilter( b3ShapeId shapeId, b3Filter filter, bool invokeContacts );

/// Enable sensor events for this shape. Only applies to kinematic and dynamic bodies. Ignored for sensors.
/// @see b3ShapeDef::isSensor
B3_API void b3Shape_EnableSensorEvents( b3ShapeId shapeId, bool flag );

/// Returns true if sensor events are enabled
B3_API bool b3Shape_AreSensorEventsEnabled( b3ShapeId shapeId );

/// Enable contact events for this shape. Only applies to kinematic and dynamic bodies. Ignored for sensors.
/// @see b3ShapeDef::enableContactEvents
B3_API void b3Shape_EnableContactEvents( b3ShapeId shapeId, bool flag );

/// Returns true if contact events are enabled
B3_API bool b3Shape_AreContactEventsEnabled( b3ShapeId shapeId );

/// Enable pre-solve contact events for this shape. Only applies to dynamic bodies. These are expensive
/// and must be carefully handled due to multithreading. Ignored for sensors.
/// @see b3PreSolveFcn
B3_API void b3Shape_EnablePreSolveEvents( b3ShapeId shapeId, bool flag );

/// Returns true if pre-solve events are enabled
B3_API bool b3Shape_ArePreSolveEventsEnabled( b3ShapeId shapeId );

/// Enable contact hit events for this shape. Ignored for sensors.
/// @see b3WorldDef.hitEventThreshold
B3_API void b3Shape_EnableHitEvents( b3ShapeId shapeId, bool flag );

/// Returns true if hit events are enabled
B3_API bool b3Shape_AreHitEventsEnabled( b3ShapeId shapeId );

/// Ray cast a shape directly. The ray runs from origin to origin + translation and the hit point
/// comes back as a world position, so the cast stays precise far from the world origin.
B3_API b3WorldCastOutput b3Shape_RayCast( b3ShapeId shapeId, b3Pos origin, b3Vec3 translation );

/// Get a copy of the shape's sphere. Asserts the type is correct.
B3_API b3Sphere b3Shape_GetSphere( b3ShapeId shapeId );

/// Get a copy of the shape's capsule. Asserts the type is correct.
B3_API b3Capsule b3Shape_GetCapsule( b3ShapeId shapeId );

/// Get the shape's convex hull. Asserts the type is correct.
B3_API const b3HullData* b3Shape_GetHull( b3ShapeId shapeId );

/// Get the shape's mesh. Asserts the type is correct.
B3_API b3Mesh b3Shape_GetMesh( b3ShapeId shapeId );

/// Get the shape's height field. Asserts the type is correct.
B3_API const b3HeightFieldData* b3Shape_GetHeightField( b3ShapeId shapeId );

/// Allows you to change a shape to be a sphere or update the current sphere.
/// This does not modify the mass properties.
/// @see b3Body_ApplyMassFromShapes
B3_API void b3Shape_SetSphere( b3ShapeId shapeId, const b3Sphere* sphere );

/// Allows you to change a shape to be a capsule or update the current capsule.
/// This does not modify the mass properties.
/// @see b3Body_ApplyMassFromShapes
B3_API void b3Shape_SetCapsule( b3ShapeId shapeId, const b3Capsule* capsule );

/// Allows you to change a shape to be a hull or update the current hull.
/// This does not modify the mass properties.
/// @see b3Body_ApplyMassFromShapes
B3_API void b3Shape_SetHull( b3ShapeId shapeId, const b3HullData* hull );

/// Allows you to change a shape to be a mesh or update the current mesh.
/// This does not modify the mass properties.
/// @see b3Body_ApplyMassFromShapes
B3_API void b3Shape_SetMesh( b3ShapeId shapeId, const b3MeshData* meshData, b3Vec3 scale );

/// Get the maximum capacity required for retrieving all the touching contacts on a shape
B3_API int b3Shape_GetContactCapacity( b3ShapeId shapeId );

/// Get the touching contact data for a shape. The provided shapeId will be either shapeIdA or shapeIdB on the contact data.
/// @note Box3D uses speculative collision so some contact points may be separated.
/// @returns the number of elements filled in the provided array
/// @warning do not ignore the return value, it specifies the valid number of elements
B3_API int b3Shape_GetContactData( b3ShapeId shapeId, b3ContactData* contactData, int capacity );

/// Get the maximum capacity required for retrieving all the overlapped shapes on a sensor shape.
/// This returns 0 if the provided shape is not a sensor.
/// @param shapeId the id of a sensor shape
/// @returns the required capacity to get all the overlaps in b3Shape_GetSensorOverlaps
B3_API int b3Shape_GetSensorCapacity( b3ShapeId shapeId );

/// Get the overlap data for a sensor shape.
/// @param shapeId the id of a sensor shape
/// @param visitorIds a user allocated array that is filled with the overlapping shapes (visitors)
/// @param capacity the capacity of overlappedShapes
/// @returns the number of elements filled in the provided array
/// @warning do not ignore the return value, it specifies the valid number of elements
/// @warning overlaps may contain destroyed shapes so use b3Shape_IsValid to confirm each overlap
B3_API int b3Shape_GetSensorData( b3ShapeId shapeId, b3ShapeId* visitorIds, int capacity );

/// Get the current world AABB
B3_API b3AABB b3Shape_GetAABB( b3ShapeId shapeId );

/// Compute the mass data for a shape
B3_API b3MassData b3Shape_ComputeMassData( b3ShapeId shapeId );

/// Get the closest point on a shape to a target point. Target and result are in world space.
B3_API b3Vec3 b3Shape_GetClosestPoint( b3ShapeId shapeId, b3Vec3 target );

/// Apply a wind force to the body for this shape using the density of air. This considers
/// the projected area of the shape in the wind direction. This also considers
/// the relative velocity of the shape.
/// @param shapeId the shape id
/// @param wind the wind velocity in world space
/// @param drag the drag coefficient, the force that opposes the relative velocity
/// @param lift the lift coefficient, the force that is perpendicular to the relative velocity
/// @param maxSpeed the maximum relative speed. Speed cap is necessary for stability. Typically 10m/s or less.
/// @param wake should this wake the body
B3_API void b3Shape_ApplyWind( b3ShapeId shapeId, b3Vec3 wind, float drag, float lift, float maxSpeed, bool wake );

/** @} */ // shape

/**
 * @defgroup joint Joint
 * @brief Joints allow you to connect rigid bodies together while allowing various forms of relative motions.
 * @{
 */

/// Destroy a joint
B3_API void b3DestroyJoint( b3JointId jointId, bool wakeAttached );

/// Joint identifier validation. Provides validation for up to 64K allocations.
B3_API bool b3Joint_IsValid( b3JointId id );

/// Get the joint type
B3_API b3JointType b3Joint_GetType( b3JointId jointId );

/// Get body A id on a joint
B3_API b3BodyId b3Joint_GetBodyA( b3JointId jointId );

/// Get body B id on a joint
B3_API b3BodyId b3Joint_GetBodyB( b3JointId jointId );

/// Get the world that owns this joint
B3_API b3WorldId b3Joint_GetWorld( b3JointId jointId );

/// Set the local frame on bodyA
B3_API void b3Joint_SetLocalFrameA( b3JointId jointId, b3Transform localFrame );

/// Get the local frame on bodyA
B3_API b3Transform b3Joint_GetLocalFrameA( b3JointId jointId );

/// Set the local frame on bodyB
B3_API void b3Joint_SetLocalFrameB( b3JointId jointId, b3Transform localFrame );

/// Get the local frame on bodyB
B3_API b3Transform b3Joint_GetLocalFrameB( b3JointId jointId );

/// Toggle collision between connected bodies
B3_API void b3Joint_SetCollideConnected( b3JointId jointId, bool shouldCollide );

/// Is collision allowed between connected bodies?
B3_API bool b3Joint_GetCollideConnected( b3JointId jointId );

/// Set the user data on a joint
B3_API void b3Joint_SetUserData( b3JointId jointId, void* userData );

/// Get the user data on a joint
B3_API void* b3Joint_GetUserData( b3JointId jointId );

/// Wake the bodies connect to this joint
B3_API void b3Joint_WakeBodies( b3JointId jointId );

/// Get the current constraint force for this joint
B3_API b3Vec3 b3Joint_GetConstraintForce( b3JointId jointId );

/// Get the current constraint torque for this joint
B3_API b3Vec3 b3Joint_GetConstraintTorque( b3JointId jointId );

/// Get the current linear separation error for this joint. Does not consider admissible movement. Usually in meters.
B3_API float b3Joint_GetLinearSeparation( b3JointId jointId );

/// Get the current angular separation error for this joint. Does not consider admissible movement. Usually in radians.
B3_API float b3Joint_GetAngularSeparation( b3JointId jointId );

/// Set the joint constraint tuning. Advanced feature.
/// @param jointId the joint
/// @param hertz the stiffness in Hertz (cycles per second)
/// @param dampingRatio the non-dimensional damping ratio (one for critical damping)
B3_API void b3Joint_SetConstraintTuning( b3JointId jointId, float hertz, float dampingRatio );

/// Get the joint constraint tuning. Advanced feature.
B3_API void b3Joint_GetConstraintTuning( b3JointId jointId, float* hertz, float* dampingRatio );

/// Set the force threshold for joint events (Newtons)
B3_API void b3Joint_SetForceThreshold( b3JointId jointId, float threshold );

/// Get the force threshold for joint events (Newtons)
B3_API float b3Joint_GetForceThreshold( b3JointId jointId );

/// Set the torque threshold for joint events (N-m)
B3_API void b3Joint_SetTorqueThreshold( b3JointId jointId, float threshold );

/// Get the torque threshold for joint events (N-m)
B3_API float b3Joint_GetTorqueThreshold( b3JointId jointId );

/**
 * @defgroup parallel_joint Parallel Joint
 * @brief Functions for the parallel joint.
 * @{
 */

/// Create a parallel joint
/// @see b3ParallelJointDef for details
B3_API b3JointId b3CreateParallelJoint( b3WorldId worldId, const b3ParallelJointDef* def );

/// Set the spring stiffness in Hertz
B3_API void b3ParallelJoint_SetSpringHertz( b3JointId jointId, float hertz );

/// Set the spring damping ratio, non-dimensional
B3_API void b3ParallelJoint_SetSpringDampingRatio( b3JointId jointId, float dampingRatio );

/// Get the spring Hertz
B3_API float b3ParallelJoint_GetSpringHertz( b3JointId jointId );

/// Get the spring damping ratio
B3_API float b3ParallelJoint_GetSpringDampingRatio( b3JointId jointId );

/// Set the maximum spring torque, usually in newton-meters
B3_API void b3ParallelJoint_SetMaxTorque( b3JointId jointId, float force );

/// Get the maximum spring torque, usually in newton-meters
B3_API float b3ParallelJoint_GetMaxTorque( b3JointId jointId );

/** @} */ // parallel_joint

/**
 * @defgroup distance_joint Distance Joint
 * @brief Functions for the distance joint.
 * @{
 */

/// Create a distance joint
/// @see b3DistanceJointDef for details
B3_API b3JointId b3CreateDistanceJoint( b3WorldId worldId, const b3DistanceJointDef* def );

/// Set the rest length of a distance joint
/// @param jointId The id for a distance joint
/// @param length The new distance joint length
B3_API void b3DistanceJoint_SetLength( b3JointId jointId, float length );

/// Get the rest length of a distance joint
B3_API float b3DistanceJoint_GetLength( b3JointId jointId );

/// Enable/disable the distance joint spring. When disabled the distance joint is rigid.
B3_API void b3DistanceJoint_EnableSpring( b3JointId jointId, bool enableSpring );

/// Is the distance joint spring enabled?
B3_API bool b3DistanceJoint_IsSpringEnabled( b3JointId jointId );

/// Set the force range for the spring.
B3_API void b3DistanceJoint_SetSpringForceRange( b3JointId jointId, float lowerForce, float upperForce );

/// Get the force range for the spring.
B3_API void b3DistanceJoint_GetSpringForceRange( b3JointId jointId, float* lowerForce, float* upperForce );

/// Set the spring stiffness in Hertz
B3_API void b3DistanceJoint_SetSpringHertz( b3JointId jointId, float hertz );

/// Set the spring damping ratio, non-dimensional
B3_API void b3DistanceJoint_SetSpringDampingRatio( b3JointId jointId, float dampingRatio );

/// Get the spring Hertz
B3_API float b3DistanceJoint_GetSpringHertz( b3JointId jointId );

/// Get the spring damping ratio
B3_API float b3DistanceJoint_GetSpringDampingRatio( b3JointId jointId );

/// Enable joint limit. The limit only works if the joint spring is enabled. Otherwise the joint is rigid
/// and the limit has no effect.
B3_API void b3DistanceJoint_EnableLimit( b3JointId jointId, bool enableLimit );

/// Is the distance joint limit enabled?
B3_API bool b3DistanceJoint_IsLimitEnabled( b3JointId jointId );

/// Set the minimum and maximum length parameters of a distance joint
B3_API void b3DistanceJoint_SetLengthRange( b3JointId jointId, float minLength, float maxLength );

/// Get the distance joint minimum length
B3_API float b3DistanceJoint_GetMinLength( b3JointId jointId );

/// Get the distance joint maximum length
B3_API float b3DistanceJoint_GetMaxLength( b3JointId jointId );

/// Get the current length of a distance joint
B3_API float b3DistanceJoint_GetCurrentLength( b3JointId jointId );

/// Enable/disable the distance joint motor
B3_API void b3DistanceJoint_EnableMotor( b3JointId jointId, bool enableMotor );

/// Is the distance joint motor enabled?
B3_API bool b3DistanceJoint_IsMotorEnabled( b3JointId jointId );

/// Set the distance joint motor speed, usually in meters per second
B3_API void b3DistanceJoint_SetMotorSpeed( b3JointId jointId, float motorSpeed );

/// Get the distance joint motor speed, usually in meters per second
B3_API float b3DistanceJoint_GetMotorSpeed( b3JointId jointId );

/// Set the distance joint maximum motor force, usually in newtons
B3_API void b3DistanceJoint_SetMaxMotorForce( b3JointId jointId, float force );

/// Get the distance joint maximum motor force, usually in newtons
B3_API float b3DistanceJoint_GetMaxMotorForce( b3JointId jointId );

/// Get the distance joint current motor force, usually in newtons
B3_API float b3DistanceJoint_GetMotorForce( b3JointId jointId );

/** @} */ // distance_joint

/**
 * @defgroup motor_joint Motor Joint
 * @brief Functions for the motor joint.
 *
 * The motor joint is designed to control the movement of a body while still being
 * responsive to collisions. A spring controls the position and rotation. A velocity motor
 * can be used to control velocity and allows for friction in top-down games. Both types
 * of control can be combined. For example, you can have a spring with friction.
 * Position and velocity control have force and torque limits.
 * @{
 */

/// Create a motor joint
/// @see b3MotorJointDef for details
B3_API b3JointId b3CreateMotorJoint( b3WorldId worldId, const b3MotorJointDef* def );

/// Set the desired relative linear velocity in meters per second
B3_API void b3MotorJoint_SetLinearVelocity( b3JointId jointId, b3Vec3 velocity );

/// Get the desired relative linear velocity in meters per second
B3_API b3Vec3 b3MotorJoint_GetLinearVelocity( b3JointId jointId );

/// Set the desired relative angular velocity in radians per second
B3_API void b3MotorJoint_SetAngularVelocity( b3JointId jointId, b3Vec3 velocity );

/// Get the desired relative angular velocity in radians per second
B3_API b3Vec3 b3MotorJoint_GetAngularVelocity( b3JointId jointId );

/// Set the motor joint maximum force, usually in newtons
B3_API void b3MotorJoint_SetMaxVelocityForce( b3JointId jointId, float maxForce );

/// Get the motor joint maximum force, usually in newtons
B3_API float b3MotorJoint_GetMaxVelocityForce( b3JointId jointId );

/// Set the motor joint maximum torque, usually in newton-meters
B3_API void b3MotorJoint_SetMaxVelocityTorque( b3JointId jointId, float maxTorque );

/// Get the motor joint maximum torque, usually in newton-meters
B3_API float b3MotorJoint_GetMaxVelocityTorque( b3JointId jointId );

/// Set the spring linear hertz stiffness
B3_API void b3MotorJoint_SetLinearHertz( b3JointId jointId, float hertz );

/// Get the spring linear hertz stiffness
B3_API float b3MotorJoint_GetLinearHertz( b3JointId jointId );

/// Set the spring linear damping ratio. Use 1.0 for critical damping.
B3_API void b3MotorJoint_SetLinearDampingRatio( b3JointId jointId, float damping );

/// Get the spring linear damping ratio.
B3_API float b3MotorJoint_GetLinearDampingRatio( b3JointId jointId );

/// Set the spring angular hertz stiffness
B3_API void b3MotorJoint_SetAngularHertz( b3JointId jointId, float hertz );

/// Get the spring angular hertz stiffness
B3_API float b3MotorJoint_GetAngularHertz( b3JointId jointId );

/// Set the spring angular damping ratio. Use 1.0 for critical damping.
B3_API void b3MotorJoint_SetAngularDampingRatio( b3JointId jointId, float damping );

/// Get the spring angular damping ratio.
B3_API float b3MotorJoint_GetAngularDampingRatio( b3JointId jointId );

/// Set the maximum spring force in newtons.
B3_API void b3MotorJoint_SetMaxSpringForce( b3JointId jointId, float maxForce );

/// Get the maximum spring force in newtons.
B3_API float b3MotorJoint_GetMaxSpringForce( b3JointId jointId );

/// Set the maximum spring torque in newtons * meters
B3_API void b3MotorJoint_SetMaxSpringTorque( b3JointId jointId, float maxTorque );

/// Get the maximum spring torque in newtons * meters
B3_API float b3MotorJoint_GetMaxSpringTorque( b3JointId jointId );

/**@}*/ // motor_joint

/**
 * @defgroup filter_joint Filter Joint
 * @brief Functions for the filter joint.
 *
 * The filter joint is used to disable collision between two bodies. As a side effect of being a joint, it also
 * keeps the two bodies in the same simulation island.
 * @{
 */

/// Create a filter joint.
/// @see b3FilterJointDef for details
B3_API b3JointId b3CreateFilterJoint( b3WorldId worldId, const b3FilterJointDef* def );

/**@}*/ // filter_joint

/**
 * @defgroup prismatic_joint Prismatic Joint
 * @brief A prismatic joint allows for translation along a single axis with no rotation.
 *
 * The prismatic joint is useful for things like pistons and moving platforms, where you want a body to translate
 * along an axis and have no rotation. Also called a *slider* joint.
 * @{
 */

/// Create a prismatic (slider) joint.
/// @see b3PrismaticJointDef for details
B3_API b3JointId b3CreatePrismaticJoint( b3WorldId worldId, const b3PrismaticJointDef* def );

/// Enable/disable the joint spring.
B3_API void b3PrismaticJoint_EnableSpring( b3JointId jointId, bool enableSpring );

/// Is the prismatic joint spring enabled or not?
B3_API bool b3PrismaticJoint_IsSpringEnabled( b3JointId jointId );

/// Set the prismatic joint stiffness in Hertz.
/// This should usually be less than a quarter of the simulation rate. For example, if the simulation
/// runs at 60Hz then the joint stiffness should be 15Hz or less.
B3_API void b3PrismaticJoint_SetSpringHertz( b3JointId jointId, float hertz );

/// Get the prismatic joint stiffness in Hertz
B3_API float b3PrismaticJoint_GetSpringHertz( b3JointId jointId );

/// Set the prismatic joint damping ratio (non-dimensional)
B3_API void b3PrismaticJoint_SetSpringDampingRatio( b3JointId jointId, float dampingRatio );

/// Get the prismatic spring damping ratio (non-dimensional)
B3_API float b3PrismaticJoint_GetSpringDampingRatio( b3JointId jointId );

/// Set the prismatic joint target translation. Usually in meters.
B3_API void b3PrismaticJoint_SetTargetTranslation( b3JointId jointId, float targetTranslation );

/// Get the prismatic joint target translation. Usually in meters.
B3_API float b3PrismaticJoint_GetTargetTranslation( b3JointId jointId );

/// Enable/disable a prismatic joint limit
B3_API void b3PrismaticJoint_EnableLimit( b3JointId jointId, bool enableLimit );

/// Is the prismatic joint limit enabled?
B3_API bool b3PrismaticJoint_IsLimitEnabled( b3JointId jointId );

/// Get the prismatic joint lower limit
B3_API float b3PrismaticJoint_GetLowerLimit( b3JointId jointId );

/// Get the prismatic joint upper limit
B3_API float b3PrismaticJoint_GetUpperLimit( b3JointId jointId );

/// Set the prismatic joint limits
B3_API void b3PrismaticJoint_SetLimits( b3JointId jointId, float lower, float upper );

/// Enable/disable a prismatic joint motor
B3_API void b3PrismaticJoint_EnableMotor( b3JointId jointId, bool enableMotor );

/// Is the prismatic joint motor enabled?
B3_API bool b3PrismaticJoint_IsMotorEnabled( b3JointId jointId );

/// Set the prismatic joint motor speed, usually in meters per second
B3_API void b3PrismaticJoint_SetMotorSpeed( b3JointId jointId, float motorSpeed );

/// Get the prismatic joint motor speed, usually in meters per second
B3_API float b3PrismaticJoint_GetMotorSpeed( b3JointId jointId );

/// Set the prismatic joint maximum motor force, usually in newtons
B3_API void b3PrismaticJoint_SetMaxMotorForce( b3JointId jointId, float force );

/// Get the prismatic joint maximum motor force, usually in newtons
B3_API float b3PrismaticJoint_GetMaxMotorForce( b3JointId jointId );

/// Get the prismatic joint current motor force, usually in newtons
B3_API float b3PrismaticJoint_GetMotorForce( b3JointId jointId );

/// Get the current joint translation, usually in meters.
B3_API float b3PrismaticJoint_GetTranslation( b3JointId jointId );

/// Get the current joint translation speed, usually in meters per second.
B3_API float b3PrismaticJoint_GetSpeed( b3JointId jointId );

/**@}*/ // prismatic_joint

/**
 * @defgroup revolute_joint Revolute Joint
 * @brief A revolute joint allows for relative rotation about a single axis with no relative translation.
 *
 * Also called a *hinge* or *pin* joint.
 * @{
 */

/// Create a revolute joint
/// @see b3RevoluteJointDef for details
B3_API b3JointId b3CreateRevoluteJoint( b3WorldId worldId, const b3RevoluteJointDef* def );

/// Enable/disable the revolute joint spring
B3_API void b3RevoluteJoint_EnableSpring( b3JointId jointId, bool enableSpring );

/// Is the revolute angular spring enabled?
B3_API bool b3RevoluteJoint_IsSpringEnabled( b3JointId jointId );

/// Set the revolute joint spring stiffness in Hertz
B3_API void b3RevoluteJoint_SetSpringHertz( b3JointId jointId, float hertz );

/// Get the revolute joint spring stiffness in Hertz
B3_API float b3RevoluteJoint_GetSpringHertz( b3JointId jointId );

/// Set the revolute joint spring damping ratio, non-dimensional
B3_API void b3RevoluteJoint_SetSpringDampingRatio( b3JointId jointId, float dampingRatio );

/// Get the revolute joint spring damping ratio, non-dimensional
B3_API float b3RevoluteJoint_GetSpringDampingRatio( b3JointId jointId );

/// Set the revolute joint target angle in radians
B3_API void b3RevoluteJoint_SetTargetAngle( b3JointId jointId, float targetRadians );

/// Get the revolute joint target angle in radians
B3_API float b3RevoluteJoint_GetTargetAngle( b3JointId jointId );

/// Get the revolute joint current angle in radians relative to the reference angle
/// @see b3RevoluteJointDef::referenceAngle
B3_API float b3RevoluteJoint_GetAngle( b3JointId jointId );

/// Enable/disable the revolute joint limit
B3_API void b3RevoluteJoint_EnableLimit( b3JointId jointId, bool enableLimit );

/// Is the revolute joint limit enabled?
B3_API bool b3RevoluteJoint_IsLimitEnabled( b3JointId jointId );

/// Get the revolute joint lower limit in radians
B3_API float b3RevoluteJoint_GetLowerLimit( b3JointId jointId );

/// Get the revolute joint upper limit in radians
B3_API float b3RevoluteJoint_GetUpperLimit( b3JointId jointId );

/// Set the revolute joint limits in radians
B3_API void b3RevoluteJoint_SetLimits( b3JointId jointId, float lowerLimitRadians, float upperLimitRadians );

/// Enable/disable a revolute joint motor
B3_API void b3RevoluteJoint_EnableMotor( b3JointId jointId, bool enableMotor );

/// Is the revolute joint motor enabled?
B3_API bool b3RevoluteJoint_IsMotorEnabled( b3JointId jointId );

/// Set the revolute joint motor speed in radians per second
B3_API void b3RevoluteJoint_SetMotorSpeed( b3JointId jointId, float motorSpeed );

/// Get the revolute joint motor speed in radians per second
B3_API float b3RevoluteJoint_GetMotorSpeed( b3JointId jointId );

/// Get the revolute joint current motor torque, usually in newton-meters
B3_API float b3RevoluteJoint_GetMotorTorque( b3JointId jointId );

/// Set the revolute joint maximum motor torque, usually in newton-meters
B3_API void b3RevoluteJoint_SetMaxMotorTorque( b3JointId jointId, float torque );

/// Get the revolute joint maximum motor torque, usually in newton-meters
B3_API float b3RevoluteJoint_GetMaxMotorTorque( b3JointId jointId );

/**@}*/ // revolute_joint

/**
 * @defgroup spherical_joint Spherical Joint
 * @brief A spherical joint allows for relative rotation in the 3D space with no relative translation.
 *
 * Also called a *ball-in-socket* or *point-to-point* joint.
 * @{
 */

/// Create a spherical joint
/// @see b3SphericalJointDef for details
B3_API b3JointId b3CreateSphericalJoint( b3WorldId worldId, const b3SphericalJointDef* def );

/// Enable/disable the spherical joint cone limit
B3_API void b3SphericalJoint_EnableConeLimit( b3JointId jointId, bool enableLimit );

/// Is the spherical joint cone limit enabled?
B3_API bool b3SphericalJoint_IsConeLimitEnabled( b3JointId jointId );

/// Get the spherical joint cone limit in radians
B3_API float b3SphericalJoint_GetConeLimit( b3JointId jointId );

/// Set the spherical joint limits in radians
B3_API void b3SphericalJoint_SetConeLimit( b3JointId jointId, float angleRadians );

/// Get the spherical joint current cone angle in radians.
B3_API float b3SphericalJoint_GetConeAngle( b3JointId jointId );

/// Enable/disable the spherical joint limit
B3_API void b3SphericalJoint_EnableTwistLimit( b3JointId jointId, bool enableLimit );

/// Is the spherical joint limit enabled?
B3_API bool b3SphericalJoint_IsTwistLimitEnabled( b3JointId jointId );

/// Get the spherical joint lower limit in radians
B3_API float b3SphericalJoint_GetLowerTwistLimit( b3JointId jointId );

/// Get the spherical joint upper limit in radians
B3_API float b3SphericalJoint_GetUpperTwistLimit( b3JointId jointId );

/// Set the spherical joint limits in radians
B3_API void b3SphericalJoint_SetTwistLimits( b3JointId jointId, float lowerLimitRadians, float upperLimitRadians );

/// Get the spherical joint current twist angle in radians.
B3_API float b3SphericalJoint_GetTwistAngle( b3JointId jointId );

/// Enable/disable the spherical joint spring
B3_API void b3SphericalJoint_EnableSpring( b3JointId jointId, bool enableSpring );

/// Is the spherical angular spring enabled?
B3_API bool b3SphericalJoint_IsSpringEnabled( b3JointId jointId );

/// Set the spherical joint spring stiffness in Hertz
B3_API void b3SphericalJoint_SetSpringHertz( b3JointId jointId, float hertz );

/// Get the spherical joint spring stiffness in Hertz
B3_API float b3SphericalJoint_GetSpringHertz( b3JointId jointId );

/// Set the spherical joint spring damping ratio, non-dimensional
B3_API void b3SphericalJoint_SetSpringDampingRatio( b3JointId jointId, float dampingRatio );

/// Get the spherical joint spring damping ratio, non-dimensional
B3_API float b3SphericalJoint_GetSpringDampingRatio( b3JointId jointId );

/// Set the spherical joint spring target rotation
B3_API void b3SphericalJoint_SetTargetRotation( b3JointId jointId, b3Quat targetRotation );

/// Get the spherical joint spring target rotation
B3_API b3Quat b3SphericalJoint_GetTargetRotation( b3JointId jointId );

/// Enable/disable a spherical joint motor
B3_API void b3SphericalJoint_EnableMotor( b3JointId jointId, bool enableMotor );

/// Is the spherical joint motor enabled?
B3_API bool b3SphericalJoint_IsMotorEnabled( b3JointId jointId );

/// Set the spherical joint motor velocity in radians per second
B3_API void b3SphericalJoint_SetMotorVelocity( b3JointId jointId, b3Vec3 motorVelocity );

/// Get the spherical joint motor velocity in radians per second
B3_API b3Vec3 b3SphericalJoint_GetMotorVelocity( b3JointId jointId );

/// Get the spherical joint current motor torque, usually in newton-meters
B3_API b3Vec3 b3SphericalJoint_GetMotorTorque( b3JointId jointId );

/// Set the spherical joint maximum motor torque, usually in newton-meters
B3_API void b3SphericalJoint_SetMaxMotorTorque( b3JointId jointId, float torque );

/// Get the spherical joint maximum motor torque, usually in newton-meters
B3_API float b3SphericalJoint_GetMaxMotorTorque( b3JointId jointId );

/**@}*/ // spherical_joint

/**
 * @defgroup weld_joint Weld Joint
 * @brief A weld joint fully constrains the relative transform between two bodies while allowing for springiness
 *
 * A weld joint constrains the relative rotation and translation between two bodies. Both rotation and translation
 * can have damped springs.
 *
 * @note The accuracy of weld joint is limited by the accuracy of the solver. Long chains of weld joints may flex.
 * @{
 */

/// Create a weld joint
/// @see b3WeldJointDef for details
B3_API b3JointId b3CreateWeldJoint( b3WorldId worldId, const b3WeldJointDef* def );

/// Set the weld joint linear stiffness in Hertz. 0 is rigid.
B3_API void b3WeldJoint_SetLinearHertz( b3JointId jointId, float hertz );

/// Get the weld joint linear stiffness in Hertz
B3_API float b3WeldJoint_GetLinearHertz( b3JointId jointId );

/// Set the weld joint linear damping ratio (non-dimensional)
B3_API void b3WeldJoint_SetLinearDampingRatio( b3JointId jointId, float dampingRatio );

/// Get the weld joint linear damping ratio (non-dimensional)
B3_API float b3WeldJoint_GetLinearDampingRatio( b3JointId jointId );

/// Set the weld joint angular stiffness in Hertz. 0 is rigid.
B3_API void b3WeldJoint_SetAngularHertz( b3JointId jointId, float hertz );

/// Get the weld joint angular stiffness in Hertz
B3_API float b3WeldJoint_GetAngularHertz( b3JointId jointId );

/// Set weld joint angular damping ratio, non-dimensional
B3_API void b3WeldJoint_SetAngularDampingRatio( b3JointId jointId, float dampingRatio );

/// Get the weld joint angular damping ratio, non-dimensional
B3_API float b3WeldJoint_GetAngularDampingRatio( b3JointId jointId );

/**@}*/ // weld_joint

/**
 * @defgroup wheel_joint Wheel Joint
 * The wheel joint can be used to simulate wheels on vehicles.
 *
 * The wheel joint restricts body B to move along a local axis in body A. Body B is free to
 * rotate. Supports a linear spring, linear limits, and a rotational motor.
 *
 * @{
 */

/// Create a wheel joint.
/// @see b3WheelJointDef for details.
B3_API b3JointId b3CreateWheelJoint( b3WorldId worldId, const b3WheelJointDef* def );

/// Enable/disable the wheel joint spring.
B3_API void b3WheelJoint_EnableSuspension( b3JointId jointId, bool flag );

/// Is the wheel joint spring enabled?
B3_API bool b3WheelJoint_IsSuspensionEnabled( b3JointId jointId );

/// Set the wheel joint stiffness in Hertz.
B3_API void b3WheelJoint_SetSuspensionHertz( b3JointId jointId, float hertz );

/// Get the wheel joint stiffness in Hertz.
B3_API float b3WheelJoint_GetSuspensionHertz( b3JointId jointId );

/// Set the wheel joint damping ratio, non-dimensional.
B3_API void b3WheelJoint_SetSuspensionDampingRatio( b3JointId jointId, float dampingRatio );

/// Get the wheel joint damping ratio, non-dimensional.
B3_API float b3WheelJoint_GetSuspensionDampingRatio( b3JointId jointId );

/// Enable/disable the wheel joint limit.
B3_API void b3WheelJoint_EnableSuspensionLimit( b3JointId jointId, bool flag );

/// Is the wheel joint limit enabled?
B3_API bool b3WheelJoint_IsSuspensionLimitEnabled( b3JointId jointId );

/// Get the wheel joint lower limit.
B3_API float b3WheelJoint_GetLowerSuspensionLimit( b3JointId jointId );

/// Get the wheel joint upper limit.
B3_API float b3WheelJoint_GetUpperSuspensionLimit( b3JointId jointId );

/// Set the wheel joint limits.
B3_API void b3WheelJoint_SetSuspensionLimits( b3JointId jointId, float lower, float upper );

/// Enable/disable the wheel joint motor.
B3_API void b3WheelJoint_EnableSpinMotor( b3JointId jointId, bool flag );

/// Is the wheel joint motor enabled?
B3_API bool b3WheelJoint_IsSpinMotorEnabled( b3JointId jointId );

/// Set the wheel joint motor speed in radians per second.
B3_API void b3WheelJoint_SetSpinMotorSpeed( b3JointId jointId, float speed );

/// Get the wheel joint motor speed in radians per second.
B3_API float b3WheelJoint_GetSpinMotorSpeed( b3JointId jointId );

/// Set the wheel joint maximum motor torque, usually in newton-meters.
B3_API void b3WheelJoint_SetMaxSpinTorque( b3JointId jointId, float torque );

/// Get the wheel joint maximum motor torque, usually in newton-meters.
B3_API float b3WheelJoint_GetMaxSpinTorque( b3JointId jointId );

/// Get the current spin speed in radians per second.
B3_API float b3WheelJoint_GetSpinSpeed( b3JointId jointId );

/// Get the wheel joint current motor torque, usually in newton-meters.
B3_API float b3WheelJoint_GetSpinTorque( b3JointId jointId );

/// Enable/disable wheel steering. Steering allows the wheel to rotate about the suspension axis.
B3_API void b3WheelJoint_EnableSteering( b3JointId jointId, bool flag );

/// Can the wheel steer?
B3_API bool b3WheelJoint_IsSteeringEnabled( b3JointId jointId );

/// Set the wheel joint steering stiffness in Hertz.
B3_API void b3WheelJoint_SetSteeringHertz( b3JointId jointId, float hertz );

/// Get the wheel joint steering stiffness in Hertz.
B3_API float b3WheelJoint_GetSteeringHertz( b3JointId jointId );

/// Set the wheel joint steering damping ratio, non-dimensional.
B3_API void b3WheelJoint_SetSteeringDampingRatio( b3JointId jointId, float dampingRatio );

/// Get the wheel joint steering damping ratio, non-dimensional.
B3_API float b3WheelJoint_GetSteeringDampingRatio( b3JointId jointId );

/// Set the wheel joint maximum steering torque in N*m.
B3_API void b3WheelJoint_SetMaxSteeringTorque( b3JointId jointId, float torque );

/// Get the wheel joint maximum steering torque in N*m.
B3_API float b3WheelJoint_GetMaxSteeringTorque( b3JointId jointId );

/// Enable/disable the wheel joint steering limit.
B3_API void b3WheelJoint_EnableSteeringLimit( b3JointId jointId, bool flag );

/// Is the wheel joint steering limit enabled?
B3_API bool b3WheelJoint_IsSteeringLimitEnabled( b3JointId jointId );

/// Get the wheel joint lower steering limit in radians.
B3_API float b3WheelJoint_GetLowerSteeringLimit( b3JointId jointId );

/// Get the wheel joint upper steering limit in radians.
B3_API float b3WheelJoint_GetUpperSteeringLimit( b3JointId jointId );

/// Set the wheel joint steering limits in radians.
B3_API void b3WheelJoint_SetSteeringLimits( b3JointId jointId, float lowerRadians, float upperRadians );

/// Set the wheel joint target steering angle in radians.
B3_API void b3WheelJoint_SetTargetSteeringAngle( b3JointId jointId, float radians );

/// Get the wheel joint target steering angle in radians.
B3_API float b3WheelJoint_GetTargetSteeringAngle( b3JointId jointId );

/// Get the current steering angle in radians.
B3_API float b3WheelJoint_GetSteeringAngle( b3JointId jointId );

/// Get the current steering torque in N*m.
B3_API float b3WheelJoint_GetSteeringTorque( b3JointId jointId );

/**@}*/ // wheel_joint

/**@}*/ // joint

/**
 * @defgroup contact Contact
 * Access to contacts
 * @{
 */

/// Contact identifier validation. Provides validation for up to 2^32 allocations.
B3_API bool b3Contact_IsValid( b3ContactId id );

/// Get the manifolds for a contact. The manifold may have no points if the contact is not touching.
B3_API b3ContactData b3Contact_GetData( b3ContactId contactId );

/**@}*/ // contact
