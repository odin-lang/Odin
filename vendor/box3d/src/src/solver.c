// SPDX-FileCopyrightText: 2025 Erin Catto
// SPDX-License-Identifier: MIT

#include "solver.h"

#include "arena_allocator.h"
#include "bitset.h"
#include "body.h"
#include "compound.h"
#include "contact.h"
#include "contact_solver.h"
#include "core.h"
#include "ctz.h"
#include "island.h"
#include "joint.h"
#include "parallel_for.h"
#include "physics_world.h"
#include "platform.h"
#include "sensor.h"
#include "shape.h"
#include "solver_set.h"

#include <limits.h>
#include <stddef.h>
#include <stdio.h>

// these are useful for solver testing
#define ITERATIONS 1
#define RELAX_ITERATIONS 1

#if ( defined( __GNUC__ ) || defined( __clang__ ) ) && ( defined( __i386__ ) || defined( __x86_64__ ) )
static void b3Pause( void )
{
	__asm__ __volatile__( "pause\n" );
}
#elif ( defined( __arm__ ) && defined( __ARM_ARCH ) && __ARM_ARCH >= 7 ) || defined( __aarch64__ )
static void b3Pause( void )
{
	__asm__ __volatile__( "yield" ::: "memory" );
}
#elif defined( _MSC_VER ) && ( defined( _M_IX86 ) || defined( _M_X64 ) )
static void b3Pause( void )
{
	_mm_pause();
}
#elif defined( _MSC_VER ) && ( defined( _M_ARM ) || defined( _M_ARM64 ) )
static void b3Pause( void )
{
	__yield();
}
#else
static void b3Pause( void )
{
}
#endif

typedef struct b3WorkerContext
{
	b3StepContext* context;
	int workerIndex;
	void* userTask;
} b3WorkerContext;

// Integrate velocities, apply damping, and gyroscopic torque
static void b3IntegrateVelocitiesTask( b3SolverBlock block, b3StepContext* context )
{
	b3TracyCZoneNC( integrate_velocity, "IntVel", b3_colorDeepPink, true );

	B3_VALIDATE( block.startIndex + block.count <= context->world->solverSets.data[b3_awakeSet].bodyStates.count );

	b3BodyState* states = context->states;
	b3BodySim* sims = context->sims;

	b3Vec3 gravity = context->world->gravity;
	float h = context->h;

	for ( int i = block.startIndex; i < block.startIndex + block.count; ++i )
	{
		b3BodySim* sim = sims + i;
		b3BodyState* state = states + i;

		b3Vec3 v = state->linearVelocity;
		b3Vec3 w = state->angularVelocity;

		// Damping math
		// Differential equation: dv/dt + c * v = 0
		// Solution: v(t) = v0 * exp(-c * t)
		// Time step: v(t + dt) = v0 * exp(-c * (t + dt)) = v0 * exp(-c * t) * exp(-c * dt) = v(t) * exp(-c * dt)
		// v2 = exp(-c * dt) * v1
		// Pade approximation:
		// v2 = v1 * 1 / (1 + c * dt)
		float linearDamping = 1.0f / ( 1.0f + h * sim->linearDamping );
		float angularDamping = 1.0f / ( 1.0f + h * sim->angularDamping );

		// Gravity scale will be zero for kinematic bodies
		float gravityScale = sim->invMass > 0.0f ? sim->gravityScale : 0.0f;

		b3Vec3 linearVelocityDelta = b3Blend2( h * sim->invMass, sim->force, h * gravityScale, gravity );
		v = b3MulAdd( linearVelocityDelta, linearDamping, v );

		b3Vec3 angularVelocityDelta = b3MulSV( h, b3MulMV( sim->invInertiaWorld, sim->torque ) );
		w = b3MulAdd( angularVelocityDelta, angularDamping, w );

		// Gyroscopic torque by solving this nonlinear equation using Newton-Raphson.
		// I * (w2 - w1) + h * cross(w2, I * w2) = 0
		// This is all done in local coordinates where the Jacobian is easier to compute.
		// This improves the simulation of long skinny bodies.
		{
			// Get current rotation.
			b3Quat q0 = sim->transform.q;
			b3Quat q = b3MulQuat( state->deltaRotation, q0 );

			// todo wasteful computation
			b3Matrix3 inertiaLocal = b3InvertMatrix( sim->invInertiaLocal );

			// Compute local angular velocity
			b3Vec3 omega1 = b3InvRotateVector( q, w );
			b3Vec3 omega2 = omega1;

			// Symmetric inertia tensor: 6 unique entries (column-major)
			const float i00 = inertiaLocal.cx.x;
			const float i01 = inertiaLocal.cy.x;
			const float i02 = inertiaLocal.cz.x;
			const float i11 = inertiaLocal.cy.y;
			const float i12 = inertiaLocal.cz.y;
			const float i22 = inertiaLocal.cz.z;

			for ( int gyroIteration = 0; gyroIteration < 1; ++gyroIteration )
			{
				const float w1 = omega2.x;
				const float w2 = omega2.y;
				const float w3 = omega2.z;

				// Iw = I * omega2 (shared between residual and Jacobian)
				const float Iw1 = i00 * w1 + i01 * w2 + i02 * w3;
				const float Iw2 = i01 * w1 + i11 * w2 + i12 * w3;
				const float Iw3 = i02 * w1 + i12 * w2 + i22 * w3;

				// Residual: b = I*(omega2 - omega1) + h * (omega2 × I*omega2)
				const b3Vec3 dw = b3Sub( omega2, omega1 );
				b3Vec3 b = {
					i00 * dw.x + i01 * dw.y + i02 * dw.z + h * ( w2 * Iw3 - w3 * Iw2 ),
					i01 * dw.x + i11 * dw.y + i12 * dw.z + h * ( w3 * Iw1 - w1 * Iw3 ),
					i02 * dw.x + i12 * dw.y + i22 * dw.z + h * ( w1 * Iw2 - w2 * Iw1 ),
				};

				// Jacobian J = I + h * (skew(omega2) * I - skew(I*omega2))
				// Jacobian derived by Erin Catto, Ph.D. Do not attempt to do this without a Ph.D.
				// Doubled inertia terms above fold into Iw, e.g. row 2 col 1: i00*w3 - i02*w1 - Iw3.
				b3Matrix3 J = {
					{ i00 + h * ( w2 * i02 - w3 * i01 ), i01 + h * ( w3 * i00 - w1 * i02 - Iw3 ),
					  i02 + h * ( w1 * i01 - w2 * i00 + Iw2 ) },
					{ i01 + h * ( w2 * i12 - w3 * i11 + Iw3 ), i11 + h * ( w3 * i01 - w1 * i12 ),
					  i12 + h * ( w1 * i11 - w2 * i01 - Iw1 ) },
					{ i02 + h * ( w2 * i22 - w3 * i12 - Iw2 ), i12 + h * ( w3 * i02 - w1 * i22 + Iw1 ),
					  i22 + h * ( w1 * i12 - w2 * i02 ) },
				};

				omega2 = b3Sub( omega2, b3Solve3( J, b ) );
			}

			w = b3RotateVector( q, omega2 );
		}

		state->linearVelocity = v;
		state->angularVelocity = w;
	}

	b3TracyCZoneEnd( integrate_velocity );
}

static void b3IntegratePositionsTask( b3SolverBlock block, b3StepContext* context )
{
	b3TracyCZoneNC( integrate_positions, "IntPos", b3_colorDarkSeaGreen, true );

	B3_VALIDATE( block.startIndex + block.count <= context->world->solverSets.data[b3_awakeSet].bodyStates.count );

	b3BodyState* states = context->states;
	float h = context->h;
	float maxLinearSpeed = context->maxLinearVelocity;
	float maxAngularSpeed = B3_MAX_ROTATION * context->inv_dt;
	float maxLinearSpeedSquared = maxLinearSpeed * maxLinearSpeed;
	float maxAngularSpeedSquared = maxAngularSpeed * maxAngularSpeed;

	for ( int i = block.startIndex; i < block.startIndex + block.count; ++i )
	{
		b3BodyState* state = states + i;

		b3Vec3 v = state->linearVelocity;
		b3Vec3 w = state->angularVelocity;

		// Motion locks - these can be viewed as a constraint that come last
		v.x = ( state->flags & b3_lockLinearX ) ? 0.0f : v.x;
		v.y = ( state->flags & b3_lockLinearY ) ? 0.0f : v.y;
		v.z = ( state->flags & b3_lockLinearZ ) ? 0.0f : v.z;
		w.x = ( state->flags & b3_lockAngularX ) ? 0.0f : w.x;
		w.y = ( state->flags & b3_lockAngularY ) ? 0.0f : w.y;
		w.z = ( state->flags & b3_lockAngularZ ) ? 0.0f : w.z;

		// Clamp to max linear speed
		if ( b3Dot( v, v ) > maxLinearSpeedSquared )
		{
			float ratio = maxLinearSpeed / b3Length( v );
			v = b3MulSV( ratio, v );
			state->flags |= b3_isSpeedCapped;
		}

		// Clamp to max angular speed
		if ( b3Dot( w, w ) > maxAngularSpeedSquared && ( state->flags & b3_allowFastRotation ) == 0 )
		{
			float ratio = maxAngularSpeed / b3Length( w );
			w = b3MulSV( ratio, w );
			state->flags |= b3_isSpeedCapped;
		}

		state->linearVelocity = v;
		state->angularVelocity = w;
		state->deltaPosition = b3MulAdd( state->deltaPosition, h, v );
		state->deltaRotation = b3IntegrateRotation( state->deltaRotation, b3MulSV( h, w ) );
	}

	b3TracyCZoneEnd( integrate_positions );
}

static void b3PrepareJointsTask( b3SolverBlock block, b3StepContext* context )
{
	b3TracyCZoneNC( prepare_joints, "PrepJoints", b3_colorOldLace, true );

	b3JointPrepareSpan* spans = context->jointPrepareSpans;

	int index = block.startIndex;
	int endIndex = block.startIndex + block.count;

	// Find color for start index. Linear search but fast.
	int colorIndex = 0;
	while ( spans[colorIndex + 1].start <= index )
	{
		colorIndex += 1;
	}

	// Loop over block
	while ( index < endIndex )
	{
		int colorStart = spans[colorIndex].start;
		int colorEndIndex = b3MinInt( spans[colorIndex + 1].start, endIndex );
		b3JointSim* joints = spans[colorIndex].joints;

		// Loop over color
		for ( ; index < colorEndIndex; ++index )
		{
			B3_ASSERT( 0 <= index - colorStart && index - colorStart < spans[colorIndex].count );
			b3JointSim* joint = joints + ( index - colorStart );
			b3PrepareJoint( joint, context );
		}

		// Advance to next color
		colorIndex += 1;
	}

	b3TracyCZoneEnd( prepare_joints );
}

static void b3WarmStartJointsTask( b3SolverBlock block, b3StepContext* context )
{
	b3TracyCZoneNC( warm_joints, "WarmJoints", b3_colorGold, true );

	b3GraphColor* color = context->graph->colors + block.colorIndex;
	b3JointSim* joints = color->jointSims.data;

	for ( int i = block.startIndex; i < block.startIndex + block.count; ++i )
	{
		b3JointSim* joint = joints + i;
		b3WarmStartJoint( joint, context );
	}

	b3TracyCZoneEnd( warm_joints );
}

