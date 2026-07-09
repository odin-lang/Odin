// SPDX-FileCopyrightText: 2025 Erin Catto
// SPDX-License-Identifier: MIT

#include "shape.h"

#include "body.h"
#include "broad_phase.h"
#include "contact.h"
#include "physics_world.h"
#include "recording.h"
#include "sensor.h"

// needed for dll export
#include "aabb.h"
#include "compound.h"

#include "box3d/box3d.h"

static b3Shape* b3GetShape( b3World* world, b3ShapeId shapeId )
{
	int id = shapeId.index1 - 1;
	b3Shape* shape = b3Array_Get( world->shapes, id );
	B3_ASSERT( shape->id == id && shape->generation == shapeId.generation );
	return shape;
}

static float b3ComputeShapeMargin( b3Shape* shape )
{
	float margin = 0.0f;

	switch ( shape->type )
	{
		case b3_sphereShape:
		{
			margin = shape->sphere.radius;
		}
		break;

		case b3_capsuleShape:
		{
			margin = 0.5f * b3Distance( shape->capsule.center2, shape->capsule.center1 ) + shape->capsule.radius;
		}
		break;

		case b3_hullShape:
		{
			const b3HullData* hull = shape->hull;
			const b3Vec3* points = b3GetHullPoints( hull );
			float maxExtentSqr = 0.0f;
			int count = hull->vertexCount;
			for ( int i = 0; i < count; ++i )
			{
				float distSqr = b3DistanceSquared( points[i], hull->center );
				maxExtentSqr = b3MaxFloat( maxExtentSqr, distSqr );
			}
			margin = sqrtf( maxExtentSqr );
		}
		break;

		case b3_meshShape:
		case b3_heightShape:
		case b3_compoundShape:
		{
			// Static-only shapes: broadphase uses speculative distance for static
			// proxies, so the per-shape margin is never consumed in practice.
			// Return the cap so any incidental use is generous.
			return B3_MAX_AABB_MARGIN;
		}

		default:
			B3_VALIDATE( false );
			return B3_MAX_AABB_MARGIN;
	}

	return b3MinFloat( B3_MAX_AABB_MARGIN, B3_AABB_MARGIN_FRACTION * margin );
}

static void b3UpdateShapeAABBs( b3Shape* shape, b3WorldTransform transform, b3BodyType proxyType )
{
	// Compute a bounding box with a speculative margin
	const float speculativeDistance = B3_SPECULATIVE_DISTANCE;
	const float aabbMargin = shape->aabbMargin;

	b3AABB aabb = b3ComputeFatShapeAABB( shape, transform, speculativeDistance );
	shape->aabb = aabb;

	// Smaller margin for static bodies. Cannot be zero due to TOI tolerance.
	float margin = proxyType == b3_staticBody ? speculativeDistance : aabbMargin;
	b3AABB fatAABB;
	fatAABB.lowerBound.x = aabb.lowerBound.x - margin;
	fatAABB.lowerBound.y = aabb.lowerBound.y - margin;
	fatAABB.lowerBound.z = aabb.lowerBound.z - margin;
	fatAABB.upperBound.x = aabb.upperBound.x + margin;
	fatAABB.upperBound.y = aabb.upperBound.y + margin;
	fatAABB.upperBound.z = aabb.upperBound.z + margin;
	shape->fatAABB = fatAABB;
}

static b3Shape* b3CreateShapeInternal( b3World* world, b3Body* body, b3WorldTransform bodyTransform, const b3ShapeDef* def,
									   const void* geometry, b3ShapeType shapeType, b3Transform shapeTransform, b3Vec3 scale,
									   bool haveShapeTransform )
{
	int shapeId = b3AllocId( &world->shapeIdPool );

	if ( shapeId == world->shapes.count )
	{
		b3Array_Push( world->shapes, (b3Shape){ 0 } );
	}
	else
	{
		B3_ASSERT( world->shapes.data[shapeId].id == B3_NULL_INDEX );
	}

	b3Shape* shape = b3Array_Get( world->shapes, shapeId );

	switch ( shapeType )
	{
		case b3_capsuleShape:
			shape->capsule = *(b3Capsule*)geometry;
			break;

		case b3_compoundShape:
			// Compounds must be a static and not a sensor
			B3_ASSERT( body->type == b3_staticBody );
			B3_ASSERT( def->isSensor == false );
			shape->compound = (b3CompoundData*)geometry;
			break;

		case b3_sphereShape:
			shape->sphere = *(b3Sphere*)geometry;
			break;

		case b3_hullShape:
			if ( haveShapeTransform )
			{
				// The transform and non-uniform scale are baked into fresh data, then shared.
				b3HullData* baked = b3CloneAndTransformHull( (b3HullData*)geometry, shapeTransform, scale );
				if ( baked == NULL )
				{
					// This can fail to produce a valid hull in extreme cases
					b3FreeId( &world->shapeIdPool, shapeId );
					shape->id = B3_NULL_INDEX;
					return NULL;
				}

				shape->hull = b3AddOwnedHullToDatabase( world, baked );
			}
			else
			{
				shape->hull = b3AddHullToDatabase( world, (const b3HullData*)geometry );
			}
			break;

		case b3_meshShape:
		{
			shape->mesh.data = (b3MeshData*)geometry;
			shape->mesh.scale = b3SafeScale( scale );
		}
		break;

		case b3_heightShape:
			shape->heightField = (b3HeightFieldData*)geometry;
			break;

		default:
			B3_ASSERT( false );
			break;
	}

	shape->id = shapeId;
	shape->bodyId = body->id;
	shape->type = shapeType;
	shape->density = def->density;
	shape->explosionScale = def->explosionScale;
	shape->filter = def->filter;
	shape->userData = def->userData;
	shape->userShape = NULL;
	shape->flags = 0;
	shape->flags |= def->enableSensorEvents ? b3_enableSensorEvents : 0;
	shape->flags |= def->enableContactEvents ? b3_enableContactEvents : 0;
	shape->flags |= def->enableCustomFiltering ? b3_enableCustomFiltering : 0;
	shape->flags |= def->enableHitEvents ? b3_enableHitEvents : 0;
	shape->flags |= def->enablePreSolveEvents ? b3_enablePreSolveEvents : 0;
	shape->flags |= def->enableSpeculativeContact ? b3_enableSpeculative : 0;
	shape->proxyKey = B3_NULL_INDEX;
	shape->localCentroid = b3GetShapeCentroid( shape );
	shape->aabbMargin = b3ComputeShapeMargin( shape );
	shape->aabb = (b3AABB){ b3Vec3_zero, b3Vec3_zero };
	shape->fatAABB = (b3AABB){ b3Vec3_zero, b3Vec3_zero };
	shape->nameId = b3AddName( &world->names, def->name );
	shape->generation += 1;

	if ( shape->type == b3_compoundShape )
	{
		// Own a copy of the compound materials so every shape frees its array the same way. Compounds
		// are few, so the copy is cheap and avoids aliasing the geometry blob.
		int materialCount = shape->compound->materialCount;
		shape->materialCount = materialCount;
		shape->materials = b3Alloc( materialCount * sizeof( b3SurfaceMaterial ) );
		memcpy( shape->materials, b3GetCompoundMaterials( shape->compound ), materialCount * sizeof( b3SurfaceMaterial ) );
	}
	else if ( def->materialCount > 1 && def->materials != NULL )
	{
		// Per triangle materials need a heap array.
		shape->materialCount = def->materialCount;
		shape->materials = b3Alloc( def->materialCount * sizeof( b3SurfaceMaterial ) );
		memcpy( shape->materials, def->materials, def->materialCount * sizeof( b3SurfaceMaterial ) );
	}
	else
	{
		// The common case is one material, stored inline with no allocation.
		shape->material = ( def->materialCount == 1 && def->materials != NULL ) ? def->materials[0] : def->baseMaterial;
		shape->materialCount = 1;
		shape->materials = NULL;
	}

	if ( body->setIndex != b3_disabledSet )
	{
		b3BodyType proxyType = body->type;
		bool forcePairCreation = def->invokeContactCreation && shape->type != b3_compoundShape;
		b3CreateShapeProxy( shape, &world->broadPhase, proxyType, bodyTransform, forcePairCreation );
	}

	// Add to shape doubly linked list
	if ( body->headShapeId != B3_NULL_INDEX )
	{
		b3Shape* headShape = b3Array_Get( world->shapes, body->headShapeId );
		headShape->prevShapeId = shapeId;
	}

	shape->prevShapeId = B3_NULL_INDEX;
	shape->nextShapeId = body->headShapeId;
	body->headShapeId = shapeId;
	body->shapeCount += 1;

	if ( def->isSensor )
	{
		shape->sensorIndex = world->sensors.count;
		b3Sensor* sensor = b3Array_Emplace( world->sensors );
		b3Array_CreateN( sensor->hits, 4 );
		b3Array_CreateN( sensor->overlaps1, 16 );
		b3Array_CreateN( sensor->overlaps2, 16 );
		sensor->shapeId = shapeId;
	}
	else
	{
		shape->sensorIndex = B3_NULL_INDEX;
	}

	b3ValidateSolverSets( world );

	return shape;
}

static b3ShapeId b3CreateShape( b3BodyId bodyId, const b3ShapeDef* def, const void* geometry, b3ShapeType shapeType,
								b3Transform transform, b3Vec3 scale, bool haveTransform )
{
	B3_CHECK_DEF( def );
	B3_ASSERT( b3IsValidFloat( def->density ) && def->density >= 0.0f );
	B3_ASSERT( b3IsValidFloat( def->baseMaterial.friction ) && def->baseMaterial.friction >= 0.0f );
	B3_ASSERT( b3IsValidFloat( def->baseMaterial.restitution ) && def->baseMaterial.restitution >= 0.0f );

	b3World* world = b3GetUnlockedWorld( bodyId.world0 );
	if ( world == NULL )
	{
		return (b3ShapeId){ 0 };
	}

	if ( world->shapes.count == B3_MAX_SHAPES && world->shapeIdPool.freeArray.count == 0 )
	{
		B3_ASSERT( false );
		return b3_nullShapeId;
	}

	b3Body* body = b3GetBodyFullId( world, bodyId );
	if ( body->type != b3_staticBody && ( shapeType == b3_compoundShape || shapeType == b3_heightShape ) )
	{
		// Compound and height shapes must be on static bodies.
		return b3_nullShapeId;
	}

	world->locked = true;

	b3WorldTransform bodyTransform = b3GetBodyTransformQuick( world, body );

	b3Shape* shape =
		b3CreateShapeInternal( world, body, bodyTransform, def, geometry, shapeType, transform, scale, haveTransform );

	if ( shape == NULL )
	{
		world->locked = false;
		return b3_nullShapeId;
	}

	if ( def->updateBodyMass == true )
	{
		b3UpdateBodyMassData( world, body );
	}
	else if ( ( body->flags & b3_dirtyMass ) == 0 )
	{
		body->flags |= b3_dirtyMass;
		b3SyncBodyFlags( world, body );
	}

	b3ValidateSolverSets( world );

	b3ShapeId id = { shape->id + 1, bodyId.world0, shape->generation };

	world->locked = false;

	return id;
}

