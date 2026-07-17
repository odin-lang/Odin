// SPDX-FileCopyrightText: 2025 Erin Catto
// SPDX-License-Identifier: MIT

#pragma once

#include "box3d/constants.h"
#include "box3d/math_functions.h"
#include "box3d/types.h"

typedef struct b3World b3World;

enum b3BodyFlags
{
	// This body has fixed translation along the x-axis
	b3_lockLinearX = 0x00000001,

	// This body has fixed translation along the y-axis
	b3_lockLinearY = 0x00000002,

	// This body has fixed translation along the z-axis
	b3_lockLinearZ = 0x00000004,

	// This body has fixed rotation around the x-axis
	b3_lockAngularX = 0x00000008,

	// This body has fixed rotation around the y-axis
	b3_lockAngularY = 0x00000010,

	// This body has fixed rotation around the z-axis
	b3_lockAngularZ = 0x00000020,

	// This flag is used for debug draw
	b3_isFast = 0x00000040,

	// This dynamic body does a final CCD pass against all body types, but not other bullets
	b3_isBullet = 0x00000080,

	// This body was speed capped in the current time step
	b3_isSpeedCapped = 0x00000100,

	// This body had a time of impact event in the current time step
	b3_hadTimeOfImpact = 0x00000200,

	// This body has no limit on angular velocity
	b3_allowFastRotation = 0x00000400,

	// This body need's to have its AABB increased
	b3_enlargeBounds = 0x00000800,

	// This body is dynamic so the solver should write to it.
	// This prevents writing to kinematic bodies that causes a multithreaded sharing
	// cache coherence problem even when the values are not changing.
	// Used for b3BodyState flags.
	b3_dynamicFlag = 0x00001000,

	b3_enableSleep = 0x00002000,

	b3_bodyEnableContactRecycling = 0x00004000,

	// The user deferred mass computation via the updateBodyMass shape option and mass
	// data still hasn't been set.
	b3_dirtyMass = 0x00008000,

	// All lock flags
	b3_allLocks = b3_lockLinearX | b3_lockLinearY | b3_lockLinearZ | b3_lockAngularX | b3_lockAngularY | b3_lockAngularZ,

	// If all these flags are set then the body has fixed rotation
	b3_fixedRotation = b3_lockAngularX | b3_lockAngularY | b3_lockAngularZ,

	// These flags are transient per time step. These may be different across b3Body, b3BodySim, and b3BodyState.
	b3_bodyTransientFlags = b3_isFast | b3_isSpeedCapped | b3_hadTimeOfImpact,
};

// Body organizational details that are not used in the solver.
typedef struct b3Body
{
	void* userData;

	// index of solver set stored in b3World
	// may be B3_NULL_INDEX
	int setIndex;

	// body sim and state index within set
	// may be B3_NULL_INDEX
	int localIndex;

	// [31 : contactId | 1 : edgeIndex]
	int headContactKey;
	int contactCount;

	// todo maybe move this to the body sim
	int headShapeId;
	int shapeCount;

	int headChainId;

	// [31 : jointId | 1 : edgeIndex]
	int headJointKey;
	int jointCount;

	// All enabled dynamic and kinematic bodies are in an island.
	int islandId;

	// Index into the island's bodies array for O(1) swap-removal.
	// B3_NULL_INDEX when not in an island.
	int islandIndex;

	float sleepThreshold;
	float sleepTime;
	float sleepVelocity;
	float mass;

	// local space inertia
	b3Matrix3 inertia;

	// this is used to adjust the fellAsleep flag in the body move array
	int bodyMoveIndex;

	int id;

	// b3BodyFlags
	uint32_t flags;
	uint32_t nameId;

	b3BodyType type;

	// This is monotonically advanced when a body is allocated in this slot
	// Used to check for invalid b3BodyId
	uint16_t generation;
} b3Body;