static void b3SolveJointsTask( b3SolverBlock block, b3StepContext* context, bool useBias, int workerIndex )
{
	b3TracyCZoneNC( solve_joints, "SolveJoints", b3_colorLemonChiffon, true );

	b3GraphColor* color = context->graph->colors + block.colorIndex;
	b3JointSim* joints = color->jointSims.data;

	B3_ASSERT( 0 <= block.startIndex && block.startIndex + block.count <= color->jointSims.count );

	b3BitSet* jointStateBitSet = &context->world->taskContexts.data[workerIndex].jointStateBitSet;

	for ( int i = block.startIndex; i < block.startIndex + block.count; ++i )
	{
		b3JointSim* joint = joints + i;
		b3SolveJoint( joint, context, useBias );

		if ( useBias && ( joint->forceThreshold < FLT_MAX || joint->torqueThreshold < FLT_MAX ) &&
			 b3GetBit( jointStateBitSet, joint->jointId ) == false )
		{
			float force, torque;
			b3GetJointReaction( context->world, joint, context->inv_h, &force, &torque );

			// Check thresholds. A zero threshold means all awake joints get reported.
			if ( force >= joint->forceThreshold || torque >= joint->torqueThreshold )
			{
				// Flag this joint for processing.
				b3SetBit( jointStateBitSet, joint->jointId );
			}
		}
	}

	b3TracyCZoneEnd( solve_joints );
}

#define B2_MAX_CONTINUOUS_SENSOR_HITS 8

typedef struct b3ContinuousContext
{
	b3World* world;
	b3BodySim* fastBodySim;
	b3Shape* fastShape;
	b3Vec3 centroid1, centroid2;
	b3Sweep sweep;
	// World base for re-centering sweeps. Keeps TOI in float precision far from the origin.
	b3Pos base;
	float fraction;
	b3SensorHit sensorHits[B2_MAX_CONTINUOUS_SENSOR_HITS];
	float sensorFractions[B2_MAX_CONTINUOUS_SENSOR_HITS];
	int sensorCount;

	int visitCount;

	int distanceIterations;
	int pushBackIterations;
	int rootIterations;
} b3ContinuousContext;

// This is called from b3DynamicTree_Query for continuous collision
static bool b3ContinuousQueryCallback( int proxyId, uint64_t userData, void* context )
{
	B3_UNUSED( proxyId );

	int shapeId = (int)userData;
	b3ContinuousContext* continuousContext = context;
	continuousContext->visitCount += 1;

	b3Shape* fastShape = continuousContext->fastShape;
	b3BodySim* fastBodySim = continuousContext->fastBodySim;

	B3_ASSERT( fastShape->sensorIndex == B3_NULL_INDEX );

	// Skip same shape
	if ( shapeId == fastShape->id )
	{
		return true;
	}

	b3World* world = continuousContext->world;
	b3Shape* shape = b3Array_Get( world->shapes, shapeId );

	// Skip same body
	if ( shape->bodyId == fastShape->bodyId )
	{
		return true;
	}

	// Skip sensors unless both shapes want sensor events
	bool isSensor = shape->sensorIndex != B3_NULL_INDEX;
	if ( isSensor && ( ( shape->flags & b3_enableSensorEvents ) == 0 || ( fastShape->flags & b3_enableSensorEvents ) == 0 ) )
	{
		return true;
	}

	// Skip filtered shapes
	bool canCollide = b3ShouldShapesCollide( fastShape->filter, shape->filter );
	if ( canCollide == false )
	{
		return true;
	}

	b3Body* body = b3Array_Get( world->bodies, shape->bodyId );

	b3BodySim* bodySim = b3GetBodySim( world, body );
	B3_ASSERT( body->type == b3_staticBody || ( fastBodySim->flags & b3_isBullet ) );

	// Skip bullets
	if ( bodySim->flags & b3_isBullet )
	{
		return true;
	}

	// Skip filtered bodies
	b3Body* fastBody = b3Array_Get( world->bodies, fastBodySim->bodyId );
	canCollide = b3ShouldBodiesCollide( world, fastBody, body );
	if ( canCollide == false )
	{
		return true;
	}

	// Custom user filtering
	if ( ( shape->flags & b3_enableCustomFiltering ) != 0 || ( fastShape->flags & b3_enableCustomFiltering ) != 0 )
	{
		b3CustomFilterFcn* customFilterFcn = world->customFilterFcn;
		if ( customFilterFcn != NULL )
		{
			b3ShapeId idA = { shape->id + 1, world->worldId, shape->generation };
			b3ShapeId idB = { fastShape->id + 1, world->worldId, fastShape->generation };
			canCollide = customFilterFcn( idA, idB, world->customFilterContext );
			if ( canCollide == false )
			{
				return true;
			}
		}
	}

	uint64_t ticks = b3GetTicks();

	// todo does having a sweep on shapeA help with bullets?
	b3Sweep sweepA = b3MakeRelativeSweep( bodySim, continuousContext->base );

	// Time of impact versus shape. Supports all shape types
	b3TOIOutput output = b3ShapeTimeOfImpact( shape, fastShape, &sweepA, &continuousContext->sweep, continuousContext->fraction );
	if ( isSensor )
	{
		// Only accept a sensor hit that is sooner than the current solid hit.
		if ( output.fraction <= continuousContext->fraction && continuousContext->sensorCount < B2_MAX_CONTINUOUS_SENSOR_HITS )
		{
			int index = continuousContext->sensorCount;

			// The hit shape is a sensor
			b3SensorHit sensorHit = {
				.sensorId = shape->id,
				.visitorId = fastShape->id,
			};

			continuousContext->sensorHits[index] = sensorHit;
			continuousContext->sensorFractions[index] = output.fraction;
			continuousContext->sensorCount += 1;
		}
	}
	else if ( 0.0f < output.fraction && output.fraction < continuousContext->fraction )
	{
		bool didHit = true;

		if ( didHit && ( ( shape->flags & b3_enablePreSolveEvents ) || ( fastShape->flags & b3_enablePreSolveEvents ) ) )
		{
			b3ShapeId shapeIdA = { shape->id + 1, world->worldId, shape->generation };
			b3ShapeId shapeIdB = { fastShape->id + 1, world->worldId, fastShape->generation };
			b3Pos point = b3OffsetPos( continuousContext->base, output.point );
			didHit = world->preSolveFcn( shapeIdA, shapeIdB, point, output.normal, world->preSolveContext );
		}

		if ( didHit )
		{
			fastBodySim->flags |= b3_hadTimeOfImpact;
			continuousContext->fraction = output.fraction;
			continuousContext->distanceIterations = b3MaxInt( continuousContext->distanceIterations, output.distanceIterations );
			continuousContext->pushBackIterations = b3MaxInt( continuousContext->pushBackIterations, output.pushBackIterations );
			continuousContext->rootIterations = b3MaxInt( continuousContext->rootIterations, output.rootIterations );
		}
	}

	float ms = b3GetMilliseconds( ticks );
	if ( ms > 1000.0f * b3GetStallThreshold() )
	{
		const char* nameFast = b3FindNameWithDefault( &world->names, fastBody->nameId, "NULL" );
		const char* name = b3FindNameWithDefault( &world->names, body->nameId, "NULL" );
		b3Log( "CCD stall: duration %.1f ms for %s versus %s", ms, nameFast, name );
	}

	// Continue query
	return true;
}

// Continuous collision of dynamic versus static
static void b3SolveContinuous( b3World* world, int bodySimIndex, b3TaskContext* taskContext )
{
	b3TracyCZoneNC( ccd, "CCD", b3_colorDarkGoldenRod, true );

	uint64_t ticks = b3GetTicks();

	b3SolverSet* awakeSet = b3Array_Get( world->solverSets, b3_awakeSet );
	b3BodySim* fastBodySim = b3Array_Get( awakeSet->bodySims, bodySimIndex );
	B3_ASSERT( fastBodySim->flags & b3_isFast );

	// Re-center the sweep on the fast body so the TOI and the swept query stay in float precision
	b3Pos base = fastBodySim->center0;

	b3Sweep sweep = b3MakeRelativeSweep( fastBodySim, base );

	b3Transform xf1;
	xf1.q = sweep.q1;
	xf1.p = b3Sub( sweep.c1, b3RotateVector( sweep.q1, sweep.localCenter ) );

	b3Transform xf2;
	xf2.q = sweep.q2;
	xf2.p = b3Sub( sweep.c2, b3RotateVector( sweep.q2, sweep.localCenter ) );

	b3DynamicTree* staticTree = world->broadPhase.trees + b3_staticBody;
	b3DynamicTree* kinematicTree = world->broadPhase.trees + b3_kinematicBody;
	b3DynamicTree* dynamicTree = world->broadPhase.trees + b3_dynamicBody;
	b3Body* fastBody = b3Array_Get( world->bodies, fastBodySim->bodyId );

	b3ContinuousContext context = { 0 };
	context.world = world;
	context.sweep = sweep;
	context.base = base;
	context.fastBodySim = fastBodySim;
	context.fraction = 1.0f;

	bool isBullet = ( fastBodySim->flags & b3_isBullet ) != 0;

	int shapeId = fastBody->headShapeId;
	while ( shapeId != B3_NULL_INDEX )
	{
		b3Shape* fastShape = b3Array_Get( world->shapes, shapeId );
		shapeId = fastShape->nextShapeId;

		context.fastShape = fastShape;
		context.centroid1 = b3TransformPoint( xf1, fastShape->localCentroid );
		context.centroid2 = b3TransformPoint( xf2, fastShape->localCentroid );

		b3AABB box1 = fastShape->aabb;
		// xf2 is relative to the base, so translate the box back to world space, rounding outward
		b3AABB box2 = b3OffsetAABB( b3ComputeShapeAABB( fastShape, xf2 ), base );

		// Store this to avoid double computation in the case there is no impact event
		fastShape->aabb = box2;

		// No continuous collision for meshes
		if ( fastShape->type == b3_meshShape || fastShape->type == b3_heightShape )
		{
			continue;
		}

		// No continuous collision for sensors
		if ( fastShape->sensorIndex != B3_NULL_INDEX )
		{
			continue;
		}

		b3AABB sweptBox = b3AABB_Union( box1, box2 );
		b3DynamicTree_Query( staticTree, sweptBox, B3_DEFAULT_MASK_BITS, false, b3ContinuousQueryCallback, &context );

		if ( isBullet )
		{
			b3DynamicTree_Query( kinematicTree, sweptBox, B3_DEFAULT_MASK_BITS, false, b3ContinuousQueryCallback, &context );
			b3DynamicTree_Query( dynamicTree, sweptBox, B3_DEFAULT_MASK_BITS, false, b3ContinuousQueryCallback, &context );
		}
	}

	const float speculativeScalar = B3_SPECULATIVE_DISTANCE;

	if ( context.fraction < 1.0f )
	{
		// Handle time of impact event. The sweep is relative to the base, so re-add the base
		// to return the advanced pose to world space.
		b3Quat q = b3NLerp( sweep.q1, sweep.q2, context.fraction );
		b3Vec3 c = b3Lerp( sweep.c1, sweep.c2, context.fraction );
		b3Vec3 origin = b3Sub( c, b3RotateVector( q, sweep.localCenter ) );

		// Advance body
		b3WorldTransform transform = { b3OffsetPos( base, origin ), q };
		b3Pos center = b3OffsetPos( base, c );
		fastBodySim->transform = transform;
		fastBodySim->center = center;
		fastBodySim->rotation0 = q;
		fastBodySim->center0 = center;

		// The move event was written before CCD, so correct it with the impact pose
		b3BodyMoveEvent* event = b3Array_Get( world->bodyMoveEvents, bodySimIndex );
		event->transform = fastBodySim->transform;

		// Prepare AABBs for broad-phase.
		// Even though a body is fast, it may not move much. So the AABB may not need enlargement.

		shapeId = fastBody->headShapeId;
		while ( shapeId != B3_NULL_INDEX )
		{
			b3Shape* shape = b3Array_Get( world->shapes, shapeId );

			// Must recompute aabb at the interpolated transform
			b3AABB aabb = b3ComputeFatShapeAABB( shape, transform, speculativeScalar );
			shape->aabb = aabb;

			if ( b3AABB_Contains( shape->fatAABB, aabb ) == false )
			{
				float marginScalar = shape->aabbMargin;
				b3Vec3 aabbMargin = { marginScalar, marginScalar, marginScalar };
				shape->fatAABB = (b3AABB){ b3Sub( aabb.lowerBound, aabbMargin ), b3Add( aabb.upperBound, aabbMargin ) };

				shape->flags |= b3_enlargedAABB;
				fastBodySim->flags |= b3_enlargeBounds;
			}

			shapeId = shape->nextShapeId;
		}
	}
	else
	{
		// No time of impact event

		// Advance body
		fastBodySim->rotation0 = fastBodySim->transform.q;
		fastBodySim->center0 = fastBodySim->center;

		// Prepare AABBs for broad-phase
		shapeId = fastBody->headShapeId;
		while ( shapeId != B3_NULL_INDEX )
		{
			b3Shape* shape = b3Array_Get( world->shapes, shapeId );

			// shape->aabb is still valid from above

			if ( b3AABB_Contains( shape->fatAABB, shape->aabb ) == false )
			{
				float marginScalar = shape->aabbMargin;
				b3Vec3 aabbMargin = { marginScalar, marginScalar, marginScalar };
				shape->fatAABB = (b3AABB){
					.lowerBound = b3Sub( shape->aabb.lowerBound, aabbMargin ),
					.upperBound = b3Add( shape->aabb.upperBound, aabbMargin ),
				};

				shape->flags |= b3_enlargedAABB;
				fastBodySim->flags |= b3_enlargeBounds;
			}

			shapeId = shape->nextShapeId;
		}
	}

	// Push sensor hits on the the task context for serial processing.
	for ( int i = 0; i < context.sensorCount; ++i )
	{
		// Skip any sensor hits that occurred after a solid hit
		if ( context.sensorFractions[i] < context.fraction )
		{
			b3Array_Push( taskContext->sensorHits, context.sensorHits[i] );
		}
	}

	taskContext->distanceIterations = b3MaxInt( taskContext->distanceIterations, context.distanceIterations );
	taskContext->pushBackIterations = b3MaxInt( taskContext->pushBackIterations, context.pushBackIterations );
	taskContext->rootIterations = b3MaxInt( taskContext->rootIterations, context.rootIterations );

	float ms = b3GetMilliseconds( ticks );
	if ( ms > 1000.0f * b3GetStallThreshold() )
	{
		const char* nameFast = b3FindNameWithDefault( &world->names, fastBody->nameId, "NULL" );
		b3Vec3 c1 = sweep.c1;
		b3Vec3 c2 = sweep.c2;
		int vc = context.visitCount;
		b3Log( "CCD stall: duration %.1f ms and visit count %d for %s: c1 = (%g, %g, %g), c2 = (%g, %g, %g)", ms, vc, nameFast,
			   c1.x, c1.y, c1.z, c2.x, c2.y, c2.z );
	}

	b3TracyCZoneEnd( ccd );
}