b3ShapeId b3CreateSphereShape( b3BodyId bodyId, const b3ShapeDef* def, const b3Sphere* sphere )
{
	b3ShapeId shapeId = b3CreateShape( bodyId, def, sphere, b3_sphereShape, b3Transform_identity, b3Vec3_one, false );
	if ( shapeId.index1 != 0 )
	{
		b3World* world = b3GetUnlockedWorld( bodyId.world0 );
		if ( world != NULL )
		{
			B3_REC_CREATE( world, CreateSphereShape, shapeId, bodyId, *def, *sphere );
		}
	}
	return shapeId;
}

b3ShapeId b3CreateCapsuleShape( b3BodyId bodyId, const b3ShapeDef* def, const b3Capsule* capsule )
{
	float lengthSqr = b3DistanceSquared( capsule->center1, capsule->center2 );
	b3ShapeId shapeId;
	if ( lengthSqr <= B3_LINEAR_SLOP * B3_LINEAR_SLOP )
	{
		b3Sphere sphere = { b3Lerp( capsule->center1, capsule->center2, 0.5f ), capsule->radius };
		shapeId = b3CreateShape( bodyId, def, &sphere, b3_sphereShape, b3Transform_identity, b3Vec3_one, false );
	}
	else
	{
		shapeId = b3CreateShape( bodyId, def, capsule, b3_capsuleShape, b3Transform_identity, b3Vec3_one, false );
	}
	if ( shapeId.index1 != 0 )
	{
		b3World* world = b3GetUnlockedWorld( bodyId.world0 );
		if ( world != NULL )
		{
			B3_REC_CREATE( world, CreateCapsuleShape, shapeId, bodyId, *def, *capsule );
		}
	}
	return shapeId;
}

b3ShapeId b3CreateHullShape( b3BodyId bodyId, const b3ShapeDef* def, const b3HullData* hull )
{
	B3_VALIDATE( b3IsValidHull( hull ) );
	B3_VALIDATE( hull->hash != 0 );
	b3ShapeId shapeId = b3CreateShape( bodyId, def, hull, b3_hullShape, b3Transform_identity, b3Vec3_one, false );
	if ( shapeId.index1 != 0 )
	{
		b3World* world = b3GetUnlockedWorld( bodyId.world0 );
		if ( world != NULL && world->recording != NULL )
		{
			uint32_t geometryId = b3RecInternHull( world->recording, hull );
			b3RecArgs_CreateHullShape createArgs = { bodyId, *def, geometryId };
			b3RecWriteRet_CreateHullShape( world->recording, &createArgs, shapeId );
		}
	}
	return shapeId;
}

b3ShapeId b3CreateTransformedHullShape( b3BodyId bodyId, const b3ShapeDef* def, const b3HullData* hull, b3Transform transform,
										b3Vec3 scale )
{
	B3_VALIDATE( b3IsValidHull( hull ) );
	b3ShapeId shapeId = b3CreateShape( bodyId, def, hull, b3_hullShape, transform, scale, true );
	if ( shapeId.index1 != 0 )
	{
		b3World* world = b3GetUnlockedWorld( bodyId.world0 );
		if ( world != NULL && world->recording != NULL )
		{
			// The transform and scale are baked into fresh hull data at create time. Record the baked hull
			// as a plain hull shape so replay rebuilds identical geometry with no rebake, and the keyframe
			// registry, which interns the live baked hull, stays seeded.
			b3Shape* shape = b3Array_Get( world->shapes, shapeId.index1 - 1 );
			uint32_t geometryId = b3RecInternHull( world->recording, shape->hull );
			b3RecArgs_CreateHullShape createArgs = { bodyId, *def, geometryId };
			b3RecWriteRet_CreateHullShape( world->recording, &createArgs, shapeId );
		}
	}
	return shapeId;
}

b3ShapeId b3CreateMeshShape( b3BodyId bodyId, const b3ShapeDef* def, const b3MeshData* mesh, b3Vec3 scale )
{
	B3_VALIDATE( b3IsValidMesh( mesh ) );
	B3_VALIDATE( mesh->hash != 0 );
	b3ShapeId shapeId = b3CreateShape( bodyId, def, mesh, b3_meshShape, b3Transform_identity, scale, true );
	if ( shapeId.index1 != 0 )
	{
		b3World* world = b3GetUnlockedWorld( bodyId.world0 );
		if ( world != NULL && world->recording != NULL )
		{
			uint32_t geometryId = b3RecInternMesh( world->recording, mesh );
			b3RecArgs_CreateMeshShape createArgs = { bodyId, *def, geometryId, scale };
			b3RecWriteRet_CreateMeshShape( world->recording, &createArgs, shapeId );
		}
	}
	return shapeId;
}

b3ShapeId b3CreateHeightFieldShape( b3BodyId bodyId, const b3ShapeDef* def, const b3HeightFieldData* heightField )
{
	B3_VALIDATE( heightField->hash != 0 );
	b3ShapeId shapeId = b3CreateShape( bodyId, def, heightField, b3_heightShape, b3Transform_identity, b3Vec3_one, false );
	if ( shapeId.index1 != 0 )
	{
		b3World* world = b3GetUnlockedWorld( bodyId.world0 );
		if ( world != NULL && world->recording != NULL )
		{
			uint32_t geometryId = b3RecInternHeightField( world->recording, heightField );
			b3RecArgs_CreateHeightFieldShape createArgs = { bodyId, *def, geometryId };
			b3RecWriteRet_CreateHeightFieldShape( world->recording, &createArgs, shapeId );
		}
	}
	return shapeId;
}

b3ShapeId b3CreateCompoundShape( b3BodyId bodyId, b3ShapeDef* def, const b3CompoundData* compound )
{
	b3ShapeId shapeId = b3CreateShape( bodyId, def, compound, b3_compoundShape, b3Transform_identity, b3Vec3_one, false );
	if ( shapeId.index1 != 0 )
	{
		b3World* world = b3GetUnlockedWorld( bodyId.world0 );
		if ( world != NULL && world->recording != NULL )
		{
			uint32_t geometryId = b3RecInternCompound( world->recording, compound );
			b3RecArgs_CreateCompoundShape createArgs = { bodyId, *def, geometryId };
			b3RecWriteRet_CreateCompoundShape( world->recording, &createArgs, shapeId );
		}
	}
	return shapeId;
}

// Destroy a shape on a body. This doesn't need to be called when destroying a body.
static void b3DestroyShapeInternal( b3World* world, b3Shape* shape, b3Body* body, bool wakeBodies )
{
	int shapeId = shape->id;

	// Remove the shape from the body's doubly linked list.
	if ( shape->prevShapeId != B3_NULL_INDEX )
	{
		b3Shape* prevShape = b3Array_Get( world->shapes, shape->prevShapeId );
		prevShape->nextShapeId = shape->nextShapeId;
	}

	if ( shape->nextShapeId != B3_NULL_INDEX )
	{
		b3Shape* nextShape = b3Array_Get( world->shapes, shape->nextShapeId );
		nextShape->prevShapeId = shape->prevShapeId;
	}

	if ( shapeId == body->headShapeId )
	{
		body->headShapeId = shape->nextShapeId;
	}

	body->shapeCount -= 1;

	// Remove from broad-phase.
	b3DestroyShapeProxy( shape, &world->broadPhase );

	// Destroy any contacts associated with the shape.
	int contactKey = body->headContactKey;
	while ( contactKey != B3_NULL_INDEX )
	{
		int contactId = contactKey >> 1;
		int edgeIndex = contactKey & 1;

		b3Contact* contact = b3Array_Get( world->contacts, contactId );
		contactKey = contact->edges[edgeIndex].nextKey;

		if ( contact->shapeIdA == shapeId || contact->shapeIdB == shapeId )
		{
			b3DestroyContact( world, contact, wakeBodies );
		}
	}

	if ( shape->sensorIndex != B3_NULL_INDEX )
	{
		b3Sensor* sensor = b3Array_Get( world->sensors, shape->sensorIndex );
		for ( int i = 0; i < sensor->overlaps2.count; ++i )
		{
			b3Visitor* ref = sensor->overlaps2.data + i;
			b3SensorEndTouchEvent event = {
				.sensorShapeId =
					{
						.index1 = shapeId + 1,
						.world0 = world->worldId,
						.generation = shape->generation,
					},
				.visitorShapeId =
					{
						.index1 = ref->shapeId + 1,
						.world0 = world->worldId,
						.generation = ref->generation,
					},
			};

			b3Array_Push( world->sensorEndEvents[world->endEventArrayIndex], event );
		}

		// Destroy sensor
		b3Array_Destroy( sensor->hits );
		b3Array_Destroy( sensor->overlaps1 );
		b3Array_Destroy( sensor->overlaps2 );

		int movedIndex = b3Array_RemoveSwap( world->sensors, shape->sensorIndex );
		if ( movedIndex != B3_NULL_INDEX )
		{
			// Fixup moved sensor
			b3Sensor* movedSensor = b3Array_Get( world->sensors, shape->sensorIndex );
			b3Shape* otherSensorShape = b3Array_Get( world->shapes, movedSensor->shapeId );
			otherSensorShape->sensorIndex = shape->sensorIndex;
		}
	}

	// Destroy every shape member from b3Alloc
	b3DestroyShapeAllocations( world, shape );

	// Return shape to free list.
	b3FreeId( &world->shapeIdPool, shapeId );
	shape->id = B3_NULL_INDEX;

	b3ValidateSolverSets( world );
}

void b3DestroyShape( b3ShapeId shapeId, bool updateBodyMass )
{
	b3World* world = b3GetUnlockedWorld( shapeId.world0 );
	if ( world == NULL )
	{
		return;
	}

	B3_REC( world, DestroyShape, shapeId, updateBodyMass );

	world->locked = true;

	b3Shape* shape = b3GetShape( world, shapeId );

	// need to wake bodies because this might be a static body
	bool wakeBodies = true;

	b3Body* body = b3Array_Get( world->bodies, shape->bodyId );
	b3DestroyShapeInternal( world, shape, body, wakeBodies );

	if ( updateBodyMass == true )
	{
		b3UpdateBodyMassData( world, body );
	}

	world->locked = false;
}

