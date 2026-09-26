// SPDX-FileCopyrightText: 2025 Erin Catto
// SPDX-License-Identifier: MIT

#include "math_internal.h"
#include "shape.h"

#include "box3d/base.h"
#include "box3d/collision.h"
#include "box3d/constants.h"

b3MassData b3ComputeCapsuleMass( const b3Capsule* shape, float density )
{
	b3Vec3 c1 = shape->center1;
	b3Vec3 c2 = shape->center2;
	float r = shape->radius;

	// Cylinder
	float cylinderHeight = b3Distance( c1, c2 );
	float cylinderVolume = B3_PI * r * r * cylinderHeight;
	float cylinderMass = cylinderVolume * density;

	// Sphere
	float sphereVolume = ( 4.0f / 3.0f ) * B3_PI * r * r * r;
	float sphereMass = sphereVolume * density;

	// Local accumulated inertia
	b3Matrix3 inertia = b3AddMM( b3CylinderInertia( cylinderMass, r, cylinderHeight ), b3SphereInertia( sphereMass, r ) );

	float steiner = 0.125f * sphereMass * ( 3.0f * r + 2.0f * cylinderHeight ) * cylinderHeight;
	inertia.cx.x += steiner;
	inertia.cz.z += steiner;

	// Align capsule axis with chosen up-axis
	b3Matrix3 rotation = b3Mat3_identity;
	if ( cylinderHeight * cylinderHeight > 1000.0f * FLT_MIN )
	{
		b3Vec3 direction = b3Normalize( b3Sub( c2, c1 ) );
		b3Quat q = b3ComputeQuatBetweenUnitVectors( b3Vec3_axisY, direction );
		rotation = b3MakeMatrixFromQuat( q );
	}

	float mass = sphereMass + cylinderMass;
	b3Vec3 center = b3MulSV( 0.5f, b3Add( c1, c2 ) );

	b3MassData out;
	out.mass = mass;
	out.center = center;

	// Rotate the central inertia into the shape frame
	out.inertia = b3MulMM( rotation, b3MulMM( inertia, b3Transpose( rotation ) ) );

	return out;
}

b3AABB b3ComputeCapsuleAABB( const b3Capsule* shape, b3Transform transform )
{
	float r = shape->radius;

	b3Vec3 center1 = b3TransformPoint( transform, shape->center1 );
	b3Vec3 center2 = b3TransformPoint( transform, shape->center2 );
	b3Vec3 extent = { r, r, r };

	b3AABB aabb;
	aabb.lowerBound = b3Sub( b3Min( center1, center2 ), extent );
	aabb.upperBound = b3Add( b3Max( center1, center2 ), extent );
	return aabb;
}

b3AABB b3ComputeSweptCapsuleAABB( const b3Capsule* shape, b3Transform xf1, b3Transform xf2 )
{
	b3Vec3 r = { shape->radius, shape->radius, shape->radius };
	b3Vec3 a = b3TransformPoint( xf1, shape->center1 );
	b3Vec3 b = b3TransformPoint( xf1, shape->center2 );
	b3Vec3 c = b3TransformPoint( xf2, shape->center1 );
	b3Vec3 d = b3TransformPoint( xf2, shape->center2 );

	b3AABB aabb = {
		.lowerBound = b3Sub( b3Min( b3Min( a, b ), b3Min( c, d ) ), r ),
		.upperBound = b3Add( b3Max( b3Max( a, b ), b3Max( c, d ) ), r ),
	};
	return aabb;
}

bool b3OverlapCapsule( const b3Capsule* shape, b3Transform shapeTransform, const b3ShapeProxy* proxy )
{
	b3DistanceInput input;
	input.proxyA = (b3ShapeProxy){ &shape->center1, 2, shape->radius };
	input.proxyB = *proxy;
	input.transform = b3InvMulTransforms( shapeTransform, b3Transform_identity );
	input.useRadii = true;

	b3SimplexCache cache = { 0 };
	b3DistanceOutput output = b3ShapeDistance( &input, &cache, NULL, 0 );
	return output.distance < B3_OVERLAP_SLOP;
}

