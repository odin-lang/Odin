// SPDX-FileCopyrightText: 2025 Erin Catto
// SPDX-License-Identifier: MIT

#include "math_internal.h"

#include "box3d/collision.h"
#include "box3d/constants.h"

b3PlaneSolverResult b3SolvePlanes( b3Vec3 targetDelta, b3CollisionPlane* planes, int count )
{
	for ( int i = 0; i < count; ++i )
	{
		planes[i].push = 0.0f;
	}

	b3Vec3 delta = targetDelta;
	float tolerance = B3_LINEAR_SLOP;

	int iteration;
	for ( iteration = 0; iteration < 20; ++iteration )
	{
		float totalPush = 0.0f;
		for ( int planeIndex = 0; planeIndex < count; ++planeIndex )
		{
			b3CollisionPlane* plane = planes + planeIndex;

			// Add slop to prevent jitter
			float separation = b3PlaneSeparation( plane->plane, delta ) + B3_LINEAR_SLOP;

			float push = -separation;

			// Clamp accumulated push
			float accumulatedPush = plane->push;
			plane->push = b3ClampFloat( plane->push + push, 0.0f, plane->pushLimit );
			push = plane->push - accumulatedPush;
			delta = b3MulAdd( delta, push, plane->plane.normal );

			// Track maximum push for convergence
			totalPush += b3AbsFloat( push );
		}

		if ( totalPush < tolerance )
		{
			break;
		}
	}

	return (b3PlaneSolverResult){
		.delta = delta,
		.iterationCount = iteration,
	};
}

b3Vec3 b3ClipVector( b3Vec3 vector, const b3CollisionPlane* planes, int count )
{
	b3Vec3 v = vector;

	for ( int planeIndex = 0; planeIndex < count; ++planeIndex )
	{
		const b3CollisionPlane* plane = planes + planeIndex;
		if ( plane->push == 0.0f || plane->clipVelocity == false )
		{
			continue;
		}

		v = b3MulSub( v, b3MinFloat( 0.0f, b3Dot( v, plane->plane.normal ) ), plane->plane.normal );
	}

	return v;
}
