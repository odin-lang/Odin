// SPDX-FileCopyrightText: 2025 Erin Catto
// SPDX-License-Identifier: MIT

// Solver work is partitioned into fixed-size blocks that worker threads claim
// in parallel via atomic CAS on a per-block syncIndex. The descriptor (b3SolverBlock)
// and the atomic counter sit in a wrapping b3SyncBlock so the CAS-winner can
// pass the descriptor by value into stage tasks without aliasing the atomic
// memory other threads are CAS-writing. Three properties of this design
// matter for performance:
//
// 1. Distributed contention. Per-block atomic syncIndex avoids the cache line stampede
//    that a single shared fetch_add counter would cause. Once a worker
//    settles into a block range, its CAS targets live in its own L1.
//
// 2. Monotonic syncIndex across iterations. Iterative stages (warm start,
//    solve, relax) reuse the same block array every sub-step iteration.
//    syncIndex grows each iteration; workers CAS (prev, prev+1), so the
//    main thread never touches any per-block state between iterations.
//    Non-iterative stages simply use syncIndex 1.
//
// 3. L2 affinity across iterations. Each worker picks a start offset from
//    its workerIndex, then scans forward and (after wrap) backward:
//
//      blocks:   [0] [1] [2] [3] [4] [5] [6] [7]
//                 ^           ^           ^   ^
//                 W0          W1          W2  W3   <- start offsets
//
//    W0 claims 0,1,2,3 (forward), W1 claims 4,5, etc. Under balanced load
//    each worker re-hits the same block range every iteration, keeping that
//    range's hot data resident in its L2. A failed CAS means a neighbour
//    already claimed the block, so the stealing worker stops -- preserving
//    locality under mild imbalance while still draining the queue.
//
// A graph color stage lays out joint blocks first, then contact blocks:
//
//      stage->blocks ->
//        +------+------+------+------+------+------+------+
//        |  J0  |  J1  |  J2  |  C0  |  C1  |  C2  |  C3  |
//        +------+------+------+------+------+------+------+
//        <-- graphJointBlocks --><---- graphContactBlocks ---->
//
// Each block carries its type so the dispatcher routes J-blocks to the joint
// solver and C-blocks to the SIMD contact solver; both kinds run concurrently
// within the stage -- no barrier between them. The type tag lives on the
// block (not the stage) so that mixed-type stages can keep the concurrency.
//
// The solver threading model is inspired by https://github.com/bepu/bepuphysics2

#pragma once

#include "container.h"
#include "core.h"

#include "box3d/math_functions.h"

#include <stdint.h>

typedef struct b3BodySim b3BodySim;
typedef struct b3BodyState b3BodyState;
typedef struct b3ContactConstraint b3ContactConstraint;
typedef struct b3ContactConstraintWide b3ContactConstraintWide;
typedef struct b3ContactSpec b3ContactSpec;
typedef struct b3JointSim b3JointSim;
typedef struct b3Manifold b3Manifold;
typedef struct b3ManifoldConstraint b3ManifoldConstraint;
typedef struct b3World b3World;

// Solver stages
typedef enum b3SolverStageType
{
	b3_stagePrepareJoints,
	b3_stagePrepareWideContacts,
	b3_stagePrepareContacts,
	b3_stageIntegrateVelocities,
	b3_stageWarmStart,
	b3_stageSolve,
	b3_stageIntegratePositions,
	b3_stageRelax,
	b3_stageRestitution,
	b3_stageStoreWideImpulses,
	b3_stageStoreImpulses,
} b3SolverStageType;

typedef enum b3SolverBlockType
{
	// Block for iterating across bodies.
	b3_bodyBlock,

	// Block for iterating across joints. For prepare.
	b3_jointBlock,

	// Block for iterating across wide contacts. For prepare and store.
	b3_wideContactBlock,

	// Block for iterating across contacts. For prepare and store.
	b3_contactBlock,

	// Block for iterating across joints of a single graph color.
	b3_graphJointBlock,

	// Block for iterating across wide contacts of a single graph color.
	b3_graphWideContactBlock,

	// Block for iterating across contacts of a single graph color.
	b3_graphContactBlock,

	// Block for processing overflow constraints
	b3_overflowBlock,
} b3SolverBlockType;

// Solver block describes a multithreaded unit of work.
typedef struct b3SolverBlock
{
	int startIndex;
	uint16_t count;
	// b3SolverBlockType
	uint8_t blockType;
	uint8_t colorIndex;
} b3SolverBlock;

// A unit of multithreaded work along with atomic synchronization. The syncIndex grows
// monotonically allowing the solver block to be re-used across sub-steps.
typedef struct b3SyncBlock
{
	b3SolverBlock block;
	b3AtomicInt syncIndex;
} b3SyncBlock;

// Each stage must be completed before going to the next stage.
// Non-iterative stages use a stage instance once while iterative stages re-use the same instance each iteration.
typedef struct b3SolverStage
{
	b3SyncBlock* blocks;
	b3SolverStageType type;
	int blockCount;
	uint8_t colorIndex;
	b3AtomicInt completionCount;
} b3SolverStage;