// Precision Improvements for Ray / Sphere Intersection - Ray Tracing Gems 2019
// http://www.codercorner.com/blog/?p=321
b3CastOutput b3RayCastCapsule( const b3Capsule* shape, const b3RayCastInput* input )
{
	B3_ASSERT( b3IsValidRay( input ) );

	b3Vec3 c1 = shape->center1;
	b3Vec3 c2 = shape->center2;
	float r = shape->radius;

	// Initialize result structure
	b3CastOutput output = { 0 };

	b3Vec3 d = b3Sub( c2, c1 );

	// Fall back to sphere if the capsule is short
	float tol = 0.01f * B3_LINEAR_SLOP;
	float lengthSquared = b3LengthSquared( d );
	if ( lengthSquared < tol * tol )
	{
		b3Vec3 sphereCenter = b3MulSV( 0.5f, b3Add( shape->center1, shape->center2 ) );
		b3Sphere sphere = { sphereCenter, shape->radius };
		return b3RayCastSphere( &sphere, input );
	}

	// Vector from first center to ray origin.
	b3Vec3 s = b3Sub( input->origin, c1 );

	// Capsule axis
	float length = sqrtf( lengthSquared );
	b3Vec3 axis = b3MulSV( 1.0f / length, d );

	// Project ray origin onto capsule axis.
	float u = b3Dot( s, axis );

	// Closest point on infinite capsule axis, relative to c1.
	b3Vec3 c = b3MulSV( u, axis );

	// Vector from closest point to ray origin
	b3Vec3 sc = b3Sub( s, c );

	// Squared distance from ray origin to capsule axis
	float sc2 = b3LengthSquared( sc );

	// Is the ray origin within the infinite cylinder along the capsule axis?
	if ( sc2 < r * r )
	{
		// Clamped barycentric coordinate of ray origin projected onto capsule axis.
		float uClamped = b3ClampFloat( u, 0.0f, length );

		// The closest point on the bounded capsule segment, relative to c1.
		b3Vec3 cp = b3MulSV( uClamped, axis );

		// Vector from ray origin to closest point on segment.
		b3Vec3 scp = b3Sub( s, cp );

		// Squared distance of ray origin from capsule segment.
		float scp2 = b3LengthSquared( scp );

		// Is the ray origin within the capsule?
		if ( scp2 < r * r )
		{
			output.hit = true;
			output.point = input->origin;
			return output;
		}

		// The ray can hit an endcap.
		b3Sphere sphere = {
			.center = b3Add( c1, cp ),
			.radius = r,
		};

		return b3RayCastSphere( &sphere, input );
	}

	// Ray axis. A zero length ray reaching here starts outside the capsule, so it misses.
	// Same zero length convention as b3RayCastSphere.
	b3Vec3 dr = input->translation;
	float rayLength;
	b3Vec3 rayAxis = b3GetLengthAndNormalize( &rayLength, dr );
	if ( rayLength == 0.0f )
	{
		return output;
	}

	// Barycentric coordinate of ray end point.
	float v = u + input->maxFraction * b3Dot( dr, axis );

	// Early out: does the projected ray fall outside the capsule?
	if ( ( u < -r && v < -r ) || ( length + r < u && length + r < v ) )
	{
		return output;
	}

	// Compute the closest point between the ray segment and the capsule segment.
	// See Real-Time Collision Detection, section 5.1.9

	// Closest point on capsule : a1 = segment unit axis, t1 = unknown fraction
	// p1 = t1 * a1

	// Closet point on ray : a2 = ray unit axis, t2 = unknown fraction
	// p2 = s + t2 * a2

	// Closest point perpendicularity conditions.
	// dot(p2 - p1, a1) = 0
	// dot(p2 - p1, a2) = 0

	// Expand
	// dot(t1 * a1 - s - t2 * a2, a1) = 0
	// dot(t1 * a1 - s - t2 * a2, a2) = 0

	// Expand
	// t1 - dot(s, a1) - t2 * dot(a1, a2) = 0
	// t1 * dot(a1, a2) - dot(s, a2) - t2 = 0

	// Group : a12 = dot(a1, a2), sa1 = dot(s, a1), sa2 = dot(s, a2)
	// t1       - a12 * t2 = sa1
	// a12 * t1 -       t2 = sa2

	// Solve
	// https://en.wikipedia.org/wiki/Cramer%27s_rule
	// I've flipped the signs of the numerator and denominator to give a positive determinant.
	// det = 1 - a12 * a12
	// t1 = (sa1 - a12 * sa2) / det
	// t2 = (a12 * sa1 - sa2) / det

	b3Vec3 a1 = axis;
	b3Vec3 a2 = rayAxis;
	float a12 = b3Dot( a1, a2 );

	// Ray distance to the near intersection with the infinite cylinder. Length units.
	float tr;

	float det = 1.0f - a12 * a12;
	if ( det < FLT_EPSILON )
	{
		// Solve the 2D problem of ray versus circle starting at the ray origin, where the circle is
		// the axial view of the infinite capsule cylinder. This works well when the ray origin is
		// not too far from the capsule axis.

		// Instead of a cross product, subtract the parallel part to get a perpendicular vector. Non-dimensional.
		b3Vec3 perp = b3MulSub( a2, a12, a1 );
		float perp2 = b3LengthSquared( perp );

		// Project to origin to infinite capsule axis vector onto the perpendicular vector. beta has length units.
		float beta = b3Dot( sc, perp );

		// Setup quadratic root finder.
		float gamma = sc2 - r * r;

		// Discriminant
		float disc = beta * beta - perp2 * gamma;

		// Casting away from the axis, or the perpendicular gap never closes to the radius.
		if ( beta >= 0.0f || disc < 0.0f )
		{
			return output;
		}

		// Quadratic near root. Expressed in an alternate form to avoid the (-beta - sqrt) cancellation as
		// the ray nears parallel.
		tr = gamma / ( -beta + sqrtf( disc ) );
	}
	else
	{
		// Ray and capsules axes are not parallel.

		// Closest points between the infinite ray and the infinite capsule axis.
		float invDet = 1.0f / det;
		float sa1 = u;
		float sa2 = b3Dot( s, a2 );

		float t1 = ( sa1 - a12 * sa2 ) * invDet;
		float t2 = ( a12 * sa1 - sa2 ) * invDet;

		// Closest points
		b3Vec3 p1 = b3MulSV( t1, a1 );
		b3Vec3 p2 = b3MulAdd( s, t2, a2 );

		// Vector from closest point on infinite capsule to infinite ray.
		b3Vec3 g = b3Sub( p2, p1 );

		float g2 = b3LengthSquared( g );
		if ( g2 > r * r )
		{
			// Early out: closest point on infinite ray is outside infinite cylinder.
			return output;
		}

		// Intersect the infinite ray with the infinite cylinder. Like ray versus sphere this is done
		// relative to the closest point to avoid round-off errors. Length units, not a fraction.
		// https://en.wikipedia.org/wiki/Line-cylinder_intersection
		float h = sqrtf( ( r * r - g2 ) * invDet );

		tr = t2 - h;
	}

	// Outside ray?
	if ( tr < 0.0f || input->maxFraction * rayLength < tr )
	{
		return output;
	}

	// The corresponding distance on the capsule axis. Length units.
	float tc = u + tr * a12;

	// Outside c1 end?
	if ( tc < 0.0f )
	{
		// Ray cast sphere 1.
		b3Sphere sphere = {
			.center = c1,
			.radius = r,
		};

		return b3RayCastSphere( &sphere, input );
	}

	// Outside c2 end?
	if (length < tc)
	{
		// Ray cast sphere 2.
		b3Sphere sphere = {
			.center = c2,
			.radius = r,
		};

		return b3RayCastSphere( &sphere, input );
	}

	// Hit point on capsule side, relative to c1.
	b3Vec3 p = b3MulAdd( s, tr, rayAxis );

	// Hit normal.
	b3Vec3 normal = b3MulSub( p, tc, axis );
	normal = b3Normalize( normal );

	output.point = b3Add( c1, p );
	output.normal = normal;
	output.fraction = b3ClampFloat( tr / rayLength, 0.0f, input->maxFraction );
	output.hit = true;
	return output;
}

