// SPDX-FileCopyrightText: 2025 Erin Catto
// SPDX-License-Identifier: MIT

#include "contact.h"

#include "algorithm.h"
#include "body.h"
#include "compound.h"
#include "island.h"
#include "manifold.h"
#include "physics_world.h"
#include "shape.h"
#include "solver_set.h"
#include "table.h"

#include "box3d/box3d.h"

// Contacts and determinism
// A deterministic simulation requires contacts to exist in the same order in b3Island no matter the thread count.
// The order must reproduce from run to run. This is necessary because the Gauss-Seidel constraint solver is order dependent.
//
// Creation:
// - Contacts are created using results from b3UpdateBroadPhasePairs
// - These results are ordered according to the order of the broad-phase move array
// - The move array is ordered according to the shape creation order using a bitset.
// - The island/shape/body order is determined by creation order
// - Logically contacts are only created for awake bodies, so they are immediately added to the awake contact array (serially)
//
// Island linking:
// - The awake contact array is built from the body-contact graph for all awake bodies in awake islands.
// - Awake contacts are solved in parallel and they generate contact state changes.
// - These state changes may link islands together using union find.
// - The state changes are ordered using a bit array that encompasses all contacts
// - As long as contacts are created in deterministic order, island link order is deterministic.
// - This keeps the order of contacts in islands deterministic

// Manifold functions should compute important results in local space to improve precision. However, this
// interface function takes two world transforms instead of a relative transform for these reasons:
//
// First:
// The anchors need to be computed relative to the shape origin in world space. This is necessary so the
// solver does not need to access static body transforms. Not even in constraint preparation. This approach
// has world space vectors yet retains precision.
//
// Second:
// b3ManifoldPoint::point is very useful for debugging and it is in world space.
//
// Third:
// The user may call the manifold functions directly and they should be easy to use and have easy to use
// results.
// typedef b3Manifold b3ManifoldFcn( const b3Shape* shapeA, b3Transform xfA, const b3Shape* shapeB, b3Transform xfB,
//								  b3ContactCache* cache );

static b3Contact* b3GetContactFullId( b3World* world, b3ContactId contactId )
{
	int id = contactId.index1 - 1;
	b3Contact* contact = b3Array_Get( world->contacts, id );
	B3_ASSERT( contact->contactId == id && contact->generation == contactId.generation );
	return contact;
}

b3ContactData b3Contact_GetData( b3ContactId contactId )
{
	b3World* world = b3GetWorld( contactId.world0 );
	b3Contact* contact = b3GetContactFullId( world, contactId );

	const b3Shape* shapeA = b3Array_Get( world->shapes, contact->shapeIdA );
	const b3Shape* shapeB = b3Array_Get( world->shapes, contact->shapeIdB );

	b3ContactData data = { 0 };
	data.contactId = contactId;
	data.shapeIdA = (b3ShapeId){
		.index1 = shapeA->id + 1,
		.world0 = contactId.world0,
		.generation = shapeA->generation,
	};
	data.shapeIdB = (b3ShapeId){
		.index1 = shapeB->id + 1,
		.world0 = contactId.world0,
		.generation = shapeB->generation,
	};

	if ( contact->manifoldCount > 0 )
	{
		data.manifolds = contact->manifolds;
		data.manifoldCount = contact->manifoldCount;
	}
	else
	{
		data.manifolds = NULL;
		data.manifoldCount = 0;
	}

	return data;
}

struct b3ContactRegister
{
	// b3ManifoldFcn* fcn;
	bool supported;
	bool primary;
};

static struct b3ContactRegister s_registers[b3_shapeTypeCount][b3_shapeTypeCount];
static bool s_initialized = false;

static void b3AddType( b3ShapeType type1, b3ShapeType type2 )
{
	B3_ASSERT( 0 <= type1 && type1 < b3_shapeTypeCount );
	B3_ASSERT( 0 <= type2 && type2 < b3_shapeTypeCount );

	s_registers[type1][type2].supported = true;
	s_registers[type1][type2].primary = true;

	if ( type1 != type2 )
	{
		s_registers[type2][type1].supported = true;
		s_registers[type2][type1].primary = false;
	}
}