b3AABB b3ComputeShapeAABB( const b3Shape* shape, b3Transform transform )
{
	switch ( shape->type )
	{
		case b3_capsuleShape:
			return b3ComputeCapsuleAABB( &shape->capsule, transform );

		case b3_compoundShape:
			return b3ComputeCompoundAABB( shape->compound, transform );

		case b3_heightShape:
			return b3ComputeHeightFieldAABB( shape->heightField, transform );

		case b3_hullShape:
			return b3ComputeHullAABB( shape->hull, transform );

		case b3_meshShape:
			return b3ComputeMeshAABB( shape->mesh.data, transform, shape->mesh.scale );

		case b3_sphereShape:
			return b3ComputeSphereAABB( &shape->sphere, transform );

		default:
		{
			B3_ASSERT( false );
			b3AABB empty = { transform.p, transform.p };
			return empty;
		}
	}
}

b3AABB b3ComputeFatShapeAABB( const b3Shape* shape, b3WorldTransform transform, float extra )
{
	b3Vec3 r = { extra, extra, extra };
#if defined( BOX3D_DOUBLE_PRECISION )
	// Build the box in the body local frame, inflate, then translate by the double origin and
	// round outward. Inflating before the single rounding matters far from the origin where the
	// float margin would otherwise vanish.
	b3Transform rotation = { b3Vec3_zero, transform.q };
	b3AABB localBox = b3ComputeShapeAABB( shape, rotation );
	localBox.lowerBound = b3Sub( localBox.lowerBound, r );
	localBox.upperBound = b3Add( localBox.upperBound, r );
	return b3OffsetAABB( localBox, transform.p );
#else
	b3AABB aabb = b3ComputeShapeAABB( shape, transform );
	aabb.lowerBound = b3Sub( aabb.lowerBound, r );
	aabb.upperBound = b3Add( aabb.upperBound, r );
	return aabb;
#endif
}

b3AABB b3ComputeSweptShapeAABB( const b3Shape* shape, const b3Sweep* sweep, float time )
{
	B3_ASSERT( 0.0f <= time && time <= 1.0f );
	b3Transform xf1 = { b3Sub( sweep->c1, b3RotateVector( sweep->q1, sweep->localCenter ) ), sweep->q1 };
	b3Transform xf2 = b3GetSweepTransform( sweep, time );

	switch ( shape->type )
	{
		case b3_capsuleShape:
			return b3ComputeSweptCapsuleAABB( &shape->capsule, xf1, xf2 );

		case b3_hullShape:
			return b3ComputeSweptHullAABB( shape->hull, xf1, xf2 );

		case b3_sphereShape:
			return b3ComputeSweptSphereAABB( &shape->sphere, xf1, xf2 );

		default:
			B3_ASSERT( false );
			return (b3AABB){ xf1.p, xf1.p };
	}
}

b3Vec3 b3GetShapeCentroid( const b3Shape* shape )
{
	switch ( shape->type )
	{
		case b3_capsuleShape:
			return b3Lerp( shape->capsule.center1, shape->capsule.center2, 0.5f );
		case b3_compoundShape:
		{
			b3AABB aabb = b3ComputeCompoundAABB( shape->compound, b3Transform_identity );
			return b3AABB_Center( aabb );
		}
		case b3_sphereShape:
			return shape->sphere.center;
		case b3_hullShape:
			return shape->hull->center;
		case b3_meshShape:
		{
			b3AABB aabb = b3ComputeMeshAABB( shape->mesh.data, b3Transform_identity, shape->mesh.scale );
			return b3AABB_Center( aabb );
		}
		case b3_heightShape:
		{
			b3AABB aabb = b3ComputeHeightFieldAABB( shape->heightField, b3Transform_identity );
			return b3AABB_Center( aabb );
		}
		default:
			return b3Vec3_zero;
	}
}

float b3GetShapeArea( const b3Shape* shape )
{
	// todo_erin fix these
	switch ( shape->type )
	{
		case b3_capsuleShape:
			return 2.0f * b3Length( b3Sub( shape->capsule.center1, shape->capsule.center2 ) ) +
				   2.0f * B3_PI * shape->capsule.radius;

		case b3_hullShape:
			return shape->hull->surfaceArea;

		case b3_sphereShape:
			return 2.0f * B3_PI * shape->sphere.radius;

		default:
			return 0.0f;
	}
}

// This projects the shape surface area onto a plane
float b3GetShapeProjectedArea( const b3Shape* shape, b3Vec3 planeNormal )
{
	switch ( shape->type )
	{
		case b3_capsuleShape:
		{
			float radius = shape->capsule.radius;
			b3Vec3 axis = b3Sub( shape->capsule.center2, shape->capsule.center1 );
			float projectedLength = b3Length( b3Cross( axis, planeNormal ) );
			float cylinderArea = 2.0f * radius * projectedLength;
			float sphereArea = B3_PI * radius * radius;
			return sphereArea + cylinderArea;
		}

		case b3_hullShape:
			return b3ComputeHullProjectedArea( shape->hull, planeNormal );

		case b3_sphereShape:
			return B3_PI * shape->sphere.radius * shape->sphere.radius;

		default:
			return 0.0f;
	}
}

b3MassData b3ComputeShapeMass( const b3Shape* shape )
{
	switch ( shape->type )
	{
		case b3_capsuleShape:
			return b3ComputeCapsuleMass( &shape->capsule, shape->density );

		case b3_hullShape:
			return b3ComputeHullMass( shape->hull, shape->density );

		case b3_sphereShape:
			return b3ComputeSphereMass( &shape->sphere, shape->density );

		default:
			return (b3MassData){ 0 };
	}
}

b3ShapeExtent b3ComputeShapeExtent( const b3Shape* shape, b3Vec3 localCenter )
{
	b3ShapeExtent extent = { 0 };

	switch ( shape->type )
	{
		case b3_capsuleShape:
		{
			float radius = shape->capsule.radius;
			extent.minExtent = radius;
			b3Vec3 c1 = b3Sub( shape->capsule.center1, localCenter );
			b3Vec3 c2 = b3Sub( shape->capsule.center2, localCenter );
			b3Vec3 r = { radius, radius, radius };
			extent.maxExtent = b3Add( b3Max( c1, c2 ), r );
		}
		break;

		case b3_compoundShape:
		{
			// This is shouldn't be needed but here for completeness
			b3AABB aabb = b3ComputeCompoundAABB( shape->compound, b3Transform_identity );
			float r1 = b3Length( b3Sub( aabb.lowerBound, localCenter ) );
			float r2 = b3Length( b3Sub( aabb.upperBound, localCenter ) );
			extent.minExtent = b3MinFloat( r1, r2 );
			b3Vec3 p = b3FarthestPointOnAABB( aabb, localCenter );
			extent.maxExtent = b3Abs( b3Sub( p, localCenter ) );
		}
		break;

		case b3_sphereShape:
		{
			float radius = shape->sphere.radius;
			extent.minExtent = radius;
			b3Vec3 r = { radius, radius, radius };
			b3Vec3 p = b3Add( b3Sub( shape->sphere.center, localCenter ), r );
			extent.maxExtent = b3Abs( b3Sub( p, localCenter ) );
		}
		break;

		case b3_hullShape:
			extent = b3ComputeHullExtent( shape->hull, localCenter );
			break;

		case b3_meshShape:
		{
			// This is needed for kinematic mesh sleeping
			b3AABB aabb = b3ComputeMeshAABB( shape->mesh.data, b3Transform_identity, shape->mesh.scale );
			float r1 = b3Length( b3Sub( aabb.lowerBound, localCenter ) );
			float r2 = b3Length( b3Sub( aabb.upperBound, localCenter ) );
			extent.minExtent = b3MinFloat( r1, r2 );
			b3Vec3 p = b3FarthestPointOnAABB( aabb, localCenter );
			extent.maxExtent = b3Abs( p );
		}
		break;

		default:
			break;
	}

	return extent;
}

b3CastOutput b3RayCastShape( const b3Shape* shape, b3Transform transform, const b3RayCastInput* input )
{
	b3RayCastInput localInput = *input;
	localInput.origin = b3InvTransformPoint( transform, input->origin );
	localInput.translation = b3InvRotateVector( transform.q, input->translation );

	b3CastOutput output = { 0 };
	switch ( shape->type )
	{
		case b3_capsuleShape:
			output = b3RayCastCapsule( &shape->capsule, &localInput );
			break;
		case b3_compoundShape:
			output = b3RayCastCompound( shape->compound, &localInput );
			break;
		case b3_sphereShape:
			output = b3RayCastSphere( &shape->sphere, &localInput );
			break;
		case b3_hullShape:
			output = b3RayCastHull( shape->hull, &localInput );
			break;
		case b3_meshShape:
			output = b3RayCastMesh( &shape->mesh, &localInput );
			break;
		case b3_heightShape:
			output = b3RayCastHeightField( shape->heightField, &localInput );
			break;
		default:
			return output;
	}

	output.point = b3TransformPoint( transform, output.point );
	output.normal = b3RotateVector( transform.q, output.normal );
	return output;
}

b3CastOutput b3ShapeCastShape( const b3Shape* shape, b3Transform transform, const b3ShapeCastInput* input )
{
	b3ShapeCastInput localInput = *input;
	b3Vec3 localPoints[B3_MAX_SHAPE_CAST_POINTS];

	localInput.proxy.count = b3MinInt( input->proxy.count, B3_MAX_SHAPE_CAST_POINTS );
	for ( int i = 0; i < localInput.proxy.count; ++i )
	{
		localPoints[i] = b3InvTransformPoint( transform, input->proxy.points[i] );
	}

	localInput.proxy.points = localPoints;
	localInput.translation = b3InvRotateVector( transform.q, input->translation );

	b3CastOutput output = { 0 };
	switch ( shape->type )
	{
		case b3_capsuleShape:
			output = b3ShapeCastCapsule( &shape->capsule, &localInput );
			break;

		case b3_compoundShape:
			output = b3ShapeCastCompound( shape->compound, &localInput );
			break;

		case b3_heightShape:
			output = b3ShapeCastHeightField( shape->heightField, &localInput );
			break;

		case b3_hullShape:
			output = b3ShapeCastHull( shape->hull, &localInput );
			break;

		case b3_meshShape:
			output = b3ShapeCastMesh( &shape->mesh, &localInput );
			break;

		case b3_sphereShape:
			output = b3ShapeCastSphere( &shape->sphere, &localInput );
			break;
		default:
			return output;
	}

	output.point = b3TransformPoint( transform, output.point );
	output.normal = b3RotateVector( transform.q, output.normal );
	return output;
}