// Implements b3ParallelForCallback
static void b3FinalizeBodiesTask( int startIndex, int endIndex, int workerIndex, void* context )
{
	b3TracyCZoneNC( finalize_bodies, "Finalize", b3_colorMediumSeaGreen, true );

	b3StepContext* stepContext = (b3StepContext*)context;
	b3World* world = stepContext->world;
	b3Body* bodies = world->bodies.data;
	b3BodySim* sims = stepContext->sims;
	b3BodyState* states = stepContext->states;

	B3_ASSERT( endIndex <= world->bodyMoveEvents.count );

	bool enableSleep = world->enableSleep;
	bool enableContinuous = world->enableContinuous;
	float timeStep = stepContext->dt;
	float invTimeStep = stepContext->inv_dt;
	uint16_t worldId = world->worldId;

	// The body move event array has should already have the correct size
	b3BodyMoveEvent* moveEvents = world->bodyMoveEvents.data;

	b3TaskContext* taskContext = world->taskContexts.data + workerIndex;
	b3BitSet* enlargedSimBitSet = &taskContext->enlargedSimBitSet;
	b3BitSet* awakeIslandBitSet = &taskContext->awakeIslandBitSet;

	const float speculativeScalar = B3_SPECULATIVE_DISTANCE;

	for ( int simIndex = startIndex; simIndex < endIndex; ++simIndex )
	{
		b3BodyState* state = states + simIndex;
		b3BodySim* sim = sims + simIndex;

		b3Vec3 v = state->linearVelocity;
		b3Vec3 w = state->angularVelocity;
		b3Vec3 localOmega = b3InvRotateVector( sim->transform.q, w );
		b3Vec3 localDeltaRotation = b3InvRotateVector( sim->transform.q, state->deltaRotation.v );

		if ( b3IsValidVec3( v ) == false || b3IsValidVec3( w ) == false )
		{
			const char* name = b3FindNameWithDefault( &world->names, bodies[sim->bodyId].nameId, "NULL" );
			b3Log( "unstable: %s", name );
		}

		B3_ASSERT( b3IsValidVec3( v ) );
		B3_ASSERT( b3IsValidVec3( w ) );

		sim->center = b3OffsetPos( sim->center, state->deltaPosition );
		sim->transform.q = b3NormalizeQuat( b3MulQuat( state->deltaRotation, sim->transform.q ) );

		// Use the velocity of the farthest point on the body to account for rotation.
		b3Vec3 velocityArc = b3ModifiedCross( b3Abs( localOmega ), sim->maxExtent );
		float maxVelocity = b3Length( v ) + b3Length( velocityArc );

		// Sleep needs to observe position correction as well as true velocity.
		// q = [sin(theta/2) * v, cos(theta/2)]
		// for small angles abs(theta) ~= 2 * length(sin(theta/2) * v)
		b3Vec3 rotationArc = b3ModifiedCross( b3Abs( localDeltaRotation ), sim->maxExtent );
		float maxDeltaPosition = b3Length( state->deltaPosition ) + 2.0f * b3Length( rotationArc );

		// Position correction is not as important for sleep as true velocity.
		float positionSleepFactor = 0.5f;
		float sleepVelocity = b3MaxFloat( maxVelocity, positionSleepFactor * invTimeStep * maxDeltaPosition );

		// reset state deltas
		state->deltaPosition = b3Vec3_zero;
		state->deltaRotation = b3Quat_identity;

		sim->transform.p = b3OffsetPos( sim->center, b3Neg( b3RotateVector( sim->transform.q, sim->localCenter ) ) );

		// cache miss here, however I need the shape list below
		b3Body* body = bodies + sim->bodyId;
		body->bodyMoveIndex = simIndex;
		body->sleepVelocity = sleepVelocity;

		moveEvents[simIndex].userData = body->userData;
		moveEvents[simIndex].transform = sim->transform;
		moveEvents[simIndex].bodyId = (b3BodyId){ sim->bodyId + 1, worldId, body->generation };
		moveEvents[simIndex].fellAsleep = false;

		// reset applied force and torque
		sim->force = b3Vec3_zero;
		sim->torque = b3Vec3_zero;

		// If you hit this then it means you deferred mass computation but never called b3Body_ApplyMassFromShapes
		// or b3Body_SetMassData.
		B3_ASSERT( ( body->flags & b3_dirtyMass ) == 0 );

		body->flags &= ~b3_bodyTransientFlags;
		body->flags |= ( sim->flags & ( b3_isSpeedCapped | b3_hadTimeOfImpact ) );
		body->flags |= ( state->flags & ( b3_isSpeedCapped | b3_hadTimeOfImpact ) );
		sim->flags &= ~b3_bodyTransientFlags;
		state->flags &= ~b3_bodyTransientFlags;

		if ( enableSleep == false || ( body->flags & b3_enableSleep ) == 0 || sleepVelocity > body->sleepThreshold )
		{
			// Body is not sleepy
			body->sleepTime = 0.0f;

			const float safetyFactor = 0.5f;
			float maxMotion = b3MaxFloat( maxDeltaPosition, maxVelocity * timeStep );
			if ( body->type == b3_dynamicBody && enableContinuous && maxMotion > safetyFactor * sim->minExtent )
			{
				// This flag is only retained for debug draw
				sim->flags |= b3_isFast;

				// Store in fast array for the continuous collision stage
				// This is deterministic because the order of TOI sweeps doesn't matter
				if ( sim->flags & b3_isBullet )
				{
					int bulletIndex = b3AtomicFetchAddInt( &stepContext->bulletBodyCount, 1 );
					stepContext->bulletBodies[bulletIndex] = simIndex;
				}
				else
				{
					b3SolveContinuous( world, simIndex, taskContext );
				}
			}
			else
			{
				// Body is safe to advance
				sim->center0 = sim->center;
				sim->rotation0 = sim->transform.q;
			}
		}
		else
		{
			// Body is safe to advance and is falling asleep
			sim->center0 = sim->center;
			sim->rotation0 = sim->transform.q;
			body->sleepTime += timeStep;
		}

		// Update world space inverse inertia tensor.
		b3Matrix3 rotationMatrix = b3MakeMatrixFromQuat( sim->transform.q );
		sim->invInertiaWorld = b3MulMM( b3MulMM( rotationMatrix, sim->invInertiaLocal ), b3Transpose( rotationMatrix ) );

		// Any single body in an island can keep it awake
		b3Island* island = b3Array_Get( world->islands, body->islandId );
		if ( body->sleepTime < B3_TIME_TO_SLEEP )
		{
			// keep island awake
			int islandIndex = island->localIndex;
			b3SetBit( awakeIslandBitSet, islandIndex );
		}
		else if ( island->constraintRemoveCount > 0 )
		{
			// Body wants to sleep but its island needs splitting first. Track the sleepiest candidate.
			// Break sleep time ties using the island id to ensure determinism. The cross worker reduction
			// breaks ties the same way.
			if ( body->sleepTime > taskContext->splitSleepTime ||
				 ( body->sleepTime == taskContext->splitSleepTime && body->islandId > taskContext->splitIslandId ) )
			{
				// pick the sleepiest candidate
				taskContext->splitIslandId = body->islandId;
				taskContext->splitSleepTime = body->sleepTime;
			}
		}

		// Update shapes AABBs
		b3WorldTransform transform = sim->transform;
		bool isFast = ( sim->flags & b3_isFast ) != 0;
		int shapeId = body->headShapeId;
		while ( shapeId != B3_NULL_INDEX )
		{
			b3Shape* shape = b3Array_Get( world->shapes, shapeId );

			if ( isFast )
			{
				// For fast non-bullet bodies the AABB has already been updated in b3SolveContinuous
				// For fast bullet bodies the AABB will be updated at a later stage

				// Add to enlarged shapes regardless of AABB changes.
				// Bit-set to keep the move array sorted
				b3SetBit( enlargedSimBitSet, simIndex );
			}
			else
			{
				b3AABB aabb = b3ComputeFatShapeAABB( shape, transform, speculativeScalar );
				shape->aabb = aabb;

				B3_ASSERT( ( shape->flags & b3_enlargedAABB ) == 0 );

				if ( b3AABB_Contains( shape->fatAABB, aabb ) == false )
				{
					float marginScalar = shape->aabbMargin;
					b3Vec3 aabbMargin = { marginScalar, marginScalar, marginScalar };
					shape->fatAABB = (b3AABB){ b3Sub( aabb.lowerBound, aabbMargin ), b3Add( aabb.upperBound, aabbMargin ) };
					shape->flags |= b3_enlargedAABB;

					// Bit-set to keep the move array sorted
					b3SetBit( enlargedSimBitSet, simIndex );
				}
			}

			shapeId = shape->nextShapeId;
		}
	}

	b3TracyCZoneEnd( finalize_bodies );
}