void b3InitializeContactRegisters( void )
{
	if ( s_initialized == false )
	{
		b3AddType( b3_sphereShape, b3_sphereShape );
		b3AddType( b3_capsuleShape, b3_sphereShape );
		b3AddType( b3_capsuleShape, b3_capsuleShape );
		b3AddType( b3_compoundShape, b3_sphereShape );
		b3AddType( b3_compoundShape, b3_capsuleShape );
		b3AddType( b3_compoundShape, b3_hullShape );
		b3AddType( b3_hullShape, b3_sphereShape );
		b3AddType( b3_hullShape, b3_capsuleShape );
		b3AddType( b3_hullShape, b3_hullShape );
		b3AddType( b3_meshShape, b3_sphereShape );
		b3AddType( b3_meshShape, b3_capsuleShape );
		b3AddType( b3_meshShape, b3_hullShape );
		b3AddType( b3_heightShape, b3_sphereShape );
		b3AddType( b3_heightShape, b3_capsuleShape );
		b3AddType( b3_heightShape, b3_hullShape );
		s_initialized = true;
	}
}

void b3CreateContact( b3World* world, b3Shape* shapeA, b3Shape* shapeB, int childIndex )
{
	b3ShapeType typeA = shapeA->type;
	b3ShapeType typeB = shapeB->type;

	B3_ASSERT( 0 <= typeA && typeA < b3_shapeTypeCount );
	B3_ASSERT( 0 <= typeB && typeB < b3_shapeTypeCount );

	if ( s_registers[typeA][typeB].supported == false )
	{
		// For example, no mesh vs mesh collision
		return;
	}

	if ( s_registers[typeA][typeB].primary == false )
	{
		// flip order
		b3CreateContact( world, shapeB, shapeA, childIndex );
		return;
	}

	b3Body* bodyA = b3Array_Get( world->bodies, shapeA->bodyId );
	b3Body* bodyB = b3Array_Get( world->bodies, shapeB->bodyId );

	B3_ASSERT( bodyA->setIndex != b3_disabledSet && bodyB->setIndex != b3_disabledSet );
	B3_ASSERT( bodyA->setIndex != b3_staticSet || bodyB->setIndex != b3_staticSet );

	int setIndex;
	if ( bodyA->setIndex == b3_awakeSet || bodyB->setIndex == b3_awakeSet )
	{
		setIndex = b3_awakeSet;
	}
	else
	{
		// sleeping and non-touching contacts live in the disabled set
		// later if this set is found to be touching then the sleeping
		// islands will be linked and the contact moved to the merged island

		// This is possible if a shape moves slightly then falls asleep
		setIndex = b3_disabledSet;
	}

	b3SolverSet* set = b3Array_Get( world->solverSets, setIndex );

	// Create contact key and contact
	int contactId = b3AllocId( &world->contactIdPool );
	if ( contactId == world->contacts.count )
	{
		b3Contact emptyContact = { 0 };
		b3Array_Push( world->contacts, emptyContact );
	}

	int shapeIdA = shapeA->id;
	int shapeIdB = shapeB->id;

	b3Contact* contact = b3Array_Get( world->contacts, contactId );
	int generation = contact->generation;
	*contact = (b3Contact){ 0 };
	contact->contactId = contactId;
	contact->generation = generation + 1;
	contact->setIndex = setIndex;
	contact->colorIndex = B3_NULL_INDEX;
	contact->localIndex = set->contactIndices.count;
	contact->islandId = B3_NULL_INDEX;
	contact->islandIndex = B3_NULL_INDEX;
	contact->shapeIdA = shapeIdA;
	contact->shapeIdB = shapeIdB;
	contact->childIndex = childIndex;

	// Both bodies must enable recycling
	if ( ( bodyA->flags & b3_bodyEnableContactRecycling ) != 0 && ( bodyB->flags & b3_bodyEnableContactRecycling ) != 0 )
	{
		contact->flags |= b3_contactRecycleFlag;
	}

	if ( shapeA->type == b3_meshShape || shapeA->type == b3_heightShape )
	{
		contact->flags |= b3_simMeshContact;
	}
	else if ( shapeA->type == b3_compoundShape )
	{
		b3ChildShape child = b3GetCompoundChild( shapeA->compound, childIndex );
		if ( child.type == b3_meshShape )
		{
			contact->flags |= b3_simMeshContact;
		}
	}

	// todo impose these restrictions to make life easier
	B3_ASSERT( shapeB->type == b3_sphereShape || shapeB->type == b3_capsuleShape || shapeB->type == b3_hullShape );
	// B3_ASSERT( bodyB->type != b3_staticBody );

	// Is either body static?
	// Note: it is possible to have a dynamic mesh collide with a static convex shape. Maybe I should disallow this.
	if ( bodyA->type == b3_staticBody || bodyB->type == b3_staticBody )
	{
		contact->flags |= b3_contactStaticFlag;
	}

	B3_ASSERT( shapeA->sensorIndex == B3_NULL_INDEX && shapeB->sensorIndex == B3_NULL_INDEX );

	if ( ( shapeA->flags & b3_enableContactEvents ) || ( shapeB->flags & b3_enableContactEvents ) )
	{
		contact->flags |= b3_contactEnableContactEvents;
	}

	if ( ( shapeA->flags & b3_enableSpeculative ) && ( shapeB->flags & b3_enableSpeculative ) )
	{
		contact->flags |= b3_enableSpeculativePoints;
	}

	// Connect to body A
	{
		contact->edges[0].bodyId = shapeA->bodyId;
		contact->edges[0].prevKey = B3_NULL_INDEX;
		contact->edges[0].nextKey = bodyA->headContactKey;

		int keyA = ( contactId << 1 ) | 0;
		int headContactKey = bodyA->headContactKey;
		if ( headContactKey != B3_NULL_INDEX )
		{
			b3Contact* headContact = b3Array_Get( world->contacts, headContactKey >> 1 );
			headContact->edges[headContactKey & 1].prevKey = keyA;
		}
		bodyA->headContactKey = keyA;
		bodyA->contactCount += 1;
	}

	// Connect to body B
	{
		contact->edges[1].bodyId = shapeB->bodyId;
		contact->edges[1].prevKey = B3_NULL_INDEX;
		contact->edges[1].nextKey = bodyB->headContactKey;

		int keyB = ( contactId << 1 ) | 1;
		int headContactKey = bodyB->headContactKey;
		if ( bodyB->headContactKey != B3_NULL_INDEX )
		{
			b3Contact* headContact = b3Array_Get( world->contacts, headContactKey >> 1 );
			headContact->edges[headContactKey & 1].prevKey = keyB;
		}
		bodyB->headContactKey = keyB;
		bodyB->contactCount += 1;
	}

	// Add to pair set for fast lookup
	uint64_t pairKey = b3ShapePairKey( shapeIdA, shapeIdB, childIndex );
	b3AddKey( &world->broadPhase.pairSet, pairKey );

	// Contacts are created as non-touching. Later if they are found to be touching
	// they will link islands and be moved into the constraint graph.
	b3Array_Push( set->contactIndices, contactId );

	float radiusA = 0.0f;
	if ( typeA == b3_sphereShape )
	{
		radiusA = shapeA->sphere.radius;
	}
	else if ( typeA == b3_capsuleShape )
	{
		radiusA = shapeA->capsule.radius;
	}

	float radiusB = 0.0f;
	if ( typeB == b3_sphereShape )
	{
		radiusB = shapeB->sphere.radius;
	}
	else if ( typeB == b3_capsuleShape )
	{
		radiusB = shapeB->capsule.radius;
	}

	float maxRadius = b3MaxFloat( radiusA, radiusB );

	// Assuming the rolling resistance doesn't change
	contact->rollingResistance =
		b3MaxFloat( b3GetShapeMaterials( shapeA )[0].rollingResistance, b3GetShapeMaterials( shapeB )[0].rollingResistance ) *
		maxRadius;

	if ( ( shapeA->flags & b3_enablePreSolveEvents ) || ( shapeB->flags & b3_enablePreSolveEvents ) )
	{
		contact->flags |= b3_simEnablePreSolveEvents;
	}
}