bool b3OverlapShape( const b3Shape* shape, b3Transform transform, const b3ShapeProxy* proxy )
{
	b3ShapeType type = shape->type;
	switch ( type )
	{
		case b3_capsuleShape:
			return b3OverlapCapsule( &shape->capsule, transform, proxy );

		case b3_compoundShape:
			return b3OverlapCompound( shape->compound, transform, proxy );

		case b3_heightShape:
			return b3OverlapHeightField( shape->heightField, transform, proxy );

		case b3_hullShape:
			return b3OverlapHull( shape->hull, transform, proxy );

		case b3_meshShape:
			return b3OverlapMesh( &shape->mesh, transform, proxy );

		case b3_sphereShape:
			return b3OverlapSphere( &shape->sphere, transform, proxy );

		default:
			B3_ASSERT( false );
			return false;
	}

#if 0
	b3Vec3 localPoints[B3_MAX_SHAPE_CAST_POINTS];
	b3ShapeProxy localProxy;

	b3Transform invTransform = b3InvertTransform( transform );
	b3Matrix3 R = b3MakeMatrixFromQuat( invTransform.q );

	localProxy.count = b3MinInt( proxy->count, B3_MAX_SHAPE_CAST_POINTS );
	for ( int i = 0; i < localProxy.count; ++i )
	{
		localPoints[i] = b3Add( b3MulMV( R, proxy->points[i] ), invTransform.p );
	}

	localProxy.points = localPoints;
	localProxy.radius = proxy->radius;

	if ( type == b3_meshShape )
	{
		return b3OverlapMesh( &localProxy, shape->mesh.data, shape->mesh.scale );
	}

	B3_ASSERT( type == b3_heightShape );

	return b3OverlapHeightField( &localProxy, shape->heightField );
#endif
}

int b3CollideMover( b3PlaneResult* planes, int planeCapacity, const b3Shape* shape, b3Transform transform,
					const b3Capsule* mover )
{
	if ( planeCapacity == 0 )
	{
		return 0;
	}

	b3Capsule localMover;
	localMover.center1 = b3InvTransformPoint( transform, mover->center1 );
	localMover.center2 = b3InvTransformPoint( transform, mover->center2 );
	localMover.radius = mover->radius;

	int planeCount = 0;
	switch ( shape->type )
	{
		case b3_capsuleShape:
			planeCount = b3CollideMoverAndCapsule( planes, &shape->capsule, &localMover );
			break;

		case b3_compoundShape:
			planeCount = b3CollideMoverAndCompound( planes, planeCapacity, shape->compound, &localMover );
			break;

		case b3_sphereShape:
			planeCount = b3CollideMoverAndSphere( planes, &shape->sphere, &localMover );
			break;

		case b3_hullShape:
			planeCount = b3CollideMoverAndHull( planes, shape->hull, &localMover );
			break;

		case b3_meshShape:
			planeCount = b3CollideMoverAndMesh( planes, planeCapacity, &shape->mesh, &localMover );
			break;

		case b3_heightShape:
			planeCount = b3CollideMoverAndHeightField( planes, planeCapacity, shape->heightField, &localMover );
			break;

		default:
			B3_ASSERT( false );
			break;
	}

	for ( int i = 0; i < planeCount; ++i )
	{
		planes[i].plane.normal = b3RotateVector( transform.q, planes[i].plane.normal );
		planes[i].point = b3TransformPoint( transform, planes[i].point );
	}

	return planeCount;
}

void b3CreateShapeProxy( b3Shape* shape, b3BroadPhase* bp, b3BodyType type, b3WorldTransform transform, bool forcePairCreation )
{
	B3_ASSERT( shape->proxyKey == B3_NULL_INDEX );

	b3UpdateShapeAABBs( shape, transform, type );

	// Create proxies in the broad-phase.
	shape->proxyKey =
		b3BroadPhase_CreateProxy( bp, type, shape->fatAABB, shape->filter.categoryBits, shape->id, forcePairCreation );
	B3_ASSERT( B3_PROXY_TYPE( shape->proxyKey ) < b3_bodyTypeCount );
}

void b3DestroyShapeProxy( b3Shape* shape, b3BroadPhase* bp )
{
	if ( shape->proxyKey != B3_NULL_INDEX )
	{
		b3BroadPhase_DestroyProxy( bp, shape->proxyKey );
		shape->proxyKey = B3_NULL_INDEX;
	}
}

static void b3DestroyShapeAllocationForShapeChange( b3World* world, b3Shape* shape )
{
	b3ShapeType type = shape->type;
	switch ( type )
	{
		case b3_hullShape:
			b3RemoveHullFromDatabase( world, shape->hull );
			shape->hull = NULL;
			break;

		default:
			break;
	}

	if ( shape->userShape != NULL )
	{
		world->destroyDebugShape( shape->userShape, world->userDebugShapeContext );
		shape->userShape = NULL;
	}
}

void b3DestroyShapeAllocations( b3World* world, b3Shape* shape )
{
	b3DestroyShapeAllocationForShapeChange( world, shape );

	if ( shape->materials != NULL )
	{
		B3_ASSERT( shape->materialCount > 0 );
		b3Free( shape->materials, shape->materialCount * sizeof( b3SurfaceMaterial ) );
		shape->materials = NULL;
		shape->materialCount = 0;
	}

	// Name is stored inline. Sensor data is destroyed elsewhere
}

b3ShapeProxy b3MakeShapeProxy( const b3Shape* shape )
{
	switch ( shape->type )
	{
		case b3_capsuleShape:
			return (b3ShapeProxy){ &shape->capsule.center1, 2, shape->capsule.radius };

		case b3_sphereShape:
			return (b3ShapeProxy){ &shape->sphere.center, 1, shape->sphere.radius };

		case b3_hullShape:
		{
			const b3HullData* hull = shape->hull;
			const b3Vec3* points = b3GetHullPoints( hull );
			return (b3ShapeProxy){ points, hull->vertexCount, 0.0f };
		}

		default:
		{
			B3_ASSERT( false );
			return (b3ShapeProxy){ 0 };
		}
	}
}

b3ShapeProxy b3MakeLocalProxy( const b3ShapeProxy* proxy, b3Transform transform, b3Vec3* buffer )
{
	b3Transform invTransform = b3InvertTransform( transform );
	b3Matrix3 R = b3MakeMatrixFromQuat( invTransform.q );

	int count = b3MinInt( proxy->count, B3_MAX_SHAPE_CAST_POINTS );
	for ( int i = 0; i < count; ++i )
	{
		buffer[i] = b3Add( b3MulMV( R, proxy->points[i] ), invTransform.p );
	}

	return (b3ShapeProxy){
		.points = buffer,
		.count = count,
		.radius = proxy->radius,
	};
}

b3AABB b3ComputeProxyAABB( const b3ShapeProxy* proxy )
{
	const b3Vec3* points = proxy->points;
	b3AABB aabb = {
		.lowerBound = points[0],
		.upperBound = points[0],
	};

	for ( int i = 1; i < proxy->count; ++i )
	{
		aabb.lowerBound = b3Min( aabb.lowerBound, points[i] );
		aabb.upperBound = b3Max( aabb.upperBound, points[i] );
	}

	b3Vec3 r = { proxy->radius, proxy->radius, proxy->radius };
	aabb.lowerBound = b3Sub( aabb.lowerBound, r );
	aabb.upperBound = b3Add( aabb.upperBound, r );
	return aabb;
}

b3BodyId b3Shape_GetBody( b3ShapeId shapeId )
{
	b3World* world = b3GetWorld( shapeId.world0 );
	b3Shape* shape = b3GetShape( world, shapeId );
	return b3MakeBodyId( world, shape->bodyId );
}

b3WorldId b3Shape_GetWorld( b3ShapeId shapeId )
{
	b3World* world = b3GetWorld( shapeId.world0 );
	return (b3WorldId){ (uint16_t)( shapeId.world0 + 1 ), world->generation };
}

void b3Shape_SetUserData( b3ShapeId shapeId, void* userData )
{
	b3World* world = b3GetWorld( shapeId.world0 );
	b3Shape* shape = b3GetShape( world, shapeId );
	shape->userData = userData;
}

void* b3Shape_GetUserData( b3ShapeId shapeId )
{
	b3World* world = b3GetWorld( shapeId.world0 );
	b3Shape* shape = b3GetShape( world, shapeId );
	return shape->userData;
}

void b3Shape_SetName( b3ShapeId shapeId, const char* name )
{
	b3World* world = b3GetWorld( shapeId.world0 );

	B3_REC( world, ShapeSetName, shapeId, name );

	b3Shape* shape = b3GetShape( world, shapeId );
	shape->nameId = b3AddName( &world->names, name );
}

const char* b3Shape_GetName( b3ShapeId shapeId )
{
	b3World* world = b3GetWorld( shapeId.world0 );
	b3Shape* shape = b3GetShape( world, shapeId );
	return b3FindNameWithDefault( &world->names, shape->nameId, "" );
}

bool b3Shape_IsSensor( b3ShapeId shapeId )
{
	b3World* world = b3GetWorld( shapeId.world0 );
	b3Shape* shape = b3GetShape( world, shapeId );
	return shape->sensorIndex != B3_NULL_INDEX;
}

// todo no tests
b3WorldCastOutput b3Shape_RayCast( b3ShapeId shapeId, b3Pos origin, b3Vec3 translation )
{
	B3_ASSERT( b3IsValidPosition( origin ) );
	B3_ASSERT( b3IsValidVec3( translation ) );

	b3World* world = b3GetWorld( shapeId.world0 );
	b3Shape* shape = b3GetShape( world, shapeId );

	// Re-center on the origin so the cast runs in float precision far from the world origin
	b3Transform transform = b3ToRelativeTransform( b3GetBodyTransform( world, shape->bodyId ), origin );

	// The ray starts at the origin, so its origin in the re-centered frame is zero
	b3RayCastInput input = { b3Vec3_zero, translation, 1.0f };

	// Lift the re-centered float result back to a world position
	b3CastOutput local = b3RayCastShape( shape, transform, &input );
	b3WorldCastOutput output;
	output.normal = local.normal;
	output.point = b3OffsetPos( origin, local.point );
	output.fraction = local.fraction;
	output.iterations = local.iterations;
	output.triangleIndex = local.triangleIndex;
	output.childIndex = local.childIndex;
	output.materialIndex = local.materialIndex;
	output.hit = local.hit;

	return output;
}

void b3Shape_SetDensity( b3ShapeId shapeId, float density, bool updateBodyMass )
{
	B3_ASSERT( b3IsValidFloat( density ) && density >= 0.0f );

	b3World* world = b3GetUnlockedWorld( shapeId.world0 );
	if ( world == NULL )
	{
		return;
	}

	B3_REC( world, ShapeSetDensity, shapeId, density, updateBodyMass );

	b3Shape* shape = b3GetShape( world, shapeId );
	if ( density == shape->density )
	{
		// early return to avoid expensive function
		return;
	}

	shape->density = density;

	if ( updateBodyMass == true )
	{
		b3Body* body = b3Array_Get( world->bodies, shape->bodyId );
		b3UpdateBodyMassData( world, body );
	}
}

float b3Shape_GetDensity( b3ShapeId shapeId )
{
	b3World* world = b3GetWorld( shapeId.world0 );
	b3Shape* shape = b3GetShape( world, shapeId );
	return shape->density;
}