typedef struct b3BlockDim
{
	// number of items per block (except last block)
	int size;

	// total number of blocks
	int count;
} b3BlockDim;

// A block is a range of tasks, a start index and count as a sub-array. Each worker receives at
// most M blocks of work. The workers may receive less blocks if there is not sufficient work.
// Each block of work has a minimum number of elements (block size). This in turn may limit the
// number of blocks. If there are many elements then the block size is increased so there are
// still at most M blocks of work per worker. M is a tunable number that has two goals:
// 1. keep M small to reduce overhead
// 2. keep M large enough for other workers to be able to steal work
// The block size is a power of two to make math efficient.
static inline b3BlockDim b3ComputeBlockCount( int itemCount, int minSize, int maxBlockCount )
{
	b3BlockDim dim = { 0 };
	if ( itemCount == 0 )
	{
		return dim;
	}

	if ( itemCount <= minSize * maxBlockCount )
	{
		dim.size = minSize;
	}
	else
	{
		dim.size = ( itemCount + maxBlockCount - 1 ) / maxBlockCount;
	}

	dim.count = ( itemCount + dim.size - 1 ) / dim.size;

	B3_ASSERT( dim.count >= 1 );
	B3_ASSERT( dim.size * dim.count >= itemCount );

	return dim;
}

// Initialize solver blocks for a contiguous range of items. Computes block size internally
// from the same parameters used by b3ComputeBlockCount. The atomic claim counter is zeroed
// so workers can CAS (0, 1) on the first stage that owns these blocks.
static void b3InitBlocks( b3SyncBlock* blocks, b3BlockDim dim, int itemCount, uint8_t blockType, uint8_t colorIndex )
{
	if ( dim.count == 0 )
	{
		return;
	}

	B3_ASSERT( itemCount >= dim.count );

	// Compute the number of elements per block
	int blockSize = dim.size;

	// Simulation too big
	B3_ASSERT( blockSize <= UINT16_MAX );

	for ( int i = 0; i < dim.count; ++i )
	{
		blocks[i].block.startIndex = i * blockSize;
		blocks[i].block.count = (uint16_t)blockSize;
		blocks[i].block.blockType = blockType;
		blocks[i].block.colorIndex = colorIndex;
		b3AtomicStoreInt( &blocks[i].syncIndex, 0 );
	}

	// The last block may not be full
	blocks[dim.count - 1].block.count = (uint16_t)( itemCount - ( dim.count - 1 ) * blockSize );

	B3_VALIDATE( blocks[dim.count - 1].block.count <= blockSize );
	B3_VALIDATE( ( dim.count - 1 ) * dim.size + blocks[dim.count - 1].block.count == itemCount );
}

static inline b3SolverStage* b3InitStage( b3SolverStage* stage, b3SolverStageType type, b3SyncBlock* blocks, int blockCount,
										  uint8_t colorIndex )
{
	stage->type = type;
	stage->blocks = blocks;
	stage->blockCount = blockCount;
	stage->colorIndex = colorIndex;
	b3AtomicStoreInt( &stage->completionCount, 0 );
	return stage + 1;
}

// Initialize one stage per color for each iteration. Used for warm start, solve, relax, and restitution.
// All iterations of a given color share the same b3SyncBlock array so the per-block syncIndex
// grows monotonically across stages within that color.
static b3SolverStage* b3InitColorStages( b3SolverStage* stage, b3SolverStageType type, int iterations, int activeColorCount,
										 b3SyncBlock** colorBlocks, int* colorBlockCounts, int* activeColorIndices )
{
	for ( int j = 0; j < iterations; ++j )
	{
		for ( int i = 0; i < activeColorCount; ++i )
		{
			stage = b3InitStage( stage, type, colorBlocks[i], colorBlockCounts[i], (uint8_t)activeColorIndices[i] );
		}
	}
	return stage;
}

static void b3ExecuteBlock( b3SolverStage* stage, b3StepContext* context, b3SolverBlock block, int workerIndex )
{
	b3SolverStageType stageType = stage->type;
	b3SolverBlockType blockType = (b3SolverBlockType)block.blockType;

	switch ( stageType )
	{
		case b3_stagePrepareJoints:
			b3PrepareJointsTask( block, context );
			break;

		case b3_stagePrepareWideContacts:
			b3PrepareContacts_Convex( block, context );
			break;

		case b3_stagePrepareContacts:
			b3PrepareContacts_Mesh( block, context );
			break;

		case b3_stageIntegrateVelocities:
			b3IntegrateVelocitiesTask( block, context );
			break;

		case b3_stageWarmStart:
			if ( blockType == b3_graphJointBlock )
			{
				b3WarmStartJointsTask( block, context );
			}
			else if ( blockType == b3_graphWideContactBlock )
			{
				b3WarmStartContacts_Convex( block, context );
			}
			else
			{
				b3WarmStartContacts_Mesh( block, context );
			}
			break;

		case b3_stageSolve:
			if ( blockType == b3_graphJointBlock )
			{
				bool useBias = true;
				b3SolveJointsTask( block, context, useBias, workerIndex );
			}
			else if ( blockType == b3_graphWideContactBlock )
			{
				bool useBias = true;
				b3SolveContacts_Convex( block, context, useBias );
			}
			else
			{
				bool useBias = true;
				b3SolveContacts_Mesh( block, context, useBias );
			}
			break;

		case b3_stageIntegratePositions:
			b3IntegratePositionsTask( block, context );
			break;

		case b3_stageRelax:
			if ( blockType == b3_graphJointBlock )
			{
				bool useBias = false;
				b3SolveJointsTask( block, context, useBias, workerIndex );
			}
			else if ( blockType == b3_graphWideContactBlock )
			{
				bool useBias = false;
				b3SolveContacts_Convex( block, context, useBias );
			}
			else
			{
				bool useBias = false;
				b3SolveContacts_Mesh( block, context, useBias );
			}
			break;

		case b3_stageRestitution:
			if ( blockType == b3_graphWideContactBlock )
			{
				b3ApplyRestitution_Convex( block, context );
			}
			else if ( blockType == b3_graphContactBlock )
			{
				b3ApplyRestitution_Mesh( block, context );
			}
			break;

		case b3_stageStoreWideImpulses:
			b3StoreImpulses_Convex( block, context, workerIndex );
			break;

		case b3_stageStoreImpulses:
			b3StoreImpulses_Mesh( block, context, workerIndex );
			break;
	}
}

// This staggers the worker start indices so they avoid touching the same solver blocks
static inline int GetWorkerStartIndex( int workerIndex, int blockCount, int workerCount )
{
	if ( blockCount <= workerCount )
	{
		return workerIndex < blockCount ? workerIndex : B3_NULL_INDEX;
	}

	int blocksPerWorker = blockCount / workerCount;
	int remainder = blockCount - blocksPerWorker * workerCount;
	return blocksPerWorker * workerIndex + b3MinInt( remainder, workerIndex );
}

// Execute a stage, which is an array of solver blocks, each controlled with an atomic sync index.
// Each worker starts at its home index and sweeps the ring, CAS-claiming any unclaimed blocks.
static void b3ExecuteStage( b3SolverStage* stage, b3StepContext* context, int previousSyncIndex, int syncIndex, int workerIndex )
{
	int completedCount = 0;
	b3SyncBlock* blocks = stage->blocks;
	int blockCount = stage->blockCount;

	int startIndex = GetWorkerStartIndex( workerIndex, blockCount, context->workerCount );
	if ( startIndex == B3_NULL_INDEX )
	{
		return;
	}

	B3_ASSERT( 0 <= startIndex && startIndex < blockCount );

	int blockIndex = startIndex;
	for ( int i = 0; i < blockCount; ++i )
	{
		if ( b3AtomicCompareExchangeInt( &blocks[blockIndex].syncIndex, previousSyncIndex, syncIndex ) )
		{
			B3_ASSERT( completedCount < blockCount );

			// Pass the descriptor by value -- the wrapping b3SyncBlock holds the atomic
			// syncIndex but we only copy .block, so the struct copy never aliases the CAS target.
			b3ExecuteBlock( stage, context, blocks[blockIndex].block, workerIndex );
			completedCount += 1;
		}

		blockIndex += 1;
		if ( blockIndex >= blockCount )
		{
			blockIndex = 0;
		}
	}

	(void)b3AtomicFetchAddInt( &stage->completionCount, completedCount );
}

// Execute a stage on worker 0 (main thread).
static void b3ExecuteMainStage( b3SolverStage* stage, b3StepContext* context, uint32_t syncBits )
{
	int blockCount = stage->blockCount;
	if ( blockCount == 0 )
	{
		return;
	}

	const int workerIndex = 0;

	if ( blockCount == 1 )
	{
		b3ExecuteBlock( stage, context, stage->blocks[0].block, workerIndex );
	}
	else
	{
		b3AtomicStoreU32( &context->atomicSyncBits, syncBits );

		int syncIndex = ( syncBits >> 16 ) & 0xFFFF;
		B3_ASSERT( syncIndex > 0 );
		int previousSyncIndex = syncIndex - 1;

		b3ExecuteStage( stage, context, previousSyncIndex, syncIndex, workerIndex );

		// Spin waiting for thieves to finish
		while ( b3AtomicLoadInt( &stage->completionCount ) != blockCount )
		{
			b3Pause();
		}

		b3AtomicStoreInt( &stage->completionCount, 0 );
	}
}