b3CastOutput b3ShapeCastCapsule( const b3Capsule* capsule, const b3ShapeCastInput* input )
{
	b3ShapeCastPairInput pairInput;
	pairInput.proxyA = (b3ShapeProxy){ &capsule->center1, 2, capsule->radius };
	pairInput.proxyB = input->proxy;
	pairInput.transform = b3Transform_identity;
	pairInput.translationB = input->translation;
	pairInput.maxFraction = input->maxFraction;
	pairInput.canEncroach = input->canEncroach;

	b3CastOutput output = b3ShapeCast( &pairInput );
	return output;
}

int b3CollideMoverAndCapsule( b3PlaneResult* result, const b3Capsule* shape, const b3Capsule* mover )
{
	float totalRadius = mover->radius + shape->radius;

	b3SegmentDistanceResult approach = b3SegmentDistance( shape->center1, shape->center2, mover->center1, mover->center2 );

	// The normal points from the shape toward the mover.
	float distance;
	b3Vec3 normal = b3GetLengthAndNormalize( &distance, b3Sub( approach.point2, approach.point1 ) );

	if ( distance > totalRadius )
	{
		return 0;
	}

	float linearSlop = B3_LINEAR_SLOP;
	if ( distance < linearSlop )
	{
		// Deep overlap: the core segments intersect. Pick an arbitrary direction perpendicular
		// the to capsule axis.
		float moverLength;
		b3Vec3 moverAxis = b3GetLengthAndNormalize( &moverLength, b3Sub( mover->center2, mover->center1 ) );
		normal = moverLength > linearSlop ? b3Perp( moverAxis ) : b3Vec3_axisY;
		distance = 0.0f;
	}

	b3Plane plane = { normal, totalRadius - distance };
	*result = (b3PlaneResult){ plane, approach.point1 };
	return 1;
}