// Body State
// The body state is designed for fast conversion to and from SIMD via scatter-gather.
// Only awake dynamic and kinematic bodies have a body state.
// This is used in the performance critical constraint solver
//
// The solver operates on the body state. The body state array does not hold static bodies. Static bodies are shared
// across worker threads. It would be okay to read their states, but writing to them would cause cache thrashing across
// workers, even if the values don't change.
// This causes some trouble when computing anchors. I rotate joint anchors using the body rotation every sub-step. For static
// bodies the anchor doesn't rotate. Body A or B could be static and this can lead to lots of branching. This branching
// should be minimized.
//
// Solution 1:
// Use delta rotations. This means anchors need to be prepared in world space. The delta rotation for static bodies will be
// identity using a dummy state. Base separation and angles need to be computed. Manifolds will be behind a frame, but that
// is probably best if bodies move fast.
//
// Solution 2:
// Use full rotation. The anchors for static bodies will be in world space while the anchors for dynamic bodies will be in local
// space. Potentially confusing and bug prone.
//
// Note:
// I rotate joint anchors each sub-step but not contact anchors. Joint stability improves a lot by rotating joint anchors
// according to substep progress. Contacts have reduced stability when anchors are rotated during substeps, especially for
// round shapes.
//
// 56 bytes
// todo_erin measure perf padding to 64 bytes
typedef struct b3BodyState
{
	b3Vec3 linearVelocity;	// 12
	b3Vec3 angularVelocity; // 12

	// Using delta position reduces round-off error far from the origin
	b3Vec3 deltaPosition; // 12

	// Using delta rotation because I cannot access the full rotation on static bodies in
	// the solver and must use zero delta rotation for static bodies (c,s) = (1,0)
	b3Quat deltaRotation; // 16

	// b3BodyFlags
	// Important flags: locking, dynamic
	uint32_t flags; // 4
} b3BodyState;

// Identity body state, notice the deltaRotation is identity
static const b3BodyState b3_identityBodyState = {
	{ 0.0f, 0.0f, 0.0f }, { 0.0f, 0.0f, 0.0f }, { 0.0f, 0.0f, 0.0f }, { { 0.0f, 0.0f, 0.0f }, 1.0f }, 0,
};

// Body simulation data used for integration of position and velocity
// Transform data used for collision and solver preparation.
typedef struct b3BodySim
{
	// transform for body origin, double translation in large world mode
	b3WorldTransform transform;

	// center of mass position in world space
	b3Pos center;

	// previous rotation and COM for TOI
	b3Quat rotation0;
	b3Pos center0;

	// location of center of mass relative to the body origin
	b3Vec3 localCenter;

	b3Vec3 force;
	b3Vec3 torque;

	float invMass;

	// Rotational inertia about the center of mass. The world space inverse inertia tensor
	// must be updated whenever the body rotation is modified.
	b3Matrix3 invInertiaLocal;
	b3Matrix3 invInertiaWorld;

	float minExtent;
	b3Vec3 maxExtent;
	float maxAngularVelocity;
	float linearDamping;
	float angularDamping;
	float gravityScale;

	// Index of b3Body
	int bodyId;

	// b3BodyFlags
	uint32_t flags;
} b3BodySim;

// Get a validated body from a world using an id.
b3Body* b3GetBodyFullId( b3World* world, b3BodyId bodyId );

b3WorldTransform b3GetBodyTransformQuick( b3World* world, b3Body* body );
b3WorldTransform b3GetBodyTransform( b3World* world, int bodyId );

// Create a b3BodyId from a raw id.
b3BodyId b3MakeBodyId( b3World* world, int bodyId );

bool b3ShouldBodiesCollide( b3World* world, b3Body* bodyA, b3Body* bodyB );
bool b3IsBodyAwake( b3World* world, b3Body* body );

b3BodySim* b3GetBodySim( b3World* world, b3Body* body );
b3BodyState* b3GetBodyState( b3World* world, b3Body* body );

// careful calling this because it can invalidate body, state, joint, and contact pointers
bool b3WakeBody( b3World* world, b3Body* body );
bool b3WakeBodyWithLock( b3World* world, b3Body* body );

void b3UpdateBodyMassData( b3World* world, b3Body* body );
void b3SyncBodyFlags( b3World* world, b3Body* body );

// Make a sweep relative to a base position to keep TOI in float precision far from the origin.
static inline b3Sweep b3MakeRelativeSweep( const b3BodySim* bodySim, b3Pos base )
{
	b3Sweep s;
	s.c1 = b3SubPos( bodySim->center0, base );
	s.c2 = b3SubPos( bodySim->center, base );
	s.q1 = bodySim->rotation0;
	s.q2 = bodySim->transform.q;
	s.localCenter = bodySim->localCenter;
	return s;
}