// Parallel solver task
static void b3SolverTask( void* taskContext )
{
	b3WorkerContext* workerContext = (b3WorkerContext*)taskContext;
	int workerIndex = workerContext->workerIndex;
	b3StepContext* context = workerContext->context;
	int activeColorCount = context->activeColorCount;
	b3SolverStage* stages = context->stages;
	b3Profile* profile = &context->world->profile;

	if ( workerIndex == 0 )
	{
		// The orchestrator slot is a race. The calling thread of b3World_Step also enters here
		// as worker 0, so progress is guaranteed even if the user's task system schedules tasks
		// out of order, has fewer threads than workerCount, or runs the task synchronously
		// inside enqueueTaskFcn. Whoever wins the CAS becomes the orchestrator; the loser
		// returns and lets the spinner-only path handle workers >0.
		if ( b3AtomicCompareExchangeInt( &context->mainClaimed, 0, 1 ) == false )
		{
			return;
		}

		// Main thread synchronizes the workers and does work itself.
		//
		// This needs to be a task for the main thread because the user's task system may execute
		// the tasks serially and this is the first task. This single task is able to fully
		// complete all work even if all other workers are blocked.

		// Stages are re-used by loops so that I don't need more stages for large substep counts.
		// The sync indices grow monotonically for the body/graph/constraint groupings because they share solver blocks.
		// The stage index and sync indices are combined in to sync bits for atomic synchronization.
		// The workers need to compute the previous sync index for a given stage so that CAS works correctly. This
		// setup makes this easy to do.

		/*
		b3_stagePrepareJoints,
		b3_stagePrepareContacts,
		b3_stageIntegrateVelocities,
		b3_stageWarmStart,
		b3_stageSolve,
		b3_stageIntegratePositions,
		b3_stageRelax,
		b3_stageRestitution,
		b3_stageStoreImpulses
		*/

		uint64_t ticks = b3GetTicks();

		int bodySyncIndex = 1;
		int stageIndex = 0;

		// Prepare joint constraints
		uint32_t jointSyncIndex = 1;
		uint32_t syncBits = ( jointSyncIndex << 16 ) | stageIndex;
		B3_ASSERT( stages[stageIndex].type == b3_stagePrepareJoints );
		b3ExecuteMainStage( stages + stageIndex, context, syncBits );
		stageIndex += 1;
		jointSyncIndex += 1;

		// Prepare convex contact constraints
		uint32_t convexSyncIndex = 1;
		syncBits = ( convexSyncIndex << 16 ) | stageIndex;
		B3_ASSERT( stages[stageIndex].type == b3_stagePrepareWideContacts );
		b3ExecuteMainStage( stages + stageIndex, context, syncBits );
		stageIndex += 1;
		convexSyncIndex += 1;

		// Prepare mesh contact constraints
		uint32_t meshSyncIndex = 1;
		syncBits = ( meshSyncIndex << 16 ) | stageIndex;
		B3_ASSERT( stages[stageIndex].type == b3_stagePrepareContacts );
		b3ExecuteMainStage( stages + stageIndex, context, syncBits );
		stageIndex += 1;
		meshSyncIndex += 1;

		// Single-threaded overflow work. These constraints don't fit in the graph coloring.
		b3PrepareJoints_Overflow( context );
		b3PrepareContacts_Overflow( context );

		profile->prepareConstraints += b3GetMillisecondsAndReset( &ticks );

		int graphSyncIndex = 1;
		int subStepCount = context->subStepCount;
		for ( int subStepIndex = 0; subStepIndex < subStepCount; ++subStepIndex )
		{
			// stageIndex restarted each iteration
			// syncBits still increases monotonically because the upper bits increase each iteration
			int iterationStageIndex = stageIndex;

			// Integrate velocities
			syncBits = ( bodySyncIndex << 16 ) | iterationStageIndex;
			B3_ASSERT( stages[iterationStageIndex].type == b3_stageIntegrateVelocities );
			b3ExecuteMainStage( stages + iterationStageIndex, context, syncBits );
			iterationStageIndex += 1;
			bodySyncIndex += 1;

			profile->integrateVelocities += b3GetMillisecondsAndReset( &ticks );

			// Warm start constraints
			b3WarmStartJoints_Overflow( context );
			b3WarmStartContacts_Overflow( context );

			for ( int colorIndex = 0; colorIndex < activeColorCount; ++colorIndex )
			{
				syncBits = ( graphSyncIndex << 16 ) | iterationStageIndex;
				B3_ASSERT( stages[iterationStageIndex].type == b3_stageWarmStart );
				b3ExecuteMainStage( stages + iterationStageIndex, context, syncBits );
				iterationStageIndex += 1;
			}
			graphSyncIndex += 1;

			profile->warmStart += b3GetMillisecondsAndReset( &ticks );

			// Solve constraints
			bool useBias = true;
			for ( int j = 0; j < ITERATIONS; ++j )
			{
				// Overflow constraints have lower priority. Typically these are dynamic-vs-dynamic.
				b3SolveJoints_Overflow( context, useBias );
				b3SolveContacts_Overflow( context, useBias );

				for ( int colorIndex = 0; colorIndex < activeColorCount; ++colorIndex )
				{
					syncBits = ( graphSyncIndex << 16 ) | iterationStageIndex;
					B3_ASSERT( stages[iterationStageIndex].type == b3_stageSolve );
					b3ExecuteMainStage( stages + iterationStageIndex, context, syncBits );
					iterationStageIndex += 1;
				}
				graphSyncIndex += 1;
			}

			profile->solveImpulses += b3GetMillisecondsAndReset( &ticks );

			// Integrate positions
			B3_ASSERT( stages[iterationStageIndex].type == b3_stageIntegratePositions );
			syncBits = ( bodySyncIndex << 16 ) | iterationStageIndex;
			b3ExecuteMainStage( stages + iterationStageIndex, context, syncBits );
			iterationStageIndex += 1;
			bodySyncIndex += 1;

			profile->integratePositions += b3GetMillisecondsAndReset( &ticks );

			// Relax constraints
			useBias = false;
			for ( int j = 0; j < RELAX_ITERATIONS; ++j )
			{
				b3SolveJoints_Overflow( context, useBias );
				b3SolveContacts_Overflow( context, useBias );

				for ( int colorIndex = 0; colorIndex < activeColorCount; ++colorIndex )
				{
					syncBits = ( graphSyncIndex << 16 ) | iterationStageIndex;
					B3_ASSERT( stages[iterationStageIndex].type == b3_stageRelax );
					b3ExecuteMainStage( stages + iterationStageIndex, context, syncBits );
					iterationStageIndex += 1;
				}
				graphSyncIndex += 1;
			}

			profile->relaxImpulses += b3GetMillisecondsAndReset( &ticks );
		}

		// Advance the stage according to the sub-stepping tasks just completed
		// integrate velocities / warm start / solve / integrate positions / relax
		stageIndex += 1 + activeColorCount + ITERATIONS * activeColorCount + 1 + RELAX_ITERATIONS * activeColorCount;

		// Restitution
		{
			b3ApplyRestitution_Overflow( context );

			int iterStageIndex = stageIndex;
			for ( int colorIndex = 0; colorIndex < activeColorCount; ++colorIndex )
			{
				syncBits = ( graphSyncIndex << 16 ) | iterStageIndex;
				B3_ASSERT( stages[iterStageIndex].type == b3_stageRestitution );
				b3ExecuteMainStage( stages + iterStageIndex, context, syncBits );
				iterStageIndex += 1;
			}
			// graphSyncIndex += 1;
			stageIndex += activeColorCount;
		}

		profile->applyRestitution += b3GetMillisecondsAndReset( &ticks );

		// Store impulses
		b3StoreImpulses_Overflow( context );

		syncBits = ( convexSyncIndex << 16 ) | stageIndex;
		B3_ASSERT( stages[stageIndex].type == b3_stageStoreWideImpulses );
		b3ExecuteMainStage( stages + stageIndex, context, syncBits );
		stageIndex += 1;

		syncBits = ( meshSyncIndex << 16 ) | stageIndex;
		B3_ASSERT( stages[stageIndex].type == b3_stageStoreImpulses );
		b3ExecuteMainStage( stages + stageIndex, context, syncBits );
		stageIndex += 1;

		profile->storeImpulses += b3GetMillisecondsAndReset( &ticks );

		// Signal workers to finish
		b3AtomicStoreU32( &context->atomicSyncBits, UINT_MAX );

		B3_ASSERT( stageIndex == context->stageCount );
		return;
	}

	// Worker spins and waits for work
	uint32_t lastSyncBits = 0;
	// uint64_t maxSpinTime = 10;
	while ( true )
	{
		// Spin until main thread bumps changes the sync bits. This can waste significant time overall, but it is necessary for
		// parallel simulation with graph coloring.
		// todo improve this spinner
		uint32_t syncBits;
		int spinCount = 0;
		while ( ( syncBits = b3AtomicLoadU32( &context->atomicSyncBits ) ) == lastSyncBits )
		{
			if ( spinCount > 5 )
			{
				b3Yield();
				spinCount = 0;
			}
			else
			{
				// Using the cycle counter helps to account for variation in mm_pause timing across different
				// CPUs. However, this is X64 only.
				// uint64_t prev = __rdtsc();
				// do
				//{
				//	b3Pause();
				//}
				// while ((__rdtsc() - prev) < maxSpinTime);
				// maxSpinTime += 10;
				b3Pause();
				b3Pause();
				spinCount += 1;
			}
		}

		if ( syncBits == UINT_MAX )
		{
			// sentinel hit
			break;
		}

		int stageIndex = syncBits & 0xFFFF;
		B3_ASSERT( stageIndex < context->stageCount );

		int syncIndex = ( syncBits >> 16 ) & 0xFFFF;
		B3_ASSERT( syncIndex > 0 );

		int previousSyncIndex = syncIndex - 1;

		b3SolverStage* stage = stages + stageIndex;
		b3ExecuteStage( stage, context, previousSyncIndex, syncIndex, workerIndex );

		lastSyncBits = syncBits;
	}
}

static void b3BulletBodyTask( int startIndex, int endIndex, int workerIndex, void* context )
{
	b3TracyCZoneNC( bullet_body_task, "Bullet Body Task", b3_colorLightSkyBlue, true );

	b3StepContext* stepContext = (b3StepContext*)context;
	b3TaskContext* taskContext = b3Array_Get( stepContext->world->taskContexts, workerIndex );

	B3_ASSERT( startIndex <= endIndex );

	for ( int i = startIndex; i < endIndex; ++i )
	{
		int simIndex = stepContext->bulletBodies[i];
		b3SolveContinuous( stepContext->world, simIndex, taskContext );
	}

	b3TracyCZoneEnd( bullet_body_task );
}

#if B3_SIMD_WIDTH == 4
#define B3_SIMD_SHIFT 2
#else
#define B3_SIMD_SHIFT 0
#endif