void b3Shape_SetFriction( b3ShapeId shapeId, float friction )
{
	B3_ASSERT( b3IsValidFloat( friction ) && friction >= 0.0f );
	b3World* world = b3GetWorld( shapeId.world0 );
	B3_REC( world, ShapeSetFriction, shapeId, friction );
	b3Shape* shape = b3GetShape( world, shapeId );
	B3_ASSERT( shape->type != b3_compoundShape );
	b3GetShapeMaterials( shape )[0].friction = friction;
}

float b3Shape_GetFriction( b3ShapeId shapeId )
{
	b3World* world = b3GetWorld( shapeId.world0 );
	b3Shape* shape = b3GetShape( world, shapeId );
	return b3GetShapeMaterials( shape )[0].friction;
}

void b3Shape_SetRestitution( b3ShapeId shapeId, float restitution )
{
	B3_ASSERT( b3IsValidFloat( restitution ) && restitution >= 0.0f );
	b3World* world = b3GetWorld( shapeId.world0 );
	B3_REC( world, ShapeSetRestitution, shapeId, restitution );
	b3Shape* shape = b3GetShape( world, shapeId );
	B3_ASSERT( shape->type != b3_compoundShape );
	b3GetShapeMaterials( shape )[0].restitution = restitution;
}

float b3Shape_GetRestitution( b3ShapeId shapeId )
{
	b3World* world = b3GetWorld( shapeId.world0 );
	b3Shape* shape = b3GetShape( world, shapeId );
	return b3GetShapeMaterials( shape )[0].restitution;
}

void b3Shape_SetSurfaceMaterial( b3ShapeId shapeId, b3SurfaceMaterial surfaceMaterial )
{
	B3_ASSERT( b3IsValidFloat( surfaceMaterial.friction ) && surfaceMaterial.friction >= 0.0f );
	B3_ASSERT( b3IsValidFloat( surfaceMaterial.restitution ) && surfaceMaterial.restitution >= 0.0f );
	B3_ASSERT( b3IsValidFloat( surfaceMaterial.rollingResistance ) && surfaceMaterial.rollingResistance >= 0.0f );
	B3_ASSERT( b3IsValidVec3( surfaceMaterial.tangentVelocity ) );

	b3World* world = b3GetWorld( shapeId.world0 );
	B3_REC( world, ShapeSetSurfaceMaterial, shapeId, surfaceMaterial );
	b3Shape* shape = b3GetShape( world, shapeId );
	B3_ASSERT( shape->type != b3_compoundShape );
	b3GetShapeMaterials( shape )[0] = surfaceMaterial;
}

b3SurfaceMaterial b3Shape_GetSurfaceMaterial( b3ShapeId shapeId )
{
	b3World* world = b3GetWorld( shapeId.world0 );
	b3Shape* shape = b3GetShape( world, shapeId );
	return b3GetShapeMaterials( shape )[0];
}

int b3Shape_GetMeshMaterialCount( b3ShapeId shapeId )
{
	b3World* world = b3GetWorld( shapeId.world0 );
	b3Shape* shape = b3GetShape( world, shapeId );
	return shape->materialCount;
}

void b3Shape_SetMeshMaterial( b3ShapeId shapeId, b3SurfaceMaterial surfaceMaterial, int index )
{
	B3_ASSERT( b3IsValidFloat( surfaceMaterial.friction ) && surfaceMaterial.friction >= 0.0f );
	B3_ASSERT( b3IsValidFloat( surfaceMaterial.restitution ) && surfaceMaterial.restitution >= 0.0f );
	B3_ASSERT( b3IsValidFloat( surfaceMaterial.rollingResistance ) && surfaceMaterial.rollingResistance >= 0.0f );
	B3_ASSERT( b3IsValidVec3( surfaceMaterial.tangentVelocity ) );

	b3World* world = b3GetWorld( shapeId.world0 );
	b3Shape* shape = b3GetShape( world, shapeId );

	B3_ASSERT( 0 <= index && index < shape->materialCount );
	B3_ASSERT( shape->type != b3_compoundShape );
	b3GetShapeMaterials( shape )[index] = surfaceMaterial;
}

b3SurfaceMaterial b3Shape_GetMeshSurfaceMaterial( b3ShapeId shapeId, int index )
{
	b3World* world = b3GetWorld( shapeId.world0 );
	b3Shape* shape = b3GetShape( world, shapeId );
	B3_ASSERT( 0 <= index && index < shape->materialCount );
	return b3GetShapeMaterials( shape )[index];
}

b3Filter b3Shape_GetFilter( b3ShapeId shapeId )
{
	b3World* world = b3GetWorld( shapeId.world0 );
	b3Shape* shape = b3GetShape( world, shapeId );
	return shape->filter;
}

static void b3ResetProxy( b3World* world, b3Shape* shape, bool wakeBodies, bool destroyProxy )
{
	b3Body* body = b3Array_Get( world->bodies, shape->bodyId );

	int shapeId = shape->id;

	// destroy all contacts associated with this shape
	int contactKey = body->headContactKey;
	while ( contactKey != B3_NULL_INDEX )
	{
		int contactId = contactKey >> 1;
		int edgeIndex = contactKey & 1;

		b3Contact* contact = b3Array_Get( world->contacts, contactId );
		contactKey = contact->edges[edgeIndex].nextKey;

		if ( contact->shapeIdA == shapeId || contact->shapeIdB == shapeId )
		{
			b3DestroyContact( world, contact, wakeBodies );
		}
	}

	b3WorldTransform transform = b3GetBodyTransformQuick( world, body );
	if ( shape->proxyKey != B3_NULL_INDEX )
	{
		b3BodyType proxyType = B3_PROXY_TYPE( shape->proxyKey );
		b3UpdateShapeAABBs( shape, transform, proxyType );

		if ( destroyProxy )
		{
			b3BroadPhase_DestroyProxy( &world->broadPhase, shape->proxyKey );

			bool forcePairCreation = true;
			shape->proxyKey = b3BroadPhase_CreateProxy( &world->broadPhase, proxyType, shape->fatAABB, shape->filter.categoryBits,
														shapeId, forcePairCreation );
		}
		else
		{
			b3BroadPhase_MoveProxy( &world->broadPhase, shape->proxyKey, shape->fatAABB );
		}
	}
	else
	{
		b3BodyType proxyType = body->type;
		b3UpdateShapeAABBs( shape, transform, proxyType );
	}

	b3ValidateSolverSets( world );
}

void b3Shape_SetFilter( b3ShapeId shapeId, b3Filter filter, bool invokeContacts )
{
	b3World* world = b3GetUnlockedWorld( shapeId.world0 );
	if ( world == NULL )
	{
		return;
	}

	B3_REC( world, ShapeSetFilter, shapeId, filter, invokeContacts );

	b3Shape* shape = b3GetShape( world, shapeId );
	if ( filter.maskBits == shape->filter.maskBits && filter.categoryBits == shape->filter.categoryBits &&
		 filter.groupIndex == shape->filter.groupIndex )
	{
		return;
	}

	shape->filter = filter;

	if ( invokeContacts )
	{
		world->locked = true;
		bool wakeBodies = true;

		// If the category bits change, I need to destroy the proxy because it affects the tree sorting.
		bool destroyProxy = filter.categoryBits == shape->filter.categoryBits;

		// need to wake bodies because a filter change may destroy contacts
		b3ResetProxy( world, shape, wakeBodies, destroyProxy );
		world->locked = false;
	}

	// note: this does not immediately update sensor overlaps. Instead sensor
	// overlaps are updated the next time step
}

void b3Shape_EnableSensorEvents( b3ShapeId shapeId, bool flag )
{
	b3World* world = b3GetUnlockedWorld( shapeId.world0 );
	if ( world == NULL )
	{
		return;
	}

	B3_REC( world, ShapeEnableSensorEvents, shapeId, flag );

	b3Shape* shape = b3GetShape( world, shapeId );
	shape->flags = flag ? shape->flags | b3_enableSensorEvents : shape->flags & ~b3_enableSensorEvents;
}

bool b3Shape_AreSensorEventsEnabled( b3ShapeId shapeId )
{
	b3World* world = b3GetWorld( shapeId.world0 );
	b3Shape* shape = b3GetShape( world, shapeId );
	return shape->flags & b3_enableSensorEvents;
}

void b3Shape_EnableContactEvents( b3ShapeId shapeId, bool flag )
{
	b3World* world = b3GetUnlockedWorld( shapeId.world0 );
	if ( world == NULL )
	{
		return;
	}

	B3_REC( world, ShapeEnableContactEvents, shapeId, flag );

	b3Shape* shape = b3GetShape( world, shapeId );
	shape->flags = flag ? shape->flags | b3_enableContactEvents : shape->flags & ~b3_enableContactEvents;
}

bool b3Shape_AreContactEventsEnabled( b3ShapeId shapeId )
{
	b3World* world = b3GetWorld( shapeId.world0 );
	b3Shape* shape = b3GetShape( world, shapeId );
	return shape->flags & b3_enableContactEvents;
}

void b3Shape_EnablePreSolveEvents( b3ShapeId shapeId, bool flag )
{
	b3World* world = b3GetUnlockedWorld( shapeId.world0 );
	if ( world == NULL )
	{
		return;
	}

	B3_REC( world, ShapeEnablePreSolveEvents, shapeId, flag );

	b3Shape* shape = b3GetShape( world, shapeId );
	shape->flags = flag ? shape->flags | b3_enablePreSolveEvents : shape->flags & ~b3_enablePreSolveEvents;
}

bool b3Shape_ArePreSolveEventsEnabled( b3ShapeId shapeId )
{
	b3World* world = b3GetWorld( shapeId.world0 );
	b3Shape* shape = b3GetShape( world, shapeId );
	return shape->flags & b3_enablePreSolveEvents;
}

void b3Shape_EnableHitEvents( b3ShapeId shapeId, bool flag )
{
	b3World* world = b3GetUnlockedWorld( shapeId.world0 );
	if ( world == NULL )
	{
		return;
	}

	B3_REC( world, ShapeEnableHitEvents, shapeId, flag );

	b3Shape* shape = b3GetShape( world, shapeId );
	shape->flags = flag ? shape->flags | b3_enableHitEvents : shape->flags & ~b3_enableHitEvents;
}

bool b3Shape_AreHitEventsEnabled( b3ShapeId shapeId )
{
	b3World* world = b3GetWorld( shapeId.world0 );
	b3Shape* shape = b3GetShape( world, shapeId );
	return shape->flags & b3_enableHitEvents;
}

b3ShapeType b3Shape_GetType( b3ShapeId shapeId )
{
	b3World* world = b3GetWorld( shapeId.world0 );
	b3Shape* shape = b3GetShape( world, shapeId );
	return shape->type;
}

b3Sphere b3Shape_GetSphere( b3ShapeId shapeId )
{
	b3World* world = b3GetWorld( shapeId.world0 );
	b3Shape* shape = b3GetShape( world, shapeId );
	B3_ASSERT( shape->type == b3_sphereShape );
	return shape->sphere;
}

