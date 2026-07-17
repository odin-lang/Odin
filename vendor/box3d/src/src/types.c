// SPDX-FileCopyrightText: 2025 Erin Catto
// SPDX-License-Identifier: MIT

#include "box3d/types.h"

#include "core.h"

#include "box3d/constants.h"

b3WorldDef b3DefaultWorldDef( void )
{
	float lengthUnits = b3GetLengthUnitsPerMeter();

	b3WorldDef def = { 0 };
	def.gravity.x = 0.0f;
	def.gravity.y = -10.0f;
	def.hitEventThreshold = 1.0f * lengthUnits;
	def.restitutionThreshold = 1.0f * lengthUnits;
	def.contactSpeed = 3.0f * lengthUnits;
	def.contactHertz = 30.0f;
	def.contactDampingRatio = 10.0f;

	// 400 meters per second, faster than the speed of sound
	def.maximumLinearSpeed = 400.0f * lengthUnits;

	def.enableSleep = true;
	def.enableContinuous = true;
	def.internalValue = B3_SECRET_COOKIE;
	return def;
}

b3BodyDef b3DefaultBodyDef( void )
{
	b3BodyDef def = { 0 };
	def.type = b3_staticBody;
	def.rotation = b3Quat_identity;
	def.sleepThreshold = 0.05f * b3GetLengthUnitsPerMeter();
	def.gravityScale = 1.0f;
	def.enableSleep = true;
	def.isAwake = true;
	def.isEnabled = true;
	def.enableContactRecycling = true;
	def.internalValue = B3_SECRET_COOKIE;
	return def;
}

b3Filter b3DefaultFilter( void )
{
	b3Filter filter = { B3_DEFAULT_CATEGORY_BITS, B3_DEFAULT_MASK_BITS, 0 };
	return filter;
}

b3QueryFilter b3DefaultQueryFilter( void )
{
	b3QueryFilter filter = { B3_DEFAULT_CATEGORY_BITS, B3_DEFAULT_MASK_BITS, 0, NULL };
	return filter;
}

b3SurfaceMaterial b3DefaultSurfaceMaterial( void )
{
	b3SurfaceMaterial surfaceMaterial = { 0 };
	surfaceMaterial.friction = 0.6f;
	return surfaceMaterial;
}

b3ShapeDef b3DefaultShapeDef( void )
{
	float lengthUnits = b3GetLengthUnitsPerMeter();

	b3ShapeDef def = { 0 };
	def.baseMaterial = b3DefaultSurfaceMaterial();
	// density of water
	def.density = 1000.0f / ( lengthUnits * lengthUnits * lengthUnits );
	def.explosionScale = 1.0f;
	def.filter = b3DefaultFilter();
	def.updateBodyMass = true;
	def.invokeContactCreation = true;
	def.enableSpeculativeContact = true;
	def.internalValue = B3_SECRET_COOKIE;
	return def;
}

static bool b3EmptyDrawShape( void* userShape, b3WorldTransform transform, b3HexColor color, void* context )
{
	B3_UNUSED( userShape, transform, color, context );
	return false;
}

static void b3EmptyDrawSegment( b3Pos p1, b3Pos p2, b3HexColor color, void* context )
{
	B3_UNUSED( p1, p2, color, context );
}

static void b3EmptyDrawTransform( b3WorldTransform transform, void* context )
{
	B3_UNUSED( transform, context );
}

static void b3EmptyDrawPoint( b3Pos p, float size, b3HexColor color, void* context )
{
	B3_UNUSED( p, size, color, context );
}

static void b3EmptyDrawSphere( b3Pos p, float radius, b3HexColor color, float alpha, void* context )
{
	B3_UNUSED( p, radius, color, alpha, context );
}

static void b3EmptyDrawCapsule( b3Pos p1, b3Pos p2, float radius, b3HexColor color, float alpha, void* context )
{
	B3_UNUSED( p1, p2, radius, color, alpha, context );
}

static void b3EmptyDrawBounds( b3AABB aabb, b3HexColor color, void* context )
{
	B3_UNUSED( aabb, color, context );
}

static void b3EmptyDrawBox( b3Vec3 extents, b3WorldTransform transform, b3HexColor color, void* context )
{
	B3_UNUSED( extents, transform, color, context );
}

static void b3EmptyDrawString( b3Pos p, const char* s, b3HexColor color, void* context )
{
	B3_UNUSED( p, s, color, context );
}

b3DebugDraw b3DefaultDebugDraw( void )
{
	b3DebugDraw draw = { 0 };

	// These allow the user to skip some implementations and not hit null exceptions.
	draw.DrawShapeFcn = b3EmptyDrawShape;
	draw.DrawSegmentFcn = b3EmptyDrawSegment;
	draw.DrawTransformFcn = b3EmptyDrawTransform;
	draw.DrawPointFcn = b3EmptyDrawPoint;
	draw.DrawSphereFcn = b3EmptyDrawSphere;
	draw.DrawCapsuleFcn = b3EmptyDrawCapsule;
	draw.DrawBoundsFcn = b3EmptyDrawBounds;
	draw.DrawBoxFcn = b3EmptyDrawBox;
	draw.DrawStringFcn = b3EmptyDrawString;

	// Not too small, not too big.
	float h = 100.0f * b3GetLengthUnitsPerMeter();
	draw.drawingBounds = (b3AABB){
		.lowerBound = { -h, -h, -h },
		.upperBound = { h, h, h },
	};

	draw.jointScale = 1.0f;
	draw.forceScale = 1.0f;

	return draw;
}