// A contact is destroyed when:
// - broad-phase proxies stop overlapping
// - a body is destroyed
// - a body is disabled
// - a body changes type from dynamic to kinematic or static
// - a shape is destroyed
// - contact filtering is modified
void b3DestroyContact( b3World* world, b3Contact* contact, bool wakeBodies )
{
	// Remove pair from set
	uint64_t pairKey = b3ShapePairKey( contact->shapeIdA, contact->shapeIdB, contact->childIndex );
	b3RemoveKey( &world->broadPhase.pairSet, pairKey );

	b3FreeManifolds( world, contact->manifolds, contact->manifoldCount );
	contact->manifolds = NULL;
	contact->manifoldCount = 0;

	b3ContactEdge* edgeA = contact->edges + 0;
	b3ContactEdge* edgeB = contact->edges + 1;

	int bodyIdA = edgeA->bodyId;
	int bodyIdB = edgeB->bodyId;
	b3Body* bodyA = b3Array_Get( world->bodies, bodyIdA );
	b3Body* bodyB = b3Array_Get( world->bodies, bodyIdB );

	uint32_t flags = contact->flags;
	bool touching = ( flags & b3_contactTouchingFlag ) != 0;

	// End touch event
	if ( touching && ( flags & b3_contactEnableContactEvents ) != 0 )
	{
		uint16_t worldId = world->worldId;
		const b3Shape* shapeA = b3Array_Get( world->shapes, contact->shapeIdA );
		const b3Shape* shapeB = b3Array_Get( world->shapes, contact->shapeIdB );
		b3ShapeId shapeIdA = { shapeA->id + 1, worldId, shapeA->generation };
		b3ShapeId shapeIdB = { shapeB->id + 1, worldId, shapeB->generation };

		b3ContactId contactId = {
			.index1 = contact->contactId + 1,
			.world0 = world->worldId,
			.padding = 0,
			.generation = contact->generation,
		};

		b3ContactEndTouchEvent event = {
			.shapeIdA = shapeIdA,
			.shapeIdB = shapeIdB,
			.contactId = contactId,
		};

		b3Array_Push( world->contactEndEvents[world->endEventArrayIndex], event );
	}

	// Remove from body A
	if ( edgeA->prevKey != B3_NULL_INDEX )
	{
		b3Contact* prevContact = b3Array_Get( world->contacts, edgeA->prevKey >> 1 );
		b3ContactEdge* prevEdge = prevContact->edges + ( edgeA->prevKey & 1 );
		prevEdge->nextKey = edgeA->nextKey;
	}

	if ( edgeA->nextKey != B3_NULL_INDEX )
	{
		b3Contact* nextContact = b3Array_Get( world->contacts, edgeA->nextKey >> 1 );
		b3ContactEdge* nextEdge = nextContact->edges + ( edgeA->nextKey & 1 );
		nextEdge->prevKey = edgeA->prevKey;
	}

	int contactId = contact->contactId;

	int edgeKeyA = ( contactId << 1 ) | 0;
	if ( bodyA->headContactKey == edgeKeyA )
	{
		bodyA->headContactKey = edgeA->nextKey;
	}

	bodyA->contactCount -= 1;

	// Remove from body B
	if ( edgeB->prevKey != B3_NULL_INDEX )
	{
		b3Contact* prevContact = b3Array_Get( world->contacts, edgeB->prevKey >> 1 );
		b3ContactEdge* prevEdge = prevContact->edges + ( edgeB->prevKey & 1 );
		prevEdge->nextKey = edgeB->nextKey;
	}

	if ( edgeB->nextKey != B3_NULL_INDEX )
	{
		b3Contact* nextContact = b3Array_Get( world->contacts, edgeB->nextKey >> 1 );
		b3ContactEdge* nextEdge = nextContact->edges + ( edgeB->nextKey & 1 );
		nextEdge->prevKey = edgeB->prevKey;
	}

	int edgeKeyB = ( contactId << 1 ) | 1;
	if ( bodyB->headContactKey == edgeKeyB )
	{
		bodyB->headContactKey = edgeB->nextKey;
	}

	bodyB->contactCount -= 1;

	if ( contact->flags & b3_simMeshContact )
	{
		b3Array_Destroy( contact->meshContact.triangleCache );
	}

	// Remove contact from the array that owns it
	if ( contact->islandId != B3_NULL_INDEX )
	{
		b3UnlinkContact( world, contact );
	}

	if ( contact->colorIndex != B3_NULL_INDEX )
	{
		// contact is an active constraint
		B3_ASSERT( contact->setIndex == b3_awakeSet );
		bool meshContact = contact->flags & b3_simMeshContact;
		b3RemoveContactFromGraph( world, bodyIdA, bodyIdB, contact->colorIndex, contact->localIndex, meshContact );
	}
	else
	{
		// contact is non-touching or is sleeping or is a sensor
		B3_ASSERT( contact->setIndex != b3_awakeSet || ( contact->flags & b3_contactTouchingFlag ) == 0 );
		b3SolverSet* set = b3Array_Get( world->solverSets, contact->setIndex );

		int localIndex = contact->localIndex;
		int movedIndex = b3Array_RemoveSwap( set->contactIndices, localIndex );
		if ( movedIndex != B3_NULL_INDEX )
		{
			int movedContactIndex = set->contactIndices.data[localIndex];
			b3Contact* movedContact = b3Array_Get( world->contacts, movedContactIndex );
			movedContact->localIndex = localIndex;
		}
	}

	// Free contact and id (preserve generation)
	contact->contactId = B3_NULL_INDEX;
	contact->setIndex = B3_NULL_INDEX;
	contact->colorIndex = B3_NULL_INDEX;
	contact->localIndex = B3_NULL_INDEX;
	b3FreeId( &world->contactIdPool, contactId );

	if ( wakeBodies && touching )
	{
		b3WakeBody( world, bodyA );
		b3WakeBody( world, bodyB );
	}
}

