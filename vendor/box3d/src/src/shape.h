// SPDX-FileCopyrightText: 2025 Erin Catto
// SPDX-License-Identifier: MIT

#pragma once

#include "math_internal.h"

#include "box3d/types.h"

#include <stdbool.h>

typedef struct b3BroadPhase b3BroadPhase;
typedef struct b3World b3World;

typedef enum b3ShapeFlags
{
	b3_enableSensorEvents = 0x01,
	b3_enableContactEvents = 0x02,
	b3_enableCustomFiltering = 0x04,
	b3_enableHitEvents = 0x08,
	b3_enablePreSolveEvents = 0x10,
	b3_enlargedAABB = 0x20,
	b3_enableSpeculative = 0x40,
} b3ShapeFlags;

typedef struct b3Shape
{
	int id;
	int bodyId;
	int prevShapeId;
	int nextShapeId;
	int sensorIndex;
	int proxyKey;
	b3ShapeType type;
	float density;
	float explosionScale;
	float aabbMargin;

	b3AABB aabb;
	b3AABB fatAABB;
	b3Vec3 localCentroid;

	int materialCount;
	b3SurfaceMaterial material;
	b3SurfaceMaterial* materials;

	b3Filter filter;
	void* userData;
	void* userShape;

	uint32_t nameId;
	uint16_t generation;

	// b3ShapeFlags
	uint8_t flags;

	union
	{
		b3Capsule capsule;
		b3Sphere sphere;
		const b3HullData* hull;
		b3Mesh mesh;
		const b3HeightFieldData* heightField;
		const b3CompoundData* compound;
	};

} b3Shape;

// A single material shape keeps its material inline. Multi material meshes and compounds own a heap
// array. Reach the materials the same way for both: a single material shape presents its inline
// material as a one element array. Do not cache the pointer, the shapes array can move.
static inline b3SurfaceMaterial* b3GetShapeMaterials( const b3Shape* shape )
{
	return shape->materials != NULL ? shape->materials : (b3SurfaceMaterial*)&shape->material;
}

void b3CreateShapeProxy( b3Shape* shape, b3BroadPhase* bp, b3BodyType type, b3WorldTransform transform, bool forcePairCreation );
void b3DestroyShapeProxy( b3Shape* shape, b3BroadPhase* bp );

void b3DestroyShapeAllocations( b3World* world, b3Shape* shape );

b3MassData b3ComputeShapeMass( const b3Shape* shape );
b3ShapeExtent b3ComputeShapeExtent( const b3Shape* shape, b3Vec3 localCenter );

b3AABB b3ComputeSweptSphereAABB( const b3Sphere* shape, b3Transform xf1, b3Transform xf2 );
b3AABB b3ComputeSweptCapsuleAABB( const b3Capsule* shape, b3Transform xf1, b3Transform xf2 );

b3AABB b3ComputeShapeAABB( const b3Shape* shape, b3Transform transform );

// Conservative world AABB for a shape inflated by extra margin. In double precision mode the
// box is built in the body local frame, translated by the double origin, and rounded outward.
b3AABB b3ComputeFatShapeAABB( const b3Shape* shape, b3WorldTransform transform, float extra );
b3AABB b3ComputeSweptShapeAABB( const b3Shape* shape, const b3Sweep* sweep, float time );
b3Vec3 b3GetShapeCentroid( const b3Shape* shape );
float b3GetShapeArea( const b3Shape* shape );
float b3GetShapeProjectedArea( const b3Shape* shape, b3Vec3 planeNormal );
uint64_t b3GetShapeUserMaterialId( const b3Shape* shape, int childIndex, int triangleIndex );

b3ShapeProxy b3MakeShapeProxy( const b3Shape* shape );
b3ShapeProxy b3MakeLocalProxy( const b3ShapeProxy* proxy, b3Transform transform, b3Vec3* buffer );
b3AABB b3ComputeProxyAABB( const b3ShapeProxy* proxy );

b3CastOutput b3RayCastShape( const b3Shape* shape, b3Transform transform, const b3RayCastInput* input );
b3CastOutput b3ShapeCastShape( const b3Shape* shape, b3Transform transform, const b3ShapeCastInput* input );
bool b3OverlapShape( const b3Shape* shape, b3Transform transform, const b3ShapeProxy* proxy );

float b3GetShapeArea( const b3Shape* shape );
float b3GetShapeProjectedArea( const b3Shape* shape, b3Vec3 planeNormal );
b3TOIOutput b3ShapeTimeOfImpact( b3Shape* shapeA, b3Shape* shapeB, b3Sweep* sweepA, b3Sweep* sweepB, float maxFraction );

int b3CollideMoverAndSphere( b3PlaneResult* result, const b3Sphere* shape, const b3Capsule* mover );
int b3CollideMoverAndCapsule( b3PlaneResult* result, const b3Capsule* shape, const b3Capsule* mover );
int b3CollideMoverAndHull( b3PlaneResult* result, const b3HullData* shape, const b3Capsule* mover );
int b3CollideMoverAndMesh( b3PlaneResult* planes, int capacity, const b3Mesh* shape, const b3Capsule* mover );
int b3CollideMoverAndHeightField( b3PlaneResult* results, int capacity, const b3HeightFieldData* shape, const b3Capsule* mover );
int b3CollideMover( b3PlaneResult* planes, int planeCapacity, const b3Shape* shape, b3Transform transform,
					const b3Capsule* mover );

// Hull
int b3FindHullSupportVertex( const b3HullData* hull, b3Vec3 direction );
int b3FindHullSupportFace( const b3HullData* hull, b3Vec3 direction );
bool b3IsValidHull( const b3HullData* hull );
b3AABB b3ComputeSweptHullAABB( const b3HullData* shape, b3Transform xf1, b3Transform xf2 );
b3ShapeExtent b3ComputeHullExtent( const b3HullData* hull, b3Vec3 origin );
float b3ComputeHullProjectedArea( const b3HullData* hull, b3Vec3 direction );

// Height field
b3Triangle b3GetHeightFieldTriangle( const b3HeightFieldData* heightField, int triangleIndex );
int b3GetHeightFieldMaterial( const b3HeightFieldData* heightField, int triangleIndex );

static inline int b3GetHeightFieldTriangleCount( const b3HeightFieldData* heightField )
{
	int cellCount = ( heightField->rowCount - 1 ) * ( heightField->columnCount - 1 );
	return 2 * cellCount;
}

// Mesh
b3Triangle b3GetMeshTriangle( const b3Mesh* mesh, int triangleIndex );
bool b3IsValidMesh( const b3MeshData* meshData );

static inline bool b3ShouldShapesCollide( b3Filter filterA, b3Filter filterB )
{
	if ( filterA.groupIndex == filterB.groupIndex && filterA.groupIndex != 0 )
	{
		return filterA.groupIndex > 0;
	}

	return ( filterA.maskBits & filterB.categoryBits ) != 0 && ( filterA.categoryBits & filterB.maskBits ) != 0;
}

static inline bool b3ShouldQueryCollide( const b3Filter* shapeFilter, const b3QueryFilter* queryFilter )
{
	return ( shapeFilter->categoryBits & queryFilter->maskBits ) != 0 &&
		   ( shapeFilter->maskBits & queryFilter->categoryBits ) != 0;
}