b3Capsule b3Shape_GetCapsule( b3ShapeId shapeId )
{
	b3World* world = b3GetWorld( shapeId.world0 );
	b3Shape* shape = b3GetShape( world, shapeId );
	B3_ASSERT( shape->type == b3_capsuleShape );
	return shape->capsule;
}

const b3HullData* b3Shape_GetHull( b3ShapeId shapeId )
{
	b3World* world = b3GetWorld( shapeId.world0 );
	b3Shape* shape = b3GetShape( world, shapeId );
	B3_ASSERT( shape->type == b3_hullShape );
	return shape->hull;
}

b3Mesh b3Shape_GetMesh( b3ShapeId shapeId )
{
	b3World* world = b3GetWorld( shapeId.world0 );
	b3Shape* shape = b3GetShape( world, shapeId );
	B3_ASSERT( shape->type == b3_meshShape );
	return shape->mesh;
}

const b3HeightFieldData* b3Shape_GetHeightField( b3ShapeId shapeId )
{
	b3World* world = b3GetWorld( shapeId.world0 );
	b3Shape* shape = b3GetShape( world, shapeId );
	B3_ASSERT( shape->type == b3_heightShape );
	return shape->heightField;
}

void b3Shape_SetSphere( b3ShapeId shapeId, const b3Sphere* sphere )
{
	b3World* world = b3GetUnlockedWorld( shapeId.world0 );
	if ( world == NULL )
	{
		return;
	}

	B3_REC( world, ShapeSetSphere, shapeId, *sphere );

	world->locked = true;

	b3Shape* shape = b3GetShape( world, shapeId );

	b3DestroyShapeAllocationForShapeChange( world, shape );

	shape->sphere = *sphere;
	shape->type = b3_sphereShape;
	shape->aabbMargin = b3ComputeShapeMargin( shape );

	// need to wake bodies so they can react to the shape change
	bool wakeBodies = true;
	bool destroyProxy = true;
	b3ResetProxy( world, shape, wakeBodies, destroyProxy );

	world->locked = false;
}

void b3Shape_SetCapsule( b3ShapeId shapeId, const b3Capsule* capsule )
{
	b3World* world = b3GetUnlockedWorld( shapeId.world0 );
	if ( world == NULL )
	{
		return;
	}

	B3_REC( world, ShapeSetCapsule, shapeId, *capsule );

	world->locked = true;

	b3Shape* shape = b3GetShape( world, shapeId );

	b3DestroyShapeAllocationForShapeChange( world, shape );

	shape->capsule = *capsule;
	shape->type = b3_capsuleShape;
	shape->aabbMargin = b3ComputeShapeMargin( shape );

	// need to wake bodies so they can react to the shape change
	bool wakeBodies = true;
	bool destroyProxy = true;
	b3ResetProxy( world, shape, wakeBodies, destroyProxy );

	world->locked = false;
}

void b3Shape_SetHull( b3ShapeId shapeId, const b3HullData* hull )
{
	B3_VALIDATE( b3IsValidHull( hull ) );
	B3_VALIDATE( hull->hash != 0 );

	b3World* world = b3GetUnlockedWorld( shapeId.world0 );
	if ( world == NULL )
	{
		return;
	}

	world->locked = true;

	b3Shape* shape = b3GetShape( world, shapeId );

	// Acquire the new hull before releasing the old so the input may safely alias
	// the shape's current shared data.
	const b3HullData* data = b3AddHullToDatabase( world, hull );

	// Same shared hull, avoid destroying contacts and recreating the proxy
	if ( shape->type == b3_hullShape && data == shape->hull )
	{
		b3RemoveHullFromDatabase( world, data );
		world->locked = false;
		return;
	}

	b3DestroyShapeAllocationForShapeChange( world, shape );

	shape->hull = data;
	shape->type = b3_hullShape;
	shape->aabbMargin = b3ComputeShapeMargin( shape );

	// need to wake bodies so they can react to the shape change
	bool wakeBodies = true;
	bool destroyProxy = true;
	b3ResetProxy( world, shape, wakeBodies, destroyProxy );

	world->locked = false;
}

void b3Shape_SetMesh( b3ShapeId shapeId, const b3MeshData* meshData, b3Vec3 scale )
{
	B3_ASSERT( b3IsValidVec3( scale ) );
	B3_ASSERT( meshData != NULL && b3IsValidMesh( meshData ) );

	b3World* world = b3GetUnlockedWorld( shapeId.world0 );
	if ( world == NULL )
	{
		return;
	}

	world->locked = true;

	b3Shape* shape = b3GetShape( world, shapeId );

	b3DestroyShapeAllocationForShapeChange( world, shape );

	shape->mesh.data = meshData;
	shape->mesh.scale = b3SafeScale( scale );
	shape->type = b3_meshShape;
	shape->aabbMargin = b3ComputeShapeMargin( shape );

	// need to wake bodies so they can react to the shape change
	bool wakeBodies = true;
	bool destroyProxy = true;
	b3ResetProxy( world, shape, wakeBodies, destroyProxy );

	world->locked = false;
}

int b3Shape_GetContactCapacity( b3ShapeId shapeId )
{
	b3World* world = b3GetUnlockedWorld( shapeId.world0 );
	if ( world == NULL )
	{
		return 0;
	}

	b3Shape* shape = b3GetShape( world, shapeId );
	if ( shape->sensorIndex != B3_NULL_INDEX )
	{
		return 0;
	}

	b3Body* body = b3Array_Get( world->bodies, shape->bodyId );

	// Conservative and fast
	return body->contactCount;
}

int b3Shape_GetContactData( b3ShapeId shapeId, b3ContactData* contactData, int capacity )
{
	b3World* world = b3GetUnlockedWorld( shapeId.world0 );
	if ( world == NULL )
	{
		return 0;
	}

	b3Shape* shape = b3GetShape( world, shapeId );
	if ( shape->sensorIndex != B3_NULL_INDEX )
	{
		return 0;
	}

	b3Body* body = b3Array_Get( world->bodies, shape->bodyId );
	int contactKey = body->headContactKey;
	int index = 0;
	while ( contactKey != B3_NULL_INDEX && index < capacity )
	{
		int contactId = contactKey >> 1;
		int edgeIndex = contactKey & 1;

		b3Contact* contact = b3Array_Get( world->contacts, contactId );

		// Does contact involve this shape and is it touching?
		if ( ( contact->shapeIdA == shapeId.index1 - 1 || contact->shapeIdB == shapeId.index1 - 1 ) &&
			 ( contact->flags & b3_contactTouchingFlag ) != 0 )
		{
			b3Shape* shapeA = world->shapes.data + contact->shapeIdA;
			b3Shape* shapeB = world->shapes.data + contact->shapeIdB;

			contactData[index].contactId = (b3ContactId){ contact->contactId + 1, shapeId.world0, 0, contact->generation };
			contactData[index].shapeIdA = (b3ShapeId){ shapeA->id + 1, shapeId.world0, shapeA->generation };
			contactData[index].shapeIdB = (b3ShapeId){ shapeB->id + 1, shapeId.world0, shapeB->generation };
			contactData[index].manifolds = contact->manifolds;
			contactData[index].manifoldCount = contact->manifoldCount;
			index += 1;
		}

		contactKey = contact->edges[edgeIndex].nextKey;
	}

	B3_ASSERT( index <= capacity );

	return index;
}

int b3Shape_GetSensorCapacity( b3ShapeId shapeId )
{
	b3World* world = b3GetUnlockedWorld( shapeId.world0 );
	if ( world == NULL )
	{
		return 0;
	}

	b3Shape* shape = b3GetShape( world, shapeId );
	if ( shape->sensorIndex == B3_NULL_INDEX )
	{
		return 0;
	}

	b3Sensor* sensor = b3Array_Get( world->sensors, shape->sensorIndex );
	return sensor->overlaps2.count;
}

int b3Shape_GetSensorData( b3ShapeId shapeId, b3ShapeId* visitorIds, int capacity )
{
	b3World* world = b3GetUnlockedWorld( shapeId.world0 );
	if ( world == NULL )
	{
		return 0;
	}

	b3Shape* shape = b3GetShape( world, shapeId );
	if ( shape->sensorIndex == B3_NULL_INDEX )
	{
		return 0;
	}

	b3Sensor* sensor = b3Array_Get( world->sensors, shape->sensorIndex );

	int count = b3MinInt( sensor->overlaps2.count, capacity );
	b3Visitor* refs = sensor->overlaps2.data;
	for ( int i = 0; i < count; ++i )
	{
		b3ShapeId visitorId = {
			.index1 = refs[i].shapeId + 1,
			.world0 = shapeId.world0,
			.generation = refs[i].generation,
		};

		visitorIds[i] = visitorId;
	}

	return count;
}

b3AABB b3Shape_GetAABB( b3ShapeId shapeId )
{
	b3World* world = b3GetWorld( shapeId.world0 );
	if ( world == NULL )
	{
		return (b3AABB){ 0 };
	}

	b3Shape* shape = b3GetShape( world, shapeId );
	return shape->aabb;
}

b3MassData b3Shape_ComputeMassData( b3ShapeId shapeId )
{
	b3World* world = b3GetWorld( shapeId.world0 );
	if ( world == NULL )
	{
		return (b3MassData){ 0 };
	}

	b3Shape* shape = b3GetShape( world, shapeId );
	return b3ComputeShapeMass( shape );
}

b3Vec3 b3Shape_GetClosestPoint( b3ShapeId shapeId, b3Vec3 target )
{
	b3World* world = b3GetWorld( shapeId.world0 );
	if ( world == NULL )
	{
		return b3Vec3_zero;
	}

	b3Shape* shape = b3GetShape( world, shapeId );
	b3Body* body = b3Array_Get( world->bodies, shape->bodyId );
	// Low level closest point query is a documented float carve-out far from the origin
	b3Transform transform = b3ToRelativeTransform( b3GetBodyTransformQuick( world, body ), b3Pos_zero );

	b3DistanceInput input;
	input.proxyA = b3MakeShapeProxy( shape );
	input.proxyB = (b3ShapeProxy){ &target, 1, 0.0f };
	input.transform = b3InvMulTransforms( transform, b3Transform_identity );
	input.useRadii = true;

	b3SimplexCache cache = { 0 };
	b3DistanceOutput output = b3ShapeDistance( &input, &cache, NULL, 0 );

	// Witness point comes back in frame A, lift it back to the query frame
	return b3TransformPoint( transform, output.pointA );
}

#define B3_DEBUG_WIND 0