static bool b3ComputeConvexManifold( b3World* world, int workerIndex, b3Contact* contact, const b3Shape* shapeA,
									 b3WorldTransform xfA, const b3Shape* shapeB, b3WorldTransform xfB, b3Arena arena )
{
	b3ShapeType typeA = shapeA->type;
	b3ShapeType typeB = shapeB->type;

	b3ContactCache* cache = &contact->convexContact.cache;

	int pointCapacity = 32;
	b3LocalManifoldPoint* pointBuffer = (b3LocalManifoldPoint*)b3Bump( &arena, pointCapacity * sizeof( b3LocalManifoldPoint ) );

	b3LocalManifold geomManifold = { 0 };
	geomManifold.points = pointBuffer;

	b3Transform transformBtoA = b3InvMulWorldTransforms( xfA, xfB );

	if ( typeA == b3_sphereShape )
	{
		B3_ASSERT( typeB == b3_sphereShape );
		b3CollideSpheres( &geomManifold, pointCapacity, &shapeA->sphere, &shapeB->sphere, transformBtoA );
	}
	else if ( typeA == b3_capsuleShape )
	{
		if ( typeB == b3_sphereShape )
		{
			b3CollideCapsuleAndSphere( &geomManifold, pointCapacity, &shapeA->capsule, &shapeB->sphere, transformBtoA );
		}
		else
		{
			B3_ASSERT( typeB == b3_capsuleShape );
			b3CollideCapsules( &geomManifold, pointCapacity, &shapeA->capsule, &shapeB->capsule, transformBtoA );
		}
	}
	else
	{
		B3_ASSERT( typeA == b3_hullShape );

		if ( typeB == b3_sphereShape )
		{
			b3CollideHullAndSphere( &geomManifold, pointCapacity, shapeA->hull, &shapeB->sphere, transformBtoA,
									&cache->simplexCache );
		}
		else if ( typeB == b3_capsuleShape )
		{
			b3CollideHullAndCapsule( &geomManifold, pointCapacity, shapeA->hull, &shapeB->capsule, transformBtoA,
									 &cache->simplexCache );
		}
		else
		{
			B3_ASSERT( typeB == b3_hullShape );
			b3CollideHulls( &geomManifold, pointCapacity, shapeA->hull, shapeB->hull, transformBtoA, &cache->satCache );
			world->taskContexts.data[workerIndex].satCallCount += 1;
			world->taskContexts.data[workerIndex].satCacheHitCount += cache->satCache.hit;
		}
	}

	if ( geomManifold.pointCount == 0 )
	{
		if ( contact->manifoldCount > 0 )
		{
			b3FreeManifolds( world, contact->manifolds, contact->manifoldCount );
			contact->manifolds = NULL;
			contact->manifoldCount = 0;
		}

		return false;
	}

	b3ManifoldPoint oldPoints[B3_MAX_MANIFOLD_POINTS];
	int oldCount = 0;

	if ( contact->manifoldCount == 0 )
	{
		contact->manifolds = b3AllocateManifolds( world, 1 );
		contact->manifoldCount = 1;
	}
	else
	{
		oldCount = contact->manifolds[0].pointCount;
		memcpy( oldPoints, contact->manifolds[0].points, oldCount * sizeof( b3ManifoldPoint ) );
	}

	b3Manifold* manifold = contact->manifolds;
	manifold->pointCount = geomManifold.pointCount;

	b3Matrix3 matrixA = b3MakeMatrixFromQuat( xfA.q );
	manifold->normal = b3MulMV( matrixA, geomManifold.normal );

	// Store point data in contact
	for ( int i = 0; i < geomManifold.pointCount; ++i )
	{
		const b3LocalManifoldPoint* source = geomManifold.points + i;
		b3ManifoldPoint* target = manifold->points + i;

		// Contact points are computed in frame A
		target->anchorA = b3MulMV( matrixA, source->point );
		target->anchorB = b3Add( target->anchorA, b3SubPos( xfA.p, xfB.p ) );
		target->separation = source->separation;
		target->featureId = b3MakeFeatureId( source->pair );
		target->triangleIndex = B3_NULL_INDEX;
		target->normalVelocity = 0.0f;
	}

	// Copy impulses from old points
	for ( int i = 0; i < geomManifold.pointCount; ++i )
	{
		b3ManifoldPoint* pt2 = manifold->points + i;
		pt2->totalNormalImpulse = 0.0f;
		pt2->persisted = false;

		for ( int j = 0; j < oldCount; ++j )
		{
			b3ManifoldPoint* pt1 = oldPoints + j;

			if ( pt2->featureId == pt1->featureId )
			{
				pt2->normalImpulse = pt1->normalImpulse;
				pt2->persisted = true;

				// claimed
				pt1->featureId = UINT32_MAX;

				break;
			}
		}

		if ( pt2->persisted == false )
		{
			pt2->normalImpulse = 0.0f;
		}
	}

	return true;
}

