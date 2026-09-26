// SPDX-FileCopyrightText: 2026 Erin Catto
// SPDX-License-Identifier: MIT

// Dirk Gregorius contributed portions of this code

#include "math_internal.h"
#include "shape.h"

#include "box3d/base.h"
#include "box3d/collision.h"
#include "box3d/constants.h"

b3MassData b3ComputeSphereMass( const b3Sphere* shape, float density )
{
	b3Vec3 center = shape->center;
	float radius = shape->radius;

	float volume = 4.0f / 3.0f * B3_PI * radius * radius * radius;
	float mass = volume * density;
	float ixx = 0.4f * mass * radius * radius;

	b3MassData out;
	out.mass = mass;
	out.center = center;

	// Inertia about the center of mass
	out.inertia = b3MakeDiagonalMatrix( ixx, ixx, ixx );
	return out;
}

b3AABB b3ComputeSphereAABB( const b3Sphere* shape, b3Transform transform )
{
	b3Vec3 center = b3TransformPoint( transform, shape->center );
	float radius = shape->radius;
	b3Vec3 extent = { radius, radius, radius };
	return ( b3AABB ){ b3Sub( center, extent ), b3Add( center, extent ) };
}

b3AABB b3ComputeSweptSphereAABB( const b3Sphere* shape, b3Transform xf1, b3Transform xf2 )
{
	b3Vec3 r = { shape->radius, shape->radius, shape->radius };
	b3Vec3 center1 = b3TransformPoint( xf1, shape->center );
	b3Vec3 center2 = b3TransformPoint( xf2, shape->center );
	return ( b3AABB ){ b3Sub( b3Min( center1, center2 ), r ), b3Add( b3Max( center1, center2 ), r ) };
}

bool b3OverlapSphere( const b3Sphere* shape, b3Transform shapeTransform, const b3ShapeProxy* proxy )
{
	b3DistanceInput input;
	input.proxyA = ( b3ShapeProxy ){ &shape->center, 1, shape->radius };
	input.proxyB = *proxy;
	input.transform = b3InvMulTransforms( shapeTransform, b3Transform_identity );
	input.useRadii = true;

	b3SimplexCache cache = { 0 };
	b3DistanceOutput output = b3ShapeDistance( &input, &cache, NULL, 0 );
	return output.distance < B3_OVERLAP_SLOP;
}

// Precision Improvements for Ray / Sphere Intersection - Ray Tracing Gems 2019
// http://www.codercorner.com/blog/?p=321
b3CastOutput b3RayCastSphere(const b3Sphere* shape, const b3RayCastInput* input )
{
	B3_ASSERT( b3IsValidRay( input ) );
	b3CastOutput output = { 0 };

	b3Vec3 p = shape->center;

	// Shift ray so sphere center is the origin
	b3Vec3 s = b3Sub( input->origin, p );

	float r = shape->radius;
	float rr = r * r;

	float length;
	b3Vec3 d = b3GetLengthAndNormalize( &length, input->translation );
	if ( length == 0.0f )
	{
		// zero length ray

		if ( b3LengthSquared( s ) < rr )
		{
			// initial overlap
			output.point = input->origin;
			output.hit = true;
		}

		return output;
	}

	// Find closest point on ray to origin

	// solve: dot(s + t * d, d) = 0
	float t = -b3Dot( s, d );

	// c is the closest point on the line to the origin
	b3Vec3 c = b3MulAdd( s, t, d );

	float cc = b3Dot( c, c );

	if ( cc > rr )
	{
		// closest point is outside the sphere
		return output;
	}

	// Pythagoras
	float h = sqrtf( rr - cc );

	float fraction = t - h;

	if ( fraction < 0.0f || input->maxFraction * length < fraction )
	{
		// intersection is point outside the range of the ray segment

		if ( b3LengthSquared( s ) < rr )
		{
			// initial overlap
			output.point = input->origin;
			output.hit = true;
		}

		return output;
	}

	b3Vec3 hitPoint = b3MulAdd( s, fraction, d );

	output.fraction = fraction / length;

	if ( output.fraction > input->maxFraction )
	{
		b3Log( "sphere input fraction = %g, output fraction = %g", input->maxFraction, output.fraction );
		output.fraction = input->maxFraction;
	}

	output.normal = b3Normalize( hitPoint );
	output.point = b3MulAdd( p, shape->radius, output.normal );
	output.hit = true;

	return output;
}

// Precision Improvements for Ray / Sphere Intersection - Ray Tracing Gems 2019
// http://www.codercorner.com/blog/?p=321
// This will do interior hits.
b3CastOutput b3RayCastHollowSphere( const b3Sphere* sphere, const b3RayCastInput* input )
{
	b3Vec3 p = sphere->center;

	b3CastOutput output = { 0 };

	// Shift ray so sphere center is the origin
	b3Vec3 s = b3Sub( input->origin, p );
	b3Vec3 d = b3Normalize( input->translation );

	// Find closest point on ray to origin

	// solve: dot(s + t * d, d) = 0
	float t = -b3Dot( s, d );

	// c is the closest point on the line to the origin
	b3Vec3 c = b3MulAdd( s, t, d );

	float cc = b3Dot( c, c );
	float r = sphere->radius;
	float rr = r * r;

	if ( cc > rr )
	{
		// closest point is outside the sphere
		return output;
	}

	// Pythagoras
	float h = sqrtf( rr - cc );

	float fraction = t - h;

	if ( fraction < 0.0f )
	{
		fraction = t + h;
	}

	if ( fraction < 0.0f )
	{
		// behind the ray
		return output;
	}

	if (fraction > input->maxFraction)
	{
		return output;
	}

	b3Vec3 hitPoint = b3MulAdd( s, fraction, d );

	output.fraction = fraction;
	output.normal = b3Normalize( hitPoint );
	output.point = b3MulAdd( p, sphere->radius, output.normal );
	output.hit = true;

	return output;
}

b3CastOutput b3ShapeCastSphere( const b3Sphere* sphere, const b3ShapeCastInput* input )
{
	b3ShapeCastPairInput pairInput;
	pairInput.proxyA = ( b3ShapeProxy ){ &sphere->center, 1, sphere->radius };
	pairInput.proxyB = input->proxy;
	pairInput.transform = b3Transform_identity;
	pairInput.translationB = input->translation;
	pairInput.maxFraction = input->maxFraction;
	pairInput.canEncroach = input->canEncroach;

	b3CastOutput output = b3ShapeCast( &pairInput );
	return output;
}

int b3CollideMoverAndSphere( b3PlaneResult* result, const b3Sphere* shape, const b3Capsule* mover )
{
	float totalRadius = mover->radius + shape->radius;
	b3Vec3 closest = b3PointToSegmentDistance( mover->center1, mover->center2, shape->center );

	// The normal points from the sphere toward the mover.
	float distance;
	b3Vec3 normal = b3GetLengthAndNormalize( &distance, b3Sub( closest, shape->center ) );

	if ( distance > totalRadius )
	{
		return 0;
	}

	float linearSlop = B3_LINEAR_SLOP;
	if ( distance < linearSlop )
	{
		// Deep overlap: the mover axis passes through the sphere center, so no
		// direction is preferred. Push perpendicular to the mover axis.
		float length;
		b3Vec3 axis = b3GetLengthAndNormalize( &length, b3Sub( mover->center2, mover->center1 ) );
		normal = length > linearSlop ? b3Perp( axis ) : b3Vec3_axisY;
		distance = 0.0f;
	}

	b3Plane plane = { normal, totalRadius - distance };
	*result = ( b3PlaneResult ){ plane, shape->center };
	return 1;
}