// https://en.wikipedia.org/wiki/Density_of_air
// https://www.engineeringtoolbox.com/wind-load-d_1775.html
// force = 0.5 * air_density * velocity^2 * area
// https://en.wikipedia.org/wiki/Lift_(force)
void b3Shape_ApplyWind( b3ShapeId shapeId, b3Vec3 wind, float drag, float lift, float maxSpeed, bool wake )
{
	b3World* world = b3GetWorld( shapeId.world0 );
	if ( world == NULL )
	{
		return;
	}

	B3_REC( world, ShapeApplyWind, shapeId, wind, drag, lift, maxSpeed, wake );

	b3Shape* shape = b3GetShape( world, shapeId );

	b3ShapeType shapeType = shape->type;
	if ( shapeType != b3_sphereShape && shapeType != b3_capsuleShape && shapeType != b3_hullShape )
	{
		return;
	}

	b3Body* body = b3Array_Get( world->bodies, shape->bodyId );

	if ( body->type != b3_dynamicBody )
	{
		return;
	}

	if ( body->setIndex == b3_disabledSet )
	{
		return;
	}

	if ( body->setIndex >= b3_firstSleepingSet && wake == false )
	{
		return;
	}

	b3BodySim* sim = b3GetBodySim( world, body );

	if ( body->setIndex != b3_awakeSet )
	{
		// Must wake for state to exist
		b3WakeBodyWithLock( world, body );
	}

	B3_ASSERT( body->setIndex == b3_awakeSet );

	b3BodyState* state = b3GetBodyState( world, body );
	// Only the rotation is used below, so the demoted world transform is exact
	b3Transform transform = b3ToRelativeTransform( sim->transform, b3Pos_zero );

	float lengthUnits = b3GetLengthUnitsPerMeter();
	float volumeUnits = lengthUnits * lengthUnits * lengthUnits;

	float airDensity = 1.2250f / ( volumeUnits );

	b3Vec3 force = { 0 };
	b3Vec3 torque = { 0 };

	switch ( shape->type )
	{
		case b3_sphereShape:
		{
			float radius = shape->sphere.radius;
			b3Vec3 centroid = shape->localCentroid;
			b3Vec3 lever = b3RotateVector( transform.q, b3Sub( centroid, sim->localCenter ) );
			b3Vec3 shapeVelocity = b3Add( state->linearVelocity, b3Cross( state->angularVelocity, lever ) );
			b3Vec3 relativeVelocity = b3MulSub( wind, drag, shapeVelocity );
			float speed;
			b3Vec3 direction = b3GetLengthAndNormalize( &speed, relativeVelocity );
			speed = b3MinFloat( speed, maxSpeed );
			float projectedArea = B3_PI * radius * radius;
			force = b3MulSV( 0.5f * airDensity * projectedArea * speed * speed, direction );
			torque = b3Cross( lever, force );
		}
		break;

		case b3_capsuleShape:
		{
			b3Vec3 centroid = shape->localCentroid;
			b3Vec3 lever = b3RotateVector( transform.q, b3Sub( centroid, sim->localCenter ) );
			b3Vec3 shapeVelocity = b3Add( state->linearVelocity, b3Cross( state->angularVelocity, lever ) );
			b3Vec3 relativeVelocity = b3MulSub( wind, drag, shapeVelocity );
			float speed;
			b3Vec3 direction = b3GetLengthAndNormalize( &speed, relativeVelocity );
			speed = b3MinFloat( speed, maxSpeed );

			b3Vec3 d = b3Sub( shape->capsule.center2, shape->capsule.center1 );
			d = b3RotateVector( transform.q, d );

			float radius = shape->capsule.radius;
			float projectedArea = B3_PI * radius * radius + 2.0f * radius * b3Length( b3Cross( d, direction ) );

			// Normal that opposes the wind
			b3Vec3 e = b3Normalize( d );
			b3Vec3 normal = b3Sub( b3MulSV( b3Dot( direction, e ), e ), direction );

			// portion of wind that is perpendicular to surface
			b3Vec3 liftDirection = b3Cross( b3Cross( normal, direction ), direction );

			float forceMagnitude = 0.5f * airDensity * projectedArea * speed * speed;
			force = b3MulSV( forceMagnitude, b3MulAdd( direction, lift, liftDirection ) );

			b3Vec3 edgeLever = b3MulAdd( lever, radius, normal );
			torque = b3Cross( edgeLever, force );
		}
		break;

		case b3_hullShape:
		{
			b3Matrix3 matrix = b3MakeMatrixFromQuat( transform.q );

			int faceCount = shape->hull->faceCount;
			const b3Vec3* points = b3GetHullPoints( shape->hull );
			const b3HullFace* faces = b3GetHullFaces( shape->hull );
			const b3HullHalfEdge* edges = b3GetHullEdges( shape->hull );
			const b3Plane* planes = b3GetHullPlanes( shape->hull );

			b3Vec3 linearVelocity = state->linearVelocity;
			b3Vec3 angularVelocity = state->angularVelocity;
			b3Vec3 localCenterOfMass = sim->localCenter;

			for ( int i = 0; i < faceCount; ++i )
			{
				const b3HullFace* face = faces + i;
				const b3HullHalfEdge* edge1 = edges + face->edge;
				const b3HullHalfEdge* edge2 = edges + edge1->next;
				const b3HullHalfEdge* edge3 = edges + edge2->next;

				B3_ASSERT( edge1 != edge3 );
				B3_ASSERT( edge1->origin < shape->hull->vertexCount );
				B3_ASSERT( edge2->origin < shape->hull->vertexCount );

				b3Vec3 localPoint1 = points[edge1->origin];
				b3Vec3 localPoint2 = points[edge2->origin];
				b3Vec3 v1 = b3MulMV( matrix, localPoint1 );
				b3Vec3 v2 = b3MulMV( matrix, localPoint2 );
				b3Vec3 normal = b3MulMV( matrix, planes[i].normal );

				do
				{
					B3_ASSERT( edge3->origin < shape->hull->vertexCount );
					b3Vec3 localPoint3 = points[edge3->origin];
					b3Vec3 v3 = b3MulMV( matrix, localPoint3 );

					// Triangle center
					b3Vec3 localCenter = b3MulSV( 0.333333f, b3Add( localPoint1, b3Add( localPoint2, localPoint3 ) ) );

					// Lever arm from center of mass to triangle center in world space
					b3Vec3 lever = b3MulMV( matrix, b3Sub( localCenter, localCenterOfMass ) );

					// Velocity of the triangle center in world space
					b3Vec3 centerVelocity = b3Add( linearVelocity, b3Cross( angularVelocity, lever ) );

					b3Vec3 relativeVelocity = b3MulSub( wind, drag, centerVelocity );
					float speed;
					b3Vec3 direction = b3GetLengthAndNormalize( &speed, relativeVelocity );

					// Check for back-side
					if ( b3Dot( normal, direction ) < -FLT_EPSILON )
					{
						float projectedArea = -0.5f * b3Dot( b3Cross( b3Sub( v2, v1 ), b3Sub( v3, v1 ) ), direction );
						B3_VALIDATE( projectedArea >= -FLT_EPSILON );

						b3Vec3 liftDirection = b3Cross( b3Cross( normal, direction ), direction );

						speed = b3MinFloat( speed, maxSpeed );

						float forceMagnitude = 0.5f * airDensity * projectedArea * speed * speed;
						b3Vec3 deltaForce = b3MulSV( forceMagnitude, b3MulAdd( direction, lift, liftDirection ) );
						b3Vec3 deltaTorque = b3Cross( lever, deltaForce );

						force = b3Add( force, deltaForce );
						torque = b3Add( torque, deltaTorque );

#if B3_DEBUG_WIND
						int lineIndex = world->taskContexts.data[0].lineCount;
						if ( lineIndex < B3_DEBUG_LINE_CAPACITY )
						{
							b3DebugLine* line = world->taskContexts.data[0].lines + lineIndex;
							line->p1 = b3OffsetPos( sim->transform.p, b3MulMV( matrix, localCenter ) );
							line->p2 = b3OffsetPos( line->p1, deltaForce );
							line->label = i;
							line->color = b3_colorBlanchedAlmond;
							world->taskContexts.data[0].lineCount += 1;
						}
#endif
					}

					edge2 = edge3;
					edge3 = edges + edge3->next;
					v2 = v3;
					localPoint2 = localPoint3;
				}
				while ( edge1 != edge3 );
			}
		}
		break;

		default:
			break;
	}

	sim->force = b3Add( sim->force, force );
	sim->torque = b3Add( sim->torque, torque );
}

typedef struct b3MeshImpactContext
{
	b3TOIInput toiInput;
	b3TOIOutput toiOutput;
	// Centroid of shape in body B local space
	b3Vec3 localCentroidB;
	// Centroid of shape at beginning and end of sweep in mesh local space. Used for early out.
	b3Vec3 meshLocalCentroidB1, meshLocalCentroidB2;
	float fallbackRadius;
	bool isSensor;

	int visitCount;
} b3MeshImpactContext;

static bool b3MeshTimeOfImpactFcn( b3Vec3 a, b3Vec3 b, b3Vec3 c, int triangleIndex, void* context )
{
	B3_UNUSED( triangleIndex );

	b3MeshImpactContext* toiContext = context;

	toiContext->visitCount += 1;

	// Early out for parallel movement
	b3Vec3 c1 = toiContext->meshLocalCentroidB1;
	b3Vec3 c2 = toiContext->meshLocalCentroidB2;

	b3Vec3 n = b3Normalize( b3Cross( b3Sub( b, a ), b3Sub( c, a ) ) );
	float offset1 = b3Dot( n, b3Sub( c1, a ) );
	float offset2 = b3Dot( n, b3Sub( c2, a ) );

	if ( offset1 < 0.0f )
	{
		// Started behind or finished in front
		return true;
	}

	if ( toiContext->isSensor == false && offset1 - offset2 < toiContext->fallbackRadius && offset2 > toiContext->fallbackRadius )
	{
		// Finished in front
		return true;
	}

	b3Vec3 triangle[3] = { a, b, c };
	toiContext->toiInput.proxyA.points = triangle;
	toiContext->toiInput.proxyA.count = 3;

	b3TOIOutput output = b3TimeOfImpact( &toiContext->toiInput );

	// It is possible for a hit at fraction == 0

	if ( 0.0f < output.fraction && output.fraction < toiContext->toiInput.maxFraction )
	{
		toiContext->toiOutput = output;
		toiContext->toiInput.maxFraction = output.fraction;
	}
	else if ( 0.0f == output.fraction )
	{
		// fallback to TOI of a small circle around the fast shape centroid
		b3TOIInput fallbackInput = toiContext->toiInput;
		fallbackInput.proxyB = (b3ShapeProxy){ &toiContext->localCentroidB, 1, toiContext->fallbackRadius + B3_LINEAR_SLOP };
		output = b3TimeOfImpact( &fallbackInput );

		if ( 0.0f < output.fraction && output.fraction < toiContext->toiInput.maxFraction )
		{
			toiContext->toiOutput = output;
			toiContext->toiInput.maxFraction = output.fraction;
			toiContext->toiOutput.usedFallback = true;
		}
	}

	// Continue the query
	return true;
}