// Solve with graph coloring
void b3Solve( b3World* world, b3StepContext* stepContext )
{
	// Only count steps that advance the simulation
	world->stepIndex += 1;

	b3SolverSet* awakeSet = b3Array_Get( world->solverSets, b3_awakeSet );
	int awakeBodyCount = awakeSet->bodySims.count;
	if ( awakeBodyCount == 0 )
	{
		b3ValidateNoEnlarged( &world->broadPhase );
		return;
	}

	// Solve constraints using graph coloring
	{
		b3TracyCZoneNC( solver_setup, "Solver Setup", b3_colorDarkOrange, true );
		uint64_t setupTicks = b3GetTicks();

		// Prepare buffers for continuous collision (fast bodies)
		b3AtomicStoreInt( &stepContext->bulletBodyCount, 0 );
		stepContext->bulletBodies = (int*)b3StackAlloc( &world->stack, awakeBodyCount * sizeof( int ), "bullet bodies" );

		b3ConstraintGraph* graph = &world->constraintGraph;
		b3GraphColor* colors = graph->colors;

		stepContext->sims = awakeSet->bodySims.data;
		stepContext->states = awakeSet->bodyStates.data;

		// count contacts, joints, and colors
		int activeColorCount = 0;
		for ( int i = 0; i < B3_GRAPH_COLOR_COUNT - 1; ++i )
		{
			int perColorContactCount = colors[i].convexContacts.count + colors[i].contacts.count;
			int perColorJointCount = colors[i].jointSims.count;
			int occupancyCount = perColorContactCount + perColorJointCount;
			activeColorCount += occupancyCount > 0 ? 1 : 0;
		}

		// prepare for move events
		b3Array_Resize( world->bodyMoveEvents, awakeBodyCount );

		int workerCount = world->workerCount;

		// Target 4 blocks per worker to allow work stealing
		const int maxBlockCount = 4 * workerCount;

		// Body blocks are for parallel iteration over bodies directly (integration, update transforms)
		int minBodiesPerBlock = 32;
		b3BlockDim bodyDim = b3ComputeBlockCount( awakeBodyCount, minBodiesPerBlock, maxBlockCount );

		const int minContactsPerBlock = 4;
		const int minJointsPerBlock = 4;

		// Configure blocks for tasks parallel-for each active graph color
		// The blocks are a mix of convex contact, mesh contact, and joint blocks
		int activeColorIndices[B3_GRAPH_COLOR_COUNT];
		int colorWideContactCounts[B3_GRAPH_COLOR_COUNT];
		int colorContactCounts[B3_GRAPH_COLOR_COUNT];
		// int colorManifoldCounts[B3_GRAPH_COLOR_COUNT];
		int colorJointCounts[B3_GRAPH_COLOR_COUNT];
		b3BlockDim graphWideContactDims[B3_GRAPH_COLOR_COUNT];
		b3BlockDim graphContactDims[B3_GRAPH_COLOR_COUNT];
		b3BlockDim graphJointDims[B3_GRAPH_COLOR_COUNT];
		int graphBlockCount = 0;

		// c is the active color index
		int wideContactCount = 0;
		int contactCount = 0;
		int manifoldCount = 0;
		int jointCount = 0;
		int c = 0;
		for ( int i = 0; i < B3_GRAPH_COLOR_COUNT - 1; ++i )
		{
			b3GraphColor* color = colors + i;
			int colorConvexContactCount = color->convexContacts.count;
			int colorContactCount = color->contacts.count;
			int colorJointCount = color->jointSims.count;

			if ( colorConvexContactCount + colorContactCount + colorJointCount == 0 )
			{
				continue;
			}

			activeColorIndices[c] = i;

			// Ceiling for wide constraint count
			int colorWideConstraintCount =
				colorConvexContactCount > 0 ? ( ( colorConvexContactCount - 1 ) >> B3_SIMD_SHIFT ) + 1 : 0;
			wideContactCount += colorWideConstraintCount;
			colorWideContactCounts[c] = colorWideConstraintCount;

			colorContactCounts[c] = colorContactCount;
			contactCount += colorContactCount;

			// Compute manifold starts and accumulate manifold count
			for ( int j = 0; j < colorContactCount; ++j )
			{
				color->contacts.data[j].manifoldStart = manifoldCount;
				manifoldCount += color->contacts.data[j].manifoldCount;
			}

			colorJointCounts[c] = colorJointCount;
			jointCount += colorJointCount;

			// Solver block dimensions
			graphWideContactDims[c] = b3ComputeBlockCount( colorWideConstraintCount, minContactsPerBlock, maxBlockCount );
			graphContactDims[c] = b3ComputeBlockCount( colorContactCount, minContactsPerBlock, maxBlockCount );
			graphJointDims[c] = b3ComputeBlockCount( colorJointCount, minJointsPerBlock, maxBlockCount );
			graphBlockCount += graphWideContactDims[c].count + graphContactDims[c].count + graphJointDims[c].count;

			c += 1;
		}
		activeColorCount = c;

		// Prepare and store run as one flat parallel-for over the entire wide constraint range,
		// partitioned into uniformly sized blocks. Color info is consulted inside the task via
		// a small span array, so blocks do not need to honor color boundaries here.
		b3BlockDim convexPrepareDim = b3ComputeBlockCount( wideContactCount, minContactsPerBlock, maxBlockCount );
		b3BlockDim meshPrepareDim = b3ComputeBlockCount( contactCount, minContactsPerBlock, maxBlockCount );
		b3BlockDim jointPrepareDim = b3ComputeBlockCount( jointCount, minJointsPerBlock, maxBlockCount );

		int wideContactByteCount = b3GetWideContactConstraintByteCount();
		b3ContactConstraintWide* wideConstraints =
			(b3ContactConstraintWide*)b3StackAlloc( &world->stack, wideContactCount * wideContactByteCount, "wide contacts" );
		b3ContactConstraint* contactConstraints =
			(b3ContactConstraint*)b3StackAlloc( &world->stack, contactCount * sizeof( b3ContactConstraint ), "contacts" );
		b3ManifoldConstraint* manifoldConstraints = (b3ManifoldConstraint*)b3StackAlloc(
			&world->stack, manifoldCount * sizeof( b3ManifoldConstraint ), "manifold constraints" );

		b3GraphColor* overflow = colors + B3_OVERFLOW_INDEX;
		int overflowCount = overflow->contacts.count;
		int overflowManifoldCount = 0;
		for ( int i = 0; i < overflowCount; ++i )
		{
			overflow->contacts.data[i].manifoldStart = overflowManifoldCount;
			overflowManifoldCount += overflow->contacts.data[i].manifoldCount;
		}

		overflow->contactConstraints = (b3ContactConstraint*)b3StackAlloc(
			&world->stack, overflowCount * sizeof( b3ContactConstraint ), "overflow contacts" );
		overflow->manifoldConstraints = (b3ManifoldConstraint*)b3StackAlloc(
			&world->stack, overflowManifoldCount * sizeof( b3ManifoldConstraint ), "overflow manifolds" );

		// Build the span table for the flat prepare/store parallel-for while I slice the
		// wide constraint buffer across colors. One entry per active color plus a sentinel
		// at wideContactCount.
		b3WidePrepareSpan widePrepareSpans[B3_GRAPH_COLOR_COUNT + 1];
		b3ContactPrepareSpan contactPrepareSpans[B3_GRAPH_COLOR_COUNT + 1];
		b3JointPrepareSpan jointPrepareSpans[B3_GRAPH_COLOR_COUNT + 1];

		// Distribute transient constraints to each graph color and prepare spans
		// todo it might be simpler for solver blocks to index into the global arrays
		{
			int wideBase = 0;
			int contactBase = 0;
			int jointBase = 0;
			for ( int i = 0; i < activeColorCount; ++i )
			{
				int j = activeColorIndices[i];
				b3GraphColor* color = colors + j;

				int colorConvexContactCount = color->convexContacts.count;
				widePrepareSpans[i].start = wideBase;
				widePrepareSpans[i].count = colorConvexContactCount;
				widePrepareSpans[i].contacts = color->convexContacts.data;

				if ( colorConvexContactCount == 0 )
				{
					color->wideConstraints = NULL;
					color->wideConstraintCount = 0;
				}
				else
				{
					color->wideConstraints =
						(b3ContactConstraintWide*)( (uint8_t*)wideConstraints + wideBase * wideContactByteCount );

					int colorContactCountW = ( ( colorConvexContactCount - 1 ) >> B3_SIMD_SHIFT ) + 1;
					color->wideConstraintCount = colorContactCountW;

					// Zero remainder lanes in the tail wide slot so prepare workers don't need to
					// initialize them.
					if ( ( colorConvexContactCount & ( B3_SIMD_WIDTH - 1 ) ) != 0 )
					{
						memset( (uint8_t*)color->wideConstraints + ( colorContactCountW - 1 ) * wideContactByteCount, 0,
								wideContactByteCount );
					}

					wideBase += colorContactCountW;
				}

				int colorContactCount = color->contacts.count;
				contactPrepareSpans[i].start = contactBase;
				contactPrepareSpans[i].count = colorContactCount;
				contactPrepareSpans[i].contacts = color->contacts.data;

				if ( colorContactCount == 0 )
				{
					color->contactConstraints = NULL;
					color->contactConstraintCount = 0;
				}
				else
				{
					color->contactConstraints = contactConstraints + contactBase;
					color->contactConstraintCount = colorContactCount;
					contactBase += colorContactCount;
				}

				jointPrepareSpans[i].start = jointBase;
				jointPrepareSpans[i].count = color->jointSims.count;
				jointPrepareSpans[i].joints = color->jointSims.data;
				jointBase += color->jointSims.count;
			}

			// Sentinels
			widePrepareSpans[activeColorCount].start = wideContactCount;
			widePrepareSpans[activeColorCount].count = 0;
			widePrepareSpans[activeColorCount].contacts = NULL;
			B3_ASSERT( wideBase == wideContactCount );

			contactPrepareSpans[activeColorCount].start = contactCount;
			contactPrepareSpans[activeColorCount].count = 0;
			contactPrepareSpans[activeColorCount].contacts = NULL;
			B3_ASSERT( contactBase == contactCount );

			jointPrepareSpans[activeColorCount].start = jointCount;
			jointPrepareSpans[activeColorCount].count = 0;
			jointPrepareSpans[activeColorCount].joints = NULL;
			B3_ASSERT( jointBase == jointCount );
		}

		//// Special span for overflow to allow for function re-use
		b3ContactPrepareSpan overflowSpans[2] = { 0 };
		overflowSpans[0].start = 0;
		overflowSpans[0].count = overflow->contacts.count;
		overflowSpans[0].contacts = overflow->contacts.data;
		overflowSpans[1].start = overflow->contacts.count;
		overflowSpans[1].count = 0;
		overflowSpans[1].contacts = NULL;

		int stageCount = 0;

		// b3_stagePrepareJoints
		stageCount += 1;
		// b3_stagePrepareWideContacts
		stageCount += 1;
		// b3_stagePrepareContacts
		stageCount += 1;
		// b3_stageIntegrateVelocities
		stageCount += 1;
		// b3_stageWarmStart
		stageCount += activeColorCount;
		// b3_stageSolve
		stageCount += ITERATIONS * activeColorCount;
		// b3_stageIntegratePositions
		stageCount += 1;
		// b3_stageRelax
		stageCount += RELAX_ITERATIONS * activeColorCount;
		// b3_stageRestitution
		stageCount += activeColorCount;
		// b3_stageStoreWideImpulses
		stageCount += 1;
		// b3_stageStoreImpulses
		stageCount += 1;

		b3SolverStage* stages = (b3SolverStage*)b3StackAlloc( &world->stack, stageCount * sizeof( b3SolverStage ), "stages" );
		b3SyncBlock* bodyBlocks =
			(b3SyncBlock*)b3StackAlloc( &world->stack, bodyDim.count * sizeof( b3SyncBlock ), "body blocks" );
		b3SyncBlock* convexBlocks =
			(b3SyncBlock*)b3StackAlloc( &world->stack, convexPrepareDim.count * sizeof( b3SyncBlock ), "convex blocks" );
		b3SyncBlock* meshBlocks =
			(b3SyncBlock*)b3StackAlloc( &world->stack, meshPrepareDim.count * sizeof( b3SyncBlock ), "mesh blocks" );
		b3SyncBlock* jointBlocks =
			(b3SyncBlock*)b3StackAlloc( &world->stack, jointPrepareDim.count * sizeof( b3SyncBlock ), "joint blocks" );
		b3SyncBlock* graphBlocks =
			(b3SyncBlock*)b3StackAlloc( &world->stack, graphBlockCount * sizeof( b3SyncBlock ), "graph blocks" );

		// Split an awake island. This modifies:
		// - stack allocator
		// - world island array and solver set
		// - island indices on bodies, contacts, and joints
		// I'm squeezing this task in here because it may be expensive and this is a safe place to put it.
		// Note: cannot split islands in parallel with FinalizeBodies
		void* splitIslandTask = NULL;
		if ( world->splitIslandId != B3_NULL_INDEX )
		{
			if ( world->taskCount < B3_MAX_TASKS )
			{
				splitIslandTask = world->enqueueTaskFcn( &b3SplitIslandTask, world, world->userTaskContext, "split" );
				world->taskCount += 1;
				world->activeTaskCount += splitIslandTask == NULL ? 0 : 1;
			}
			else
			{
				b3SplitIslandTask( world );
			}
		}

		// Prepare body blocks
		b3InitBlocks( bodyBlocks, bodyDim, awakeBodyCount, b3_bodyBlock, UINT8_MAX );

		// Prepare blocks as a single flat parallel-for over the whole constraint range.
		// The task walks spans to decode flat slot indices back to per-color arrays.
		b3InitBlocks( convexBlocks, convexPrepareDim, wideContactCount, b3_wideContactBlock, UINT8_MAX );
		b3InitBlocks( meshBlocks, meshPrepareDim, contactCount, b3_contactBlock, UINT8_MAX );
		b3InitBlocks( jointBlocks, jointPrepareDim, jointCount, b3_jointBlock, UINT8_MAX );

		// Prepare graph work blocks. Each color gets joint blocks followed by contact blocks.
		b3SyncBlock* graphColorBlocks[B3_GRAPH_COLOR_COUNT] = { 0 };
		b3SyncBlock* baseGraphBlock = graphBlocks;
		int graphBlockCounts[B3_GRAPH_COLOR_COUNT] = { 0 };
		for ( int i = 0; i < activeColorCount; ++i )
		{
			graphColorBlocks[i] = baseGraphBlock;

			uint8_t colorIndex = (uint8_t)activeColorIndices[i];
			b3InitBlocks( baseGraphBlock, graphJointDims[i], colorJointCounts[i], b3_graphJointBlock, colorIndex );
			baseGraphBlock += graphJointDims[i].count;

			b3InitBlocks( baseGraphBlock, graphWideContactDims[i], colorWideContactCounts[i], b3_graphWideContactBlock,
						  colorIndex );
			baseGraphBlock += graphWideContactDims[i].count;

			b3InitBlocks( baseGraphBlock, graphContactDims[i], colorContactCounts[i], b3_graphContactBlock, colorIndex );
			baseGraphBlock += graphContactDims[i].count;

			graphBlockCounts[i] = graphJointDims[i].count + graphWideContactDims[i].count + graphContactDims[i].count;
		}

		B3_ASSERT( (ptrdiff_t)( baseGraphBlock - graphBlocks ) == graphBlockCount );

		b3SolverStage* stage = stages;
		stage = b3InitStage( stage, b3_stagePrepareJoints, jointBlocks, jointPrepareDim.count, UINT8_MAX );
		stage = b3InitStage( stage, b3_stagePrepareWideContacts, convexBlocks, convexPrepareDim.count, UINT8_MAX );
		stage = b3InitStage( stage, b3_stagePrepareContacts, meshBlocks, meshPrepareDim.count, UINT8_MAX );
		stage = b3InitStage( stage, b3_stageIntegrateVelocities, bodyBlocks, bodyDim.count, UINT8_MAX );
		stage = b3InitColorStages( stage, b3_stageWarmStart, 1, activeColorCount, graphColorBlocks, graphBlockCounts,
								   activeColorIndices );
		stage = b3InitColorStages( stage, b3_stageSolve, ITERATIONS, activeColorCount, graphColorBlocks, graphBlockCounts,
								   activeColorIndices );
		stage = b3InitStage( stage, b3_stageIntegratePositions, bodyBlocks, bodyDim.count, UINT8_MAX );
		stage = b3InitColorStages( stage, b3_stageRelax, RELAX_ITERATIONS, activeColorCount, graphColorBlocks, graphBlockCounts,
								   activeColorIndices );
		// Note: joint blocks mixed in, could have joint limit restitution
		stage = b3InitColorStages( stage, b3_stageRestitution, 1, activeColorCount, graphColorBlocks, graphBlockCounts,
								   activeColorIndices );
		stage = b3InitStage( stage, b3_stageStoreWideImpulses, convexBlocks, convexPrepareDim.count, UINT8_MAX );
		stage = b3InitStage( stage, b3_stageStoreImpulses, meshBlocks, meshPrepareDim.count, UINT8_MAX );

		B3_ASSERT( (int)( stage - stages ) == stageCount );

		B3_ASSERT( workerCount <= B3_MAX_WORKERS );
		b3WorkerContext workerContext[B3_MAX_WORKERS];

		stepContext->graph = graph;
		stepContext->activeColorCount = activeColorCount;
		stepContext->workerCount = workerCount;
		stepContext->stageCount = stageCount;
		stepContext->stages = stages;
		stepContext->wideConstraints = wideConstraints;
		stepContext->widePrepareSpans = widePrepareSpans;
		stepContext->wideContactCount = wideContactCount;
		stepContext->manifoldConstraints = manifoldConstraints;
		stepContext->contactConstraints = contactConstraints;
		stepContext->contactPrepareSpans = contactPrepareSpans;
		stepContext->overflowSpans = overflowSpans;
		stepContext->jointPrepareSpans = jointPrepareSpans;
		b3AtomicStoreU32( &stepContext->atomicSyncBits, 0 );
		b3AtomicStoreInt( &stepContext->mainClaimed, 0 );

		world->profile.solverSetup = b3GetMillisecondsAndReset( &setupTicks );
		b3TracyCZoneEnd( solver_setup );

		b3TracyCZoneNC( solve_constraints, "Solve Constraints", b3_colorIndigo, true );
		uint64_t constraintTicks = b3GetTicks();

		int jointIdCapacity = b3GetIdCapacity( &world->jointIdPool );
		int contactIdCapacity = b3GetIdCapacity( &world->contactIdPool );
		for ( int i = 0; i < workerCount; ++i )
		{
			b3TaskContext* taskContext = b3Array_Get( world->taskContexts, i );
			b3SetBitCountAndClear( &taskContext->jointStateBitSet, jointIdCapacity );
			b3SetBitCountAndClear( &taskContext->hitEventBitSet, contactIdCapacity );
			taskContext->hasHitEvents = false;

			workerContext[i].context = stepContext;
			workerContext[i].workerIndex = i;

			if ( world->taskCount < B3_MAX_TASKS )
			{
				char buffer[16];
				snprintf( buffer, sizeof( buffer ), "solve[%d]", i );
				workerContext[i].userTask =
					world->enqueueTaskFcn( &b3SolverTask, workerContext + i, world->userTaskContext, buffer );
				world->taskCount += 1;
				world->activeTaskCount += workerContext[i].userTask == NULL ? 0 : 1;
			}
			else
			{
				workerContext[i].userTask = NULL;
				b3SolverTask( workerContext + i );
			}
		}

		// The calling thread of b3World_Step also enters b3SolverTask as worker 0 and races for the
		// orchestrator slot via the CAS inside. This guarantees progress even when the user's task
		// system can't run the queued worker 0 promptly: it might schedule out of order, have fewer
		// threads than workerCount, or invert priority by parking the calling thread in finishTaskFcn.
		// Whoever wins the CAS becomes the orchestrator; the loser returns and lets the spinner-only
		// path handle workers >0.
		b3WorkerContext callerContext = { stepContext, 0, NULL };
		b3SolverTask( &callerContext );

		// Finish constraint solve
		for ( int i = 0; i < workerCount; ++i )
		{
			if ( workerContext[i].userTask != NULL )
			{
				world->finishTaskFcn( workerContext[i].userTask, world->userTaskContext );
				world->activeTaskCount -= 1;
			}
		}

		// Finish island split
		if ( splitIslandTask != NULL )
		{
			world->finishTaskFcn( splitIslandTask, world->userTaskContext );
			world->activeTaskCount -= 1;
		}
		world->splitIslandId = B3_NULL_INDEX;

		world->profile.constraints = b3GetMillisecondsAndReset( &constraintTicks );
		b3TracyCZoneEnd( solve_constraints );

		b3TracyCZoneNC( update_transforms, "Update Transforms", b3_colorMediumSeaGreen, true );
		uint64_t transformTicks = b3GetTicks();

		// Prepare contact, enlarged body, and island bit sets used in body finalization.
		int awakeIslandCount = awakeSet->islandSims.count;
		for ( int i = 0; i < world->workerCount; ++i )
		{
			b3TaskContext* taskContext = world->taskContexts.data + i;
			b3Array_Clear( taskContext->sensorHits );
			b3SetBitCountAndClear( &taskContext->enlargedSimBitSet, awakeBodyCount );
			b3SetBitCountAndClear( &taskContext->awakeIslandBitSet, awakeIslandCount );
			taskContext->splitIslandId = B3_NULL_INDEX;
			taskContext->splitSleepTime = 0.0f;
		}

		// Finalize bodies. Must happen after the constraint solver and after island splitting.
		b3ParallelFor( world, &b3FinalizeBodiesTask, awakeBodyCount, 16, stepContext, "ccd" );

		// Free in reverse order
		b3StackFree( &world->stack, graphBlocks );
		b3StackFree( &world->stack, jointBlocks );
		b3StackFree( &world->stack, meshBlocks );
		b3StackFree( &world->stack, convexBlocks );
		b3StackFree( &world->stack, bodyBlocks );
		b3StackFree( &world->stack, stages );
		b3StackFree( &world->stack, overflow->manifoldConstraints );
		b3StackFree( &world->stack, overflow->contactConstraints );
		b3StackFree( &world->stack, manifoldConstraints );
		b3StackFree( &world->stack, contactConstraints );
		b3StackFree( &world->stack, wideConstraints );

		world->profile.transforms = b3GetMilliseconds( transformTicks );
		b3TracyCZoneEnd( update_transforms );
	}

	// Report joint events
	{
		b3TracyCZoneNC( joint_events, "Joint Events", b3_colorPeru, true );
		uint64_t jointEventTicks = b3GetTicks();

		// Gather bits for all joints that have force/torque events
		b3BitSet* jointStateBitSet = &world->taskContexts.data[0].jointStateBitSet;
		for ( int i = 1; i < world->workerCount; ++i )
		{
			b3InPlaceUnion( jointStateBitSet, &world->taskContexts.data[i].jointStateBitSet );
		}

		{
			uint32_t wordCount = jointStateBitSet->blockCount;
			uint64_t* bits = jointStateBitSet->bits;

			b3Joint* jointArray = world->joints.data;
			uint16_t worldIndex0 = world->worldId;

			for ( uint32_t k = 0; k < wordCount; ++k )
			{
				uint64_t word = bits[k];
				while ( word != 0 )
				{
					uint32_t ctz = b3CTZ64( word );
					int jointId = (int)( 64 * k + ctz );

					B3_ASSERT( jointId < world->joints.capacity );

					b3Joint* joint = jointArray + jointId;

					B3_ASSERT( joint->setIndex == b3_awakeSet );

					b3JointEvent event = {
						.jointId =
							{
								.index1 = jointId + 1,
								.world0 = worldIndex0,
								.generation = joint->generation,
							},
						.userData = joint->userData,
					};

					b3Array_Push( world->jointEvents, event );

					// Clear the smallest set bit
					word = word & ( word - 1 );
				}
			}
		}

		world->profile.jointEvents = b3GetMilliseconds( jointEventTicks );
		b3TracyCZoneEnd( joint_events );
	}

	// Report hit events
	{
		b3TracyCZoneNC( hit_events, "Hit Events", b3_colorRosyBrown, true );
		uint64_t hitTicks = b3GetTicks();

		B3_ASSERT( world->contactHitEvents.count == 0 );

		// Fast path: if no worker flagged any hit-event candidates during b2StoreImpulsesTask, skip entirely.
		bool anyHitEvents = false;
		for ( int i = 0; i < world->workerCount; ++i )
		{
			if ( world->taskContexts.data[i].hasHitEvents )
			{
				anyHitEvents = true;
				break;
			}
		}

		if ( anyHitEvents )
		{
			// Union per-worker bits into worker 0's bit set.
			b3BitSet* hitEventBitSet = &world->taskContexts.data[0].hitEventBitSet;
			for ( int i = 1; i < world->workerCount; ++i )
			{
				if ( world->taskContexts.data[i].hasHitEvents )
				{
					b3InPlaceUnion( hitEventBitSet, &world->taskContexts.data[i].hitEventBitSet );
				}
			}

			float threshold = world->hitEventThreshold;
			b3Contact* contactArray = world->contacts.data;
			uint16_t worldId = world->worldId;

			uint32_t wordCount = hitEventBitSet->blockCount;
			uint64_t* bits = hitEventBitSet->bits;
			for ( uint32_t k = 0; k < wordCount; ++k )
			{
				uint64_t word = bits[k];
				while ( word != 0 )
				{
					uint32_t ctz = b3CTZ64( word );
					int contactId = (int)( 64 * k + ctz );

					b3Contact* contact = contactArray + contactId;
					B3_ASSERT( contact->setIndex == b3_awakeSet && contact->colorIndex != B3_NULL_INDEX );

					b3Shape* shapeA = b3Array_Get( world->shapes, contact->shapeIdA );
					b3Shape* shapeB = b3Array_Get( world->shapes, contact->shapeIdB );
					b3Body* bodyA = b3Array_Get( world->bodies, shapeA->bodyId );
					b3Body* bodyB = b3Array_Get( world->bodies, shapeB->bodyId );
					b3BodySim* simA = b3GetBodySim( world, bodyA );
					b3BodySim* simB = b3GetBodySim( world, bodyB );
					b3Pos midCenter = b3LerpPosition( simA->center, simB->center, 0.5f );

					b3ContactHitEvent event = { 0 };
					event.approachSpeed = threshold;

					bool found = false;
					int triangleIndex = 0;
					int manifoldCount = contact->manifoldCount;
					for ( int i = 0; i < manifoldCount; ++i )
					{
						b3Manifold* manifold = contact->manifolds + i;
						int pointCount = manifold->pointCount;
						for ( int p = 0; p < pointCount; ++p )
						{
							b3ManifoldPoint* mp = manifold->points + p;
							float approachSpeed = -mp->normalVelocity;

							// Need to check total impulse because the point may be speculative and not colliding
							if ( approachSpeed > event.approachSpeed && mp->totalNormalImpulse > 0.0f )
							{
								event.approachSpeed = approachSpeed;
								event.point = b3OffsetPos( midCenter, b3Lerp( mp->anchorA, mp->anchorB, 0.5f ) );
								event.normal = manifold->normal;
								triangleIndex = mp->triangleIndex;
								found = true;
							}
						}
					}

					if ( found == true )
					{
						event.shapeIdA = (b3ShapeId){ shapeA->id + 1, worldId, shapeA->generation };
						event.shapeIdB = (b3ShapeId){ shapeB->id + 1, worldId, shapeB->generation };

						event.contactId = (b3ContactId){
							.index1 = contact->contactId + 1,
							.world0 = worldId,
							.padding = 0,
							.generation = contact->generation,
						};

						// shapeB is never a compound today (asserted in b3CreateContact), so the
						// childIndex argument is irrelevant for it. shapeA carries the compound.
						event.userMaterialIdA = b3GetShapeUserMaterialId( shapeA, contact->childIndex, triangleIndex );
						event.userMaterialIdB = b3GetShapeUserMaterialId( shapeB, 0, triangleIndex );

						b3Array_Push( world->contactHitEvents, event );
					}

					// Clear the smallest set bit
					word = word & ( word - 1 );
				}
			}
		}

		world->profile.hitEvents = b3GetMilliseconds( hitTicks );
		b3TracyCZoneEnd( hit_events );
	}

	{
		b3TracyCZoneNC( refit_bvh, "Refit BVH", b3_colorFireBrick, true );
		uint64_t refitTicks = b3GetTicks();

		// Finish the user tree task that was queued earlier in the time step. This must be complete before touching the
		// broad-phase.
		if ( world->userTreeTask != NULL )
		{
			world->finishTaskFcn( world->userTreeTask, world->userTaskContext );
			world->userTreeTask = NULL;
			world->activeTaskCount -= 1;
		}

		b3ValidateNoEnlarged( &world->broadPhase );

		// Gather bits for all sim bodies that have enlarged AABBs
		b3BitSet* enlargedBodyBitSet = &world->taskContexts.data[0].enlargedSimBitSet;
		for ( int i = 1; i < world->workerCount; ++i )
		{
			b3InPlaceUnion( enlargedBodyBitSet, &world->taskContexts.data[i].enlargedSimBitSet );
		}

		// Enlarge broad-phase proxies and build move array
		// Apply shape AABB changes to broad-phase. This also create the move array which must be
		// in deterministic order. I'm tracking sim bodies because the number of shape ids can be huge.
		// This has to happen before bullets are processed.
		{
			b3BroadPhase* broadPhase = &world->broadPhase;
			uint32_t wordCount = enlargedBodyBitSet->blockCount;
			uint64_t* bits = enlargedBodyBitSet->bits;

			// Fast array access is important here
			b3Body* bodyArray = world->bodies.data;
			b3BodySim* bodySimArray = awakeSet->bodySims.data;
			b3Shape* shapeArray = world->shapes.data;

			for ( uint32_t k = 0; k < wordCount; ++k )
			{
				uint64_t word = bits[k];
				while ( word != 0 )
				{
					uint32_t ctz = b3CTZ64( word );
					uint32_t bodySimIndex = 64 * k + ctz;

					b3BodySim* bodySim = bodySimArray + bodySimIndex;

					b3Body* body = bodyArray + bodySim->bodyId;

					int shapeId = body->headShapeId;
					if ( ( bodySim->flags & ( b3_isBullet | b3_isFast ) ) == ( b3_isBullet | b3_isFast ) )
					{
						// Fast bullet bodies don't have their final AABB yet
						while ( shapeId != B3_NULL_INDEX )
						{
							b3Shape* shape = shapeArray + shapeId;

							// Shape is fast. It's aabb will be enlarged in continuous collision.
							// Update the move array here for determinism because bullets are processed
							// below in non-deterministic order.
							b3BufferMove( broadPhase, shape->proxyKey );

							shapeId = shape->nextShapeId;
						}
					}
					else
					{
						while ( shapeId != B3_NULL_INDEX )
						{
							b3Shape* shape = shapeArray + shapeId;

							// The AABB may not have been enlarged, despite the body being flagged as enlarged.
							// For example, a body with multiple shapes may have not have all shapes enlarged.
							// A fast body may have been flagged as enlarged despite having no shapes enlarged.
							if ( shape->flags & b3_enlargedAABB )
							{
								b3BroadPhase_EnlargeProxy( broadPhase, shape->proxyKey, shape->fatAABB );
								shape->flags &= ~b3_enlargedAABB;
							}

							shapeId = shape->nextShapeId;
						}
					}

					// Clear the smallest set bit
					word = word & ( word - 1 );
				}
			}
		}

		b3ValidateBroadPhase( &world->broadPhase );

		world->profile.refit = b3GetMilliseconds( refitTicks );
		b3TracyCZoneEnd( refit_bvh );
	}

	int bulletBodyCount = b3AtomicLoadInt( &stepContext->bulletBodyCount );
	if ( bulletBodyCount > 0 )
	{
		b3TracyCZoneNC( bullets, "Bullets", b3_colorDarkGoldenRod, true );
		uint64_t bulletTicks = b3GetTicks();

		// Fast bullet bodies
		// Note: a bullet body may be moving slow
		int minRange = 8;
		b3ParallelFor( world, &b3BulletBodyTask, bulletBodyCount, minRange, stepContext, "bullets" );

		// Serially enlarge broad-phase proxies for bullet shapes
		b3BroadPhase* broadPhase = &world->broadPhase;
		b3DynamicTree* dynamicTree = broadPhase->trees + b3_dynamicBody;

		// Fast array access is important here
		b3Body* bodyArray = world->bodies.data;
		b3BodySim* bodySimArray = awakeSet->bodySims.data;
		b3Shape* shapeArray = world->shapes.data;

		// Serially enlarge broad-phase proxies for bullet shapes
		int* bulletBodySimIndices = stepContext->bulletBodies;

		// This loop has non-deterministic order but it shouldn't affect the result
		for ( int i = 0; i < bulletBodyCount; ++i )
		{
			b3BodySim* bulletBodySim = bodySimArray + bulletBodySimIndices[i];
			if ( ( bulletBodySim->flags & b3_enlargeBounds ) == 0 )
			{
				continue;
			}

			// Clear flag
			bulletBodySim->flags &= ~b3_enlargeBounds;

			int bodyId = bulletBodySim->bodyId;
			B3_ASSERT( 0 <= bodyId && bodyId < world->bodies.count );
			b3Body* bulletBody = bodyArray + bodyId;

			int shapeId = bulletBody->headShapeId;
			while ( shapeId != B3_NULL_INDEX )
			{
				b3Shape* shape = shapeArray + shapeId;
				if ( ( shape->flags & b3_enlargedAABB ) == 0 )
				{
					shapeId = shape->nextShapeId;
					continue;
				}

				// clear flag
				shape->flags &= ~b3_enlargedAABB;

				int proxyKey = shape->proxyKey;
				int proxyId = B3_PROXY_ID( proxyKey );
				B3_ASSERT( B3_PROXY_TYPE( proxyKey ) == b3_dynamicBody );

				// all fast bullet shapes should already be in the move buffer
				B3_ASSERT( b3GetBit( &broadPhase->movedProxies[b3_dynamicBody], proxyId ) );

				b3DynamicTree_EnlargeProxy( dynamicTree, proxyId, shape->fatAABB );

				shapeId = shape->nextShapeId;
			}
		}

		world->profile.bullets = b3GetMilliseconds( bulletTicks );
		b3TracyCZoneEnd( bullets );
	}

	b3StackFree( &world->stack, stepContext->bulletBodies );
	stepContext->bulletBodies = NULL;
	b3AtomicStoreInt( &stepContext->bulletBodyCount, 0 );

	// Report sensor hits. This may include bullets sensor hits.
	{
		b3TracyCZoneNC( sensor_hits, "Sensor Hits", b3_colorPowderBlue, true );
		uint64_t sensorHitTicks = b3GetTicks();

		int workerCount = world->workerCount;
		B3_ASSERT( workerCount == world->taskContexts.count );

		for ( int i = 0; i < workerCount; ++i )
		{
			b3TaskContext* taskContext = world->taskContexts.data + i;
			int hitCount = taskContext->sensorHits.count;
			b3SensorHit* hits = taskContext->sensorHits.data;

			for ( int j = 0; j < hitCount; ++j )
			{
				b3SensorHit hit = hits[j];
				b3Shape* sensorShape = b3Array_Get( world->shapes, hit.sensorId );
				b3Shape* visitor = b3Array_Get( world->shapes, hit.visitorId );

				b3Sensor* sensor = b3Array_Get( world->sensors, sensorShape->sensorIndex );
				b3Visitor shapeRef = {
					.shapeId = hit.visitorId,
					.generation = visitor->generation,
				};
				b3Array_Push( sensor->hits, shapeRef );
			}
		}

		world->profile.sensorHits = b3GetMilliseconds( sensorHitTicks );
		b3TracyCZoneEnd( sensor_hits );
	}

	// Island sleeping
	// This must be done last because putting islands to sleep invalidates the enlarged body bits.
	// todo_erin figure out how to do this in parallel with tree refit
	if ( world->enableSleep == true )
	{
		b3TracyCZoneNC( sleep_islands, "Island Sleep", b3_colorLightSlateGray, true );
		uint64_t sleepTicks = b3GetTicks();

		// Collect split island candidate for the next time step. No need to split if sleeping is disabled.
		B3_ASSERT( world->splitIslandId == B3_NULL_INDEX );
		float splitSleepTimer = 0.0f;
		for ( int i = 0; i < world->workerCount; ++i )
		{
			b3TaskContext* taskContext = world->taskContexts.data + i;
			if ( taskContext->splitIslandId != B3_NULL_INDEX && taskContext->splitSleepTime >= splitSleepTimer )
			{
				B3_ASSERT( taskContext->splitSleepTime > 0.0f );

				// Tie breaking for determinism. Largest island id wins. Needed due to work stealing.
				if ( taskContext->splitSleepTime == splitSleepTimer && taskContext->splitIslandId < world->splitIslandId )
				{
					continue;
				}

				world->splitIslandId = taskContext->splitIslandId;
				splitSleepTimer = taskContext->splitSleepTime;
			}
		}

		b3BitSet* awakeIslandBitSet = &world->taskContexts.data[0].awakeIslandBitSet;
		for ( int i = 1; i < world->workerCount; ++i )
		{
			b3InPlaceUnion( awakeIslandBitSet, &world->taskContexts.data[i].awakeIslandBitSet );
		}

		// Need to process in reverse because this moves islands to sleeping solver sets.
		b3IslandSim* islands = awakeSet->islandSims.data;
		int count = awakeSet->islandSims.count;
		for ( int islandIndex = count - 1; islandIndex >= 0; islandIndex -= 1 )
		{
			if ( b3GetBit( awakeIslandBitSet, islandIndex ) == true )
			{
				// this island is still awake
				continue;
			}

			b3IslandSim* island = islands + islandIndex;
			int islandId = island->islandId;

			b3TrySleepIsland( world, islandId );
		}

		b3ValidateSolverSets( world );

		world->profile.sleepIslands = b3GetMilliseconds( sleepTicks );
		b3TracyCZoneEnd( sleep_islands );
	}
}