static bool b3UpdateConvexContact( b3World* world, int workerIndex, b3Contact* contact, b3Shape* shapeA, b3WorldTransform xfA,
								   b3Shape* shapeB, b3WorldTransform xfB, bool flip, b3Arena arena )
{
	// Compute new manifold
	bool touching = b3ComputeConvexManifold( world, workerIndex, contact, shapeA, xfA, shapeB, xfB, arena );

	if ( touching == false )
	{
		B3_ASSERT( contact->manifolds == NULL && contact->manifoldCount == 0 );
		return false;
	}

	B3_ASSERT( contact->manifoldCount == 1 );

	if ( flip )
	{
		// Not flipping the feature ids because they just need to match and flipping is consistent.
		b3Manifold* manifold = contact->manifolds + 0;
		manifold->normal = b3Neg( manifold->normal );
		int pointCount = manifold->pointCount;
		for ( int i = 0; i < pointCount; ++i )
		{
			b3ManifoldPoint* mp = manifold->points + i;
			B3_SWAP( mp->anchorA, mp->anchorB );
		}
	}

	const b3SurfaceMaterial* materialA = b3GetShapeMaterials( shapeA );
	const b3SurfaceMaterial* materialB = b3GetShapeMaterials( shapeB );

	// Keep these updated in case the values on the shapes are modified
	contact->friction =
		world->frictionCallback( materialA->friction, materialA->userMaterialId, materialB->friction, materialB->userMaterialId );
	contact->restitution = world->restitutionCallback( materialA->restitution, materialA->userMaterialId, materialB->restitution,
													   materialB->userMaterialId );

	if ( materialA->rollingResistance > 0.0f || materialB->rollingResistance > 0.0f )
	{
		b3ShapeType typeA = shapeA->type;
		b3ShapeType typeB = shapeB->type;

		float radiusA = 0.0f;
		if ( typeA == b3_sphereShape )
		{
			radiusA = shapeA->sphere.radius;
		}
		else if ( typeA == b3_capsuleShape )
		{
			radiusA = shapeA->capsule.radius;
		}
		else if ( typeA == b3_hullShape )
		{
			radiusA = 0.25f * shapeA->hull->innerRadius;
		}

		float radiusB = 0.0f;
		if ( typeB == b3_sphereShape )
		{
			radiusB = shapeB->sphere.radius;
		}
		else if ( typeB == b3_capsuleShape )
		{
			radiusB = shapeB->capsule.radius;
		}
		else if ( typeB == b3_hullShape )
		{
			radiusB = 0.25f * shapeB->hull->innerRadius;
		}

		float maxRadius = b3MaxFloat( radiusA, radiusB );
		contact->rollingResistance = b3MaxFloat( materialA->rollingResistance, materialB->rollingResistance ) * maxRadius;
	}
	else
	{
		contact->rollingResistance = 0.0f;
	}

	b3Vec3 tangentVelocityA = b3RotateVector( xfA.q, materialA->tangentVelocity );
	b3Vec3 tangentVelocityB = b3RotateVector( xfB.q, materialB->tangentVelocity );
	contact->tangentVelocity = b3Sub( tangentVelocityA, tangentVelocityB );

	if ( world->preSolveFcn && ( contact->flags & b3_simEnablePreSolveEvents ) != 0 )
	{
		b3ShapeId shapeIdA = { shapeA->id + 1, world->worldId, shapeA->generation };
		b3ShapeId shapeIdB = { shapeB->id + 1, world->worldId, shapeB->generation };

		// this call assumes thread safety
		b3Pos point = b3OffsetPos( xfA.p, contact->manifolds[0].points[0].anchorA );
		b3Vec3 normal = contact->manifolds[0].normal;
		touching = world->preSolveFcn( shapeIdA, shapeIdB, point, normal, world->preSolveContext );
		if ( touching == false )
		{
			// disable contact
			b3FreeManifolds( world, contact->manifolds, contact->manifoldCount );
			contact->manifolds = NULL;
			contact->manifoldCount = 0;
			return false;
		}
	}

	if ( ( shapeA->flags & b3_enableHitEvents ) || ( shapeB->flags & b3_enableHitEvents ) )
	{
		contact->flags |= b3_simEnableHitEvent;
	}
	else
	{
		contact->flags &= ~b3_simEnableHitEvent;
	}

	return true;
}

