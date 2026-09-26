// SPDX-FileCopyrightText: 2025 Erin Catto
// SPDX-License-Identifier: MIT

#include "aabb.h"

#include "math_internal.h"

#include "box3d/math_functions.h"

#include <float.h>

// Similar to Real-time Collision Detection, p179.
// todo try
// https://www.scratchapixel.com/lessons/3d-basic-rendering/minimal-ray-tracer-rendering-simple-shapes/ray-box-intersection.html
bool b3RayCastAABB( b3AABB a, b3Vec3 p1, b3Vec3 p2, float* minFraction, float* maxFraction )
{
	// Ray direction and length
	b3Vec3 d = b3Sub( p2, p1 );
	float rayLength = b3Length( d );

	// Handle degenerate ray
	if ( rayLength < FLT_EPSILON )
	{
		// Check if point is inside AABB
		if ( p1.x >= a.lowerBound.x && p1.x <= a.upperBound.x && p1.y >= a.lowerBound.y && p1.y <= a.upperBound.y &&
			 p1.z >= a.lowerBound.z && p1.z <= a.upperBound.z )
		{
			*minFraction = 0.0f;
			*maxFraction = 0.0f;
			return true;
		}

		return false;
	}

	b3Vec3 rayDir = b3MulSV( 1.0f / rayLength, d );

	// Slab method for ray-AABB intersection
	float tMin = 0.0f;
	float tMax = rayLength;

	// x-axis
	{
		float rayComponent = rayDir.x;
		float rayStart = p1.x;
		float boxMin = a.lowerBound.x;
		float boxMax = a.upperBound.x;

		if ( b3AbsFloat( rayComponent ) < FLT_EPSILON )
		{
			// Ray is parallel to slab, check if ray origin is within slab
			if ( rayStart < boxMin || rayStart > boxMax )
			{
				return false;
			}
		}
		else
		{
			// Compute intersection distances
			float t1 = ( boxMin - rayStart ) / rayComponent;
			float t2 = ( boxMax - rayStart ) / rayComponent;

			// Ensure t1 <= t2
			if ( t1 > t2 )
			{
				float temp = t1;
				t1 = t2;
				t2 = temp;
			}

			// Update intersection interval
			tMin = b3MaxFloat( tMin, t1 );
			tMax = b3MinFloat( tMax, t2 );

			// Check for no intersection
			if ( tMin > tMax )
			{
				return false;
			}
		}
	}
	
	// y-axis
	{
		float rayComponent = rayDir.y;
		float rayStart = p1.y;
		float boxMin = a.lowerBound.y;
		float boxMax = a.upperBound.y;

		if ( b3AbsFloat( rayComponent ) < FLT_EPSILON )
		{
			// Ray is parallel to slab, check if ray origin is within slab
			if ( rayStart < boxMin || rayStart > boxMax )
			{
				return false;
			}
		}
		else
		{
			// Compute intersection distances
			float t1 = ( boxMin - rayStart ) / rayComponent;
			float t2 = ( boxMax - rayStart ) / rayComponent;

			// Ensure t1 <= t2
			if ( t1 > t2 )
			{
				float temp = t1;
				t1 = t2;
				t2 = temp;
			}

			// Update intersection interval
			tMin = b3MaxFloat( tMin, t1 );
			tMax = b3MinFloat( tMax, t2 );

			// Check for no intersection
			if ( tMin > tMax )
			{
				return false;
			}
		}
	}

	// z-axis
	{
		float rayComponent = rayDir.z;
		float rayStart = p1.z;
		float boxMin = a.lowerBound.z;
		float boxMax = a.upperBound.z;

		if ( b3AbsFloat( rayComponent ) < FLT_EPSILON )
		{
			// Ray is parallel to slab, check if ray origin is within slab
			if ( rayStart < boxMin || rayStart > boxMax )
			{
				return false;
			}
		}
		else
		{
			// Compute intersection distances
			float t1 = ( boxMin - rayStart ) / rayComponent;
			float t2 = ( boxMax - rayStart ) / rayComponent;

			// Ensure t1 <= t2
			if ( t1 > t2 )
			{
				float temp = t1;
				t1 = t2;
				t2 = temp;
			}

			// Update intersection interval
			tMin = b3MaxFloat( tMin, t1 );
			tMax = b3MinFloat( tMax, t2 );

			// Check for no intersection
			if ( tMin > tMax )
			{
				return false;
			}
		}
	}

	// Check if intersection is behind ray start
	if ( tMax < 0.0f )
	{
		return false;
	}

	// Convert distances to fractions
	*minFraction = b3ClampFloat( tMin / rayLength, 0.0f, 1.0f );
	*maxFraction = b3ClampFloat( tMax / rayLength, 0.0f, 1.0f );

	return true;
}