// Constraint softness
typedef struct b3Softness
{
	float biasRate;
	float massScale;
	float impulseScale;
} b3Softness;

// Prepare/store run as a flat parallel-for over the whole wide-constraint
// range. Each span maps a slice of that range back to the owning color's
// contacts so workers can decode flat wide-slot indices without touching
// graph state. The spans array has one entry per active color plus a sentinel
// whose start == wideContactCount.
typedef struct b3WidePrepareSpan
{
	int start;
	int count;
	int* contacts;
} b3WidePrepareSpan;

typedef struct b3ContactPrepareSpan
{
	int start;
	int count;
	b3ContactSpec* contacts;
} b3ContactPrepareSpan;

typedef struct b3JointPrepareSpan
{
	int start;
	int count;
	b3JointSim* joints;
} b3JointPrepareSpan;

// Context for a time step. Recreated each time step.
typedef struct b3StepContext
{
	// time step
	float dt;

	// inverse time step (0 if dt == 0).
	float inv_dt;

	// sub-step
	float h;
	float inv_h;

	int subStepCount;

	b3Softness contactSoftness;
	b3Softness staticSoftness;

	float restitutionThreshold;
	float maxLinearVelocity;

	struct b3World* world;
	struct b3ConstraintGraph* graph;

	// shortcut to body states from awake set
	b3BodyState* states;

	// shortcut to body sims from awake set
	b3BodySim* sims;

	// array of all shape ids for shapes that have enlarged AABBs
	int* enlargedShapes;
	int enlargedShapeCount;

	// Array of bullet bodies that need continuous collision handling
	int* bulletBodies;
	b3AtomicInt bulletBodyCount;

	// Contact ids for simplified parallel-for access. Used in narrow-phase.
	// These contacts may or may not be touching. They are associated with awake bodies.
	int* awakeContactIndices;

	// Flat view of the wide contact constraint array used by prepare and store.
	// prepareSpans has activeColorCount + 1 entries, the last being a sentinel
	// at wideContactCount. wideContactConstraints is the contiguous base
	// pointer; per-color slices live at colors[i].wideConstraints.
	struct b3ContactConstraintWide* wideConstraints;
	b3WidePrepareSpan* widePrepareSpans;
	int wideContactCount;

	// Similar for mesh/overflow contact constraints
	struct b3ManifoldConstraint* manifoldConstraints;
	struct b3ContactConstraint* contactConstraints;
	b3ContactPrepareSpan* contactPrepareSpans;
	b3ContactPrepareSpan* overflowSpans;
	b3JointPrepareSpan* jointPrepareSpans;

	int activeColorCount;
	int workerCount;

	b3SolverStage* stages;
	int stageCount;
	bool enableWarmStarting;

	// padding to prevent false sharing
	char padding1[64];

	// This atomic is central to multi-threaded solver task synchronization.
	// It prevents ABA problems by monotonically growing as the solver advances.
	// This means a delayed worker thread will catch up without repeating already completed
	// work (causing a race condition).
	// sync index (16-bits) | stage type (16-bits)
	b3AtomicU32 atomicSyncBits;

	// padding to prevent false sharing
	char padding2[64];

	// Race flag claimed by whichever runner reaches b3SolverTask with workerIndex 0 first.
	// The calling thread of b3World_Step also races for this slot so the orchestrator can
	// always make progress, regardless of how the user's task system schedules tasks (out
	// of order, fewer threads than workers, or synchronously inside enqueueTaskFcn). The
	// loser of the race no-ops as workerIndex 0.
	b3AtomicInt mainClaimed;

	// padding to prevent false sharing
	char padding3[64];
} b3StepContext;

void b3Solve( b3World* world, b3StepContext* stepContext );

static inline b3Softness b3MakeSoft( float hertz, float zeta, float h )
{
	if ( hertz == 0.0f )
	{
		return B3_LITERAL( b3Softness ){
			.biasRate = 0.0f,
			.massScale = 0.0f,
			.impulseScale = 0.0f,
		};
	}

	float omega = 2.0f * B3_PI * hertz;
	float a1 = 2.0f * zeta + h * omega;
	float a2 = h * omega * a1;
	float a3 = 1.0f / ( 1.0f + a2 );

	// bias = w / (2 * z + hw)
	// massScale = hw * (2 * z + hw) / (1 + hw * (2 * z + hw))
	// impulseScale = 1 / (1 + hw * (2 * z + hw))

	// If z == 0
	// bias = 1/h
	// massScale = hw^2 / (1 + hw^2)
	// impulseScale = 1 / (1 + hw^2)

	// w -> inf
	// bias = 1/h
	// massScale = 1
	// impulseScale = 0

	// if w = pi / 4  * inv_h
	// massScale = (pi/4)^2 / (1 + (pi/4)^2) = pi^2 / (16 + pi^2) ~= 0.38
	// impulseScale = 1 / (1 + (pi/4)^2) = 16 / (16 + pi^2) ~= 0.62

	// In all cases:
	// massScale + impulseScale == 1

	return ( b3Softness ){
		.biasRate = omega / a1,
		.massScale = a2 * a3,
		.impulseScale = a3,
	};
}