// Update the contact manifold and touching status.
// Note: do not assume the shape AABBs are overlapping or are valid.
bool b3UpdateContact( b3World* world, int workerIndex, b3Contact* contact, b3Shape* shapeA, b3Vec3 localCenterA,
					  b3WorldTransform xfA, b3Shape* shapeB, b3Vec3 localCenterB, b3WorldTransform xfB, bool isFast,
					  b3Arena arena )
{
	bool touching;

	B3_ASSERT( shapeB->type != b3_compoundShape );

	if ( shapeA->type == b3_compoundShape )
	{
		int childIndex = contact->childIndex;
		b3ChildShape child = b3GetCompoundChild( shapeA->compound, childIndex );

		// Temporary child shape to match existing function signatures
		b3Shape childShapeA;
		memcpy( &childShapeA, shapeA, sizeof( b3Shape ) );

		childShapeA.type = child.type;

		if ( child.type == b3_capsuleShape )
		{
			childShapeA.capsule = child.capsule;
			if ( shapeB->type == b3_hullShape )
			{
				// Flip
				bool flip = true;
				touching = b3UpdateConvexContact( world, workerIndex, contact, shapeB, xfB, &childShapeA, xfA, flip, arena );
			}
			else
			{
				bool flip = false;
				touching = b3UpdateConvexContact( world, workerIndex, contact, &childShapeA, xfA, shapeB, xfB, flip, arena );
			}
		}
		else if ( child.type == b3_hullShape )
		{
			childShapeA.hull = child.hull;
			b3WorldTransform xfChild = b3MulWorldTransforms( xfA, child.transform );
			bool flip = false;
			touching = b3UpdateConvexContact( world, workerIndex, contact, &childShapeA, xfChild, shapeB, xfB, flip, arena );
		}
		else if ( child.type == b3_meshShape )
		{
			childShapeA.mesh = child.mesh;
			b3WorldTransform xfChild = b3MulWorldTransforms( xfA, child.transform );

			touching = b3ComputeMeshManifolds( world, workerIndex, contact, &childShapeA, child.materialIndices, xfChild, shapeB,
											   xfB, isFast, arena );

			if ( touching && ( ( shapeA->flags & b3_enableHitEvents ) || ( shapeB->flags & b3_enableHitEvents ) ) )
			{
				contact->flags |= b3_simEnableHitEvent;
			}
			else
			{
				contact->flags &= ~b3_simEnableHitEvent;
			}

			B3_ASSERT( ( touching == true && contact->manifoldCount > 0 ) ||
					   ( touching == false && contact->manifoldCount == 0 ) );
		}
		else
		{
			B3_ASSERT( child.type == b3_sphereShape );

			childShapeA.sphere = child.sphere;
			if ( shapeB->type == b3_capsuleShape || shapeB->type == b3_hullShape )
			{
				// Flip
				bool flip = true;
				touching = b3UpdateConvexContact( world, workerIndex, contact, shapeB, xfB, &childShapeA, xfA, flip, arena );
			}
			else
			{
				bool flip = false;
				touching = b3UpdateConvexContact( world, workerIndex, contact, &childShapeA, xfA, shapeB, xfB, flip, arena );
			}
		}

		// The anchor is relative to the child origin but oriented in world space.
		// Offset the anchor to be relative to the compound origin.
		int manifoldCount = contact->manifoldCount;
		b3Vec3 offset = b3RotateVector( xfA.q, child.transform.p );
		for ( int i = 0; i < manifoldCount; ++i )
		{
			b3Manifold* manifold = contact->manifolds + i;
			int pointCount = manifold->pointCount;
			for ( int j = 0; j < pointCount; ++j )
			{
				b3ManifoldPoint* mp = manifold->points + j;
				mp->anchorA = b3Add( mp->anchorA, offset );
			}
		}
	}
	else if ( shapeA->type == b3_meshShape || shapeA->type == b3_heightShape )
	{
		// Does this contact touch a mesh or height-field?

		// Compute mesh manifolds
		touching = b3ComputeMeshManifolds( world, workerIndex, contact, shapeA, NULL, xfA, shapeB, xfB, isFast, arena );

		if ( touching && ( ( shapeA->flags & b3_enableHitEvents ) || ( shapeB->flags & b3_enableHitEvents ) ) )
		{
			contact->flags |= b3_simEnableHitEvent;
		}
		else
		{
			contact->flags &= ~b3_simEnableHitEvent;
		}

		B3_ASSERT( ( touching == true && contact->manifoldCount > 0 ) || ( touching == false && contact->manifoldCount == 0 ) );
	}
	else
	{
		// Convex-vs-convex
		bool flip = false;
		touching = b3UpdateConvexContact( world, workerIndex, contact, shapeA, xfA, shapeB, xfB, flip, arena );
	}

	if ( touching )
	{
		b3Vec3 centerA = b3RotateVector( xfA.q, localCenterA );
		b3Vec3 centerB = b3RotateVector( xfB.q, localCenterB );

		// Adjust anchors to be relative to center of mass
		for ( int i = 0; i < contact->manifoldCount; ++i )
		{
			b3Manifold* manifold = contact->manifolds + i;
			for ( int j = 0; j < manifold->pointCount; ++j )
			{
				b3ManifoldPoint* mp = manifold->points + j;
				mp->anchorA = b3Sub( mp->anchorA, centerA );
				mp->anchorB = b3Sub( mp->anchorB, centerB );
			}
		}

		contact->flags |= b3_simTouchingFlag;
	}
	else
	{
		contact->flags &= ~b3_simTouchingFlag;
	}

	return touching;
}