typedef struct b3CompoundImpactContext
{
	b3TOIInput toiInput;
	b3TOIOutput toiOutput;
	b3Transform compoundTransform;

	// Bounds local to compound
	b3AABB localSweepBoundsB;

	// Centroid of shape in body B local space
	b3Vec3 localCentroidB;
	float fallbackRadius;
} b3CompoundImpactContext;

// Implements b3CompoundQueryFcn
static bool b3CompoundTimeOfImpactFcn( const b3CompoundData* compound, int childIndex, void* context )
{
	b3CompoundImpactContext* toiContext = (b3CompoundImpactContext*)context;

	b3ChildShape child = b3GetCompoundChild( compound, childIndex );

	b3TOIOutput output = { 0 };
	toiContext->toiInput.sweepA = b3MakeCompoundChildSweep( toiContext->compoundTransform, child.transform );

	switch ( child.type )
	{
		case b3_capsuleShape:
		{
			toiContext->toiInput.proxyA.points = &child.capsule.center1;
			toiContext->toiInput.proxyA.count = 2;
			toiContext->toiInput.proxyA.radius = child.capsule.radius;
			output = b3TimeOfImpact( &toiContext->toiInput );
		}
		break;

		case b3_hullShape:
		{
			toiContext->toiInput.proxyA.points = b3GetHullPoints( child.hull );
			toiContext->toiInput.proxyA.count = child.hull->vertexCount;
			toiContext->toiInput.proxyA.radius = 0.0f;
			output = b3TimeOfImpact( &toiContext->toiInput );
		}
		break;

		case b3_meshShape:
		{
			b3MeshImpactContext meshContext = { 0 };
			meshContext.toiInput = toiContext->toiInput;
			meshContext.isSensor = false;
			meshContext.localCentroidB = toiContext->localCentroidB;
			meshContext.fallbackRadius = toiContext->fallbackRadius;

			b3Transform meshWorldTransform = b3MulTransforms( toiContext->compoundTransform, child.transform );

			const b3Sweep* sweepB = &toiContext->toiInput.sweepB;
			b3Transform xfB1 = {
				.p = b3Sub( sweepB->c1, b3RotateVector( sweepB->q1, sweepB->localCenter ) ),
				.q = sweepB->q1,
			};

			b3Transform xfB2 = {
				.p = b3Sub( sweepB->c2, b3RotateVector( sweepB->q2, sweepB->localCenter ) ),
				.q = sweepB->q2,
			};

			meshContext.meshLocalCentroidB1 =
				b3InvTransformPoint( meshWorldTransform, b3TransformPoint( xfB1, meshContext.localCentroidB ) );
			meshContext.meshLocalCentroidB2 =
				b3InvTransformPoint( meshWorldTransform, b3TransformPoint( xfB2, meshContext.localCentroidB ) );

			// Bounds local to mesh
			b3AABB localBounds = b3AABB_Transform( b3InvertTransform( child.transform ), toiContext->localSweepBoundsB );

			b3QueryMesh( &child.mesh, localBounds, b3MeshTimeOfImpactFcn, &meshContext );

			output = meshContext.toiOutput;
		}
		break;

		case b3_sphereShape:
		{
			toiContext->toiInput.proxyA.points = &child.sphere.center;
			toiContext->toiInput.proxyA.count = 1;
			toiContext->toiInput.proxyA.radius = child.sphere.radius;
			output = b3TimeOfImpact( &toiContext->toiInput );
		}
		break;

		default:
			B3_ASSERT( false );
			break;
	}

	if ( 0.0f < output.fraction && output.fraction < toiContext->toiInput.maxFraction )
	{
		toiContext->toiOutput = output;
		toiContext->toiInput.maxFraction = output.fraction;
	}

	// Clear this to be safe
	toiContext->toiInput.proxyA = (b3ShapeProxy){ 0 };

	// Continue the query
	return true;
}

b3TOIOutput b3ShapeTimeOfImpact( b3Shape* shapeA, b3Shape* shapeB, b3Sweep* sweepA, b3Sweep* sweepB, float maxFraction )
{
	bool isSensor = shapeA->sensorIndex != B3_NULL_INDEX;

	b3ShapeType typeA = shapeA->type;
	if ( typeA == b3_compoundShape )
	{
		// todo implement b3CompoundTimeOfImpact
		b3CompoundImpactContext context = { 0 };
		context.toiInput.proxyB = b3MakeShapeProxy( shapeB );
		context.toiInput.sweepB = *sweepB;
		context.toiInput.maxFraction = maxFraction;

		context.compoundTransform = (b3Transform){
			.p = sweepA->c1,
			.q = sweepA->q1,
		};

		b3Vec3 localCentroidB = b3GetShapeCentroid( shapeB );
		context.localCentroidB = localCentroidB;

		b3ShapeExtent extents = b3ComputeShapeExtent( shapeB, context.localCentroidB );
		context.fallbackRadius = b3MaxFloat( 0.75f * extents.minExtent, B3_SPECULATIVE_DISTANCE );

		// Swept bounds of shapeB
		b3AABB bounds = b3ComputeSweptShapeAABB( shapeB, sweepB, maxFraction );

		// Bounds local to mesh
		b3AABB localBounds = b3AABB_Transform( b3InvertTransform( context.compoundTransform ), bounds );
		context.localSweepBoundsB = localBounds;

		b3QueryCompound( shapeA->compound, localBounds, b3CompoundTimeOfImpactFcn, &context );

		return context.toiOutput;
	}

	if ( typeA == b3_heightShape || typeA == b3_meshShape )
	{
		// todo implement b3MeshTimeOfImpact and b3HeightFieldTimeOfImpact
		// Note: assuming mesh is static

		uint64_t ticks = b3GetTicks();

		b3MeshImpactContext context = { 0 };
		context.toiInput.sweepA = *sweepA;
		context.toiInput.proxyA.count = 3;
		context.toiInput.proxyB = b3MakeShapeProxy( shapeB );
		context.toiInput.sweepB = *sweepB;
		context.toiInput.maxFraction = maxFraction;
		context.isSensor = isSensor;

		b3Vec3 localCentroidB = b3GetShapeCentroid( shapeB );
		context.localCentroidB = localCentroidB;

		// Assume mesh is static
		b3Transform xfA = {
			.p = b3Sub( sweepA->c1, b3RotateVector( sweepA->q1, sweepA->localCenter ) ),
			.q = sweepA->q1,
		};

		b3Transform xfB1 = {
			.p = b3Sub( sweepB->c1, b3RotateVector( sweepB->q1, sweepB->localCenter ) ),
			.q = sweepB->q1,
		};

		b3Transform xfB2 = {
			.p = b3Sub( sweepB->c2, b3RotateVector( sweepB->q2, sweepB->localCenter ) ),
			.q = sweepB->q2,
		};

		context.meshLocalCentroidB1 = b3InvTransformPoint( xfA, b3TransformPoint( xfB1, localCentroidB ) );
		context.meshLocalCentroidB2 = b3InvTransformPoint( xfA, b3TransformPoint( xfB2, localCentroidB ) );

		b3ShapeExtent extents = b3ComputeShapeExtent( shapeB, context.localCentroidB );
		context.fallbackRadius = b3MaxFloat( 0.5f * extents.minExtent, B3_LINEAR_SLOP );

		// Swept bounds of shapeB
		// todo pass in xfA to get local bounds directly
		b3AABB bounds = b3ComputeSweptShapeAABB( shapeB, sweepB, maxFraction );

		// Bounds local to mesh
		b3AABB localBounds = b3AABB_Transform( b3InvertTransform( xfA ), bounds );

		if ( typeA == b3_meshShape )
		{
			b3QueryMesh( &shapeA->mesh, localBounds, b3MeshTimeOfImpactFcn, &context );
		}
		else if ( typeA == b3_heightShape )
		{
			b3QueryHeightField( shapeA->heightField, localBounds, b3MeshTimeOfImpactFcn, &context );
		}

		float ms = b3GetMilliseconds( ticks );
		if ( ms > 1000.0f * b3GetStallThreshold() )
		{
			b3Log( "CCD stall: visited %d triangles", context.visitCount );
		}

		return context.toiOutput;
	}

	B3_ASSERT( shapeB->type != b3_compoundShape && shapeB->type != b3_meshShape && shapeB->type != b3_heightShape );

	b3TOIInput input;
	input.proxyA = b3MakeShapeProxy( shapeA );
	input.proxyB = b3MakeShapeProxy( shapeB );
	input.sweepA = *sweepA;
	input.sweepB = *sweepB;
	input.maxFraction = maxFraction;

	b3TOIOutput output = b3TimeOfImpact( &input );

#if 0
	// todo I'm not sure this is worth it for convex vs convex.
	if (0.0f < output.fraction && output.fraction < maxFraction)
	{
		return output;
	}

	if (0.0f == output.fraction)
	{
		// fallback to TOI of a small circle around the fast shape centroid
		b3Vec3 centroid = b3GetShapeCentroid( shapeB );
		input.proxyB = ( b3ShapeProxy ){ &centroid, 1, B3_SPECULATIVE_DISTANCE };
		output = b3TimeOfImpact( &input );
		return output;
	}
#endif

	return output;
}

// Resolve the user material id for a hit point on the given shape. Mesh/heightfield shapes
// use the manifold-point triangleIndex to pick a per-triangle material. Compound shapes use
// the contact's childIndex to find the participating child, then for a mesh child apply the
// child's materialIndices indirection on top of the per-triangle index. Convex shapes fall
// back to materials[0]. childIndex is unused for non-compound shapes.
uint64_t b3GetShapeUserMaterialId( const b3Shape* shape, int childIndex, int triangleIndex )
{
	if ( shape->materialCount == 0 )
	{
		return 0;
	}

	int materialIndex = 0;
	if ( shape->type == b3_meshShape )
	{
		const uint8_t* indices = b3GetMeshMaterialIndices( shape->mesh.data );
		if ( indices != NULL )
		{
			materialIndex = indices[triangleIndex];
		}
	}
	else if ( shape->type == b3_heightShape )
	{
		materialIndex = b3GetHeightFieldMaterial( shape->heightField, triangleIndex );
	}
	else if ( shape->type == b3_compoundShape )
	{
		b3ChildShape child = b3GetCompoundChild( shape->compound, childIndex );
		if ( child.type == b3_meshShape )
		{
			const uint8_t* indices = b3GetMeshMaterialIndices( child.mesh.data );
			int meshMaterialIndex = indices != NULL ? indices[triangleIndex] : 0;
			meshMaterialIndex = b3ClampInt( meshMaterialIndex, 0, B3_MAX_COMPOUND_MESH_MATERIALS - 1 );
			materialIndex = child.materialIndices[meshMaterialIndex];
		}
		else
		{
			materialIndex = child.materialIndices[0];
		}
	}

	materialIndex = b3ClampInt( materialIndex, 0, shape->materialCount - 1 );
	return b3GetShapeMaterials( shape )[materialIndex].userMaterialId;
}
